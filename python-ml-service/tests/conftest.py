"""Shared fixtures.

- `checkpoint`: a real (random-weight) checkpoint in the Phase 1 format, so the
  real InferenceService is tested without needing Phase 1 to have run.
- `client`: an httpx client talking to the app in-process with a loaded service.
"""

import io
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import pytest
import torch
from PIL import Image
from torch import nn
from torchvision.models import mobilenet_v2

from app.main import create_app
from app.services.inference import InferenceService

CLASS_NAMES = ["Pepper__bell___Bacterial_spot", "Potato___healthy", "Tomato__Target_Spot"]


def make_checkpoint(path: Path, class_names: list[str] = CLASS_NAMES, threshold: float | None = 0.5) -> Path:
    """Write a checkpoint with exactly the keys Phase 1's train.py saves."""
    model = mobilenet_v2(weights=None)
    model.classifier[1] = nn.Linear(model.last_channel, len(class_names))
    ckpt = {
        "model_state_dict": model.state_dict(),
        "num_classes": len(class_names),
        "class_names": class_names,
        "model_version": "v1",
        "val_acc": 0.5,
        "image_size": 224,
        "mean": [0.485, 0.456, 0.406],
        "std": [0.229, 0.224, 0.225],
    }
    if threshold is not None:
        ckpt["confidence_threshold"] = threshold
    torch.save(ckpt, path)
    return path


def image_bytes(fmt: str = "JPEG", size: tuple[int, int] = (300, 200)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, (40, 160, 60)).save(buf, format=fmt)
    return buf.getvalue()


@pytest.fixture(scope="session")
def checkpoint(tmp_path_factory: pytest.TempPathFactory) -> Path:
    return make_checkpoint(tmp_path_factory.mktemp("models") / "mobilenetv2_v1_best.pt")


@pytest.fixture(scope="session")
def loaded_service(checkpoint: Path) -> InferenceService:
    service = InferenceService(checkpoint)
    service.load()
    return service


@pytest.fixture
async def client(loaded_service: InferenceService) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(service=loaded_service)
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture
async def unloaded_client(tmp_path: Path) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(service=InferenceService(tmp_path / "missing.pt"))
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as c:
        yield c
