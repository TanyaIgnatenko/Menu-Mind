"""Database-backed cache for menu extractions, keyed by image hash."""
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.models import MenuRecord
from app.schemas.dish import Dish
from app.schemas.menu import Menu, MenuCreate


def _record_to_menu(record: MenuRecord) -> Menu:
    """Convert a MenuRecord row to a Menu API schema."""
    dishes = [Dish.model_validate(d) for d in record.dishes_json]
    return Menu(
        id=record.id,
        source_language=record.source_language,
        restaurant_name=record.restaurant_name,
        dishes=dishes,
        created_at=record.created_at,
    )


async def get_cached_menu(db: AsyncSession, image_hash: str) -> Menu | None:
    """Return a previously extracted menu for this image hash, or None."""
    result = await db.execute(select(MenuRecord).where(MenuRecord.image_hash == image_hash))
    record = result.scalar_one_or_none()
    if record is None:
        return None
    return _record_to_menu(record)


async def save_menu(db: AsyncSession, image_hash: str, menu: MenuCreate) -> Menu:
    """Persist an extracted menu. Idempotent: returns existing record on conflict."""
    record = MenuRecord(
        image_hash=image_hash,
        source_language=menu.source_language,
        restaurant_name=menu.restaurant_name,
        dishes_json=[d.model_dump() for d in menu.dishes],
    )
    db.add(record)
    try:
        await db.commit()
        await db.refresh(record)
    except IntegrityError:
        await db.rollback()
        existing = await get_cached_menu(db, image_hash)
        if existing is None:
            raise
        return existing
    return _record_to_menu(record)


async def get_menu_by_id(db: AsyncSession, menu_id: UUID) -> Menu | None:
    """Retrieve a stored menu by its UUID."""
    result = await db.execute(select(MenuRecord).where(MenuRecord.id == menu_id))
    record = result.scalar_one_or_none()
    if record is None:
        return None
    return _record_to_menu(record)
