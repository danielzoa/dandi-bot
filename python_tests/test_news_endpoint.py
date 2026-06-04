import asyncio
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch

import api_server


class FakeTicker:
    def get_news(self, count):
        return []


class FakeSearch:
    def __init__(self, **kwargs):
        published_at = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
        self.news = [
            {
                "content": {
                    "title": "Fed mantem juros",
                    "summary": "Mercado avalia a decisao.",
                    "provider": {"displayName": "Fonte Teste"},
                    "canonicalUrl": {"url": "https://example.com/news"},
                    "pubDate": published_at,
                }
            }
        ]


class NewsEndpointTest(unittest.TestCase):
    def setUp(self):
        api_server.news_cache.clear()
        self.brazil_news_patcher = patch.object(
            api_server, "fetch_brazil_news", new=AsyncMock(return_value=[])
        )
        self.brazil_news_patcher.start()

    def tearDown(self):
        self.brazil_news_patcher.stop()

    def test_returns_structured_agent_news(self):
        with patch.object(api_server, "YFINANCE_AVAILABLE", True), patch.object(
            api_server.yf, "Ticker", return_value=FakeTicker()
        ), patch.object(api_server.yf, "Search", FakeSearch):
            response = asyncio.run(api_server.get_news(limit=5))

        article = response["articles"][0]
        self.assertEqual(article["title"], "Fed mantem juros")
        self.assertEqual(article["source"], "Fonte Teste")
        self.assertEqual(response["refresh_seconds"], 30)
        self.assertEqual(response["today_count"], 1)

    def test_excludes_old_news(self):
        class OldSearch:
            def __init__(self, **kwargs):
                self.news = [
                    {
                        "content": {
                            "title": "Noticia antiga",
                            "provider": {"displayName": "Fonte Teste"},
                            "pubDate": (
                                datetime.now(timezone.utc) - timedelta(days=30)
                            ).isoformat(),
                        }
                    }
                ]

        with patch.object(api_server, "YFINANCE_AVAILABLE", True), patch.object(
            api_server.yf, "Ticker", return_value=FakeTicker()
        ), patch.object(api_server.yf, "Search", OldSearch):
            response = asyncio.run(api_server.get_news(limit=5))

        self.assertEqual(response["articles"], [])

    def test_orders_newest_news_first(self):
        now = datetime.now(timezone.utc)

        class UnsortedSearch:
            def __init__(self, **kwargs):
                self.news = [
                    {
                        "content": {
                            "title": "Noticia anterior",
                            "provider": {"displayName": "Fonte Teste"},
                            "pubDate": (now - timedelta(hours=5)).isoformat(),
                        }
                    },
                    {
                        "content": {
                            "title": "Noticia mais nova",
                            "provider": {"displayName": "Fonte Teste"},
                            "pubDate": (now - timedelta(minutes=10)).isoformat(),
                        }
                    },
                ]

        with patch.object(api_server, "YFINANCE_AVAILABLE", True), patch.object(
            api_server.yf, "Ticker", return_value=FakeTicker()
        ), patch.object(api_server.yf, "Search", UnsortedSearch):
            response = asyncio.run(api_server.get_news(limit=5))

        self.assertEqual(response["articles"][0]["title"], "Noticia mais nova")

    def test_normalizes_flat_yfinance_article(self):
        article = api_server._news_article_data(
            {
                "title": "Mercados sobem",
                "publisher": "Fonte Flat",
                "link": "https://example.com/flat",
            },
            "mercados",
        )

        self.assertEqual(article["source"], "Fonte Flat")
        self.assertEqual(article["url"], "https://example.com/flat")


if __name__ == "__main__":
    unittest.main()
