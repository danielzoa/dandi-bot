const DEFAULT_LIMIT = 16;
const RSS_FEEDS = [
  {
    name: 'G1 Economia',
    url: 'https://g1.globo.com/rss/g1/economia/',
  },
  {
    name: 'InfoMoney',
    url: 'https://www.infomoney.com.br/feed/',
  },
  {
    name: 'Money Times',
    url: 'https://www.moneytimes.com.br/feed/',
  },
];

export async function onRequestGet({ request }) {
  const url = new URL(request.url);
  const ticker = (url.searchParams.get('ticker') || '').trim().toUpperCase();
  const limit = clamp(Number(url.searchParams.get('limit')) || DEFAULT_LIMIT, 1, 30);

  try {
    const feedResults = await Promise.allSettled(RSS_FEEDS.map(fetchFeed));
    const feedErrors = [];
    const allArticles = [];
    for (const result of feedResults) {
      if (result.status === 'fulfilled') {
        allArticles.push(...result.value);
      } else {
        feedErrors.push(result.reason instanceof Error ? result.reason.message : String(result.reason));
      }
    }

    if (!allArticles.length) {
      throw new Error(feedErrors.join('; ') || 'All RSS feeds failed');
    }

    const rankedArticles = rankArticles(dedupeArticles(allArticles), ticker);
    const articles = rankedArticles
      .filter((article) => article.title && article.url)
      .slice(0, limit)
      .map((article) => ({
        ...article,
        category: classify(article.title, article.summary),
        agent_name: agentFor(article.title, article.summary),
      }));

    return jsonResponse({
      articles,
      ticker: ticker || null,
      updated_at: new Date().toISOString(),
      refresh_seconds: 300,
      lookback_hours: 72,
      today_count: articles.filter(isToday).length,
      source: 'G1 Economia, InfoMoney, Money Times',
      brazil_count: articles.length,
      stale: false,
      partial_errors: feedErrors,
    });
  } catch (error) {
    return jsonResponse(
      fallbackPayload(ticker, limit, error instanceof Error ? error.message : 'News fetch failed'),
      200,
    );
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: corsHeaders() });
}

async function fetchFeed(feed) {
  const response = await fetch(feed.url, {
    headers: {
      'User-Agent': 'DandiBot/1.0 (+https://dandi-bot.pages.dev)',
      Accept: 'application/rss+xml, application/xml, text/xml',
    },
    cf: { cacheTtl: 300, cacheEverything: true },
  });

  if (!response.ok) {
    throw new Error(`${feed.name} returned ${response.status}`);
  }

  const xml = await response.text();
  return parseRss(xml, feed.name);
}

function parseRss(xml, fallbackSource) {
  const items = [...xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)];
  return items.map((match) => {
    const item = match[1];
    const title = clean(readTag(item, 'title'));
    const source = clean(readTag(item, 'source')) || fallbackSource;
    const description = clean(stripHtml(readTag(item, 'description')));
    const pubDate = clean(readTag(item, 'pubDate'));
    return {
      title: stripSourceSuffix(title, source),
      summary: description || `Notícia de ${source} agregada pelo radar do Dandi Bot.`,
      source,
      url: clean(readTag(item, 'link')),
      published_at: pubDate ? new Date(pubDate).toISOString() : new Date().toISOString(),
    };
  });
}

function dedupeArticles(articles) {
  const seen = new Set();
  const deduped = [];
  for (const article of articles) {
    const key = normalize(article.url || article.title).replace(/[^a-z0-9]/g, '');
    if (seen.has(key)) continue;
    seen.add(key);
    deduped.push(article);
  }
  return deduped;
}

function rankArticles(articles, ticker) {
  const normalizedTicker = normalize(ticker.replace(/\.SA|-USD/g, ''));
  return [...articles].sort((a, b) => {
    const aScore = articleScore(a, normalizedTicker);
    const bScore = articleScore(b, normalizedTicker);
    if (aScore !== bScore) return bScore - aScore;
    return new Date(b.published_at).getTime() - new Date(a.published_at).getTime();
  });
}

function articleScore(article, ticker) {
  const text = normalize(`${article.title} ${article.summary}`);
  let score = 0;
  if (ticker && text.includes(ticker.toLowerCase())) score += 10;
  if (/(ibovespa|bolsa|b3|acoes|mercado|juros|selic|dolar|cambio|petroleo|minerio)/i.test(text)) {
    score += 3;
  }
  if (isToday(article)) score += 1;
  return score;
}

function readTag(xml, tag) {
  const match = xml.match(new RegExp(`<${tag}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${tag}>`, 'i'));
  return match ? decodeEntities(stripCdata(match[1])) : '';
}

function stripCdata(value) {
  return value.replace(/^<!\[CDATA\[/, '').replace(/\]\]>$/, '');
}

function stripHtml(value) {
  return value.replace(/<[^>]+>/g, ' ');
}

function clean(value) {
  return decodeEntities(value).replace(/\s+/g, ' ').trim();
}

function decodeEntities(value) {
  return value
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)));
}

function stripSourceSuffix(title, source) {
  const suffix = ` - ${source}`;
  return title.endsWith(suffix) ? title.slice(0, -suffix.length).trim() : title;
}

function classify(title, summary) {
  const text = normalize(`${title} ${summary}`);
  if (/(selic|banco central|inflacao|ipca|juros|fiscal|dolar|cambio)/i.test(text)) {
    return 'macro';
  }
  if (/(petroleo|minerio|commodit|soja|ouro|brent)/i.test(text)) {
    return 'commodities';
  }
  if (/(regulacao|governo|congresso|supremo|geopolitica|tarifa)/i.test(text)) {
    return 'geopolitica';
  }
  return 'mercados';
}

function normalize(value) {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

function agentFor(title, summary) {
  const category = classify(title, summary);
  return {
    macro: 'Analista Macroeconomico',
    commodities: 'Analista de Sentimento',
    geopolitica: 'Analista de Risco Regulatorio',
    mercados: 'Analista de Noticias',
  }[category];
}

function isToday(article) {
  const published = new Date(article.published_at);
  const now = new Date();
  return (
    published.getUTCFullYear() === now.getUTCFullYear() &&
    published.getUTCMonth() === now.getUTCMonth() &&
    published.getUTCDate() === now.getUTCDate()
  );
}

function fallbackPayload(ticker, limit, reason) {
  return {
    articles: [
      {
        title: 'Radar de noticias temporariamente indisponivel',
        summary: reason,
        source: 'Dandi Bot',
        url: '',
        published_at: new Date().toISOString(),
        category: 'mercados',
        agent_name: 'Analista de Noticias',
        fallback: true,
      },
    ].slice(0, limit),
    ticker: ticker || null,
    updated_at: new Date().toISOString(),
    refresh_seconds: 120,
    lookback_hours: 72,
    today_count: 0,
    source: 'Cloudflare Pages Function',
    brazil_count: 0,
    stale: true,
    fallback_reason: reason,
  };
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders(),
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=120',
    },
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}
