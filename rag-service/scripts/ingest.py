"""Index (or re-index) the knowledge base into ChromaDB.

Run (from rag-service/):
    uv run python -m scripts.ingest            # sync knowledge/ -> .chroma/
    uv run python -m scripts.ingest --show 3   # also print 3 sample chunks

Idempotent: unchanged chunks are skipped, edited ones replaced, deleted ones removed.
Running it twice in a row reports "0 upserted, 0 deleted".
"""

import argparse
import time

from app.config import get_settings
from app.services.documents import build_chunks, load_notes
from app.services.vector_store import VectorStore, default_embedder


def main() -> None:
    p = argparse.ArgumentParser(description="Sync knowledge/ into the vector store.")
    p.add_argument("--show", type=int, default=0, help="print N sample chunks")
    a = p.parse_args()
    s = get_settings()

    start = time.perf_counter()
    notes = load_notes(s.knowledge_dir)
    chunks = build_chunks(s.knowledge_dir, s.chunk_size, s.chunk_overlap)
    print(f"{len(notes)} notes -> {len(chunks)} chunks "
          f"(avg {sum(len(c.text) for c in chunks) // max(len(chunks), 1)} chars)")
    for c in chunks[: a.show]:
        print(f"\n--- {c.id} {c.meta['source']} / {c.meta['section']}\n{c.text[:300]}")

    report = VectorStore(s.chroma_dir, s.collection, default_embedder()).sync(chunks)
    print(f"\n{report.upserted} upserted, {report.deleted} deleted, {report.total} total "
          f"in '{s.collection}' at {s.chroma_dir}/ ({time.perf_counter() - start:.1f}s)")


if __name__ == "__main__":
    main()
