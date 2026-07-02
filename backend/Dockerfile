FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
RUN pip install --no-cache-dir --user --upgrade pip && \
    pip install --no-cache-dir --user .


FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash app

COPY --from=builder /root/.local /home/app/.local
ENV PATH=/home/app/.local/bin:$PATH

COPY ./app ./app
COPY ./alembic.ini ./
COPY ./alembic ./alembic

RUN chown -R app:app /app
USER app

EXPOSE 8000

# Apply DB migrations, then bind to the platform's $PORT (Railway/Render inject
# it; falls back to 8000 locally). `exec` keeps uvicorn as PID 1 for signals.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
