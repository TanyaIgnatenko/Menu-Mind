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
- name_english: English version of the name. Set this to "" ONLY if name_original is genuinely in English (composed of English words or an English-language menu entry) OR if it already includes an explicit English translation separated by a slash/dash (e.g. "Crema di Pomodoro / Tomato Cream"). LOANWORDS DO NOT COUNT AS ALREADY-ENGLISH: dishes like "Spaghetti alla Carbonara", "Lasagna", "Gnocchi", "Sushi", "Tiramisu", "Pierogi" are Italian/Japanese/Polish names borrowed into English — for these you MUST still provide name_english, either as a clean English translation ("Pasta with Pancetta and Egg") or, when the name has no real English equivalent, simply repeat or transliterate the dish name in name_english so the field is populated. The original may contain the SAME item in several non-English languages (e.g. German + Russian) — in that case give ONE single English translation, do NOT translate each language separately.
- description_original: description text from the menu, or empty string if none
- description_english: English translation of the description. PROVIDE THIS ONLY IF the original description does not already contain English. If description_original is already English or already includes an English version, set this to "". If the original repeats the same description in multiple non-English languages (e.g. German and Russian), produce ONE single English translation — never concatenate or duplicate translations per language. Empty string if there is no description.
- fun_facts: 2-4 short interesting facts or highlights about this dish. Focus on: origin, key ingredients, cooking method, cultural significance, flavor profile, common variations. Write in English. Each fact is 1-2 sentences. Return as a list of strings. Return [] if nothing interesting to say.
- nutrition: estimated nutritional values per typical serving of this dish. Base your estimate on standard culinary knowledge — this is an approximation, not a medical fact. Return an object with:
  - calories: integer (kcal per serving), e.g. 450
  - protein_g: float (grams of protein), e.g. 22.5
  - carbs_g: float (grams of carbohydrates), e.g. 38.0
  - fat_g: float (grams of fat), e.g. 18.5
  If you truly cannot estimate (e.g. dish is completely unrecognisable), return null.
- size: serving size if explicitly specified (e.g. "20cl", "2cl"), otherwise empty
- category: section header from the menu (e.g. "Suppen", "Pasta"). Preserve slash-separated bilingual headers like "Zuppe / Suppen".
- category_english: clean English translation of the category. PROVIDE THIS ONLY IF the category does not already contain English. If the category is already English or includes an English version (e.g. "Zuppe / Soups"), set this to "". For multilingual non-English categories (e.g. "Vorspeisen & Salate // Закуски & салаты"), give ONE single English translation (e.g. "Appetizers & Salads").
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
- dietary_tags: array of dietary/preference tags. Use ONLY these values:
vegan, vegetarian, contains_pork, contains_beef, contains_chicken, contains_turkey, contains_fish, contains_shellfish, contains_eggs, contains_dairy, contains_nuts, contains_gluten, contains_alcohol, spicy, sweet, low_calorie
  Tagging rules:
    - Base tags on general culinary knowledge of the dish AS TYPICALLY PREPARED, not only on the menu text. Example: "Spaghetti alla Carbonara" -> ["contains_pork", "contains_dairy", "contains_eggs", "contains_gluten"] even if ingredients are not listed.
    - "vegan" / "vegetarian": add ONLY when confident the dish qualifies. A vegan dish gets BOTH tags (vegan implies vegetarian).
    - "contains_*": add whenever the ingredient is typically or plausibly present, even if not written on the menu (e.g. butter in sauces -> contains_dairy, mayonnaise -> contains_eggs, bacon bits in salad -> contains_pork). When uncertain, INCLUDE the warning — it is safer to warn than to miss an allergen.
    - "contains_fish" is for fish only; "contains_shellfish" is for crustaceans and molluscs (shrimp, prawns, crab, lobster, mussels, oysters, squid, octopus). These are separate allergies — tag them separately. Mixed seafood dishes get both.
    - "spicy": the dish is typically hot/spicy, or the menu marks it as such (chili icon, "scharf", "piccante").
    - "sweet": desserts and clearly sweet dishes or drinks.
    - "low_calorie": add ONLY for clearly light dishes (fresh salads without heavy dressing, steamed vegetables, clear soups). When in doubt, omit.
    - Plain drinks (water, espresso, tea) usually get [] or just relevant tags (wine -> ["contains_alcohol"], latte -> ["contains_dairy"]).
    - If you cannot judge the dish at all, return [].

Also identify:
- source_language: ISO code of the menu's primary language (de, en, it, fr, es, etc.)
- restaurant_name: the restaurant or establishment name. Look everywhere — header, footer, watermark, diagonal background text, logo area, corners. Even faint or decorative text counts. If you see any name (e.g. "Trattoria Sapore") anywhere on the image, return it. Return null only if truly absent.
- cuisine_type: the cuisine style of this menu in English, e.g. "Italian", "Japanese", "German", "French", "Mexican", "Chinese", "Indian", "Mediterranean", "Middle Eastern", "Thai", "Korean", "American", "Greek", "Spanish", "Vietnamese", "Turkish", "Lebanese", "Peruvian", "Fusion". Infer from dish names and ingredients even if not stated explicitly. Use a single short noun or adjective. Return null only if the cuisine is truly ambiguous or mixed with no dominant style.

Return ONLY valid JSON in this schema:
{
  "source_language": "de",
  "restaurant_name": "Restaurant Name" | null,
  "cuisine_type": "Italian" | null,
  "dishes": [
    {
      "name_original": "...",
      "name_english": "...",
      "description_original": "...",
      "description_english": "...",
      "fun_facts": ["...", "..."],
      "nutrition": {"calories": 450, "protein_g": 22.5, "carbs_g": 38.0, "fat_g": 18.5},
      "size": "",
      "category": "...",
      "category_english": "...",
      "visual_appearance": "...",
      "price": "...",
      "dietary_tags": ["contains_dairy", "contains_gluten"]
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
- ENGLISH FIELDS (name_english, description_english, category_english): only fill these when the original lacks English. Whenever the original text already contains English, the corresponding English field MUST be "". When the original has multiple non-English languages, output a SINGLE English translation - do not duplicate it once per language.
- dietary_tags: use ONLY values from the allowed list above. Never invent new tag names.
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
    cuisine_type = parsed.get("cuisine_type") or None

    menu = MenuCreate(
        source_language=source_language,
        restaurant_name=restaurant_name,
        cuisine_type=cuisine_type,
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
