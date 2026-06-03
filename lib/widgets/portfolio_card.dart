import 'package:flutter/material.dart';

import '../enums/market_type.dart';
import '../models/portfolio_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'analysis_card.dart';

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({super.key, required this.item, this.onRemove});

  final PortfolioItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final resultColor = item.profitLoss >= 0 ? AppColors.teal : AppColors.red;

    return DandiCard(
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
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
                  '${item.quantity.toStringAsFixed(2)} un. • entrada ${Formatters.compactMoney(item.entryPrice, item.asset.currency)}',
                  style: AppTextStyles.muted,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compactMoney(item.currentValue, item.asset.currency),
                style: AppTextStyles.mono.copyWith(fontSize: 13),
              ),
              Text(
                '${Formatters.compactMoney(item.profitLoss, item.asset.currency)} (${Formatters.percent(item.profitLossPercent, signed: true)})',
                style: TextStyle(color: resultColor, fontSize: 12),
              ),
            ],
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
