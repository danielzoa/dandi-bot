enum AiProvider { tradingAgents, geminiFlash, groqLlama, cerebrasLlama, openRouter, mock }

extension AiProviderX on AiProvider {
  String get label => switch (this) {
    AiProvider.tradingAgents => 'TradingAgents',
    AiProvider.geminiFlash => 'Gemini Flash',
    AiProvider.groqLlama => 'Groq Llama',
    AiProvider.cerebrasLlama => 'Cerebras Llama',
    AiProvider.openRouter => 'OpenRouter',
    AiProvider.mock => 'Simulado',
  };
}
