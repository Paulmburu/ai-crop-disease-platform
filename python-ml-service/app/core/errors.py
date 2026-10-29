"""Turn every failure into the same ErrorResponse JSON: {"error", "detail", "request_id"}.

Clients (the Go gateway, the Flutter app) then need only one error parser.
"""

import structlog
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.schemas.prediction import ErrorResponse
from app.services.inference import InvalidImageError, ModelNotLoadedError

log = structlog.get_logger(__name__)

_CODES = {
    400: "bad_request", 404: "not_found", 405: "method_not_allowed", 413: "payload_too_large",
    415: "unsupported_media_type", 422: "validation_error", 503: "service_unavailable",
}


def _error(request: Request, code: int, error: str, detail) -> JSONResponse:
    body = ErrorResponse(error=error, detail=detail, request_id=getattr(request.state, "request_id", None))
    return JSONResponse(status_code=code, content=body.model_dump())


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        return _error(request, exc.status_code, _CODES.get(exc.status_code, "http_error"), exc.detail)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
        detail = [{"loc": list(e["loc"]), "msg": e["msg"]} for e in exc.errors()]
        return _error(request, 422, "validation_error", detail)

    @app.exception_handler(InvalidImageError)
    async def invalid_image(request: Request, exc: InvalidImageError) -> JSONResponse:
        return _error(request, 400, "invalid_image", str(exc))

    @app.exception_handler(ModelNotLoadedError)
    async def not_loaded(request: Request, exc: ModelNotLoadedError) -> JSONResponse:
        return _error(request, 503, "model_not_loaded", str(exc))

    @app.exception_handler(Exception)
    async def unexpected(request: Request, exc: Exception) -> JSONResponse:
        # Log the real cause; never leak stack traces to clients.
        log.exception("unhandled_error", path=request.url.path)
        return _error(request, status.HTTP_500_INTERNAL_SERVER_ERROR, "internal_error", "Unexpected server error")
