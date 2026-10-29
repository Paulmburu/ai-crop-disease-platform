"""POST /api/v1/ask: answer a crop-disease question from the knowledge base.

curl -X POST localhost:8001/api/v1/ask -H 'Content-Type: application/json' \
     -d '{"question": "How do I manage late blight?", "class_name": "Tomato_Late_blight"}'
"""

from typing import Annotated

import structlog
from fastapi import APIRouter, Depends

from app.dependencies import get_rag_service
from app.schemas.ask import AskRequest, AskResponse, ErrorResponse, Source
from app.services.rag import RAGService

router = APIRouter(prefix="/api/v1", tags=["rag"])
log = structlog.get_logger(__name__)


@router.post("/ask", response_model=AskResponse, responses={c: {"model": ErrorResponse} for c in (422, 503)})
async def ask(body: AskRequest, rag: Annotated[RAGService, Depends(get_rag_service)]) -> AskResponse:
    result = await rag.ask(body.question, body.top_k, body.class_name)
    log.info("answered", grounded=result.grounded, sources=len(result.sources),
             retrieval_ms=result.retrieval_ms, generation_ms=result.generation_ms)
    return AskResponse(
        answer=result.answer,
        sources=[
            Source(
                index=i,
                title=h.meta.get("title", ""),
                section=h.meta.get("section", ""),
                source_file=h.meta.get("source", ""),
                class_name=h.meta.get("class_name"),
                references=[u.strip() for u in h.meta.get("sources", "").split("|") if u.strip()],
                distance=round(h.distance, 4),
            )
            for i, h in enumerate(result.sources, 1)
        ],
        grounded=result.grounded,
        model=result.model,
        retrieval_ms=result.retrieval_ms,
        generation_ms=result.generation_ms,
    )
