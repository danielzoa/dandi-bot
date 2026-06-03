import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../enums/ai_provider.dart';
import '../enums/chat_intent.dart';
import '../models/chat_message.dart';
import 'ai_gateway_service.dart';
import 'chat_service.dart';
import 'gemini_api_service.dart';
import 'trading_agents_api_service.dart';

class MockChatService implements ChatService {
  MockChatService(this._gateway, {TradingAgentsApiService? backendApi})
    : _backendApi = backendApi; // ignore: prefer_initializing_formals

  final AiGatewayService _gateway;
  TradingAgentsApiService? _backendApi;
  final _uuid = const Uuid();
  final _geminiApi = GeminiApiService();

  /// Update the backend API service (e.g. when URL changes in settings).
  void updateBackendApi(TradingAgentsApiService? api) {
    _backendApi = api;
  }

  @override
  Future<ChatMessage> sendMessage(
    String content, {
    String? contextTicker,
    List<ChatMessage> history = const [],
    String? apiKey,
  }) async {
    // ── Priority 1: TradingAgents Backend (api_server.py :8000) ──
    if (_backendApi != null) {
      try {
        final available = await _backendApi!.isAvailable();
        final hasGeminiKey =
            apiKey != null && apiKey.isNotEmpty ||
            await _backendApi!.hasConfiguredProvider('google');
        if (available && hasGeminiKey) {
          return await _sendViaBackend(content, contextTicker, apiKey: apiKey);
        }
      } catch (e) {
        debugPrint('[ChatService] Backend unavailable: $e');
      }
    }

    // ── Priority 2: Gemini API direto (se apiKey existe) ──
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _geminiApi.chat(
          message: content,
          history: history,
          apiKey: apiKey,
          contextTicker: contextTicker,
        );
        return ChatMessage(
          id: _uuid.v4(),
          content: geminiResponse,
          sender: MessageSender.bot,
          createdAt: DateTime.now(),
          relatedTicker: contextTicker,
          intent: _detectIntent(content),
          provider: AiProvider.geminiFlash,
        );
      } catch (e) {
        debugPrint('[ChatService] Gemini API failed: $e');
      }
    }

    // ── Priority 3: Mock/Gateway fallback ──
    final response = await _gateway.sendMessage(
      message: content,
      history: history.take(10).toList(),
      selectedTicker: contextTicker,
      provider: AiProvider.mock,
    );

    return ChatMessage(
      id: _uuid.v4(),
      content: response,
      sender: MessageSender.bot,
      createdAt: DateTime.now(),
      relatedTicker: contextTicker,
      intent: _detectIntent(content),
      provider: AiProvider.mock,
    );
  }

  /// Sends message via TradingAgents backend, polls for result if job is started.
  Future<ChatMessage> _sendViaBackend(
    String content,
    String? contextTicker, {
    String? apiKey,
  }) async {
    final response = await _backendApi!.sendChatMessage(
      message: content,
      apiKey: apiKey,
    );
    final type = response['type'] as String?;
    final botMsg = response['message'] as String? ?? '';
    final jobId = response['job_id'] as String?;

    // If backend parsed the message and started an analysis job
    if (type == 'analysis_started' && jobId != null) {
      // Poll for job completion
      try {
        final jobResult = await _backendApi!.waitForJob(
          jobId,
          interval: const Duration(seconds: 3),
          timeout: const Duration(minutes: 8),
        );

        final status = jobResult['status'] as String?;
        if (status == 'done') {
          final result = jobResult['result'] as Map<String, dynamic>?;
          final resultText =
              result?['raw'] as String? ??
              _formatAnalysisResult(result) ??
              'Análise concluída.';

          return ChatMessage(
            id: _uuid.v4(),
            content: '$botMsg\n\n---\n\n**Resultado da análise:**\n$resultText',
            sender: MessageSender.bot,
            createdAt: DateTime.now(),
            relatedTicker: contextTicker ?? response['ticker'] as String?,
            intent: ChatIntent.assetAnalysis,
            provider: AiProvider.tradingAgents,
          );
        } else {
          final error = jobResult['error'] as String? ?? 'Erro desconhecido';
          return ChatMessage(
            id: _uuid.v4(),
            content: '$botMsg\n\n⚠️ A análise encontrou um erro: $error',
            sender: MessageSender.bot,
            createdAt: DateTime.now(),
            relatedTicker: contextTicker,
            intent: ChatIntent.assetAnalysis,
            provider: AiProvider.tradingAgents,
          );
        }
      } catch (e) {
        return ChatMessage(
          id: _uuid.v4(),
          content:
              '$botMsg\n\n⏳ A análise está demorando. '
              'Você pode verificar o status em: /api/status/$jobId',
          sender: MessageSender.bot,
          createdAt: DateTime.now(),
          relatedTicker: contextTicker,
          intent: ChatIntent.assetAnalysis,
          provider: AiProvider.tradingAgents,
        );
      }
    }

    // Simple text response (no analysis triggered)
    return ChatMessage(
      id: _uuid.v4(),
      content: botMsg,
      sender: MessageSender.bot,
      createdAt: DateTime.now(),
      relatedTicker: contextTicker,
      intent: _detectIntent(content),
      provider: AiProvider.tradingAgents,
    );
  }

  /// Formats a TradingAgents analysis result map into readable text.
  String? _formatAnalysisResult(Map<String, dynamic>? result) {
    if (result == null || result.isEmpty) return null;

    final buffer = StringBuffer();

    if (result.containsKey('summary')) {
      buffer.writeln(result['summary']);
    }

    if (result.containsKey('decision')) {
      buffer.writeln('\n**Decisão:** ${result['decision']}');
    }

    if (result.containsKey('confidence')) {
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0;
      buffer.writeln(
        '**Confiança:** ${(confidence * 100).toStringAsFixed(0)}%',
      );
    }

    if (result.containsKey('risk_level')) {
      buffer.writeln('**Risco:** ${result['risk_level']}');
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  @override
  List<String> getDynamicSuggestions({
    String? lastAnalyzedTicker,
    bool hasPortfolio = false,
  }) {
    final suggestions = <String>[];

    if (lastAnalyzedTicker != null) {
      suggestions.add('Ver debate de $lastAnalyzedTicker');
      suggestions.add('Risco de $lastAnalyzedTicker explicado');
      suggestions.add('Compare $lastAnalyzedTicker com similar');
    }

    if (hasPortfolio) {
      suggestions.add('Minha carteira está diversificada?');
    }

    suggestions.addAll([
      'O que é P/L?',
      'Explique dividend yield.',
      'Analise PETR4.SA.',
      'Compare AAPL e MSFT.',
      'BTC está muito arriscado?',
      'O que significa risco regulatório?',
      'Qual a diferença entre ação e cripto?',
    ]);

    return suggestions.take(8).toList();
  }

  ChatIntent _detectIntent(String content) {
    final value = content.toLowerCase();
    if (value.contains('compare')) return ChatIntent.assetComparison;
    if (value.contains('carteira')) return ChatIntent.portfolioQuestion;
    if (value.contains('risco')) return ChatIntent.riskExplanation;
    if (value.contains('btc') || value.contains('cripto')) {
      return ChatIntent.cryptoQuestion;
    }
    if (value.contains('debate')) return ChatIntent.agentDebateQuestion;
    if (value.contains('analise') || value.contains('análise')) {
      return ChatIntent.assetAnalysis;
    }
    if (value.contains('p/l') || value.contains('dividend')) {
      return ChatIntent.educationalQuestion;
    }
    return ChatIntent.unknown;
  }
}
