"""Every failure becomes {"error", "detail", "request_id"}: same shape as the ML service."""

import structlog
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.schemas.ask import ErrorResponse
from app.services.llm import LLMUnavailableError

log = structlog.get_logger(__name__)

_CODES = {400: "bad_request", 404: "not_found", 405: "method_not_allowed", 422: "validation_error",
          503: "service_unavailable"}


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

    @app.exception_handler(LLMUnavailableError)
    async def llm_down(request: Request, exc: LLMUnavailableError) -> JSONResponse:
        log.warning("llm_unavailable", reason=str(exc))
        return _error(request, 503, "llm_unavailable", str(exc))

    @app.exception_handler(Exception)
    async def unexpected(request: Request, exc: Exception) -> JSONResponse:
        log.exception("unhandled_error", path=request.url.path)
        return _error(request, 500, "internal_error", "Unexpected server error")
