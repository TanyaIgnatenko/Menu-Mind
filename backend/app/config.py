"""Application settings loaded from environment variables."""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings.

    Values are loaded from environment variables, with .env file as fallback.
    See .env.example for the required variables.
    """

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # API
    api_v1_prefix: str = "/api/v1"
    project_name: str = "MenuMind"
    debug: bool = False

    # Database
    database_url: str

    # External APIs
    gemini_api_key: str
    fal_api_key: str = ""  # Optional - if empty, image generation is disabled

    # Image processing
    max_image_size_mb: int = 10
    max_image_dimension: int = 1536

    # Image generation
    fal_model: str = "fal-ai/flux/schnell"
    image_concurrency: int = 8  # Max parallel FAL calls per menu
    image_timeout_seconds: float = 300.0  # 5 minutes
    image_storage_dir: Path = Path("./storage/images")
    image_url_prefix: str = "/images"  # Public path served by FastAPI StaticFiles

    # CORS
    cors_origins: list[str] = ["http://localhost:3000"]

    # External call timeouts
    gemini_timeout_seconds: float = 60.0


@lru_cache
def get_settings() -> Settings:
    """Return cached Settings instance.

    Cached to avoid re-reading env vars on every call.
    """
    return Settings()
