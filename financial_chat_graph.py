"""LangGraph financial chat orchestrator backed by Google Gemini."""

from __future__ import annotations

import os
from typing import Annotated, Any, Literal, Protocol

from langchain_core.messages import AIMessage, AnyMessage, HumanMessage, SystemMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from typing_extensions import NotRequired, TypedDict


GATEKEEPER_PROMPT = (
    "Voce e o porteiro do sistema. Avalie se a entrada do usuario e "
    "estritamente sobre acoes, criptomoedas ou mercado financeiro. Se for, "
    "responda apenas 'PASS'. Se for sobre qualquer outro assunto, responda "
    "com uma correcao sutil, levemente ironica e elegante, redirecionando o "
    "usuario para o mercado financeiro. Nunca responda a perguntas fora do "
    "escopo."
)

SYNTHESIS_PROMPT = (
    "Voce e o Analista-Chefe. Use os dados tecnicos, fundamentalistas e de "
    "sentimento fornecidos pelos agentes anteriores. Gere uma resposta "
    "profunda, detalhada e ampla, explorando todos os cenarios, riscos e "
    "oportunidades. E estritamente proibido fornecer respostas curtas ou "
    "rasas. Diferencie fatos, hipoteses e limitacoes dos dados. Nao invente "
    "cotacoes em tempo real e inclua um aviso educativo de que a resposta "
    "nao constitui recomendacao de investimento."
)


class AsyncChatModel(Protocol):
    async def ainvoke(self, input: Any, config: Any = None, **kwargs: Any) -> Any:
        """Invoke a chat model asynchronously."""


class FinancialChatState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
    user_input: str
    gatekeeper_result: NotRequired[str]
    gatekeeper_passed: NotRequired[bool]
    fundamental_analysis: NotRequired[str]
    technical_analysis: NotRequired[str]
    sentiment_analysis: NotRequired[str]
    final_response: NotRequired[str]


def _content_as_text(response: Any) -> str:
    content = getattr(response, "content", response)
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict) and isinstance(item.get("text"), str):
                parts.append(item["text"])
        return "\n".join(parts).strip()
    return str(content).strip()


def _history_text(messages: list[AnyMessage], limit: int = 10) -> str:
    recent = messages[-limit:]
    lines = []
    for message in recent:
        role = "Usuario" if isinstance(message, HumanMessage) else "Assistente"
        lines.append(f"{role}: {_content_as_text(message)}")
    return "\n".join(lines)


def create_gemini_model(
    *,
    model: str | None = None,
    max_output_tokens: int = 2048,
    temperature: float = 0.7,
) -> ChatGoogleGenerativeAI:
    api_key = os.getenv("GOOGLE_API_KEY") or os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError(
            "Configure GOOGLE_API_KEY ou GEMINI_API_KEY para usar o chat financeiro."
        )

    return ChatGoogleGenerativeAI(
        model=model or os.getenv("GEMINI_CHAT_MODEL", "gemini-2.5-flash"),
        google_api_key=api_key,
        max_output_tokens=max_output_tokens,
        temperature=temperature,
    )


