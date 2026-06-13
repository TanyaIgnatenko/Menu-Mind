"""In-process rate limiting for menu uploads.

Two tiers of protection:
  - Per-IP daily limit  (RATE_LIMIT_PER_IP_DAILY,   default 5)
  - Global daily cap    (RATE_LIMIT_GLOBAL_DAILY,    default 50)

Both limits reset at midnight UTC.

Storage: plain dicts in process memory.
  - Good enough for a single ECS task (max 1 task is set in the infra).
  - Lost on container restart — intentional: a restart gives users a fresh
    start, which is fine for a beta.
  - If you later scale to multiple tasks, swap the dicts for a Redis INCR
    with TTL. The interface of this module stays the same.

Kill switch:
  Set RATE_LIMIT_ENABLED=false in .env or ECS env vars to bypass everything.
  Useful during local development and load testing.
"""

from __future__ import annotations

from collections import defaultdict

from app.config import get_settings
from app.exceptions import UploadLimitError
from app.utils.logging import get_logger

logger = get_logger(__name__)

# ── In-memory counters ────────────────────────────────────────────────────────
# { "YYYY-MM-DD": { ip: count } }
_per_ip: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
# { "YYYY-MM-DD": count }
_global: dict[str, int] = defaultdict(int)


def _today_utc() -> str:
    """Return current UTC date as 'YYYY-MM-DD' string."""
    import datetime
    return datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%d")


def _prune_old_days() -> None:
    """Drop counters older than today to prevent unbounded memory growth.

    Called once per check — O(keys) but keys ≤ 2 in practice.
    """
    today = _today_utc()
    for day in list(_per_ip.keys()):
        if day != today:
            del _per_ip[day]
    for day in list(_global.keys()):
        if day != today:
            del _global[day]


def check_and_increment(ip: str, *, is_cache_hit: bool) -> None:
    """Check rate limits and increment counters for a new upload attempt.

    Args:
        ip: Client IP address string.
        is_cache_hit: If True, the image was already processed — skip limits
            entirely (re-uploading the same photo should never be penalised).

    Raises:
        UploadLimitError: If either the per-IP or global limit is exceeded.
            The error carries a ``scope`` attribute ("ip" or "global") so the
            HTTP handler can log and respond appropriately.
    """
    settings = get_settings()

    # Kill switch — bypass everything in development.
    if not settings.rate_limit_enabled:
        return

    # Cache hits never count toward any limit.
    if is_cache_hit:
        return

    _prune_old_days()
    today = _today_utc()

    # ── Global cap check ──────────────────────────────────────────────────────
    global_count = _global[today]
    if global_count >= settings.rate_limit_global_daily:
        logger.warning(
            "global_daily_cap_reached",
            date=today,
            count=global_count,
            cap=settings.rate_limit_global_daily,
        )
        raise UploadLimitError(
            "The app has reached its daily processing limit. Please try again tomorrow.",
            scope="global",
        )

    # ── Per-IP check ──────────────────────────────────────────────────────────
    ip_count = _per_ip[today][ip]
    if ip_count >= settings.rate_limit_per_ip_daily:
        logger.warning(
            "per_ip_daily_limit_reached",
            date=today,
            ip=ip,
            count=ip_count,
            limit=settings.rate_limit_per_ip_daily,
        )
        raise UploadLimitError(
            f"You've reached the daily limit of {settings.rate_limit_per_ip_daily} menus. "
            "Please try again tomorrow.",
            scope="ip",
        )

    # ── Increment both counters ───────────────────────────────────────────────
    _per_ip[today][ip] += 1
    _global[today] += 1

    logger.info(
        "rate_limit_incremented",
        date=today,
        ip=ip,
        ip_count=_per_ip[today][ip],
        global_count=_global[today],
    )


def get_status() -> dict:
    """Return current counter snapshot — useful for a debug/admin endpoint."""
    today = _today_utc()
    _prune_old_days()
    return {
        "date": today,
        "global_count": _global.get(today, 0),
        "per_ip": dict(_per_ip.get(today, {})),
    }
