"""Unit tests for Pydantic schemas."""
import pytest
from pydantic import ValidationError

from app.schemas.dish import Dish
from app.schemas.menu import MenuCreate


class TestDish:
    def test_minimal_dish_with_required_fields(self) -> None:
        dish = Dish(name_original="Pasta", name_english="Pasta")
        assert dish.name_original == "Pasta"
        assert dish.description_original == ""
        assert dish.size == ""
        assert dish.price == ""

    def test_dish_with_all_fields(self) -> None:
        dish = Dish(
            name_original="Wiener Schnitzel",
            name_english="Viennese cutlet",
            description_original="mit Kartoffeln",
            description_english="with potatoes",
            size="",
            category="Hauptgerichte",
            price="14,90 EUR",
        )
        assert dish.category == "Hauptgerichte"
        assert dish.price == "14,90 EUR"

    def test_missing_required_field_raises(self) -> None:
        with pytest.raises(ValidationError):
            Dish.model_validate({"name_english": "only english"})

    def test_extra_fields_rejected_or_ignored(self) -> None:
        # Pydantic v2 default: extra fields ignored
        dish = Dish.model_validate(
            {"name_original": "X", "name_english": "X", "unknown_field": "value"}
        )
        assert not hasattr(dish, "unknown_field")


class TestMenuCreate:
    def test_menu_with_dishes(self) -> None:
        menu = MenuCreate(
            source_language="de",
            dishes=[Dish(name_original="A", name_english="A")],
        )
        assert menu.source_language == "de"
        assert len(menu.dishes) == 1
        assert menu.restaurant_name is None

    def test_empty_dishes_list_allowed_at_schema_level(self) -> None:
        # Schema permits it; extraction service enforces non-empty.
        menu = MenuCreate(source_language="en", dishes=[])
        assert menu.dishes == []
