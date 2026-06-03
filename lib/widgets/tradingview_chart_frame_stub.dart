import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/market_data_symbols.dart';

class TradingViewChartFrame extends StatelessWidget {
  const TradingViewChartFrame({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final url = MarketDataSymbols.tradingViewUrl(asset);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.blueBright),
              const SizedBox(height: 10),
              Text(
                'Gráfico TradingView disponível na versão web.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText(
                url.toString(),
                style: AppTextStyles.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
