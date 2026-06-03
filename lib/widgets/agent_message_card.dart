import 'package:flutter/material.dart';

import '../enums/agent_role.dart';
import '../enums/ai_provider.dart';
import '../models/agent_opinion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'analysis_card.dart';
import 'decision_badge.dart';
import 'risk_badge.dart';

class AgentMessageCard extends StatelessWidget {
  const AgentMessageCard({super.key, required this.opinion});

  final AgentOpinion opinion;

  @override
  Widget build(BuildContext context) {
    final isDandi = opinion.role == AgentRole.trader;

    return DandiCard(
      highlight: isDandi,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (isDandi ? AppColors.blue : AppColors.surfaceAlt)
                .withValues(alpha: 0.82),
            child: Text(
              opinion.role.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        opinion.agentName,
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                    _ProviderChip(provider: opinion.provider),
                  ],
                ),
                const SizedBox(height: 8),
                Text(opinion.message, style: AppTextStyles.body),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (opinion.suggestion != null)
                      DecisionBadge(decision: opinion.suggestion!),
                    if (opinion.riskAssessment != null)
                      RiskBadge(riskLevel: opinion.riskAssessment!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({required this.provider});

  final AiProvider provider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(provider.label, style: AppTextStyles.muted),
      ),
    );
  }
}
