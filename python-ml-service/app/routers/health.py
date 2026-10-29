"""Liveness and readiness probes.

GET /health  -> 200 while the process is up (Docker/Kubernetes liveness: restart if it fails)
GET /ready   -> 200 only when the model is loaded, else 503 (readiness: send traffic only when ready)
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse

from app.dependencies import get_inference_service
from app.schemas.prediction import HealthResponse
from app.services.inference import InferenceService

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health(service: Annotated[InferenceService, Depends(get_inference_service)]) -> HealthResponse:
    return HealthResponse(status="ok", model_loaded=service.is_loaded, model_version=service.model_version or None)


@router.get("/ready", response_model=HealthResponse, responses={503: {"model": HealthResponse}})
async def ready(service: Annotated[InferenceService, Depends(get_inference_service)]) -> JSONResponse:
    body = HealthResponse(
        status="ready" if service.is_loaded else "not_ready",
        model_loaded=service.is_loaded,
        model_version=service.model_version or None,
    )
    return JSONResponse(status_code=200 if service.is_loaded else 503, content=body.model_dump())
