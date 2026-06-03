import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../enums/asset_decision.dart';
import '../../enums/market_type.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/decision_badge.dart';
import '../../widgets/risk_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  MarketType? _marketFilter;
  AssetDecision? _decisionFilter;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final filtered = controller.analysisHistory.where((item) {
      final marketOk =
          _marketFilter == null || item.asset.marketType == _marketFilter;
      final decisionOk =
          _decisionFilter == null || item.decision == _decisionFilter;
      return marketOk && decisionOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico de análises', style: AppTextStyles.display),
        const SizedBox(height: 6),
        Text(
          'Análises simuladas salvas localmente no aparelho.',
          style: AppTextStyles.muted,
        ),
        const SizedBox(height: 18),
        DandiCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final marketFilter = DropdownButtonFormField<MarketType?>(
                initialValue: _marketFilter,
                decoration: const InputDecoration(labelText: 'Mercado'),
                items: [
                  const DropdownMenuItem<MarketType?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  for (final market in MarketType.values)
                    DropdownMenuItem<MarketType?>(
                      value: market,
                      child: Text(market.label),
                    ),
                ],
                onChanged: (value) => setState(() => _marketFilter = value),
              );
              final decisionFilter = DropdownButtonFormField<AssetDecision?>(
                initialValue: _decisionFilter,
                decoration: const InputDecoration(labelText: 'Decisão'),
                items: [
                  const DropdownMenuItem<AssetDecision?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  for (final decision in AssetDecision.values)
                    DropdownMenuItem<AssetDecision?>(
                      value: decision,
                      child: Text(decision.filterLabel),
                    ),
                ],
                onChanged: (value) => setState(() => _decisionFilter = value),
              );

              if (compact) {
                return Column(
                  children: [
                    marketFilter,
                    const SizedBox(height: 12),
                    decisionFilter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: marketFilter),
                  const SizedBox(width: 12),
                  Expanded(child: decisionFilter),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          DandiCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.blueBright,
                      size: 54,
                    ),
                    const SizedBox(height: 12),
                    Text('Nenhuma análise ainda.', style: AppTextStyles.title),
                    const SizedBox(height: 6),
                    Text(
                      'Comece analisando um ativo na Home.',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          for (final item in filtered) ...[
            DandiCard(
              onTap: () async {
                await controller.analyzeTicker(item.asset.ticker);
                if (!context.mounted) return;
                context.go('$routeAnalysis?ticker=${item.asset.ticker}');
              },
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          item.asset.logoEmoji ?? item.asset.marketType.icon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.asset.ticker, style: AppTextStyles.mono),
                        Text(
                          '${item.asset.name} • ${Formatters.dateTime(item.createdAt)}',
                          style: AppTextStyles.muted,
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DecisionBadge(decision: item.decision),
                      Text(
                        Formatters.confidence(item.confidence),
                        style: AppTextStyles.mono,
                      ),
                      RiskBadge(riskLevel: item.riskLevel),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
