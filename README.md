# MenuMind

> Eat with confidence, anywhere in the world.

MenuMind is an AI-powered application that helps travelers and expats understand restaurant menus in foreign languages. Photograph any menu, get back bilingual extraction (original + English), dish details, and — in later phases — cultural context, dietary safety flags, and AI-generated dish images.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Project skeleton, dev environment, infrastructure | ✅ Done |
| 2 | End-to-end extraction pipeline (photo → bilingual menu) | ✅ Done |
| 4 | Image generation with 20s latency target | ✅ Done |
| 3 | Enrichment + dietary safety | Planned |
| 5+ | AWS deployment, IaC, polish | Planned |

## Tech stack

| Layer | Tech |
| --- | --- |
| Backend | FastAPI, Python 3.12, SQLAlchemy 2.0 async, Pydantic v2 |
| Database | PostgreSQL 16 (JSONB), Alembic migrations |
| LLM | Google Gemini 2.5 Flash via `google-genai` |
| Image gen | FAL.ai Flux Schnell via REST API |
| Frontend | Next.js 15, TypeScript, Tailwind CSS, shadcn/ui |
| Testing | pytest, pytest-asyncio, httpx, real Postgres |
| Tooling | ruff, mypy strict, Docker Compose, GitHub Actions |

See [`docs/architecture.md`](docs/architecture.md) for the reasoning behind these choices, and [`docs/api.md`](docs/api.md) for endpoint reference.

## Repository structure

```
menumind/
├── backend/        # FastAPI service
│   ├── app/        # Application code
│   ├── tests/      # Unit + integration tests
│   ├── alembic/    # Database migrations
│   └── Dockerfile
├── frontend/       # Next.js app
│   ├── app/        # App Router pages
│   ├── components/ # React components (incl. shadcn/ui)
│   └── lib/        # API client, types, utils
├── docs/
├── .github/workflows/
└── docker-compose.yml
```

## Running locally

### Prerequisites

- Docker + Docker Compose
- Node.js 20+
- A Google Gemini API key (free tier: https://aistudio.google.com/)
- A FAL.ai API key for image generation (free $5 credit on signup: https://fal.ai/)
  Without this key, text extraction still works — only image generation is disabled.

### Setup

1. Clone this repo and `cd` into it.

2. Copy environment templates:

   ```bash
   cp backend/.env.example backend/.env
   cp frontend/.env.local.example frontend/.env.local
   ```

3. Open `backend/.env` and set:
   - `GEMINI_API_KEY` to your real Gemini key
   - `FAL_API_KEY` to your FAL.ai key (or leave empty to disable image generation)

4. Start the backend and database:

   ```bash
   docker-compose up
   ```

   On first start, Alembic creates the `menus` table automatically. The backend will be available at `http://localhost:8000`. Confirm with:

   ```bash
   curl http://localhost:8000/api/v1/health
   ```

5. In a separate terminal, start the frontend:

   ```bash
   cd frontend
   npm install
   npm run dev
   ```

6. Open `http://localhost:3000` and upload a menu photo.

### Running tests

Tests are split into two tiers:

- **Unit tests** (`tests/unit/`) — pure logic, no database, no network. Fast.
- **Integration tests** (`tests/integration/`) — run against a real PostgreSQL
  database to exercise the same dialect behaviour as production (JSONB, UUID,
  unique constraints). The Gemini client is still mocked, so no network calls.

Integration tests need Postgres running. The easiest way is `docker-compose up db`
to launch the database container, then in another terminal:

```bash
cd backend
pip install -e ".[dev]"
export TEST_DATABASE_URL=postgresql+asyncpg://menumind:dev@localhost:5432/menumind_test
createdb -h localhost -U menumind menumind_test  # one-time setup
pytest --cov=app
```

To run only unit tests (no Postgres needed):

```bash
pytest tests/unit/
```

### Quality checks

```bash
cd backend
ruff check .
mypy app
```

```bash
cd frontend
npm run lint
npm run type-check
npm run build
```

## License

[MIT](LICENSE)
