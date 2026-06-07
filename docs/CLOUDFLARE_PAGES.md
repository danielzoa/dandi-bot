# Cloudflare Pages deploy

This project deploys to Cloudflare Pages as a static Flutter Web app. The
Python/FastAPI backend is still deployed separately.

## Cloudflare Pages settings

- Build command: `bash scripts/build_cloudflare_pages.sh`
- Build output directory: `build/web`
- Current Pages URL: `https://dandi-bot.pages.dev`
- Environment variable:
  - `DANDI_BACKEND_URL`: public HTTPS URL of the FastAPI backend, for example
    `https://api.dandibot.com`

The repository also includes `wrangler.toml` for CLI-based Pages deploys.

## What Cloudflare Pages hosts

- Flutter Web static assets from `build/web`
- SPA fallback through `web/_redirects`
- Basic security/cache headers through `web/_headers`
- News endpoint through `functions/api/news.js`
- TradingView proxy through `functions/api/tradingview/[[path]].js`

## What stays outside Pages

Cloudflare Pages does not run the current `api_server.py` FastAPI process.
Deploy it to a Python host such as Render, Railway, Fly.io, Cloud Run, or a VPS.

## Backend deploy

The repository includes backend deployment files:

- `backend_requirements.txt`: FastAPI runtime plus TradingAgents from GitHub
- `render.yaml`: Render Blueprint for `dandi-bot-api`
- `Procfile`: generic Python web process for platforms that support it

Render settings if creating the service manually:

```txt
Runtime: Python
Build command: pip install -r backend_requirements.txt
Start command: uvicorn api_server:app --host 0.0.0.0 --port $PORT
Health check path: /api/health
```

Set `DANDI_CORS_ORIGINS` on the backend host to the final frontend origins:

```txt
https://your-project.pages.dev,https://dandibot.com
```

For the current Cloudflare Pages deployment, use:

```txt
https://dandi-bot.pages.dev
```

The backend also accepts Cloudflare Pages preview domains through an origin
regex for `*.pages.dev`.

## Local production build

```bash
DANDI_BACKEND_URL=https://api.dandibot.com bash scripts/build_cloudflare_pages.sh
```

On Windows PowerShell with local Flutter installed, use:

```powershell
$env:DANDI_BACKEND_URL='https://api.dandibot.com'
flutter build web --release --dart-define=DANDI_BACKEND_URL=$env:DANDI_BACKEND_URL
```
