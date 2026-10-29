"""Train the MobileNetV2 baseline and save the best checkpoint.

Run (from ml-training/):
    uv run python -m crop_ml.train                       # defaults from TrainConfig
    uv run python -m crop_ml.train --epochs 3 --batch-size 64

Writes:
    outputs/splits.json                                 exact train/val/test file lists
    outputs/checkpoints/mobilenetv2_v1_best.pt          best model (lowest val loss)
    outputs/checkpoints/class_names.json                label index -> folder name
    outputs/checkpoints/history.json                    per-epoch loss/accuracy

Checkpoint contract (Phase 2 relies on these exact keys):
    model_state_dict, num_classes, class_names, model_version,
    val_acc, image_size, mean, std, confidence_threshold (chosen on validation data)
"""

import argparse
import json
import random
import time
from dataclasses import asdict
from pathlib import Path

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader

from crop_ml.config import TrainConfig
from crop_ml.data import build_dataloaders, scan_images, split_dataset
from crop_ml.model import build_model


def pick_device() -> torch.device:
    """Apple GPU (MPS) on an M-series Mac, CUDA on Nvidia, else CPU."""
    if torch.backends.mps.is_available():
        return torch.device("mps")
    if torch.cuda.is_available():
        return torch.device("cuda")
    return torch.device("cpu")


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def run_epoch(model: nn.Module, loader: DataLoader, criterion: nn.Module, device: torch.device,
              optimizer: torch.optim.Optimizer | None = None, frozen_backbone: bool = False) -> tuple[float, float]:
    """One pass over `loader`. Trains if `optimizer` is given, else evaluates.

    Returns (mean loss, accuracy).
    """
    training = optimizer is not None
    model.train(training)
    if training and frozen_backbone:
        # Frozen layers must also keep their BatchNorm statistics frozen.
        model.features.eval()

    total_loss, correct, seen = 0.0, 0, 0
    with torch.set_grad_enabled(training):
        for images, labels in loader:
            images, labels = images.to(device), labels.to(device)
            logits = model(images)
            loss = criterion(logits, labels)
            if training:
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
            total_loss += loss.item() * labels.size(0)
            correct += (logits.argmax(1) == labels).sum().item()
            seen += labels.size(0)
    return total_loss / seen, correct / seen


def save_checkpoint(model: nn.Module, cfg: TrainConfig, class_names: list[str], val_acc: float) -> None:
    """Write the checkpoint plus class_names.json (the Phase 1 -> Phase 2 contract)."""
    cfg.checkpoint_dir.mkdir(parents=True, exist_ok=True)
    torch.save({
        "model_state_dict": model.state_dict(),
        "num_classes": len(class_names),
        "class_names": class_names,
        "model_version": cfg.model_version,
        "val_acc": float(val_acc),
        "image_size": cfg.image_size,
        "mean": list(cfg.mean),
        "std": list(cfg.std),
    }, cfg.checkpoint_path)
    (cfg.checkpoint_dir / "class_names.json").write_text(json.dumps(class_names, indent=2))


def fit(cfg: TrainConfig) -> dict[str, list[float]]:
    """Full training run with early stopping. Returns the per-epoch history."""
    set_seed(cfg.seed)
    device = pick_device()

    splits = split_dataset(scan_images(cfg.data_dir), cfg.val_fraction, cfg.test_fraction, cfg.seed)
    splits.save(cfg.output_dir / "splits.json")
    loaders = build_dataloaders(cfg, splits)
    print(f"Device: {device} | classes: {len(splits.class_names)} | "
          f"train/val/test: {len(splits.train)}/{len(splits.val)}/{len(splits.test)}")

    model = build_model(len(splits.class_names), cfg.pretrained, cfg.freeze_backbone).to(device)
    # The sampler already balances classes, so the loss is unweighted (no double correction).
    criterion = nn.CrossEntropyLoss(label_smoothing=cfg.label_smoothing)
    optimizer = torch.optim.AdamW((p for p in model.parameters() if p.requires_grad),
                                  lr=cfg.lr, weight_decay=cfg.weight_decay)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, factor=0.5, patience=1)

    history: dict[str, list[float]] = {"train_loss": [], "train_acc": [], "val_loss": [], "val_acc": []}
    best_val_loss, epochs_without_improvement = float("inf"), 0

    for epoch in range(1, cfg.epochs + 1):
        start = time.perf_counter()
        tr_loss, tr_acc = run_epoch(model, loaders["train"], criterion, device, optimizer, cfg.freeze_backbone)
        va_loss, va_acc = run_epoch(model, loaders["val"], criterion, device)
        scheduler.step(va_loss)
        for k, v in zip(history, (tr_loss, tr_acc, va_loss, va_acc), strict=True):
            history[k].append(v)

        improved = va_loss < best_val_loss
        print(f"Epoch {epoch:2d}/{cfg.epochs} | train {tr_loss:.4f}/{tr_acc:.3f} | "
              f"val {va_loss:.4f}/{va_acc:.3f} | {time.perf_counter() - start:.0f}s"
              f"{'  <- best, saved' if improved else ''}")
        if improved:
            best_val_loss, epochs_without_improvement = va_loss, 0
            save_checkpoint(model, cfg, splits.class_names, va_acc)
        else:
            epochs_without_improvement += 1
            if epochs_without_improvement >= cfg.patience:
                print(f"Early stopping: no val-loss improvement for {cfg.patience} epochs.")
                break

    # Imported here because evaluate.py imports pick_device from this module.
    from crop_ml.evaluate import calibrate

    calibrate(cfg.checkpoint_path, cfg.output_dir / "splits.json", num_workers=cfg.num_workers)
    (cfg.checkpoint_dir / "history.json").write_text(json.dumps(history, indent=2))
    (cfg.checkpoint_dir / "train_config.json").write_text(json.dumps(asdict(cfg), indent=2, default=str))
    print(f"Best checkpoint -> {cfg.checkpoint_path}")
    return history


def parse_args(argv: list[str] | None = None) -> TrainConfig:
    d = TrainConfig()
    p = argparse.ArgumentParser(description="Train the crop disease baseline model.")
    p.add_argument("--data-dir", type=Path, default=d.data_dir)
    p.add_argument("--output-dir", type=Path, default=d.output_dir)
    p.add_argument("--model-version", default=d.model_version)
    p.add_argument("--epochs", type=int, default=d.epochs)
    p.add_argument("--batch-size", type=int, default=d.batch_size)
    p.add_argument("--lr", type=float, default=d.lr)
    p.add_argument("--patience", type=int, default=d.patience)
    p.add_argument("--num-workers", type=int, default=d.num_workers)
    p.add_argument("--no-pretrained", dest="pretrained", action="store_false",
                   help="random init (offline tests only)")
    p.add_argument("--unfreeze", dest="freeze_backbone", action="store_false",
                   help="fine-tune the whole network")
    return TrainConfig(**vars(p.parse_args(argv)))


if __name__ == "__main__":
    fit(parse_args())

