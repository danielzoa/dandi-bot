const TRADINGVIEW_ORIGIN = 'https://scanner.tradingview.com';

export async function onRequest(context) {
  const { request, params } = context;

  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders() });
  }

  if (request.method !== 'GET' && request.method !== 'POST') {
    return new Response('Method not allowed', {
      status: 405,
      headers: corsHeaders({ Allow: 'GET, POST, OPTIONS' }),
    });
  }

  const path = Array.isArray(params.path)
    ? params.path.join('/')
    : params.path || '';
  const incomingUrl = new URL(request.url);
  const targetUrl = new URL(`/${path}${incomingUrl.search}`, TRADINGVIEW_ORIGIN);

  const upstreamHeaders = new Headers(request.headers);
  upstreamHeaders.set('Origin', 'https://www.tradingview.com');
  upstreamHeaders.set('Referer', 'https://www.tradingview.com/');

  const upstreamResponse = await fetch(targetUrl.toString(), {
    method: request.method,
    headers: upstreamHeaders,
    body: request.method === 'GET' ? undefined : await request.arrayBuffer(),
  });

  const responseHeaders = new Headers(upstreamResponse.headers);
  for (const [key, value] of Object.entries(corsHeaders())) {
    responseHeaders.set(key, value);
  }

  return new Response(upstreamResponse.body, {
    status: upstreamResponse.status,
    statusText: upstreamResponse.statusText,
    headers: responseHeaders,
  });
}

function corsHeaders(extra = {}) {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    ...extra,
  };
}
