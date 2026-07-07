"""Image generation orchestration (sequential).

Generates images for all dishes in a menu ONE AT A TIME, updating the DB
after each. Sequential processing trades a little speed for total reliability:
no concurrent writes to the same JSONB column means no lost-update races and
no zombie 'generating' rows.

Caching means repeated dishes across menus reuse the same generated image,
so re-uploads are near-instant.
"""
from collections.abc import Iterable
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.clients.fal import FalClient
from app.config import get_settings
from app.database.models import MenuRecord
from app.schemas.dish import Dish
from app.services.image_storage import (
    cache_key_for_dish,
    lookup_cached_url,
    save_shared_image,
)
from app.utils.logging import get_logger

logger = get_logger(__name__)


# Category keywords that indicate a drink rather than a plated dish.
_DRINK_CATEGORY_HINTS = (
    "drink", "beverage", "coffee", "tea", "getränke", "getranke",
    "bar", "wine", "beer", "cocktail", "juice", "soft drink",
)

# Dish-name keywords for common drinks (covers cases where the category
# is generic, e.g. just "Menu" or empty).
_DRINK_NAME_HINTS = (
    "espresso", "cortado", "cappuccino", "latte", "macchiato", "americano",
    "mocha", "flat white", "coffee", "tea", "chai", "matcha",
    "juice", "lemonade", "soda", "cola", "water", "wine", "beer",
    "cocktail", "smoothie", "milkshake",
)


def _is_drink(dish: Dish) -> bool:
    """Heuristic: does this dish look like a drink rather than a plated dish?"""
    cat = dish.category_english.lower()
    name = dish.name_english.lower()
    if any(h in cat for h in _DRINK_CATEGORY_HINTS):
        return True
    if any(h in name for h in _DRINK_NAME_HINTS):
        return True
    return False


def _build_prompt(dish: Dish) -> str:
    """Construct a Flux Schnell prompt for one dish.

    Drinks and plated dishes use different prompt scaffolding: a drink must be
    rendered as a single beverage with no food props, while a dish gets the
    full food-photography treatment. Category context is included so the model
    renders type-appropriate presentation.
    """
    if _is_drink(dish):
        parts = [f"professional beverage photography of a {dish.name_english}"]
        if dish.description_english:
            parts.append(f"({dish.description_english})")
        parts.extend([
            "a single beverage in an appropriate glass or cup, centered",
            "drink only, no food, no plate of food, no side dishes",
            "no people, no hands, no table edge, no background clutter",
            "studio product shot on a plain seamless white surface",
            "soft even lighting",
            "high quality, detailed, sharp focus",
        ])
        return ", ".join(parts)

    # Plated food dish
    parts = [f"professional food photography of {dish.name_english}"]
    if dish.category_english:
        parts.append(f"a {dish.category_english.lower()}")
    # Prefer the visual appearance description (crafted for image gen) over the
    # raw ingredient list — it tells the model how the dish actually looks.
    if dish.visual_appearance:
        parts.append(dish.visual_appearance)
    elif dish.description_english:
        parts.append(f"showing {dish.description_english}")
    # Use overhead view by default, but skip it if the visual_appearance
    # already specifies an angle (e.g. "side view" for layered dishes), to
    # avoid contradicting prompt directions.
    appearance_lower = dish.visual_appearance.lower()
    specifies_angle = any(
        kw in appearance_lower
        for kw in ("side view", "cross-section", "cross section", "angle")
    )
    parts.append("a single plated dish")
    parts.append("restaurant menu style")
    if not specifies_angle:
        parts.append("overhead view")
    parts.extend([
        "natural lighting",
        "appetizing presentation",
        "clean background",
        "high quality, detailed, sharp focus",
    ])
    return ", ".join(parts)

def _humanize_error(exc: BaseException) -> str:
    """Convert technical exception into a short user-friendly message."""
    msg = str(exc).lower()
    if "rate" in msg or "429" in msg or "quota" in msg:
        return "Rate limit reached"
    if "timeout" in msg or "timed out" in msg:
        return "Generation timed out"
    if "safety" in msg or "filter" in msg or "moderation" in msg:
        return "Content filter triggered"
    if "401" in msg or "unauthorized" in msg or "api_key" in msg:
        return "API key error"
    if "402" in msg or "insufficient" in msg or "credit" in msg:
        return "Out of credits"
    if "network" in msg or "connection" in msg:
        return "Network error"
    if "fal_api_key not configured" in msg:
        return "Image service not configured"
    return str(exc)[:80] if str(exc) else "Generation failed"


