"""FastAPI application factory for the RAG service.

Run locally (from rag-service/, with the Ollama app running):
    uv run uvicorn app.main:app --reload --port 8001
    open http://localhost:8001/docs

Startup: open the Chroma store; if it is empty, index knowledge/ automatically.
Ollama is NOT required to start: /ready reports 503 and /ask returns 503 until it is up.
"""

import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request, Response
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.core.errors import register_error_handlers
from app.core.logging import configure_logging
from app.routers import ask, health, index
from app.services.documents import build_chunks
from app.services.llm import OllamaClient
from app.services.rag import RAGService
from app.services.vector_store import VectorStore, default_embedder

log = structlog.get_logger(__name__)


def create_app(rag: RAGService | None = None) -> FastAPI:
    """Build the app. Pass `rag` (e.g. with fakes) in tests to skip Chroma/Ollama setup."""
    settings = get_settings()
    configure_logging(settings.log_level, settings.log_json)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        llm = None
        if rag is None:
            store = VectorStore(settings.chroma_dir, settings.collection, default_embedder())
            if store.count() == 0:
                chunks = build_chunks(settings.knowledge_dir, settings.chunk_size, settings.chunk_overlap)
                report = await run_in_threadpool(store.sync, chunks)
                log.info("knowledge_indexed", chunks=report.total)
            llm = OllamaClient(settings.ollama_base_url, settings.llm_model, settings.llm_temperature,
                               settings.llm_timeout_s)
            app.state.rag = RAGService(store, llm, settings.top_k, settings.max_distance)
        log.info("startup_complete", chunks=app.state.rag.store.count(), model=app.state.rag.llm.model,
                 llm_ready=await app.state.rag.llm.is_ready())
        yield
        if llm is not None:
            await llm.aclose()

    app = FastAPI(title="Crop Disease RAG Service", version="1.0.0",
                  description="Answers crop-disease questions from a curated, cited knowledge base.",
                  lifespan=lifespan)
    if rag is not None:
        app.state.rag = rag

    app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins, allow_methods=["GET", "POST"],
                       allow_headers=["*"])

    @app.middleware("http")
    async def request_context(request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        request.state.request_id = request_id
        structlog.contextvars.bind_contextvars(request_id=request_id)
        start = time.perf_counter()
        try:
            response = await call_next(request)
        finally:
            structlog.contextvars.unbind_contextvars("request_id")
        response.headers["X-Request-ID"] = request_id
        log.info("request", method=request.method, path=request.url.path, status=response.status_code,
                 ms=round((time.perf_counter() - start) * 1000, 1), request_id=request_id)
        return response

    register_error_handlers(app)
    app.include_router(health.router)
    app.include_router(ask.router)
    app.include_router(index.router)
    return app


app = create_app()
