import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../enums/market_type.dart';
import '../models/asset.dart';
import '../utils/market_data_symbols.dart';

class MarketQuote {
  const MarketQuote({
    required this.price,
    required this.changePercent,
    required this.source,
    required this.fetchedAt,
  });

  final double price;
  final double changePercent;
  final String source;
  final DateTime fetchedAt;
}

class MarketChartPoint {
  const MarketChartPoint({required this.time, required this.price});

  final DateTime time;
  final double price;
}

class MarketChart {
  const MarketChart({
    required this.points,
    required this.source,
    required this.fetchedAt,
  });

  final List<MarketChartPoint> points;
  final String source;
  final DateTime fetchedAt;
}

class MarketQuoteService {
  MarketQuoteService({
    http.Client? client,
    String? brapiToken,
    String? investingProxyUrl,
    String? tradingViewProxyUrl,
  }) : _client = client ?? http.Client(),
       _brapiToken = brapiToken ?? const String.fromEnvironment('BRAPI_TOKEN'),
       _investingProxyUrl =
           investingProxyUrl ??
           const String.fromEnvironment('INVESTING_PROXY_URL'),
       _tradingViewProxyUrl =
           tradingViewProxyUrl ??
           const String.fromEnvironment('TRADINGVIEW_PROXY_URL');

  final http.Client _client;
  final String _brapiToken;
  final String _investingProxyUrl;
  final String _tradingViewProxyUrl;

  static const refreshInterval = Duration(seconds: 30);
  static const _requestTimeout = Duration(seconds: 8);

  Future<Asset> enrichAsset(Asset asset) async {
    final quote = await fetchQuote(asset);
    if (quote == null) return asset;

    return asset.copyWith(
      simulatedPrice: quote.price,
      simulatedChangePercent: quote.changePercent,
      quoteSource: quote.source,
      quoteUpdatedAt: quote.fetchedAt,
      quoteIsLive: true,
    );
  }

  Future<List<Asset>> enrichAssets(Iterable<Asset> assets) async {
    return Future.wait(assets.map(enrichAsset));
  }

  Future<MarketQuote?> fetchQuote(Asset asset) async {
    final providers = <Future<MarketQuote?> Function()>[
      if (asset.marketType == MarketType.brazil ||
          asset.marketType == MarketType.usa ||
          asset.marketType == MarketType.crypto)
        () => _fetchTradingView(asset),
      if (asset.marketType == MarketType.crypto) () => _fetchCoinGecko(asset),
      if (_investingProxyUrl.trim().isNotEmpty)
        () => _fetchInvestingProxy(asset),
      if (asset.marketType == MarketType.brazil || _brapiToken.isNotEmpty)
        () => _fetchBrapi(asset),
      () => _fetchYahoo(asset),
    ];

    for (final provider in providers) {
      try {
        final quote = await provider();
        if (quote != null) return quote;
      } catch (_) {
        // Keep the app usable if a public quote source is unavailable.
      }
    }

    return null;
  }

  Future<MarketChart?> fetchCoinGeckoChart(Asset asset, {int days = 7}) async {
    final coinId = MarketDataSymbols.coinGeckoIdForAsset(asset);
    if (coinId == null) return null;

    final uri = Uri.https(
      'api.coingecko.com',
      '/api/v3/coins/$coinId/market_chart',
      {'vs_currency': 'usd', 'days': '$days'},
    );
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final prices = data['prices'] as List<dynamic>?;
    if (prices == null || prices.isEmpty) return null;

    final points = <MarketChartPoint>[];
    for (final row in prices) {
      if (row is! List<dynamic> || row.length < 2) continue;
      final timestamp = row[0];
      final price = row[1];
      if (timestamp is! num || price is! num) continue;
      points.add(
        MarketChartPoint(
          time: DateTime.fromMillisecondsSinceEpoch(
            timestamp.round(),
            isUtc: true,
          ).toLocal(),
          price: price.toDouble(),
        ),
      );
    }

    if (points.isEmpty) return null;

    return MarketChart(
      points: points,
      source: 'CoinGecko',
      fetchedAt: DateTime.now(),
    );
  }

