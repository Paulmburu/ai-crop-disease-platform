import pytest
from PIL import Image

from crop_ml.field_eval import PLANTDOC_TO_OURS, scan_plantdoc

NAMES = ["Potato___Early_blight", "Potato___Late_blight", "Potato___healthy"]


def test_mapping_targets_are_model_labels():
    assert set(PLANTDOC_TO_OURS.values()) <= set(NAMES)


def test_scan_maps_folders_to_model_labels(tmp_path):
    for split in ("train", "test"):
        for folder in (*PLANTDOC_TO_OURS, "Tomato leaf"):  # unmapped folders are ignored
            d = tmp_path / split / folder
            d.mkdir(parents=True)
            Image.new("RGB", (8, 8)).save(d / "a.JPG")
            (d / "notes.txt").write_text("x")
    df = scan_plantdoc(tmp_path, NAMES)
    assert len(df) == 4  # 2 splits x 2 mapped classes, non-images skipped
    assert sorted(df["label"].unique()) == [0, 1]


def test_scan_without_images_is_an_error(tmp_path):
    (tmp_path / "train").mkdir()
    with pytest.raises(FileNotFoundError):
        scan_plantdoc(tmp_path, NAMES)
