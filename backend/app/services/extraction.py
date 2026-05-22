"""Menu extraction service: photo bytes -> structured MenuCreate."""
from pydantic import ValidationError

from app.clients.gemini import GeminiClient, parse_json_response
from app.exceptions import SchemaValidationError
from app.schemas.dish import Dish
from app.schemas.menu import MenuCreate
from app.utils.logging import get_logger

logger = get_logger(__name__)


EXTRACTION_PROMPT = """You are extracting structured data from a restaurant menu photograph.

Extract every dish/drink visible on the menu. For each item, provide these fields:
- name_original: dish name exactly as written on the menu (in source language)
- name_english: English translation of the name
- description_original: description text from the menu, or empty string if none
- description_english: English translation of the description, or empty if no description
- size: serving size if explicitly specified (e.g. "20cl", "2cl"), otherwise empty
- category: section header from the menu (e.g. "Suppen", "Pasta"). Preserve slash-separated bilingual headers like "Zuppe / Suppen".
- category_english: clean English translation of the category (e.g. "Soups", "Pasta")
- visual_appearance: a SHORT description of how this dish physically LOOKS, written for someone who will draw or photograph it. Describe SHAPE, COLORS, and PLATING STYLE — not the ingredient list. For LAYERED dishes (terrines, layered salads, tiramisu, lasagna, cakes), explicitly mention "side view" or "cross-section showing layers" so the layers are visible. For most other dishes no angle is needed. For well-known dishes, describe their canonical look. Examples:
    - "Сельдь под шубой" -> "layered salad shaped like a cake, cross-section side view showing distinct colorful layers, bright pink-purple beetroot on top, white mayonnaise and fish layers below"
    - "Tiramisu" -> "side view showing layered dessert, alternating cream and coffee-soaked sponge layers, dusted with cocoa on top"
    - "Caesar Salad" -> "romaine lettuce in a wide bowl, topped with croutons, shaved parmesan, creamy dressing"
    - "Espresso" -> "small cup of dark coffee with golden crema on top, on a saucer"
  If you are unsure how the dish looks, leave this empty.
- price: price with currency. Many menus use typographic conventions for cents:
    - Superscript cents: "14\u2070\u2070" means 14.00
    - Small/raised cents without separator: "1400" or "14 00" where context implies decimal -> interpret as 14.00
    - Standard formats: "14,90" (European), "14.90" (US) - keep as is
  Output prices in format like "14.00 EUR" or "14,90 EUR" matching menu's locale convention.
  If currency symbol/word is not visible, append " EUR" assuming euros.

Also identify:
- source_language: ISO code of the menu's primary language (de, en, it, fr, es, etc.)
- restaurant_name: if visible on the menu, otherwise null

Return ONLY valid JSON in this schema:
{
  "source_language": "de",
  "restaurant_name": "Restaurant Name" | null,
  "dishes": [
    {
      "name_original": "...",
      "name_english": "...",
      "description_original": "...",
      "description_english": "...",
      "size": "",
      "category": "...",
      "category_english": "...",
      "visual_appearance": "...",
      "price": "..."
    }
  ]
}

Critical rules:
- Do NOT invent dishes that are not visible
- Preserve original spelling and capitalization in name_original
- Include every dish - do not summarize or skip
- Do not include menu numbering codes (e.g. "675.") as part of the dish name
- Interpret superscript or raised cents as decimal - never output prices like "1400" as whole numbers
- If you cannot read part of the menu clearly, still include what you can see
"""


async def extract_menu_from_image(
    image_bytes: bytes,
    client: GeminiClient | None = None,
) -> MenuCreate:
    """Extract a structured menu from preprocessed image bytes.

    Args:
        image_bytes: JPEG bytes (already preprocessed).
        client: optional injected GeminiClient (for testing).

    Returns:
        MenuCreate ready to be persisted.

    Raises:
        ExtractionError: if Gemini call fails.
        SchemaValidationError: if output cannot be parsed or validated.
    """
    client = client or GeminiClient()

    logger.info("extraction_started", image_size=len(image_bytes))

    result = await client.generate_with_image(
        prompt=EXTRACTION_PROMPT,
        image_bytes=image_bytes,
    )

    parsed = parse_json_response(result["text"])

    if not isinstance(parsed, dict):
        raise SchemaValidationError("Expected JSON object at top level")

    dishes_raw = parsed.get("dishes")
    if not isinstance(dishes_raw, list):
        raise SchemaValidationError("'dishes' field missing or not a list")

    try:
        dishes = [Dish.model_validate(d) for d in dishes_raw]
    except ValidationError as e:
        raise SchemaValidationError(f"Dish schema invalid: {e}") from e

    if not dishes:
        raise SchemaValidationError("No dishes extracted from menu")

    source_language = parsed.get("source_language") or "unknown"
    restaurant_name = parsed.get("restaurant_name")

    menu = MenuCreate(
        source_language=source_language,
        restaurant_name=restaurant_name,
        dishes=dishes,
    )

    logger.info(
        "extraction_completed",
        dish_count=len(menu.dishes),
        source_language=menu.source_language,
        input_tokens=result["input_tokens"],
        output_tokens=result["output_tokens"],
    )

    return menu
