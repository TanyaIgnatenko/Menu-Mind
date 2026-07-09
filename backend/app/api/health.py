"""Health check endpoint."""
from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_db
from app.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)) -> dict[str, Any]:
    """Verify service is running and DB is reachable.

    Returns 200 with database status. Returns "degraded" status (but still 200)
    if the database is unreachable so that container orchestrators can
    distinguish "process up" from "fully healthy".
    """
    try:
        await db.execute(text("SELECT 1"))
        db_status = "ok"
    except Exception:
        db_status = "error"

    settings = get_settings()
    return {
        "status": "ok" if db_status == "ok" else "degraded",
        "database": db_status,
        # Non-secret config flags — lets us confirm which features are live.
        "config": {
            "s3": bool(settings.s3_bucket),
            "store_menu_uploads": settings.store_menu_uploads,
            "analytics": bool(settings.posthog_api_key),
        },
    }
