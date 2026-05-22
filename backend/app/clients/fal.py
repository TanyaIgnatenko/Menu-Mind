"""FAL.ai API client for image generation via Flux Schnell.

We use the REST API directly via httpx rather than the fal_client SDK for two
reasons: simpler dependency tree, and more control over async behaviour.

API reference: https://fal.ai/models/fal-ai/flux/schnell/api
"""
import asyncio
from typing import Any

import httpx
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from app.config import get_settings
from app.exceptions import ExtractionError, RateLimitError
from app.utils.logging import get_logger

logger = get_logger(__name__)

FAL_BASE_URL = "https://queue.fal.run"


class FalClient:
    """Async client for FAL.ai image generation.

    Uses the FAL queue endpoint: submit job, poll for completion, fetch result.
    For Flux Schnell this typically completes in 2-4 seconds.
    """

    def __init__(self, api_key: str | None = None, model: str | None = None):
        settings = get_settings()
        self._api_key = api_key or settings.fal_api_key
        self._model = model or settings.fal_model
        self._timeout = settings.image_timeout_seconds
        self._headers = {"Authorization": f"Key {self._api_key}"}

    @property
    def is_configured(self) -> bool:
        """Whether FAL is configured (has API key)."""
        return bool(self._api_key)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=8),
        retry=retry_if_exception_type(RateLimitError),
        reraise=True,
    )
    async def generate_image(self, prompt: str) -> bytes:
        """Generate one image from a text prompt, return PNG/JPEG bytes.

        Raises:
            ExtractionError: on API failure or timeout.
            RateLimitError: when FAL rate-limits (auto-retried up to 3 times).
        """
        if not self._api_key:
            raise ExtractionError("FAL_API_KEY not configured")

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            image_url = await self._submit_and_wait(client, prompt)
            return await self._download(client, image_url)

    async def _submit_and_wait(self, client: httpx.AsyncClient, prompt: str) -> str:
        """Submit job to FAL queue, poll until ready, return image URL."""
        submit_url = f"{FAL_BASE_URL}/{self._model}"
        try:
            r = await client.post(
                submit_url,
                headers=self._headers,
                json={
                    "prompt": prompt,
                    "image_size": "square_hd",
                    "num_inference_steps": 4,
                    "num_images": 1,
                    "enable_safety_checker": True,
                },
            )
        except httpx.HTTPError as e:
            raise ExtractionError(f"FAL submit failed: {e}") from e

        if r.status_code == 429:
            raise RateLimitError(f"FAL rate limited: {r.text}")
        if r.status_code >= 400:
            raise ExtractionError(f"FAL submit error {r.status_code}: {r.text}")

        data = r.json()
        status_url = data.get("status_url")
        response_url = data.get("response_url")

        if not status_url or not response_url:
            raise ExtractionError(f"FAL response missing URLs: {data}")

        # Poll for completion
        poll_interval = 0.5
        max_polls = int(self._timeout / poll_interval)
        for _ in range(max_polls):
            await asyncio.sleep(poll_interval)
            try:
                status_resp = await client.get(status_url, headers=self._headers)
            except httpx.HTTPError as e:
                raise ExtractionError(f"FAL status poll failed: {e}") from e

            # FAL returns 200 when complete, 202 while in progress.
            # Treat anything outside that range as a real error.
            if status_resp.status_code not in (200, 202):
                raise ExtractionError(
                    f"FAL status error {status_resp.status_code}: {status_resp.text}"
                )

            status_data = status_resp.json()
            status = status_data.get("status")
            if status == "COMPLETED":
                break
            if status in ("FAILED", "ERROR"):
                raise ExtractionError(f"FAL generation failed: {status_data}")
            # IN_PROGRESS or IN_QUEUE - keep polling

        else:
            raise ExtractionError(f"FAL generation timed out after {self._timeout}s")

        # Fetch result
        try:
            result_resp = await client.get(response_url, headers=self._headers)
        except httpx.HTTPError as e:
            raise ExtractionError(f"FAL result fetch failed: {e}") from e

        if result_resp.status_code != 200:
            raise ExtractionError(
                f"FAL result error {result_resp.status_code}: {result_resp.text}"
            )

        result: dict[str, Any] = result_resp.json()
        images = result.get("images", [])
        if not images:
            raise ExtractionError(f"FAL result missing images: {result}")

        image_url: str = images[0].get("url", "")
        if not image_url:
            raise ExtractionError(f"FAL image missing url: {images[0]}")

        return image_url

    async def _download(self, client: httpx.AsyncClient, image_url: str) -> bytes:
        """Download generated image bytes."""
        try:
            r = await client.get(image_url)
        except httpx.HTTPError as e:
            raise ExtractionError(f"Image download failed: {e}") from e
        if r.status_code != 200:
            raise ExtractionError(f"Image download error {r.status_code}")
        return r.content
