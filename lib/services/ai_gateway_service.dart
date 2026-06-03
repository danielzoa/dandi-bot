import '../enums/agent_role.dart';
import '../enums/ai_provider.dart';
import '../enums/market_type.dart';
import '../models/chat_message.dart';
import '../mock/mock_chat_responses.dart';

abstract class AiGatewayService {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    String? selectedTicker,
    MarketType? marketType,
    AiProvider provider = AiProvider.mock,
    AgentRole? agentRole,
  });

  AiProvider resolveProvider(AgentRole role);
}

const Map<AiProvider, String> kProviderBaseUrls = {
  AiProvider.groqLlama: 'https://api.groq.com/openai/v1',
  AiProvider.cerebrasLlama: 'https://api.cerebras.ai/v1',
  AiProvider.geminiFlash:
      'https://generativelanguage.googleapis.com/v1beta/openai',
  AiProvider.openRouter: 'https://openrouter.ai/api/v1',
};

const Map<AiProvider, String> kProviderModels = {
  AiProvider.groqLlama: 'llama-3.3-70b-versatile',
  AiProvider.cerebrasLlama: 'llama3.3-70b',
  AiProvider.geminiFlash: 'gemini-2.0-flash',
  AiProvider.openRouter: 'meta-llama/llama-3.3-70b-instruct:free',
};

const kProviderFallbackChain = [
  AiProvider.groqLlama,
  AiProvider.cerebrasLlama,
  AiProvider.geminiFlash,
  AiProvider.openRouter,
  AiProvider.mock,
];

// TODO(backend): Substituir MockAiGatewayService por HttpAiGatewayService
// quando FastAPI estiver disponivel.
//
// Endpoint esperado:
// POST /api/v1/chat
// Body: { message, history, ticker?, market_type?, agent_role?, provider? }
// Response: { response: string, provider_used: string, tokens_used: int }
//
// Provedores suportados pelo backend:
// - gemini_flash (Google AI Studio free tier)
// - groq_llama (Groq free tier - velocidade)
// - cerebras_llama (Cerebras free tier - volume)
// - openrouter (fallback variado)
//
// Chaves de API ficam EXCLUSIVAMENTE no servidor FastAPI.
// O Flutter nunca armazena ou transmite chaves de API.
class MockAiGatewayService implements AiGatewayService {
  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    String? selectedTicker,
    MarketType? marketType,
    AiProvider provider = AiProvider.mock,
    AgentRole? agentRole,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return MockChatResponses.getResponse(message, selectedTicker);
  }

  @override
  AiProvider resolveProvider(AgentRole role) => AiProvider.mock;

  static AiProvider plannedProviderFor(AgentRole role) => switch (role) {
    AgentRole.newsAnalyst => AiProvider.groqLlama,
    AgentRole.sentimentAnalyst => AiProvider.groqLlama,
    AgentRole.fundamentalsAnalyst => AiProvider.geminiFlash,
    AgentRole.technicalAnalyst => AiProvider.geminiFlash,
    AgentRole.riskManager => AiProvider.geminiFlash,
    AgentRole.bullResearcher => AiProvider.cerebrasLlama,
    AgentRole.bearResearcher => AiProvider.cerebrasLlama,
    AgentRole.trader => AiProvider.geminiFlash,
  };
}
