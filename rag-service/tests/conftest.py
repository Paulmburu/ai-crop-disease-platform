"""Fixtures: a tiny knowledge base, a fake embedder and a fake LLM.

No Ollama and no model download are needed: the fake embedder is a hashed
bag-of-words, so texts sharing words are close together, which is enough to
test retrieval logic deterministically.
"""

import hashlib
import math
import re
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
import pytest

from app.main import create_app
from app.services.documents import build_chunks
from app.services.llm import LLMUnavailableError
from app.services.rag import RAGService
from app.services.vector_store import VectorStore

DIM = 256

NOTES = {
    "tomato_late_blight.md": """---
class_name: Tomato_Late_blight
plant: Tomato
condition: Late blight
sources: https://example.org/late-blight | https://example.org/other
---
# Tomato late blight

## Cause
Late blight is caused by the water mold Phytophthora infestans.

## Management
Remove infected plants and apply protectant fungicide before rain.
""",
    "potato_early_blight.md": """---
class_name: Potato___Early_blight
plant: Potato
condition: Early blight
sources: https://example.org/early-blight
---
# Potato early blight

## Symptoms
Brown target-like concentric rings on older potato leaves.
""",
    "README.md": "# Not a note\nThis file must be skipped.",
}


def fake_embed(texts: list[str]) -> list[list[float]]:
    out = []
    for t in texts:
        v = [0.0] * DIM
        for w in re.findall(r"[a-z]+", t.lower()):
            v[int(hashlib.md5(w.encode()).hexdigest(), 16) % DIM] += 1.0
        n = math.sqrt(sum(x * x for x in v)) or 1.0
        out.append([x / n for x in v])
    return out


class FakeLLM:
    model = "fake-llm"

    def __init__(self, ready: bool = True, fail: bool = False) -> None:
        self.ready, self.fail, self.calls = ready, fail, []

    async def is_ready(self) -> bool:
        return self.ready

    async def chat(self, system: str, user: str) -> str:
        if self.fail:
            raise LLMUnavailableError("Ollama request failed: ConnectError")
        self.calls.append((system, user))
        return "Remove infected plants [1]."


@pytest.fixture
def knowledge_dir(tmp_path: Path) -> Path:
    d = tmp_path / "knowledge"
    d.mkdir()
    for name, text in NOTES.items():
        (d / name).write_text(text)
    return d


@pytest.fixture
def store(tmp_path: Path, knowledge_dir: Path) -> VectorStore:
    s = VectorStore(tmp_path / "chroma", "test", fake_embed)
    s.sync(build_chunks(knowledge_dir))
    return s


def make_client(rag: RAGService) -> httpx.AsyncClient:
    return httpx.AsyncClient(transport=httpx.ASGITransport(app=create_app(rag=rag)), base_url="http://test")


@pytest.fixture
async def client(store: VectorStore) -> AsyncIterator[httpx.AsyncClient]:
    async with make_client(RAGService(store, FakeLLM(), top_k=3, max_distance=0.95)) as c:
        yield c
