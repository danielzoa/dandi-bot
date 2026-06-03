"""
api_server.py — Bridge entre o Dandi Bot (Vite :4173) e o TradingAgents
Inicia com: uvicorn api_server:app --reload --port 8000
"""

import asyncio
import json
import uuid
import os
from datetime import datetime
from typing import Optional, AsyncGenerator

from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

# ---------------------------------------------------------------------------
# Importação do TradingAgents (deve estar instalado no mesmo venv)
# ---------------------------------------------------------------------------
try:
    from tradingagents.graph.trading_graph import TradingAgentsGraph
    from tradingagents.default_config import DEFAULT_CONFIG
    TRADINGAGENTS_AVAILABLE = True
except ImportError:
    TRADINGAGENTS_AVAILABLE = False
    print("[WARN] tradingagents não encontrado — rode: pip install .")

try:
    from langchain_core.messages import AIMessage, HumanMessage
    from financial_chat_graph import FinancialChatGraph
    FINANCIAL_CHAT_AVAILABLE = True
except ImportError:
    FINANCIAL_CHAT_AVAILABLE = False
    print("[WARN] financial_chat_graph nao esta disponivel.")

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Dandi Bot API",
    description="Bridge FastAPI → TradingAgents multi-agent framework",
    version="1.0.0",
)

# CORS: libera o Vite em dev (:5173) e preview (:4173)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:4173",
        "http://127.0.0.1:4173",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://dandibot.netlify.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Job store (in-memory; para prod use Redis/Postgres)
# ---------------------------------------------------------------------------
# job_id → { status, result, error, logs, created_at }
jobs: dict[str, dict] = {}

# SSE subscribers: job_id → lista de filas
sse_queues: dict[str, list[asyncio.Queue]] = {}

# session_id -> LangChain messages (in-memory; replace with Redis in production)
conversation_histories: dict[str, list] = {}
financial_chat_graph: Optional["FinancialChatGraph"] = None


def _push_event(job_id: str, event: dict):
    """Empurra evento para todos os subscribers SSE daquele job."""
    for q in sse_queues.get(job_id, []):
        try:
            q.put_nowait(event)
        except asyncio.QueueFull:
            pass


# ---------------------------------------------------------------------------
# Modelos de request/response
# ---------------------------------------------------------------------------
class AnalyzeRequest(BaseModel):
    ticker: str
    date: str  # formato YYYY-MM-DD
    llm_provider: str = "openai"
    deep_think_llm: str = "gpt-4o"
    quick_think_llm: str = "gpt-4o-mini"
    max_debate_rounds: int = 1
    checkpoint_enabled: bool = False


class ChatRequest(BaseModel):
    message: str
    llm_provider: str = "openai"
    deep_think_llm: str = "gpt-4o"
    quick_think_llm: str = "gpt-4o-mini"
    max_debate_rounds: int = 1


class ChatHistoryMessage(BaseModel):
    role: str
    content: str


class FinancialChatRequest(BaseModel):
    message: str
    session_id: str = "default"
    history: list[ChatHistoryMessage] = Field(default_factory=list)


class JobResponse(BaseModel):
    job_id: str
    status: str
    result: Optional[dict] = None
    error: Optional[str] = None
    logs: list[str] = []
    created_at: str


def _get_financial_chat_graph() -> "FinancialChatGraph":
    global financial_chat_graph
    if not FINANCIAL_CHAT_AVAILABLE:
        raise RuntimeError(
            "O grafo financeiro nao esta disponivel. "
            "Instale langgraph e langchain-google-genai."
        )
    if financial_chat_graph is None:
        financial_chat_graph = FinancialChatGraph()
    return financial_chat_graph


