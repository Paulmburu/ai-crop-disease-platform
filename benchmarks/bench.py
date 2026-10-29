# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = ["ai-edge-litert", "numpy", "httpx"]
# ///
"""Benchmarks for the talk: is on-device inference worth it?

Run from the repo root (services running for D3/D4; see README sections):
    uv run benchmarks/bench.py --image path/to/leaf.JPG

Measures:
    D1  model size: .pt checkpoint vs .tflite
    D2  LiteRT inference latency on THIS machine (phone numbers come from the app later)
    D3  backend /predict: measured server time on localhost, plus the time a phone would
        spend uploading the measured test photo and a typical phone photo (modelled, see NETWORKS)
    D4  RAG /ask latency: first call vs warm calls

Writes benchmarks/results.md.
"""

import argparse
import time
from pathlib import Path

import httpx
import numpy as np

ROOT = Path(__file__).resolve().parent.parent

# Network profiles used to model upload time: (uplink kbit/s, round-trip ms).
# These are assumptions for illustration, not measurements; edit them to match
# the networks your users actually have. Real phone measurements come in Stage E.
NETWORKS = {
    "Wi-Fi": (20_000, 20),
    "4G": (5_000, 60),
    "3G": (750, 200),
    "2G (EDGE)": (100, 600),
}


def pct(values: list[float], q: float) -> float:
    return float(np.percentile(values, q))


def fmt_ms(v: float) -> str:
    return f"{v:,.0f} ms" if v >= 10 else f"{v:.1f} ms"


def d1_sizes() -> list[str]:
    pt = ROOT / "python-ml-service/models/mobilenetv2_v1_best.pt"
    tfl = ROOT / "python-ml-service/models/crop_disease_v1.tflite"
    rows = ["## D1 Model size", "", "| File | Size |", "|---|---|"]
    for p in (pt, tfl):
        rows.append(f"| `{p.name}` | {p.stat().st_size / 1e6:.1f} MB |" if p.exists() else f"| `{p.name}` | missing |")
    return rows


def d2_litert(runs: int) -> list[str]:
    from ai_edge_litert.interpreter import Interpreter

    model = ROOT / "python-ml-service/models/crop_disease_v1.tflite"
    interp = Interpreter(model_path=str(model))
    interp.allocate_tensors()
    inp = interp.get_input_details()[0]
    x = np.random.rand(*inp["shape"]).astype(np.float32)
    times = []
    for i in range(runs + 5):
        start = time.perf_counter()
        interp.set_tensor(inp["index"], x)
        interp.invoke()
        if i >= 5:  # skip warm-up runs
            times.append((time.perf_counter() - start) * 1000)
    return ["## D2 On-device inference (LiteRT, this laptop CPU)", "",
            f"{runs} runs, input {inp['shape'].tolist()}: p50 **{fmt_ms(pct(times, 50))}**, "
            f"p95 {fmt_ms(pct(times, 95))}.", "",
            "No network involved, so this is the whole cost of a diagnosis on the device."]


def d3_backend(image: bytes, runs: int, base: str, phone_photo_mb: float) -> list[str]:
    times = []
    with httpx.Client(base_url=base, timeout=30) as c:
        for i in range(runs + 3):
            start = time.perf_counter()
            r = c.post("/api/v1/predict", files={"file": ("leaf.jpg", image, "image/jpeg")})
            r.raise_for_status()
            if i >= 3:
                times.append((time.perf_counter() - start) * 1000)
    server = pct(times, 50)
    payloads = {f"Test photo ({len(image) / 1024:.0f} KB, measured)": len(image),
                f"Phone photo ({phone_photo_mb:g} MB, assumed)": int(phone_photo_mb * 1024 * 1024)}

    def total(size: int, kbps: int, rtt: int) -> float:
        return size * 8 / (kbps * 1000) * 1000 + rtt + server

    rows = ["## D3 Backend /predict", "",
            f"Server time measured on localhost ({runs} requests): p50 **{fmt_ms(server)}**, "
            f"p95 {fmt_ms(pct(times, 95))}.", "",
            "Modelled time for a phone to get a diagnosis from the backend "
            "(upload + round trip + server time; network profiles are assumptions):", "",
            "| Network | Uplink | RTT | " + " | ".join(payloads) + " |",
            "|---|---|---|" + "---|" * len(payloads)]
    for name, (kbps, rtt) in NETWORKS.items():
        cells = " | ".join(f"**{fmt_ms(total(size, kbps, rtt))}**" for size in payloads.values())
        rows.append(f"| {name} | {kbps:,} kbit/s | {rtt} ms | {cells} |")
    rows += ["", "Compare with D2: on-device inference needs no upload at all."]
    return rows


def d4_rag(base: str, warm_runs: int) -> list[str]:
    body = {"question": "What should I do about this?", "class_name": "Potato___Late_blight"}
    times = []
    with httpx.Client(base_url=base, timeout=300) as c:
        for _ in range(warm_runs + 1):
            start = time.perf_counter()
            c.post("/api/v1/ask", json=body).raise_for_status()
            times.append((time.perf_counter() - start) * 1000)
    return ["## D4 RAG /ask (local Ollama)", "",
            f"First call: **{fmt_ms(times[0])}** (includes loading the model if Ollama was idle). "
            f"Warm calls ({warm_runs}): p50 **{fmt_ms(pct(times[1:], 50))}**.", "",
            "This is why advice is an online add-on and never blocks the diagnosis."]


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--image", type=Path, required=True, help="a leaf photo (JPEG)")
    p.add_argument("--ml-url", default="http://localhost:8000")
    p.add_argument("--rag-url", default="http://localhost:8001")
    p.add_argument("--runs", type=int, default=100)
    p.add_argument("--skip-rag", action="store_true")
    p.add_argument("--phone-photo-mb", type=float, default=3.0, help="assumed size of a typical phone photo")
    a = p.parse_args()
    image = a.image.read_bytes()

    sections = [["# Benchmark results", "",
                 f"Generated {time.strftime('%Y-%m-%d %H:%M')} on this machine. "
                 "Network figures in D3 are modelled from the stated profiles, not measured on a phone."],
                d1_sizes(), d2_litert(a.runs), d3_backend(image, a.runs, a.ml_url, a.phone_photo_mb)]
    if not a.skip_rag:
        sections.append(d4_rag(a.rag_url, warm_runs=5))
    text = "\n\n".join("\n".join(s) for s in sections) + "\n"
    out = ROOT / "benchmarks/results.md"
    out.write_text(text)
    print(text)
    print(f"Saved -> {out}")


if __name__ == "__main__":
    main()
