enum MarketType { brazil, usa, crypto }

extension MarketTypeX on MarketType {
  String get label => switch (this) {
    MarketType.brazil => 'Brasil / B3',
    MarketType.usa => 'EUA',
    MarketType.crypto => 'Cripto',
  };

  String get shortLabel => switch (this) {
    MarketType.brazil => 'B3',
    MarketType.usa => 'NYSE/NASDAQ',
    MarketType.crypto => 'Moedas',
  };

  String get icon => switch (this) {
    MarketType.brazil => '🇧🇷',
    MarketType.usa => '🇺🇸',
    MarketType.crypto => '₿',
  };
}
