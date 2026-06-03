import '../enums/asset_decision.dart';
import '../enums/risk_level.dart';
import '../models/analysis_result.dart';
import '../utils/formatters.dart';
import 'mock_analyses.dart';

abstract final class MockChatResponses {
  static String getResponse(String message, String? selectedTicker) {
    final normalized = message.trim().toLowerCase();

    if (normalized.contains('p/l') ||
        normalized.contains('preço sobre lucro')) {
      return 'P/L significa Preço sobre Lucro. Ele mostra quanto o mercado paga por cada unidade de lucro. P/L alto pode indicar expectativa de crescimento ou preço esticado; P/L baixo pode indicar oportunidade ou um problema ainda não visível. Conteúdo educativo e simulado.';
    }

    if (normalized.contains('dividend')) {
      return 'Dividend yield é a relação entre dividendos pagos e preço do ativo. Ele ajuda a comparar renda, mas não garante retorno futuro e deve ser analisado junto com lucro, caixa, dívida e governança. Conteúdo educativo e simulado.';
    }

    if (normalized.contains('compare aapl') ||
        normalized.contains('aapl e msft')) {
      return 'AAPL é uma empresa madura, com ecossistema premium e receitas de serviços crescentes. MSFT tem forte exposição a cloud, software corporativo e IA via Copilot. Em simulação, MSFT apresenta tese de crescimento mais ligada à nuvem, enquanto AAPL tem perfil mais defensivo. Conteúdo educativo.';
    }

    if (normalized.contains('btc')) {
      return 'BTC tem risco alto por volatilidade extrema, ciclos de mercado, regulação em evolução e sentimento global. Em simulação, o Dandi Bot classificaria BTC-USD como risco ALTO com decisão MANTER, dependendo do perfil do investidor. Conteúdo educativo e simulado.';
    }

    if (normalized.contains('carteira') && normalized.contains('divers')) {
      return 'Uma carteira simulada mais diversificada tende a distribuir exposição entre Brasil, EUA e cripto, evitando concentração excessiva em um único mercado ou tese. A leitura ideal depende do seu perfil, horizonte e tolerância a volatilidade. Conteúdo educativo e simulado.';
    }

    final ticker = _extractTicker(message) ?? selectedTicker;
    if (normalized.contains('analise') ||
        normalized.contains('análise') ||
        normalized.contains('risco') ||
        normalized.contains('debate')) {
      if (ticker != null) return _formatAnalysis(MockAnalyses.create(ticker));
    }

    if (normalized.contains('risco regulatório')) {
      return 'Risco regulatório é a possibilidade de regras, decisões governamentais, processos ou supervisão setorial afetarem preço, lucro, operação ou liquidez de um ativo. Conteúdo educativo e simulado.';
    }

    if (normalized.contains('ação') && normalized.contains('cripto')) {
      return 'Ação representa participação em uma empresa, com balanços, lucro e governança. Cripto representa um ativo digital de rede ou protocolo, geralmente mais volátil e com regulação em evolução. Conteúdo educativo e simulado.';
    }

    return 'Não entendi completamente sua pergunta. Posso ajudar com análises de ativos, termos financeiros, criptomoedas ou sua carteira simulada. Conteúdo educativo.';
  }

  static String? _extractTicker(String message) {
    final regex = RegExp(r'\b[A-Z]{3,6}(?:\.SA|-USD)?\b', caseSensitive: false);
    final match = regex.firstMatch(message.toUpperCase());
    return match?.group(0);
  }

  static String _formatAnalysis(AnalysisResult analysis) {
    final asset = analysis.asset;
    return '''
Análise educativa de ${asset.ticker} (${asset.name}):

Decisão simulada: ${analysis.decision.label}
Confiança: ${Formatters.confidence(analysis.confidence)}
Risco: ${analysis.riskLevel.label}

Resumo: ${analysis.summary}

Pontos positivos: ${analysis.positivePoints.join(', ')}.
Pontos de atenção: ${analysis.cautionPoints.join(', ')}.

Conteúdo educativo e simulado. Não é recomendação de investimento.
''';
  }
}
