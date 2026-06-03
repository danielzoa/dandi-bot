import '../enums/agent_role.dart';
import '../enums/ai_provider.dart';
import '../enums/asset_decision.dart';
import '../enums/market_type.dart';
import '../enums/risk_level.dart';
import '../models/agent_opinion.dart';
import '../models/analysis_result.dart';
import '../models/asset.dart';
import '../models/crypto_analysis.dart';
import '../models/stock_analysis.dart';
import 'mock_assets.dart';

abstract final class MockAnalyses {
  static AnalysisResult create(String ticker, {Asset? assetOverride}) {
    final asset =
        assetOverride ?? MockAssets.find(ticker) ?? MockAssets.generic(ticker);
    final seed = _seeds[asset.ticker] ?? _genericSeed(asset);
    final now = DateTime.now();

    if (asset.marketType == MarketType.crypto) {
      return CryptoAnalysis(
        asset: asset,
        summary: seed.summary,
        positivePoints: seed.positivePoints,
        cautionPoints: seed.cautionPoints,
        technicalAnalysis: seed.technical,
        cryptoMetrics: seed.fundamentals,
        macroAnalysis: seed.macro,
        regulatoryRisk: seed.regulatory,
        sentiment: seed.sentiment,
        decision: seed.decision,
        confidence: seed.confidence,
        riskLevel: seed.riskLevel,
        agentOpinions: _agents(asset, seed),
        indicators: seed.indicators,
        createdAt: now,
      );
    }

    return StockAnalysis(
      asset: asset,
      summary: seed.summary,
      positivePoints: seed.positivePoints,
      cautionPoints: seed.cautionPoints,
      technicalAnalysis: seed.technical,
      fundamentalAnalysis: seed.fundamentals,
      dividendAnalysis: seed.dividends,
      macroAnalysis: seed.macro,
      regulatoryRisk: seed.regulatory,
      sentiment: seed.sentiment,
      decision: seed.decision,
      confidence: seed.confidence,
      riskLevel: seed.riskLevel,
      agentOpinions: _agents(asset, seed),
      indicators: seed.indicators,
      createdAt: now,
    );
  }

