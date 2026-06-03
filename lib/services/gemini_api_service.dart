import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class GeminiApiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> chat({
    required String message,
    required List<ChatMessage> history,
    required String apiKey,
    String? contextTicker,
  }) async {
    var urlString = '$_baseUrl?key=$apiKey';
    if (kIsWeb) {
      urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
    }
    final url = Uri.parse(urlString);

    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      contents.add({
        'role': msg.sender == MessageSender.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      });
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': message}
      ],
    });

    final contextString = contextTicker != null
        ? 'Você está prestando suporte no contexto do ativo financeiro: $contextTicker.'
        : '';

    final systemInstruction = '''
Você é o Dandi Bot, o assistente central do Dandi Bot, uma plataforma educativa e simulada de investimentos baseada no framework de debate de multiagentes do TradingAgents (desenvolvido pela Tauric Research).
Sua personalidade é profissional, analítica, amigável e educativa. Responda em português brasileiro.
$contextString
Se o usuário perguntar sobre a análise de um ativo específico (ex: PETR4.SA, AAPL, BTC-USD), você pode encorajar o usuário a usar a aba de "Mercados" para rodar uma análise de agentes em tempo real completa ou responder com seus insights, lembrando que tudo é simulado e educacional.
Nunca dê conselhos reais de compra/venda como recomendação de investimento direta e real. Sempre inclua um tom educativo.
''';

    final body = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1500,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao comunicar com Gemini: Status ${response.statusCode}\n${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Nenhuma resposta retornada do Gemini.');
    }

    final firstCandidate = candidates[0] as Map<String, dynamic>;
    final content = firstCandidate['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    if (parts.isEmpty) {
      throw Exception('Parte de resposta vazia.');
    }

    return parts[0]['text'] as String;
  }

  Future<Map<String, dynamic>> analyzeTicker({
    required String ticker,
    required String marketType,
    required String apiKey,
    Map<String, dynamic>? assetData,
  }) async {
    var urlString = '$_baseUrl?key=$apiKey';
    if (kIsWeb) {
      urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
    }
    final url = Uri.parse(urlString);

    final assetCtx = assetData != null
        ? 'Dados atuais de mercado (simulados) do ativo:\n${jsonEncode(assetData)}'
        : 'Nenhum dado prévio de mercado disponível.';

    final systemInstruction = '''
Você é um gerador de análise financeira profissional que simula um comitê multiagente inspirado no framework TradingAgents (Tauric Research).
Você DEVE responder APENAS com um JSON estruturado válido contendo as opiniões detalhadas de cada um dos 8 agentes (fundamentalsAnalyst, sentimentAnalyst, newsAnalyst, technicalAnalyst, bullResearcher, bearResearcher, riskManager, trader).
''';

    final prompt = '''
Analise o ativo "$ticker" ($marketType).
$assetCtx

Seus agentes devem debater o ativo e produzir um parecer estruturado final.
O JSON resultante deve seguir exatamente esta estrutura e tipos de dados:

{
  "summary": "Resumo consolidado da análise em português brasileiro",
  "positivePoints": ["Ponto positivo 1", "Ponto positivo 2", "Ponto positivo 3"],
  "cautionPoints": ["Ponto de cautela 1", "Ponto de cautela 2", "Ponto de cautela 3"],
  "technicalAnalysis": "Resumo detalhado da leitura gráfica técnica do ativo",
  "fundamentalsText": "Resumo detalhado dos fundamentos ou métricas on-chain do ativo",
  "dividendText": "Resumo detalhado da política de dividendos (se for cripto, deve ser null)",
  "macroAnalysis": "Resumo detalhado do impacto macroeconômico e notícias sobre o ativo",
  "regulatoryRisk": "Análise detalhada de riscos regulatórios aplicados a este ativo",
  "sentiment": "Leitura de sentimento de mercado e redes sociais",
  "decision": "buy", // Deve ser exatamente um dos valores: "buy", "overweight", "hold", "underweight", "sell"
  "confidence": 0.75, // Valor decimal de confiança entre 0.0 e 1.0
  "riskLevel": "medium", // Deve ser exatamente um dos valores: "low", "medium", "high", "extreme"
  "agentOpinions": [
    {
      "role": "fundamentalsAnalyst",
      "agentName": "Analista Fundamentalista",
      "message": "Mensagem detalhada contendo a análise deste agente específica para o ativo $ticker."
    },
    {
      "role": "sentimentAnalyst",
      "agentName": "Analista de Sentimento",
      "message": "Mensagem detalhada contendo a análise deste agente específica para o ativo $ticker."
    },
    {
      "role": "newsAnalyst",
      "agentName": "Analista de Notícias",
      "message": "Mensagem detalhada contendo a análise deste agente específica para o ativo $ticker."
    },
    {
      "role": "technicalAnalyst",
      "agentName": "Analista Técnico",
      "message": "Mensagem detalhada contendo a análise deste agente específica para o ativo $ticker."
    },
    {
      "role": "bullResearcher",
      "agentName": "Agente Bull",
      "message": "Mensagem de debate otimista e argumentos fortes para compra/manutenção.",
      "suggestion": "overweight" // buy | overweight | hold | underweight | sell
    },
    {
      "role": "bearResearcher",
      "agentName": "Agente Bear",
      "message": "Mensagem de debate pessimista/cauteloso e argumentos de riscos/venda.",
      "suggestion": "underweight", // buy | overweight | hold | underweight | sell
      "riskAssessment": "high" // low | medium | high | extreme
    },
    {
      "role": "riskManager",
      "agentName": "Gestor de Risco",
      "message": "Análise consolidada de riscos estruturais e operacionais.",
      "riskAssessment": "medium" // low | medium | high | extreme
    },
    {
      "role": "trader",
      "agentName": "Dandi Bot",
      "message": "Decisão de negociação final do Dandi Bot consolidando todos os argumentos e emitindo o veredito.",
      "suggestion": "hold", // buy | overweight | hold | underweight | sell
      "riskAssessment": "medium" // low | medium | high | extreme
    }
  ],
  "indicators": {
    "P/L": "Valor ou N/A",
    "P/VP": "Valor ou N/A",
    "Div. Yield": "Valor ou N/A",
    "ROE": "Valor ou N/A",
    "Margem": "Valor ou N/A",
    "Dívida/EBITDA": "Valor ou N/A"
  }
}

Importante: Retorne apenas o JSON limpo, sem blocos de código markdown adicionais, sem preâmbulos e sem conclusões fora do JSON.
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao obter análise do Gemini: Status ${response.statusCode}\n${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Nenhuma resposta retornada do Gemini.');
    }

    final firstCandidate = candidates[0] as Map<String, dynamic>;
    final content = firstCandidate['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    if (parts.isEmpty) {
      throw Exception('Parte de resposta vazia.');
    }

    final responseText = parts[0]['text'] as String;

    // Parse responseText as JSON map
    try {
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      // Fallback in case responseMimeType wasn't fully respected or formatting issue
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.firstMatch(responseText);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
      rethrow;
    }
  }
}
