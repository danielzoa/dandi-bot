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
import '../../utils/formatters.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/asset_autocomplete_field.dart';
import '../../widgets/dandi_bot_avatar.dart';
import '../../widgets/news_strip.dart';

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
        .take(7)
        .toList();
    final focusAsset = featured.isNotEmpty
        ? featured.first
        : MockAssets.byMarket(_selectedMarket).first;

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
            _TerminalHero(
              asset: focusAsset,
              onAskAi: () => context.go(routeChat),
              onFocusSearch: () {
                _tickerFocusNode.requestFocus();
                _tickerController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _tickerController.text.length,
                );
              },
            ),
            const SizedBox(height: 16),
            _MetricStrip(asset: focusAsset),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 1080;
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
                final watchlist = _WatchlistPanel(assets: featured);
                final aiPanel = _AiInsightsPanel(asset: focusAsset);

                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchCard,
                      const SizedBox(height: 14),
                      watchlist,
                      const SizedBox(height: 14),
                      aiPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: searchCard),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: watchlist),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: aiPanel),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _QuickActions(),
            const SizedBox(height: 14),
            const NewsStrip(),
            const SizedBox(height: 14),
            const _MarketPulsePanel(),
          ],
        ),
      ),
    );
  }
}

class _TerminalHero extends StatelessWidget {
  const _TerminalHero({
    required this.asset,
    required this.onAskAi,
    required this.onFocusSearch,
  });

  final Asset asset;
  final VoidCallback onAskAi;
  final VoidCallback onFocusSearch;