  static final _seeds = <String, _AnalysisSeed>{
    'PETR4.SA': _AnalysisSeed(
      decision: AssetDecision.hold,
      confidence: 0.72,
      riskLevel: RiskLevel.high,
      summary:
          'PETR4 apresenta fundamentos sólidos e boa geração de caixa, porém risco político e volatilidade do petróleo impactam a leitura.',
      positivePoints: [
        'Dividendos atrativos',
        'Geração de caixa forte',
        'Petróleo em alta',
      ],
      cautionPoints: [
        'Risco político elevado',
        'Interferência estatal',
        'Volatilidade cambial',
      ],
      technical:
          'Tendência neutra no curto prazo, com resistência simulada em R\$ 38,50.',
      fundamentals:
          'Empresa sólida, valuation atrativo e geração de caixa consistente.',
      dividends:
          'Dividend yield elevado, mas dependente do ciclo de caixa e política de distribuição.',
      macro:
          'Preço do petróleo e câmbio seguem como vetores centrais para o ativo.',
      regulatory: 'Risco alto por sensibilidade a decisões governamentais.',
      sentiment: 'Sentimento neutro, com fluxo comprador moderado.',
      indicators: {
        'P/L': '4,32',
        'P/VP': '1,12',
        'Div. Yield': '18,45%',
        'ROE': '23,12%',
        'Margem': '18,23%',
        'Dívida/EBITDA': '1,1x',
      },
      bull: 'Geração de caixa forte e dividendos acima da média histórica.',
      bear:
          'Risco político elevado e interferência estatal são riscos estruturais.',
    ),
    'VALE3.SA': _AnalysisSeed(
      decision: AssetDecision.underweight,
      confidence: 0.65,
      riskLevel: RiskLevel.high,
      summary:
          'VALE3 mantém escala global e caixa robusto, mas depende de China, minério e câmbio em cenário volátil.',
      positivePoints: ['Líder global em minério', 'Geração de caixa robusta'],
      cautionPoints: [
        'Dependência da China',
        'Risco ambiental',
        'Volatilidade do dólar',
      ],
      technical:
          'Preço perdeu força no curto prazo e opera abaixo de médias relevantes.',
      fundamentals: 'Margens fortes, mas sensíveis ao ciclo de commodities.',
      dividends:
          'Dividendos historicamente relevantes, com oscilação conforme preço do minério.',
      macro: 'China e demanda industrial global dominam a tese.',
      regulatory: 'Risco ambiental e licenciamento seguem pontos de atenção.',
      sentiment:
          'Sentimento defensivo, com investidores aguardando sinais da China.',
      indicators: {
        'P/L': '5,80',
        'P/VP': '1,45',
        'Div. Yield': '12,30%',
        'ROE': '25,10%',
        'Margem': '22,50%',
        'Dívida/EBITDA': '0,9x',
      },
      bull:
          'Escala global e balanço resiliente favorecem a tese em ciclo positivo.',
      bear: 'A dependência de China e riscos ambientais reduzem a assimetria.',
    ),
    'ITUB4.SA': _AnalysisSeed(
      decision: AssetDecision.overweight,
      confidence: 0.74,
      riskLevel: RiskLevel.medium,
      summary:
          'ITUB4 combina rentabilidade recorrente, ROE elevado e gestão eficiente, com atenção à inadimplência futura.',
      positivePoints: ['Banco sólido', 'ROE alto', 'Rentabilidade consistente'],
      cautionPoints: [
        'Selic elevada pressiona crédito',
        'Inadimplência futura',
      ],
      technical:
          'Tendência levemente positiva, com suporte simulado em R\$ 32,20.',
      fundamentals:
          'Qualidade operacional e eficiência sustentam prêmio frente ao setor.',
      dividends:
          'Distribuição regular, sem depender de eventos extraordinários.',
      macro: 'Juros e ciclo de crédito são os principais vetores.',
      regulatory: 'Risco regulatório médio para bancos sistêmicos.',
      sentiment: 'Sentimento construtivo em bancos de alta qualidade.',
      indicators: {
        'P/L': '8,50',
        'P/VP': '2,10',
        'Div. Yield': '8,20%',
        'ROE': '21,50%',
        'Margem': '28,40%',
        'Dívida/EBITDA': 'N/A',
      },
      bull: 'ROE elevado e execução consistente favorecem exposição moderada.',
      bear: 'Valuation menos descontado pode limitar ganhos no curto prazo.',
    ),
    'BBAS3.SA': _AnalysisSeed(
      decision: AssetDecision.hold,
      confidence: 0.70,
      riskLevel: RiskLevel.high,
      summary:
          'BBAS3 tem lucro crescente e dividendos generosos, mas carrega desconto por exposição estatal e crédito rural.',
      positivePoints: [
        'Dividendos generosos',
        'Lucro crescente',
        'Base de clientes ampla',
      ],
      cautionPoints: [
        'Exposição estatal',
        'Risco político',
        'Crédito rural concentrado',
      ],
      technical: 'Movimento lateral com suporte simulado em R\$ 24,80.',
      fundamentals:
          'Lucro robusto e eficiência melhorando, com desconto de governança.',
      dividends: 'Perfil de proventos forte em simulação.',
      macro: 'Juros, agro e crédito direcionado afetam a leitura.',
      regulatory: 'Risco alto por influência estatal.',
      sentiment: 'Sentimento neutro, equilibrando dividendos e governança.',
      indicators: {
        'P/L': '4,90',
        'P/VP': '0,92',
        'Div. Yield': '10,80%',
        'ROE': '19,30%',
        'Margem': '24,10%',
        'Dívida/EBITDA': 'N/A',
      },
      bull: 'Lucro e dividendos compensam parte do desconto de risco.',
      bear: 'Influência estatal pode pressionar múltiplos por mais tempo.',
    ),
    'WEGE3.SA': _AnalysisSeed(
      decision: AssetDecision.underweight,
      confidence: 0.68,
      riskLevel: RiskLevel.medium,
      summary:
          'WEGE3 é empresa excelente e globalizada, mas o preço simulado já embute boa parte do crescimento esperado.',
      positivePoints: [
        'Empresa excelente',
        'Expansão internacional',
        'Qualidade de gestão',
      ],
      cautionPoints: ['Valuation muito elevado', 'Crescimento já precificado'],
      technical:
          'Ativo em tendência positiva, porém esticado em relação às médias.',
      fundamentals: 'Qualidade superior, margens consistentes e execução rara.',
      dividends: 'Dividendos menores, com foco maior em crescimento.',
      macro: 'Ciclo industrial global e câmbio influenciam receitas.',
      regulatory: 'Risco regulatório baixo a médio.',
      sentiment: 'Sentimento positivo, mas com alerta de valuation.',
      indicators: {
        'P/L': '32,40',
        'P/VP': '9,10',
        'Div. Yield': '1,60%',
        'ROE': '27,80%',
        'Margem': '18,70%',
        'Dívida/EBITDA': '0,3x',
      },
      bull: 'Qualidade operacional justifica prêmio estrutural.',
      bear: 'Preço elevado reduz margem de segurança.',
    ),
    'B3SA3.SA': _AnalysisSeed(
      decision: AssetDecision.hold,
      confidence: 0.66,
      riskLevel: RiskLevel.medium,
      summary:
          'B3SA3 é infraestrutura financeira relevante, sensível a volumes de mercado, juros e competição em serviços.',
      positivePoints: [
        'Modelo escalável',
        'Geração de caixa recorrente',
        'Baixa alavancagem',
      ],
      cautionPoints: [
        'Volumes cíclicos',
        'Concorrência potencial',
        'Juros altos reduzem apetite a risco',
      ],
      technical:
          'Tendência neutra, com melhora se romper R\$ 13,40 em simulação.',
      fundamentals: 'Margens elevadas e posição competitiva forte.',
      dividends:
          'Distribuição consistente, mas ligada ao volume de negociação.',
      macro: 'Mercado de capitais aquecido melhora receitas.',
      regulatory: 'Risco médio por mudanças competitivas e regras de mercado.',
      sentiment: 'Sentimento neutro com viés positivo.',
      indicators: {
        'P/L': '14,20',
        'P/VP': '3,10',
        'Div. Yield': '5,20%',
        'ROE': '18,60%',
        'Margem': '39,40%',
        'Dívida/EBITDA': '1,4x',
      },
      bull: 'Infraestrutura essencial e margens fortes sustentam qualidade.',
      bear: 'Volumes fracos e competição podem limitar expansão.',
    ),
    'MGLU3.SA': _AnalysisSeed(
      decision: AssetDecision.sell,
      confidence: 0.60,
      riskLevel: RiskLevel.extreme,
      summary:
          'MGLU3 segue como caso especulativo no varejo, com alto risco por margens apertadas e ambiente competitivo.',
      positivePoints: [
        'Marca conhecida',
        'Potencial de recuperação operacional',
      ],
      cautionPoints: [
        'Margens pressionadas',
        'Endividamento sensível',
        'Competição intensa',
      ],
      technical: 'Tendência fraca e volatilidade elevada no curto prazo.',
      fundamentals:
          'Fundamentos ainda frágeis em simulação, exigindo melhora operacional.',
      dividends:
          'Sem atratividade relevante de dividendos no cenário simulado.',
      macro: 'Juros e consumo das famílias são determinantes.',
      regulatory: 'Risco regulatório baixo, mas risco competitivo alto.',
      sentiment: 'Sentimento especulativo e instável.',
      indicators: {
        'P/L': 'N/A',
        'P/VP': '1,80',
        'Div. Yield': '0,00%',
        'ROE': '-8,40%',
        'Margem': '-2,10%',
        'Dívida/EBITDA': '3,8x',
      },
      bull: 'Qualquer melhora de margem pode gerar recuperação relevante.',
      bear: 'Risco operacional e financeiro segue elevado.',
    ),
    'AAPL': _usSeed(
      decision: AssetDecision.hold,
      confidence: 0.76,
      riskLevel: RiskLevel.medium,
      summary:
          'AAPL tem ecossistema premium e serviços crescendo, mas hardware desacelerado limita surpresa no curto prazo.',
      positives: ['Ecossistema forte', 'Serviços crescendo', 'Marca premium'],
      cautions: [
        'Crescimento de hardware desacelerando',
        'Dependência de iPhone',
      ],
      bull: 'Base instalada e serviços sustentam previsibilidade de caixa.',
      bear: 'Valuation exige retomada mais clara de crescimento.',
    ),
    'MSFT': _usSeed(
      decision: AssetDecision.overweight,
      confidence: 0.74,
      riskLevel: RiskLevel.medium,
      summary:
          'MSFT combina Azure, software corporativo e IA integrada, com valuation exigente como principal alerta.',
      positives: [
        'Azure em crescimento',
        'IA integrada',
        'Software corporativo dominante',
      ],
      cautions: ['Valuation esticado', 'Concorrência em cloud'],
      bull: 'Cloud e IA ampliam o crescimento com alta recorrência.',
      bear: 'Expectativas elevadas deixam pouco espaço para erro.',
    ),
    'NVDA': _usSeed(
      decision: AssetDecision.overweight,
      confidence: 0.70,
      riskLevel: RiskLevel.high,
      summary:
          'NVDA lidera chips de IA e cresce rápido, mas valuation e ciclicidade tornam a posição mais arriscada.',
      positives: ['Domínio em chips de IA', 'Crescimento de receita explosivo'],
      cautions: ['Valuation elevadíssimo', 'Ciclicidade de semicondutores'],
      bull: 'Demanda por IA sustenta crescimento acima da média.',
      bear: 'Qualquer desaceleração pode gerar ajuste forte.',
    ),
    'TSLA': _usSeed(
      decision: AssetDecision.underweight,
      confidence: 0.61,
      riskLevel: RiskLevel.high,
      summary:
          'TSLA mantém tese de longo prazo em EVs, energia e autonomia, mas margens e competição pesam no curto prazo.',
      positives: ['Liderança em EVs', 'Energia e autonomia como teses'],
      cautions: [
        'Competição intensa',
        'Margens pressionadas',
        'Dependência de execução',
      ],
      bull: 'Opcionalidade em autonomia ainda pode reprecificar a tese.',
      bear: 'Competição reduz poder de preço e pressiona margens.',
    ),
    'AMZN': _usSeed(
      decision: AssetDecision.hold,
      confidence: 0.71,
      riskLevel: RiskLevel.medium,
      summary:
          'AMZN tem AWS dominante e marketplace global, com melhora de margens, mas enfrenta risco regulatório.',
      positives: ['AWS dominante', 'Marketplace global', 'Margens em expansão'],
      cautions: ['Regulatório anti-truste', 'Competição em cloud'],
      bull: 'AWS e eficiência operacional sustentam expansão de lucro.',
      bear: 'Reguladores podem limitar algumas alavancas de crescimento.',
    ),
    'GOOGL': _usSeed(
      decision: AssetDecision.hold,
      confidence: 0.73,
      riskLevel: RiskLevel.medium,
      summary:
          'GOOGL segue forte em publicidade, GCP e IA, com risco regulatório e dependência de anúncios no radar.',
      positives: ['Publicidade digital', 'GCP crescendo', 'IA no core'],
      cautions: ['Regulatório', 'Dependência de ad revenue'],
      bull: 'Dados, busca e IA formam vantagem competitiva relevante.',
      bear: 'Pressão antitruste pode afetar múltiplos.',
    ),
    'META': _usSeed(
      decision: AssetDecision.overweight,
      confidence: 0.72,
      riskLevel: RiskLevel.medium,
      summary:
          'META tem publicidade social dominante, Reels e IA integrada, com metaverso e regulação como alertas.',
      positives: [
        'Publicidade social dominante',
        'Reels em alta',
        'IA integrada',
      ],
      cautions: ['Metaverso sem retorno claro', 'Regulatório europeu'],
      bull: 'Eficiência e IA melhoram monetização do ecossistema.',
      bear: 'Investimentos de longo prazo podem pressionar resultados.',
    ),
    'BTC-USD': _cryptoSeed(
      decision: AssetDecision.hold,
      confidence: 0.67,
      riskLevel: RiskLevel.high,
      summary:
          'BTC-USD segue como reserva digital simulada, com adoção institucional, mas volatilidade e regulação elevam o risco.',
      positives: ['Reserva digital', 'Adoção institucional', 'Supply fixo'],
      cautions: [
        'Volatilidade extrema',
        'Ciclos de mercado',
        'Regulatório global',
      ],
      metrics: 'Volatilidade alta, dominância de 52% e liquidez muito alta.',
      bull: 'Oferta limitada e entrada institucional sustentam a tese.',
      bear: 'Ciclos de queda podem ser longos e intensos.',
    ),
    'ETH-USD': _cryptoSeed(
      decision: AssetDecision.overweight,
      confidence: 0.69,
      riskLevel: RiskLevel.high,
      summary:
          'ETH-USD combina ecossistema DeFi, NFTs e L2s, com risco de concorrência e enquadramento regulatório.',
      positives: ['Ecossistema DeFi/NFT/L2', 'Smart contracts dominantes'],
      cautions: ['Concorrência de L1s', 'Risco regulatório de securities'],
      metrics:
          'Volatilidade alta, liquidez muito alta e tendência positiva em L2s.',
      bull: 'Uso real de rede e ecossistema ampliam utilidade.',
      bear: 'Taxas, concorrência e regulação podem reduzir prêmio.',
    ),
    'SOL-USD': _cryptoSeed(
      decision: AssetDecision.underweight,
      confidence: 0.58,
      riskLevel: RiskLevel.extreme,
      summary:
          'SOL-USD tem velocidade e taxas baixas, mas risco extremo por histórico técnico, centralização e volatilidade.',
      positives: ['Velocidade', 'Baixa taxa', 'Crescimento de ecossistema'],
      cautions: [
        'Histórico de outages',
        'Centralização',
        'Extrema volatilidade',
      ],
      metrics:
          'Volatilidade extrema, liquidez alta e tendência de curto prazo especulativa.',
      bull: 'Experiência rápida atrai apps e usuários em ciclos fortes.',
      bear: 'Histórico de instabilidade aumenta risco de cauda.',
    ),
    'BNB-USD': _cryptoSeed(
      decision: AssetDecision.hold,
      confidence: 0.62,
      riskLevel: RiskLevel.high,
      summary:
          'BNB-USD tem utilidade no ecossistema Binance, mas concentração e risco regulatório reduzem a visibilidade.',
      positives: ['Ecossistema Binance forte', 'Uso em BNB Chain'],
      cautions: ['Risco regulatório Binance', 'Centralização elevada'],
      metrics:
          'Volatilidade alta, liquidez alta e dependência elevada do ecossistema Binance.',
      bull: 'Uso recorrente em taxas e rede cria demanda estrutural.',
      bear: 'Concentração em uma plataforma aumenta risco específico.',
    ),
    'XRP-USD': _cryptoSeed(
      decision: AssetDecision.underweight,
      confidence: 0.59,
      riskLevel: RiskLevel.high,
      summary:
          'XRP-USD oferece velocidade em pagamentos, mas depende da Ripple e carrega histórico jurídico relevante.',
      positives: [
        'Adoção institucional em pagamentos',
        'Velocidade de transação',
      ],
      cautions: ['Risco jurídico histórico', 'Dependência da Ripple'],
      metrics:
          'Volatilidade alta, liquidez média-alta e sentimento sensível a notícias jurídicas.',
      bull: 'Uso em pagamentos pode ganhar tração institucional.',
      bear: 'Dependência corporativa reduz descentralização percebida.',
    ),
  };

