"""End-to-end smoke test: train 2 epochs on the tiny dataset, then evaluate."""

import json

import torch

from crop_ml.config import TrainConfig
from crop_ml.evaluate import evaluate
from crop_ml.mismatch import run as mismatch_run
from crop_ml.model import build_model
from crop_ml.theory.gradient_descent import generate_data, train
from crop_ml.train import fit

from .conftest import CLASSES

CONTRACT_KEYS = {"model_state_dict", "num_classes", "class_names", "model_version",
                 "val_acc", "image_size", "mean", "std", "confidence_threshold"}


def test_model_outputs_one_logit_per_class():
    model = build_model(5, pretrained=False).eval()
    assert model(torch.zeros(2, 3, 64, 64)).shape == (2, 5)


def test_frozen_backbone_trains_only_head():
    model = build_model(3, pretrained=False, freeze_backbone=True)
    trainable = {n for n, p in model.named_parameters() if p.requires_grad}
    assert trainable == {"classifier.1.weight", "classifier.1.bias"}


def test_gradient_descent_recovers_true_line():
    w, b, losses = train(*generate_data(), lr=0.05, epochs=200, verbose=False)
    assert abs(w - 3) < 0.15 and abs(b - 2) < 0.15 and losses[-1] < losses[0]


def test_fit_then_evaluate_writes_contract_artifacts(tiny_dataset, tmp_path):
    cfg = TrainConfig(data_dir=tiny_dataset, output_dir=tmp_path, image_size=32, batch_size=8,
                      epochs=2, num_workers=0, pretrained=False)
    history = fit(cfg)
    assert len(history["val_loss"]) >= 1

    ckpt = torch.load(cfg.checkpoint_path, weights_only=True)
    assert CONTRACT_KEYS <= ckpt.keys()
    assert ckpt["class_names"] == sorted(CLASSES)
    assert json.loads((cfg.checkpoint_dir / "class_names.json").read_text()) == sorted(CLASSES)

    summary = evaluate(cfg.checkpoint_path, tmp_path / "splits.json", tmp_path, num_workers=0)
    assert set(summary["per_class"]) == set(CLASSES)
    assert (tmp_path / "plots" / "confusion_matrix.png").exists()
    assert 0.5 <= ckpt["confidence_threshold"] <= 1.0
    assert "test_coverage" in summary

    results = mismatch_run(cfg.checkpoint_path, tmp_path / "splits.json", tmp_path / "mismatch.json", num_workers=2)
    assert set(results) == {"correct", "stretch", "no_scale", "bgr"}
