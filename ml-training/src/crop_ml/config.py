"""All training settings in one place.

Every CLI flag in `crop_ml.train` maps onto a field here, so a run is fully
described by one `TrainConfig` (it is saved next to the checkpoint).
"""

from dataclasses import dataclass, field
from pathlib import Path

# ImageNet statistics: the pretrained MobileNetV2 expects inputs normalised this way.
IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)


@dataclass
class TrainConfig:
    data_dir: Path = Path("data/PlantVillage")  # folder of class sub-folders
    output_dir: Path = Path("outputs")  # checkpoints/, plots/, splits.json
    model_version: str = "v1"

    image_size: int = 224
    batch_size: int = 32
    epochs: int = 10
    lr: float = 1e-3
    weight_decay: float = 1e-4
    label_smoothing: float = 0.1
    patience: int = 3  # early stopping: epochs without val-loss improvement
    val_fraction: float = 0.15
    test_fraction: float = 0.10
    seed: int = 42
    num_workers: int = 2
    pretrained: bool = True  # False = random weights (offline tests)
    freeze_backbone: bool = True  # train only the classifier head

    mean: tuple[float, float, float] = field(default=IMAGENET_MEAN)
    std: tuple[float, float, float] = field(default=IMAGENET_STD)

    @property
    def checkpoint_dir(self) -> Path:
        return self.output_dir / "checkpoints"

    @property
    def plots_dir(self) -> Path:
        return self.output_dir / "plots"

    @property
    def checkpoint_path(self) -> Path:
        return self.checkpoint_dir / f"mobilenetv2_{self.model_version}_best.pt"
