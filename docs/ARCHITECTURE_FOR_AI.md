# Dandi Bot Architecture Guide for AI Assistants

## Purpose

Dandi Bot is a Flutter investment education application with:

- Windows, Web, and Android clients.
- Local simulated behavior and resilient fallbacks.
- A FastAPI backend.
- A lightweight financial chat graph.
- A full TradingAgents multi-agent analysis framework.

The application is educational and simulated. It must not present content as
investment advice.

## Repository Map

```text
lib/                         Flutter application
  app.dart                   Routes and MaterialApp
  main.dart                  Startup and crash logging
  models/                    Domain models
  screens/                   User-facing screens
  services/                  State, APIs, storage, market data
  widgets/                   Shared UI components
  mock/                      Offline fallback data
  theme/                     Colors and typography
  utils/                     Ticker and market helpers

api_server.py                FastAPI bridge
financial_chat_graph.py      Lightweight Gemini LangGraph chat
TradingAgents/               Full multi-agent framework and Python runtime
python_tests/                Backend tests
test/                        Flutter tests
docs/                        Project documentation
```

## High-Level Architecture

```text
Flutter UI
  -> DandiScope / AppController
      -> LocalStorageService
      -> MarketQuoteService / MarketCatalogService
      -> MockAnalysisService / GeminiApiService
      -> MockChatService
          -> TradingAgentsApiService
              -> FastAPI
                  -> FinancialChatGraph
                  -> TradingAgentsGraph
                  -> Yahoo Finance news
```

## Flutter Entry Points

### `lib/main.dart`

- Initializes Flutter and Portuguese date formatting.
- Creates and initializes `AppController`.
- Starts `DandiApp`.
- Writes uncaught desktop errors to a local crash log.

### `lib/app.dart`

- Defines all route constants.
- Configures `GoRouter`.
- Wraps every screen with `AppShell`.
- Provides `AppController` through `DandiScope`.

Important routes:

```text
/                 Home
/markets          Market showcases
/markets/catalog  Complete market catalog, selected by `market` query parameter
/analysis         Asset analysis
/agents           Agent debate
/portfolio        Simulated portfolio
/history          Analysis history
/chat             Financial chat
/news             Recent market news
/settings         User settings
```

## State Management

### `lib/services/app_controller.dart`

`AppController` is the central Flutter state and orchestration layer. It extends
`ChangeNotifier`.

It owns:

- Analysis history and selected analysis.
- Portfolio items.
- Chat messages.
- User settings.
- Live and catalog asset caches.
- News articles.
- Loading and backend health states.
- Service instances.

UI obtains the controller with:

```dart
final controller = DandiScope.of(context);
```

After changing public state, call `notifyListeners()`.

Do not introduce a second global state system without a strong reason.

## Flutter Service Responsibilities

### `TradingAgentsApiService`

File: `lib/services/trading_agents_api_service.dart`

HTTP client for FastAPI. Supports:

- Health checks.
- Chat requests.
- Starting and polling analysis jobs.
- News requests.
- Provider and diagnostics requests.

Default backend URL:

```text
http://127.0.0.1:8000
```

### `MockChatService`

File: `lib/services/mock_chat_service.dart`

Chat fallback chain:

1. FastAPI / TradingAgents backend.
2. Direct Gemini API when an API key is available.
3. Local mock gateway.

Despite its name, this is the active chat orchestration service.

### `MockAnalysisService`

File: `lib/services/mock_analysis_service.dart`

Analysis fallback chain:

1. Direct structured Gemini analysis when an API key is available.
2. Local `MockAnalyses` fallback.

The standard Flutter analysis screen currently uses this service. The complete
TradingAgents pipeline is mainly triggered through the backend/chat flow.

### `MarketQuoteService`

File: `lib/services/market_quote_service.dart`

Quote fallback order:

1. TradingView.
2. CoinGecko for crypto.
3. Configured Investing.com proxy.
4. Brapi.
5. Yahoo Finance.

Returns the original asset unchanged when all live providers fail.

### `MarketCatalogService`

File: `lib/services/market_catalog_service.dart`

- Loads paginated market catalogs from TradingView Scanner.
- Supports Brazil, USA, and crypto.
- The catalog screen provides known local assets as a fallback.

### `LocalStorageService`

File: `lib/services/local_storage_service.dart`

Persists:

- Analysis history.
- Portfolio.
- Chat history.
- User settings.

Storage implementations:

- Desktop: JSON file under the user application data directory.
- Web: browser `localStorage`.

## Main Flutter Screens

| Screen | File | Responsibility |
|---|---|---|
| Home | `lib/screens/home/home_screen.dart` | Search, featured assets, quick actions, news strip |
| Markets | `lib/screens/markets/markets_screen.dart` | Market showcases |
| Catalog | `lib/screens/markets/market_catalog_screen.dart` | Complete market listing and search |
| Analysis | `lib/screens/analysis/analysis_screen.dart` | Summary, indicators, charts, full analysis |
| Agents | `lib/screens/agents/agents_debate_screen.dart` | Individual agent opinions |
| Chat | `lib/screens/chat/chat_screen.dart` | Financial conversation |
| News | `lib/screens/news/news_screen.dart` | Recent categorized news |
| Portfolio | `lib/screens/portfolio/portfolio_screen.dart` | Simulated positions |
| History | `lib/screens/history/history_screen.dart` | Previous analyses |
| Settings | `lib/screens/settings/settings_screen.dart` | API keys, backend, preferences |

