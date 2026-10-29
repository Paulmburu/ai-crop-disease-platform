"""Evaluate the RAG pipeline with RAGAS, using the local Ollama model as the judge.

Run (from rag-service/, with Ollama running and the index built):
    uv run --group eval python -m scripts.evaluate
    uv run --group eval python -m scripts.evaluate --limit 3      # quick smoke run

For every question in eval/questions.json it runs the real RAGService, then scores:
    faithfulness       is every claim in the answer supported by the retrieved chunks?
    context_recall     do the retrieved chunks contain the facts in the reference answer?
    context_precision  are the relevant chunks ranked near the top?
    answer_accuracy    does the answer agree with the reference answer?
All scores are 0..1. Writes eval/results.json.

Note: an 8B local judge is noisier than a large cloud model; compare runs against
each other (same judge) rather than against published benchmarks.
"""

import argparse
import asyncio
import json
import statistics
import time
from pathlib import Path

from openai import AsyncOpenAI
from ragas.llms import llm_factory
from ragas.metrics.collections import AnswerAccuracy, ContextPrecisionWithReference, ContextRecall, Faithfulness

from app.config import get_settings
from app.services.llm import OllamaClient
from app.services.rag import RAGService
from app.services.vector_store import VectorStore, default_embedder

QUESTIONS = Path("eval/questions.json")
RESULTS = Path("eval/results.json")


async def run(limit: int | None) -> None:
    s = get_settings()
    cases = json.loads(QUESTIONS.read_text())[:limit]
    store = VectorStore(s.chroma_dir, s.collection, default_embedder())
    if store.count() == 0:
        raise SystemExit("Index is empty: run `uv run python -m scripts.ingest` first.")
    llm = OllamaClient(s.ollama_base_url, s.llm_model, s.llm_temperature, s.llm_timeout_s)
    if not await llm.is_ready():
        raise SystemExit(f"Ollama not ready or model missing: ollama pull {s.llm_model}")
    rag = RAGService(store, llm, s.top_k, s.max_distance)

    # Ollama speaks the OpenAI API at /v1, so RAGAS's OpenAI adapter can use it as the judge.
    judge = llm_factory(s.llm_model, provider="openai",
                        client=AsyncOpenAI(base_url=f"{s.ollama_base_url}/v1", api_key="ollama"))
    metrics = {
        "faithfulness": Faithfulness(llm=judge),
        "context_recall": ContextRecall(llm=judge),
        "context_precision": ContextPrecisionWithReference(llm=judge),
        "answer_accuracy": AnswerAccuracy(llm=judge),
    }

    rows = []
    for i, case in enumerate(cases, 1):
        start = time.perf_counter()
        result = await rag.ask(case["question"])
        contexts = [h.text for h in result.sources]
        row = {"question": case["question"], "answer": result.answer, "grounded": result.grounded,
               "sources": [h.meta.get("source") for h in result.sources]}
        args = {"user_input": case["question"], "response": result.answer,
                "retrieved_contexts": contexts or [""], "reference": case["reference"]}
        for name, metric in metrics.items():
            params = {k: v for k, v in args.items() if k in metric.ascore.__code__.co_varnames}
            try:
                row[name] = round(float((await metric.ascore(**params)).value), 3)
            except Exception as exc:  # a judge that returns malformed JSON should not kill the whole run
                row[name] = None
                row.setdefault("errors", {})[name] = f"{exc.__class__.__name__}: {str(exc)[:120]}"
        rows.append(row)
        scores = " ".join(f"{k}={row[k]}" for k in metrics)
        print(f"[{i}/{len(cases)}] {time.perf_counter() - start:5.1f}s {scores} | {case['question'][:50]}")

    summary = {k: round(statistics.mean(v), 3) if (v := [r[k] for r in rows if r[k] is not None]) else None
               for k in metrics}
    summary["failed_scores"] = sum(r[k] is None for r in rows for k in metrics)
    RESULTS.write_text(json.dumps({"model": s.llm_model, "judge": s.llm_model, "summary": summary,
                                   "rows": rows}, indent=2))
    print("\nMean scores (0..1):", json.dumps(summary, indent=2))
    print(f"Details -> {RESULTS}")
    await llm.aclose()


if __name__ == "__main__":
    p = argparse.ArgumentParser(description="RAGAS evaluation with an Ollama judge.")
    p.add_argument("--limit", type=int, default=None, help="only the first N questions")
    asyncio.run(run(p.parse_args().limit))
