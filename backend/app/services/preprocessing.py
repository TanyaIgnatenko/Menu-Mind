"""Image preprocessing: validation, hashing, EXIF correction, resizing."""
import hashlib
import io

from PIL import Image, ImageOps

from app.config import get_settings
from app.exceptions import InvalidImageError

ALLOWED_FORMATS: frozenset[str] = frozenset({"JPEG", "PNG", "WEBP"})


def compute_image_hash(image_bytes: bytes) -> str:
    """Return SHA-256 hex digest of image bytes (used as cache key)."""
    return hashlib.sha256(image_bytes).hexdigest()


def preprocess_image(image_bytes: bytes) -> bytes:
    """Validate, fix orientation, resize, and re-encode as JPEG.

    Args:
        image_bytes: raw bytes from upload.

    Returns:
        Re-encoded JPEG bytes ready to send to VLM.

    Raises:
        InvalidImageError: if image is too large, unsupported format, or unreadable.
    """
    settings = get_settings()

    max_bytes = settings.max_image_size_mb * 1024 * 1024
    if len(image_bytes) > max_bytes:
        raise InvalidImageError(
            f"Image too large: {len(image_bytes) / 1024 / 1024:.1f}MB. "
            f"Max: {settings.max_image_size_mb}MB."
        )

    if not image_bytes:
        raise InvalidImageError("Empty file uploaded.")

    try:
        opened = Image.open(io.BytesIO(image_bytes))
        opened.load()
    except Exception as e:
        raise InvalidImageError(f"Could not open image: {e}") from e

    if opened.format not in ALLOWED_FORMATS:
        raise InvalidImageError(
            f"Unsupported format: {opened.format}. Allowed: JPEG, PNG, WEBP."
        )

    img: Image.Image | None = ImageOps.exif_transpose(opened)
    if img is None:
        raise InvalidImageError("Could not process image orientation.")

    max_dim = settings.max_image_dimension
    if max(img.size) > max_dim:
        img.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)

    if img.mode != "RGB":
        img = img.convert("RGB")

    output = io.BytesIO()
    img.save(output, "JPEG", quality=85, optimize=True)
    return output.getvalue()
