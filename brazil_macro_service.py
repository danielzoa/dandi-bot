"""Brazilian macroeconomic context backed by Banco Central do Brasil APIs."""

from __future__ import annotations

import logging
import time
from datetime import datetime, timedelta, timezone
from typing import Any

try:
    from bcb import Expectativas, PTAX, sgs
except ImportError:  # Keep the backend usable before optional deps are installed.
    Expectativas = PTAX = sgs = None


logger = logging.getLogger(__name__)
_CACHE_TTL_SECONDS = 30 * 60
_cache: dict[str, Any] = {"timestamp": 0.0, "data": None}


def _empty_macro() -> dict:
    return {
        "selic_meta": None,
        "ipca_12m": None,
        "ipca_acumulado_ano": None,
        "cambio_usd": None,
        "focus": {
            "ipca_ano_corrente": None,
            "selic_ano_corrente": None,
            "cambio_ano_corrente": None,
            "pib_ano_corrente": None,
        },
        "atualizado_em": datetime.now(timezone.utc).isoformat(),
        "fonte": "BCB/SGS + Expectativas",
    }


def _numeric_values(frame: Any) -> list[float]:
    if frame is None or getattr(frame, "empty", True):
        return []
    values: list[float] = []
    for value in frame.select_dtypes(include="number").to_numpy().flatten():
        try:
            values.append(float(value))
        except (TypeError, ValueError):
            continue
    return values


def _fetch_sgs(macro: dict) -> None:
    if sgs is None:
        raise RuntimeError("python-bcb nao esta instalado")

    today = datetime.now().date()
    try:
        selic = sgs.get(432, start=today - timedelta(days=30), end=today)
        values = _numeric_values(selic)
        if values:
            macro["selic_meta"] = values[-1]
    except Exception as exc:
        logger.warning("Falha ao buscar Selic no BCB/SGS: %s", exc)

    try:
        ipca = sgs.get(433, start=today - timedelta(days=400), end=today)
        if ipca is not None and not ipca.empty:
            numeric_column = ipca.select_dtypes(include="number").columns[0]
            recent = ipca.tail(12)
            macro["ipca_12m"] = [
                {"data": index.isoformat(), "valor": float(value)}
                for index, value in recent[numeric_column].items()
            ]
            current_year = ipca[ipca.index.year == today.year]
            macro["ipca_acumulado_ano"] = float(current_year[numeric_column].sum())
    except Exception as exc:
        logger.warning("Falha ao buscar IPCA no BCB/SGS: %s", exc)


def _fetch_ptax(macro: dict) -> None:
    if PTAX is None:
        raise RuntimeError("python-bcb nao esta instalado")
    try:
        today = datetime.now().date()
        start = today - timedelta(days=10)
        endpoint = PTAX().get_endpoint("CotacaoDolarPeriodo")
        frame = (
            endpoint.query()
            .parameters(
                dataInicial=start.strftime("%m/%d/%Y"),
                dataFinalCotacao=today.strftime("%m/%d/%Y"),
            )
            .collect()
        )
        if frame is not None and not frame.empty and "cotacaoCompra" in frame:
            macro["cambio_usd"] = float(frame["cotacaoCompra"].dropna().iloc[-1])
    except Exception as exc:
        logger.warning("Falha ao buscar PTAX USD/BRL: %s", exc)


def _fetch_focus(macro: dict) -> None:
    if Expectativas is None:
        raise RuntimeError("python-bcb nao esta instalado")

    mapping = {
        "IPCA": "ipca_ano_corrente",
        "Selic": "selic_ano_corrente",
        "Câmbio": "cambio_ano_corrente",
        "PIB Total": "pib_ano_corrente",
    }
    current_year = str(datetime.now().year)
    endpoint = Expectativas().get_endpoint("ExpectativasMercadoAnuais")
    for indicator, target in mapping.items():
        try:
            query = (
                endpoint.query()
                .filter(
                    endpoint.Indicador == indicator,
                    endpoint.DataReferencia == current_year,
                    endpoint.baseCalculo == 0,
                )
                .orderby(endpoint.Data.desc())
                .limit(1)
            )
            rows = query.collect()
            if rows is None or rows.empty:
                continue
            column = "Mediana" if "Mediana" in rows else "Media"
            macro["focus"][target] = float(rows[column].dropna().iloc[0])
        except Exception as exc:
            logger.warning("Falha ao buscar Focus %s: %s", indicator, exc)


def get_macro_context(force_refresh: bool = False) -> dict:
    """Return a best-effort serializable Brazilian macro snapshot."""
    now = time.time()
    if (
        not force_refresh
        and _cache["data"] is not None
        and now - float(_cache["timestamp"]) < _CACHE_TTL_SECONDS
    ):
        return _cache["data"]

    macro = _empty_macro()
    for name, collector in [
        ("SGS", _fetch_sgs),
        ("PTAX", _fetch_ptax),
        ("Focus", _fetch_focus),
    ]:
        try:
            collector(macro)
        except Exception as exc:
            logger.warning("Falha inesperada no coletor %s: %s", name, exc)
    macro["atualizado_em"] = datetime.now(timezone.utc).isoformat()
    _cache.update({"timestamp": now, "data": macro})
    return macro


def _format_number(value: Any, decimals: int = 2) -> str:
    return f"{float(value):.{decimals}f}".replace(".", ",")


def format_macro_for_prompt(macro: dict | None) -> str:
    """Format macro context as a concise LLM prompt block."""
    if not macro:
        return ""
    parts = ["Macro BR"]
    if macro.get("selic_meta") is not None:
        parts.append(f"Selic: {_format_number(macro['selic_meta'])}% a.a.")
    ipca_values = macro.get("ipca_12m") or []
    if ipca_values:
        total = sum(float(item["valor"]) for item in ipca_values)
        parts.append(f"IPCA 12m: {_format_number(total)}%")
    if macro.get("cambio_usd") is not None:
        parts.append(f"USD/BRL: {_format_number(macro['cambio_usd'])}")
    focus_ipca = (macro.get("focus") or {}).get("ipca_ano_corrente")
    if focus_ipca is not None:
        parts.append(f"Focus IPCA: {_format_number(focus_ipca)}%")
    return " | ".join(parts) if len(parts) > 1 else ""
