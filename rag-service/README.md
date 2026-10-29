# rag-service (Phase 3)

Answers "what do I do about this?" questions from a small, cited knowledge base, using a local LLM
(Ollama). It takes the classifier's label (`class_name`) from Phase 2, so advice is scoped to the
disease the phone detected.
Full walkthrough: [`docs/PHASE_3_RAG_PIPELINE.md`](../docs/PHASE_3_RAG_PIPELINE.md).
API contract: [`docs/API_CONTRACT.md`](../docs/API_CONTRACT.md).

```
knowledge/              one markdown note per disease class (3 potato notes; others in _other/)
app/
  main.py               create_app(): builds the index on first start, request-id middleware
  config.py             Settings from env vars / .env
  services/
    documents.py        load notes + front matter, split by "## " section into chunks
    vector_store.py     ChromaDB + all-MiniLM-L6-v2 (ONNX, no PyTorch); idempotent sync
    llm.py              Ollama REST client (/api/chat, /api/tags)
    prompt.py           system prompt, <context>/<question> tags, numbered citations
    rag.py              retrieve -> relevance gate or class scoping -> prompt -> answer
  routers/              health.py, ask.py, index.py
scripts/ingest.py       (re)index knowledge/ into .chroma/
scripts/evaluate.py     RAGAS evaluation with Ollama as the judge
eval/questions.json     5 potato questions with reference answers
tests/                  20 tests with a fake embedder + fake LLM (no Ollama needed)
```

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness, plus chunk count |
| GET | `/ready` | 200 only when the index has chunks **and** the Ollama model is available |
| POST | `/api/v1/ask` | `{"question", "class_name"?, "top_k"?}` → answer with `[n]` citations and sources |
| POST | `/api/v1/index` | Re-sync the index with `knowledge/` (idempotent) |
| GET | `/api/v1/classes` | Disease labels the knowledge base covers |
| GET | `/docs` | Swagger UI |

## Run locally

```bash
# 1. Ollama (desktop app, or `ollama serve` in a terminal)
ollama pull llama3.1:8b          # ~4.9 GB, once
ollama list                      # the exact tag must match LLM_MODEL (default llama3.1:8b)

# 2. Service
cd rag-service
uv sync
uv run pytest                    # 20 tests, <1 s, no Ollama needed
uv run python -m scripts.ingest  # "3 notes -> 17 chunks"; run again -> "0 upserted, 0 deleted"
uv run uvicorn app.main:app --reload --port 8001
```

```bash
curl localhost:8001/ready
curl -X POST localhost:8001/api/v1/ask -H 'Content-Type: application/json' \
     -d '{"question": "What should I do about this?", "class_name": "Potato___Late_blight"}'
curl -X POST localhost:8001/api/v1/ask -H 'Content-Type: application/json' \
     -d '{"question": "How do I fix my car engine?"}'      # refused, no LLM call
```

How a question is answered:
- **With `class_name`:** retrieval is limited to that disease's note (the whole note, so the
  Management section is always there), and the relevance gate is skipped.
- **Without:** the top chunks are retrieved; if even the best one is not close enough
  (`MAX_DISTANCE`), the service answers "I don't have enough information…" without calling the LLM.

## Evaluate (RAGAS)

```bash
uv run --group eval python -m scripts.evaluate              # ~8 min for 5 questions on an M-series Mac
uv run --group eval python -m scripts.evaluate --limit 1    # quick check
```

Writes `eval/results.json`. The local 8B model is also the judge, so scores are directional:
compare runs with each other, not with published numbers. The `eval` group pins
`langchain-community<0.4` because RAGAS 0.4.3 imports a module that newer versions removed.

## Run with Docker

From the repo root, with Docker Desktop and Ollama running on the Mac:

```bash
docker compose up --build -d rag-service
curl localhost:8001/ready          # chunks 17, llm_ready true
docker compose down
```

- Ollama stays on the host, so it can use the Mac GPU; the container reaches it at
  `host.docker.internal:11434`.
- The index is stored in the `rag-index` volume and built automatically on first start.
- The image is ≈1.2 GB: about 470 MB of Python packages (chromadb pulls in about 126 MB of
  Kubernetes client code) plus the 167 MB embedding-model cache baked in at build time.

## Edit the knowledge base

Add or change a note in `knowledge/` (see `knowledge/README.md` for the format), then run
`uv run python -m scripts.ingest` or `POST /api/v1/index`. Only changed chunks are re-embedded.
Keep each `## ` section self-contained: a chunk like "Phytophthora infestans." that doesn't name
its subject is hard to retrieve. Rewriting those lines raised faithfulness from 0.77 to 0.88.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/ready` → `llm_ready: false` | Start Ollama; check `LLM_MODEL` matches `ollama list` exactly |
| `/ask` → 503 `llm_unavailable` | Same as above; the message says which |
| First answer takes 10–50 s | Ollama is loading the model; later answers take a few seconds |
| Answer cites the wrong disease | Pass `class_name` from the classifier |
| Docker: `llm_ready: false` | Ollama must run on the host; on Linux, `extra_hosts` in compose maps `host.docker.internal` |
