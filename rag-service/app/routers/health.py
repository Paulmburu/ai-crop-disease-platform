"""GET /health (process alive) and GET /ready (index loaded AND Ollama model available)."""

from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse

from app.dependencies import get_rag_service
from app.schemas.ask import HealthResponse
from app.services.rag import RAGService

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health(rag: Annotated[RAGService, Depends(get_rag_service)]) -> HealthResponse:
    return HealthResponse(status="ok", chunks=rag.store.count())


@router.get("/ready", response_model=HealthResponse, responses={503: {"model": HealthResponse}})
async def ready(rag: Annotated[RAGService, Depends(get_rag_service)]) -> JSONResponse:
    chunks, llm_ready = rag.store.count(), await rag.llm.is_ready()
    ok = chunks > 0 and llm_ready
    body = HealthResponse(status="ready" if ok else "not_ready", chunks=chunks, llm_ready=llm_ready,
                          llm_model=rag.llm.model)
    return JSONResponse(status_code=200 if ok else 503, content=body.model_dump())
