# Architecture

This document explains the main technical decisions behind MenuMind and why they were chosen for Phases 1 and 2.

## High-level shape

```
[Browser / Next.js]
        |
        v
[FastAPI backend]
        |
        +--> [Gemini 2.5 Flash] (extraction + translation)
        |
        +--> [PostgreSQL] (idempotency cache + persistence)
```

Phase 1 builds the skeleton. Phase 2 implements the path from photo upload to a stored, structured menu. Enrichment (Phase 3), image generation (Phase 4), and AWS deployment (Phase 5+) come later.

## Backend: FastAPI

Chosen for:

- **Native async.** External calls (Gemini, Postgres) are I/O-bound. Async lets a single worker serve concurrent uploads without thread pools.
- **First-class Pydantic v2 support.** Request and response models, OpenAPI docs, and validation come from the same schemas the service layer uses.
- **Auto-generated OpenAPI docs** at `/docs`. Useful during development and as a portfolio artifact.

## Database: PostgreSQL via SQLAlchemy async + Alembic

Chosen for:

- **Production-ready foundation.** No prototype-feeling SQLite in the README. JSONB columns are first-class.
- **JSONB for `dishes_json`.** Phase 2 stores dishes as a JSON blob inside the menu row. Phase 3 may split into a normalised `dishes` table if querying by dish becomes a hot path; for now, the simpler schema is faster to ship.
- **Async access** via `asyncpg` driver and SQLAlchemy 2.0 async API. Matches FastAPI's runtime.
- **Alembic** for schema migrations from day one. Easier to add than to retrofit.

## VLM-first extraction (no OCR cascade)

The spec explicitly chooses a vision-language model over an OCR + text-LLM cascade.

Why:

- **One call, not two.** Lower latency, simpler error model.
- **Visual context preserved.** Multi-column layouts, handwritten daily specials, and decorative menus break OCR's reading order. A VLM looks at the whole image and reasons about it.
- **Translation in the same call.** The model sees the menu while translating, which preserves cultural nuance that "OCR text -> translate" loses.

The spike notebook compared this with an OCR + LLM cascade on real Berlin menus and the VLM approach won on both recall and translation quality.

## Idempotency via image hash

Every upload computes `sha256(image_bytes)` before doing anything else. The `image_hash` column on `menus` has a unique index. Two consequences:

- **Cheap re-uploads.** Same image returned from DB in <100 ms instead of paying for another LLM call.
- **Race condition is safe.** If two requests for the same image arrive simultaneously, one wins the unique constraint and the other catches `IntegrityError` and returns the winner's row.

## Schema discipline

Pydantic schemas are the contract between layers:

- **`Dish`, `Menu`, `MenuCreate`** in `app/schemas/` are used everywhere a record crosses a service boundary.
- **LLM output is validated** through `Dish.model_validate` before persistence. Malformed JSON raises `SchemaValidationError`, which the exception handler maps to HTTP 502.
- **DB models are separate** from API schemas. `MenuRecord` (SQLAlchemy) is internal; `Menu` (Pydantic) is the public shape.

## Structured logging

`structlog` configured to emit JSON to stdout. Every extraction event carries context: image size, dish count, source language, token counts. This makes log analysis trivial later (CloudWatch Logs Insights queries, etc.).

## Error handling

Custom domain exceptions in `app/exceptions.py`:

| Exception | HTTP code | Meaning |
| --- | --- | --- |
| `InvalidImageError` | 400 | Upload failed validation (size, format, empty). |
| `RateLimitError` | 429 | Gemini rate-limited; client should retry. |
| `ExtractionError` | 502 | Gemini call failed or timed out. |
| `SchemaValidationError` | 502 | Gemini returned malformed output. |

Services raise these; the API layer translates them to JSON responses via FastAPI exception handlers. No bare `except` in the codebase.

## Retry strategy

`tenacity` decorator on `GeminiClient.generate_with_image`:

- 3 attempts max
- Exponential backoff (2s, 4s, 8s capped)
- Retries **only** on `RateLimitError` — extraction or schema errors are not transient, no point retrying

## Caching

Phase 2 only caches at the menu level (whole extraction by image hash). Dish-level and image-generation caches come in Phases 3 and 4.

## Frontend: Next.js 15 + shadcn/ui

Chosen for:

- **App Router + RSC** keep client bundles small.
- **shadcn/ui** components are copied into the repo, not pulled from a black-box package — easier to customise and a stronger signal of intentional design choices than Material UI.
- **TypeScript strict mode** with `noEmit` type checks in CI.

The frontend mirrors the backend Pydantic schemas in `lib/types.ts`. When schemas change, update both.

## Testing

Two-tier strategy:

- **Unit tests** (`tests/unit/`) exercise pure logic: schema validation, image
  preprocessing, JSON parsing, extraction-service orchestration. They mock the
  `GeminiClient` and touch no database. Fast feedback (<1 second).
- **Integration tests** (`tests/integration/`) run against a real PostgreSQL
  instance. They exercise the same dialect behaviour as production: JSONB
  storage, UUID column types, unique constraints, the SQLAlchemy async session
  lifecycle. The Gemini client is still mocked — no network calls in CI.

Test isolation uses `NullPool` engine per test plus `TRUNCATE` on teardown:
each test gets a clean menus table without recreating the schema. This avoids
asyncpg's "another operation in progress" errors that arise when sessions
share connections across tests.

In-memory SQLite was considered for speed but rejected: it does not exercise
JSONB, native UUID, or any other Postgres-specific behaviour the application
relies on. The risk of green tests masking production bugs is not worth the
2-second time saving.

## What is deferred to later phases

- Enrichment (ingredients, cultural context, dietary tags) — Phase 3
- Image generation (Flux Schnell, S3 storage, parallel pipeline) — Phase 4
- AWS deployment (App Runner, RDS, S3, CloudFront, CloudFormation) — Phase 5+
- Observability beyond logs (CloudWatch metrics, alarms) — Phase 5+
- User authentication — out of scope for MVP
- Celery / Redis / Kafka — not needed for current scale; documented as future migration paths

These are deliberate non-decisions. The architecture supports adding them without rewriting Phase 2.
