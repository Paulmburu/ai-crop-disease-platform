"""Request/response shapes for the RAG API (the contract the Go gateway consumes)."""

from pydantic import BaseModel, Field


class AskRequest(BaseModel):
    question: str = Field(min_length=3, max_length=500, examples=["How do I treat late blight on tomatoes?"])
    class_name: str | None = Field(
        default=None,
        max_length=100,
        description="Optional label from the image classifier (Phase 2). Restricts retrieval to that disease.",
        examples=["Tomato_Late_blight"],
    )
    top_k: int | None = Field(default=None, ge=1, le=10, description="Chunks to retrieve (default from settings)")


class Source(BaseModel):
    index: int = Field(description="The [n] number used in the answer")
    title: str
    section: str
    source_file: str
    class_name: str | None = None
    references: list[str] = Field(default_factory=list, description="Public URLs the note is based on")
    distance: float = Field(description="Cosine distance to the question (lower = more relevant)")


class AskResponse(BaseModel):
    answer: str
    sources: list[Source]
    grounded: bool = Field(description="False when no relevant passage was found and the LLM was not called")
    model: str
    retrieval_ms: float
    generation_ms: float


class IndexResponse(BaseModel):
    upserted: int
    deleted: int
    total_chunks: int


class HealthResponse(BaseModel):
    status: str
    chunks: int
    llm_ready: bool | None = None
    llm_model: str | None = None


class ErrorResponse(BaseModel):
    error: str
    detail: str | list
    request_id: str | None = None
