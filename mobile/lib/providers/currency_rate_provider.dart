import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/currency/data/currency_api.dart';
import '../features/currency/models/currency_conversion_result.dart';
import '../shared/formatters/app_money_formatter.dart';

typedef CurrencyRateLookup =
    Future<CurrencyRateSnapshot> Function({
      required String baseCurrency,
      required Iterable<String> quoteCurrencies,
    });

class CurrencyRateProvider extends ChangeNotifier {
  CurrencyRateProvider({
    CurrencyApi? api,
    this.latestRates,
    DateTime Function()? now,
  }) : _api = api ?? CurrencyApi(),
       _now = now ?? DateTime.now;

  static const _retryCooldown = Duration(minutes: 5);

  final CurrencyApi _api;
  final CurrencyRateLookup? latestRates;
  final DateTime Function() _now;
  final Map<String, double> _rates = {};
  final Set<String> _loadingPairs = {};
  final Map<String, DateTime> _failedAt = {};

  double? convertAmount({
    required num amount,
    required String? fromCurrency,
    required String? toCurrency,
  }) {
    final from = normalizeAppCurrencyCode(fromCurrency);
    final to = normalizeAppCurrencyCode(toCurrency);
    if (from == null || to == null) return null;
    if (from == to) return amount.toDouble();

    final direct = _rates[_pairKey(from, to)];
    if (direct != null) {
      return amount.toDouble() * direct;
    }

    final inverse = _rates[_pairKey(to, from)];
    if (inverse != null && inverse != 0) {
      return amount.toDouble() / inverse;
    }

    _ensureRateLoad(from, to);
    return null;
  }

  void _ensureRateLoad(String from, String to) {
    final key = _pairKey(from, to);
    if (_loadingPairs.contains(key)) return;
    final failedAt = _failedAt[key];
    if (failedAt != null && _now().difference(failedAt) < _retryCooldown) {
      return;
    }

    _loadingPairs.add(key);
    unawaited(_loadRate(from, to));
  }

  Future<void> _loadRate(String from, String to) async {
    final key = _pairKey(from, to);
    try {
      final snapshot = await (latestRates ?? _api.latestRates)(
        baseCurrency: from,
        quoteCurrencies: [to],
      );
      final rate = snapshot.rateFor(to);
      if (rate != null && rate > 0) {
        _rates[key] = rate;
        _failedAt.remove(key);
        notifyListeners();
      } else {
        _failedAt[key] = _now();
      }
    } catch (_) {
      _failedAt[key] = _now();
    } finally {
      _loadingPairs.remove(key);
    }
  }

  String _pairKey(String from, String to) => '$from->$to';
}
