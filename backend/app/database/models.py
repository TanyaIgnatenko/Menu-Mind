"""SQLAlchemy ORM models.

Uses native PostgreSQL types (JSONB, UUID). Tests run against a real Postgres
instance to exercise the same dialect behavior as production.
"""
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import DateTime, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class MenuRecord(Base):
    """Stored extraction result for a menu image.

    Idempotent by (`image_hash`, `target_language`): re-uploading the same image
    for the same target language returns the same row, but the same photo can be
    translated into several languages (one row each). Dishes are stored as a JSONB
    blob to keep things simple.
    """

    __tablename__ = "menus"
    __table_args__ = (
        UniqueConstraint("image_hash", "target_language", name="uq_menus_image_hash_language"),
    )

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    image_hash: Mapped[str] = mapped_column(String(64), index=True)
    # Language the dish text (name/description/category/about) is translated into.
    target_language: Mapped[str] = mapped_column(String(10), server_default="en", index=True)
    source_language: Mapped[str] = mapped_column(String(10))
    restaurant_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    dishes_json: Mapped[list[dict[str, Any]]] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
