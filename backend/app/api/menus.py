"""Menu API endpoints."""
import asyncio
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.api.dependencies import get_db
from app.config import get_settings
from app.exceptions import InvalidImageError
from app.schemas.menu import Menu
from app.services.cache import (
    apply_dish_enrichment,
    complete_menu_extraction,
    create_pending_menu,
    get_cached_menu,
    get_menu_by_id,
    mark_menu_failed,
)
from app.services.extraction import enrich_dishes, extract_menu_from_image
from app.services.image_generation import (
    generate_images_for_menu,
    mark_menu_images_generating,
)
from app.services.preprocessing import compute_image_hash, preprocess_image
from app.services.rate_limit import check_and_increment
from app.utils.logging import get_logger

logger = get_logger(__name__)
router = APIRouter(tags=["menus"], prefix="/menus")

# Photos for the first N (on-screen) dishes are generated before the text-only
# enrichment pass and the remaining photos — getting the visible dishes' images
# up fast matters most for perceived speed.
_FIRST_IMAGE_BATCH = 6


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


async def _extract_and_generate(menu_id: UUID, processed_bytes: bytes) -> None:
    """Background pipeline for one upload: extract the menu (slow OCR +
    translation), then generate dish images.

    Runs as a detached asyncio task so the slow work happens AFTER the HTTP
    response — the request can no longer be killed by the gateway timeout (504).
    Uses its own DB engine because it runs outside the request scope. The image
    is already validated + preprocessed by the request handler.
    """
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    extracted = False
    try:
        menu_create = await extract_menu_from_image(processed_bytes)
        async with session_factory() as session:
            await complete_menu_extraction(session, menu_id, menu_create)
        extracted = True
        logger.info("extraction_complete", menu_id=str(menu_id), dish_count=len(menu_create.dishes))
    except Exception as e:
        logger.error(
            "extraction_failed",
            menu_id=str(menu_id),
            error=str(e),
            error_type=type(e).__name__,
        )
        try:
            async with session_factory() as session:
                await mark_menu_failed(session, menu_id)
        except Exception as mark_err:
            logger.error("extraction_mark_failed_error", menu_id=str(menu_id), error=str(mark_err))
    finally:
        await engine.dispose()

    if extracted:
        # The functions below each manage their own engine/session.
        await _enrich_and_generate_images(menu_id, menu_create)


async def _run_enrichment(menu_id: UUID, menu_create) -> None:  # type: ignore[no-untyped-def]
    """Second pass: about + nutrition (text-only, no image). Runs after the menu
    is already shown (status=ready), so it never blocks the loading spinner.
    Non-fatal — a failure just leaves those fields empty."""
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    try:
        by_index = await enrich_dishes(menu_create.dishes, menu_create.cuisine_type)
        async with session_factory() as session:
            await apply_dish_enrichment(session, menu_id, by_index)
        logger.info("enrichment_complete", menu_id=str(menu_id), enriched=len(by_index))
    except Exception as enr_err:
        logger.warning("enrichment_failed", menu_id=str(menu_id), error=str(enr_err))
    finally:
        await engine.dispose()


async def _enrich_and_generate_images(menu_id: UUID, menu_create) -> None:  # type: ignore[no-untyped-def]
    """Post-extraction priority pipeline (all steps sequential — the per-dish
    image write is only race-free without concurrency):

      1. mark every dish image 'generating' so all cards show a loading state
      2. generate photos for the first N (on-screen) dishes
      3. enrich all dishes with about + nutrition (quick text pass)
      4. generate the remaining photos

    For menus that fit one screen (<= N dishes) enrichment runs BEFORE the images
    instead, so `about` is present before clients stop polling — they settle once
    every image resolves, and with no tail batch step 3 would otherwise land last.
    """
    n = len(menu_create.dishes)
    await mark_menu_images_generating(menu_id)
    if n > _FIRST_IMAGE_BATCH:
        await generate_images_for_menu(menu_id, indices=range(_FIRST_IMAGE_BATCH))
        await _run_enrichment(menu_id, menu_create)
        await generate_images_for_menu(menu_id, indices=range(_FIRST_IMAGE_BATCH, n))
    else:
        await _run_enrichment(menu_id, menu_create)
        await generate_images_for_menu(menu_id)


@router.post("/", response_model=Menu, status_code=201)
async def create_menu(
    request: Request,
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
) -> Menu:
    """Start menu processing and return a placeholder immediately.

    OCR + translation (slow) and image generation both run as detached asyncio
    tasks, so the response returns in well under the gateway timeout. The client
    then polls GET /menus/{id} until `status` becomes 'ready' (or 'failed').

    Idempotent by image hash: re-uploading the same image returns the existing
    menu (ready or still extracting) without re-processing, and a previously
    'failed' attempt is re-extracted.

    Rate limits (both bypass-able via RATE_LIMIT_ENABLED=false):
      - 5 unique uploads per IP per day
      - 50 unique uploads globally per day
    """
    image_bytes = await file.read()
    if not image_bytes:
        raise InvalidImageError("Empty file uploaded")

    image_hash = compute_image_hash(image_bytes)

    # Check cache BEFORE rate limiting — cache hits bypass limits entirely.
    # A 'failed' record is treated as a miss so the retry re-extracts.
    cached = await get_cached_menu(db, image_hash)
    if cached is not None and cached.status != "failed":
        logger.info(
            "cache_hit", image_hash=image_hash, menu_id=str(cached.id), status=cached.status
        )
        check_and_increment(_get_client_ip(request), is_cache_hit=True)
        return cached

    # Validate + preprocess synchronously so a bad image fails fast with 400
    # (raises InvalidImageError) before we create a record or count rate limits.
    # Only the slow Gemini extraction runs in the background.
    processed_bytes = preprocess_image(image_bytes)

    # New (or previously-failed) image — check and increment rate limit counters.
    # Raises UploadLimitError (→ HTTP 429) if either limit is exceeded.
    check_and_increment(_get_client_ip(request), is_cache_hit=False)

    # Persist a placeholder and respond immediately; process in the background.
    pending = await create_pending_menu(db, image_hash)
    logger.info("scheduling_extraction", menu_id=str(pending.id))
    task = asyncio.create_task(_extract_and_generate(pending.id, processed_bytes))
    _background_tasks.add(task)
    task.add_done_callback(_on_image_gen_done)

    return pending


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
