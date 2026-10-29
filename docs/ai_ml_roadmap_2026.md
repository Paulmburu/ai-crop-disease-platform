# AI/ML Learning Roadmap 2026
## Go + Python + Flutter + Android KMP Stack
**Goal:** Transition from Backend/Mobile Developer to AI/ML Engineer with a production-grade portfolio that positions you for trending Python AI/ML roles.

---

## Project Overview

**What you're building:** An end-to-end AI-powered crop disease detection platform — a multi-service system that combines:

- A **Python FastAPI ML service** that accepts an image and returns `{"class": "leaf blight", "confidence": 0.91}`
- A **Go API gateway** that handles uploads, auth, rate limiting, retries, and proxies to the Python service
- A **RAG chatbot** (Phase 3) that lets users ask "what causes this disease?" against a domain knowledge base
- A **Flutter mobile app** with offline-first TFLite on-device inference
- An **Android KMP module** that shares ML inference logic between Android and iOS natively

**Domain:** PlantVillage crop disease dataset — 54,000 images, 38 disease classes. Social-impact framing is a differentiator in portfolios and interviews.

**Why this project:** It covers the exact skills that appear in 2026 AI/ML job descriptions — RAG, model serving, production APIs, evaluation frameworks, Docker, CI/CD, and mobile AI. It produces answers to real interview questions at every phase. A Jupyter notebook with `model.predict()` tells interviewers nothing about how you build real systems. This project does the opposite.

---

## 2026 Priority Stack

| Priority | Phase | Why |
|---|---|---|
| 1 | Python fluency (Phase 0) | Non-negotiable foundation — assumed but not taught in most plans |
| 2 | ML theory + data (Phase 1) | Interviews probe loss functions, metrics, and data pipelines hard |
| 3 | FastAPI ML service (Phase 2) | Core production skill — model serving is table stakes |
| 4 | **RAG pipeline (Phase 6 → promoted)** | **Most in-demand AI skill of 2026 — do not treat as a bonus** |
| 5 | Go backend gateway (Phase 3) | Your existing strength — this phase will go faster than estimated |
| 6 | Production + CI/CD (Phase 5) | Turns the project from a demo into a portfolio artefact |
| 7 | Flutter mobile (Phase 4) | Nice differentiator — lowest ROI for pure AI/ML roles |
| 8 | Android KMP (Phase 7) | Strongest differentiator for mobile-AI crossover roles |

---

## Environment Setup

Complete this once before starting Phase 0. Everything here is required.

### System requirements

- macOS (M-series chip) — you are on an M5 MacBook with 16GB RAM, 1TB
- Homebrew installed
- Zsh with your existing `.zshrc` config

### Core tools

```bash
# Python — use pyenv to manage versions, never use system Python
brew install pyenv
pyenv install 3.11.9
pyenv global 3.11.9

# uv — fast Python package manager (replaces pip for new projects)
brew install uv

# Verify
python --version   # should show 3.11.9
uv --version

# Go — already installed, verify version
go version   # need 1.22+

# Docker Desktop — required for Phase 2 onwards
brew install --cask docker
# Launch Docker Desktop from Applications and let it finish setup

# Node.js — needed for some tooling
brew install node

# Android Studio — already installed
# Verify Flutter
flutter doctor

# Ollama — for local LLM in Phase 3 (RAG)
brew install ollama
ollama pull llama3.2   # 3B model, runs well on M5
```

### Python project setup pattern

Use this pattern for every Python service you create (Phase 2, Phase 3 RAG):

```bash
# Create project with uv
uv init my-ml-service
cd my-ml-service

# Create and activate virtual environment
uv venv
source .venv/bin/activate

# Install dependencies (uv is 10-100x faster than pip)
uv add fastapi uvicorn torch torchvision pillow pydantic

# Dev dependencies
uv add --dev pytest pytest-asyncio httpx mypy ruff

# Lock: uv writes uv.lock automatically on every `uv add`; commit it (no requirements.txt needed)
uv lock
```

### Go project setup pattern

```bash
mkdir go-gateway && cd go-gateway
go mod init github.com/yourusername/go-gateway

# Dependencies added as you need them
go get github.com/gin-gonic/gin
go get github.com/sirupsen/logrus
go get golang.org/x/time/rate
go get github.com/prometheus/client_golang/prometheus
```

### GitHub repository structure

Create one mono-repo for the entire project:

```
ai-crop-disease-platform/
├── python-ml-service/       # Phase 2 — FastAPI + model
├── go-gateway/              # Phase 4 — Go API
├── rag-service/             # Phase 3 — RAG pipeline
├── flutter-app/             # Phase 6 — Flutter mobile
├── android-kmp/             # Phase 7 — KMP shared module
├── docker-compose.yml       # runs all services locally
├── .github/workflows/       # CI/CD
├── ARCHITECTURE.md          # system diagram and decisions
└── README.md                # one-command setup guide
```

Commit daily. Set up branch protection on `main` from day one — it trains production habits.

---

## Phase 0 — Python Fluency
**Duration:** 2 weeks
**Goal:** Get Python-fluent fast using your existing Kotlin and Go background as a bridge.

Since you already know Kotlin and Go, skip beginner content entirely. Focus on what is *different* about Python.

### Setup for this phase

```bash
# Create a practice repo
mkdir python-foundations && cd python-foundations
uv init .
uv venv && source .venv/bin/activate
uv add mypy ruff ipython

# Open in VS Code or your editor
code .
```

### Week 1 — Syntax and idioms (Day 1–7)

**Day 1–3: Syntax blitz**

Things that look like Kotlin/Go but behave differently:

```python
# List comprehensions — Python's equivalent of Kotlin .map{}
squares = [x**2 for x in range(10)]                        # list
evens = {x for x in range(20) if x % 2 == 0}              # set
lookup = {k: v for k, v in zip(keys, values)}              # dict

# Unpacking — similar to Kotlin destructuring
first, *rest = [1, 2, 3, 4, 5]
a, b, c = (10, 20, 30)

# *args and **kwargs — no Kotlin equivalent, critical for FastAPI
def wrap(*args, **kwargs):
    print(args)    # tuple
    print(kwargs)  # dict

# f-strings (Python's string templates)
name = "Paul"
msg = f"Hello {name}, your score is {score:.2f}"
```

**Day 4–6: Python OOP vs Kotlin**

```python
from dataclasses import dataclass, field
from typing import Protocol

# Dataclass — like Kotlin data class
@dataclass
class Prediction:
    label: str
    confidence: float
    model_version: str = "v1"
    tags: list[str] = field(default_factory=list)

# Protocol — like Kotlin interface (structural typing, no explicit `implements`)
class Classifier(Protocol):
    def predict(self, image: bytes) -> Prediction: ...

# __dunder__ methods — like Kotlin operator overloading
class ImageBatch:
    def __init__(self, images: list):
        self.images = images

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        return self.images[idx]

    def __repr__(self):
        return f"ImageBatch({len(self.images)} images)"
```

