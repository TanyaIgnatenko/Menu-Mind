"""Database-backed cache for menu extractions, keyed by image hash."""
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm.attributes import flag_modified

from app.database.models import MenuRecord
from app.schemas.dish import Dish
from app.schemas.menu import Menu, MenuCreate


def _record_to_menu(record: MenuRecord) -> Menu:
    """Convert a MenuRecord row to a Menu API schema.

    cuisine_type and status are stored inside dishes_json as top-level keys
    (alongside the dishes list) to avoid a DB migration.
    """
    raw: list | dict = record.dishes_json

    # Support both storage shapes:
    #   old shape: dishes_json is a plain list of dish dicts
    #   new shape: dishes_json is {"cuisine_type": "...", "status": "...", "dishes": [...]}
    if isinstance(raw, dict):
        cuisine_type: str | None = raw.get("cuisine_type")
        status: str = raw.get("status", "ready")
        dishes_data: list = raw.get("dishes", [])
    else:
        cuisine_type = None
        status = "ready"
        dishes_data = raw

    dishes = [Dish.model_validate(d) for d in dishes_data]
    return Menu(
        id=record.id,
        source_language=record.source_language,
        restaurant_name=record.restaurant_name,
        cuisine_type=cuisine_type,
        dishes=dishes,
        status=status,  # type: ignore[arg-type]
        created_at=record.created_at,
    )


async def _get_record(session: AsyncSession, menu_id: UUID) -> MenuRecord | None:
    result = await session.execute(select(MenuRecord).where(MenuRecord.id == menu_id))
    return result.scalar_one_or_none()


async def get_cached_menu(db: AsyncSession, image_hash: str) -> Menu | None:
    """Return a previously extracted menu for this image hash, or None."""
    result = await db.execute(select(MenuRecord).where(MenuRecord.image_hash == image_hash))
    record = result.scalar_one_or_none()
    if record is None:
        return None
    return _record_to_menu(record)


async def save_menu(db: AsyncSession, image_hash: str, menu: MenuCreate) -> Menu:
    """Persist an extracted menu. Idempotent: returns existing record on conflict.

    cuisine_type and status are stored as top-level keys inside the dishes_json
    JSONB field to avoid adding a new column and running a migration.
    """
    dishes_json: dict = {
        "cuisine_type": menu.cuisine_type,
        "status": "ready",
        "dishes": [d.model_dump() for d in menu.dishes],
    }
    record = MenuRecord(
        image_hash=image_hash,
        source_language=menu.source_language,
        restaurant_name=menu.restaurant_name,
        dishes_json=dishes_json,
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


async def create_pending_menu(db: AsyncSession, image_hash: str) -> Menu:
    """Create (or reset) a placeholder menu in the 'extracting' state and return
    it immediately, so the POST can respond before the slow OCR + translation.

    If a record for this hash already exists (e.g. a previously 'failed' attempt),
    it is reset to 'extracting' so the retry re-extracts.
    """
    result = await db.execute(select(MenuRecord).where(MenuRecord.image_hash == image_hash))
    record = result.scalar_one_or_none()
    pending_json: dict = {"cuisine_type": None, "status": "extracting", "dishes": []}

    if record is not None:
        record.source_language = "unknown"
        record.restaurant_name = None
        record.dishes_json = pending_json
        flag_modified(record, "dishes_json")
        await db.commit()
        await db.refresh(record)
        return _record_to_menu(record)

    record = MenuRecord(
        image_hash=image_hash,
        source_language="unknown",
        restaurant_name=None,
        dishes_json=pending_json,
    )
    db.add(record)
    try:
        await db.commit()
        await db.refresh(record)
    except IntegrityError:
        # Concurrent insert for the same hash — return whatever is there now.
        await db.rollback()
        existing = await get_cached_menu(db, image_hash)
        if existing is None:
            raise
        return existing
    return _record_to_menu(record)


async def complete_menu_extraction(
    session: AsyncSession, menu_id: UUID, menu: MenuCreate
) -> None:
    """Fill a pending menu record with extracted dishes and mark it 'ready'."""
    record = await _get_record(session, menu_id)
    if record is None:
        return
    record.source_language = menu.source_language
    record.restaurant_name = menu.restaurant_name
    record.dishes_json = {
        "cuisine_type": menu.cuisine_type,
        "status": "ready",
        "dishes": [d.model_dump() for d in menu.dishes],
    }
    flag_modified(record, "dishes_json")
    await session.commit()


async def apply_dish_enrichment(
    session: AsyncSession, menu_id: UUID, by_index: dict[int, dict]
) -> None:
    """Merge second-pass about/nutrition into a ready menu's dishes (by index)."""
    record = await _get_record(session, menu_id)
    if record is None or not isinstance(record.dishes_json, dict):
        return
    dishes = record.dishes_json.get("dishes", [])
    for i, dish in enumerate(dishes):
        enr = by_index.get(i)
        if not enr:
            continue
        if enr.get("about"):
            dish["about"] = enr["about"]
        if enr.get("nutrition") is not None:
            dish["nutrition"] = enr["nutrition"]
    flag_modified(record, "dishes_json")
    await session.commit()


async def mark_menu_failed(session: AsyncSession, menu_id: UUID) -> None:
    """Mark a pending menu record as 'failed' so the client stops polling."""
    record = await _get_record(session, menu_id)
    if record is None:
        return
    raw = record.dishes_json
    cuisine = raw.get("cuisine_type") if isinstance(raw, dict) else None
    dishes = raw.get("dishes", []) if isinstance(raw, dict) else (raw if isinstance(raw, list) else [])
    record.dishes_json = {"cuisine_type": cuisine, "status": "failed", "dishes": dishes}
    flag_modified(record, "dishes_json")
    await session.commit()


async def get_menu_by_id(db: AsyncSession, menu_id: UUID) -> Menu | None:
    """Retrieve a stored menu by its UUID."""
    result = await db.execute(select(MenuRecord).where(MenuRecord.id == menu_id))
    record = result.scalar_one_or_none()
    if record is None:
        return None
    return _record_to_menu(record)
