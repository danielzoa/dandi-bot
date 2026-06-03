import '../enums/currency.dart';
import '../enums/market_type.dart';
import '../models/asset.dart';
import '../utils/ticker_detector.dart';

abstract final class MockAssets {
  static const all = <Asset>[
    Asset(
      ticker: 'PETR4.SA',
      name: 'Petrobras PN',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 36.74,
      simulatedChangePercent: 1.32,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'VALE3.SA',
      name: 'Vale ON',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 58.30,
      simulatedChangePercent: -0.85,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'ITUB4.SA',
      name: 'Itaú Unibanco PN',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 33.80,
      simulatedChangePercent: 0.60,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'BBAS3.SA',
      name: 'Banco do Brasil ON',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 25.90,
      simulatedChangePercent: 0.23,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'WEGE3.SA',
      name: 'WEG ON',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 49.20,
      simulatedChangePercent: 0.40,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'B3SA3.SA',
      name: 'B3 ON',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 12.80,
      simulatedChangePercent: 0.72,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'MGLU3.SA',
      name: 'Magazine Luiza ON',
      marketType: MarketType.brazil,
      currency: Currency.brl,
      simulatedPrice: 2.34,
      simulatedChangePercent: -2.15,
      logoEmoji: 'BR',
    ),
    Asset(
      ticker: 'AAPL',
      name: 'Apple Inc.',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 195.42,
      simulatedChangePercent: 0.31,
      logoEmoji: '',
    ),
    Asset(
      ticker: 'MSFT',
      name: 'Microsoft Corporation',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 415.80,
      simulatedChangePercent: 0.95,
      logoEmoji: 'MS',
    ),
    Asset(
      ticker: 'NVDA',
      name: 'NVIDIA Corporation',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 890.50,
      simulatedChangePercent: 2.10,
      logoEmoji: 'NV',
    ),
    Asset(
      ticker: 'TSLA',
      name: 'Tesla Inc.',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 178.30,
      simulatedChangePercent: -1.20,
      logoEmoji: 'TS',
    ),
    Asset(
      ticker: 'AMZN',
      name: 'Amazon.com Inc.',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 182.60,
      simulatedChangePercent: 0.55,
      logoEmoji: 'AZ',
    ),
    Asset(
      ticker: 'GOOGL',
      name: 'Alphabet Inc.',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 168.90,
      simulatedChangePercent: 0.42,
      logoEmoji: 'GO',
    ),
    Asset(
      ticker: 'META',
      name: 'Meta Platforms',
      marketType: MarketType.usa,
      currency: Currency.usd,
      simulatedPrice: 492.30,
      simulatedChangePercent: 1.05,
      logoEmoji: 'ME',
    ),
    Asset(
      ticker: 'BTC-USD',
      name: 'Bitcoin',
      marketType: MarketType.crypto,
      currency: Currency.usd,
      simulatedPrice: 67254.21,
      simulatedChangePercent: 3.20,
      logoEmoji: '₿',
    ),
    Asset(
      ticker: 'ETH-USD',
      name: 'Ethereum',
      marketType: MarketType.crypto,
      currency: Currency.usd,
      simulatedPrice: 3420.80,
      simulatedChangePercent: 1.90,
      logoEmoji: 'Ξ',
    ),
    Asset(
      ticker: 'SOL-USD',
      name: 'Solana',
      marketType: MarketType.crypto,
      currency: Currency.usd,
      simulatedPrice: 168.40,
      simulatedChangePercent: 4.50,
      logoEmoji: '◎',
    ),
    Asset(
      ticker: 'BNB-USD',
      name: 'BNB',
      marketType: MarketType.crypto,
      currency: Currency.usd,
      simulatedPrice: 582.10,
      simulatedChangePercent: 0.80,
      logoEmoji: 'BNB',
    ),
    Asset(
      ticker: 'XRP-USD',
      name: 'XRP',
      marketType: MarketType.crypto,
      currency: Currency.usd,
      simulatedPrice: 0.5820,
      simulatedChangePercent: 1.20,
      logoEmoji: 'XRP',
    ),
  ];

  static Asset? find(String ticker) {
    final normalized = TickerDetector.normalize(ticker);
    for (final asset in all) {
      if (asset.ticker == normalized) return asset;
    }
    return null;
  }

  static List<Asset> byMarket(MarketType marketType) {
    return all.where((asset) => asset.marketType == marketType).toList();
  }

  static Asset generic(String ticker) {
    final normalized = TickerDetector.normalize(ticker);
    final marketType = TickerDetector.detect(normalized);
    final currency = marketType == MarketType.brazil
        ? Currency.brl
        : Currency.usd;
    return Asset(
      ticker: normalized.isEmpty ? 'PETR4.SA' : normalized,
      name: 'Ativo simulado',
      marketType: marketType,
      currency: currency,
      simulatedPrice: marketType == MarketType.crypto ? 100.00 : 25.00,
      simulatedChangePercent: 0.00,
      logoEmoji: marketType.icon,
    );
  }
}
