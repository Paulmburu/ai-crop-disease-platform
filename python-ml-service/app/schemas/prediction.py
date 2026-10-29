"""API response shapes (Pydantic). These are the public contract the Go gateway consumes."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class _Schema(BaseModel):
    model_config = ConfigDict(protected_namespaces=())  # allow "model_version" field names


class Prediction(_Schema):
    class_name: str = Field(examples=["Tomato___Late_blight"], description="Raw label from training")
    plant: str = Field(examples=["Tomato"])
    condition: str = Field(examples=["Late blight"])
    confidence: float = Field(ge=0, le=1, examples=[0.93])


class PredictionResponse(_Schema):
    status: Literal["ok", "uncertain"] = Field(
        description="'uncertain' when top-1 confidence is below the model's threshold: "
        "ask the user for a clearer photo instead of showing a diagnosis")
    prediction: Prediction = Field(description="Top-1 result")
    top_k: list[Prediction] = Field(description="Best k results, highest confidence first")
    is_healthy: bool
    confidence_threshold: float = Field(examples=[0.62])
    model_version: str = Field(examples=["v1"])
    inference_ms: float = Field(examples=[38.5])


class ModelInfo(_Schema):
    model_version: str
    num_classes: int
    class_names: list[str]
    image_size: int
    val_acc: float | None
    confidence_threshold: float
    device: str


class HealthResponse(_Schema):
    status: str = Field(examples=["ok"])
    model_loaded: bool
    model_version: str | None = None


class ErrorResponse(_Schema):
    """Every error the service returns (400, 404, 413, 415, 422, 500, 503) has this shape."""

    error: str = Field(examples=["unsupported_media_type"])
    detail: str | list = Field(examples=["Allowed types: image/jpeg, image/png"])
    request_id: str | None = None
