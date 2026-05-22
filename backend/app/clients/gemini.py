"""Gemini API client wrapper with retry, timeout, and JSON parsing."""
import asyncio
import json
import re
from typing import Any

from google import genai
from google.genai import types
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from app.config import get_settings
from app.exceptions import ExtractionError, RateLimitError, SchemaValidationError
from app.utils.logging import get_logger

logger = get_logger(__name__)


class GeminiClient:
    """Thin async wrapper around google-genai for menu extraction.

    Provides retry on rate-limit errors and structured error mapping to our
    domain exceptions.
    """

    def __init__(self, api_key: str | None = None):
        settings = get_settings()
        self._client = genai.Client(api_key=api_key or settings.gemini_api_key)
        self._timeout = settings.gemini_timeout_seconds

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(RateLimitError),
        reraise=True,
    )
    async def generate_with_image(
        self,
        prompt: str,
        image_bytes: bytes,
        model: str = "gemini-2.5-flash",
    ) -> dict[str, Any]:
        """Call Gemini with image + prompt, return raw text and token counts.

        Raises:
            ExtractionError: if Gemini call fails for non-rate-limit reasons.
            RateLimitError: if rate-limited (retries automatically up to 3 times).
        """
        try:
            response = await asyncio.wait_for(
                self._generate(prompt, image_bytes, model),
                timeout=self._timeout,
            )
        except TimeoutError as e:
            raise ExtractionError(f"Gemini call exceeded {self._timeout}s timeout") from e
        except Exception as e:
            msg = str(e).lower()
            # Rate limit (429) and Service Unavailable (503) are both transient
            # and worth retrying via the tenacity decorator above.
            if any(token in msg for token in ("rate", "quota", "429", "503", "unavailable", "overloaded")):
                raise RateLimitError(str(e)) from e
            raise ExtractionError(f"Gemini call failed: {e}") from e

        return {
            "text": response.text,
            "input_tokens": response.usage_metadata.prompt_token_count,
            "output_tokens": response.usage_metadata.candidates_token_count,
        }

    async def _generate(self, prompt: str, image_bytes: bytes, model: str) -> Any:
        # The google-genai stubs expect a list[str | Image | File | Part] union, not a
        # list parameterised with Part | str. We construct it as the wider type.
        from google.genai.types import File, Part
        from PIL.Image import Image as PILImage

        contents: list[str | PILImage | File | Part] = [
            types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
            prompt,
        ]
        return await self._client.aio.models.generate_content(
            model=model,
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            ),
        )


def parse_json_response(text: str) -> Any:
    """Parse JSON from an LLM response, tolerating markdown code fences.

    Raises:
        SchemaValidationError: if text is not valid JSON.
    """
    text = text.strip()
    fence_match = re.match(r"^```(?:json)?\s*(.*?)\s*```$", text, re.DOTALL)
    if fence_match:
        text = fence_match.group(1).strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        raise SchemaValidationError(f"LLM returned invalid JSON: {e}") from e