# ---------------------------------------------------------------------------
# Lógica de análise (roda em executor para não bloquear o loop async)
# ---------------------------------------------------------------------------
def _sync_run_analysis(job_id: str, req: AnalyzeRequest):
    """Executa TradingAgentsGraph de forma síncrona (thread pool)."""
    if not TRADINGAGENTS_AVAILABLE:
        raise RuntimeError(
            "tradingagents não está instalado. "
            "Ative o venv correto e rode: pip install ."
        )

    config = DEFAULT_CONFIG.copy()
    config["llm_provider"] = req.llm_provider
    config["deep_think_llm"] = req.deep_think_llm
    config["quick_think_llm"] = req.quick_think_llm
    config["max_debate_rounds"] = req.max_debate_rounds
    config["checkpoint_enabled"] = req.checkpoint_enabled

    ta = TradingAgentsGraph(debug=True, config=config)
    state, decision = ta.propagate(req.ticker, req.date)
    return state, decision


async def _run_analysis_job(job_id: str, req: AnalyzeRequest):
    """Task de background que roda a análise e atualiza o job store."""
    try:
        _push_event(job_id, {"type": "status", "status": "running",
                              "msg": f"Iniciando análise de {req.ticker}…"})

        loop = asyncio.get_event_loop()
        state, decision = await loop.run_in_executor(
            None, _sync_run_analysis, job_id, req
        )

        # Normaliza o resultado (decision pode ser str ou dict)
        if isinstance(decision, str):
            result = {"raw": decision}
        elif hasattr(decision, "model_dump"):
            result = decision.model_dump()
        elif isinstance(decision, dict):
            result = decision
        else:
            result = {"raw": str(decision)}

        jobs[job_id].update({
            "status": "done",
            "result": result,
            "logs": jobs[job_id].get("logs", []) + ["✅ Análise concluída"],
        })
        _push_event(job_id, {"type": "status", "status": "done", "result": result})

    except Exception as exc:
        error_msg = str(exc)
        jobs[job_id].update({
            "status": "error",
            "error": error_msg,
            "logs": jobs[job_id].get("logs", []) + [f"❌ Erro: {error_msg}"],
        })
        _push_event(job_id, {"type": "status", "status": "error", "error": error_msg})
    finally:
        # Fecha todas as filas SSE desse job após 5s
        async def _close_queues():
            await asyncio.sleep(5)
            for q in sse_queues.pop(job_id, []):
                await q.put(None)  # sentinela de fechamento

        asyncio.create_task(_close_queues())


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/api/health")
async def health():
    """Health check — confirma se o servidor está de pé."""
    return {
        "status": "ok",
        "tradingagents": TRADINGAGENTS_AVAILABLE,
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/providers")
async def list_providers():
    """Lista provedores LLM suportados e seus modelos principais."""
    return {
        "providers": [
            {"id": "openai",     "name": "OpenAI (GPT)",
             "deep": "gpt-4o",         "quick": "gpt-4o-mini",
             "env": "OPENAI_API_KEY"},
            {"id": "anthropic",  "name": "Anthropic (Claude)",
             "deep": "claude-sonnet-4-6", "quick": "claude-haiku-4-5-20251001",
             "env": "ANTHROPIC_API_KEY"},
            {"id": "google",     "name": "Google (Gemini)",
             "deep": "gemini-2.5-pro",  "quick": "gemini-2.0-flash",
             "env": "GOOGLE_API_KEY"},
            {"id": "deepseek",   "name": "DeepSeek",
             "deep": "deepseek-reasoner","quick": "deepseek-chat",
             "env": "DEEPSEEK_API_KEY"},
            {"id": "xai",        "name": "xAI (Grok)",
             "deep": "grok-3",          "quick": "grok-3-mini",
             "env": "XAI_API_KEY"},
            {"id": "openrouter", "name": "OpenRouter",
             "deep": "meta-llama/llama-3.3-70b-instruct",
             "quick": "meta-llama/llama-3.3-70b-instruct",
             "env": "OPENROUTER_API_KEY"},
            {"id": "ollama",     "name": "Ollama (local)",
             "deep": "llama3.3",        "quick": "llama3.3",
             "env": None},
        ]
    }


@app.post("/api/analyze")
async def start_analysis(req: AnalyzeRequest, background_tasks: BackgroundTasks):
    """
    Dispara uma análise de trading em background.
    Retorna job_id para polling / SSE.
    """
    job_id = str(uuid.uuid4())
    jobs[job_id] = {
        "status": "pending",
        "result": None,
        "error": None,
        "logs": [f"Job {job_id[:8]} criado para {req.ticker} em {req.date}"],
        "created_at": datetime.utcnow().isoformat(),
        "ticker": req.ticker,
        "date": req.date,
    }
    sse_queues[job_id] = []
    background_tasks.add_task(_run_analysis_job, job_id, req)
    return {"job_id": job_id, "status": "pending"}


@app.get("/api/status/{job_id}", response_model=JobResponse)
async def job_status(job_id: str):
    """Polling simples — retorna estado atual do job."""
    job = jobs.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job não encontrado")
    return JobResponse(
        job_id=job_id,
        status=job["status"],
        result=job.get("result"),
        error=job.get("error"),
        logs=job.get("logs", []),
        created_at=job.get("created_at", ""),
    )


@app.get("/api/stream/{job_id}")
async def stream_job(job_id: str):
    """
    SSE — o frontend assina este endpoint e recebe eventos em tempo real.
    Exemplo JS:
        const ev = new EventSource(`/api/stream/${jobId}`)
        ev.onmessage = e => console.log(JSON.parse(e.data))
    """
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job não encontrado")

    queue: asyncio.Queue = asyncio.Queue(maxsize=50)
    sse_queues.setdefault(job_id, []).append(queue)

    async def event_generator() -> AsyncGenerator[str, None]:
        # Envia estado atual imediatamente
        job = jobs.get(job_id, {})
        yield f"data: {json.dumps({'type': 'snapshot', **job})}\n\n"

        while True:
            try:
                event = await asyncio.wait_for(queue.get(), timeout=30)
            except asyncio.TimeoutError:
                yield "data: {\"type\":\"ping\"}\n\n"
                continue

            if event is None:  # sentinela → fecha stream
                break
            yield f"data: {json.dumps(event)}\n\n"
            if event.get("status") in ("done", "error"):
                break

        # Remove fila após encerrar
        try:
            sse_queues[job_id].remove(queue)
        except (KeyError, ValueError):
            pass

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@app.get("/api/jobs")
async def list_jobs(limit: int = 20):
    """Lista os jobs mais recentes."""
    recent = sorted(jobs.items(), key=lambda x: x[1].get("created_at", ""), reverse=True)
    return [
        {
            "job_id": jid,
            "ticker": j.get("ticker"),
            "date": j.get("date"),
            "status": j.get("status"),
            "created_at": j.get("created_at"),
        }
        for jid, j in recent[:limit]
    ]


@app.post("/api/v1/chat")
async def financial_chat(req: FinancialChatRequest):
    """
    LangGraph financial chat with gatekeeper, TradingAgents-inspired analysts,
    synthesis, and per-session message history.
    """
    message = req.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="A mensagem nao pode ser vazia.")

    try:
        graph = _get_financial_chat_graph()
        if req.history:
            history = [
                HumanMessage(content=item.content)
                if item.role.lower() in {"user", "human"}
                else AIMessage(content=item.content)
                for item in req.history
                if item.content.strip()
            ]
        else:
            history = conversation_histories.get(req.session_id, [])

        result = await graph.ainvoke(message, history=history)
        response = result.get("final_response", "")
        conversation_histories[req.session_id] = result.get("messages", [])[-20:]

        return {
            "type": (
                "financial_analysis"
                if result.get("gatekeeper_passed")
                else "out_of_scope"
            ),
            "message": response,
            "session_id": req.session_id,
            "provider": "google_gemini",
            "analyses": {
                "fundamental": result.get("fundamental_analysis"),
                "technical": result.get("technical_analysis"),
                "sentiment": result.get("sentiment_analysis"),
            },
        }
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Falha ao executar o grafo financeiro: {exc}",
        ) from exc


