"""The four losses you meet most often, written by hand and checked against PyTorch.

- MSE: regression, punishes large errors hard.
- MAE: regression, robust to outliers.
- Cross-entropy: pick 1 of N classes (our crop disease task).
- Binary cross-entropy: yes/no, or several independent yes/no labels.

Run:  uv run python -m crop_ml.theory.loss_functions
"""

import numpy as np
import torch
from torch import nn


def mse(y_pred: np.ndarray, y_true: np.ndarray) -> float:
    return float(np.mean((y_pred - y_true) ** 2))


def mae(y_pred: np.ndarray, y_true: np.ndarray) -> float:
    return float(np.mean(np.abs(y_pred - y_true)))


def cross_entropy(logits: np.ndarray, true_class: int) -> float:
    """Softmax the raw scores, then take -log(probability of the correct class)."""
    exp = np.exp(logits - logits.max())  # subtracting the max avoids overflow
    probs = exp / exp.sum()
    return float(-np.log(probs[true_class]))


def binary_cross_entropy(logit: float, label: int) -> float:
    """Sigmoid the raw score, then -[y*log(p) + (1-y)*log(1-p)]."""
    p = 1.0 / (1.0 + np.exp(-logit))
    return float(-(label * np.log(p) + (1 - label) * np.log(1 - p)))


def _t(a: np.ndarray) -> torch.Tensor:
    return torch.from_numpy(np.asarray(a, dtype=np.float32))


def main() -> None:
    y_pred = np.array([2.5, 0.0, 2.0, 8.0])
    y_true = np.array([3.0, -0.5, 2.0, 7.0])
    print(f"MSE  manual={mse(y_pred, y_true):.4f}  torch={nn.MSELoss()(_t(y_pred), _t(y_true)):.4f}")
    print(f"MAE  manual={mae(y_pred, y_true):.4f}  torch={nn.L1Loss()(_t(y_pred), _t(y_true)):.4f}")

    # 3 classes (Healthy, Early blight, Late blight); the model favours class 0.
    logits = np.array([2.0, 1.0, 0.1])
    torch_ce = nn.CrossEntropyLoss()(_t(logits).unsqueeze(0), torch.tensor([0]))
    print(f"CE   manual={cross_entropy(logits, 0):.4f}  torch={torch_ce:.4f}")

    torch_bce = nn.BCEWithLogitsLoss()(torch.tensor([1.5]), torch.tensor([1.0]))
    print(f"BCE  manual={binary_cross_entropy(1.5, 1):.4f}  torch={torch_bce:.4f}")

    print(
        "\nWhich loss?\n"
        "  predict a number           -> MSE (default) or MAE (outliers)\n"
        "  yes/no                     -> BCEWithLogitsLoss\n"
        "  1 of N classes             -> CrossEntropyLoss (feed raw logits, no softmax)\n"
        "  several labels at once     -> BCEWithLogitsLoss per label"
    )


if __name__ == "__main__":
    main()
