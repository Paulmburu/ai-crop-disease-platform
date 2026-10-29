"""How the learning rate changes convergence: too small, good, near the edge, too large.

For this data (X ~ N(0, 1)) the MSE curvature is about 2, so plain gradient
descent is stable only while lr < ~1.0. lr=0.5 converges in very few steps;
lr=1.05 overshoots further on every step and diverges.

Run:  uv run python -m crop_ml.theory.lr_experiment
Out:  outputs/plots/learning_rate_comparison.png
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

from crop_ml.theory.gradient_descent import PLOTS_DIR, generate_data, train  # noqa: E402

EXPERIMENTS = {
    "lr=0.001 (too small)": 0.001,
    "lr=0.05 (good)": 0.05,
    "lr=0.5 (fast, still stable)": 0.5,
    "lr=1.05 (too large: diverges)": 1.05,
}


def run_all(epochs: int = 60) -> dict[str, list[float]]:
    """Train once per learning rate and return each loss history."""
    X, y = generate_data()
    return {label: train(X, y, lr=lr, epochs=epochs, verbose=False)[2] for label, lr in EXPERIMENTS.items()}


def plot(histories: dict[str, list[float]], save_dir: Path = PLOTS_DIR) -> Path:
    """Plot every history on one log-scale chart (clipped so divergence stays readable)."""
    save_dir.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(10, 4))
    for label, losses in histories.items():
        ax.plot([min(v, 1e3) for v in losses], label=label)
    ax.set(xlabel="Epoch", ylabel="MSE (clipped at 1000, log)", yscale="log",
           title="Effect of learning rate on convergence")
    ax.legend()
    path = save_dir / "learning_rate_comparison.png"
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    return path


if __name__ == "__main__":
    histories = run_all()
    for label, losses in histories.items():
        print(f"{label:32s} final loss = {losses[-1]:.4g}")
    print(f"Saved -> {plot(histories)}")
