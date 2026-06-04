import asyncio
import unittest
from unittest.mock import patch

import api_server


class FakeTicker:
    def get_news(self, count):
        return []


class FakeSearch:
    def __init__(self, **kwargs):
        self.news = [
            {
                "content": {
                    "title": "Fed mantem juros",
                    "summary": "Mercado avalia a decisao.",
                    "provider": {"displayName": "Fonte Teste"},
                    "canonicalUrl": {"url": "https://example.com/news"},
                    "pubDate": "2026-06-04T12:00:00Z",
                }
            }
        ]


class NewsEndpointTest(unittest.TestCase):
    def setUp(self):
        api_server.news_cache.clear()

    def test_returns_structured_agent_news(self):
        with patch.object(api_server, "YFINANCE_AVAILABLE", True), patch.object(
            api_server.yf, "Ticker", return_value=FakeTicker()
        ), patch.object(api_server.yf, "Search", FakeSearch):
            response = asyncio.run(api_server.get_news(limit=5))

        article = response["articles"][0]
        self.assertEqual(article["title"], "Fed mantem juros")
        self.assertEqual(article["source"], "Fonte Teste")
        self.assertEqual(response["refresh_seconds"], 30)

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
