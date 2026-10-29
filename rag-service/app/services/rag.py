"""RAGService: the whole question -> answer pipeline.

    question -> retrieve top-k chunks (optionally filtered to one disease)
             -> relevance gate (refuse if nothing is close enough)
             -> build grounded prompt -> LLM -> answer + sources
"""

import time
from dataclasses import dataclass
from typing import Protocol

from fastapi.concurrency import run_in_threadpool

from app.services.prompt import NO_ANSWER, SYSTEM_PROMPT, build_user_prompt
from app.services.vector_store import Hit, VectorStore

# A class-scoped question retrieves up to this many chunks: enough for one whole note.
CLASS_SCOPED_K = 8


class ChatModel(Protocol):
    model: str

    async def chat(self, system: str, user: str) -> str: ...

    async def is_ready(self) -> bool: ...


@dataclass(frozen=True)
class RAGResult:
    answer: str
    sources: list[Hit]
    model: str
    grounded: bool  # False when the relevance gate refused without calling the LLM
    retrieval_ms: float
    generation_ms: float


class RAGService:
    def __init__(self, store: VectorStore, llm: ChatModel, top_k: int = 4, max_distance: float = 0.75) -> None:
        self.store = store
        self.llm = llm
        self.top_k = top_k
        self.max_distance = max_distance

    async def retrieve(self, question: str, k: int | None = None, class_name: str | None = None) -> list[Hit]:
        # Embedding the query is CPU work: keep it off the event loop.
        return await run_in_threadpool(self.store.search, question, k or self.top_k, class_name)

    async def ask(self, question: str, top_k: int | None = None, class_name: str | None = None) -> RAGResult:
        t0 = time.perf_counter()
        if class_name:
            # The classifier already chose the topic: "How do I control it?" alone embeds far from
            # every note, so name the disease in the query and skip the gate (the filter keeps
            # results on-topic). One note is only a handful of chunks, so take all of it
            # (up to CLASS_SCOPED_K): "what do I do?" then always sees the Management section
            # instead of the model filling gaps from memory.
            query = f"{class_name.replace('_', ' ')}: {question}"
            hits = await self.retrieve(query, max(top_k or self.top_k, CLASS_SCOPED_K), class_name)
            relevant = hits
        else:
            hits = await self.retrieve(question, top_k)
            relevant = [h for h in hits if h.distance <= self.max_distance]
        t1 = time.perf_counter()
        if not relevant:
            return RAGResult(NO_ANSWER, [], self.llm.model, False, round((t1 - t0) * 1000, 1), 0.0)

        answer = await self.llm.chat(SYSTEM_PROMPT, build_user_prompt(question, relevant, class_name))
        t2 = time.perf_counter()
        return RAGResult(answer, relevant, self.llm.model, True,
                         round((t1 - t0) * 1000, 1), round((t2 - t1) * 1000, 1))
