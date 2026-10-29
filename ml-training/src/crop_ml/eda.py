"""Exploratory data analysis: what is in the dataset before we train on it.

Run (from ml-training/, after downloading the data):
    uv run python -m crop_ml.eda

Writes:
    data/metadata.csv                    one row per image (path, class, plant, condition, size)
    outputs/plots/class_distribution.png images per class (shows the imbalance)
    outputs/plots/image_sizes.png        width/height spread
    outputs/plots/sample_grid.png        one example image per class
"""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402
from PIL import Image  # noqa: E402

from crop_ml.config import TrainConfig  # noqa: E402
from crop_ml.data import scan_images  # noqa: E402


def add_image_sizes(df: pd.DataFrame) -> pd.DataFrame:
    """Add width/height columns (reads only the image header, so it is fast)."""
    sizes = [Image.open(p).size for p in df["path"]]
    return df.assign(width=[w for w, _ in sizes], height=[h for _, h in sizes])


def class_summary(df: pd.DataFrame) -> pd.DataFrame:
    """Images per class, largest first, with share of the dataset."""
    counts = df.groupby("class_name").size().sort_values(ascending=False).rename("images").to_frame()
    counts["share_%"] = (100 * counts["images"] / counts["images"].sum()).round(1)
    return counts


def plot_class_distribution(summary: pd.DataFrame, path: Path) -> None:
    fig, ax = plt.subplots(figsize=(10, 6))
    summary["images"].sort_values().plot.barh(ax=ax, color="seagreen")
    ax.set(xlabel="Images", ylabel="", title="Images per class")
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def plot_image_sizes(df: pd.DataFrame, path: Path) -> None:
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(df["width"], df["height"], s=4, alpha=0.3)
    ax.set(xlabel="Width (px)", ylabel="Height (px)", title="Image dimensions")
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)


def plot_sample_grid(df: pd.DataFrame, path: Path, cols: int = 5) -> None:
    """One random image from every class, titled with its class name."""
    samples = df.groupby("class_name").sample(n=1, random_state=0)
    rows = -(-len(samples) // cols)  # ceiling division
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 3, rows * 3.2))
    for ax in axes.flat:
        ax.axis("off")
    for ax, (_, r) in zip(axes.flat, samples.iterrows(), strict=False):
        ax.imshow(Image.open(r["path"]).convert("RGB"))
        ax.set_title(f"{r['plant']}\n{r['condition']}", fontsize=8)  # title still shows with axis off
    fig.savefig(path, dpi=120, bbox_inches="tight")
    plt.close(fig)


def run(data_dir: Path, output_dir: Path, metadata_csv: Path) -> pd.DataFrame:
    df = add_image_sizes(scan_images(data_dir))
    summary = class_summary(df)
    print(summary.to_string())
    print(f"\n{len(df)} images, {len(summary)} classes, "
          f"imbalance (largest/smallest) = {summary['images'].max() / summary['images'].min():.1f}x")

    plots = output_dir / "plots"
    plots.mkdir(parents=True, exist_ok=True)
    plot_class_distribution(summary, plots / "class_distribution.png")
    plot_image_sizes(df, plots / "image_sizes.png")
    plot_sample_grid(df, plots / "sample_grid.png")
    metadata_csv.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(metadata_csv, index=False)
    print(f"Saved plots -> {plots}/ and metadata -> {metadata_csv}")
    return df


if __name__ == "__main__":
    d = TrainConfig()
    p = argparse.ArgumentParser(description="Explore the PlantVillage dataset.")
    p.add_argument("--data-dir", type=Path, default=d.data_dir)
    p.add_argument("--output-dir", type=Path, default=d.output_dir)
    p.add_argument("--metadata-csv", type=Path, default=Path("data/metadata.csv"))
    a = p.parse_args()
    run(a.data_dir, a.output_dir, a.metadata_csv)
