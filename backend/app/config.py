"""Application settings loaded from environment variables."""
from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
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

    @field_validator("database_url")
    @classmethod
    def _use_asyncpg_driver(cls, v: str) -> str:
        """Managed hosts (Railway, Heroku, …) hand out a plain
        ``postgres://`` / ``postgresql://`` URL, but the async SQLAlchemy engine
        needs the asyncpg driver. Normalize the scheme so DATABASE_URL can be
        referenced as-is from the provider's connection string.
        """
        prefix, sep, rest = v.partition("://")
        if not sep:
            return v
        if prefix in ("postgres", "postgresql"):
            return f"postgresql+asyncpg://{rest}"
        return v

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

    # S3 storage (if s3_bucket is set, use S3; otherwise local filesystem)
    s3_bucket: str = ""
    s3_region: str = "eu-central-1"
    s3_public_url_base: str = ""  # e.g. https://bucket.s3.eu-central-1.amazonaws.com

    # Store the uploaded menu photo under the `_uploads/` S3 prefix so failed
    # scans can be inspected. Privacy-sensitive: OFF by default. Enable only once
    # the privacy policy reflects it AND a 30-day lifecycle-expiry rule exists on
    # that prefix (otherwise photos are retained indefinitely). See docs.
    store_menu_uploads: bool = False

    # Analytics (PostHog, server-side). Empty api key → analytics is a no-op.
    posthog_api_key: str = ""
    posthog_host: str = "https://eu.i.posthog.com"

    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "https://menu-mind-tawny.vercel.app"]

    # External call timeouts
    gemini_timeout_seconds: float = 60.0

    # ── Rate limiting ──────────────────────────────────────────────────────────
    # Set RATE_LIMIT_ENABLED=false in .env to bypass limits during development.
    rate_limit_enabled: bool = True

    # Max unique menus one IP can upload per calendar day (UTC).
    # Cache hits (same image re-uploaded) never count toward this limit.
    rate_limit_per_ip_daily: int = 5

    # Hard cap on total unique menus processed by the whole app per day.
    # Protects against a single beta invite going viral unexpectedly.
    rate_limit_global_daily: int = 50


@lru_cache
def get_settings() -> Settings:
    """Return cached Settings instance.

    Cached to avoid re-reading env vars on every call.
    """
    return Settings()