**Day 7–9: Async Python**

The key mental model: Python's `asyncio` is single-threaded cooperative multitasking. Unlike Kotlin coroutines which can use multiple threads via Dispatchers, Python async runs on one thread unless you explicitly use `ThreadPoolExecutor` for CPU work.

```python
import asyncio
import httpx  # async HTTP client

# Basic async — like Kotlin suspend fun
async def fetch_prediction(image_url: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(image_url)
        return response.json()

# Run concurrent requests — like Kotlin async{} + awaitAll()
async def batch_predict(urls: list[str]) -> list[dict]:
    tasks = [fetch_prediction(url) for url in urls]
    return await asyncio.gather(*tasks)

# CPU-bound work must be offloaded — key difference from Kotlin
import asyncio
from concurrent.futures import ThreadPoolExecutor

executor = ThreadPoolExecutor(max_workers=4)

async def run_inference(image: bytes) -> dict:
    loop = asyncio.get_event_loop()
    # run_in_executor prevents blocking the event loop
    result = await loop.run_in_executor(executor, model.predict, image)
    return result
```

**Day 10–14: Type hints, decorators, context managers**

```python
from typing import Optional, Union, Generator
from contextlib import contextmanager

# Type hints with mypy
def process_image(
    data: bytes,
    size: tuple[int, int] = (224, 224),
    normalize: bool = True
) -> Optional[list[float]]:
    ...

# Decorators — used heavily in FastAPI
import functools
import time

def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.3f}s")
        return result
    return wrapper

@timer
def load_model(path: str):
    ...

# Context managers — like Kotlin use{}
@contextmanager
def model_session() -> Generator:
    session = create_session()
    try:
        yield session
    finally:
        session.close()

with model_session() as sess:
    result = sess.predict(image)
```

### Week 2 — Output

Build a Python CLI tool that does something you would normally write in Go:

```bash
# Suggested: a file-processing CLI that reads a folder of images,
# reports their dimensions and file sizes, and outputs a JSON summary

uv add pillow click rich

# cli.py using Click (Python's equivalent of cobra/urfave-cli)
import click
from pathlib import Path
from PIL import Image
import json

@click.command()
@click.argument("folder", type=click.Path(exists=True))
@click.option("--output", "-o", default="report.json")
def analyse(folder: str, output: str):
    """Analyse images in FOLDER and write a JSON report."""
    results = []
    for path in Path(folder).glob("**/*.jpg"):
        img = Image.open(path)
        results.append({"file": str(path), "size": path.stat().st_size, "dims": img.size})
    Path(output).write_text(json.dumps(results, indent=2))
    click.echo(f"Wrote {len(results)} entries to {output}")

if __name__ == "__main__":
    analyse()
```

### Resources

