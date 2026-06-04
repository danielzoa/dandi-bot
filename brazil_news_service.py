"""Recent Brazilian economy news from public RSS feeds."""

from __future__ import annotations

import asyncio
import calendar
import logging
from datetime import datetime, timedelta, timezone
from typing import Any

import httpx

try:
    import feedparser
except ImportError:
    feedparser = None


logger = logging.getLogger(__name__)
BRAZIL_RSS_FEEDS = [
    {
        "url": "https://feeds.valor.com.br/rss/mercados",
        "source": "Valor Economico",
        "category": "mercados",
    },
    {
        "url": "https://www.infomoney.com.br/feed/",
        "source": "InfoMoney",
        "category": "mercados",
    },
    {
        "url": "https://br.reuters.com/rssFeed/businessNews",
        "source": "Reuters Brasil",
        "category": "economia",
    },
    {
        "url": "https://agenciabrasil.ebc.com.br/rss/economia/feed.xml",
        "source": "Agencia Brasil",
        "category": "economia",
    },
]


def _published_at(entry: Any) -> datetime | None:
    parsed = entry.get("published_parsed") or entry.get("updated_parsed")
    if parsed is None:
        return None
    try:
        return datetime.fromtimestamp(calendar.timegm(parsed), tz=timezone.utc)
    except (TypeError, ValueError, OverflowError):
        return None


async def _fetch_feed(
    client: httpx.AsyncClient, feed: dict, max_per_feed: int
) -> list[dict]:
    if feedparser is None:
        logger.warning("feedparser nao esta instalado")
        return []
    try:
        response = await client.get(feed["url"], timeout=5.0)
        response.raise_for_status()
        parsed = await asyncio.to_thread(feedparser.parse, response.content)
    except Exception as exc:
        logger.warning("Falha ao buscar RSS %s: %s", feed["source"], exc)
        return []

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=72)
    articles = []
    for entry in parsed.entries:
        published = _published_at(entry)
        if published is None or not cutoff <= published <= now + timedelta(hours=2):
            continue
        url = str(entry.get("link", "")).strip()
        if not url:
            continue
        articles.append(
            {
                "title": str(entry.get("title", "Sem titulo")).strip(),
                "summary": str(entry.get("summary", "")).strip(),
                "url": url,
                "source": feed["source"],
                "published_at": published.isoformat(),
                "category": feed["category"],
                "brazil": True,
            }
        )
        if len(articles) >= max_per_feed:
            break
    return articles


async def fetch_brazil_news(max_per_feed: int = 5) -> list[dict]:
    """Fetch, validate, deduplicate, and sort recent Brazilian RSS news."""
    async with httpx.AsyncClient(follow_redirects=True) as client:
        results = await asyncio.gather(
            *(_fetch_feed(client, feed, max_per_feed) for feed in BRAZIL_RSS_FEEDS)
        )

    deduped: dict[str, dict] = {}
    for article in (item for result in results for item in result):
        deduped.setdefault(article["url"], article)
    return sorted(
        deduped.values(),
        key=lambda article: article["published_at"],
        reverse=True,
    )
