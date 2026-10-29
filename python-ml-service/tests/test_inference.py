"""Unit tests for InferenceService (no HTTP)."""

import pytest
import torch

from app.services.inference import (
    InferenceService,
    InvalidImageError,
    ModelNotLoadedError,
    build_preprocess,
    parse_class_name,
)

from .conftest import CLASS_NAMES, image_bytes, make_checkpoint


def test_load_reads_phase1_contract(loaded_service):
    assert loaded_service.class_names == CLASS_NAMES
    assert loaded_service.model_version == "v1"
    assert loaded_service.image_size == 224


def test_confidences_are_probabilities(loaded_service):
    result = loaded_service.predict(image_bytes(), top_k=10)
    assert len(result.top_k) == len(CLASS_NAMES)  # top_k capped at number of classes
    assert sum(s.confidence for s in result.top_k) == pytest.approx(1.0, abs=1e-3)


def test_predict_before_load_raises(tmp_path):
    with pytest.raises(ModelNotLoadedError):
        InferenceService(tmp_path / "x.pt").predict(image_bytes())


def test_load_missing_checkpoint_explains_fix(tmp_path):
    with pytest.raises(FileNotFoundError, match="ml-training"):
        InferenceService(tmp_path / "x.pt").load()


def test_invalid_bytes_raise_invalid_image(loaded_service):
    with pytest.raises(InvalidImageError):
        loaded_service.predict(b"\x00\x01garbage")


def test_preprocess_matches_phase1_eval_pipeline():
    """Phase 1 eval: Resize(256) -> CenterCrop(224) -> [0,1] float -> ImageNet normalise."""
    from PIL import Image

    img = Image.new("RGB", (400, 300), (255, 0, 0))
    t = build_preprocess(224, [0.485, 0.456, 0.406], [0.229, 0.224, 0.225])(img)
    assert t.shape == (3, 224, 224) and t.dtype == torch.float32
    assert t[0, 0, 0].item() == pytest.approx((1.0 - 0.485) / 0.229, abs=1e-4)  # pure red pixel


def test_parse_class_name_matches_phase1():
    assert parse_class_name("Pepper__bell___Bacterial_spot") == ("Pepper bell", "Bacterial spot")
    assert parse_class_name("Tomato__Target_Spot") == ("Tomato", "Target Spot")
    assert parse_class_name("Tomato_healthy") == ("Tomato", "healthy")


def test_any_class_count_loads(tmp_path):
    names = [f"Plant___c{i}" for i in range(15)]
    service = InferenceService(make_checkpoint(tmp_path / "m.pt", names))
    service.load()
    assert len(service.predict(image_bytes(), top_k=3).top_k) == 3