| Resource | Type | Why |
|---|---|---|
| [Python Crash Course, 3rd Ed.](https://nostarch.com/pythoncrashcourse3) | Book | Ch. 1–10 only — fast ramp for existing programmers |
| [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/) | Docs | Teaches async Python naturally through real API code |
| [mypy cheat sheet](https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html) | Reference | Type hints — essential for production Python |
| [Ruff docs](https://docs.astral.sh/ruff/) | Tool | Linter + formatter — replaces flake8 + black |
| [Real Python: Python vs Java](https://realpython.com/python-vs-javascript/) | Article | Python idioms for typed-language developers |

### Learning outcomes

- Write idiomatic Python (comprehensions, unpacking, f-strings)
- Async/await and when to offload to ThreadPoolExecutor
- Type hints + mypy for production code
- Decorators and context managers
- Click CLI tooling

---

## Phase 1 — ML Theory + Data Foundations
**Duration:** 2 weeks
**Goal:** Understand *why* models work, not just how to run them. Build intuition before touching frameworks.

### Setup for this phase

```bash
mkdir ml-foundations && cd ml-foundations
uv init .
uv venv && source .venv/bin/activate

# Core ML stack
uv add numpy pandas matplotlib seaborn scikit-learn jupyter torch torchvision

# Launch Jupyter
jupyter notebook
```

### Week 1 — Math intuition (no heavy calculus required)

**Linear regression from scratch:**

```python
import numpy as np
import matplotlib.pyplot as plt

# Generate synthetic data
np.random.seed(42)
X = np.random.randn(100, 1)
y = 3 * X.squeeze() + 2 + np.random.randn(100) * 0.5

# Manual gradient descent — implement once to build intuition
def linear_regression_gd(X, y, lr=0.01, epochs=1000):
    w, b = 0.0, 0.0
    losses = []
    for epoch in range(epochs):
        y_pred = X * w + b
        loss = np.mean((y_pred - y) ** 2)      # MSE loss
        dw = 2 * np.mean(X * (y_pred - y))     # gradient w.r.t. w
        db = 2 * np.mean(y_pred - y)           # gradient w.r.t. b
        w -= lr * dw
        b -= lr * db
        losses.append(loss)
    return w, b, losses

w, b, losses = linear_regression_gd(X.squeeze(), y)
# Plot loss curve — visualising convergence is the point
plt.plot(losses)
plt.xlabel("Epoch")
plt.ylabel("MSE Loss")
plt.title("Loss convergence")
plt.savefig("loss_curve.png")
```

**Loss function intuition — know when to use which:**

| Loss function | Use when | Formula (concept) |
|---|---|---|
| MSE | Regression — penalises large errors heavily | mean((pred - true)²) |
| MAE | Regression — more robust to outliers | mean(abs(pred - true)) |
| Cross-entropy | Classification | -sum(true * log(pred)) |
| Binary cross-entropy | Binary classification | same, for 0/1 labels |

**Complete fast.ai Lesson 1** — it is the best single resource for building ML intuition without drowning in calculus. It pitches directly at practitioners.

### Week 2 — Data work

This is where 60–70% of real ML job time goes. Most tutorials skip it.

```bash
# Download PlantVillage dataset from Kaggle (you will use this in Phase 2)
pip install kaggle
# Place your kaggle.json API token at ~/.kaggle/kaggle.json
kaggle datasets download -d emmarex/plantdisease
unzip plantdisease.zip -d data/
```

**Pandas on real messy data:**

```python
import pandas as pd

df = pd.read_csv("data/metadata.csv")

# Always start here — understand what you have
print(df.info())
print(df.describe())
print(df.isnull().sum())

# Handle nulls — don't just drop rows
df["confidence"].fillna(df["confidence"].median(), inplace=True)

# Group-by — understand class distribution
class_dist = df.groupby("label").size().sort_values(ascending=False)
print(class_dist)

# Check for class imbalance — critical before training
total = len(df)
for label, count in class_dist.items():
    print(f"{label}: {count} ({count/total*100:.1f}%)")
```

**Image preprocessing pipeline:**

```python
from torchvision import transforms

# Standard pipeline for transfer learning with MobileNetV2
train_transforms = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.RandomCrop(224),
    transforms.RandomHorizontalFlip(),
    transforms.ColorJitter(brightness=0.2, contrast=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],   # ImageNet stats
                         std=[0.229, 0.224, 0.225])
])

val_transforms = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])
```

**Write your own evaluation reporter:**

```python
import matplotlib.pyplot as plt
import seaborn as sns
import torch
from sklearn.metrics import classification_report, confusion_matrix

def evaluate_model(model, dataloader, class_names):
    all_preds, all_labels = [], []

    model.eval()
    with torch.no_grad():
        for images, labels in dataloader:
            outputs = model(images)
            preds = outputs.argmax(dim=1)
            all_preds.extend(preds.numpy())
            all_labels.extend(labels.numpy())

    # Full report
    labels = list(range(len(class_names)))  # keep every class even if absent from this split
    print(classification_report(all_labels, all_preds, labels=labels, target_names=class_names, zero_division=0))

    # Confusion matrix heatmap
    cm = confusion_matrix(all_labels, all_preds, labels=labels)
    plt.figure(figsize=(12, 10))
    sns.heatmap(cm, annot=True, fmt="d", xticklabels=class_names, yticklabels=class_names)
    plt.savefig("confusion_matrix.png")
```

### Output

A Jupyter notebook committed to GitHub with:
- Loss curve visualisation
- Class distribution analysis of PlantVillage
- A baseline model trained and evaluated with precision/recall/F1

This is Phase 1's portfolio artefact — it shows you understand the data before you build the API.

### Resources

| Resource | Type | Why |
|---|---|---|
| [fast.ai Practical Deep Learning](https://course.fast.ai/) | Course (free) | Best practitioner-first ML course globally |
| [CS229 Lecture Notes](https://cs229.stanford.edu/lectures-spring2022/main_notes.pdf) | Notes | Gradient descent and loss function derivations |
| [Kaggle Learn: Pandas](https://www.kaggle.com/learn/pandas) | Interactive | Real pandas exercises — not toy CSVs |
| [Scikit-learn metrics guide](https://scikit-learn.org/stable/modules/model_evaluation.html) | Docs | Confusion matrix, precision/recall — definitive reference |
| [torchvision transforms](https://pytorch.org/vision/stable/transforms.html) | Docs | Image preprocessing for training pipelines |

### Learning outcomes

- Gradient descent intuition (implemented manually)
- Loss function selection reasoning
- Pandas for real messy data
- Image preprocessing pipelines
- Evaluation: confusion matrix, precision, recall, F1

---

## Phase 2 — Python ML Service (FastAPI)
**Duration:** 1.5 weeks
**Goal:** Wrap a trained model in a production-ready API with proper testing, validation, and containerisation.

### Setup for this phase

```bash
mkdir python-ml-service && cd python-ml-service
uv init .
uv venv && source .venv/bin/activate

uv add fastapi uvicorn torch torchvision pillow pydantic python-multipart structlog
uv add --dev pytest pytest-asyncio httpx ruff mypy

# Project structure
mkdir -p app/{models,routers,services,schemas}
touch app/main.py app/config.py
touch app/models/.gitkeep        # model weights go here (gitignored)
```

### Train and export the model

> Sketch of the idea. The real, tested implementation is `ml-training/src/crop_ml/train.py`
> (see `docs/PHASE_1_ML_THEORY_AND_DATA.md`); it uses separate train/val transforms, a
> stratified split and early stopping.

```python
# scripts/train.py
import torch
import torch.nn as nn
from torchvision import models, datasets, transforms
from torch.utils.data import DataLoader, random_split
from pathlib import Path

train_transforms = transforms.Compose([
    transforms.RandomResizedCrop(224),
    transforms.RandomHorizontalFlip(),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
])

def train(data_dir: str, output_dir: str, epochs: int = 10):
    # Dataset
    dataset = datasets.ImageFolder(data_dir, transform=train_transforms)
    class_names = dataset.classes
    n_train = int(0.8 * len(dataset))
    train_ds, val_ds = random_split(dataset, [n_train, len(dataset) - n_train])

    train_loader = DataLoader(train_ds, batch_size=32, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_ds, batch_size=32, num_workers=4)

    # MobileNetV2 — transfer learning, model < 50MB
    model = models.mobilenet_v2(weights="IMAGENET1K_V1")
    model.classifier[1] = nn.Linear(model.last_channel, len(class_names))

    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(epochs):
        model.train()
        for images, labels in train_loader:
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

        print(f"Epoch {epoch+1}/{epochs} — loss: {loss.item():.4f}")

    # Save with version
    version = "v1"
    Path(output_dir).mkdir(exist_ok=True)
    # Keys must match what the Phase 2 service reads (see the checkpoint contract in PHASE_1 doc)
    torch.save({
        "model_state_dict": model.state_dict(),
        "num_classes": len(class_names),
        "class_names": class_names,
        "model_version": version,
        "image_size": 224,
        "mean": [0.485, 0.456, 0.406],
        "std": [0.229, 0.224, 0.225],
    }, f"{output_dir}/mobilenetv2_{version}_best.pt")

    print(f"Saved model to {output_dir}/mobilenetv2_{version}_best.pt")
```

**Export to TFLite for Phase 6 (Flutter + Android KMP):**

```bash
pip install tensorflow
```

```python
# scripts/export_tflite.py
import tensorflow as tf

# Convert from SavedModel or .h5 — do a TF training pass or use ONNX bridge
converter = tf.lite.TFLiteConverter.from_saved_model("saved_model/")
converter.optimizations = [tf.lite.Optimize.DEFAULT]   # quantise for size
tflite_model = converter.convert()

with open("models/crop_disease_v1.tflite", "wb") as f:
    f.write(tflite_model)

print(f"TFLite model: {len(tflite_model) / 1024:.1f} KB")
```

### FastAPI service

```python
# app/main.py
from fastapi import FastAPI
from app.routers import predict
import structlog

log = structlog.get_logger()

app = FastAPI(title="Crop Disease ML Service", version="1.0.0")
app.include_router(predict.router)

@app.get("/health")
async def health():
    return {"status": "ok"}
```

```python
# app/routers/predict.py
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.schemas.prediction import PredictionResponse
from app.services.inference import InferenceService
import structlog

router = APIRouter(prefix="/api/v1")
log = structlog.get_logger()
svc = InferenceService(model_path="models/mobilenetv2_v1_best.pt")  # real version: python-ml-service/app/

@router.post("/predict", response_model=PredictionResponse)
async def predict(file: UploadFile = File(...)):
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Only JPEG and PNG accepted")

    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image must be under 5MB")

    try:
        result = await svc.predict(contents)
        log.info("prediction.complete", label=result.label, confidence=result.confidence)
        return result
    except Exception as e:
        log.error("prediction.failed", error=str(e))
        raise HTTPException(status_code=500, detail="Inference failed")
```

```python
# app/schemas/prediction.py
from pydantic import BaseModel, Field

class PredictionResponse(BaseModel):
    label: str
    confidence: float = Field(ge=0.0, le=1.0)
    model_version: str
    top_3: list[dict]   # [{label, confidence}] for top 3 predictions
```

### pytest unit tests

```python
# tests/test_predict.py
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_predict_valid_image():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test")  # httpx 0.28 removed app= as client:
        with open("tests/fixtures/healthy_leaf.jpg", "rb") as f:
            response = await client.post(
                "/api/v1/predict",
                files={"file": ("leaf.jpg", f, "image/jpeg")}
            )
    assert response.status_code == 200
    data = response.json()
    assert "label" in data
    assert 0.0 <= data["confidence"] <= 1.0

@pytest.mark.asyncio
async def test_predict_invalid_type():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test")  # httpx 0.28 removed app= as client:
        response = await client.post(
            "/api/v1/predict",
            files={"file": ("doc.pdf", b"fake", "application/pdf")}
        )
    assert response.status_code == 415  # Unsupported Media Type
```

### Dockerfile

```dockerfile
# python-ml-service/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install uv
RUN pip install uv

COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

COPY app/ ./app/
COPY models/ ./models/

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Resources

| Resource | Type | Why |
|---|---|---|
| [FastAPI docs — file uploads](https://fastapi.tiangolo.com/tutorial/request-files/) | Docs | Official multipart/form-data handling guide |
| [PyTorch Transfer Learning tutorial](https://pytorch.org/tutorials/beginner/transfer_learning_tutorial.html) | Tutorial | MobileNetV2 fine-tuning walkthrough |
| [TFLite conversion guide](https://www.tensorflow.org/lite/models/convert) | Docs | Export SavedModel/.h5 to .tflite |
| [pytest — Getting started](https://docs.pytest.org/en/stable/getting-started.html) | Docs | Fixtures, parametrize, async testing |
| [PlantVillage dataset](https://www.kaggle.com/datasets/emmarex/plantdisease) | Dataset | 54,000 images, 38 disease classes |
| [Pydantic v2 docs](https://docs.pydantic.dev/latest/) | Docs | Request/response validation used natively by FastAPI |

### Learning outcomes

- FastAPI routing, file uploads, error handling
- Model versioning from day one
- pytest for async endpoints
- Docker multi-stage builds
- Pydantic schema validation
- TFLite export for mobile deployment

---

## Phase 3 (Priority 4) — RAG Pipeline
**Duration:** 2–3 weeks
**Goal:** Build a production RAG chatbot grounded in crop disease domain knowledge. This is the most in-demand AI skill of 2026 — treat it as the core of the project, not a bonus.

### Why this is promoted to Priority 4

AI engineer interviews in 2026 are 60%+ GenAI-focused. RAG, LLMs, prompt engineering, and agents dominate technical rounds. CNN knowledge now covers roughly 25% of what interviewers ask. Do not deprioritise this phase.

> **Implemented differently.** The snippets below are the original LangChain + Gemini sketch and
> no longer run as written: LangChain 1.x moved these imports, `vectorstore.persist()` no longer
> exists, and `gemini-1.5-flash` is retired. The real, tested service is in `rag-service/`: chromadb
> plus Ollama directly, no LangChain, no cloud key. See `docs/PHASE_3_RAG_PIPELINE.md`.

### Setup for this phase

```bash
mkdir rag-service && cd rag-service
uv init .
uv venv && source .venv/bin/activate

uv add fastapi uvicorn langchain langchain-community chromadb \
    sentence-transformers google-generativeai pypdf structlog pydantic
uv add --dev pytest pytest-asyncio ragas httpx

# Verify Ollama is running (from environment setup)
ollama serve &   # run in background
ollama pull llama3.2
curl http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"Hello"}'
```

### Document preparation

```bash
# Prepare your knowledge base — agricultural FAQs, PlantVillage disease descriptions
mkdir -p data/docs

# Example sources to collect:
# - FAO crop disease management PDFs
# - PlantVillage disease descriptions (exportable as text)
# - University extension service crop guides
```

```python
# scripts/ingest.py — run once to build the vector store
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from pathlib import Path

def ingest(docs_dir: str = "data/docs", persist_dir: str = "data/chroma"):
    # Load all PDFs
    loader = DirectoryLoader(docs_dir, glob="**/*.pdf", loader_cls=PyPDFLoader)
    raw_docs = loader.load()
    print(f"Loaded {len(raw_docs)} pages from {docs_dir}")

    # Chunk — 500 tokens with 50 overlap is a good starting point
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        separators=["\n\n", "\n", ".", " "]
    )
    chunks = splitter.split_documents(raw_docs)
    print(f"Split into {len(chunks)} chunks")

    # Embed — all-MiniLM-L6-v2 is fast, small (80MB), good quality
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )

    # Store in ChromaDB — runs in-process, no infrastructure needed
    vectorstore = Chroma.from_documents(
        chunks,
        embedding=embeddings,
        persist_directory=persist_dir
    )
    vectorstore.persist()
    print(f"Vector store persisted to {persist_dir}")

if __name__ == "__main__":
    ingest()
```

### RAG service

```python
# app/rag_service.py
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_community.llms import Ollama
import google.generativeai as genai
import structlog
import os

log = structlog.get_logger()

class RAGService:
    def __init__(self):
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.vectorstore = Chroma(
            persist_directory="data/chroma",
            embedding_function=self.embeddings
        )
        self.retriever = self.vectorstore.as_retriever(search_kwargs={"k": 5})

        # Local LLM via Ollama (primary)
        self.local_llm = Ollama(model="llama3.2")

        # Gemini as cloud fallback
        genai.configure(api_key=os.environ["GEMINI_API_KEY"])
        self.gemini = genai.GenerativeModel("gemini-1.5-flash")

    async def ask(self, question: str, use_local: bool = True) -> dict:
        # Retrieve relevant chunks
        docs = self.retriever.invoke(question)
        context = "\n\n".join([d.page_content for d in docs])
        sources = [d.metadata.get("source", "unknown") for d in docs]

        prompt = f"""You are a crop disease expert. Answer the question using ONLY the context below.
If the answer is not in the context, say so clearly.

Context:
{context}

Question: {question}

Answer:"""

        log.info("rag.query", question=question, num_docs=len(docs))

        if use_local:
            answer = self.local_llm.invoke(prompt)
        else:
            response = self.gemini.generate_content(prompt)
            answer = response.text

        return {
            "answer": answer,
            "sources": list(set(sources)),
            "num_chunks_retrieved": len(docs)
        }
```

```python
# app/routers/ask.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.rag_service import RAGService
import structlog

router = APIRouter(prefix="/api/v1")
log = structlog.get_logger()
svc = RAGService()

class AskRequest(BaseModel):
    question: str
    use_local_llm: bool = True

class AskResponse(BaseModel):
    answer: str
    sources: list[str]
    num_chunks_retrieved: int

@router.post("/ask", response_model=AskResponse)
async def ask(body: AskRequest):
    if not body.question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty")
    try:
        result = await svc.ask(body.question, use_local=body.use_local_llm)
        return result
    except Exception as e:
        log.error("rag.failed", error=str(e))
        raise HTTPException(status_code=500, detail="RAG query failed")
```

### RAG evaluation with RAGAS

This is what separates your portfolio from every other RAG project. Most candidates skip evaluation entirely.

```python
# scripts/evaluate_rag.py
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_recall
from datasets import Dataset
import json

# Prepare test set — 10–20 question/answer pairs from your domain
test_cases = [
    {
        "question": "What causes early blight in tomatoes?",
        "ground_truth": "Early blight is caused by the fungus Alternaria solani.",
        "contexts": [...],   # retrieved chunks
        "answer": "..."      # model's answer
    },
    # ... more cases
]

dataset = Dataset.from_list(test_cases)

results = evaluate(
    dataset,
    metrics=[faithfulness, answer_relevancy, context_recall]
)

# Log results — reference in README
report = {
    "faithfulness": results["faithfulness"],
    "answer_relevancy": results["answer_relevancy"],
    "context_recall": results["context_recall"]
}

with open("eval_results.json", "w") as f:
    json.dump(report, f, indent=2)

print(json.dumps(report, indent=2))
```

### Interview preparation from this phase

Questions this phase directly prepares you to answer:

- "How does RAG work and how is it different from fine-tuning?"
- "How do you evaluate a RAG pipeline?"
- "What chunking strategy did you use and why?"
- "What happens when retrieval returns irrelevant chunks?"
- "How would you integrate a traditional ML model into an LLM workflow?" — your crop disease CNN + RAG chatbot is a live answer

### Resources

| Resource | Type | Why |
|---|---|---|
| [LangChain RAG tutorial](https://python.langchain.com/docs/tutorials/rag/) | Tutorial | End-to-end RAG with retrievers and chains |
| [sentence-transformers](https://www.sbert.net/) | Docs | all-MiniLM-L6-v2 — go-to embedding model |
| [ChromaDB quickstart](https://docs.trychroma.com/getting-started) | Docs | Local vector store, zero infrastructure |
| [Ollama](https://ollama.com/) | Tool | Llama 3.2 locally — runs well on M5 MacBook |
| [RAGAS](https://docs.ragas.io/en/stable/) | Package | Faithfulness, answer relevance, context recall |
| [Google Generative AI SDK](https://ai.google.dev/gemini-api/docs/quickstart?lang=python) | Docs | Gemini API — cloud LLM fallback |

### Learning outcomes

- RAG architecture (ingestion, chunking, embedding, retrieval, generation)
- ChromaDB vector store operations
- sentence-transformers embedding models
- RAGAS evaluation (faithfulness, answer relevance, context recall)
- Local LLM with Ollama
- Gemini API as cloud fallback

---

## Phase 4 — Go Backend Gateway
**Duration:** 2 weeks
**Goal:** Build a Go REST API gateway to both the Python ML service and the RAG service. This phase goes faster than estimated given your existing Go experience.

### Setup for this phase

```bash
mkdir go-gateway && cd go-gateway
go mod init github.com/yourusername/go-gateway

go get github.com/gin-gonic/gin
go get github.com/sirupsen/logrus
go get golang.org/x/time/rate
go get github.com/prometheus/client_golang/prometheus
go get github.com/prometheus/client_golang/prometheus/promhttp
```

### Project structure

```
go-gateway/
├── cmd/server/main.go
├── internal/
│   ├── handlers/
│   │   ├── predict.go
│   │   └── ask.go
│   ├── middleware/
│   │   ├── auth.go
│   │   ├── ratelimit.go
│   │   └── logging.go
│   ├── client/
│   │   ├── ml_client.go
│   │   └── rag_client.go
│   └── metrics/metrics.go
├── Dockerfile
└── go.sum
```

### Main server

```go
// cmd/server/main.go
package main

import (
    "context"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/sirupsen/logrus"
    "github.com/yourusername/go-gateway/internal/handlers"
    "github.com/yourusername/go-gateway/internal/middleware"
    "github.com/yourusername/go-gateway/internal/metrics"
)

func main() {
    log := logrus.New()
    log.SetFormatter(&logrus.JSONFormatter{})

    r := gin.New()
    r.Use(middleware.RequestLogger(log))
    r.Use(middleware.Recovery(log))
    r.Use(middleware.APIKeyAuth(os.Getenv("API_KEY")))
    r.Use(middleware.RateLimiter(100, 10)) // 100 req/s, burst 10

    mlClient := client.NewMLClient(os.Getenv("ML_SERVICE_URL"), 10*time.Second)
    ragClient := client.NewRAGClient(os.Getenv("RAG_SERVICE_URL"), 30*time.Second)

    api := r.Group("/api/v1")
    api.POST("/upload", handlers.Upload(mlClient))
    api.POST("/ask", handlers.Ask(ragClient))
    api.GET("/metrics", metrics.Handler())

    srv := &http.Server{Addr: ":8080", Handler: r}

    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("listen: %s\n", err)
        }
    }()

    // Graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    srv.Shutdown(ctx)
    log.Info("Server shutdown cleanly")
}
```

### Rate limiter middleware

```go
// internal/middleware/ratelimit.go
package middleware

import (
    "net/http"
    "sync"

    "github.com/gin-gonic/gin"
    "golang.org/x/time/rate"
)

type ipLimiter struct {
    limiters sync.Map
    r        rate.Limit
    b        int
}

func (il *ipLimiter) get(ip string) *rate.Limiter {
    v, _ := il.limiters.LoadOrStore(ip, rate.NewLimiter(il.r, il.b))
    return v.(*rate.Limiter)
}

func RateLimiter(rps float64, burst int) gin.HandlerFunc {
    il := &ipLimiter{r: rate.Limit(rps), b: burst}
    return func(c *gin.Context) {
        if !il.get(c.ClientIP()).Allow() {
            c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
                "error": "rate limit exceeded",
            })
            return
        }
        c.Next()
    }
}
```

### Unit tests

```go
// internal/handlers/predict_test.go
package handlers_test

import (
    "bytes"
    "mime/multipart"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestUploadValidImage(t *testing.T) {
    gin.SetMode(gin.TestMode)
    r := gin.New()
    r.POST("/api/v1/upload", handlers.Upload(mockMLClient()))

    body := &bytes.Buffer{}
    writer := multipart.NewWriter(body)
    part, _ := writer.CreateFormFile("file", "leaf.jpg")
    part.Write([]byte("fake jpeg content"))
    writer.Close()

    req := httptest.NewRequest(http.MethodPost, "/api/v1/upload", body)
    req.Header.Set("Content-Type", writer.FormDataContentType())
    w := httptest.NewRecorder()

    r.ServeHTTP(w, req)
    assert.Equal(t, http.StatusOK, w.Code)
}
```

### Docker Compose — run everything locally

```yaml
# docker-compose.yml (project root)
version: "3.9"
services:
  ml-service:
    build: ./python-ml-service
    ports: ["8000:8000"]
    volumes:
      - ./python-ml-service/models:/app/models
    environment:
      - MODEL_VERSION=v1

  rag-service:
    build: ./rag-service
    ports: ["8001:8001"]
    volumes:
      - ./rag-service/data:/app/data
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}

  go-gateway:
    build: ./go-gateway
    ports: ["8080:8080"]
    depends_on: [ml-service, rag-service]
    environment:
      - ML_SERVICE_URL=http://ml-service:8000
      - RAG_SERVICE_URL=http://rag-service:8001
      - API_KEY=${API_KEY}
```

```bash
# Run everything
docker compose up --build

# Test end-to-end
curl -X POST http://localhost:8080/api/v1/upload \
  -H "X-API-Key: your-key" \
  -F "file=@/path/to/leaf.jpg"

curl -X POST http://localhost:8080/api/v1/ask \
  -H "X-API-Key: your-key" \
  -H "Content-Type: application/json" \
  -d '{"question": "What causes early blight in tomatoes?"}'
```

### Resources

| Resource | Type | Why |
|---|---|---|
| [Gin framework docs](https://gin-gonic.com/docs/) | Docs | Routing, middleware, file handling |
| [Go net/http/httptest](https://pkg.go.dev/net/http/httptest) | Docs | Testing HTTP handlers without a running server |
| [golang.org/x/time/rate](https://pkg.go.dev/golang.org/x/time/rate) | Package | Token bucket rate limiter — idiomatic Go |
| [Go blog: pipelines and cancellation](https://go.dev/blog/pipelines) | Article | Context propagation and goroutine lifecycle |
| [Awesome Go](https://awesome-go.com/) | Reference | Curated Go libraries — middleware, clients, testing |

### Learning outcomes

- Gin routing and middleware chain
- Go concurrency patterns (goroutines, channels, sync.Map)
- Per-IP rate limiting
- httptest for handler unit tests
- Graceful shutdown
- Docker Compose multi-service orchestration

---

## Phase 5 — Production + CI/CD
**Duration:** 2 weeks
**Goal:** Turn the project from a working demo into a professional portfolio artefact.

### Setup for this phase

```bash
# Install Prometheus + Grafana locally for testing metrics
docker run -d -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

docker run -d -p 3000:3000 grafana/grafana
```

### Prometheus metrics in Go

```go
// internal/metrics/metrics.go
package metrics

import (
    "net/http"

    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    RequestCount = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "gateway_requests_total", Help: "Total requests"},
        []string{"endpoint", "status"},
    )
    RequestLatency = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "gateway_latency_seconds",
            Help:    "Request latency",
            Buckets: prometheus.DefBuckets,
        },
        []string{"endpoint"},
    )
    PredictionLabels = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "ml_prediction_labels_total", Help: "Prediction class counts"},
        []string{"label"},
    )
)