  @override
  Widget build(BuildContext context) {
    final positive = asset.simulatedChangePercent >= 0;
    final changeColor = positive ? AppColors.teal : AppColors.red;

    return DandiCard(
      highlight: true,
      child: Row(
        children: [
          const DandiBotAvatar(size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'DanDiBot Terminal Mode',
                      style: AppTextStyles.display,
                    ),
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.blueBright,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${asset.ticker} - ${asset.name} - ${asset.marketType.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compactMoney(asset.simulatedPrice, asset.currency),
                style: AppTextStyles.mono.copyWith(fontSize: 22),
              ),
              Text(
                Formatters.percent(asset.simulatedChangePercent, signed: true),
                style: AppTextStyles.mono.copyWith(color: changeColor),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Chat com IA',
            onPressed: onAskAi,
            icon: const Icon(Icons.psychology_alt_outlined),
          ),
          IconButton(
            tooltip: 'Focar busca (Ctrl+K)',
            onPressed: onFocusSearch,
            icon: const Icon(Icons.manage_search_rounded),
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final positive = asset.simulatedChangePercent >= 0;
    final changeColor = positive ? AppColors.teal : AppColors.red;
    final items = [
      (
        'Preco',
        Formatters.compactMoney(asset.simulatedPrice, asset.currency),
        AppColors.white,
      ),
      (
        'Variacao (D)',
        Formatters.percent(asset.simulatedChangePercent, signed: true),
        changeColor,
      ),
      ('Volume', asset.quoteIsLive ? 'Live' : 'Simulado', AppColors.muted),
      ('RSI (14)', positive ? '57,6' : '42,8', AppColors.gold),
      ('Sentimento', positive ? 'Positivo' : 'Defensivo', changeColor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 560
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 2.15 : 1.75,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return DandiCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$1, style: AppTextStyles.muted),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono.copyWith(
                      color: item.$3,
                      fontSize: 18,
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
          Text('Terminal de analise', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            'Digite um ticker ou escolha um mercado para iniciar uma analise simulada.',
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
              label: const Text('ANALISAR ATIVO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistPanel extends StatelessWidget {
  const _WatchlistPanel({required this.assets});

  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    final controller = DandiScope.of(context);

    return DandiCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Watchlist',
            trailing: IconButton(
              tooltip: 'Mercados',
              onPressed: () => context.go(routeMarkets),
              icon: const Icon(Icons.add_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          for (final asset in assets) ...[
            _WatchlistRow(
              asset: asset,
              onTap: () {
                controller.analyzeTicker(asset.ticker).then((_) {
                  if (!context.mounted) return;
                  context.go('$routeAnalysis?ticker=${asset.ticker}');
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.asset, required this.onTap});

  final Asset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = asset.simulatedChangePercent >= 0;
    final color = positive ? AppColors.teal : AppColors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 18,
              child: CustomPaint(painter: _SparklinePainter(color: color)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.compactMoney(asset.simulatedPrice, asset.currency),
                  style: AppTextStyles.mono.copyWith(fontSize: 12),
                ),
                Text(
                  Formatters.percent(
                    asset.simulatedChangePercent,
                    signed: true,
                  ),
                  style: AppTextStyles.mono.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.34, size.height * 0.64)
      ..lineTo(size.width * 0.52, size.height * 0.34)
      ..lineTo(size.width * 0.72, size.height * 0.42)
      ..lineTo(size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AiInsightsPanel extends StatelessWidget {
  const _AiInsightsPanel({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final positive = asset.simulatedChangePercent >= 0;

    return DandiCard(
      padding: const EdgeInsets.all(14),
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_outlined,
                color: AppColors.blueBright,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('IA Insights', style: AppTextStyles.subtitle),
              ),
              IconButton(
                tooltip: 'Chat',
                onPressed: () => context.go(routeChat),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _InsightTabs(),
          const SizedBox(height: 12),
          Text('Resumo IA', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            '${asset.ticker} mostra leitura ${positive ? 'construtiva' : 'defensiva'} no curto prazo. Volume, momentum e risco devem ser acompanhados antes de qualquer decisao simulada.',
            style: AppTextStyles.muted.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              InfoPill(
                label: 'Tendencia',
                value: positive ? 'Alta' : 'Baixa',
                color: positive ? AppColors.teal : AppColors.red,
              ),
              const InfoPill(label: 'Forca', value: 'Moderada'),
              const InfoPill(
                label: 'Risco',
                value: 'Medio',
                color: AppColors.gold,
              ),
              const InfoPill(label: 'Alvos', value: '38/40'),
              const InfoPill(label: 'Suporte', value: '36/34'),
              const InfoPill(
                label: 'Stop',
                value: '35,40',
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Assistente DanDiBot', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PromptChip(label: 'Analisar ${asset.ticker}'),
              const _PromptChip(label: 'Resumo do mercado hoje'),
              const _PromptChip(label: 'Quais acoes estao fortes?'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'As respostas da IA nao sao recomendacoes de investimento.',
            style: AppTextStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _InsightTabs extends StatelessWidget {
  const _InsightTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabLabel(label: 'Analise', active: true),
        _TabLabel(label: 'Sentimento'),
        _TabLabel(label: 'Cenarios'),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        label,
        style: AppTextStyles.muted.copyWith(
          color: active ? AppColors.blueBright : AppColors.muted,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.bolt_rounded, size: 16),
      onPressed: () => context.go(routeChat),
    );
  }
}

class _MarketPulsePanel extends StatelessWidget {
  const _MarketPulsePanel();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('IBOV', '129.845,23', '+0,61%', AppColors.teal),
      ('S&P 500', '5.334,21', '+0,58%', AppColors.teal),
      ('NASDAQ', '16.853,75', '+0,81%', AppColors.teal),
      ('DOLAR', '5,12', '-0,21%', AppColors.red),
    ];

    return DandiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Visao de Mercado'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 760 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDeep.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(row.$1, style: AppTextStyles.subtitle),
                                Text(row.$2, style: AppTextStyles.muted),
                              ],
                            ),
                          ),
                          Text(
                            row.$3,
                            style: AppTextStyles.mono.copyWith(
                              color: row.$4,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
