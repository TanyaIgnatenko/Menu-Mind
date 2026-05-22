"""Unit tests for image storage service."""
import tempfile
from pathlib import Path
from unittest.mock import patch
from uuid import uuid4

from app.services.image_storage import (
    cache_key_for_dish,
    lookup_cached_url,
    save_menu_image,
    save_shared_image,
)


class TestCacheKeyForDish:
    def test_same_dish_same_key(self) -> None:
        k1 = cache_key_for_dish("Wiener Schnitzel", "Mains")
        k2 = cache_key_for_dish("Wiener Schnitzel", "Mains")
        assert k1 == k2

    def test_case_insensitive(self) -> None:
        k1 = cache_key_for_dish("Wiener Schnitzel", "Mains")
        k2 = cache_key_for_dish("WIENER SCHNITZEL", "mains")
        assert k1 == k2

    def test_whitespace_normalized(self) -> None:
        k1 = cache_key_for_dish("Wiener  Schnitzel", "Mains")
        k2 = cache_key_for_dish("Wiener Schnitzel ", "Mains")
        assert k1 == k2

    def test_different_dish_different_key(self) -> None:
        k1 = cache_key_for_dish("Wiener Schnitzel", "Mains")
        k2 = cache_key_for_dish("Carbonara", "Pasta")
        assert k1 != k2

    def test_key_is_16_hex_chars(self) -> None:
        k = cache_key_for_dish("X", "Y")
        assert len(k) == 16
        assert all(c in "0123456789abcdef" for c in k)


class TestSaveAndLookup:
    def test_save_and_read_menu_image(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, patch(
            "app.services.image_storage._settings",
            return_value=(Path(tmp), "/images"),
        ):
            menu_id = uuid4()
            url = save_menu_image(menu_id, 0, b"fake-jpeg-bytes")
            assert url == f"/images/{menu_id}/0.jpg"
            assert (Path(tmp) / str(menu_id) / "0.jpg").read_bytes() == b"fake-jpeg-bytes"

    def test_lookup_returns_none_for_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, patch(
            "app.services.image_storage._settings",
            return_value=(Path(tmp), "/images"),
        ):
            assert lookup_cached_url("nonexistent_key") is None

    def test_save_shared_then_lookup(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, patch(
            "app.services.image_storage._settings",
            return_value=(Path(tmp), "/images"),
        ):
            url1 = save_shared_image("abc123", b"jpg-bytes")
            url2 = lookup_cached_url("abc123")
            assert url1 == url2 == "/images/_cache/abc123.jpg"
