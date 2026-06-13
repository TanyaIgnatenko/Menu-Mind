"""Menu API endpoints."""
import asyncio
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_db
from app.exceptions import InvalidImageError
from app.schemas.menu import Menu
from app.services.cache import get_cached_menu, get_menu_by_id, save_menu
from app.services.extraction import extract_menu_from_image
from app.services.image_generation import generate_images_for_menu
from app.services.preprocessing import compute_image_hash, preprocess_image
from app.services.rate_limit import check_and_increment
from app.utils.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(tags=["menus"], prefix="/menus")


# Keep references to running background tasks so they aren't garbage-collected
# before they finish. asyncio.create_task only holds a weak reference internally.
_background_tasks: set[asyncio.Task[None]] = set()


def _on_image_gen_done(task: "asyncio.Task[None]") -> None:
    """Callback when background image generation finishes."""
    _background_tasks.discard(task)
    try:
        task.result()  # Re-raises any unhandled exception
        logger.info("background_image_gen_finished")
    except Exception as e:
        logger.error(
            "background_image_gen_unhandled_exception",
            error=str(e),
            error_type=type(e).__name__,
        )


def _get_client_ip(request: Request) -> str:
    """Extract the real client IP, respecting X-Forwarded-For from ECS/ALB."""
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        # X-Forwarded-For can be a comma-separated list; take the first (client) IP.
        return forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


@router.post("/", response_model=Menu, status_code=201)
async def create_menu(
    request: Request,
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
) -> Menu:
    """Extract menu from uploaded image, queue image generation in background.

    Idempotent by image hash: re-uploading the same image returns the existing
    menu without re-extracting or re-generating images (and does not count
    toward rate limits).

    Rate limits (both bypass-able via RATE_LIMIT_ENABLED=false):
      - 5 unique uploads per IP per day
      - 50 unique uploads globally per day

    Image generation runs as a detached asyncio task — not a FastAPI
    BackgroundTask — so it can outlive the request lifecycle without being
    cancelled when the response is sent.
    """
    image_bytes = await file.read()
    if not image_bytes:
        raise InvalidImageError("Empty file uploaded")

    image_hash = compute_image_hash(image_bytes)

    # Check cache BEFORE rate limiting — cache hits bypass limits entirely.
    cached = await get_cached_menu(db, image_hash)
    if cached is not None:
        logger.info("cache_hit", image_hash=image_hash, menu_id=str(cached.id))
        check_and_increment(_get_client_ip(request), is_cache_hit=True)
        return cached

    # New unique image — check and increment rate limit counters.
    # Raises UploadLimitError (→ HTTP 429) if either limit is exceeded.
    check_and_increment(_get_client_ip(request), is_cache_hit=False)

    processed_bytes = preprocess_image(image_bytes)
    menu_create = await extract_menu_from_image(processed_bytes)

    menu = await save_menu(db, image_hash, menu_create)

    # Schedule image generation as fire-and-forget on the running event loop.
    logger.info("scheduling_image_gen", menu_id=str(menu.id))
    task = asyncio.create_task(generate_images_for_menu(menu.id))
    _background_tasks.add(task)
    task.add_done_callback(_on_image_gen_done)

    return menu


@router.get("/{menu_id}", response_model=Menu)
async def get_menu(
    menu_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> Menu:
    """Retrieve menu by ID, including current image generation status."""
    menu = await get_menu_by_id(db, menu_id)
    if menu is None:
        raise HTTPException(status_code=404, detail="Menu not found")
    return menu