@app.post("/api/chat")
async def chat(req: ChatRequest, background_tasks: BackgroundTasks):
    """
    Endpoint de chat — o Dandi Bot envia uma mensagem livre e o servidor
    tenta extrair ticker + data para disparar uma análise.
    Retorna job_id se o parser conseguir identificar; caso contrário retorna
    uma resposta textual de ajuda.
    """
    import re
    msg = req.message.strip().upper()
    today = datetime.utcnow().strftime("%Y-%m-%d")

    # Parser simples de ticker (ex: "analise NVDA", "AAPL hoje", "PETR4.SA")
    ticker_pattern = r"\b([A-Z]{1,5}(?:\.[A-Z]{2})?)\b"
    tickers = re.findall(ticker_pattern, msg)

    # Data: procura padrões YYYY-MM-DD ou "hoje"
    date_match = re.search(r"(\d{4}-\d{2}-\d{2})", msg)
    date = date_match.group(1) if date_match else today

    # Filtra falsos positivos comuns
    EXCLUDE = {"HOJE", "ANALISE", "ANALYZE", "THE", "FOR", "AND", "BUY", "SELL"}
    tickers = [t for t in tickers if t not in EXCLUDE]

    if not tickers:
        return {
            "type": "text",
            "message": (
                "Não consegui identificar um ticker na sua mensagem. "
                "Exemplos: 'Analise NVDA', 'AAPL 2026-01-15', 'PETR4.SA hoje'."
            ),
            "job_id": None,
        }

    ticker = tickers[0]
    analyze_req = AnalyzeRequest(
        ticker=ticker,
        date=date,
        llm_provider=req.llm_provider,
        deep_think_llm=req.deep_think_llm,
        quick_think_llm=req.quick_think_llm,
        max_debate_rounds=req.max_debate_rounds,
    )

    job_id = str(uuid.uuid4())
    jobs[job_id] = {
        "status": "pending",
        "result": None,
        "error": None,
        "logs": [f"Chat disparou análise de {ticker} em {date}"],
        "created_at": datetime.utcnow().isoformat(),
        "ticker": ticker,
        "date": date,
    }
    sse_queues[job_id] = []
    background_tasks.add_task(_run_analysis_job, job_id, analyze_req)

    return {
        "type": "analysis_started",
        "message": f"Iniciando análise de **{ticker}** para {date}. Acompanhe em tempo real abaixo.",
        "job_id": job_id,
        "ticker": ticker,
        "date": date,
    }


