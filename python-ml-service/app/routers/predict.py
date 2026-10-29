"""POST /api/v1/predict: upload a leaf photo, get the disease prediction.

curl -F "file=@leaf.jpg" "http://localhost:8000/api/v1/predict?top_k=3"
"""

from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.dependencies import get_inference_service
from app.schemas.prediction import ErrorResponse, Prediction, PredictionResponse
from app.services.inference import HEALTHY_LABEL, InferenceService

router = APIRouter(prefix="/api/v1", tags=["prediction"])


async def read_limited(file: UploadFile, max_bytes: int) -> bytes:
    """Read at most max_bytes + 1 bytes, so a huge upload is rejected without loading it all."""
    data = await file.read(max_bytes + 1)
    if len(data) > max_bytes:
        raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, f"File exceeds {max_bytes // (1024 * 1024)} MB")
    if not data:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Empty file")
    return data


@router.post(
    "/predict",
    response_model=PredictionResponse,
    responses={c: {"model": ErrorResponse} for c in (400, 413, 415, 422, 503)},
    summary="Classify a crop leaf image",
)
async def predict(
    file: Annotated[UploadFile, File(description="JPEG, PNG or WebP leaf photo")],
    service: Annotated[InferenceService, Depends(get_inference_service)],
    settings: Annotated[Settings, Depends(get_settings)],
    top_k: Annotated[int, Query(ge=1, le=10)] = 3,
) -> PredictionResponse:
    if file.content_type not in settings.allowed_content_types:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            f"Got {file.content_type!r}. Allowed: {', '.join(settings.allowed_content_types)}",
        )
    data = await read_limited(file, settings.max_upload_bytes)

    # Decoding + the forward pass are CPU-bound; a worker thread keeps the event loop responsive.
    result = await run_in_threadpool(service.predict, data, top_k)

    top = [Prediction(**vars(s)) for s in result.top_k]
    return PredictionResponse(
        status="ok" if top[0].confidence >= service.confidence_threshold else "uncertain",
        prediction=top[0],
        top_k=top,
        is_healthy=top[0].condition.lower() == HEALTHY_LABEL,
        confidence_threshold=service.confidence_threshold,
        model_version=result.model_version,
        inference_ms=result.inference_ms,
    )
