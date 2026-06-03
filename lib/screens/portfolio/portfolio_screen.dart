import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../enums/market_type.dart';
import '../../models/asset.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/asset_autocomplete_field.dart';
import '../../widgets/portfolio_card.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final items = controller.portfolioItems;
    final totalInvested = controller.portfolioService.getTotalInvested(items);
    final totalValue = controller.portfolioService.getTotalCurrentValue(items);
    final profit = controller.portfolioService.getTotalProfitLoss(items);
    final profitPercent = totalInvested == 0
        ? 0.0
        : (profit / totalInvested) * 100;
    final resultColor = profit >= 0 ? AppColors.teal : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Carteira Simulada', style: AppTextStyles.display),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADICIONAR ATIVO'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900 ? 3 : 1;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.2 : 1.7,
              ),
              children: [
                InfoPill(
                  label: 'Patrimônio total (simulado)',
                  value: Formatters.compactMoney(
                    totalValue,
                    controller.settings.currency,
                  ),
                  color: AppColors.blue,
                ),
                InfoPill(
                  label: 'Resultado total',
                  value:
                      '${Formatters.compactMoney(profit, controller.settings.currency)} (${Formatters.percent(profitPercent, signed: true)})',
                  color: resultColor,
                ),
                InfoPill(
                  label: 'Variação do dia simulada',
                  value: Formatters.percent(
                    items.isEmpty
                        ? 0.0
                        : items.fold<double>(
                                0,
                                (sum, item) =>
                                    sum + item.asset.simulatedChangePercent,
                              ) /
                              items.length,
                    signed: true,
                  ),
                  color: AppColors.gold,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final distribution = _DistributionCard(itemsEmpty: items.isEmpty);
            final list = _PortfolioList();

            if (!wide) {
              return Column(
                children: [distribution, const SizedBox(height: 14), list],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: distribution),
                const SizedBox(width: 14),
                Expanded(flex: 6, child: list),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const _AddPortfolioDialog(),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.itemsEmpty});

  final bool itemsEmpty;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final distribution = controller.portfolioService.getDistributionByMarket(
      controller.portfolioItems,
    );
    final total = distribution.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Distribuição'),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: itemsEmpty
                ? Center(
                    child: Text(
                      'Adicione ativos fictícios para visualizar a distribuição.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.muted,
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 54,
                      sections: [
                        _section(
                          MarketType.brazil,
                          distribution[MarketType.brazil] ?? 0,
                        ),
                        _section(
                          MarketType.usa,
                          distribution[MarketType.usa] ?? 0,
                        ),
                        _section(
                          MarketType.crypto,
                          distribution[MarketType.crypto] ?? 0,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          for (final market in MarketType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: _color(market)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(market.label, style: AppTextStyles.body),
                  ),
                  Text(
                    total == 0
                        ? '0%'
                        : '${(((distribution[market] ?? 0) / total) * 100).round()}%',
                    style: AppTextStyles.mono.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  PieChartSectionData _section(MarketType market, double value) {
    return PieChartSectionData(
      value: value <= 0 ? 0.01 : value,
      radius: 42,
      showTitle: false,
      color: _color(market),
    );
  }

  Color _color(MarketType market) => switch (market) {
    MarketType.brazil => AppColors.teal,
    MarketType.usa => AppColors.blue,
    MarketType.crypto => AppColors.gold,
  };
}

class _PortfolioList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final items = controller.portfolioItems;

    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Ativos'),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nenhum ativo na carteira simulada ainda.',
                  style: AppTextStyles.muted,
                ),
              ),
            )
          else
            for (final item in items) ...[
              PortfolioCard(
                item: item,
                onRemove: () => controller.removePortfolioItem(item.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _AddPortfolioDialog extends StatefulWidget {
  const _AddPortfolioDialog();

  @override
  State<_AddPortfolioDialog> createState() => _AddPortfolioDialogState();
}

class _AddPortfolioDialogState extends State<_AddPortfolioDialog> {
  final _ticker = TextEditingController(text: 'PETR4.SA');
  final _tickerFocusNode = FocusNode();
  final _entry = TextEditingController(text: '36,74');
  final _quantity = TextEditingController(text: '10');
  final _note = TextEditingController();
  MarketType _market = MarketType.brazil;
  bool _saving = false;

  @override
  void dispose() {
    _ticker.dispose();
    _tickerFocusNode.dispose();
    _entry.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entry = _parse(_entry.text);
    final quantity = _parse(_quantity.text);
    if (entry <= 0 || quantity <= 0 || _ticker.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha ticker, preço e quantidade válidos.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await DandiScope.of(context).addPortfolioItem(
      ticker: _ticker.text,
      quantity: quantity,
      entryPrice: entry,
      note: _note.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  double _parse(String value) {
    final normalized = value.contains(',')
        ? value.replaceAll('.', '').replaceAll(',', '.')
        : value;
    return double.tryParse(normalized) ?? 0;
  }

  String _formatInputPrice(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _setTicker(String ticker) {
    _ticker.value = TextEditingValue(
      text: ticker,
      selection: TextSelection.collapsed(offset: ticker.length),
    );
  }

  void _applyAssetSuggestion(Asset asset) {
    setState(() {
      _market = asset.marketType;
      _entry.text = _formatInputPrice(asset.simulatedPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    return AlertDialog(
      title: const Text('Adicionar ativo simulado'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MarketType>(
                initialValue: _market,
                decoration: const InputDecoration(labelText: 'Mercado'),
                items: [
                  for (final market in MarketType.values)
                    DropdownMenuItem(value: market, child: Text(market.label)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _market = value;
                    final asset = controller.assetsByMarket(value).first;
                    _setTicker(asset.ticker);
                    _entry.text = _formatInputPrice(asset.simulatedPrice);
                  });
                },
              ),
              const SizedBox(height: 12),
              AssetAutocompleteField(
                controller: _ticker,
                focusNode: _tickerFocusNode,
                assets: controller.availableAssets,
                preferredMarket: _market,
                labelText: 'Ticker',
                textInputAction: TextInputAction.next,
                onSearch: controller.searchAssets,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                onSelected: _applyAssetSuggestion,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _entry,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço de entrada',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação opcional',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
