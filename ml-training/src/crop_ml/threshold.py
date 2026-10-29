"""Pick the confidence threshold below which the app says "retake photo" instead of guessing.

Rule: the lowest threshold t (never below `floor`) such that predictions with
confidence >= t are correct at least `target_precision` of the time on the
VALIDATION set. Lower t keeps more predictions (coverage); higher t keeps fewer,
more reliable ones.

The threshold is stored in the checkpoint as `confidence_threshold`, so the
Phase 2 service and the phone apply exactly the same rule.

Limitation: this guards against low-confidence mistakes on potato leaves. A photo
of something that is not a potato leaf can still get high confidence; the
threshold reduces that risk but does not remove it.
"""

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class ThresholdChoice:
    threshold: float
    coverage: float  # share of validation images that would get an answer
    precision: float  # accuracy on those answered images


def choose_threshold(confidences: np.ndarray, correct: np.ndarray,
                     target_precision: float = 0.95, floor: float = 0.5) -> ThresholdChoice:
    """Lowest threshold >= floor whose accepted predictions reach target_precision.

    confidences: top-1 softmax probability per image; correct: bool per image.
    Falls back to the most selective candidate if the target can't be reached.
    """
    if len(confidences) == 0:
        raise ValueError("Need at least one validation prediction")
    candidates = np.unique(np.concatenate([[floor], confidences[confidences >= floor]]))
    best = None
    for t in candidates:  # ascending: first hit is the lowest qualifying threshold
        kept = confidences >= t
        if not kept.any():
            continue
        precision = float(correct[kept].mean())
        best = ThresholdChoice(float(t), float(kept.mean()), precision)
        if precision >= target_precision:
            return best
    return best or ThresholdChoice(float(floor), 0.0, 0.0)
