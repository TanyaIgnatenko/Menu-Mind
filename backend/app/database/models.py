"""SQLAlchemy ORM models.

Uses native PostgreSQL types (JSONB, UUID). Tests run against a real Postgres
instance to exercise the same dialect behavior as production.
"""
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import DateTime, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.session import Base


class MenuRecord(Base):
    """Stored extraction result for a menu image.

    Idempotent by `image_hash`: re-uploading the same image returns the same row.
    Dishes are stored as JSONB blob to keep Phase 2 simple. Phase 3 may split
    into separate `dishes` table if querying by dish becomes a hot path.
    """

    __tablename__ = "menus"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    image_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    source_language: Mapped[str] = mapped_column(String(10))
    restaurant_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    cuisine_type: Mapped[str] = mapped_column(String(100), nullable=False, server_default="")
    dishes_json: Mapped[list[dict[str, Any]]] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
