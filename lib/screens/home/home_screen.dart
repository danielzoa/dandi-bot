import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../enums/market_type.dart';
import '../../mock/mock_assets.dart';
import '../../models/asset.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/asset_autocomplete_field.dart';
import '../../widgets/dandi_bot_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tickerController = TextEditingController(text: 'PETR4.SA');
  final _tickerFocusNode = FocusNode();
  MarketType _selectedMarket = MarketType.brazil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DandiScope.of(
        context,
      ).refreshQuotesForAssets(MockAssets.byMarket(_selectedMarket));
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final ticker = _tickerController.text.trim();
    if (ticker.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um ticker para analisar.')),
      );
      return;
    }

    final controller = DandiScope.of(context);
    await controller.analyzeTicker(ticker);
    if (!mounted) return;
    context.go('$routeAnalysis?ticker=${Uri.encodeComponent(ticker)}');
  }

  void _setTicker(String ticker) {
    _tickerController.value = TextEditingValue(
      text: ticker,
      selection: TextSelection.collapsed(offset: ticker.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);
    final featured = controller
        .assetsByMarket(_selectedMarket)
        .take(3)
        .toList();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusTickerIntent(),
      },
      child: Actions(
        actions: {
          _FocusTickerIntent: CallbackAction<_FocusTickerIntent>(
            onInvoke: (intent) {
              _tickerFocusNode.requestFocus();
              _tickerController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _tickerController.text.length,
              );
              return null;
            },
          ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DandiBotAvatar(size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dandi Bot', style: AppTextStyles.display),
                      const SizedBox(height: 4),
                      Text(
                        'Seu assistente inteligente para investimentos simulados.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Chat com IA',
                  onPressed: () => context.go(routeChat),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Focar busca (Ctrl+K)',
                  onPressed: () {
                    _tickerFocusNode.requestFocus();
                    _tickerController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _tickerController.text.length,
                    );
                  },
                  icon: const Icon(Icons.manage_search_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final searchCard = _SearchCard(
                  tickerController: _tickerController,
                  tickerFocusNode: _tickerFocusNode,
                  assets: controller.availableAssets,
                  selectedMarket: _selectedMarket,
                  loading: controller.isLoadingAnalysis,
                  onMarketChanged: (market) {
                    setState(() {
                      _selectedMarket = market;
                      _setTicker(MockAssets.byMarket(market).first.ticker);
                    });
                    controller.refreshQuotesForAssets(
                      MockAssets.byMarket(market),
                    );
                  },
                  onAnalyze: _analyze,
                );
                final featuredList = _FeaturedAssets(assets: featured);

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchCard,
                      const SizedBox(height: 18),
                      featuredList,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: searchCard),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: featuredList),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _FocusTickerIntent extends Intent {
  const _FocusTickerIntent();
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.tickerController,
    required this.tickerFocusNode,
    required this.assets,
    required this.selectedMarket,
    required this.loading,
    required this.onMarketChanged,
    required this.onAnalyze,
  });

  final TextEditingController tickerController;
  final FocusNode tickerFocusNode;
  final List<Asset> assets;
  final MarketType selectedMarket;
  final bool loading;
  final ValueChanged<MarketType> onMarketChanged;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return DandiCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O que deseja analisar hoje?', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            'Digite um ticker ou escolha um mercado para iniciar uma análise simulada.',
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 18),
          AssetAutocompleteField(
            controller: tickerController,
            focusNode: tickerFocusNode,
            assets: assets,
            preferredMarket: selectedMarket,
            autofocus: true,
            onSearch: DandiScope.of(context).searchAssets,
            onSubmitted: (_) => onAnalyze(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final market in MarketType.values)
                ChoiceChip(
                  selected: selectedMarket == market,
                  label: Text('${market.icon} ${market.label}'),
                  onSelected: (_) => onMarketChanged(market),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onAnalyze,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_graph_rounded),
              label: const Text('ANALISAR'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedAssets extends StatelessWidget {
  const _FeaturedAssets({required this.assets});

  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);

    return Column(
      children: [
        for (final asset in assets) ...[
          DandiCard(
            onTap: () async {
              await controller.analyzeTicker(asset.ticker);
              if (!context.mounted) return;
              context.go('$routeAnalysis?ticker=${asset.ticker}');
            },
            child: Row(
              children: [
                Text(asset.logoEmoji ?? asset.marketType.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.ticker, style: AppTextStyles.mono),
                      Text(asset.name, style: AppTextStyles.muted),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(
        'Carteira Simulada',
        'Acompanhe P&L fictício',
        Icons.account_balance_wallet_rounded,
        routePortfolio,
      ),
      _QuickAction(
        'Histórico de Análises',
        'Revise decisões simuladas',
        Icons.history_rounded,
        routeHistory,
      ),
      _QuickAction(
        'Chat com IA',
        'Tire dúvidas educativas',
        Icons.smart_toy_outlined,
        routeChat,
      ),
      _QuickAction(
        'Configurações',
        'Perfil e preferências',
        Icons.settings_rounded,
        routeSettings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.2 : 1.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return DandiCard(
              onTap: () => context.go(item.route),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(item.icon, color: AppColors.blueBright),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTextStyles.subtitle),
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: AppTextStyles.muted),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAction {
  const _QuickAction(this.title, this.subtitle, this.icon, this.route);
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
