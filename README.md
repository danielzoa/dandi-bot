# 🤖 DanDi Bot — AI Trading Assistant

> Assistente de investimentos inteligente com múltiplos agentes de IA para análise de ações, criptomoedas e mercados globais.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![TradingAgents](https://img.shields.io/badge/TradingAgents-FF6B35?style=for-the-badge)

## 📋 Visão Geral

O DanDi Bot é uma aplicação desktop/web construída com **Flutter** que se conecta ao framework **TradingAgents** (multi-agent LLM) para fornecer análises de trading em tempo real.

### Arquitetura

```
┌─────────────────────────────────────────────────┐
│              Flutter Frontend                    │
│  (Desktop Windows / Web)                        │
│                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │  Chat    │ │ Markets  │ │  Portfolio       │ │
│  │  Screen  │ │ Explorer │ │  Manager         │ │
│  └────┬─────┘ └──────────┘ └──────────────────┘ │
│       │                                          │
│  ┌────▼──────────────────────────────────────┐  │
│  │  TradingAgentsApiService (HTTP client)    │  │
│  │  → health / chat / analyze / poll         │  │
│  └────┬──────────────────────────────────────┘  │
└───────┼──────────────────────────────────────────┘
        │ HTTP :8000
┌───────▼──────────────────────────────────────────┐
│            api_server.py (FastAPI)                │
│                                                   │
│  /api/health    → status do servidor              │
│  /api/chat      → parse ticker + dispara análise  │
│  /api/analyze   → análise direta por ticker/data  │
│  /api/status    → polling de job                  │
│  /api/stream    → SSE em tempo real               │
│  /api/providers → LLMs disponíveis                │
│  /api/diagnostics → diagnóstico completo          │
└───────┬──────────────────────────────────────────┘
        │
┌───────▼──────────────────────────────────────────┐
│         TradingAgents Framework                   │
│  (github.com/TauricResearch/TradingAgents)       │
│                                                   │
│  Analysts: Market, News, Fundamentals, Sentiment │
│  Researchers: Bull, Bear                          │
│  Managers: Research, Portfolio                    │
│  Risk: Aggressive, Conservative, Neutral Debator │
│  Trader: Final decision maker                     │
└──────────────────────────────────────────────────┘
```

## 🚀 Setup Rápido

### Pré-requisitos

- **Flutter SDK** ≥ 3.x
- **Python** ≥ 3.10
- **Git**
- Uma API key de LLM (OpenAI, Google Gemini, Anthropic, etc.)

### 1. Clone o repositório

```bash
git clone https://github.com/SEU_USUARIO/dandi-bot.git
cd dandi-bot
```

### 2. Setup do Backend

```bash
# Clone TradingAgents dentro do projeto
git clone https://github.com/TauricResearch/TradingAgents.git

# Crie o venv e instale dependências
cd TradingAgents
python -m venv venv
.\venv\Scripts\activate   # Windows
pip install . fastapi "uvicorn[standard]"

# Configure sua API key
cp .env.example .env
# Edite .env e adicione sua chave (ex: GOOGLE_API_KEY=sua_chave_aqui)

# Copie o servidor API
copy ..\api_server.py .

# Inicie o backend
uvicorn api_server:app --reload --port 8000
```

Ou use o script automatizado:
```bash
SETUP_BACKEND.bat
```

### 3. Setup do Frontend (Flutter)

```bash
# Na raiz do projeto
flutter pub get
flutter run -d windows    # Desktop
flutter run -d chrome      # Web
```

### 4. Build para distribuição

```bash
# Windows Desktop
flutter build windows --release

# Web
flutter build web --release
```

## 🔑 Configuração de API Keys

Edite o arquivo `TradingAgents/.env`:

| Provider | Variável | Modelos |
|----------|----------|---------|
| OpenAI | `OPENAI_API_KEY` | gpt-4o, gpt-4o-mini |
| Google | `GOOGLE_API_KEY` | gemini-2.5-pro, gemini-2.0-flash |
| Anthropic | `ANTHROPIC_API_KEY` | claude-sonnet-4-6, claude-haiku-4-5 |
| DeepSeek | `DEEPSEEK_API_KEY` | deepseek-reasoner, deepseek-chat |
| xAI | `XAI_API_KEY` | grok-3, grok-3-mini |
| OpenRouter | `OPENROUTER_API_KEY` | llama-3.3-70b |

## 🧩 Agentes de Trading

O DanDi Bot usa o framework **TradingAgents** com os seguintes agentes:

### 📊 Analistas
- **Market Analyst** — dados de mercado e indicadores técnicos
- **News Analyst** — notícias relevantes e transações de insiders
- **Fundamentals Analyst** — balanços, fluxo de caixa, demonstrações
- **Sentiment Analyst** — análise de sentimento de mercado

### 🔬 Pesquisadores
- **Bull Researcher** — argumentos a favor (compra)
- **Bear Researcher** — argumentos contra (venda)

### 👔 Gerentes
- **Research Manager** — coordena analistas
- **Portfolio Manager** — decisões finais de portfólio

### ⚖️ Gestão de Risco
- **Aggressive Debator** — perspectiva de alto risco/retorno
- **Conservative Debator** — perspectiva conservadora
- **Neutral Debator** — perspectiva equilibrada

### 💹 Trader
- **Trader** — executa a decisão final de trading

## 📡 API Endpoints

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/api/health` | Health check do servidor |
| POST | `/api/chat` | Chat com parsing de ticker |
| POST | `/api/analyze` | Análise direta por ticker |
| GET | `/api/status/{job_id}` | Status de um job |
| GET | `/api/stream/{job_id}` | Stream SSE de um job |
| GET | `/api/providers` | LLMs disponíveis |
| GET | `/api/diagnostics` | Diagnóstico do ambiente |
| GET | `/api/jobs` | Lista de jobs recentes |

## 🛠️ Estrutura do Projeto

```
DanDi Bot/
├── lib/                          # Flutter app source
│   ├── enums/                    # Enumerações
│   ├── models/                   # Modelos de dados
│   ├── mock/                     # Dados mock
│   ├── screens/                  # Telas (Chat, Markets, etc.)
│   ├── services/                 # Serviços e controladores
│   │   ├── app_controller.dart   # Controlador principal
│   │   ├── trading_agents_api_service.dart  # Client HTTP do backend
│   │   ├── mock_chat_service.dart           # Chat com fallback 3-tier
│   │   └── ...
│   ├── utils/                    # Utilitários
│   └── widgets/                  # Widgets reutilizáveis
├── api_server.py                 # Servidor FastAPI (bridge)
├── SETUP_BACKEND.bat             # Script de setup automatizado
├── pubspec.yaml                  # Dependências Flutter
├── web/                          # Assets web
├── windows/                      # Config Windows
└── TradingAgents/                # (clonado separadamente)
```

## 📝 Licença

MIT License

## 🤝 Créditos

- **TradingAgents** — [TauricResearch/TradingAgents](https://github.com/TauricResearch/TradingAgents)
- **Flutter** — Google
- **FastAPI** — Sebastián Ramírez
