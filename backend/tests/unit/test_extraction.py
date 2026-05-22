"""Unit tests for extraction service and JSON parsing helper."""
import json

import pytest

from app.clients.gemini import GeminiClient, parse_json_response
from app.exceptions import SchemaValidationError
from app.schemas.menu import MenuCreate
from app.services.extraction import extract_menu_from_image


class TestParseJsonResponse:
    def test_plain_json(self) -> None:
        assert parse_json_response('{"a": 1}') == {"a": 1}

    def test_json_with_code_fence(self) -> None:
        assert parse_json_response('```json\n{"a": 1}\n```') == {"a": 1}

    def test_json_with_plain_fence(self) -> None:
        assert parse_json_response('```\n{"a": 1}\n```') == {"a": 1}

    def test_invalid_json_raises(self) -> None:
        with pytest.raises(SchemaValidationError, match="invalid JSON"):
            parse_json_response("not json at all")


class TestExtractMenuFromImage:
    async def test_happy_path(
        self,
        mock_gemini_client: GeminiClient,
        sample_image_bytes: bytes,
        sample_menu_create: MenuCreate,
    ) -> None:
        result = await extract_menu_from_image(sample_image_bytes, client=mock_gemini_client)
        assert result.source_language == sample_menu_create.source_language
        assert len(result.dishes) == len(sample_menu_create.dishes)
        assert result.dishes[0].name_original == sample_menu_create.dishes[0].name_original

    async def test_empty_dishes_raises(
        self, mock_gemini_client: GeminiClient, sample_image_bytes: bytes
    ) -> None:
        mock_gemini_client.generate_with_image.return_value = {  # type: ignore[attr-defined]
            "text": json.dumps({"source_language": "de", "dishes": []}),
            "input_tokens": 100,
            "output_tokens": 50,
        }
        with pytest.raises(SchemaValidationError, match="No dishes"):
            await extract_menu_from_image(sample_image_bytes, client=mock_gemini_client)

    async def test_dishes_not_a_list_raises(
        self, mock_gemini_client: GeminiClient, sample_image_bytes: bytes
    ) -> None:
        mock_gemini_client.generate_with_image.return_value = {  # type: ignore[attr-defined]
            "text": json.dumps({"source_language": "de", "dishes": "not a list"}),
            "input_tokens": 100,
            "output_tokens": 50,
        }
        with pytest.raises(SchemaValidationError, match="not a list"):
            await extract_menu_from_image(sample_image_bytes, client=mock_gemini_client)

    async def test_non_dict_top_level_raises(
        self, mock_gemini_client: GeminiClient, sample_image_bytes: bytes
    ) -> None:
        mock_gemini_client.generate_with_image.return_value = {  # type: ignore[attr-defined]
            "text": json.dumps(["just", "a", "list"]),
            "input_tokens": 100,
            "output_tokens": 50,
        }
        with pytest.raises(SchemaValidationError, match="JSON object"):
            await extract_menu_from_image(sample_image_bytes, client=mock_gemini_client)

    async def test_dish_schema_invalid_raises(
        self, mock_gemini_client: GeminiClient, sample_image_bytes: bytes
    ) -> None:
        mock_gemini_client.generate_with_image.return_value = {  # type: ignore[attr-defined]
            "text": json.dumps({
                "source_language": "de",
                "dishes": [{"name_english": "only english, missing name_original"}],
            }),
            "input_tokens": 100,
            "output_tokens": 50,
        }
        with pytest.raises(SchemaValidationError, match="Dish schema"):
            await extract_menu_from_image(sample_image_bytes, client=mock_gemini_client)
