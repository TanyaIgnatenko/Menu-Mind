"""Integration-test fixtures using a real PostgreSQL database.

Strategy
--------
Each test gets its own engine with NullPool to avoid asyncpg connection
contention across tests. Schema is set up once per session, then each test
runs inside a transaction that rolls back on teardown. This gives:

- Real Postgres behaviour (JSONB, UUID, indexes, constraints all exercised).
- Fast test isolation — no need to drop/recreate tables between tests.
- Each test gets its own connection (NullPool), avoiding asyncpg's "another
  operation in progress" errors when sessions share connections.

Required: a running Postgres instance accessible at TEST_DATABASE_URL.
The CI workflow provides this via a service container; local dev can use
the docker-compose db service.
"""
import os
from collections.abc import AsyncGenerator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from app.api.dependencies import get_db
from app.database.session import Base
from app.main import app

TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://menumind:dev@localhost:5432/menumind_test",
)


@pytest_asyncio.fixture(scope="session")
async def _setup_schema() -> AsyncGenerator[None, None]:
    """Create schema once at session start, drop at session end."""
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    yield
    cleanup_engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
    async with cleanup_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await cleanup_engine.dispose()


@pytest_asyncio.fixture
async def db_session(_setup_schema: None) -> AsyncGenerator[AsyncSession, None]:
    """Function-scoped session that truncates the menus table on teardown.

    We use truncate-on-teardown rather than transaction rollback because
    the API code under test issues its own commit, which interacts poorly
    with nested-transaction patterns when using asyncpg.
    """
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        yield session
        await session.close()

    # Clean state for next test
    async with engine.begin() as conn:
        await conn.exec_driver_sql("TRUNCATE TABLE menus")
    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """httpx AsyncClient wired to the FastAPI app with the test DB session."""

    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()

