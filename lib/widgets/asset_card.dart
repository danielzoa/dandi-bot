import 'package:flutter/material.dart';

import '../enums/market_type.dart';
import '../models/asset.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'analysis_card.dart';

class AssetCard extends StatelessWidget {
  const AssetCard({super.key, required this.asset, this.onTap});

  final Asset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = asset.simulatedChangePercent >= 0
        ? AppColors.teal
        : AppColors.red;

    return DandiCard(
      onTap: onTap,
      child: Row(
        children: [
          _AssetAvatar(asset: asset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.ticker, style: AppTextStyles.mono),
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted,
                ),
                Text(
                  asset.quoteIsLive ? asset.quoteSource : 'Simulado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compactMoney(asset.simulatedPrice, asset.currency),
                style: AppTextStyles.mono.copyWith(fontSize: 13),
              ),
              Text(
                Formatters.percent(asset.simulatedChangePercent, signed: true),
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetAvatar extends StatelessWidget {
  const _AssetAvatar({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.42)),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Text(
            asset.logoEmoji ?? asset.marketType.icon,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