# ---------------------------------------------------------------------------
# Diagnóstico de configuração
# ---------------------------------------------------------------------------
@app.get("/api/diagnostics")
async def diagnostics():
    """Retorna diagnóstico completo do ambiente."""
    providers_with_keys = []
    providers_missing_keys = []

    env_map = {
        "OPENAI_API_KEY": "openai",
        "ANTHROPIC_API_KEY": "anthropic",
        "GOOGLE_API_KEY": "google",
        "DEEPSEEK_API_KEY": "deepseek",
        "XAI_API_KEY": "xai",
        "OPENROUTER_API_KEY": "openrouter",
        "DASHSCOPE_API_KEY": "qwen",
        "ZHIPU_API_KEY": "glm",
        "ALPHA_VANTAGE_API_KEY": "alpha_vantage",
        "FINNHUB_API_KEY": "finnhub",
    }

    for env_var, provider in env_map.items():
        val = os.getenv(env_var, "")
        if val and len(val) > 5:
            providers_with_keys.append(provider)
        else:
            providers_missing_keys.append({"provider": provider, "env_var": env_var})

    return {
        "tradingagents_installed": TRADINGAGENTS_AVAILABLE,
        "financial_chat_available": FINANCIAL_CHAT_AVAILABLE,
        "financial_chat_sessions": len(conversation_histories),
        "providers_configured": providers_with_keys,
        "providers_missing_keys": providers_missing_keys,
        "python_path": os.sys.executable,
        "jobs_in_memory": len(jobs),
    }