  Future<MarketQuote?> _fetchTradingView(Asset asset) async {
    final scannerPath = MarketDataSymbols.tradingViewScannerPath(asset);
    if (scannerPath == null) return null;

    for (final symbol in MarketDataSymbols.tradingViewQuoteCandidates(asset)) {
      final uri = _tradingViewUri(scannerPath);
      final response = await _post(
        uri,
        body: jsonEncode({
          'symbols': {
            'tickers': [symbol],
          },
          'columns': ['close', 'change', 'currency', 'update_mode'],
        }),
        headers: const {'Content-Type': 'text/plain;charset=UTF-8'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) continue;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['data'] as List<dynamic>?;
      if (results == null || results.isEmpty) continue;

      final result = results.first as Map<String, dynamic>;
      final values = result['d'] as List<dynamic>?;
      if (values == null || values.length < 2) continue;

      final price = _readListDouble(values, 0);
      final changePercent = _readListDouble(values, 1);
      if (price == null || changePercent == null) continue;

      return MarketQuote(
        price: price,
        changePercent: changePercent,
        source: 'TradingView',
        fetchedAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<MarketQuote?> _fetchInvestingProxy(Asset asset) async {
    final base = Uri.parse(_investingProxyUrl);
    final uri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'symbol': asset.ticker,
        'market': asset.marketType.name,
      },
    );
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final price = _readDouble(data, ['price', 'last', 'regularMarketPrice']);
    final changePercent = _readDouble(data, [
      'changePercent',
      'change_percent',
      'regularMarketChangePercent',
    ]);
    if (price == null || changePercent == null) return null;

    return MarketQuote(
      price: price,
      changePercent: changePercent,
      source: data['source'] as String? ?? 'Investing.com',
      fetchedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Future<MarketQuote?> _fetchBrapi(Asset asset) async {
    final symbol = asset.ticker.replaceAll('.SA', '');
    final uri = Uri.https('brapi.dev', '/api/quote/$symbol');
    final response = await _get(
      uri,
      headers: _brapiToken.isEmpty
          ? null
          : {'Authorization': 'Bearer $_brapiToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final item = results.first as Map<String, dynamic>;
    final price = _readDouble(item, ['regularMarketPrice']);
    final changePercent = _readDouble(item, ['regularMarketChangePercent']);
    if (price == null || changePercent == null) return null;

    return MarketQuote(
      price: price,
      changePercent: changePercent,
      source: 'Brapi',
      fetchedAt: _parseDate(item['regularMarketTime']) ?? DateTime.now(),
    );
  }

  Future<MarketQuote?> _fetchCoinGecko(Asset asset) async {
    final coinId = MarketDataSymbols.coinGeckoIdForAsset(asset);
    if (coinId == null) return null;

    final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
      'ids': coinId,
      'vs_currencies': 'usd',
      'include_24hr_change': 'true',
      'include_last_updated_at': 'true',
    });
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final item = data[coinId] as Map<String, dynamic>?;
    if (item == null) return null;

    final price = _readDouble(item, ['usd']);
    final changePercent = _readDouble(item, ['usd_24h_change']);
    if (price == null || changePercent == null) return null;

    return MarketQuote(
      price: price,
      changePercent: changePercent,
      source: 'CoinGecko',
      fetchedAt: _parseTimestamp(item['last_updated_at']) ?? DateTime.now(),
    );
  }

  Future<MarketQuote?> _fetchYahoo(Asset asset) async {
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/${asset.ticker}',
      {'interval': '1d', 'range': '2d'},
    );
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final chart = data['chart'] as Map<String, dynamic>?;
    final results = chart?['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final result = results.first as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>?;
    if (meta == null) return null;

    final price = _readDouble(meta, ['regularMarketPrice']);
    final previousClose = _readDouble(meta, [
      'chartPreviousClose',
      'regularMarketPreviousClose',
      'previousClose',
    ]);
    if (price == null || previousClose == null || previousClose == 0) {
      return null;
    }

    return MarketQuote(
      price: price,
      changePercent: ((price - previousClose) / previousClose) * 100,
      source: 'Yahoo Finance',
      fetchedAt: _parseTimestamp(meta['regularMarketTime']) ?? DateTime.now(),
    );
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    return _client.get(uri, headers: headers).timeout(_requestTimeout);
  }

  Uri _tradingViewUri(String scannerPath) {
    final proxy = _tradingViewProxyUrl.trim();
    if (proxy.isNotEmpty) {
      return Uri.parse('${proxy.replaceFirst(RegExp(r'/+$'), '')}$scannerPath');
    }
    if (kIsWeb) return Uri.base.resolve('/api/tradingview$scannerPath');
    return Uri.https('scanner.tradingview.com', scannerPath);
  }

  Future<http.Response> _post(
    Uri uri, {
    required Object body,
    Map<String, String>? headers,
  }) {
    return _client
        .post(uri, headers: headers, body: body)
        .timeout(_requestTimeout);
  }

  double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double? _readListDouble(List<dynamic> data, int index) {
    if (index < 0 || index >= data.length) return null;
    final value = data[index];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (value * 1000).round(),
      isUtc: true,
    ).toLocal();
  }
}
