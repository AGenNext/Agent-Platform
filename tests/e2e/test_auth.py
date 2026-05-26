"""E2E: API key authentication.

These tests only run meaningfully when E2E_API_KEY is set AND the server has
PLATFORM_API_KEYS configured.  They are skipped automatically when auth is
disabled (empty PLATFORM_API_KEYS means dev-mode pass-through).
"""
import os
import pytest
import httpx

from conftest import API_BASE, API_KEY

pytestmark = pytest.mark.asyncio

_AUTH_ROUTE = "/agents/run/nonexistent-run"


def _requires_auth_configured():
    if not API_KEY:
        pytest.skip("E2E_API_KEY not set — auth enforcement tests require PLATFORM_API_KEYS on the server")


async def test_missing_key_returns_401(api_no_auth):
    _requires_auth_configured()
    r = await api_no_auth.get(_AUTH_ROUTE)
    assert r.status_code == 401, (
        f"Expected 401 without API key, got {r.status_code}. "
        "Is PLATFORM_API_KEYS set on the server?"
    )


async def test_invalid_key_returns_401(api_no_auth):
    _requires_auth_configured()
    r = await api_no_auth.get(_AUTH_ROUTE, headers={"X-API-Key": "wrong-key-xyz"})
    assert r.status_code == 401


async def test_valid_key_does_not_return_401(api):
    _requires_auth_configured()
    r = await api.get(_AUTH_ROUTE)
    assert r.status_code != 401, f"Valid API key still returned 401: {r.text}"


async def test_cors_preflight_responds(api_no_auth):
    r = await api_no_auth.options(
        "/health",
        headers={
            "Origin": "https://example.com",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert r.status_code in (200, 204), f"CORS preflight failed: {r.status_code}"
