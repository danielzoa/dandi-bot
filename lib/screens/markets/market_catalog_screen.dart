import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../enums/market_type.dart';
import '../../mock/mock_assets.dart';
import '../../models/asset.dart';
import '../../services/app_controller.dart';
import '../../services/market_catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/asset_card.dart';

class MarketCatalogScreen extends StatefulWidget {
  const MarketCatalogScreen({super.key, required this.marketType});

  final MarketType marketType;

  @override
  State<MarketCatalogScreen> createState() => _MarketCatalogScreenState();
}

class _MarketCatalogScreenState extends State<MarketCatalogScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _assets = <Asset>[];
  bool _loading = false;
  bool _hasMore = true;
  int _totalCount = 0;
  String _query = '';
  int _loadGeneration = 0;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void didUpdateWidget(covariant MarketCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketType != widget.marketType) {
      _searchController.clear();
      _query = '';
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    final generation = reset ? ++_loadGeneration : _loadGeneration;
    if (reset) {
      setState(() {
        _assets.clear();
        _totalCount = 0;
        _hasMore = true;
        _usingFallback = false;
        _loading = true;
      });
    } else {
      setState(() => _loading = true);
    }

    final controller = DandiScope.of(context);
    final marketType = widget.marketType;
    final query = _query;
    final start = reset ? 0 : _assets.length;
    late MarketCatalogPage page;
    var usingFallback = false;
    try {
      page = await controller.catalogService.fetchAssets(
        marketType,
        start: start,
        query: query,
      );
      if (reset && page.assets.isEmpty && query.isEmpty) {
        page = _fallbackPage(marketType);
        usingFallback = true;
      }
      controller.rememberCatalogAssets(page.assets);
    } catch (_) {
      page = reset
          ? _fallbackPage(marketType)
          : const MarketCatalogPage(assets: [], totalCount: 0, hasMore: false);
      usingFallback = reset;
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      final nextAssets = reset ? page.assets : [..._assets, ...page.assets];
      _assets
        ..clear()
        ..addAll(_dedupeAssets(nextAssets));
      _totalCount = page.totalCount;
      _hasMore = page.hasMore;
      _usingFallback = usingFallback;
      _loading = false;
    });
  }

  MarketCatalogPage _fallbackPage(MarketType marketType) {
    final assets = MockAssets.byMarket(marketType);
    return MarketCatalogPage(
      assets: assets,
      totalCount: assets.length,
      hasMore: false,
    );
  }

  void _applySearch(String value) {
    _query = value.trim();
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    const source = 'TradingView';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => context.go(routeMarkets),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Todos - ${widget.marketType.label}',
                style: AppTextStyles.display,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Catálogo $source com busca e carregamento por páginas.',
          style: AppTextStyles.muted,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.marketType == MarketType.crypto
                ? 'Buscar moeda, símbolo ou projeto'
                : 'Buscar ticker ou empresa',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: () => _applySearch(_searchController.text),
              icon: const Icon(Icons.manage_search_rounded),
            ),
          ),
          onSubmitted: _applySearch,
        ),
        const SizedBox(height: 14),
        _CatalogStatus(
          loaded: _assets.length,
          total: _totalCount,
          source: source,
          loading: _loading,
          usingFallback: _usingFallback,
          onRetry: _loading ? null : () => _load(reset: true),
        ),
        const SizedBox(height: 14),
        if (_assets.isEmpty && _loading)
          const SizedBox(
            height: 420,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_assets.isEmpty)
          const SizedBox(height: 420, child: _EmptyCatalog())
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final columns = maxWidth > 980
                  ? 3
                  : maxWidth > 620
                  ? 2
                  : 1;
              const spacing = 12.0;
              final cardWidth =
                  (maxWidth - (spacing * (columns - 1))) / columns;
              final cardHeight = columns == 1 ? 112.0 : 126.0;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final asset in _assets)
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: AssetCard(
                        asset: asset,
                        onTap: () async {
                          final controller = DandiScope.of(context);
                          await controller.analyzeAsset(asset);
                          if (!context.mounted) return;
                          context.go(
                            '$routeAnalysis?ticker=${Uri.encodeComponent(asset.ticker)}',
                          );
                        },
                      ),
                    ),
                  if (_hasMore)
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _LoadMoreCard(
                        loading: _loading,
                        onPressed: _loading ? null : () => _load(),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<Asset> _dedupeAssets(Iterable<Asset> assets) {
    final deduped = <String, Asset>{};
    for (final asset in assets) {
      final key = asset.coinGeckoId ?? asset.tradingViewSymbol ?? asset.ticker;
      deduped[key] = asset;
    }
    return deduped.values.toList();
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({
    required this.loaded,
    required this.total,
    required this.source,
    required this.loading,
    required this.usingFallback,
    required this.onRetry,
  });

  final int loaded;
  final int total;
  final String source;
  final bool loading;
  final bool usingFallback;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final label = total > 0 ? '$loaded de $total ativos' : '$loaded ativos';
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: AppTextStyles.muted),
        Text('Fonte $source', style: AppTextStyles.muted),
        if (usingFallback)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Exibindo ativos conhecidos. Tentar atualizar'),
          ),
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_rounded),
      label: Text(loading ? 'Carregando' : 'Carregar mais'),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhum ativo encontrado.',
        style: AppTextStyles.muted.copyWith(color: AppColors.muted),
      ),
    );
  }
}
