"""Product/quality analytics via PostHog (server-side).

A thin, fail-safe wrapper: if POSTHOG_API_KEY is unset, every call is a no-op, so
the pipeline runs identically with or without analytics configured. capture()
never raises and never blocks — the PostHog SDK enqueues events onto its own
background consumer thread.

Events are tagged platform="backend" so the shared PostHog project can separate
them from the web (posthog-js) and mobile (posthog-flutter) sources.
"""
from functools import lru_cache
from typing import Any

from app.config import get_settings
from app.utils.logging import get_logger

logger = get_logger(__name__)


@lru_cache
def _client() -> Any | None:
    """Cached PostHog client, or None if analytics is not configured."""
    settings = get_settings()
    if not settings.posthog_api_key:
        return None
    from posthog import Posthog

    return Posthog(settings.posthog_api_key, host=settings.posthog_host)


def capture(
    event: str,
    properties: dict[str, Any] | None = None,
    distinct_id: str = "backend",
) -> None:
    """Emit a PostHog event. No-op when unconfigured; never raises."""
    client = _client()
    if client is None:
        return
    props = {"platform": "backend", **(properties or {})}
    try:
        client.capture(distinct_id, event, properties=props)
    except Exception as e:  # analytics must never break the request pipeline
        logger.warning("analytics_capture_failed", event=event, error=str(e))
