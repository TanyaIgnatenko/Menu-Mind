"""Shared API response schemas."""
from pydantic import BaseModel


class ErrorResponse(BaseModel):
    """Consistent error envelope returned by exception handlers."""

    error: str
    message: str
    request_id: str | None = None
