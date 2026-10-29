"""Minimal async client for Ollama's REST API (https://github.com/ollama/ollama/blob/main/docs/api.md).

Two calls are enough:
    GET  /api/tags   which models are pulled (readiness check)
    POST /api/chat   generate a reply from system + user messages
"""

import httpx


class LLMUnavailableError(RuntimeError):
    """Ollama is not running, too slow, or the model is not pulled."""


class OllamaClient:
    def __init__(self, base_url: str, model: str, temperature: float = 0.1, timeout_s: float = 120.0) -> None:
        self.model = model
        self.temperature = temperature
        self._http = httpx.AsyncClient(base_url=base_url, timeout=httpx.Timeout(timeout_s, connect=5.0))

    async def is_ready(self) -> bool:
        """True if Ollama answers and the configured model is pulled."""
        try:
            r = await self._http.get("/api/tags", timeout=3.0)
            r.raise_for_status()
        except httpx.HTTPError:
            return False
        names = {m["name"] for m in r.json().get("models", [])}
        # "llama3.1" matches "llama3.1:latest"; "llama3.1:8b" must match exactly.
        return self.model in names or f"{self.model}:latest" in names

    async def chat(self, system: str, user: str) -> str:
        payload = {
            "model": self.model,
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            "stream": False,
            "options": {"temperature": self.temperature},
        }
        try:
            r = await self._http.post("/api/chat", json=payload)
        except httpx.HTTPError as exc:  # connection refused, timeout, ...
            raise LLMUnavailableError(f"Ollama request failed: {exc.__class__.__name__}") from exc
        if r.status_code == 404:
            raise LLMUnavailableError(f"Model '{self.model}' not found. Run: ollama pull {self.model}")
        if r.is_error:
            raise LLMUnavailableError(f"Ollama returned {r.status_code}: {r.text[:200]}")
        return r.json()["message"]["content"].strip()

    async def aclose(self) -> None:
        await self._http.aclose()
