# Multi-stage build.
#   Stage 1 (builder): uv installs locked dependencies into /app/.venv (CPU-only torch on Linux).
#   Stage 2 (runtime): copies only the venv + app code. No uv, no compilers, non-root user.
#
# Build:  docker build -t crop-ml-service .
# Run:    docker run -p 8000:8000 -v "$PWD/models:/app/models:ro" crop-ml-service

FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:0.12 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
WORKDIR /app
# Dependencies first: this layer is cached until pyproject.toml/uv.lock change.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-project

FROM python:3.11-slim AS runtime
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1 LOG_JSON=true ENVIRONMENT=production
RUN useradd --create-home --uid 1000 appuser
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY app ./app
# Models are mounted at runtime (-v ./models:/app/models) or baked in by uncommenting:
# COPY models ./models
USER appuser
EXPOSE 8000
# Liveness check; uses Python so we don't need curl in the image.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=3)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
