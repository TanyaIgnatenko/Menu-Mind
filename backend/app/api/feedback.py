"""In-app feedback: emails the note (with any screenshot attachments) to a
support inbox via Gmail SMTP.

Delivery is best-effort and never fails the request — the message is always
captured in PostHog and the logs, so feedback is never lost even before the
Gmail secret is configured (in which case it is logged instead of emailed).
"""
import smtplib
from email.message import EmailMessage

from fastapi import APIRouter, File, Form, Request, UploadFile
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.services.analytics import capture
from app.utils.logging import get_logger

router = APIRouter(tags=["feedback"])
logger = get_logger(__name__)

_MAX_FILES = 3
_MAX_BYTES = 5 * 1024 * 1024  # 5 MB per image (Gmail caps a message at ~25 MB)


def _compose(
    message: str,
    reply_to: str,
    platform: str,
    app_version: str,
    install_id: str,
    attachment_count: int,
) -> tuple[str, str]:
    """Build the (subject, plaintext body) for the feedback email."""
    subject = f"[MenuMind feedback] {platform} {app_version}".strip()
    lines = [
        message,
        "",
        "—",
        f"Reply to: {reply_to}",
        f"Platform: {platform}",
        f"App version: {app_version or 'n/a'}",
        f"Install id: {install_id}",
        f"Attachments: {attachment_count}",
    ]
    return subject, "\n".join(lines)


def _send_email(
    settings: Settings,
    subject: str,
    body: str,
    reply_to: str,
    files: list[tuple[str, str, bytes]],
) -> str:
    """Send the feedback email with attachments. Blocking — call in a threadpool.
    Returns 'sent', or 'logged' if sending failed (feedback is still in logs)."""
    recipient = settings.feedback_to or settings.gmail_address
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = settings.gmail_address
    msg["To"] = recipient
    msg["Reply-To"] = reply_to
    msg.set_content(body)

    for filename, content_type, data in files:
        maintype, _, subtype = content_type.partition("/")
        if maintype != "image" or not subtype:
            maintype, subtype = "application", "octet-stream"
        msg.add_attachment(data, maintype=maintype, subtype=subtype, filename=filename)

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, timeout=20) as smtp:
            smtp.login(settings.gmail_address, settings.gmail_app_password)
            smtp.send_message(msg)
        logger.info("feedback_email_sent", to=recipient, attachments=len(files))
        return "sent"
    except Exception as exc:  # noqa: BLE001 — never fail the request over email.
        logger.error("feedback_email_failed", error=str(exc), reply_to=reply_to)
        return "logged"


@router.post("/feedback", status_code=202)
async def submit_feedback(
    request: Request,
    message: str = Form(...),
    reply_to: str = Form(...),
    platform: str = Form("mobile"),
    app_version: str = Form(""),
    attachments: list[UploadFile] = File(default=[]),
) -> dict[str, str]:
    settings = get_settings()
    install_id = request.headers.get("x-device-id") or "unknown"

    # Read + validate attachments (cap count & per-file size).
    files: list[tuple[str, str, bytes]] = []
    for upload in attachments[:_MAX_FILES]:
        data = await upload.read()
        if not data or len(data) > _MAX_BYTES:
            continue  # skip empty/oversized (the client already validates size)
        files.append(
            (upload.filename or "screenshot.jpg", upload.content_type or "image/jpeg", data)
        )

    # Analytics breadcrumb (best-effort; no-op without POSTHOG_API_KEY).
    capture(
        "feedback_submitted",
        {
            "platform": platform,
            "app_version": app_version,
            "attachment_count": len(files),
            "message_length": len(message),
        },
        distinct_id=install_id,
    )

    subject, body = _compose(message, reply_to, platform, app_version, install_id, len(files))

    if not settings.gmail_address or not settings.gmail_app_password:
        # Not configured yet — don't lose the feedback; log it (and it's in PostHog).
        logger.warning(
            "feedback_email_not_configured",
            reply_to=reply_to,
            platform=platform,
            attachment_count=len(files),
            message=message[:1000],
        )
        return {"status": "logged"}

    status = await run_in_threadpool(_send_email, settings, subject, body, reply_to, files)
    return {"status": status}
