import 'package:intl/intl.dart';

import '../enums/currency.dart';

abstract final class Formatters {
  static String money(double value, Currency currency) {
    final locale = currency == Currency.brl ? 'pt_BR' : 'en_US';
    final symbol = currency.symbol;
    return NumberFormat.currency(locale: locale, symbol: symbol).format(value);
  }

  static String compactMoney(double value, Currency currency) {
    final symbol = currency.symbol;
    return '$symbol ${NumberFormat('#,##0.00', 'pt_BR').format(value)}';
  }

  static String percent(double value, {bool signed = false}) {
    final sign = signed && value > 0 ? '+' : '';
    return '$sign${NumberFormat('0.00', 'pt_BR').format(value)}%';
  }

  static String confidence(double value) {
    return '${(value * 100).round()}%';
  }

  static String dateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy, HH:mm', 'pt_BR').format(value);
  }

  static String time(DateTime value) {
    return DateFormat('HH:mm', 'pt_BR').format(value);
  }
}
