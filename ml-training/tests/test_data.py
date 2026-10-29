import pytest
import torch

from crop_ml.config import TrainConfig
from crop_ml.data import (
    build_dataloaders,
    make_balanced_sampler,
    parse_class_name,
    scan_images,
    split_dataset,
)

from .conftest import CLASSES


@pytest.mark.parametrize(("folder", "expected"), [
    ("Pepper__bell___Bacterial_spot", ("Pepper bell", "Bacterial spot")),
    ("Potato___Early_blight", ("Potato", "Early blight")),
    ("Tomato__Target_Spot", ("Tomato", "Target Spot")),
    ("Tomato__Tomato_YellowLeaf__Curl_Virus", ("Tomato", "Tomato YellowLeaf Curl Virus")),
    ("Tomato_Bacterial_spot", ("Tomato", "Bacterial spot")),
    ("Tomato_healthy", ("Tomato", "healthy")),
])
def test_parse_class_name(folder, expected):
    assert parse_class_name(folder) == expected


def test_scan_counts_mixed_case_extensions_and_skips_non_images(tiny_dataset):
    df = scan_images(tiny_dataset)
    assert len(df) == sum(CLASSES.values())
    assert sorted(df["class_name"].unique()) == sorted(CLASSES)


def test_folders_without_images_are_not_classes(tiny_dataset, tmp_path):
    import shutil

    root = tmp_path / "pv"
    shutil.copytree(tiny_dataset, root)
    (root / "PlantVillage" / "nested").mkdir(parents=True)  # like the duplicate folder in the Kaggle zip
    df = scan_images(root)
    assert sorted(df["class_name"].unique()) == sorted(CLASSES)
    assert sorted(df["label"].unique()) == list(range(len(CLASSES)))  # no gaps in label indices


def test_split_is_disjoint_and_stratified(tiny_dataset):
    s = split_dataset(scan_images(tiny_dataset), 0.15, 0.10, seed=42)
    paths = [set(x["path"]) for x in (s.train, s.val, s.test)]
    assert not (paths[0] & paths[1] or paths[0] & paths[2] or paths[1] & paths[2])
    assert sum(len(p) for p in paths) == sum(CLASSES.values())
    for part in (s.val, s.test):  # every class present in the small splits too
        assert part["label"].nunique() == len(CLASSES)


def test_split_round_trips_through_json(tiny_dataset, tmp_path):
    s = split_dataset(scan_images(tiny_dataset), 0.15, 0.10, seed=42)
    s.save(tmp_path / "splits.json")
    loaded = type(s).load(tmp_path / "splits.json")
    assert loaded.test["path"].tolist() == s.test["path"].tolist()
    assert loaded.class_names == s.class_names


def test_sampler_only_indexes_train_set():
    labels = [0] * 90 + [1] * 10
    idx = list(make_balanced_sampler(labels))
    assert max(idx) < len(labels)
    share_rare = sum(labels[i] == 1 for i in idx) / len(idx)
    assert 0.3 < share_rare < 0.7  # rare class drawn about as often as the common one


def test_train_loader_augments_and_eval_loader_does_not(tiny_dataset):
    cfg = TrainConfig(data_dir=tiny_dataset, image_size=32, batch_size=4, num_workers=0)
    loaders = build_dataloaders(cfg, split_dataset(scan_images(tiny_dataset), 0.15, 0.10, 42))
    ds_train, ds_val = loaders["train"].dataset, loaders["val"].dataset
    assert ds_train.transform is not ds_val.transform
    images, _ = next(iter(loaders["val"]))
    assert images.shape[1:] == (3, 32, 32) and images.dtype == torch.float32
    # Same val image twice -> identical; same train image twice -> differs (random augmentation).
    assert torch.equal(ds_val[0][0], ds_val[0][0])
    assert not torch.equal(ds_train[0][0], ds_train[0][0])
