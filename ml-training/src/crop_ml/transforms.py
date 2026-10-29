"""Image preprocessing pipelines (torchvision.transforms.v2).

Train: random crop/flip/rotation/colour jitter, so the model sees varied leaves.
Eval:  deterministic resize + centre crop. The Phase 2 service must apply
       exactly this eval pipeline; the checkpoint stores image_size/mean/std
       so it can.
"""

import torch
from torchvision.transforms import v2 as T

from crop_ml.config import IMAGENET_MEAN, IMAGENET_STD


def _to_normalized_tensor(mean: tuple[float, ...], std: tuple[float, ...]) -> list:
    # ToImage + ToDtype(scale=True) replaces the deprecated ToTensor(): uint8 [0,255] -> float [0,1]
    return [T.ToImage(), T.ToDtype(torch.float32, scale=True), T.Normalize(mean, std)]


def build_train_transforms(
    image_size: int = 224, mean: tuple[float, ...] = IMAGENET_MEAN, std: tuple[float, ...] = IMAGENET_STD
) -> T.Compose:
    """Augmenting pipeline for training images (PIL in, normalised CxHxW tensor out)."""
    return T.Compose([
        T.RandomResizedCrop(image_size, scale=(0.7, 1.0)),
        T.RandomHorizontalFlip(),
        T.RandomVerticalFlip(),  # leaf photos have no fixed "up"
        T.RandomRotation(20),
        T.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        *_to_normalized_tensor(mean, std),
    ])


def build_eval_transforms(
    image_size: int = 224, mean: tuple[float, ...] = IMAGENET_MEAN, std: tuple[float, ...] = IMAGENET_STD
) -> T.Compose:
    """Deterministic pipeline for validation, test and serving."""
    return T.Compose([
        T.Resize(int(image_size * 256 / 224)),  # 256 for 224: standard ImageNet ratio
        T.CenterCrop(image_size),
        *_to_normalized_tensor(mean, std),
    ])
