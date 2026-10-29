"""Knowledge-base admin endpoints.

POST /api/v1/index    re-sync the vector store with knowledge/ (idempotent)
GET  /api/v1/classes  disease labels the knowledge base covers (valid `class_name` values)
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.dependencies import get_rag_service
from app.schemas.ask import IndexResponse
from app.services.documents import build_chunks
from app.services.rag import RAGService

router = APIRouter(prefix="/api/v1", tags=["knowledge base"])


@router.post("/index", response_model=IndexResponse)
async def reindex(rag: Annotated[RAGService, Depends(get_rag_service)],
                  settings: Annotated[Settings, Depends(get_settings)]) -> IndexResponse:
    chunks = build_chunks(settings.knowledge_dir, settings.chunk_size, settings.chunk_overlap)
    report = await run_in_threadpool(rag.store.sync, chunks)  # embedding is CPU-bound
    return IndexResponse(upserted=report.upserted, deleted=report.deleted, total_chunks=report.total)


@router.get("/classes", response_model=list[str])
async def classes(rag: Annotated[RAGService, Depends(get_rag_service)]) -> list[str]:
    return rag.store.class_names()
