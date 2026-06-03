import asyncio
import unittest

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


if __name__ == "__main__":
    unittest.main()
