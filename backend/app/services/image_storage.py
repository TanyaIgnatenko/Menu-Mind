"""Image storage — local filesystem or S3, selected by config.

If settings.s3_bucket is set, images are stored in S3. Otherwise they go to
the local filesystem (used for local development with Docker).

The public interface — cache_key_for_dish, save_shared_image, lookup_cached_url,
ensure_storage_dir — is identical in both modes, so calling code (image
generation orchestration) never needs to know which backend is active.
"""
import hashlib
from functools import lru_cache
from pathlib import Path

from app.config import get_settings
from app.utils.logging import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Cache key (storage-agnostic)
# ---------------------------------------------------------------------------

def cache_key_for_dish(name_english: str, category_english: str) -> str:
    """Stable cache key for a dish so the same dish gets the same image.

    Hash of normalized name + category. Lower-cased, whitespace-collapsed.
    """
    normalized_name = " ".join(name_english.lower().split())
    normalized_cat = " ".join(category_english.lower().split())
    raw = f"{normalized_name}|{normalized_cat}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]


def _use_s3() -> bool:
    return bool(get_settings().s3_bucket)


# ---------------------------------------------------------------------------
# S3 backend
# ---------------------------------------------------------------------------

@lru_cache
def _s3_client():  # type: ignore[no-untyped-def]
    """Cached boto3 S3 client. Uses the App Runner IAM role in prod, or local
    aws-configure credentials in development."""
    import boto3

    settings = get_settings()
    return boto3.client("s3", region_name=settings.s3_region)


def _s3_key(cache_key: str) -> str:
    """Object key within the bucket for a shared cache image."""
    return f"_cache/{cache_key}.jpg"


def _s3_public_url(object_key: str) -> str:
    settings = get_settings()
    base = settings.s3_public_url_base or (
        f"https://{settings.s3_bucket}.s3.{settings.s3_region}.amazonaws.com"
    )
    return f"{base.rstrip('/')}/{object_key}"


def _s3_save_shared_image(cache_key: str, image_bytes: bytes) -> str:
    settings = get_settings()
    object_key = _s3_key(cache_key)
    _s3_client().put_object(
        Bucket=settings.s3_bucket,
        Key=object_key,
        Body=image_bytes,
        ContentType="image/jpeg",
    )
    url = _s3_public_url(object_key)
    logger.info("image_saved_s3", cache_key=cache_key, url=url, size_bytes=len(image_bytes))
    return url


def _s3_lookup_cached_url(cache_key: str) -> str | None:
    from botocore.exceptions import ClientError

    settings = get_settings()
    object_key = _s3_key(cache_key)
    try:
        _s3_client().head_object(Bucket=settings.s3_bucket, Key=object_key)
    except ClientError:
        return None
    return _s3_public_url(object_key)


# ---------------------------------------------------------------------------
# Local filesystem backend
# ---------------------------------------------------------------------------

def _local_paths() -> tuple[Path, str]:
    s = get_settings()
    return s.image_storage_dir, s.image_url_prefix


def _local_save_shared_image(cache_key: str, image_bytes: bytes) -> str:
    storage_dir, url_prefix = _local_paths()
    cache_dir = storage_dir / "_cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{cache_key}.jpg"
    (cache_dir / filename).write_bytes(image_bytes)
    return f"{url_prefix}/_cache/{filename}"


def _local_lookup_cached_url(cache_key: str) -> str | None:
    storage_dir, url_prefix = _local_paths()
    filename = f"{cache_key}.jpg"
    if (storage_dir / "_cache" / filename).exists():
        return f"{url_prefix}/_cache/{filename}"
    return None


# ---------------------------------------------------------------------------
# Public interface (dispatches to S3 or local)
# ---------------------------------------------------------------------------

def ensure_storage_dir() -> None:
    """Create the local image directory if using local storage. No-op for S3."""
    if _use_s3():
        return
    storage_dir, _ = _local_paths()
    storage_dir.mkdir(parents=True, exist_ok=True)


def save_shared_image(cache_key: str, image_bytes: bytes) -> str:
    """Save image under the shared cache and return its public URL."""
    if _use_s3():
        return _s3_save_shared_image(cache_key, image_bytes)
    return _local_save_shared_image(cache_key, image_bytes)


def lookup_cached_url(cache_key: str) -> str | None:
    """Return URL if an image already exists for this cache key, else None."""
    if _use_s3():
        return _s3_lookup_cached_url(cache_key)
    return _local_lookup_cached_url(cache_key)