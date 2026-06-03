import asyncio
import os
import unittest
from unittest.mock import patch

import api_server
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


if __name__ == "__main__":
    unittest.main()
