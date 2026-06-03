enum Currency { brl, usd }

extension CurrencyX on Currency {
  String get label => switch (this) {
    Currency.brl => 'BRL',
    Currency.usd => 'USD',
  };

  String get symbol => switch (this) {
    Currency.brl => 'R\$',
    Currency.usd => 'US\$',
  };
}