  static _AnalysisSeed _usSeed({
    required AssetDecision decision,
    required double confidence,
    required RiskLevel riskLevel,
    required String summary,
    required List<String> positives,
    required List<String> cautions,
    required String bull,
    required String bear,
  }) {
    return _AnalysisSeed(
      decision: decision,
      confidence: confidence,
      riskLevel: riskLevel,
      summary: summary,
      positivePoints: positives,
      cautionPoints: cautions,
      technical:
          'Preço em tendência neutra a positiva, com suporte técnico respeitado no curto prazo.',
      fundamentals:
          'Empresa com geração de caixa relevante, vantagem competitiva e escala global.',
      dividends:
          'Proventos existem, mas a tese principal é qualidade e crescimento.',
      macro:
          'Juros dos EUA, dólar e apetite por tecnologia influenciam o ativo.',
      regulatory:
          'Risco regulatório médio, especialmente em tecnologia e competição.',
      sentiment:
          'Sentimento de mercado construtivo, com seletividade por valuation.',
      indicators: {
        'P/L': '28,40',
        'P/VP': '9,30',
        'Div. Yield': '0,80%',
        'ROE': '31,20%',
        'Margem': '24,70%',
        'Dívida/EBITDA': '0,8x',
      },
      bull: bull,
      bear: bear,
    );
  }

