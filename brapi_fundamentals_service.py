"""Best-effort B3 fundamentals from BrAPI."""

from __future__ import annotations

import logging
import os
import re
import time
from datetime import datetime, timezone
from typing import Any

import httpx


logger = logging.getLogger(__name__)
_CACHE_TTL_SECONDS = 15 * 60
_cache: dict[str, dict[str, Any]] = {}
_B3_PATTERN = re.compile(r"^[A-Z]{4,6}\d{1,2}$")


def is_brazilian_ticker(ticker: str) -> bool:
    normalized = ticker.strip().upper()
    return normalized.endswith(".SA") or bool(_B3_PATTERN.fullmatch(normalized))


def _number(item: dict, *keys: str) -> float | None:
    for key in keys:
        value = item.get(key)
        if isinstance(value, (int, float)):
            return float(value)
    return None


def _percent(value: float | None) -> float | None:
    if value is None:
        return None
    return value * 100 if abs(value) <= 1 else value


async def get_brapi_fundamentals(
    ticker: str, brapi_token: str | None = None
) -> dict | None:
    """Return selected BrAPI fundamentals for Brazilian stocks."""
    if not is_brazilian_ticker(ticker):
        return None
    normalized = ticker.strip().upper().removesuffix(".SA")
    cached = _cache.get(normalized)
    now = time.time()
    if cached and now - float(cached["timestamp"]) < _CACHE_TTL_SECONDS:
        return cached["data"]

    params = {"fundamental": "true"}
    token = brapi_token or os.getenv("BRAPI_TOKEN")
    if token:
        params["token"] = token
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://brapi.dev/api/quote/{normalized}",
                params=params,
                timeout=8.0,
            )
            response.raise_for_status()
            results = response.json().get("results") or []
    except Exception as exc:
        logger.warning("Falha ao buscar fundamentos BrAPI para %s: %s", normalized, exc)
        return None
    if not results:
        return None

    item = results[0]
    data = {
        "ticker": normalized,
        "nome": item.get("longName") or item.get("shortName"),
        "setor": item.get("sector") or item.get("industry"),
        "pl": _number(item, "priceEarnings", "trailingPE"),
        "pvp": _number(item, "priceToBook"),
        "dy": _percent(_number(item, "dividendYield")),
        "roe": _percent(_number(item, "returnOnEquity")),
        "margem_liquida": _percent(_number(item, "netMargin", "profitMargins")),
        "divida_liquida_ebitda": _number(
            item, "netDebtToEbitda", "netDebtEbitda"
        ),
        "market_cap": _number(item, "marketCap"),
        "fonte": "BrAPI",
        "atualizado_em": datetime.now(timezone.utc).isoformat(),
    }
    _cache[normalized] = {"timestamp": now, "data": data}
    return data


def _format_number(value: Any, decimals: int = 1) -> str:
    return f"{float(value):.{decimals}f}".replace(".", ",")


def format_fundamentals_for_prompt(fund: dict | None) -> str:
    if not fund:
        return ""
    parts = [f"Fundamentos {fund.get('ticker', 'B3')}"]
    fields = [
        ("pl", "P/L", ""),
        ("pvp", "P/VP", ""),
        ("dy", "DY", "%"),
        ("roe", "ROE", "%"),
        ("margem_liquida", "Margem liquida", "%"),
        ("divida_liquida_ebitda", "Div/EBITDA", "x"),
    ]
    for key, label, suffix in fields:
        if fund.get(key) is not None:
            parts.append(f"{label}: {_format_number(fund[key])}{suffix}")
    return " | ".join(parts) if len(parts) > 1 else ""
