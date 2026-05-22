"""Shared pytest fixtures used by both unit and integration tests.

Layer-specific fixtures live in:
- tests/unit/conftest.py — for tests that need no database
- tests/integration/conftest.py — for tests using real Postgres
"""
import json
from io import BytesIO
from typing import Any
from unittest.mock import AsyncMock

import pytest
from PIL import Image

from app.clients.gemini import GeminiClient
from app.schemas.dish import Dish
from app.schemas.menu import MenuCreate


@pytest.fixture
def sample_image_bytes() -> bytes:
    """Return small valid JPEG bytes for upload tests."""
    img = Image.new("RGB", (200, 200), color=(255, 200, 100))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return buf.getvalue()


@pytest.fixture
def sample_menu_create() -> MenuCreate:
    """Return a MenuCreate fixture with two dishes."""
    return MenuCreate(
        source_language="de",
        restaurant_name="Test Restaurant",
        dishes=[
            Dish(
                name_original="Wiener Schnitzel",
                name_english="Viennese cutlet",
                description_original="mit Kartoffeln",
                description_english="with potatoes",
                size="",
                category="Hauptgerichte",
                price="14,90 EUR",
            ),
            Dish(
                name_original="Apfelstrudel",
                name_english="Apple strudel",
                description_original="",
                description_english="",
                size="",
                category="Desserts",
                price="6,50 EUR",
            ),
        ],
    )


@pytest.fixture
def mock_gemini_client(sample_menu_create: MenuCreate) -> GeminiClient:
    """Return a GeminiClient mock that returns sample_menu_create as JSON."""
    mock = AsyncMock(spec=GeminiClient)

    payload: dict[str, Any] = {
        "source_language": sample_menu_create.source_language,
        "restaurant_name": sample_menu_create.restaurant_name,
        "dishes": [d.model_dump() for d in sample_menu_create.dishes],
    }

    mock.generate_with_image.return_value = {
        "text": json.dumps(payload),
        "input_tokens": 1500,
        "output_tokens": 800,
    }
    return mock
