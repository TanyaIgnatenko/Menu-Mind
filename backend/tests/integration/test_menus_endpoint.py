"""Integration tests for /menus endpoints.

Uses dependency override to inject a mocked GeminiClient so tests don't call
the real API. We patch the GeminiClient class used inside the extraction
service module.
"""
from io import BytesIO
from typing import Any
from unittest.mock import patch

import pytest
from httpx import AsyncClient
from PIL import Image


def _make_jpeg(color: tuple[int, int, int] = (255, 0, 0)) -> bytes:
    img = Image.new("RGB", (200, 200), color=color)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return buf.getvalue()


@pytest.fixture
def patched_gemini(mock_gemini_client: Any) -> Any:
    """Patch GeminiClient constructor in extraction module to return our mock."""
    with patch(
        "app.services.extraction.GeminiClient", return_value=mock_gemini_client
    ) as patched:
        yield patched


class TestCreateMenu:
    async def test_upload_returns_201_and_pending_menu(
        self, client: AsyncClient, patched_gemini: Any
    ) -> None:
        # Extraction now runs in the background, so the POST returns a placeholder
        # in the 'extracting' state immediately; dishes arrive via polling GET.
        files = {"file": ("menu.jpg", _make_jpeg(), "image/jpeg")}
        response = await client.post("/api/v1/menus/", files=files)
        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert data["status"] == "extracting"

    async def test_same_image_returns_same_id_idempotent(
        self, client: AsyncClient, patched_gemini: Any
    ) -> None:
        image = _make_jpeg(color=(123, 45, 67))
        files = {"file": ("menu.jpg", image, "image/jpeg")}

        first = await client.post("/api/v1/menus/", files=files)
        assert first.status_code == 201
        first_id = first.json()["id"]

        # Re-upload same bytes — cache hit on the existing (pending) record.
        files2 = {"file": ("menu.jpg", image, "image/jpeg")}
        second = await client.post("/api/v1/menus/", files=files2)
        assert second.status_code == 201
        second_id = second.json()["id"]

        assert first_id == second_id

    async def test_empty_file_returns_400(self, client: AsyncClient) -> None:
        files = {"file": ("empty.jpg", b"", "image/jpeg")}
        response = await client.post("/api/v1/menus/", files=files)
        assert response.status_code == 400
        assert response.json()["error"] == "invalid_image"

    async def test_invalid_file_format_returns_400(self, client: AsyncClient) -> None:
        files = {"file": ("fake.jpg", b"this is not an image", "image/jpeg")}
        response = await client.post("/api/v1/menus/", files=files)
        assert response.status_code == 400
        assert response.json()["error"] == "invalid_image"


class TestGetMenu:
    async def test_get_existing_menu(
        self, client: AsyncClient, patched_gemini: Any
    ) -> None:
        files = {"file": ("menu.jpg", _make_jpeg(), "image/jpeg")}
        upload = await client.post("/api/v1/menus/", files=files)
        menu_id = upload.json()["id"]

        response = await client.get(f"/api/v1/menus/{menu_id}")
        assert response.status_code == 200
        assert response.json()["id"] == menu_id

    async def test_get_nonexistent_returns_404(self, client: AsyncClient) -> None:
        fake_id = "00000000-0000-0000-0000-000000000000"
        response = await client.get(f"/api/v1/menus/{fake_id}")
        assert response.status_code == 404

    async def test_get_invalid_uuid_returns_422(self, client: AsyncClient) -> None:
        response = await client.get("/api/v1/menus/not-a-uuid")
        assert response.status_code == 422
