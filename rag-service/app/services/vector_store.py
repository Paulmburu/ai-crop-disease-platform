"""ChromaDB wrapper: store chunk embeddings, search by similarity.

We compute embeddings ourselves (an `Embedder` is just "texts in, vectors out")
and hand Chroma the vectors. That keeps the embedding model explicit, swappable,
and fake-able in tests.

Default embedder: all-MiniLM-L6-v2 run with ONNX Runtime (bundled with chromadb).
No PyTorch needed; the ~80 MB model downloads once to ~/.cache/chroma.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Protocol

import chromadb

from app.services.documents import Chunk


class Embedder(Protocol):
    def __call__(self, texts: list[str]) -> list[list[float]]: ...


def default_embedder() -> Embedder:
    from chromadb.utils.embedding_functions import ONNXMiniLM_L6_V2

    onnx = ONNXMiniLM_L6_V2()
    return lambda texts: [list(map(float, v)) for v in onnx(texts)]


@dataclass(frozen=True)
class Hit:
    id: str
    text: str
    meta: dict
    distance: float  # cosine distance: 0 = same direction, larger = less similar


@dataclass(frozen=True)
class SyncReport:
    upserted: int
    deleted: int
    total: int


class VectorStore:
    def __init__(self, path: Path, collection: str, embedder: Embedder) -> None:
        self._client = chromadb.PersistentClient(path=str(path))
        # embedding_function=None: we always pass vectors in, Chroma never embeds.
        self._col = self._client.get_or_create_collection(
            collection, embedding_function=None, configuration={"hnsw": {"space": "cosine"}}
        )
        self._embed = embedder

    def count(self) -> int:
        return self._col.count()

    def sync(self, chunks: list[Chunk], batch: int = 64) -> SyncReport:
        """Make the collection contain exactly `chunks`: upsert new/changed, delete stale.

        Idempotent: running it twice on the same notes changes nothing.
        """
        wanted = {c.id for c in chunks}
        existing = set(self._col.get(include=[])["ids"])
        new = [c for c in chunks if c.id not in existing]
        for i in range(0, len(new), batch):
            part = new[i : i + batch]
            self._col.upsert(
                ids=[c.id for c in part],
                documents=[c.text for c in part],
                metadatas=[c.meta for c in part],
                embeddings=self._embed([c.text for c in part]),
            )
        stale = sorted(existing - wanted)
        if stale:
            self._col.delete(ids=stale)
        return SyncReport(upserted=len(new), deleted=len(stale), total=self.count())

    def search(self, query: str, k: int, class_name: str | None = None) -> list[Hit]:
        """Top-k chunks closest to `query`, optionally only from one disease's note."""
        if self.count() == 0:
            return []
        res = self._col.query(
            query_embeddings=self._embed([query]),
            n_results=min(k, self.count()),
            where={"class_name": class_name} if class_name else None,
            include=["documents", "metadatas", "distances"],
        )
        return [
            Hit(id=i, text=d, meta=dict(m or {}), distance=float(dist))
            for i, d, m, dist in zip(res["ids"][0], res["documents"][0], res["metadatas"][0],
                                     res["distances"][0], strict=True)
        ]

    def class_names(self) -> list[str]:
        metas = self._col.get(include=["metadatas"])["metadatas"] or []
        return sorted({m["class_name"] for m in metas if m and "class_name" in m})
