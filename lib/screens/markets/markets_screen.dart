import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../enums/market_type.dart';
import '../../mock/mock_assets.dart';
import '../../services/app_controller.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/asset_card.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFamousAssets();
      _quoteTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshFamousAssets(),
      );
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _refreshFamousAssets() {
    if (!mounted) return;
    DandiScope.of(context).refreshQuotesForAssets(MockAssets.all);
  }

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mercados', style: AppTextStyles.display),
        const SizedBox(height: 6),
        Text(
          'Ativos famosos na vitrine. Abra o catálogo completo de cada mercado para explorar todos.',
          style: AppTextStyles.muted,
        ),
        const SizedBox(height: 22),
        for (final market in MarketType.values) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '${market.icon} ${market.label}',
                  style: AppTextStyles.title,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('$routeMarketCatalog?market=${market.name}'),
                icon: const Icon(Icons.format_list_bulleted_rounded),
                label: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 980
                  ? 3
                  : constraints.maxWidth > 620
                  ? 2
                  : 1;
              final assets = MockAssets.byMarket(market)
                  .map((asset) => controller.assetForTicker(asset.ticker))
                  .toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assets.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 4.2 : 3.2,
                ),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return AssetCard(
                    asset: asset,
                    onTap: () async {
                      await controller.analyzeTicker(asset.ticker);
                      if (!context.mounted) return;
                      context.go('$routeAnalysis?ticker=${asset.ticker}');
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
