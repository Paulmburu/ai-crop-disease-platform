"""Shared fixtures: a tiny synthetic PlantVillage-style dataset (no download needed)."""

from pathlib import Path

import numpy as np
import pytest
from PIL import Image

# Folder names mimic the real dataset, including the "__" variant and mixed-case extensions.
CLASSES = {
    "Pepper__bell___Bacterial_spot": 24,
    "Potato___healthy": 12,
    "Tomato__Target_Spot": 30,
}


@pytest.fixture(scope="session")
def tiny_dataset(tmp_path_factory: pytest.TempPathFactory) -> Path:
    root = tmp_path_factory.mktemp("plantvillage")
    rng = np.random.default_rng(0)
    for i, (name, n) in enumerate(CLASSES.items()):
        d = root / name
        d.mkdir()
        for j in range(n):
            # Each class has a distinct base colour so a model can actually learn it.
            arr = np.full((64, 80, 3), 60 * (i + 1), dtype=np.uint8)
            arr = (arr + rng.integers(0, 40, arr.shape)).astype(np.uint8)
            ext = ".JPG" if j % 2 else ".jpg"
            Image.fromarray(arr).save(d / f"img_{j}{ext}", format="JPEG")
        (d / "notes.txt").write_text("not an image")
    return root
