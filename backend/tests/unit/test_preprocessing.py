"""Unit tests for image preprocessing service."""
from io import BytesIO

import pytest
from PIL import Image

from app.exceptions import InvalidImageError
from app.services.preprocessing import (
    compute_image_hash,
    preprocess_image,
)


def _jpeg_bytes(size: tuple[int, int] = (100, 100), color: tuple[int, int, int] = (255, 0, 0)) -> bytes:
    img = Image.new("RGB", size, color=color)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return buf.getvalue()


def _png_bytes(size: tuple[int, int] = (100, 100)) -> bytes:
    img = Image.new("RGB", size, color=(0, 255, 0))
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


class TestComputeImageHash:
    def test_same_bytes_yield_same_hash(self) -> None:
        data = _jpeg_bytes()
        assert compute_image_hash(data) == compute_image_hash(data)

    def test_different_bytes_yield_different_hashes(self) -> None:
        a = _jpeg_bytes(color=(255, 0, 0))
        b = _jpeg_bytes(color=(0, 0, 255))
        assert compute_image_hash(a) != compute_image_hash(b)

    def test_hash_is_64_hex_chars(self) -> None:
        h = compute_image_hash(_jpeg_bytes())
        assert len(h) == 64
        assert all(c in "0123456789abcdef" for c in h)


class TestPreprocessImage:
    def test_valid_jpeg_passes(self) -> None:
        result = preprocess_image(_jpeg_bytes())
        assert isinstance(result, bytes)
        assert len(result) > 0

    def test_valid_png_converted_to_jpeg(self) -> None:
        result = preprocess_image(_png_bytes())
        img = Image.open(BytesIO(result))
        assert img.format == "JPEG"

    def test_large_image_resized(self) -> None:
        big = _jpeg_bytes(size=(3000, 3000))
        result = preprocess_image(big)
        img = Image.open(BytesIO(result))
        assert max(img.size) <= 1536

    def test_empty_bytes_raises(self) -> None:
        with pytest.raises(InvalidImageError, match="Empty"):
            preprocess_image(b"")

    def test_too_large_raises(self) -> None:
        # 11 MB random-looking data
        huge = b"x" * (11 * 1024 * 1024)
        with pytest.raises(InvalidImageError, match="too large"):
            preprocess_image(huge)

    def test_corrupt_bytes_raises(self) -> None:
        with pytest.raises(InvalidImageError):
            preprocess_image(b"this is not an image")

    def test_unsupported_format_raises(self) -> None:
        # Create a GIF in memory
        img = Image.new("RGB", (50, 50), color=(0, 0, 0))
        buf = BytesIO()
        img.save(buf, format="GIF")
        with pytest.raises(InvalidImageError, match="Unsupported"):
            preprocess_image(buf.getvalue())
