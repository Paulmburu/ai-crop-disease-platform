"""Model loading and prediction. No HTTP code here, so it can be tested and reused directly.

The preprocessing below MUST match Phase 1's eval pipeline
(ml-training/src/crop_ml/transforms.py::build_eval_transforms). The image
size and normalisation values come from the checkpoint, so they cannot drift;
only the resize/crop steps are duplicated, and test_inference.py guards them.

All methods are synchronous and CPU-bound. Routers call them through
run_in_threadpool so the event loop keeps serving other requests.
"""

import io
import time
from dataclasses import dataclass
from pathlib import Path

import structlog
import torch
from PIL import Image, UnidentifiedImageError
from torch import nn
from torchvision.models import mobilenet_v2
from torchvision.transforms import v2 as T

log = structlog.get_logger(__name__)

HEALTHY_LABEL = "healthy"


class ModelNotLoadedError(RuntimeError):
    pass


class InvalidImageError(ValueError):
    pass


@dataclass(frozen=True)
class ClassScore:
    class_name: str
    plant: str
    condition: str
    confidence: float


@dataclass(frozen=True)
class InferenceResult:
    top_k: list[ClassScore]
    model_version: str
    inference_ms: float


def parse_class_name(folder: str) -> tuple[str, str]:
    """'Pepper__bell___Bacterial_spot' -> ('Pepper bell', 'Bacterial spot'). Same rule as Phase 1."""
    # Three naming styles exist in this dataset: "Potato___Early_blight",
    # "Tomato__Target_Spot" and "Tomato_Bacterial_spot". Use the longest separator present.
    sep = next((s for s in ("___", "__", "_") if s in folder), "_")
    plant, _, condition = folder.partition(sep)

    def clean(s: str) -> str:
        return " ".join(s.replace("_", " ").split())

    return clean(plant), clean(condition) or "unknown"


def build_preprocess(image_size: int, mean: list[float], std: list[float]) -> T.Compose:
    """Phase 1 eval pipeline: resize short side to 256/224 * size, centre crop, normalise."""
    return T.Compose([
        T.Resize(int(image_size * 256 / 224)),
        T.CenterCrop(image_size),
        T.ToImage(),
        T.ToDtype(torch.float32, scale=True),
        T.Normalize(mean, std),
    ])


def resolve_device(name: str) -> torch.device:
    if name == "auto":
        if torch.backends.mps.is_available():
            return torch.device("mps")
        return torch.device("cuda" if torch.cuda.is_available() else "cpu")
    return torch.device(name)


class InferenceService:
    """Loads one checkpoint and turns image bytes into ranked predictions."""

    def __init__(self, checkpoint_path: Path, device: str = "cpu") -> None:
        self.checkpoint_path = checkpoint_path
        self.device = resolve_device(device)
        self._model: nn.Module | None = None
        self.class_names: list[str] = []
        self.model_version = ""
        self.image_size = 224
        self.val_acc: float | None = None
        self.confidence_threshold = 0.5
        self._preprocess: T.Compose | None = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self) -> None:
        """Read the checkpoint (Phase 1 contract), rebuild the network, warm it up."""
        if not self.checkpoint_path.exists():
            raise FileNotFoundError(
                f"Checkpoint not found: {self.checkpoint_path}. Copy it from "
                "ml-training/outputs/checkpoints/ (see README)."
            )
        # weights_only=True refuses to unpickle arbitrary objects: safe for files from elsewhere.
        ckpt = torch.load(self.checkpoint_path, map_location="cpu", weights_only=True)
        model = mobilenet_v2(weights=None)
        model.classifier[1] = nn.Linear(model.last_channel, ckpt["num_classes"])
        model.load_state_dict(ckpt["model_state_dict"])
        self._model = model.to(self.device).eval()

        self.class_names = list(ckpt["class_names"])
        self.model_version = ckpt["model_version"]
        self.image_size = int(ckpt["image_size"])
        self.val_acc = ckpt.get("val_acc")
        # Chosen on validation data in Phase 1; 0.5 for older checkpoints that predate it.
        self.confidence_threshold = float(ckpt.get("confidence_threshold", 0.5))
        self._preprocess = build_preprocess(self.image_size, ckpt["mean"], ckpt["std"])

        # First call is slow (allocations); pay that cost at startup, not on a user request.
        with torch.inference_mode():
            self._model(torch.zeros(1, 3, self.image_size, self.image_size, device=self.device))
        log.info("model_loaded", version=self.model_version, classes=len(self.class_names),
                 device=str(self.device), path=str(self.checkpoint_path))

    def _decode(self, image_bytes: bytes) -> Image.Image:
        try:
            with Image.open(io.BytesIO(image_bytes)) as img:
                img.verify()  # cheap integrity check; verify() invalidates img, so reopen below
            return Image.open(io.BytesIO(image_bytes)).convert("RGB")
        except (UnidentifiedImageError, OSError, SyntaxError) as exc:
            raise InvalidImageError("File is not a readable image") from exc

    def predict(self, image_bytes: bytes, top_k: int = 3) -> InferenceResult:
        """Decode, preprocess and classify one image. Blocking: call from a worker thread."""
        if self._model is None or self._preprocess is None:
            raise ModelNotLoadedError("Model is not loaded")
        start = time.perf_counter()
        tensor = self._preprocess(self._decode(image_bytes)).unsqueeze(0).to(self.device)
        with torch.inference_mode():
            probs = torch.softmax(self._model(tensor), dim=1)[0].cpu()
        k = max(1, min(top_k, len(self.class_names)))
        conf, idx = probs.topk(k)
        scores = [
            ClassScore(name, *parse_class_name(name), confidence=round(float(c), 4))
            for c, name in ((c, self.class_names[i]) for c, i in zip(conf.tolist(), idx.tolist(), strict=True))
        ]
        return InferenceResult(scores, self.model_version, round((time.perf_counter() - start) * 1000, 2))
