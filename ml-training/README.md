# ml-training (Phase 1)

PlantVillage data pipeline and a MobileNetV2 baseline for crop disease classification.
The checkpoint this project produces is served by `../python-ml-service` (Phase 2).
Full walkthrough: [`docs/PHASE_1_ML_THEORY_AND_DATA.md`](../docs/PHASE_1_ML_THEORY_AND_DATA.md).

```
src/crop_ml/
  config.py      all settings (TrainConfig) + ImageNet mean/std
  data.py        scan images, parse class names, stratified split, DataLoaders, balanced sampler
  transforms.py  train (augmenting) and eval (deterministic) pipelines
  model.py       MobileNetV2 with a new classification head
  train.py       CLI: training loop, early stopping, checkpoint
  evaluate.py    CLI: test-set report, confusion matrix, eval_summary.json
  eda.py         CLI: class distribution, image sizes, sample grid, metadata.csv
  theory/        week 1: gradient descent, learning-rate experiment, loss functions
notebooks/       thin notebooks that call the modules above
tests/           runs on a tiny synthetic dataset (no download needed)
```

## Setup (once)

```bash
cd ml-training
uv sync                                   # creates .venv with Python 3.11 + all deps (from uv.lock)
uv run pytest                             # 20 tests, ~30 s, no dataset needed
uv run python -m ipykernel install --user --name crop-ml --display-name "crop-ml (ml-training)"
```

## Get the dataset

1. Create a free Kaggle account at kaggle.com.
2. Log in from the terminal and download (zip ≈690 MB; 15 classes, 20,638 images):

```bash
uv run kaggle auth login                     # opens a browser; approve access
uv run kaggle datasets download -d emmarex/plantdisease -p data/ --unzip
ls data/PlantVillage | head                  # 15 class folders (+ a nested duplicate the code ignores)
```

### Potato demo (presentation)

```bash
mkdir -p data/potato
for c in Potato___Early_blight Potato___Late_blight Potato___healthy; do
  ln -sfn "$PWD/data/PlantVillage/$c" "data/potato/$c"
done
uv run python -m crop_ml.train --data-dir data/potato    # ~40 s; then evaluate / mismatch as below
```

Potato v1: test accuracy 95.8%, macro F1 0.945, confidence threshold 0.50.

## Run, in order

| Step | Command | Output |
|---|---|---|
| Theory | `uv run python -m crop_ml.theory.gradient_descent` | `outputs/plots/gradient_descent.png` |
| | `uv run python -m crop_ml.theory.lr_experiment` | `outputs/plots/learning_rate_comparison.png` |
| | `uv run python -m crop_ml.theory.loss_functions` | printed comparison |
| EDA | `uv run python -m crop_ml.eda` | `outputs/plots/*.png`, `data/metadata.csv` |
| Train | `uv run python -m crop_ml.train` | `outputs/checkpoints/mobilenetv2_v1_best.pt`, `class_names.json`, `history.json`, `outputs/splits.json` |
| Evaluate | `uv run python -m crop_ml.evaluate` | `outputs/plots/confusion_matrix.png`, `outputs/eval_summary.json` |
| Mismatch | `uv run python -m crop_ml.mismatch` | `outputs/mismatch.json`: accuracy under 3 preprocessing bugs |
| Hand off | `cp outputs/checkpoints/{mobilenetv2_v1_best.pt,class_names.json} ../python-ml-service/models/` | Phase 2 input |

`uv run python -m crop_ml.train --help` lists all flags (`--epochs`, `--batch-size`, `--unfreeze`, ...).
Notebooks: `uv run jupyter lab`, then pick the **crop-ml** kernel.

## Checkpoint contract (Phase 1 → Phase 2)

`mobilenetv2_<version>_best.pt` is a dict with exactly these keys, and Phase 2 depends on them:

| Key | Meaning |
|---|---|
| `model_state_dict` | MobileNetV2 weights |
| `num_classes`, `class_names` | label index → folder name (sorted order) |
| `model_version` | e.g. `v1` |
| `val_acc` | best validation accuracy |
| `image_size`, `mean`, `std` | eval preprocessing the service must reproduce |

## Troubleshooting

- **`Dataset folder not found`**: pass `--data-dir` pointing at the folder that *contains* the class folders.
- **DataLoader hangs in Jupyter**: use `TrainConfig(num_workers=0)`.
- **Slow first run**: ImageNet weights (~14 MB) download once into `~/.cache/torch`.
- **Test accuracy looks too good (>97%)**: PlantVillage has near-duplicate photos of the same leaf, so
  test scores are optimistic. Expect lower accuracy on real field photos.