class FinancialChatGraph:
    """Multi-agent financial chat graph inspired by TradingAgents."""

    def __init__(
        self,
        *,
        gatekeeper_model: AsyncChatModel | None = None,
        analyst_model: AsyncChatModel | None = None,
        synthesis_model: AsyncChatModel | None = None,
    ) -> None:
        self.gatekeeper_model = gatekeeper_model or create_gemini_model(
            max_output_tokens=256,
            temperature=0.1,
        )
        self.analyst_model = analyst_model or create_gemini_model(
            max_output_tokens=1024,
            temperature=0.4,
        )
        self.synthesis_model = synthesis_model or create_gemini_model(
            max_output_tokens=2048,
            temperature=0.7,
        )
        self.graph = self._build_graph()

    async def gatekeeper_node(self, state: FinancialChatState) -> dict[str, Any]:
        response = await self.gatekeeper_model.ainvoke(
            [
                SystemMessage(content=GATEKEEPER_PROMPT),
                HumanMessage(content=state["user_input"]),
            ]
        )
        result = _content_as_text(response)
        passed = result.strip().upper() == "PASS"
        update: dict[str, Any] = {
            "gatekeeper_result": result,
            "gatekeeper_passed": passed,
        }
        if not passed:
            update["final_response"] = result
            update["messages"] = [AIMessage(content=result)]
        return update

    def route_after_gatekeeper(
        self, state: FinancialChatState
    ) -> Literal["fundamental_analyst", "__end__"]:
        return "fundamental_analyst" if state.get("gatekeeper_passed") else END

    async def fundamental_analyst_node(
        self, state: FinancialChatState
    ) -> dict[str, str]:
        prompt = (
            "Voce e o Fundamental Analyst inspirado no TradingAgents. Analise "
            "a pergunta financeira usando fundamentos, modelo de negocio, "
            "receitas, margens, balanco, valuation e riscos estruturais. Se "
            "faltarem dados atuais, declare a limitacao sem inventar numeros.\n\n"
            f"Pergunta: {state['user_input']}\n\n"
            f"Historico recente:\n{_history_text(state['messages'])}"
        )
        response = await self.analyst_model.ainvoke([HumanMessage(content=prompt)])
        return {"fundamental_analysis": _content_as_text(response)}

    async def technical_analyst_node(
        self, state: FinancialChatState
    ) -> dict[str, str]:
        prompt = (
            "Voce e o Technical Analyst inspirado no TradingAgents. Explore "
            "tendencia, momentum, volatilidade, suportes, resistencias e "
            "cenarios tecnicos. Nao invente precos ou indicadores ausentes.\n\n"
            f"Pergunta: {state['user_input']}\n\n"
            f"Contexto fundamentalista:\n{state.get('fundamental_analysis', '')}"
        )
        response = await self.analyst_model.ainvoke([HumanMessage(content=prompt)])
        return {"technical_analysis": _content_as_text(response)}

    async def sentiment_analyst_node(
        self, state: FinancialChatState
    ) -> dict[str, str]:
        prompt = (
            "Voce e o Sentiment Analyst inspirado no TradingAgents. Avalie "
            "narrativas, vieses, catalisadores, noticias e possiveis mudancas "
            "de percepcao do mercado. Explicite quando nao houver dados de "
            "sentimento em tempo real.\n\n"
            f"Pergunta: {state['user_input']}\n\n"
            f"Contexto fundamentalista:\n{state.get('fundamental_analysis', '')}\n\n"
            f"Contexto tecnico:\n{state.get('technical_analysis', '')}"
        )
        response = await self.analyst_model.ainvoke([HumanMessage(content=prompt)])
        return {"sentiment_analysis": _content_as_text(response)}

    async def synthesis_node(self, state: FinancialChatState) -> dict[str, Any]:
        prompt = (
            f"{SYNTHESIS_PROMPT}\n\n"
            f"Pergunta do usuario:\n{state['user_input']}\n\n"
            f"Analise fundamentalista:\n{state.get('fundamental_analysis', '')}\n\n"
            f"Analise tecnica:\n{state.get('technical_analysis', '')}\n\n"
            f"Analise de sentimento:\n{state.get('sentiment_analysis', '')}\n\n"
            f"Historico recente:\n{_history_text(state['messages'])}"
        )
        response = await self.synthesis_model.ainvoke(
            [
                SystemMessage(content=SYNTHESIS_PROMPT),
                HumanMessage(content=prompt),
            ]
        )
        result = _content_as_text(response)
        return {
            "final_response": result,
            "messages": [AIMessage(content=result)],
        }

    def _build_graph(self):
        workflow = StateGraph(FinancialChatState)
        workflow.add_node("gatekeeper", self.gatekeeper_node)
        workflow.add_node("fundamental_analyst", self.fundamental_analyst_node)
        workflow.add_node("technical_analyst", self.technical_analyst_node)
        workflow.add_node("sentiment_analyst", self.sentiment_analyst_node)
        workflow.add_node("synthesis", self.synthesis_node)

        workflow.add_edge(START, "gatekeeper")
        workflow.add_conditional_edges(
            "gatekeeper",
            self.route_after_gatekeeper,
            {
                "fundamental_analyst": "fundamental_analyst",
                END: END,
            },
        )
        workflow.add_edge("fundamental_analyst", "technical_analyst")
        workflow.add_edge("technical_analyst", "sentiment_analyst")
        workflow.add_edge("sentiment_analyst", "synthesis")
        workflow.add_edge("synthesis", END)
        return workflow.compile()

    async def ainvoke(
        self,
        user_input: str,
        *,
        history: list[AnyMessage] | None = None,
    ) -> FinancialChatState:
        messages = list(history or [])
        messages.append(HumanMessage(content=user_input))
        return await self.graph.ainvoke(
            {
                "messages": messages,
                "user_input": user_input,
            }
        )
