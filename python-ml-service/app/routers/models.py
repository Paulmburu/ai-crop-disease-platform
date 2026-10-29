"""GET /api/v1/models: which model is being served (version, classes, input size)."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_inference_service
from app.schemas.prediction import ErrorResponse, ModelInfo
from app.services.inference import InferenceService

router = APIRouter(prefix="/api/v1", tags=["models"])


@router.get("/models", response_model=ModelInfo, responses={503: {"model": ErrorResponse}})
async def model_info(service: Annotated[InferenceService, Depends(get_inference_service)]) -> ModelInfo:
    if not service.is_loaded:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Model is not loaded")
    return ModelInfo(
        model_version=service.model_version,
        num_classes=len(service.class_names),
        class_names=service.class_names,
        image_size=service.image_size,
        val_acc=service.val_acc,
        confidence_threshold=service.confidence_threshold,
        device=str(service.device),
    )
