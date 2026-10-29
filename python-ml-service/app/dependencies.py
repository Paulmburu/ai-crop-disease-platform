"""FastAPI dependencies. Routers ask for the service here instead of importing a global,
so tests can swap in a fake with app.dependency_overrides or create_app(service=...)."""

from fastapi import Request

from app.services.inference import InferenceService


def get_inference_service(request: Request) -> InferenceService:
    return request.app.state.inference
