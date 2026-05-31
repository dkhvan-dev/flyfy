import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/currency_conversion_result.dart';

class CurrencyApi {
  CurrencyApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CurrencyConversionResult> convert({
    required String amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final response = await _apiClient.dio.post(
      '/currency/convert',
      data: {
        'amount': amount.trim(),
        'fromCurrency': fromCurrency.trim().toUpperCase(),
        'toCurrency': toCurrency.trim().toUpperCase(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    return CurrencyConversionResult.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<List<CurrencyOption>> listCurrencies() async {
    final response = await _apiClient.dio.get(
      '/reference/currencies',
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data;
    final items = (data is Map<String, dynamic>
            ? data['items'] as List<dynamic>?
            : null) ??
        const [];

    final currencies = items
        .whereType<Map<String, dynamic>>()
        .map(CurrencyOption.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList(growable: false);

    if (currencies.isEmpty) {
      return defaultCurrencyOptions;
    }
    return currencies;
  }
}

const defaultCurrencyOptions = [
  CurrencyOption(code: 'KZT', name: 'Kazakhstani tenge', symbol: '₸'),
  CurrencyOption(code: 'USD', name: 'US dollar', symbol: r'$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'RUB', name: 'Russian ruble', symbol: '₽'),
  CurrencyOption(code: 'TRY', name: 'Turkish lira', symbol: '₺'),
  CurrencyOption(
      code: 'AED', name: 'United Arab Emirates dirham', symbol: 'د.إ'),
  CurrencyOption(code: 'GBP', name: 'British pound', symbol: '£'),
  CurrencyOption(code: 'CNY', name: 'Chinese yuan', symbol: '¥'),
  CurrencyOption(code: 'JPY', name: 'Japanese yen', symbol: '¥'),
  CurrencyOption(code: 'KRW', name: 'South Korean won', symbol: '₩'),
  CurrencyOption(code: 'UZS', name: 'Uzbekistani som', symbol: "so'm"),
  CurrencyOption(code: 'KGS', name: 'Kyrgyzstani som', symbol: 'с'),
];
