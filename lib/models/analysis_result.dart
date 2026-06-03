import '../enums/asset_decision.dart';
import '../enums/risk_level.dart';
import 'agent_opinion.dart';
import 'asset.dart';

abstract class AnalysisResult {
  Asset get asset;
  String get summary;
  List<String> get positivePoints;
  List<String> get cautionPoints;
  String get technicalAnalysis;
  String get macroAnalysis;
  String get regulatoryRisk;
  String get sentiment;
  AssetDecision get decision;
  double get confidence;
  RiskLevel get riskLevel;
  List<AgentOpinion> get agentOpinions;
  Map<String, String> get indicators;
  DateTime get createdAt;
  String get type;
  String get fundamentalsText;
  String? get dividendText;
  AnalysisResult copyWithAsset(Asset asset);
  Map<String, dynamic> toJson();
}
