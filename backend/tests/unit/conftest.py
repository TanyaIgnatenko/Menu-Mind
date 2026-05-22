"""Unit-test-specific fixtures.

Unit tests must not touch the database or any external services. They use
mocked clients (provided by the parent conftest.py) and pure-Python fixtures.

This file exists as a marker — add unit-only fixtures here when needed.
"""
