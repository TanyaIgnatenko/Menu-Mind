"""Menu enrichment: derive cuisine type and highlight the most iconic dishes.

Runs as a separate Gemini call AFTER extraction. Extraction is faithful
transcription; enrichment is world knowledge (what cuisine, what's iconic).
Keeping them separate lets each prompt stay focused. Enrichment is best-effort:
if it fails, the menu is still fully usable without cuisine/iconic data.
"""
from pydantic import BaseModel

from app.clients.gemini import GeminiClient, parse_json_response
from app.schemas.menu import MenuCreate
from app.utils.logging import get_logger

logger = get_logger(__name__)


ENRICHMENT_PROMPT = """You are a culinary expert analyzing a restaurant menu.

Tasks:
1. Identify the cuisine. If it is clearly one cuisine, name it concisely
   (e.g. "Italian", "Russian", "Thai"). If the menu mixes cuisines or is
   unclear, use a broad label like "mixed European" — DO NOT invent a specific
   cuisine you are unsure of. A few words only, no description.
2. Select up to 3 of the MOST iconic / signature dishes (fewer if the menu is
   small or has no clear standouts). For each, write a SHORT appealing note
   (5 to 9 words) telling a traveler why to try it — e.g. "The most iconic pasta
   here", "Try this if you like seafood", "A must for first-time visitors".
   Do NOT flag common or generic items. Reference each dish by its number.

Return ONLY valid JSON in this schema:
{
  "cuisine_type": "...",
  "iconic": [
    {"index": 2, "note": "..."},
    {"index": 7, "note": "..."}
  ]
}

Dishes (numbered):
"""


class IconicDish(BaseModel):
    index: int
    note: str


class EnrichmentResult(BaseModel):
    cuisine_type: str = ""
    iconic: list[IconicDish] = []


async def enrich_menu(
    menu: MenuCreate,
    client: GeminiClient | None = None,
) -> EnrichmentResult:
    """Derive cuisine type and iconic-dish notes for a menu.

    Lenient parsing: returns whatever it can, capped at 3 iconic dishes.
    Caller is expected to treat this as best-effort.
    """
    client = client or GeminiClient()

    lines = []
    for i, dish in enumerate(menu.dishes):
        name = dish.name_english or dish.name_original
        category = dish.category_english or dish.category
        lines.append(f"{i}. {name} ({category})")
    dish_list = "\n".join(lines)

    prompt = ENRICHMENT_PROMPT + dish_list

    result = await client.generate_text(prompt)
    parsed = parse_json_response(result["text"])

    if not isinstance(parsed, dict):
        logger.warning("enrichment_bad_shape")
        return EnrichmentResult()

    cuisine_type = (parsed.get("cuisine_type") or "").strip()

    iconic: list[IconicDish] = []
    for item in (parsed.get("iconic") or [])[:3]:  # cap at 3
        if not isinstance(item, dict):
            continue
        idx = item.get("index")
        note = (item.get("note") or "").strip()
        if isinstance(idx, int) and note:
            iconic.append(IconicDish(index=idx, note=note))

    logger.info(
        "enrichment_completed",
        cuisine_type=cuisine_type,
        iconic_count=len(iconic),
        output_tokens=result["output_tokens"],
    )
    return EnrichmentResult(cuisine_type=cuisine_type, iconic=iconic)