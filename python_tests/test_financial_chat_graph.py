import asyncio
import unittest

from langchain_core.messages import AIMessage, HumanMessage

from financial_chat_graph import FinancialChatGraph


class QueueModel:
    def __init__(self, responses):
        self.responses = list(responses)
        self.calls = []

    async def ainvoke(self, input, config=None, **kwargs):
        self.calls.append(input)
        return AIMessage(content=self.responses.pop(0))


class FinancialChatGraphTest(unittest.TestCase):
    def test_gatekeeper_stops_out_of_scope_requests(self):
        gatekeeper = QueueModel(
            [
                "Interessante, mas deixemos a culinaria para quem mede risco "
                "em colheres."
            ]
        )
        graph = FinancialChatGraph(
            gatekeeper_model=gatekeeper,
            analyst_model=QueueModel([]),
            synthesis_model=QueueModel([]),
        )

        result = asyncio.run(graph.ainvoke("Como fazer um bolo?"))

        self.assertFalse(result["gatekeeper_passed"])
        self.assertIn("culinaria", result["final_response"])
        self.assertNotIn("fundamental_analysis", result)

    def test_financial_request_runs_all_analysts_and_synthesis_with_history(self):
        gatekeeper = QueueModel(["PASS"])
        analysts = QueueModel(
            [
                "Fundamentos com crescimento e riscos.",
                "Tecnico com tendencia e volatilidade.",
                "Sentimento com catalisadores e cautela.",
            ]
        )
        synthesis = QueueModel(["Relatorio final amplo e educativo."])
        graph = FinancialChatGraph(
            gatekeeper_model=gatekeeper,
            analyst_model=analysts,
            synthesis_model=synthesis,
        )

        result = asyncio.run(
            graph.ainvoke(
                "Analise PETR4.",
                history=[
                    HumanMessage(content="Quero entender empresas brasileiras."),
                    AIMessage(content="Vamos avaliar fundamentos e riscos."),
                ],
            )
        )

        self.assertTrue(result["gatekeeper_passed"])
        self.assertTrue(result["fundamental_analysis"].startswith("Fundamentos"))
        self.assertTrue(result["technical_analysis"].startswith("Tecnico"))
        self.assertTrue(result["sentiment_analysis"].startswith("Sentimento"))
        self.assertTrue(result["final_response"].startswith("Relatorio final"))
        self.assertEqual(len(analysts.calls), 3)
        self.assertEqual(len(result["messages"]), 4)


if __name__ == "__main__":
    unittest.main()
