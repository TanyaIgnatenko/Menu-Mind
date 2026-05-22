"""FastAPI application factory."""
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api import health, menus
from app.config import get_settings
from app.exceptions import register_exception_handlers
from app.services.image_storage import ensure_storage_dir
from app.utils.logging import configure_logging, get_logger


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan: setup logging and storage on startup."""
    settings = get_settings()
    configure_logging(debug=settings.debug)
    ensure_storage_dir()
    logger = get_logger(__name__)
    logger.info(
        "application_started",
        project=settings.project_name,
        image_gen_enabled=bool(settings.fal_api_key),
    )
    yield
    logger.info("application_stopped")


def create_app() -> FastAPI:
    """Construct and configure the FastAPI app."""
    settings = get_settings()

    app = FastAPI(
        title=settings.project_name,
        version="0.2.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )

    register_exception_handlers(app)

    # Mount static files for generated images
    # Ensure dir exists before mounting (StaticFiles requires the path to exist)
    ensure_storage_dir()
    app.mount(
        settings.image_url_prefix,
        StaticFiles(directory=settings.image_storage_dir),
        name="images",
    )

    app.include_router(health.router, prefix=settings.api_v1_prefix)
    app.include_router(menus.router, prefix=settings.api_v1_prefix)

    return app


app = create_app()
