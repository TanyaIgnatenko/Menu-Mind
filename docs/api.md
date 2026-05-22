# API Reference

Base URL (local): `http://localhost:8000/api/v1`

Interactive OpenAPI docs: `http://localhost:8000/docs`

All endpoints return JSON. Errors follow this shape:

```json
{ "error": "error_code", "message": "Human-readable message" }
```

## GET /health

Verify the service is running and the database is reachable.

**Response 200**

```json
{ "status": "ok", "database": "ok" }
```

If the database is unreachable the service still returns 200 with `status: "degraded"` and `database: "error"`.

## POST /menus/

Extract a structured menu from an uploaded image.

**Request:** `multipart/form-data` with a single `file` field.

Accepted formats: JPEG, PNG, WEBP. Max size: 10 MB.

**Response 201**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "source_language": "de",
  "restaurant_name": "Lemke am Schloss",
  "dishes": [
    {
      "name_original": "Wiener Schnitzel",
      "name_english": "Viennese cutlet",
      "description_original": "mit Kartoffeln",
      "description_english": "with potatoes",
      "size": "",
      "category": "Hauptgerichte",
      "price": "29,00 EUR"
    }
  ],
  "created_at": "2026-05-16T10:23:45.000Z"
}
```

**Idempotency:** uploading the same image bytes twice returns the same `id` and skips the LLM call.

**Errors**

| Status | `error` | When |
| --- | --- | --- |
| 400 | `invalid_image` | File is empty, too large, or not a supported format. |
| 429 | `rate_limited` | Gemini API rate-limited; retry after a few seconds. |
| 502 | `extraction_failed` | Gemini call failed or returned malformed output. |

## GET /menus/{menu_id}

Retrieve a previously extracted menu.

**Path parameter:** `menu_id` — UUID returned by `POST /menus/`.

**Response 200** — same shape as `POST /menus/` response.

**Errors**

| Status | Detail | When |
| --- | --- | --- |
| 404 | `Menu not found` | No menu exists with that ID. |
| 422 | FastAPI validation | `menu_id` is not a valid UUID. |
