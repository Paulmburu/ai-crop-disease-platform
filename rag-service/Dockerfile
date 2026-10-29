# Multi-stage build, same pattern as python-ml-service.
#   Stage 1: uv installs locked runtime deps into /app/.venv (no dev/eval groups).
#   Stage 2: venv + app + knowledge notes; the embedding model is downloaded at build
#            time so containers start without internet access.
#
# Ollama is NOT in this image: it runs on the host (Mac GPU) and is reached via
# OLLAMA_BASE_URL (see docker-compose.yml).

FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:0.12 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project

FROM python:3.11-slim AS runtime
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1 LOG_JSON=true ENVIRONMENT=production \
    CHROMA_DIR=/data/chroma
RUN useradd --create-home --uid 1000 appuser && mkdir -p /data/chroma && chown -R appuser /data
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY app ./app
COPY scripts ./scripts
COPY knowledge ./knowledge
USER appuser
# Download all-MiniLM-L6-v2 (ONNX, ~80 MB) into the image.
RUN python -c "from chromadb.utils.embedding_functions import ONNXMiniLM_L6_V2 as E; E()(['warm up'])"
EXPOSE 8001
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8001/health', timeout=3)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
