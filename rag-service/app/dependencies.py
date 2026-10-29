"""Routers get the RAG service from app.state, so tests can inject a fake one."""

from fastapi import Request

from app.services.rag import RAGService


def get_rag_service(request: Request) -> RAGService:
    return request.app.state.rag
