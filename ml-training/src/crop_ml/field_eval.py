"""How does the lab-trained model do on real field photos?

PlantVillage (training data) shows single leaves on plain backgrounds. PlantDoc
(Singh et al., 2020, CC BY 4.0) has photos taken in the field: whole plants, soil,
shadows, several leaves. This scores the potato model on PlantDoc's potato images
with the correct preprocessing, so the only thing that changes is the photos.

PlantDoc has no healthy-potato class, so this measures the two blights only, and
reports how often a diseased field leaf is called "healthy" (the costly mistake).

Get the data (only the potato folders, ~500 images) into data/plantdoc/{train,test}/<class>/,
then run (from ml-training/):
    uv run python -m crop_ml.field_eval
Writes outputs/field_eval.json.
"""

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
from torch.utils.data import DataLoader

from crop_ml.config import TrainConfig
from crop_ml.data import IMAGE_EXTENSIONS, LeafDataset
from crop_ml.evaluate import load_checkpoint, predict
from crop_ml.train import pick_device
from crop_ml.transforms import build_eval_transforms

# PlantDoc folder name -> our class name (the model's label)
PLANTDOC_TO_OURS = {
    "Potato leaf early blight": "Potato___Early_blight",
    "Potato leaf late blight": "Potato___Late_blight",
}


def scan_plantdoc(root: Path, class_names: list[str]) -> pd.DataFrame:
    """All mapped images under root/<split>/<PlantDoc class>/ with our integer labels."""
    rows = []
    for split_dir in sorted(p for p in root.iterdir() if p.is_dir()):
        for folder, ours in PLANTDOC_TO_OURS.items():
            for f in sorted((split_dir / folder).glob("*")) if (split_dir / folder).is_dir() else []:
                if f.suffix.lower() in IMAGE_EXTENSIONS:
                    rows.append({"path": str(f), "label": class_names.index(ours), "class_name": ours})
    if not rows:
        raise FileNotFoundError(f"No PlantDoc potato images under {root}")
    return pd.DataFrame(rows)


def run(checkpoint: Path, root: Path, out: Path, num_workers: int = 2) -> dict:
    device = pick_device()
    model, ckpt = load_checkpoint(checkpoint, device)
    names: list[str] = ckpt["class_names"]
    df = scan_plantdoc(root, names)
    tf = build_eval_transforms(ckpt["image_size"], tuple(ckpt["mean"]), tuple(ckpt["std"]))
    y_true, y_pred, conf = predict(model, DataLoader(LeafDataset(df, tf), batch_size=64,
                                                     num_workers=num_workers), device)
    threshold = float(ckpt.get("confidence_threshold", 0.5))
    kept = conf >= threshold
    healthy = names.index("Potato___healthy") if "Potato___healthy" in names else -1

    per_class = {}
    for name in PLANTDOC_TO_OURS.values():
        idx = names.index(name)
        mask = y_true == idx
        per_class[name] = {
            "images": int(mask.sum()),
            "recall": float((y_pred[mask] == idx).mean()),
            "called_healthy": float((y_pred[mask] == healthy).mean()),
            "predicted_counts": np.bincount(y_pred[mask], minlength=len(names)).tolist(),
        }
    summary = {
        "images": int(len(y_true)),
        "accuracy": float((y_true == y_pred).mean()),
        "called_healthy": float((y_pred == healthy).mean()),
        "confidence_threshold": threshold,
        "answered": float(kept.mean()),
        "accuracy_when_answered": float((y_true[kept] == y_pred[kept]).mean()) if kept.any() else None,
        "mean_confidence": float(conf.mean()),
        "per_class": per_class,
        "class_names": names,
    }
    out.write_text(json.dumps(summary, indent=2))
    print(f"PlantDoc potato field photos: {summary['images']}")
    print(f"accuracy {summary['accuracy']:.1%} | diseased leaves called healthy {summary['called_healthy']:.1%} | "
          f"answered at threshold {summary['answered']:.1%}, of those correct "
          f"{summary['accuracy_when_answered'] or 0:.1%} | mean confidence {summary['mean_confidence']:.2f}")
    for name, r in per_class.items():
        print(f"  {name:24s} n={r['images']:3d} recall {r['recall']:.1%} called healthy {r['called_healthy']:.1%} "
              f"predictions {r['predicted_counts']}")
    print(f"Saved -> {out}")
    return summary


if __name__ == "__main__":
    d = TrainConfig()
    p = argparse.ArgumentParser(description="Score the model on PlantDoc field photos.")
    p.add_argument("--checkpoint", type=Path, default=d.checkpoint_path)
    p.add_argument("--plantdoc-dir", type=Path, default=Path("data/plantdoc"))
    p.add_argument("--out", type=Path, default=d.output_dir / "field_eval.json")
    p.add_argument("--num-workers", type=int, default=d.num_workers)
    a = p.parse_args()
    run(a.checkpoint, a.plantdoc_dir, a.out, a.num_workers)
