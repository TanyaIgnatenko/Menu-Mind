"""Create menus table.

Revision ID: 0001_create_menus
Revises:
Create Date: 2026-05-16 12:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0001_create_menus"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "menus",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("image_hash", sa.String(length=64), nullable=False),
        sa.Column("source_language", sa.String(length=10), nullable=False),
        sa.Column("restaurant_name", sa.String(length=255), nullable=True),
        sa.Column("dishes_json", postgresql.JSONB(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_menus_image_hash", "menus", ["image_hash"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_menus_image_hash", table_name="menus")
    op.drop_table("menus")
