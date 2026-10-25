import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum AppCurrency {
  usd,
  cdf;

  String get code => this == AppCurrency.usd ? 'USD' : 'CDF';
  String get symbol => this == AppCurrency.usd ? '\$' : 'FC';
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(AppCurrency.usd);

  // Exchange rate: 1 USD = 2,800 CDF
  static const int cdfPerUsd = 2800;

  void toggleCurrency() {
    state = state == AppCurrency.usd ? AppCurrency.cdf : AppCurrency.usd;
  }

  void setCurrency(AppCurrency currency) {
    state = currency;
  }

  static String formatAmount({
    required int amountUsdCents,
    required int amountCdf,
    required AppCurrency activeCurrency,
    bool compact = false,
  }) {
    if (activeCurrency == AppCurrency.usd) {
      final double dollars = amountUsdCents / 100.0;
      if (compact && dollars >= 1000) {
        return '\$${(dollars / 1000).toStringAsFixed(1)}k';
      }
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: dollars % 1 == 0 ? 0 : 2);
      return formatter.format(dollars);
    } else {
      if (compact && amountCdf >= 1000000) {
        return '${(amountCdf / 1000000).toStringAsFixed(1)}M FC';
      }
      final formatter = NumberFormat('#,###', 'fr_FR');
      return '${formatter.format(amountCdf)} FC';
    }
  }

  static int convertUsdToCdf(int usdCents) {
    return (usdCents / 100 * cdfPerUsd).round();
  }

  static int convertCdfToUsdCents(int cdf) {
    return ((cdf / cdfPerUsd) * 100).round();
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});
