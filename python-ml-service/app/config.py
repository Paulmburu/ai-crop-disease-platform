"""Service settings, read from environment variables (or a local .env file).

Every field can be overridden with an env var of the same name in upper case,
e.g. MODEL_VERSION=v2 or MAX_UPLOAD_MB=10. See .env.example.
"""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # protected_namespaces=() lets us use field names starting with "model_" without warnings.
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", protected_namespaces=())

    app_name: str = "crop-disease-ml-service"
    environment: Literal["development", "production", "test"] = "development"
    log_level: str = "INFO"
    log_json: bool = False  # True in Docker: one JSON object per log line

    model_dir: Path = Path("models")
    model_version: str = "v1"
    device: Literal["cpu", "mps", "cuda", "auto"] = "cpu"  # cpu is predictable for serving

    max_upload_mb: float = 5.0
    allowed_content_types: tuple[str, ...] = ("image/jpeg", "image/png", "image/webp")
    cors_origins: list[str] = ["http://localhost:3000"]

    @property
    def checkpoint_path(self) -> Path:
        """Matches the file name Phase 1 writes: mobilenetv2_<version>_best.pt."""
        return self.model_dir / f"mobilenetv2_{self.model_version}_best.pt"

    @property
    def max_upload_bytes(self) -> int:
        return int(self.max_upload_mb * 1024 * 1024)


@lru_cache
def get_settings() -> Settings:
    """Settings are read once per process."""
    return Settings()
