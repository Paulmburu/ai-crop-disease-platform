"""Find images, label them, split them, and build DataLoaders.

Dataset layout (Kaggle `emmarex/plantdisease`, 15 classes, ~20.6k images):

    data/plantvillage/PlantVillage/
        Pepper__bell___Bacterial_spot/xxx.JPG
        Potato___Early_blight/...
        Tomato__Target_Spot/...          <- some folders use "__"
        Tomato_Bacterial_spot/...        <- and some a single "_"

Things this module gets right that are easy to get wrong:
- File extensions are mixed case (.JPG / .jpg), so matching is case-insensitive.
- The split is stratified, so rare classes appear in val and test too.
- Each split has its own Dataset object, so train gets augmentation and
  val/test do not.
- The balancing sampler is built from *train* labels only, so it can never
  draw a val/test image into training.
"""

import json
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import torch
from PIL import Image
from sklearn.model_selection import train_test_split
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler

from crop_ml.config import TrainConfig
from crop_ml.transforms import build_eval_transforms, build_train_transforms

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}


def parse_class_name(folder: str) -> tuple[str, str]:
    """Split a PlantVillage folder name into (plant, condition).

    >>> parse_class_name("Pepper__bell___Bacterial_spot")
    ('Pepper bell', 'Bacterial spot')
    >>> parse_class_name("Tomato__Target_Spot")
    ('Tomato', 'Target Spot')
    >>> parse_class_name("Tomato_Bacterial_spot")
    ('Tomato', 'Bacterial spot')
    """
    # Three naming styles exist in this dataset: "Potato___Early_blight",
    # "Tomato__Target_Spot" and "Tomato_Bacterial_spot". Use the longest separator present.
    sep = next((s for s in ("___", "__", "_") if s in folder), "_")
    plant, _, condition = folder.partition(sep)

    def clean(s: str) -> str:
        return " ".join(s.replace("_", " ").split())

    return clean(plant), clean(condition) or "unknown"


def scan_images(data_dir: Path) -> pd.DataFrame:
    """One row per image: path, class_name, label (int), plant, condition.

    Labels are assigned in sorted folder order; that order is saved as
    class_names.json and must never change between training and serving.
    """
    if not data_dir.is_dir():
        raise FileNotFoundError(f"Dataset folder not found: {data_dir}")
    # Only folders that directly contain images are classes. The Kaggle zip also holds a
    # nested duplicate "PlantVillage/" folder with no images of its own; counting it as a
    # class would shift every label index after it.
    class_dirs = sorted(d for d in data_dir.iterdir()
                        if d.is_dir() and any(f.suffix.lower() in IMAGE_EXTENSIONS for f in d.iterdir()))
    rows = []
    for label, d in enumerate(class_dirs):
        plant, condition = parse_class_name(d.name)
        for f in sorted(d.iterdir()):
            if f.suffix.lower() in IMAGE_EXTENSIONS:
                rows.append({"path": str(f), "class_name": d.name, "label": label,
                             "plant": plant, "condition": condition})
    if not rows:
        raise ValueError(f"No images found under {data_dir}")
    return pd.DataFrame(rows)


@dataclass
class Splits:
    train: pd.DataFrame
    val: pd.DataFrame
    test: pd.DataFrame
    class_names: list[str]

    def save(self, path: Path) -> None:
        """Write the exact file lists so evaluation re-uses the same test set."""
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({
            "class_names": self.class_names,
            **{k: getattr(self, k)[["path", "label"]].to_dict("records") for k in ("train", "val", "test")},
        }))

    @classmethod
    def load(cls, path: Path) -> "Splits":
        raw = json.loads(path.read_text())
        return cls(*(pd.DataFrame(raw[k]) for k in ("train", "val", "test")), class_names=raw["class_names"])


def split_dataset(df: pd.DataFrame, val_fraction: float, test_fraction: float, seed: int) -> Splits:
    """Stratified train/val/test split (class proportions kept in every split).

    Note: PlantVillage holds several photos of the same leaf, so a random split
    still lets near-duplicates land in both train and test. Treat test accuracy
    as optimistic; real field photos will score lower.
    """
    class_names = sorted(df["class_name"].unique())
    train_val, test = train_test_split(df, test_size=test_fraction, stratify=df["label"], random_state=seed)
    rel_val = val_fraction / (1 - test_fraction)
    train, val = train_test_split(train_val, test_size=rel_val, stratify=train_val["label"], random_state=seed)
    return Splits(*(s.reset_index(drop=True) for s in (train, val, test)), class_names=class_names)


class LeafDataset(Dataset):
    """Loads images from a split DataFrame and applies one transform."""

    def __init__(self, frame: pd.DataFrame, transform) -> None:
        self.paths = frame["path"].tolist()
        self.labels = frame["label"].tolist()
        self.transform = transform

    def __len__(self) -> int:
        return len(self.paths)

    def __getitem__(self, i: int) -> tuple[torch.Tensor, int]:
        with Image.open(self.paths[i]) as img:
            return self.transform(img.convert("RGB")), self.labels[i]


def make_balanced_sampler(labels: list[int]) -> WeightedRandomSampler:
    """Sample each training image with probability 1/(its class count).

    Rare classes get drawn as often as common ones, which counters the ~20x
    imbalance in this dataset. Built from train labels only.
    """
    counts = Counter(labels)
    weights = torch.tensor([1.0 / counts[y] for y in labels], dtype=torch.double)
    return WeightedRandomSampler(weights, num_samples=len(labels), replacement=True)


def build_dataloaders(cfg: TrainConfig, splits: Splits) -> dict[str, DataLoader]:
    """Return {"train", "val", "test"} DataLoaders for the given splits."""
    train_tf = build_train_transforms(cfg.image_size, cfg.mean, cfg.std)
    eval_tf = build_eval_transforms(cfg.image_size, cfg.mean, cfg.std)
    common = {
        "batch_size": cfg.batch_size,
        "num_workers": cfg.num_workers,
        "persistent_workers": cfg.num_workers > 0,
        "pin_memory": torch.cuda.is_available(),  # only useful (and supported) on CUDA
    }
    return {
        "train": DataLoader(LeafDataset(splits.train, train_tf),
                            sampler=make_balanced_sampler(splits.train["label"].tolist()), **common),
        "val": DataLoader(LeafDataset(splits.val, eval_tf), shuffle=False, **common),
        "test": DataLoader(LeafDataset(splits.test, eval_tf), shuffle=False, **common),
    }