async def _generate_one_dish(client: FalClient, dish: Dish) -> tuple[str, str, str]:
    """Generate one dish image (or return cached).

    Returns (status, url, error). Always returns a 3-tuple, even on failure.
    """
    # Fall back to original name/category when English is empty (e.g. for
    # loanword dish names like "Spaghetti alla Carbonara" where Gemini may
    # leave name_english empty). Without this fallback, all dishes with empty
    # name_english would collide on the same cache key and share one image.
    cache_key = cache_key_for_dish(
        dish.name_english or dish.name_original,
        dish.category_english or dish.category,
    )

    cached = lookup_cached_url(cache_key)
    if cached:
        logger.info("image_cache_hit", dish=dish.name_english)
        return "ready", cached, ""

    try:
        logger.info("image_generation_start", dish=dish.name_english)
        prompt = _build_prompt(dish)
        image_bytes = await client.generate_image(prompt)
        url = save_shared_image(cache_key, image_bytes)
        logger.info("image_generation_ok", dish=dish.name_english, url=url)
        return "ready", url, ""
    except BaseException as e:
        error_msg = _humanize_error(e)
        logger.error(
            "image_generation_failed",
            dish=dish.name_english,
            error=str(e),
            user_message=error_msg,
        )
        return "failed", "", error_msg


async def mark_menu_images_generating(menu_id: UUID) -> None:
    """Mark every dish's image as 'generating' so all cards show a loading state
    immediately, before the (slower) per-dish generation runs. Called once, up
    front, so the tail dishes still read as loading while the first batch renders.
    """
    settings = get_settings()
    if not settings.fal_api_key:
        return

    engine = create_async_engine(settings.database_url)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    try:
        async with session_factory() as session:
            menu_record = await _load_menu(session, menu_id)
            if menu_record is None:
                return
            raw = menu_record.dishes_json
            dishes_data = list(raw.get("dishes", [])) if isinstance(raw, dict) else list(raw)
            for d in dishes_data:
                d["image_status"] = "generating"
            # Preserve every other top-level key (cuisine_type, status).
            menu_record.dishes_json = (
                {**raw, "dishes": dishes_data} if isinstance(raw, dict) else dishes_data
            )
            await _persist(session, menu_record)
    finally:
        await engine.dispose()


async def generate_images_for_menu(
    menu_id: UUID, indices: Iterable[int] | None = None
) -> None:
    """Generate images for the given dish indices (all if None), one at a time.

    Runs as a detached asyncio task (scheduled from the menus endpoint). Creates
    its own DB engine because it runs outside the request scope. Assumes dishes
    were already marked 'generating' by mark_menu_images_generating; if not, they
    simply transition pending→ready. Safe to call several times for disjoint
    index ranges as long as the calls are sequential (the per-dish read-modify-
    write is only race-free without concurrency).
    """
    settings = get_settings()
    if not settings.fal_api_key:
        logger.warning("image_gen_skipped_no_api_key", menu_id=str(menu_id))
        return

    engine = create_async_engine(settings.database_url)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    try:
        # Load dishes (a fresh snapshot — picks up any enrichment merged since).
        async with session_factory() as session:
            menu_record = await _load_menu(session, menu_id)
            if menu_record is None:
                logger.error("image_gen_menu_not_found", menu_id=str(menu_id))
                return
            raw = menu_record.dishes_json
            dishes_data = list(raw.get("dishes", [])) if isinstance(raw, dict) else list(raw)
            dishes = [Dish.model_validate(d) for d in dishes_data]

        target = (
            list(range(len(dishes)))
            if indices is None
            else [i for i in indices if 0 <= i < len(dishes)]
        )

        client = FalClient()

        # Generate one dish at a time, persisting after each.
        # No concurrency → no race conditions → no zombies.
        for idx in target:
            dish = dishes[idx]
            status = "failed"
            url = ""
            error = "Unknown error"
            try:
                result = await _generate_one_dish(client, dish)
                if isinstance(result, tuple) and len(result) == 3:
                    status, url, error = result
            except BaseException as e:
                logger.error(
                    "image_generation_unexpected_error",
                    dish=dish.name_english,
                    error=str(e),
                )
                error = str(e)[:100] if str(e) else "Unexpected error"

            # Persist this single dish result. Safe read-modify-write because
            # image-gen calls run sequentially (no concurrent writers). Spreading
            # the current dict preserves enrichment (about/nutrition) and the
            # menu's top-level status key.
            try:
                async with session_factory() as session:
                    menu_record = await _load_menu(session, menu_id)
                    if menu_record is None:
                        return
                    raw2 = menu_record.dishes_json
                    current = (
                        list(raw2.get("dishes", [])) if isinstance(raw2, dict) else list(raw2)
                    )
                    if idx < len(current):
                        current[idx] = {
                            **current[idx],
                            "image_status": status,
                            "image_url": url,
                            "image_error": error,
                        }
                        menu_record.dishes_json = (
                            {**raw2, "dishes": current} if isinstance(raw2, dict) else current
                        )
                        await _persist(session, menu_record)
            except Exception as e:
                logger.error("image_db_update_failed", dish=dish.name_english, error=str(e))

        logger.info("image_gen_batch_complete", menu_id=str(menu_id), count=len(target))
    finally:
        await engine.dispose()


async def _load_menu(session: AsyncSession, menu_id: UUID) -> MenuRecord | None:
    result = await session.execute(select(MenuRecord).where(MenuRecord.id == menu_id))
    return result.scalar_one_or_none()


async def _persist(session: AsyncSession, menu_record: MenuRecord) -> None:
    """Force JSONB column update (SQLAlchemy doesn't auto-detect in-place changes)."""
    from sqlalchemy.orm.attributes import flag_modified

    flag_modified(menu_record, "dishes_json")
    await session.commit()