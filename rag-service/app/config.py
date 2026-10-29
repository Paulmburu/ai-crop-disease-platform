"""Service settings, read from environment variables (or a local .env file).

Every field can be overridden with an env var of the same name in upper case,
e.g. LLM_MODEL=llama3.2 or TOP_K=6. See .env.example.
"""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "crop-disease-rag-service"
    environment: Literal["development", "production", "test"] = "development"
    log_level: str = "INFO"
    log_json: bool = False

    # Knowledge base and vector store
    knowledge_dir: Path = Path("knowledge")
    chroma_dir: Path = Path(".chroma")
    collection: str = "crop_disease_kb"
    chunk_size: int = 800  # characters, not tokens
    chunk_overlap: int = 100

    # Retrieval
    top_k: int = 4
    # Cosine distance (0 = identical, 2 = opposite). Above this, the best chunk is
    # treated as unrelated and the service refuses instead of calling the LLM.
    max_distance: float = 0.75

    # Ollama (local LLM)
    ollama_base_url: str = "http://localhost:11434"
    llm_model: str = "llama3.1:8b"  # exact tag from `ollama list`
    llm_temperature: float = 0.1  # low = factual, repeatable answers
    llm_timeout_s: float = 120.0

    cors_origins: list[str] = ["http://localhost:3000"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
