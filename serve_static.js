const fs = require('fs');
const http = require('http');
const path = require('path');

const port = Number(process.env.PORT || 4173);
const host = process.env.HOST || '127.0.0.1';
const root = path.resolve(__dirname, 'build', 'web');
const accessLog = path.resolve(__dirname, 'server_access.log');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
};

const server = http.createServer((request, response) => {
  const url = new URL(request.url, `http://${host}:${port}`);

  if (url.pathname.startsWith('/api/tradingview/')) {
    proxyTradingView(request, response, url);
    return;
  }

  let filePath = path.resolve(root, `.${decodeURIComponent(url.pathname)}`);

  if (!filePath.startsWith(root)) {
    response.writeHead(403);
    response.end('Forbidden');
    return;
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }

  if (!fs.existsSync(filePath)) {
    filePath = path.join(root, 'index.html');
  }

  response.setHeader(
    'Content-Type',
    types[path.extname(filePath)] || 'application/octet-stream',
  );

  fs.createReadStream(filePath)
    .on('error', () => {
      response.writeHead(500);
      response.end('Server error');
    })
    .pipe(response);
});

server.listen(port, host);

function proxyTradingView(request, response, url) {
  const scannerPath = url.pathname.replace('/api/tradingview', '');
  const target = `https://scanner.tradingview.com${scannerPath}`;
  let body = '';

  request.on('data', (chunk) => {
    body += chunk;
  });

  request.on('end', async () => {
    try {
      const upstream = await fetch(target, {
        method: request.method,
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: request.method === 'GET' || request.method === 'HEAD'
          ? undefined
          : body,
      });
      const text = await upstream.text();
      logAccess(`${request.method} ${url.pathname} -> ${upstream.status}`);
      response.writeHead(upstream.status, {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': upstream.headers.get('content-type') || 'application/json',
      });
      response.end(text);
    } catch (error) {
      logAccess(`${request.method} ${url.pathname} -> 502 ${String(error)}`);
      response.writeHead(502, {'Content-Type': 'application/json'});
      response.end(JSON.stringify({error: String(error)}));
    }
  });
}

function logAccess(line) {
  fs.appendFile(accessLog, `${new Date().toISOString()} ${line}\n`, () => {});
}
