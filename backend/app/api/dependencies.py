"""Shared FastAPI dependencies.

Currently re-exports `get_db` from the database session module. Add other
shared dependencies (e.g., auth, request ID) here in later phases.
"""
from app.database.session import get_db

__all__ = ["get_db"]
