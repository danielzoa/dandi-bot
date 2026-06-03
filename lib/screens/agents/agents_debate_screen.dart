import 'package:flutter/material.dart';

import '../../models/analysis_result.dart';
import '../../services/app_controller.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/agent_message_card.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/dandi_bot_avatar.dart';

class AgentsDebateScreen extends StatefulWidget {
  const AgentsDebateScreen({super.key});

  @override
  State<AgentsDebateScreen> createState() => _AgentsDebateScreenState();
}

class _AgentsDebateScreenState extends State<AgentsDebateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = DandiScope.of(context);
      if (controller.selectedAnalysis == null &&
          !controller.isLoadingAnalysis) {
        controller.analyzeTicker('PETR4.SA');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final analysis = controller.selectedAnalysis;

    if (analysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const DandiBotAvatar(size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debate dos Agentes', style: AppTextStyles.display),
                  Text(
                    '${analysis.asset.ticker} • ${analysis.asset.name}',
                    style: AppTextStyles.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AgentsDebateList(analysis: analysis),
      ],
    );
  }
}

class AgentsDebateList extends StatelessWidget {
  const AgentsDebateList({super.key, required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final opinion in analysis.agentOpinions) ...[
          AgentMessageCard(opinion: opinion),
          const SizedBox(height: 12),
        ],
        DandiCard(
          child: Text(
            'As opiniões acima são simuladas e inspiradas na organização multiagente do TradingAgents, sem execução de ordens reais.',
            style: AppTextStyles.muted,
          ),
        ),
      ],
    );
  }
}
