import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../enums/currency.dart';
import '../enums/market_type.dart';
import '../models/asset.dart';

class MarketCatalogPage {
  const MarketCatalogPage({
    required this.assets,
    required this.totalCount,
    required this.hasMore,
  });

  final List<Asset> assets;
  final int totalCount;
  final bool hasMore;
}

class MarketCatalogService {
  MarketCatalogService({http.Client? client, String? tradingViewProxyUrl})
    : _client = client ?? http.Client(),
      _tradingViewProxyUrl =
          tradingViewProxyUrl ??
          const String.fromEnvironment('TRADINGVIEW_PROXY_URL');

  final http.Client _client;
  final String _tradingViewProxyUrl;

  static const pageSize = 100;
  static const fullCatalogPageSize = 150;
  static const fullCatalogMaxPages = 40;
  static const _requestTimeout = Duration(seconds: 8);

  Future<MarketCatalogPage> fetchAssets(
    MarketType marketType, {
    int start = 0,
    int size = pageSize,
    String query = '',
  }) {
    return _fetchTradingViewAssets(
      marketType,
      start: start,
      size: size,
      query: query,
    );
  }

  Future<MarketCatalogPage> fetchAllAssets(
    MarketType marketType, {
    String query = '',
    int pageSize = fullCatalogPageSize,
    int maxPages = fullCatalogMaxPages,
  }) async {
    final assets = <Asset>[];
    var totalCount = 0;
    var hasMore = true;

    for (var page = 0; page < maxPages && hasMore; page++) {
      final next = await fetchAssets(
        marketType,
        start: assets.length,
        size: pageSize,
        query: query,
      );
      totalCount = next.totalCount;
      assets.addAll(next.assets);
      hasMore = next.hasMore && next.assets.isNotEmpty;
    }

    final deduped = <String, Asset>{};
    for (final asset in assets) {
      final key = asset.tradingViewSymbol ?? asset.ticker;
      deduped[key] = asset;
    }

    return MarketCatalogPage(
      assets: deduped.values.toList(),
      totalCount: totalCount,
      hasMore: hasMore,
    );
  }

  Future<MarketCatalogPage> _fetchTradingViewAssets(
    MarketType marketType, {
    required int start,
    required int size,
    required String query,
  }) async {
    final String scanner;
    final List<String> markets;
    final List<Map<String, Object>> filters;

    if (marketType == MarketType.crypto) {
      scanner = 'crypto';
      markets = ['crypto'];
      filters = [
        if (query.trim().isNotEmpty)
          {
            'left': 'name,description',
            'operation': 'match',
            'right': query.trim(),
          },
      ];
    } else {
      scanner = marketType == MarketType.brazil ? 'brazil' : 'america';
      markets = [scanner];
      filters = [
        {'left': 'type', 'operation': 'equal', 'right': 'stock'},
        if (query.trim().isNotEmpty)
          {
            'left': 'name,description',
            'operation': 'match',
            'right': query.trim(),
          },
      ];
    }

    final response = await _post(
      _tradingViewUri('/$scanner/scan'),
      jsonEncode({
        'filter': filters,
        'options': {'lang': 'pt'},
        'markets': markets,
        'symbols': {
          'query': {'types': []},
          'tickers': [],
        },
        'columns': [
          'name',
          'description',
          'close',
          'change',
          'currency',
          'exchange',
        ],
        'sort': {'sortBy': 'name', 'sortOrder': 'asc'},
        'range': [start, start + size],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const MarketCatalogPage(assets: [], totalCount: 0, hasMore: false);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final totalCount = data['totalCount'] as int? ?? 0;
    final results = data['data'] as List<dynamic>? ?? const [];
    final assets = results
        .map((item) => _assetFromTradingView(item, marketType))
        .whereType<Asset>()
        .toList();

    return MarketCatalogPage(
      assets: assets,
      totalCount: totalCount,
      hasMore: start + assets.length < totalCount,
    );
  }

  Asset? _assetFromTradingView(Object? item, MarketType marketType) {
    if (item is! Map<String, dynamic>) return null;
    final tradingViewSymbol = item['s'] as String?;
    final values = item['d'] as List<dynamic>?;
    if (tradingViewSymbol == null || values == null || values.length < 6) {
      return null;
    }

    final rawTicker = values[0] as String?;
    final name = values[1] as String?;
    if (rawTicker == null || name == null) return null;

    final price = _readDouble(values[2]) ?? 0;
    final change = _readDouble(values[3]) ?? 0;
    final currencyCode = values[4] as String?;

    String ticker = rawTicker;
    if (marketType == MarketType.crypto) {
      if (rawTicker.endsWith('USD')) {
        ticker = '${rawTicker.substring(0, rawTicker.length - 3)}-USD';
      } else if (rawTicker.endsWith('USDT')) {
        ticker = '${rawTicker.substring(0, rawTicker.length - 4)}-USD';
      } else {
        ticker = '$rawTicker-USD';
      }
    } else if (marketType == MarketType.brazil) {
      ticker = '$rawTicker.SA';
    }

    final logoEmoji = marketType == MarketType.crypto
        ? rawTicker.replaceAll(RegExp(r'USD|USDT'), '')
        : marketType.icon;

    return Asset(
      ticker: ticker,
      name: name,
      marketType: marketType,
      currency: currencyCode == 'BRL' ? Currency.brl : Currency.usd,
      simulatedPrice: price,
      simulatedChangePercent: change,
      logoEmoji: logoEmoji,
      quoteSource: 'TradingView',
      quoteUpdatedAt: DateTime.now(),
      quoteIsLive: price > 0,
      tradingViewSymbol: tradingViewSymbol,
    );
  }



  Future<http.Response> _post(Uri uri, String body) {
    return _client
        .post(
          uri,
          headers: const {'Content-Type': 'text/plain;charset=UTF-8'},
          body: body,
        )
        .timeout(_requestTimeout);
  }

  Uri _tradingViewUri(String scannerPath) {
    final proxy = _tradingViewProxyUrl.trim();
    if (proxy.isNotEmpty) {
      return Uri.parse('${proxy.replaceFirst(RegExp(r'/+$'), '')}$scannerPath');
    }
    if (kIsWeb) return Uri.base.resolve('/api/tradingview$scannerPath');
    return Uri.https('scanner.tradingview.com', scannerPath);
  }

  double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
