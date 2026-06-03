import '../enums/market_type.dart';

abstract final class TickerDetector {
  static MarketType detect(String ticker) {
    final normalized = ticker.trim().toUpperCase();
    if (normalized.endsWith('.SA')) return MarketType.brazil;
    if (normalized.endsWith('-USD')) return MarketType.crypto;
    return MarketType.usa;
  }

  static String normalize(String ticker) => ticker.trim().toUpperCase();
}