func init() {
    prometheus.MustRegister(RequestCount, RequestLatency, PredictionLabels)
}

func Handler() gin.HandlerFunc {
    h := promhttp.Handler()
    return func(c *gin.Context) {
        h.ServeHTTP(c.Writer, c.Request)
    }
}
```

### GitHub Actions CI/CD

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install uv
      - run: uv pip install --system -r python-ml-service/requirements.txt
      - run: cd python-ml-service && pytest tests/ -v --tb=short

  test-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
      - run: cd go-gateway && go test ./... -v

  build-and-push:
    needs: [test-python, test-go]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - run: |
          docker build -t ghcr.io/${{ github.repository }}/ml-service:${{ github.sha }} ./python-ml-service
          docker push ghcr.io/${{ github.repository }}/ml-service:${{ github.sha }}
          docker build -t ghcr.io/${{ github.repository }}/go-gateway:${{ github.sha }} ./go-gateway
          docker push ghcr.io/${{ github.repository }}/go-gateway:${{ github.sha }}
```

### Deploy to Cloud Run

```bash
# One-time setup
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com

# Deploy ML service
gcloud run deploy ml-service \
  --image ghcr.io/yourusername/repo/ml-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 2Gi

# Deploy Go gateway
gcloud run deploy go-gateway \
  --image ghcr.io/yourusername/repo/go-gateway:latest \
  --platform managed \
  --region us-central1 \
  --set-env-vars ML_SERVICE_URL=https://ml-service-xxxx-uc.a.run.app \
  --set-secrets API_KEY=api-key:latest
```

