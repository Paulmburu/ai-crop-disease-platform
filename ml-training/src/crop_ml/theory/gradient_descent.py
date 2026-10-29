"""Linear regression trained with hand-written gradient descent.

Week 1 theory exercise: every moving part of training (forward pass, loss,
gradients, update) is visible before PyTorch hides it.

Run:  uv run python -m crop_ml.theory.gradient_descent
Out:  outputs/plots/gradient_descent.png
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # write PNGs without needing a GUI window
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

PLOTS_DIR = Path("outputs/plots")


def generate_data(n: int = 100, seed: int = 42) -> tuple[np.ndarray, np.ndarray]:
    """Return X, y with a known relationship y = 3x + 2 plus noise.

    Knowing the true answer (w=3, b=2) lets us check that training works.
    """
    rng = np.random.default_rng(seed)
    X = rng.standard_normal(n)
    y = 3 * X + 2 + rng.standard_normal(n) * 0.5
    return X, y


def forward(X: np.ndarray, w: float, b: float) -> np.ndarray:
    """Forward pass: the model is just a line."""
    return w * X + b


def mse_loss(y_pred: np.ndarray, y_true: np.ndarray) -> float:
    """Mean squared error. Squaring removes signs and punishes big misses."""
    return float(np.mean((y_pred - y_true) ** 2))


def compute_gradients(
    X: np.ndarray, y_pred: np.ndarray, y_true: np.ndarray
) -> tuple[float, float]:
    """Partial derivatives of MSE with respect to w and b (chain rule).

    dL/dw = 2 * mean(X * error)      dL/db = 2 * mean(error)
    """
    error = y_pred - y_true
    return float(2 * np.mean(X * error)), float(2 * np.mean(error))


def train(
    X: np.ndarray, y: np.ndarray, lr: float = 0.05, epochs: int = 200, verbose: bool = True
) -> tuple[float, float, list[float]]:
    """Run full-batch gradient descent. Returns (w, b, loss history)."""
    w, b = 0.0, 0.0
    losses: list[float] = []
    for epoch in range(epochs):
        y_pred = forward(X, w, b)  # 1. predict
        loss = mse_loss(y_pred, y)  # 2. measure error
        losses.append(loss)
        dw, db = compute_gradients(X, y_pred, y)  # 3. which way is downhill?
        w -= lr * dw  # 4. step downhill
        b -= lr * db
        if verbose and epoch % 20 == 0:
            print(f"Epoch {epoch:3d} | Loss: {loss:.4f} | w={w:.3f} b={b:.3f}")
    return w, b, losses


def plot_results(
    X: np.ndarray, y: np.ndarray, w: float, b: float, losses: list[float], save_dir: Path = PLOTS_DIR
) -> Path:
    """Save the fitted line and the loss curve side by side. Returns the file path."""
    save_dir.mkdir(parents=True, exist_ok=True)
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))

    axes[0].scatter(X, y, alpha=0.5, label="Data", color="steelblue")
    x_line = np.linspace(X.min(), X.max(), 100)
    axes[0].plot(x_line, w * x_line + b, color="tomato", lw=2, label=f"Fit: y={w:.2f}x+{b:.2f}")
    axes[0].set(title="Fitted line", xlabel="X", ylabel="y")
    axes[0].legend()

    axes[1].plot(losses, color="steelblue")
    axes[1].set(title="Loss convergence", xlabel="Epoch", ylabel="MSE (log scale)", yscale="log")

    path = save_dir / "gradient_descent.png"
    fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    return path


if __name__ == "__main__":
    X, y = generate_data()
    w, b, losses = train(X, y)
    print(f"\nLearned: w={w:.3f}, b={b:.3f}  (true: w=3.0, b=2.0)")
    print(f"Saved plot -> {plot_results(X, y, w, b, losses)}")
