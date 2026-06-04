import asyncio
import time
import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import brazil_macro_service
import brazil_news_service
import brapi_fundamentals_service


class BrazilMacroServiceTest(unittest.TestCase):
    def setUp(self):
        brazil_macro_service._cache.update({"timestamp": 0.0, "data": None})

    def test_get_macro_context_returns_dict_on_success(self):
        def fill_sgs(macro):
            macro["selic_meta"] = 14.75

        with patch.object(brazil_macro_service, "_fetch_sgs", fill_sgs), patch.object(
            brazil_macro_service, "_fetch_ptax"
        ), patch.object(brazil_macro_service, "_fetch_focus"):
            result = brazil_macro_service.get_macro_context(force_refresh=True)

        self.assertEqual(result["selic_meta"], 14.75)
        self.assertEqual(result["fonte"], "BCB/SGS + Expectativas")

    def test_get_macro_context_returns_partial_on_bcb_failure(self):
        with patch.object(
            brazil_macro_service, "_fetch_sgs", side_effect=Exception("BCB offline")
        ), patch.object(brazil_macro_service, "_fetch_ptax"), patch.object(
            brazil_macro_service, "_fetch_focus"
        ):
            result = brazil_macro_service.get_macro_context(force_refresh=True)
        self.assertIsInstance(result, dict)
        self.assertIsNone(result["selic_meta"])

    def test_format_macro_for_prompt_returns_empty_string_on_none(self):
        self.assertEqual(brazil_macro_service.format_macro_for_prompt(None), "")

    def test_cache_prevents_double_fetch(self):
        with patch.object(brazil_macro_service, "_fetch_sgs") as fetch, patch.object(
            brazil_macro_service, "_fetch_ptax"
        ), patch.object(brazil_macro_service, "_fetch_focus"), patch.object(
            brazil_macro_service.time, "time", side_effect=[100.0, 101.0]
        ):
            brazil_macro_service.get_macro_context(force_refresh=True)
            brazil_macro_service.get_macro_context()
        self.assertEqual(fetch.call_count, 1)


class FakeResponse:
    def __init__(self, content=b"<rss/>", status_error=None, json_data=None):
        self.content = content
        self._status_error = status_error
        self._json_data = json_data or {}

    def raise_for_status(self):
        if self._status_error:
            raise self._status_error

    def json(self):
        return self._json_data


class FakeFeedClient:
    def __init__(self, response):
        self.response = response

    async def get(self, *args, **kwargs):
        return self.response


class BrazilNewsServiceTest(unittest.TestCase):
    def _entry(self, *, hours=1, url="https://example.com/1", dated=True):
        published = datetime.now(timezone.utc) - timedelta(hours=hours)
        return {
            "title": "Noticia",
            "link": url,
            "summary": "Resumo",
            "published_parsed": published.timetuple() if dated else None,
        }

    def test_fetch_brazil_news_returns_list(self):
        article = {
            "title": "Hoje",
            "summary": "",
            "url": "https://example.com/1",
            "source": "Fonte",
            "published_at": datetime.now(timezone.utc).isoformat(),
            "category": "economia",
            "brazil": True,
        }
        with patch.object(
            brazil_news_service, "_fetch_feed", new=AsyncMock(return_value=[article])
        ):
            result = asyncio.run(brazil_news_service.fetch_brazil_news())
        self.assertIsInstance(result, list)
        self.assertTrue(result[0]["brazil"])

    def test_fetch_brazil_news_rejects_old_articles(self):
        parsed = SimpleNamespace(entries=[self._entry(hours=80)])
        with patch.object(
            brazil_news_service, "feedparser", SimpleNamespace(parse=lambda _: parsed)
        ):
            result = asyncio.run(
                brazil_news_service._fetch_feed(
                    FakeFeedClient(FakeResponse()),
                    brazil_news_service.BRAZIL_RSS_FEEDS[0],
                    5,
                )
            )
        self.assertEqual(result, [])

    def test_fetch_brazil_news_rejects_undated_articles(self):
        parsed = SimpleNamespace(entries=[self._entry(dated=False)])
        with patch.object(
            brazil_news_service, "feedparser", SimpleNamespace(parse=lambda _: parsed)
        ):
            result = asyncio.run(
                brazil_news_service._fetch_feed(
                    FakeFeedClient(FakeResponse()),
                    brazil_news_service.BRAZIL_RSS_FEEDS[0],
                    5,
                )
            )
        self.assertEqual(result, [])

    def test_fetch_brazil_news_deduplicates_by_url(self):
        article = {
            "title": "Hoje",
            "summary": "",
            "url": "https://example.com/same",
            "source": "Fonte",
            "published_at": datetime.now(timezone.utc).isoformat(),
            "category": "economia",
            "brazil": True,
        }
        with patch.object(
            brazil_news_service,
            "_fetch_feed",
            new=AsyncMock(return_value=[article, article]),
        ):
            result = asyncio.run(brazil_news_service.fetch_brazil_news())
        self.assertEqual(len(result), 1)

    def test_individual_feed_failure_does_not_raise(self):
        result = asyncio.run(
            brazil_news_service._fetch_feed(
                FakeFeedClient(FakeResponse(status_error=RuntimeError("offline"))),
                brazil_news_service.BRAZIL_RSS_FEEDS[0],
                5,
            )
        )
        self.assertEqual(result, [])


class BrapiFundamentalsServiceTest(unittest.TestCase):
    def test_is_brazilian_ticker_true_for_sa_suffix(self):
        self.assertTrue(brapi_fundamentals_service.is_brazilian_ticker("PETR4.SA"))

    def test_is_brazilian_ticker_true_for_b3_format(self):
        self.assertTrue(brapi_fundamentals_service.is_brazilian_ticker("VALE3"))

    def test_is_brazilian_ticker_false_for_aapl(self):
        self.assertFalse(brapi_fundamentals_service.is_brazilian_ticker("AAPL"))

    def test_get_brapi_fundamentals_returns_none_on_http_error(self):
        client = AsyncMock()
        client.__aenter__.return_value.get.side_effect = RuntimeError("offline")
        with patch.object(brapi_fundamentals_service.httpx, "AsyncClient", return_value=client):
            result = asyncio.run(
                brapi_fundamentals_service.get_brapi_fundamentals("PETR4")
            )
        self.assertIsNone(result)

    def test_format_fundamentals_for_prompt_returns_empty_on_none(self):
        self.assertEqual(
            brapi_fundamentals_service.format_fundamentals_for_prompt(None), ""
        )


if __name__ == "__main__":
    unittest.main()
