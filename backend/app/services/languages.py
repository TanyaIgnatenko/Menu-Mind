"""Supported menu-translation target languages (server-side).

Kept in sync with the mobile picker (mobile/lib/models/language.dart). The
English *name* of the language is injected into the extraction/enrichment
prompts as the translation target. Unknown or empty codes fall back to English,
so older clients that don't send a language keep working unchanged.
"""

LANGUAGE_NAMES: dict[str, str] = {
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "it": "Italian",
    "pt": "Portuguese",
    "nl": "Dutch",
    "ru": "Russian",
    "uk": "Ukrainian",
    "pl": "Polish",
    "cs": "Czech",
    "sk": "Slovak",
    "hu": "Hungarian",
    "ro": "Romanian",
    "bg": "Bulgarian",
    "el": "Greek",
    "tr": "Turkish",
    "sv": "Swedish",
    "da": "Danish",
    "no": "Norwegian",
    "fi": "Finnish",
    "is": "Icelandic",
    "hr": "Croatian",
    "sr": "Serbian",
    "sl": "Slovenian",
    "lt": "Lithuanian",
    "lv": "Latvian",
    "et": "Estonian",
    "zh": "Chinese (Simplified)",
    "zh-TW": "Traditional Chinese",
    "ja": "Japanese",
    "ko": "Korean",
    "th": "Thai",
    "vi": "Vietnamese",
    "id": "Indonesian",
    "ms": "Malay",
    "tl": "Filipino",
    "hi": "Hindi",
    "bn": "Bengali",
    "ta": "Tamil",
    "te": "Telugu",
    "ur": "Urdu",
    "fa": "Persian",
    "ar": "Arabic",
    "he": "Hebrew",
    "sw": "Swahili",
    "am": "Amharic",
    "af": "Afrikaans",
}

DEFAULT_LANGUAGE = "en"


def resolve_language(code: str | None) -> tuple[str, str]:
    """Return (normalized_code, english_name) for a requested target language.

    Matching is case-insensitive but preserves the canonical key (e.g. "zh-TW").
    Unknown or empty codes fall back to English.
    """
    if code:
        for key, name in LANGUAGE_NAMES.items():
            if key.lower() == code.lower():
                return key, name
    return DEFAULT_LANGUAGE, LANGUAGE_NAMES[DEFAULT_LANGUAGE]