## FastAPI Backend

### `api_server.py`

FastAPI acts as a bridge between Flutter and Python AI workflows.

Main endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/health` | Backend health |
| GET | `/api/news` | Structured recent news |
| POST | `/api/analyze` | Start TradingAgents job |
| GET | `/api/status/{job_id}` | Poll a job |
| GET | `/api/stream/{job_id}` | Stream job events with SSE |
| POST | `/api/chat` | Parse ticker and start TradingAgents analysis |
| POST | `/api/v1/chat` | Lightweight financial LangGraph chat |
| GET | `/api/providers` | Supported LLM providers |
| GET | `/api/diagnostics` | Environment diagnostics |
| GET | `/api/jobs` | Recent in-memory jobs |

Backend state is currently in memory:

- Analysis jobs.
- SSE subscriber queues.
- Financial chat session histories.
- News cache.

Restarting the backend clears this state.

`SETUP_BACKEND.bat` copies the root `api_server.py` into `TradingAgents/`.
When backend code changes, keep the runtime copy synchronized.

## AI Workflows

### Lightweight Financial Chat

File: `financial_chat_graph.py`

Graph:

```text
User input
  -> Gatekeeper
  -> Fundamental analyst
  -> Technical analyst
  -> Sentiment analyst
  -> Synthesis
  -> Final response
```

The gatekeeper rejects requests outside financial markets. The graph uses
Gemini and keeps recent conversation history per session.

### Full TradingAgents Analysis

Main file:

```text
TradingAgents/tradingagents/graph/trading_graph.py
```

Typical pipeline:

```text
Market / News / Sentiment / Fundamentals analysts
  -> Bull and Bear researcher debate
  -> Research manager
  -> Trader plan
  -> Aggressive / Conservative / Neutral risk debate
  -> Risk manager
  -> Final trade decision
```

TradingAgents supports:

- Multiple LLM providers.
- Tool-based data collection.
- Memory of previous decisions.
- Reflection on later outcomes.
- Optional SQLite checkpoints.
- Structured execution and debate state.

## News Architecture

News endpoint:

```text
GET /api/news
```

Current behavior:

- Uses Yahoo Finance search.
- Queries macroeconomics, markets, geopolitics, and commodities.
- Prioritizes news from the last 24 hours.
- Rejects news older than 72 hours.
- Rejects articles without a verifiable publication time.
- Sorts newest articles first.
- Caches responses briefly.

Flutter:

- Refreshes news every 30 seconds from `AppShell`.
- Stores results in `AppController.newsArticles`.
- Displays a subtle Home strip and categorized News screen.
- Opens original article URLs with `url_launcher`.

## Core Domain Models

Important files under `lib/models/`:

| Model | Purpose |
|---|---|
| `Asset` | Ticker, market, price, source, identifiers |
| `AnalysisResult` | Shared analysis contract |
| `StockAnalysis` | Stock-specific analysis |
| `CryptoAnalysis` | Crypto-specific analysis |
| `AgentOpinion` | Individual agent output |
| `ChatMessage` | Chat history item |
| `NewsArticle` | Structured news item |
| `PortfolioItem` | Simulated position |
| `UserSettings` | User and backend preferences |

## Resilience and Fallback Rules

Preserve these behaviors:

- External market providers may fail independently.
- Market data should fall back without crashing the app.
- Chat should fall back from backend to Gemini to mock responses.
- Analysis should fall back from Gemini to local mock analysis.
- Market catalog should show known assets if TradingView fails.
- News must not present old or undated articles as current.
- User-facing financial content must remain educational.

## Development and Validation

Flutter static analysis:

```powershell
& 'C:\flutter_windows_3.44.0-stable\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze lib
```

Flutter tests:

```powershell
& 'C:\flutter_windows_3.44.0-stable\flutter\bin\flutter.bat' test
```

Python tests:

```powershell
& '.\TradingAgents\venv\Scripts\python.exe' -m unittest discover -s python_tests
```

Start backend:

```powershell
& '.\TradingAgents\venv\Scripts\python.exe' -m uvicorn api_server:app --host 127.0.0.1 --port 8000
```

## Important Caveats

- `TradingAgents/` is ignored by the parent repository and has its own upstream
  codebase. Changes there are not included in normal parent-repository commits.
- The root `api_server.py` is the tracked source of truth for the Dandi bridge.
- Some existing source files contain legacy text encoding artifacts.
- `AppController` is large and owns many responsibilities; changes to it can
  affect most screens.
- Do not remove mock fallbacks unless the application is intentionally being
  converted to require online services.
- Avoid presenting live-data claims unless the provider and timestamp are known.

## Quick Task Routing

When modifying:

- Navigation: inspect `lib/app.dart`, `AppShell`, `SideNav`, and `BottomNav`.
- Global state: inspect `AppController` and `DandiScope`.
- Chat behavior: inspect `MockChatService`, `TradingAgentsApiService`,
  `api_server.py`, and `financial_chat_graph.py`.
- Standard asset analysis: inspect `MockAnalysisService` and analysis models.
- Full agent analysis: inspect `api_server.py` and `TradingAgentsGraph`.
- Market quotes: inspect `MarketQuoteService` and `MarketDataSymbols`.
- Catalog behavior: inspect `MarketCatalogService` and `MarketCatalogScreen`.
- News: inspect `api_server.py`, `NewsArticle`, `NewsScreen`, and `NewsStrip`.
- Persistence: inspect `LocalStorageService` and platform storage backends.
