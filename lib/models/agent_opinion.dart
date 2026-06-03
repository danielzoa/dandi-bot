import '../enums/agent_role.dart';
import '../enums/ai_provider.dart';
import '../enums/asset_decision.dart';
import '../enums/risk_level.dart';

class AgentOpinion {
  const AgentOpinion({
    required this.role,
    required this.agentName,
    required this.message,
    this.suggestion,
    this.riskAssessment,
    required this.provider,
  });

  final AgentRole role;
  final String agentName;
  final String message;
  final AssetDecision? suggestion;
  final RiskLevel? riskAssessment;
  final AiProvider provider;

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'agentName': agentName,
    'message': message,
    'suggestion': suggestion?.name,
    'riskAssessment': riskAssessment?.name,
    'provider': provider.name,
  };

  factory AgentOpinion.fromJson(Map<String, dynamic> json) {
    return AgentOpinion(
      role: AgentRole.values.byName(json['role'] as String),
      agentName: json['agentName'] as String,
      message: json['message'] as String,
      suggestion: json['suggestion'] == null
          ? null
          : AssetDecision.values.byName(json['suggestion'] as String),
      riskAssessment: json['riskAssessment'] == null
          ? null
          : RiskLevel.values.byName(json['riskAssessment'] as String),
      provider: AiProvider.values.byName(json['provider'] as String),
    );
  }
}
