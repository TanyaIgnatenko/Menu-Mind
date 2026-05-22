"""Local filesystem storage for generated images.

Images are stored under settings.image_storage_dir, organized by menu UUID.
The service exposes a URL prefix (e.g. "/images") that maps to this directory
via FastAPI StaticFiles.

Phase 5 will swap this implementation for an S3-backed one; the interface is
designed to make that migration straightforward.
"""
import hashlib
from pathlib import Path
from uuid import UUID

from app.config import get_settings
from app.utils.logging import get_logger

logger = get_logger(__name__)


def _settings() -> tuple[Path, str]:
    s = get_settings()
    return s.image_storage_dir, s.image_url_prefix


def ensure_storage_dir() -> None:
    """Create the image storage directory if missing. Idempotent."""
    storage_dir, _ = _settings()
    storage_dir.mkdir(parents=True, exist_ok=True)


def save_menu_image(menu_id: UUID, dish_index: int, image_bytes: bytes) -> str:
    """Save image bytes to disk and return the public URL.

    Path layout: <storage_dir>/<menu_id>/<dish_index>.jpg
    Public URL:  <url_prefix>/<menu_id>/<dish_index>.jpg
    """
    storage_dir, url_prefix = _settings()
    menu_dir = storage_dir / str(menu_id)
    menu_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{dish_index}.jpg"
    file_path = menu_dir / filename
    file_path.write_bytes(image_bytes)

    public_url = f"{url_prefix}/{menu_id}/{filename}"
    logger.info(
        "image_saved",
        menu_id=str(menu_id),
        dish_index=dish_index,
        path=str(file_path),
        size_bytes=len(image_bytes),
    )
    return public_url


def cache_key_for_dish(name_english: str, category_english: str) -> str:
    """Stable cache key for a dish so the same dish gets the same image.

    Hash of normalized name + category. Lower-cased, whitespace-collapsed.
    """
    normalized_name = " ".join(name_english.lower().split())
    normalized_cat = " ".join(category_english.lower().split())
    raw = f"{normalized_name}|{normalized_cat}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]


def save_shared_image(cache_key: str, image_bytes: bytes) -> str:
    """Save image under the shared cache directory and return its URL.

    Shared images live under <storage_dir>/_cache/<cache_key>.jpg and can be
    reused across menus.
    """
    storage_dir, url_prefix = _settings()
    cache_dir = storage_dir / "_cache"
    cache_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{cache_key}.jpg"
    file_path = cache_dir / filename
    file_path.write_bytes(image_bytes)

    return f"{url_prefix}/_cache/{filename}"


def lookup_cached_url(cache_key: str) -> str | None:
    """Return URL if an image already exists for this cache key, else None."""
    storage_dir, url_prefix = _settings()
    filename = f"{cache_key}.jpg"
    file_path = storage_dir / "_cache" / filename
    if file_path.exists():
        return f"{url_prefix}/_cache/{filename}"
    return None