  static _AnalysisSeed _cryptoSeed({
    required AssetDecision decision,
    required double confidence,
    required RiskLevel riskLevel,
    required String summary,
    required List<String> positives,
    required List<String> cautions,
    required String metrics,
    required String bull,
    required String bear,
  }) {
    return _AnalysisSeed(
      decision: decision,
      confidence: confidence,
      riskLevel: riskLevel,
      summary: summary,
      positivePoints: positives,
      cautionPoints: cautions,
      technical:
          'Movimento de curto prazo volátil, com forte dependência de fluxo e liquidez global.',
      fundamentals: metrics,
      dividends: null,
      macro: 'Liquidez global, dólar e ciclos de risco afetam a classe cripto.',
      regulatory:
          'Regulação global permanece em evolução e pode alterar a tese rapidamente.',
      sentiment:
          'Sentimento altamente sensível a notícias e fluxo institucional.',
      indicators: {
        'Volatilidade': riskLevel == RiskLevel.extreme ? 'Extrema' : 'Alta',
        'Dominância': decision == AssetDecision.hold ? '52%' : 'Setorial',
        'Sentimento': 'Neutro+',
        'Risco Reg.': riskLevel.label,
        'Liquidez': 'Alta',
        'Tendência CP': 'Volátil',
      },
      bull: bull,
      bear: bear,
    );
  }

