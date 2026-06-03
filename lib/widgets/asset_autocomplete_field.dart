import 'package:flutter/material.dart';

import '../enums/market_type.dart';
import '../mock/mock_assets.dart';
import '../models/asset.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AssetAutocompleteField extends StatelessWidget {
  const AssetAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.assets = MockAssets.all,
    this.preferredMarket,
    this.autofocus = false,
    this.labelText,
    this.hintText = 'Ex: PETR4.SA, AAPL, BTC-USD...',
    this.prefixIcon = const Icon(Icons.search_rounded),
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
    this.onSelected,
    this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<Asset> assets;
  final MarketType? preferredMarket;
  final bool autofocus;
  final String? labelText;
  final String hintText;
  final Widget prefixIcon;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<Asset>? onSelected;
  final Future<List<Asset>> Function(
    String query, {
    MarketType? preferredMarket,
  })?
  onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Asset>(
          textEditingController: controller,
          focusNode: focusNode,
          displayStringForOption: (asset) => asset.ticker,
          optionsBuilder: _optionsFor,
          onSelected: (asset) {
            onSelected?.call(asset);
          },
          fieldViewBuilder:
              (context, fieldController, fieldFocusNode, onFieldSubmitted) {
                return TextField(
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  autofocus: autofocus,
                  textInputAction: textInputAction,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    prefixIcon: prefixIcon,
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: fieldController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: 'Limpar',
                          onPressed: () {
                            fieldController.clear();
                            fieldFocusNode.requestFocus();
                          },
                          icon: const Icon(Icons.close_rounded),
                        );
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    onFieldSubmitted();
                    onSubmitted?.call(fieldController.text);
                  },
                );
              },
          optionsViewBuilder: (context, onSelectedOption, options) {
            final items = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppColors.surfaceAlt,
                elevation: 10,
                shadowColor: AppColors.background.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 292,
                    maxWidth: constraints.maxWidth,
                    minWidth: constraints.maxWidth,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 14, endIndent: 14),
                    itemBuilder: (context, index) {
                      final asset = items[index];
                      final highlighted =
                          AutocompleteHighlightedOption.of(context) == index;

                      return _AssetOptionTile(
                        asset: asset,
                        highlighted: highlighted,
                        onTap: () => onSelectedOption(asset),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Iterable<Asset>> _optionsFor(TextEditingValue value) async {
    final query = _normalizeSearch(value.text);
    final localMatches = query.isEmpty
        ? assets
        : assets.where((asset) {
            final haystack = _normalizeSearch(
              '${asset.ticker} ${asset.name} '
              '${asset.marketType.label} ${asset.marketType.shortLabel}',
            );
            return query.split(' ').every(haystack.contains);
          });

    final remoteMatches = query.length >= 2 && onSearch != null
        ? await onSearch!(value.text, preferredMarket: preferredMarket)
        : const <Asset>[];
    final sorted = _sortAssets(
      _mergeAssets([...localMatches, ...remoteMatches]),
      query,
    );

    return sorted.take(8);
  }

  List<Asset> _sortAssets(List<Asset> matches, String query) {
    return matches..sort((a, b) {
      final rank = _rank(a, query).compareTo(_rank(b, query));
      if (rank != 0) return rank;

      if (preferredMarket != null && a.marketType != b.marketType) {
        if (a.marketType == preferredMarket) return -1;
        if (b.marketType == preferredMarket) return 1;
      }

      return a.ticker.compareTo(b.ticker);
    });
  }

  List<Asset> _mergeAssets(Iterable<Asset> source) {
    final merged = <String, Asset>{};
    for (final asset in source) {
      merged[asset.ticker] = asset;
    }
    return merged.values.toList();
  }

  int _rank(Asset asset, String query) {
    if (query.isEmpty) return 0;

    final ticker = _normalizeSearch(asset.ticker);
    final name = _normalizeSearch(asset.name);

    if (ticker == query) return 0;
    if (ticker.startsWith(query)) return 1;
    if (name.startsWith(query)) return 2;
    if (ticker.contains(query)) return 3;
    if (name.contains(query)) return 4;
    return 5;
  }

  String _normalizeSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}

class _AssetOptionTile extends StatelessWidget {
  const _AssetOptionTile({
    required this.asset,
    required this.highlighted,
    required this.onTap,
  });

  final Asset asset;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.blue.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.36),
                  ),
                ),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Text(
                      asset.logoEmoji ?? asset.marketType.icon,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.ticker, style: AppTextStyles.mono),
                    const SizedBox(height: 2),
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                asset.marketType.shortLabel,
                style: AppTextStyles.muted.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
