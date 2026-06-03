import '../enums/asset_decision.dart';
import '../enums/risk_level.dart';
import 'agent_opinion.dart';
import 'analysis_result.dart';
import 'asset.dart';

class CryptoAnalysis implements AnalysisResult {
  const CryptoAnalysis({
    required this.asset,
    required this.summary,
    required this.positivePoints,
    required this.cautionPoints,
    required this.technicalAnalysis,
    required this.cryptoMetrics,
    required this.macroAnalysis,
    required this.regulatoryRisk,
    required this.sentiment,
    required this.decision,
    required this.confidence,
    required this.riskLevel,
    required this.agentOpinions,
    required this.indicators,
    required this.createdAt,
  });

  @override
  final Asset asset;
  @override
  final String summary;
  @override
  final List<String> positivePoints;
  @override
  final List<String> cautionPoints;
  @override
  final String technicalAnalysis;
  final String cryptoMetrics;
  @override
  final String macroAnalysis;
  @override
  final String regulatoryRisk;
  @override
  final String sentiment;
  @override
  final AssetDecision decision;
  @override
  final double confidence;
  @override
  final RiskLevel riskLevel;
  @override
  final List<AgentOpinion> agentOpinions;
  @override
  final Map<String, String> indicators;
  @override
  final DateTime createdAt;

  @override
  String get type => 'crypto';

  @override
  String get fundamentalsText => cryptoMetrics;

  @override
  String? get dividendText => null;

  @override
  CryptoAnalysis copyWithAsset(Asset asset) {
    return CryptoAnalysis(
      asset: asset,
      summary: summary,
      positivePoints: positivePoints,
      cautionPoints: cautionPoints,
      technicalAnalysis: technicalAnalysis,
      cryptoMetrics: cryptoMetrics,
      macroAnalysis: macroAnalysis,
      regulatoryRisk: regulatoryRisk,
      sentiment: sentiment,
      decision: decision,
      confidence: confidence,
      riskLevel: riskLevel,
      agentOpinions: agentOpinions,
      indicators: indicators,
      createdAt: createdAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'asset': asset.toJson(),
    'summary': summary,
    'positivePoints': positivePoints,
    'cautionPoints': cautionPoints,
    'technicalAnalysis': technicalAnalysis,
    'cryptoMetrics': cryptoMetrics,
    'macroAnalysis': macroAnalysis,
    'regulatoryRisk': regulatoryRisk,
    'sentiment': sentiment,
    'decision': decision.name,
    'confidence': confidence,
    'riskLevel': riskLevel.name,
    'agentOpinions': agentOpinions.map((item) => item.toJson()).toList(),
    'indicators': indicators,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CryptoAnalysis.fromJson(Map<String, dynamic> json) {
    return CryptoAnalysis(
      asset: Asset.fromJson(json['asset'] as Map<String, dynamic>),
      summary: json['summary'] as String,
      positivePoints: List<String>.from(json['positivePoints'] as List),
      cautionPoints: List<String>.from(json['cautionPoints'] as List),
      technicalAnalysis: json['technicalAnalysis'] as String,
      cryptoMetrics: json['cryptoMetrics'] as String,
      macroAnalysis: json['macroAnalysis'] as String,
      regulatoryRisk: json['regulatoryRisk'] as String,
      sentiment: json['sentiment'] as String,
      decision: AssetDecision.values.byName(json['decision'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      riskLevel: RiskLevel.values.byName(json['riskLevel'] as String),
      agentOpinions: (json['agentOpinions'] as List)
          .map((item) => AgentOpinion.fromJson(item as Map<String, dynamic>))
          .toList(),
      indicators: Map<String, String>.from(json['indicators'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