  static _AnalysisSeed _genericSeed(Asset asset) {
    return _AnalysisSeed(
      decision: AssetDecision.hold,
      confidence: 0.55,
      riskLevel: RiskLevel.high,
      summary:
          'Ativo não identificado. Análise genérica educativa simulada, sem dados reais de mercado.',
      positivePoints: [
        'Ticker reconhecido para simulação',
        'Pode ser acompanhado no histórico',
      ],
      cautionPoints: [
        'Sem dados mockados específicos',
        'Risco alto por baixa cobertura',
      ],
      technical: 'Sem histórico suficiente no mock. Leitura técnica neutra.',
      fundamentals: asset.marketType == MarketType.crypto
          ? 'Métricas cripto indisponíveis no mock para este ativo.'
          : 'Fundamentos indisponíveis no mock para este ativo.',
      dividends: asset.marketType == MarketType.crypto
          ? null
          : 'Dividendos/JCP indisponíveis para este ativo simulado.',
      macro: 'Cenário macro tratado de forma genérica.',
      regulatory:
          'Risco regulatório classificado como alto por falta de cobertura.',
      sentiment: 'Sentimento neutro por falta de dados específicos.',
      indicators: asset.marketType == MarketType.crypto
          ? {
              'Volatilidade': 'Alta',
              'Dominância': 'N/A',
              'Sentimento': 'Neutro',
              'Risco Reg.': 'Alto',
              'Liquidez': 'N/A',
              'Tendência CP': 'Neutra',
            }
          : {
              'P/L': 'N/A',
              'P/VP': 'N/A',
              'Div. Yield': 'N/A',
              'ROE': 'N/A',
              'Margem': 'N/A',
              'Dívida/EBITDA': 'N/A',
            },
      bull: 'Pode valer monitoramento se houver tese externa bem fundamentada.',
      bear:
          'Sem dados específicos, a decisão simulada deve permanecer conservadora.',
    );
  }

