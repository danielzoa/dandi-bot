import 'package:flutter/foundation.dart';
import '../enums/agent_role.dart';
import '../enums/ai_provider.dart';
import '../enums/asset_decision.dart';
import '../enums/market_type.dart';
import '../enums/risk_level.dart';
import '../mock/mock_analyses.dart';
import '../mock/mock_assets.dart';
import '../models/agent_opinion.dart';
import '../models/analysis_result.dart';
import '../models/asset.dart';
import '../models/crypto_analysis.dart';
import '../models/stock_analysis.dart';
import '../utils/ticker_detector.dart';
import 'gemini_api_service.dart';

class MockAnalysisService {
  final _geminiApi = GeminiApiService();

  MarketType detectMarket(String ticker) => TickerDetector.detect(ticker);

  Future<AnalysisResult> analyze(
    String ticker, {
    Asset? asset,
    String? apiKey,
  }) async {
    final normalized = TickerDetector.normalize(ticker);
    final market = TickerDetector.detect(normalized);

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final mockAsset = asset ??
            MockAssets.find(normalized) ??
            MockAssets.generic(normalized);
        final assetData = {
          'ticker': mockAsset.ticker,
          'name': mockAsset.name,
          'simulatedPrice': mockAsset.simulatedPrice,
          'marketType': mockAsset.marketType.name,
        };

        final json = await _geminiApi.analyzeTicker(
          ticker: normalized,
          marketType: market.name,
          apiKey: apiKey,
          assetData: assetData,
        );

        final now = DateTime.now();

        // Map opinions
        final rawOpinions = json['agentOpinions'] as List<dynamic>;
        final agentOpinions = rawOpinions.map((item) {
          final map = item as Map<String, dynamic>;
          return AgentOpinion(
            role: AgentRole.values.byName(map['role'] as String),
            agentName: map['agentName'] as String,
            message: map['message'] as String,
            suggestion: map['suggestion'] == null
                ? null
                : AssetDecision.values.byName(map['suggestion'] as String),
            riskAssessment: map['riskAssessment'] == null
                ? null
                : RiskLevel.values.byName(map['riskAssessment'] as String),
            provider: AiProvider.geminiFlash,
          );
        }).toList();

        final positivePoints = List<String>.from(json['positivePoints'] as List);
        final cautionPoints = List<String>.from(json['cautionPoints'] as List);
        final indicators = Map<String, String>.from(json['indicators'] as Map);

        if (market == MarketType.crypto) {
          return CryptoAnalysis(
            asset: mockAsset,
            summary: json['summary'] as String,
            positivePoints: positivePoints,
            cautionPoints: cautionPoints,
            technicalAnalysis: json['technicalAnalysis'] as String,
            cryptoMetrics:
                json['cryptoMetrics'] ?? json['fundamentalsText'] as String,
            macroAnalysis: json['macroAnalysis'] as String,
            regulatoryRisk: json['regulatoryRisk'] as String,
            sentiment: json['sentiment'] as String,
            decision: AssetDecision.values.byName(json['decision'] as String),
            confidence: (json['confidence'] as num).toDouble(),
            riskLevel: RiskLevel.values.byName(json['riskLevel'] as String),
            agentOpinions: agentOpinions,
            indicators: indicators,
            createdAt: now,
          );
        } else {
          return StockAnalysis(
            asset: mockAsset,
            summary: json['summary'] as String,
            positivePoints: positivePoints,
            cautionPoints: cautionPoints,
            technicalAnalysis: json['technicalAnalysis'] as String,
            fundamentalAnalysis: json['fundamentalsText'] as String,
            dividendAnalysis: json['dividendText'] as String?,
            macroAnalysis: json['macroAnalysis'] as String,
            regulatoryRisk: json['regulatoryRisk'] as String,
            sentiment: json['sentiment'] as String,
            decision: AssetDecision.values.byName(json['decision'] as String),
            confidence: (json['confidence'] as num).toDouble(),
            riskLevel: RiskLevel.values.byName(json['riskLevel'] as String),
            agentOpinions: agentOpinions,
            indicators: indicators,
            createdAt: now,
          );
        }
      } catch (e) {
        // Fallback to mock on error
        debugPrint('Error in Gemini analysis: $e. Falling back to MockAnalyses.');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockAnalyses.create(
      normalized,
      assetOverride: asset,
    );
  }
}
