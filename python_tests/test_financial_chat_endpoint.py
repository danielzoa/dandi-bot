import asyncio
import os
import unittest
from unittest.mock import AsyncMock, patch

import api_server
from fastapi import BackgroundTasks
from langchain_core.messages import AIMessage, HumanMessage


class FakeFinancialGraph:
    async def ainvoke(self, message, *, history=None):
        messages = list(history or [])
        messages.extend(
            [
                HumanMessage(content=message),
                AIMessage(content="Resposta final detalhada."),
            ]
        )
        return {
            "messages": messages,
            "gatekeeper_passed": True,
            "fundamental_analysis": "Fundamentos",
            "technical_analysis": "Tecnico",
            "sentiment_analysis": "Sentimento",
            "final_response": "Resposta final detalhada.",
        }


class FinancialChatEndpointTest(unittest.TestCase):
    def setUp(self):
        api_server.financial_chat_graph = FakeFinancialGraph()
        api_server.conversation_histories.clear()

    def tearDown(self):
        api_server.financial_chat_graph = None
        api_server.conversation_histories.clear()

    def test_endpoint_returns_analyses_and_keeps_session_history(self):
        request = api_server.FinancialChatRequest(
            message="Analise PETR4.",
            session_id="test-session",
        )

        response = asyncio.run(api_server.financial_chat(request))

        self.assertEqual(response["type"], "financial_analysis")
        self.assertEqual(response["provider"], "google_gemini")
        self.assertEqual(response["analyses"]["technical"], "Tecnico")
        self.assertEqual(len(api_server.conversation_histories["test-session"]), 2)

    def test_analysis_uses_request_api_key_without_persisting_it(self):
        captured = {}

        class FakeTradingAgentsGraph:
            def __init__(self, **kwargs):
                captured["key_during_init"] = os.getenv("GOOGLE_API_KEY")

            def propagate(self, ticker, date):
                return {}, "done"

        previous_key = os.environ.pop("GOOGLE_API_KEY", None)
        try:
            request = api_server.AnalyzeRequest(
                ticker="BTC-USD",
                date="2026-06-03",
                llm_provider="google",
                api_key="request-only-key",
            )
            with patch.object(api_server, "TradingAgentsGraph", FakeTradingAgentsGraph):
                api_server._sync_run_analysis("test-job", request)

            self.assertEqual(captured["key_during_init"], "request-only-key")
            self.assertIsNone(os.getenv("GOOGLE_API_KEY"))
            self.assertNotIn("api_key", request.model_dump())
        finally:
            if previous_key is not None:
                os.environ["GOOGLE_API_KEY"] = previous_key

    def test_brazilian_analysis_job_exposes_brazil_context(self):
        context = {"macro": {"selic_meta": 14.5}, "fundamentals": {"ticker": "PETR4"}}
        request = api_server.AnalyzeRequest(ticker="PETR4.SA", date="2026-06-04")
        with patch.object(
            api_server,
            "_prepare_brazil_context",
            new=AsyncMock(return_value=(context, "Macro BR")),
        ):
            response = asyncio.run(api_server.start_analysis(request, BackgroundTasks()))

        self.assertEqual(response["brazil_context"], context)
        self.assertEqual(api_server.jobs[response["job_id"]]["context_notes"], "Macro BR")

    def test_brazil_context_is_injected_into_tradingagents_instrument_context(self):
        captured = {}

        class FakeTradingAgentsGraph:
            def __init__(self, **kwargs):
                captured["config"] = kwargs["config"]

            def resolve_instrument_context(self, ticker, asset_type="stock"):
                return f"Instrument: {ticker}"

            def propagate(self, ticker, date):
                captured["instrument_context"] = self.resolve_instrument_context(ticker)
                return {}, "done"

        job_id = "brazil-context-job"
        api_server.jobs[job_id] = {
            "brazil_context": {"macro": {"selic_meta": 14.5}},
            "context_notes": "Macro BR | Selic: 14,50% a.a.",
        }
        request = api_server.AnalyzeRequest(ticker="PETR4.SA", date="2026-06-04")
        with patch.object(api_server, "TradingAgentsGraph", FakeTradingAgentsGraph):
            api_server._sync_run_analysis(job_id, request)

        self.assertIn("Selic: 14,50%", captured["instrument_context"])
        self.assertIn("brazil_context", captured["config"])


if __name__ == "__main__":
    unittest.main()
