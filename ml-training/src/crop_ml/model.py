"""MobileNetV2 with a new classification head (transfer learning).

MobileNetV2 is small (~3.5M params) and fast on phones, which matters for the
Flutter/KMP phases. We reuse its ImageNet features and replace only the last layer.
"""

from torch import nn
from torchvision.models import MobileNet_V2_Weights, mobilenet_v2


def build_model(num_classes: int, pretrained: bool = True, freeze_backbone: bool = True) -> nn.Module:
    """Return MobileNetV2 whose final Linear layer outputs `num_classes` logits.

    pretrained=True downloads ImageNet weights once (~14 MB, cached by torch).
    freeze_backbone=True trains only the head: fast and enough for a baseline.
    """
    weights = MobileNet_V2_Weights.IMAGENET1K_V2 if pretrained else None
    model = mobilenet_v2(weights=weights)
    if freeze_backbone:
        for p in model.features.parameters():
            p.requires_grad = False
    model.classifier[1] = nn.Linear(model.last_channel, num_classes)
    return model