### Documentation checklist

Every file below is required for the portfolio to be taken seriously:

```
ARCHITECTURE.md   — system diagram, component responsibilities, tradeoffs
README.md         — one-command local setup, env vars table, API reference, demo GIF
DEVELOPMENT.md    — how to run tests, add a new model version, add a new endpoint
eval_results.json — RAGAS scores from Phase 3
docs/devlog.md    — short bullet entries per phase (shows learning trajectory)
```

### Resources

| Resource | Type | Why |
|---|---|---|
| [GitHub Actions docs](https://docs.github.com/en/actions) | Docs | Workflow syntax, matrix builds, GHCR publishing |
| [logrus](https://github.com/sirupsen/logrus) | Package | Structured, leveled logging for Go |
| [structlog (Python)](https://www.structlog.org/) | Docs | JSON structured logging, context binding |
| [Prometheus Go client](https://github.com/prometheus/client_golang) | Docs | Official Go metrics library |
| [GCP Cloud Run quickstart](https://cloud.google.com/run/docs/quickstarts) | Docs | Deploy a containerised service — free tier |
| [Railway.app](https://railway.app/) | Tool | Simpler than GCP for first deploys — Docker-native |

### Learning outcomes

- Prometheus metrics (counters, histograms)
- GitHub Actions (test, build, push, deploy)
- GHCR Docker image publishing
- GCP Cloud Run deployment
- Structured logging correlation across services
- Professional project documentation

---

## Phase 6 — Flutter Mobile App
**Duration:** 1.5 weeks
**Goal:** Showcase mobile + AI integration with offline-first TFLite on-device inference — the rare differentiator in AI/ML portfolios.

### Setup for this phase

```bash
# Create Flutter project
flutter create --org com.yourdomain crop_disease_app
cd crop_disease_app

# Add dependencies to pubspec.yaml
flutter pub add image_picker dio hive hive_flutter tflite_flutter connectivity_plus path_provider

# Copy the .tflite model from Phase 2
mkdir -p assets/models
cp ../python-ml-service/models/crop_disease_v1.tflite assets/models/

# Register asset in pubspec.yaml
# flutter:
#   assets:
#     - assets/models/crop_disease_v1.tflite
```

### On-device inference

```dart
// lib/services/inference_service.dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class InferenceService {
  late Interpreter _interpreter;
  final List<String> _labels;

  InferenceService(this._labels);

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/crop_disease_v1.tflite');
  }

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    // Preprocess — match Python training pipeline exactly
    final image = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(image, width: 224, height: 224);

    // Normalise to [-1, 1] (MobileNetV2 standard)
    final input = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        })
      )
    );

    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter.run(input, output);

    final scores = output[0] as List<double>;
    final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));

    return {
      'label': _labels[maxIdx],
      'confidence': scores[maxIdx],
      'source': 'on_device',
    };
  }

  void dispose() => _interpreter.close();
}
```

### Offline-first prediction flow

```dart
// lib/services/prediction_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'inference_service.dart';
import 'cache_service.dart';

class PredictionService {
  final InferenceService _onDevice;
  final Dio _dio;
  final CacheService _cache;

  PredictionService(this._onDevice, this._dio, this._cache);

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    Map<String, dynamic> result;

    if (isOnline) {
      try {
        // Try backend first when online
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(imageBytes, filename: 'image.jpg'),
        });
        final response = await _dio.post('/api/v1/upload', data: formData);
        result = {...response.data, 'source': 'backend'};
      } catch (_) {
        // Fall back to on-device if backend fails
        result = await _onDevice.predict(imageBytes);
      }
    } else {
      // Offline — always use on-device
      result = await _onDevice.predict(imageBytes);
    }

    await _cache.save(result);
    return result;
  }
}
```

### Benchmark on-device vs backend

Measure both and put the numbers in your README — this is what gets noticed:

```dart
// lib/utils/benchmark.dart
Future<void> benchmarkLatency(Uint8List imageBytes) async {
  final onDeviceStart = DateTime.now();
  await inferenceService.predict(imageBytes);
  final onDeviceMs = DateTime.now().difference(onDeviceStart).inMilliseconds;

  final backendStart = DateTime.now();
  await predictionService.predictViaBackend(imageBytes);
  final backendMs = DateTime.now().difference(backendStart).inMilliseconds;

  print('On-device: ${onDeviceMs}ms | Backend: ${backendMs}ms');
}
```

### Resources

| Resource | Type | Why |
|---|---|---|
| [tflite_flutter](https://pub.dev/packages/tflite_flutter) | Package | TFLite on Android and iOS directly in Flutter |
| [image_picker](https://pub.dev/packages/image_picker) | Package | Camera and gallery access — official Flutter team |
| [Hive Flutter](https://pub.dev/packages/hive_flutter) | Package | Lightweight local key-value store |
| [Dio](https://pub.dev/packages/dio) | Package | HTTP client with interceptors and retry |
| [connectivity_plus](https://pub.dev/packages/connectivity_plus) | Package | Network state detection for offline logic |

### Learning outcomes

- Flutter HTTP with Dio
- Hive offline caching
- TFLite on-device inference
- Offline-first architecture pattern
- Latency benchmarking

---

## Phase 7 — Android KMP Module
**Duration:** 2–3 weeks
**Goal:** Share ML inference logic between Android and iOS using Kotlin Multiplatform — the strongest differentiator for mobile-AI crossover roles.

### Why this phase matters

Most ML engineers cannot build mobile apps. Most Android developers cannot build ML systems. KMP with on-device ML inference sits at that intersection and almost nobody has it in their portfolio. It also directly leverages your Kotlin and Android expertise from Pezesha.

### Setup for this phase

```bash
# Android Studio — already installed
# Install KMP plugin
# Android Studio → Settings → Plugins → search "Kotlin Multiplatform"

# Create KMP project using the wizard
# File → New → New Project → Kotlin Multiplatform App
# Project name: CropDiseaseKMP
# Package: com.yourdomain.cropdisease
# Android + iOS targets
```

### Project structure

```
android-kmp/
├── shared/
│   ├── src/
│   │   ├── commonMain/kotlin/
│   │   │   ├── InferenceEngine.kt      # shared interface
│   │   │   ├── PredictionResult.kt     # shared data class
│   │   │   └── RAGClient.kt            # shared HTTP client
│   │   ├── androidMain/kotlin/
│   │   │   └── TFLiteInferenceEngine.kt
│   │   └── iosMain/kotlin/
│   │       └── CoreMLInferenceEngine.kt
│   └── build.gradle.kts
├── androidApp/
└── iosApp/
```

### Shared interface (commonMain)

```kotlin
// shared/src/commonMain/kotlin/InferenceEngine.kt
package com.yourdomain.cropdisease

interface InferenceEngine {
    suspend fun predict(imageBytes: ByteArray): PredictionResult
    fun loadModel()
    fun close()
}

data class PredictionResult(
    val label: String,
    val confidence: Float,
    val topThree: List<Pair<String, Float>>,
    val inferenceTimeMs: Long,
    val source: InferenceSource
)

enum class InferenceSource { ON_DEVICE, BACKEND }
```

```kotlin
// shared/src/commonMain/kotlin/RAGClient.kt
package com.yourdomain.cropdisease

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.Serializable

@Serializable
data class AskRequest(val question: String)

@Serializable
data class AskResponse(val answer: String, val sources: List<String>)

class RAGClient(private val baseUrl: String) {
    private val client = HttpClient {
        install(ContentNegotiation) { json() }
    }

    suspend fun ask(question: String): AskResponse =
        client.post("$baseUrl/api/v1/ask") {
            setBody(AskRequest(question))
        }.body()
}
```

### Android implementation (androidMain)

```kotlin
// shared/src/androidMain/kotlin/TFLiteInferenceEngine.kt
package com.yourdomain.cropdisease

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

actual class PlatformInferenceEngine(
    private val context: Context,
    private val modelAssetPath: String,
    private val labels: List<String>
) : InferenceEngine {

    private lateinit var interpreter: Interpreter

    actual override fun loadModel() {
        val assetFileDescriptor = context.assets.openFd(modelAssetPath)
        val fileChannel = FileInputStream(assetFileDescriptor.fileDescriptor).channel
        val mappedBuffer = fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            assetFileDescriptor.startOffset,
            assetFileDescriptor.declaredLength
        )
        interpreter = Interpreter(mappedBuffer)
    }

    actual override suspend fun predict(imageBytes: ByteArray): PredictionResult {
        val start = System.currentTimeMillis()

        // Preprocess — same pipeline as Python training
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        val resized = Bitmap.createScaledBitmap(bitmap, 224, 224, true)

        val inputBuffer = ByteBuffer.allocateDirect(1 * 224 * 224 * 3 * 4)
            .order(ByteOrder.nativeOrder())

        for (y in 0 until 224) {
            for (x in 0 until 224) {
                val pixel = resized.getPixel(x, y)
                inputBuffer.putFloat(((pixel shr 16 and 0xFF) / 127.5f) - 1f)
                inputBuffer.putFloat(((pixel shr 8 and 0xFF) / 127.5f) - 1f)
                inputBuffer.putFloat(((pixel and 0xFF) / 127.5f) - 1f)
            }
        }

        val output = Array(1) { FloatArray(labels.size) }
        interpreter.run(inputBuffer, output)

        val scores = output[0]
        val topThree = scores.indices
            .sortedByDescending { scores[it] }
            .take(3)
            .map { Pair(labels[it], scores[it]) }

        return PredictionResult(
            label = topThree[0].first,
            confidence = topThree[0].second,
            topThree = topThree,
            inferenceTimeMs = System.currentTimeMillis() - start,
            source = InferenceSource.ON_DEVICE
        )
    }

    actual override fun close() = interpreter.close()
}
```

### ViewModel using shared logic

```kotlin
// androidApp/src/main/kotlin/MainViewModel.kt
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yourdomain.cropdisease.PlatformInferenceEngine
import com.yourdomain.cropdisease.RAGClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(
    private val engine: PlatformInferenceEngine,
    private val ragClient: RAGClient
) : ViewModel() {

    private val _prediction = MutableStateFlow<UiState>(UiState.Idle)
    val prediction = _prediction.asStateFlow()

    fun analyse(imageBytes: ByteArray) {
        viewModelScope.launch {
            _prediction.value = UiState.Loading
            try {
                val result = engine.predict(imageBytes)
                _prediction.value = UiState.Success(result)
            } catch (e: Exception) {
                _prediction.value = UiState.Error(e.message ?: "Inference failed")
            }
        }
    }

    fun askAboutDisease(question: String) {
        viewModelScope.launch {
            val response = ragClient.ask(question)
            // update UI with RAG answer
        }
    }
}
```

### build.gradle.kts (shared module)

```kotlin
// shared/build.gradle.kts
plugins {
    kotlin("multiplatform")
    kotlin("plugin.serialization")
    id("com.android.library")
}

kotlin {
    androidTarget()
    iosX64()
    iosArm64()
    iosSimulatorArm64()

    sourceSets {
        val commonMain by getting {
            dependencies {
                implementation("io.ktor:ktor-client-core:2.3.7")
                implementation("io.ktor:ktor-client-content-negotiation:2.3.7")
                implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.7")
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
                implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
            }
        }
        val androidMain by getting {
            dependencies {
                implementation("io.ktor:ktor-client-android:2.3.7")
                implementation("org.tensorflow:tensorflow-lite:2.14.0")
            }
        }
        val iosMain by getting {
            dependencies {
                implementation("io.ktor:ktor-client-darwin:2.3.7")
            }
        }
    }
}
```

### Interview questions this phase answers

- "How would you share business logic between Android and iOS without duplicating it?"
- "Explain how you'd run ML inference on an Android device without network access"
- "What is KMP and how does it differ from Flutter for cross-platform?"
- "Walk me through the preprocessing steps needed to make a PyTorch model run on Android"

### Resources

| Resource | Type | Why |
|---|---|---|
| [KMP Getting Started](https://www.jetbrains.com/help/kotlin-multiplatform-dev/get-started.html) | Docs | Official JetBrains KMP setup guide |
| [TFLite Android quickstart](https://www.tensorflow.org/lite/android/quickstart) | Docs | TFLite interpreter for Android — official guide |
| [Ktor client docs](https://ktor.io/docs/client-create-new-application.html) | Docs | Multiplatform HTTP client used in shared module |
| [KMP sample apps](https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-samples.html) | Reference | Real-world KMP project examples from JetBrains |
| [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization) | Docs | JSON serialisation in the shared module |
| [ONNX Runtime for Android](https://onnxruntime.ai/docs/tutorials/mobile/) | Docs | Alternative to TFLite for model inference |

### Learning outcomes

- Kotlin Multiplatform project structure
- Shared business logic across Android and iOS
- TFLite inference in Android (Kotlin, not Java)
- Ktor multiplatform HTTP client
- expect/actual pattern for platform-specific implementations
- Bridging Python ML models to native mobile

---

## Overall Timeline

| Phase | Focus | Duration | Cumulative |
|---|---|---|---|
| 0 | Python fluency | 2 weeks | 2 weeks |
| 1 | ML theory + data | 2 weeks | 4 weeks |
| 2 | FastAPI ML service | 1.5 weeks | 5.5 weeks |
| **3** | **RAG pipeline (promoted)** | **2–3 weeks** | **8.5 weeks** |
| 4 | Go backend gateway | 2 weeks | 10.5 weeks |
| 5 | Production + CI/CD | 2 weeks | 12.5 weeks |
| 6 | Flutter mobile | 1.5 weeks | 14 weeks |
| 7 | Android KMP | 2–3 weeks | 17 weeks |

**Total: ~4 months at 10–15 hrs/week**

Phases 0–5 give you a deployable, interview-ready portfolio. Phases 6–7 add the mobile-AI differentiator that almost no AI/ML candidate has.

---

## Success Metrics

- **Python:** Write async FastAPI endpoints with type hints and pytest coverage without referencing docs
- **ML:** Train a custom CNN, explain every preprocessing decision, and justify metric choices in an interview
- **RAG:** Design and explain the full ingestion → retrieval → generation → evaluation pipeline on a whiteboard
- **Go:** Write a concurrent HTTP gateway with tests, middleware, and metrics from scratch
- **Production:** Both services deployed on cloud with CI/CD passing on every push
- **Flutter:** App demonstrates offline TFLite inference with measurable latency benchmark
- **KMP:** Shared inference module runs on both Android emulator and iOS simulator from the same Kotlin code

---

## Interview Question Map

| Interview question | Which phase answers it |
|---|---|
| "Explain gradient descent and why it works" | Phase 1 |
| "How do you handle class imbalance in a dataset?" | Phase 1 |
| "Walk me through your model serving architecture" | Phase 2 + Phase 4 (Go) |
| "How does RAG differ from fine-tuning and when would you choose each?" | Phase 3 |
| "How do you evaluate a RAG pipeline?" | Phase 3 (RAGAS) |
| "Design a rate limiter for an API" | Phase 4 (Go — you built one) |
| "How do you integrate a traditional ML model into an LLM workflow?" | Phase 3 + Phase 4 |
| "What observability do you have on your models in production?" | Phase 5 (Prometheus) |
| "How do you run ML on a mobile device without internet?" | Phase 6 + Phase 7 |
| "How would you share ML logic between Android and iOS?" | Phase 7 (KMP) |
