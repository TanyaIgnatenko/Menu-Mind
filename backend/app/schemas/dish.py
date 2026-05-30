"""Pydantic schema for a single dish."""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

ImageStatus = Literal["pending", "generating", "ready", "failed"]


class Dish(BaseModel):
    """A single dish extracted from a menu."""

    name_original: str = Field(..., description="Dish name in source language")
    name_english: str = Field(..., description="English translation of name")
    description_original: str = Field("", description="Description in source language")
    description_english: str = Field("", description="English translation of description")
    size: str = Field("", description="Serving size if specified (e.g. '20cl')")
    category: str = Field("", description="Section header as on menu (e.g. 'Zuppe / Suppen')")
    category_english: str = Field("", description="English translation of category")
    price: str = Field("", description="Price with currency, as written on menu")

    visual_appearance: str = Field(
        "",
        description="Short description of how the dish physically looks "
        "(shape, colors, plating) — used to guide image generation",
    )

    # Image generation fields (Phase 4)
    image_status: ImageStatus = Field("pending", description="Image generation status")
    image_url: str = Field("", description="URL to generated dish image, empty if not ready")
    image_error: str = Field("", description="Error message if image_status is 'failed'")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "name_original": "Wiener Schnitzel",
                "name_english": "Viennese cutlet",
                "description_original": "mit Bratkartoffeln",
                "description_english": "with fried potatoes",
                "size": "",
                "category": "Hauptgerichte",
                "category_english": "Main Courses",
                "visual_appearance": "golden breaded cutlet on a plate with fried potatoes",
                "price": "14,90 EUR",
                "image_status": "ready",
                "image_url": "/images/abc/0.jpg",
                "image_error": "",
            }
        }
    )