  static List<AgentOpinion> _agents(Asset asset, _AnalysisSeed seed) {
    final dividendMessage = asset.marketType == MarketType.crypto
        ? 'Não há dividendos em cripto; o foco simulado fica em liquidez, rede e volatilidade.'
        : seed.dividends ??
              'Dividendos sem leitura específica nesta simulação.';

    return [
      AgentOpinion(
        role: AgentRole.bullResearcher,
        agentName: 'Agente Bull',
        message: seed.bull,
        suggestion: seed.decision == AssetDecision.sell
            ? AssetDecision.underweight
            : AssetDecision.overweight,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.bearResearcher,
        agentName: 'Agente Bear',
        message: seed.bear,
        suggestion: seed.riskLevel == RiskLevel.extreme
            ? AssetDecision.sell
            : AssetDecision.underweight,
        riskAssessment: seed.riskLevel,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.technicalAnalyst,
        agentName: 'Analista Técnico',
        message: seed.technical,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.fundamentalsAnalyst,
        agentName: asset.marketType == MarketType.crypto
            ? 'Analista de Métricas Cripto'
            : 'Analista Fundamentalista',
        message: seed.fundamentals,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.fundamentalsAnalyst,
        agentName: asset.marketType == MarketType.crypto
            ? 'Analista de Liquidez'
            : 'Analista de Dividendos/JCP',
        message: dividendMessage,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.newsAnalyst,
        agentName: 'Analista Macroeconômico',
        message: seed.macro,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.newsAnalyst,
        agentName: 'Analista de Risco Regulatório',
        message: seed.regulatory,
        riskAssessment: seed.riskLevel,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.riskManager,
        agentName: 'Gestor de Risco',
        message:
            'Risco classificado como ${seed.riskLevel.label.toUpperCase()} no cenário simulado.',
        riskAssessment: seed.riskLevel,
        provider: AiProvider.mock,
      ),
      AgentOpinion(
        role: AgentRole.trader,
        agentName: 'Dandi Bot',
        message:
            'Decisão simulada: ${seed.decision.label} com ${(seed.confidence * 100).round()}% de confiança.',
        suggestion: seed.decision,
        riskAssessment: seed.riskLevel,
        provider: AiProvider.mock,
      ),
    ];
  }
}

class _AnalysisSeed {
  const _AnalysisSeed({
    required this.decision,
    required this.confidence,
    required this.riskLevel,
    required this.summary,
    required this.positivePoints,
    required this.cautionPoints,
    required this.technical,
    required this.fundamentals,
    required this.dividends,
    required this.macro,
    required this.regulatory,
    required this.sentiment,
    required this.indicators,
    required this.bull,
    required this.bear,
  });

  final AssetDecision decision;
  final double confidence;
  final RiskLevel riskLevel;
  final String summary;
  final List<String> positivePoints;
  final List<String> cautionPoints;
  final String technical;
  final String fundamentals;
  final String? dividends;
  final String macro;
  final String regulatory;
  final String sentiment;
  final Map<String, String> indicators;
  final String bull;
  final String bear;
}
