"""FastAPI application factory.

Run locally (from python-ml-service/):
    uv run uvicorn app.main:app --reload --port 8000
    open http://localhost:8000/docs        # interactive API docs

Request flow:
    middleware (request id + timing log) -> router -> InferenceService (worker thread)
    errors anywhere -> app/core/errors.py -> ErrorResponse JSON
"""

import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.core.errors import register_error_handlers
from app.core.logging import configure_logging
from app.routers import health, models, predict
from app.services.inference import InferenceService

log = structlog.get_logger(__name__)


def create_app(service: InferenceService | None = None) -> FastAPI:
    """Build the app. Pass `service` (e.g. a fake in tests) to skip loading the real model."""
    settings = get_settings()
    configure_logging(settings.log_level, settings.log_json)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        if service is None:
            # Load once at startup. A missing model fails fast here instead of on the first request.
            real = InferenceService(settings.checkpoint_path, settings.device)
            real.load()
            app.state.inference = real
        log.info("startup_complete", env=settings.environment)
        yield
        log.info("shutdown")

    app = FastAPI(
        title="Crop Disease ML Service",
        version="1.0.0",
        description="Classifies crop leaf photos into PlantVillage disease classes.",
        lifespan=lifespan,
    )
    if service is not None:
        app.state.inference = service

    app.add_middleware(
        CORSMiddleware, allow_origins=settings.cors_origins, allow_methods=["GET", "POST"], allow_headers=["*"]
    )

    @app.middleware("http")
    async def request_context(request: Request, call_next) -> Response:
        # Reuse the gateway's X-Request-ID if present so one id follows a request across services.
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
    app.include_router(predict.router)
    app.include_router(models.router)
    return app


app = create_app()
