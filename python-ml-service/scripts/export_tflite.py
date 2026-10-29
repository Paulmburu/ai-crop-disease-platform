# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = [
#   "litert-torch>=0.10",
#   "torch>=2.4,<2.15",   # litert-torch 0.10 requires torch < 2.15
#   "torchvision",
#   "ai-edge-litert",
#   "numpy",
# ]
# ///
"""Export the PyTorch checkpoint to a TFLite (LiteRT) model for the Flutter/KMP apps.

This is a standalone uv script: it declares its own dependencies above, so its
pinned torch version never conflicts with the service's environment.

Run (from python-ml-service/):
    uv run scripts/export_tflite.py                    # models/mobilenetv2_v1_best.pt -> models/crop_disease_v1.tflite
    uv run scripts/export_tflite.py --version v2

What the mobile app must feed the .tflite model:
    input  float32 [1, H, W, 3]   RGB, values 0..1 (just divide pixels by 255), channels LAST (NHWC)
    output float32 [1, num_classes] probabilities (softmax already applied)
Resizing/cropping to HxW is the app's job; ImageNet normalisation is built into the model.
The .json written next to the model holds class order and the confidence threshold.
"""

import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torch import nn
from torchvision.models import mobilenet_v2


class MobileWrapper(nn.Module):
    """Makes the model phone-friendly: NHWC input in [0,1], normalisation and softmax inside."""

    def __init__(self, model: nn.Module, mean: list[float], std: list[float]) -> None:
        super().__init__()
        self.model = model
        self.register_buffer("mean", torch.tensor(mean).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor(std).view(1, 3, 1, 1))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = x.permute(0, 3, 1, 2)  # NHWC (what mobile image APIs give you) -> NCHW (what PyTorch expects)
        x = (x - self.mean) / self.std
        return torch.softmax(self.model(x), dim=1)


def load_wrapped(checkpoint: Path) -> tuple[nn.Module, dict]:
    ckpt = torch.load(checkpoint, map_location="cpu", weights_only=True)
    model = mobilenet_v2(weights=None)
    model.classifier[1] = nn.Linear(model.last_channel, ckpt["num_classes"])
    model.load_state_dict(ckpt["model_state_dict"])
    return MobileWrapper(model, ckpt["mean"], ckpt["std"]).eval(), ckpt


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--model-dir", type=Path, default=Path("models"))
    p.add_argument("--version", default="v1")
    a = p.parse_args()

    checkpoint = a.model_dir / f"mobilenetv2_{a.version}_best.pt"
    out = a.model_dir / f"crop_disease_{a.version}.tflite"
    wrapped, ckpt = load_wrapped(checkpoint)
    size = int(ckpt["image_size"])
    sample = torch.rand(1, size, size, 3)

    import litert_torch  # imported late: heavy, and only needed here

    edge_model = litert_torch.convert(wrapped, (sample,))
    edge_model.export(str(out))

    # Verify: the TFLite model must agree with PyTorch on the same input.
    with torch.inference_mode():
        expected = wrapped(sample).numpy()
    from ai_edge_litert.interpreter import Interpreter

    interp = Interpreter(model_path=str(out))
    interp.allocate_tensors()
    inp, outp = interp.get_input_details()[0], interp.get_output_details()[0]
    interp.set_tensor(inp["index"], sample.numpy())
    interp.invoke()
    got = interp.get_tensor(outp["index"])
    max_diff = float(np.abs(got - expected).max())

    meta = {"model_version": ckpt["model_version"], "input_shape": inp["shape"].tolist(), "input_layout": "NHWC",
            "input_range": [0, 1], "output": "probabilities", "class_names": ckpt["class_names"],
            # Below this top-1 probability the app shows "retake photo" (same rule as the API).
            "confidence_threshold": float(ckpt.get("confidence_threshold", 0.5))}
    out.with_suffix(".json").write_text(json.dumps(meta, indent=2))
    print(f"Exported {out} ({out.stat().st_size / 1e6:.1f} MB)")
    print(f"input {inp['shape'].tolist()} {inp['dtype'].__name__} | output {outp['shape'].tolist()}")
    print(f"max |tflite - torch| = {max_diff:.2e}  {'OK' if max_diff < 1e-3 else 'MISMATCH'}")
    print(f"metadata -> {out.with_suffix('.json')}")


if __name__ == "__main__":
    main()
