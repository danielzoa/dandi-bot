import '../enums/market_type.dart';
import '../models/asset.dart';

abstract final class MarketDataSymbols {
  static const coinGeckoIds = {
    'BTC-USD': 'bitcoin',
    'ETH-USD': 'ethereum',
    'SOL-USD': 'solana',
    'BNB-USD': 'binancecoin',
    'XRP-USD': 'ripple',
  };

  static const _usExchanges = {
    'AAPL': 'NASDAQ',
    'MSFT': 'NASDAQ',
    'NVDA': 'NASDAQ',
    'TSLA': 'NASDAQ',
    'AMZN': 'NASDAQ',
    'GOOGL': 'NASDAQ',
    'META': 'NASDAQ',
  };

  static String? coinGeckoIdForTicker(String ticker) {
    return coinGeckoIds[ticker.toUpperCase()];
  }

  static String? coinGeckoIdForAsset(Asset asset) {
    return asset.coinGeckoId ?? coinGeckoIdForTicker(asset.ticker);
  }

  static String tradingViewPrimarySymbol(Asset asset) {
    if (asset.tradingViewSymbol != null) return asset.tradingViewSymbol!;

    final ticker = asset.ticker.toUpperCase();
    return switch (asset.marketType) {
      MarketType.brazil => 'BMFBOVESPA:${_withoutBrazilSuffix(ticker)}',
      MarketType.usa => '${_usExchanges[ticker] ?? 'NASDAQ'}:$ticker',
      MarketType.crypto => 'BINANCE:${ticker.replaceAll('-', '')}',
    };
  }

  static List<String> tradingViewQuoteCandidates(Asset asset) {
    if (asset.marketType == MarketType.brazil ||
        asset.marketType == MarketType.crypto) {
      return [tradingViewPrimarySymbol(asset)];
    }

    if (asset.marketType != MarketType.usa) return const [];

    final ticker = asset.ticker.toUpperCase();
    return {
      if (asset.tradingViewSymbol != null) asset.tradingViewSymbol!,
      tradingViewPrimarySymbol(asset),
      'NYSE:$ticker',
      'AMEX:$ticker',
      'OTC:$ticker',
    }.toList();
  }

  static String? tradingViewScannerPath(Asset asset) {
    return switch (asset.marketType) {
      MarketType.brazil => '/brazil/scan',
      MarketType.usa => '/america/scan',
      MarketType.crypto => '/crypto/scan',
    };
  }

  static Uri tradingViewUrl(Asset asset) {
    final symbol = tradingViewPrimarySymbol(asset).replaceAll(':', '-');
    return Uri.https('br.tradingview.com', '/symbols/$symbol/');
  }

  static String _withoutBrazilSuffix(String ticker) {
    return ticker.replaceFirst(RegExp(r'\.SA$'), '');
  }
}
