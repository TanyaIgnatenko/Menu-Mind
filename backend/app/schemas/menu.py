"""Pydantic schemas for menus."""
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.dish import Dish


class MenuCreate(BaseModel):
    """Internal model used between extraction service and persistence."""

    source_language: str = Field(..., description="ISO language code: de, en, it, etc.")
    dishes: list[Dish]
    restaurant_name: str | None = None
    cuisine_type: str = ""


class Menu(BaseModel):
    """Public API response for a menu."""

    id: UUID
    source_language: str = Field(..., description="ISO language code: de, en, it, etc.")
    restaurant_name: str | None = None
    cuisine_type: str = ""
    dishes: list[Dish]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
