"""Unit tests for image generation service."""
from unittest.mock import AsyncMock, patch

from app.schemas.dish import Dish
from app.services.image_generation import _build_prompt


class TestBuildPrompt:
    def test_includes_dish_name(self) -> None:
        dish = Dish(
            name_original="Wiener Schnitzel",
            name_english="Viennese cutlet",
        )
        prompt = _build_prompt(dish)
        assert "Viennese cutlet" in prompt
        assert "food photography" in prompt

    def test_includes_description_when_present(self) -> None:
        dish = Dish(
            name_original="Carbonara",
            name_english="Carbonara",
            description_english="with pancetta and parmesan",
        )
        prompt = _build_prompt(dish)
        assert "pancetta and parmesan" in prompt

    def test_omits_description_when_empty(self) -> None:
        dish = Dish(
            name_original="Pasta",
            name_english="Pasta",
            description_english="",
        )
        prompt = _build_prompt(dish)
        assert "showing" not in prompt

    def test_includes_style_keywords(self) -> None:
        dish = Dish(name_original="X", name_english="X")
        prompt = _build_prompt(dish)
        assert "restaurant" in prompt.lower()
        assert "natural lighting" in prompt


class TestGenerateImagesForMenu:
    async def test_skips_when_no_api_key(self) -> None:
        """When FAL_API_KEY is empty, generation is skipped without error."""
        from uuid import uuid4

        from app.services.image_generation import generate_images_for_menu

        with patch("app.services.image_generation.get_settings") as mock_settings:
            mock_settings.return_value = AsyncMock()
            mock_settings.return_value.fal_api_key = ""

            # Should not raise - just returns
            await generate_images_for_menu(uuid4())
