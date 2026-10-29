"""Evaluate a trained checkpoint on the held-out test split.

Run (from ml-training/, after training):
    uv run python -m crop_ml.evaluate
    uv run python -m crop_ml.evaluate --checkpoint outputs/checkpoints/mobilenetv2_v1_best.pt

Uses outputs/splits.json written by training, so the test images are exactly
the ones the model never saw.

Writes:
    outputs/plots/confusion_matrix.png
    outputs/eval_summary.json     accuracy, macro/weighted F1, per-class P/R/F1
"""

import argparse
import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import seaborn as sns  # noqa: E402
import torch  # noqa: E402
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix  # noqa: E402
from torch import nn  # noqa: E402
from torch.utils.data import DataLoader  # noqa: E402

from crop_ml.config import TrainConfig  # noqa: E402
from crop_ml.data import LeafDataset, Splits  # noqa: E402
from crop_ml.model import build_model  # noqa: E402
from crop_ml.threshold import ThresholdChoice, choose_threshold  # noqa: E402
from crop_ml.train import pick_device  # noqa: E402
from crop_ml.transforms import build_eval_transforms  # noqa: E402


def load_checkpoint(path: Path, device: torch.device) -> tuple[nn.Module, dict]:
    """Rebuild the model from a checkpoint. Returns (model in eval mode, checkpoint dict)."""
    ckpt = torch.load(path, map_location=device, weights_only=True)
    model = build_model(ckpt["num_classes"], pretrained=False, freeze_backbone=False)
    model.load_state_dict(ckpt["model_state_dict"])
    return model.to(device).eval(), ckpt


@torch.inference_mode()
def predict(model: nn.Module, loader: DataLoader, device: torch.device) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Return (true labels, predicted labels, top-1 confidence) for every image in `loader`."""
    y_true, y_pred, conf = [], [], []
    for images, labels in loader:
        probs = torch.softmax(model(images.to(device)), dim=1)
        top, idx = probs.max(1)
        y_pred.append(idx.cpu().numpy())
        conf.append(top.cpu().numpy())
        y_true.append(labels.numpy())
    return np.concatenate(y_true), np.concatenate(y_pred), np.concatenate(conf)


def calibrate(checkpoint: Path, splits_path: Path, target_precision: float = 0.95, batch_size: int = 64,
              num_workers: int = 2) -> ThresholdChoice:
    """Choose the confidence threshold on the VALIDATION split and store it in the checkpoint."""
    device = pick_device()
    model, ckpt = load_checkpoint(checkpoint, device)
    tf = build_eval_transforms(ckpt["image_size"], tuple(ckpt["mean"]), tuple(ckpt["std"]))
    loader = DataLoader(LeafDataset(Splits.load(splits_path).val, tf), batch_size=batch_size,
                        num_workers=num_workers)
    y_true, y_pred, conf = predict(model, loader, device)
    choice = choose_threshold(conf, y_true == y_pred, target_precision)
    ckpt["confidence_threshold"] = choice.threshold
    torch.save(ckpt, checkpoint)
    print(f"Confidence threshold {choice.threshold:.3f}: answers {choice.coverage:.1%} of validation images "
          f"with {choice.precision:.1%} precision")
    return choice


def save_confusion_matrix(y_true: np.ndarray, y_pred: np.ndarray, class_names: list[str], path: Path) -> None:
    """Row-normalised confusion matrix: each row shows where one true class went."""
    labels = list(range(len(class_names)))
    cm = confusion_matrix(y_true, y_pred, labels=labels, normalize="true")
    fig, ax = plt.subplots(figsize=(max(8, len(labels) * 0.7), max(6, len(labels) * 0.6)))
    sns.heatmap(cm, annot=True, fmt=".2f", cmap="Blues", xticklabels=class_names,
                yticklabels=class_names, ax=ax, cbar=False)
    ax.set(xlabel="Predicted", ylabel="True", title="Confusion matrix (row-normalised)")
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def _threshold_stats(threshold: float | None, y_true: np.ndarray, y_pred: np.ndarray, conf: np.ndarray) -> dict:
    """How the stored threshold behaves on the test set (answered share and their accuracy)."""
    if threshold is None:
        return {}
    kept = conf >= threshold
    return {"confidence_threshold": threshold, "test_coverage": float(kept.mean()),
            "test_accuracy_when_answered": float((y_true[kept] == y_pred[kept]).mean()) if kept.any() else None}


def evaluate(checkpoint: Path, splits_path: Path, output_dir: Path, batch_size: int = 64,
             num_workers: int = 2) -> dict:
    """Score the checkpoint on the test split, save plots + summary, return the summary."""
    device = pick_device()
    model, ckpt = load_checkpoint(checkpoint, device)
    splits = Splits.load(splits_path)
    class_names: list[str] = ckpt["class_names"]

    tf = build_eval_transforms(ckpt["image_size"], tuple(ckpt["mean"]), tuple(ckpt["std"]))
    loader = DataLoader(LeafDataset(splits.test, tf), batch_size=batch_size, num_workers=num_workers)
    y_true, y_pred, conf = predict(model, loader, device)

    labels = list(range(len(class_names)))
    # labels= keeps every class in the report even if one is missing from the test split;
    # zero_division=0 avoids warnings/NaN for classes with no predictions.
    report = classification_report(y_true, y_pred, labels=labels, target_names=class_names,
                                   zero_division=0, output_dict=True)
    print(classification_report(y_true, y_pred, labels=labels, target_names=class_names, zero_division=0))

    save_confusion_matrix(y_true, y_pred, class_names, output_dir / "plots" / "confusion_matrix.png")
    summary = {
        "model_version": ckpt["model_version"],
        "test_images": int(len(y_true)),
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "macro_f1": report["macro avg"]["f1-score"],
        "weighted_f1": report["weighted avg"]["f1-score"],
        **_threshold_stats(ckpt.get("confidence_threshold"), y_true, y_pred, conf),
        "per_class": {n: {k: report[n][k] for k in ("precision", "recall", "f1-score", "support")}
                      for n in class_names},
    }
    (output_dir / "eval_summary.json").write_text(json.dumps(summary, indent=2))
    print(f"Accuracy {summary['accuracy']:.3f} | macro F1 {summary['macro_f1']:.3f} "
          f"-> {output_dir / 'eval_summary.json'}")
    return summary


if __name__ == "__main__":
    d = TrainConfig()
    p = argparse.ArgumentParser(description="Evaluate a checkpoint on the test split.")
    p.add_argument("--checkpoint", type=Path, default=d.checkpoint_path)
    p.add_argument("--splits", type=Path, default=d.output_dir / "splits.json")
    p.add_argument("--output-dir", type=Path, default=d.output_dir)
    p.add_argument("--num-workers", type=int, default=d.num_workers)
    a = p.parse_args()
    evaluate(a.checkpoint, a.splits, a.output_dir, num_workers=a.num_workers)
