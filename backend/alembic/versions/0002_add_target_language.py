"""Add target_language to menus (per-language translation cache).

The cache is now keyed on (image_hash, target_language) instead of image_hash
alone, so the same menu photo can be translated into several languages — one row
per language. Existing rows default to English.

Revision ID: 0002_add_target_language
Revises: 0001_create_menus
Create Date: 2026-08-09 00:00:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0002_add_target_language"
down_revision: str | None = "0001_create_menus"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "menus",
        sa.Column(
            "target_language",
            sa.String(length=10),
            nullable=False,
            server_default="en",
        ),
    )
    op.create_index("ix_menus_target_language", "menus", ["target_language"])
    # image_hash is no longer unique on its own — the pair is.
    op.drop_index("ix_menus_image_hash", table_name="menus")
    op.create_index("ix_menus_image_hash", "menus", ["image_hash"], unique=False)
    op.create_unique_constraint(
        "uq_menus_image_hash_language", "menus", ["image_hash", "target_language"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_menus_image_hash_language", "menus", type_="unique")
    op.drop_index("ix_menus_image_hash", table_name="menus")
    op.create_index("ix_menus_image_hash", "menus", ["image_hash"], unique=True)
    op.drop_index("ix_menus_target_language", table_name="menus")
    op.drop_column("menus", "target_language")
