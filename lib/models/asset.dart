import '../enums/currency.dart';
import '../enums/market_type.dart';

class Asset {
  const Asset({
    required this.ticker,
    required this.name,
    required this.marketType,
    required this.currency,
    required this.simulatedPrice,
    required this.simulatedChangePercent,
    this.logoEmoji,
    this.quoteSource = 'Simulado',
    this.quoteUpdatedAt,
    this.quoteIsLive = false,
    this.tradingViewSymbol,
    this.coinGeckoId,
  });

  final String ticker;
  final String name;
  final MarketType marketType;
  final Currency currency;
  final double simulatedPrice;
  final double simulatedChangePercent;
  final String? logoEmoji;
  final String quoteSource;
  final DateTime? quoteUpdatedAt;
  final bool quoteIsLive;
  final String? tradingViewSymbol;
  final String? coinGeckoId;

  Asset copyWith({
    String? ticker,
    String? name,
    MarketType? marketType,
    Currency? currency,
    double? simulatedPrice,
    double? simulatedChangePercent,
    String? logoEmoji,
    String? quoteSource,
    DateTime? quoteUpdatedAt,
    bool? quoteIsLive,
    String? tradingViewSymbol,
    String? coinGeckoId,
    bool clearQuoteUpdatedAt = false,
  }) {
    return Asset(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      marketType: marketType ?? this.marketType,
      currency: currency ?? this.currency,
      simulatedPrice: simulatedPrice ?? this.simulatedPrice,
      simulatedChangePercent:
          simulatedChangePercent ?? this.simulatedChangePercent,
      logoEmoji: logoEmoji ?? this.logoEmoji,
      quoteSource: quoteSource ?? this.quoteSource,
      quoteUpdatedAt: clearQuoteUpdatedAt
          ? null
          : quoteUpdatedAt ?? this.quoteUpdatedAt,
      quoteIsLive: quoteIsLive ?? this.quoteIsLive,
      tradingViewSymbol: tradingViewSymbol ?? this.tradingViewSymbol,
      coinGeckoId: coinGeckoId ?? this.coinGeckoId,
    );
  }

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'name': name,
    'marketType': marketType.name,
    'currency': currency.name,
    'simulatedPrice': simulatedPrice,
    'simulatedChangePercent': simulatedChangePercent,
    'logoEmoji': logoEmoji,
    'quoteSource': quoteSource,
    'quoteUpdatedAt': quoteUpdatedAt?.toIso8601String(),
    'quoteIsLive': quoteIsLive,
    'tradingViewSymbol': tradingViewSymbol,
    'coinGeckoId': coinGeckoId,
  };

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      marketType: MarketType.values.byName(json['marketType'] as String),
      currency: Currency.values.byName(json['currency'] as String),
      simulatedPrice: (json['simulatedPrice'] as num).toDouble(),
      simulatedChangePercent: (json['simulatedChangePercent'] as num)
          .toDouble(),
      logoEmoji: json['logoEmoji'] as String?,
      quoteSource: json['quoteSource'] as String? ?? 'Simulado',
      quoteUpdatedAt: json['quoteUpdatedAt'] == null
          ? null
          : DateTime.parse(json['quoteUpdatedAt'] as String),
      quoteIsLive: json['quoteIsLive'] as bool? ?? false,
      tradingViewSymbol: json['tradingViewSymbol'] as String?,
      coinGeckoId: json['coinGeckoId'] as String?,
    );
  }
}
