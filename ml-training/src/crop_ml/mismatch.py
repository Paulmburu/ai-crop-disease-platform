"""What a preprocessing mismatch does to accuracy: the "silent failure" experiment.

The phone must prepare images exactly like training did. Each variant below is a
realistic bug in a Dart port; the model still returns confident-looking answers,
only the accuracy drops. Nothing crashes, which is why this failure is silent.

Run (from ml-training/, after training):
    uv run python -m crop_ml.mismatch

Variants:
    correct          Resize short side to 256 -> centre crop 224 -> /255 -> normalise
    stretch          Resize straight to 224x224 (aspect ratio distorted, no crop)
    no_scale         Forget /255: pixel values 0..255 reach the network
    bgr              Red and blue channels swapped (common with camera/OpenCV buffers)
"""

import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader
from torchvision.transforms import v2 as T

from crop_ml.config import TrainConfig
from crop_ml.data import LeafDataset, Splits
from crop_ml.evaluate import load_checkpoint, predict
from crop_ml.train import pick_device


def swap_red_blue(x: torch.Tensor) -> torch.Tensor:
    """RGB -> BGR. A named function (not a lambda) so DataLoader worker processes can pickle it."""
    return x[[2, 1, 0]]


def variants(size: int, mean: list[float], std: list[float]) -> dict[str, T.Compose]:
    norm = T.Normalize(mean, std)
    to_float = [T.ToImage(), T.ToDtype(torch.float32, scale=True)]
    crop = [T.Resize(int(size * 256 / 224)), T.CenterCrop(size)]
    return {
        "correct": T.Compose([*crop, *to_float, norm]),
        "stretch": T.Compose([T.Resize((size, size)), *to_float, norm]),
        # scale=False keeps 0..255 values, exactly what a missing "/ 255.0" in Dart produces
        "no_scale": T.Compose([*crop, T.ToImage(), T.ToDtype(torch.float32, scale=False), norm]),
        "bgr": T.Compose([*crop, *to_float, T.Lambda(swap_red_blue), norm]),
    }


def run(checkpoint: Path, splits_path: Path, out: Path, num_workers: int = 2) -> dict[str, dict]:
    device = pick_device()
    model, ckpt = load_checkpoint(checkpoint, device)
    test = Splits.load(splits_path).test
    threshold = ckpt.get("confidence_threshold")
    results = {}
    for name, tf in variants(ckpt["image_size"], ckpt["mean"], ckpt["std"]).items():
        loader = DataLoader(LeafDataset(test, tf), batch_size=64, num_workers=num_workers)
        y_true, y_pred, conf = predict(model, loader, device)
        results[name] = {
            "accuracy": float((y_true == y_pred).mean()),
            "mean_confidence": float(conf.mean()),
            # Share of images the app would still answer (confident) even though the input is broken
            "answered": float((conf >= threshold).mean()) if threshold is not None else None,
            "predicted_class_counts": np.bincount(y_pred, minlength=ckpt["num_classes"]).tolist(),
        }
    out.write_text(json.dumps({"class_names": ckpt["class_names"], "threshold": threshold,
                               "results": results}, indent=2))
    print(f"{'variant':10s} {'accuracy':>9s} {'mean conf':>10s} {'answered':>9s}  predictions per class")
    for name, r in results.items():
        answered = f"{r['answered']:.1%}" if r["answered"] is not None else "-"
        print(f"{name:10s} {r['accuracy']:9.1%} {r['mean_confidence']:10.2f} {answered:>9s}  "
              f"{r['predicted_class_counts']}")
    print(f"\nclasses: {ckpt['class_names']}\nSaved -> {out}")
    return results


if __name__ == "__main__":
    d = TrainConfig()
    p = argparse.ArgumentParser(description="Measure accuracy under preprocessing mismatches.")
    p.add_argument("--checkpoint", type=Path, default=d.checkpoint_path)
    p.add_argument("--splits", type=Path, default=d.output_dir / "splits.json")
    p.add_argument("--out", type=Path, default=d.output_dir / "mismatch.json")
    p.add_argument("--num-workers", type=int, default=d.num_workers)
    a = p.parse_args()
    run(a.checkpoint, a.splits, a.out, a.num_workers)
