"""Custom exceptions for MenuMind and FastAPI exception handlers."""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.utils.logging import get_logger

logger = get_logger(__name__)


class MenuMindError(Exception):
    """Base exception for MenuMind domain errors."""


class ExtractionError(MenuMindError):
    """Failed to extract menu from image via VLM."""


class SchemaValidationError(MenuMindError):
    """LLM returned output that does not match expected schema."""


class RateLimitError(MenuMindError):
    """Hit an external API rate limit."""


class InvalidImageError(MenuMindError):
    """Uploaded image is invalid, unsupported, or too large."""


class UploadLimitError(MenuMindError):
    """User or global daily upload limit reached.

    Attributes:
        scope: "ip" if the per-user limit was hit, "global" if the app-wide
               daily cap was hit. Useful for logging and monitoring.
    """

    def __init__(self, message: str, scope: str = "ip") -> None:
        super().__init__(message)
        self.scope = scope


def register_exception_handlers(app: FastAPI) -> None:
    """Register FastAPI exception handlers for our domain errors.

    Each handler maps a domain error to an appropriate HTTP response with a
    consistent JSON shape: {"error": "<code>", "message": "<text>"}.
    """

    @app.exception_handler(InvalidImageError)
    async def invalid_image_handler(_request: Request, exc: InvalidImageError) -> JSONResponse:
        logger.warning("invalid_image_request", message=str(exc))
        return JSONResponse(
            status_code=400,
            content={"error": "invalid_image", "message": str(exc)},
        )

    @app.exception_handler(SchemaValidationError)
    async def schema_validation_handler(
        _request: Request, exc: SchemaValidationError
    ) -> JSONResponse:
        logger.error("schema_validation_failed", message=str(exc))
        return JSONResponse(
            status_code=502,
            content={
                "error": "extraction_failed",
                "message": "Could not parse menu from image. Please try a clearer photo.",
            },
        )

    @app.exception_handler(ExtractionError)
    async def extraction_error_handler(_request: Request, exc: ExtractionError) -> JSONResponse:
        logger.error("extraction_failed", message=str(exc))
        return JSONResponse(
            status_code=502,
            content={
                "error": "extraction_failed",
                "message": "Could not extract menu. Please try a clearer photo.",
            },
        )

    @app.exception_handler(RateLimitError)
    async def rate_limit_handler(_request: Request, exc: RateLimitError) -> JSONResponse:
        logger.warning("rate_limited", message=str(exc))
        return JSONResponse(
            status_code=429,
            content={"error": "rate_limited", "message": "Please try again in a moment."},
        )

    @app.exception_handler(UploadLimitError)
    async def upload_limit_handler(_request: Request, exc: UploadLimitError) -> JSONResponse:
        logger.warning("upload_limit_reached", scope=exc.scope, message=str(exc))
        return JSONResponse(
            status_code=429,
            content={"error": "upload_limit_reached", "message": str(exc)},
        )
