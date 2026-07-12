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

  Future<List<CurrencyOption>> listCurrencies({String? locale}) async {
    final lang = _referenceLocale(locale);
    final response = await _apiClient.dio.get(
      '/reference/currencies',
      queryParameters: lang == null ? null : {'lang': lang},
      options: Options(extra: const {'requiresAuth': false}),
    );
    final data = response.data;
    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    } else {
      items = const [];
    }

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

  Future<CurrencyRateSnapshot> latestRates({
    required String baseCurrency,
    required Iterable<String> quoteCurrencies,
  }) async {
    final base = baseCurrency.trim().toUpperCase();
    final quotes = quoteCurrencies
        .map((currency) => currency.trim().toUpperCase())
        .where((currency) => currency.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final response = await _apiClient.dio.get(
      '/exchange-rates/latest',
      queryParameters: {
        'base': base,
        if (quotes.isNotEmpty) 'quotes': quotes.join(','),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    return CurrencyRateSnapshot.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  String? _referenceLocale(String? locale) {
    final normalized = locale?.trim().toLowerCase().split(RegExp('[-_]')).first;
    return switch (normalized) {
      'en' || 'ru' || 'kk' => normalized,
      _ => null,
    };
  }
}

const defaultCurrencyOptions = [
  CurrencyOption(code: 'KZT', name: 'Kazakhstani tenge', symbol: '₸'),
  CurrencyOption(code: 'USD', name: 'US dollar', symbol: r'$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'RUB', name: 'Russian ruble', symbol: '₽'),
  CurrencyOption(code: 'UZS', name: 'Uzbekistani som', symbol: "so'm"),
  CurrencyOption(code: 'KGS', name: 'Kyrgyzstani som', symbol: 'с'),
  CurrencyOption(code: 'TJS', name: 'Tajikistani somoni', symbol: 'SM'),
  CurrencyOption(code: 'TMT', name: 'Turkmen manat', symbol: 'm'),
  CurrencyOption(code: 'GEL', name: 'Georgian lari', symbol: '₾'),
  CurrencyOption(code: 'AZN', name: 'Azerbaijani manat', symbol: '₼'),
  CurrencyOption(code: 'AMD', name: 'Armenian dram', symbol: '֏'),
  CurrencyOption(code: 'BYN', name: 'Belarusian ruble', symbol: 'Br'),
  CurrencyOption(code: 'RSD', name: 'Serbian dinar', symbol: 'дин.'),
  CurrencyOption(code: 'UAH', name: 'Ukrainian hryvnia', symbol: '₴'),
  CurrencyOption(code: 'MDL', name: 'Moldovan leu', symbol: 'L'),
  CurrencyOption(code: 'TRY', name: 'Turkish lira', symbol: '₺'),
  CurrencyOption(
    code: 'AED',
    name: 'United Arab Emirates dirham',
    symbol: 'د.إ',
  ),
  CurrencyOption(code: 'VND', name: 'Vietnamese dong', symbol: '₫'),
  CurrencyOption(code: 'THB', name: 'Thai baht', symbol: '฿'),
  CurrencyOption(code: 'PHP', name: 'Philippine peso', symbol: '₱'),
  CurrencyOption(code: 'EGP', name: 'Egyptian pound', symbol: 'E£'),
  CurrencyOption(code: 'CNY', name: 'Chinese yuan', symbol: '¥'),
  CurrencyOption(code: 'KRW', name: 'South Korean won', symbol: '₩'),
  CurrencyOption(code: 'JPY', name: 'Japanese yen', symbol: '¥'),
  CurrencyOption(code: 'CHF', name: 'Swiss franc', symbol: 'CHF'),
  CurrencyOption(code: 'INR', name: 'Indian rupee', symbol: '₹'),
  CurrencyOption(code: 'AUD', name: 'Australian dollar', symbol: r'$'),
  CurrencyOption(code: 'NZD', name: 'New Zealand dollar', symbol: r'$'),
  CurrencyOption(code: 'TZS', name: 'Tanzanian shilling', symbol: 'TSh'),
  CurrencyOption(code: 'KES', name: 'Kenyan shilling', symbol: 'KSh'),
  CurrencyOption(code: 'CAD', name: 'Canadian dollar', symbol: r'$'),
  CurrencyOption(code: 'SGD', name: 'Singapore dollar', symbol: r'$'),
  CurrencyOption(code: 'GBP', name: 'British pound', symbol: '£'),
  CurrencyOption(code: 'MNT', name: 'Mongolian tugrik', symbol: '₮'),
  CurrencyOption(code: 'MYR', name: 'Malaysian ringgit', symbol: 'RM'),
  CurrencyOption(code: 'IDR', name: 'Indonesian rupiah', symbol: 'Rp'),
  CurrencyOption(code: 'MVR', name: 'Maldivian rufiyaa', symbol: 'Rf'),
  CurrencyOption(code: 'SCR', name: 'Seychellois rupee', symbol: 'SR'),
  CurrencyOption(code: 'PLN', name: 'Polish zloty', symbol: 'zł'),
  CurrencyOption(code: 'MXN', name: 'Mexican peso', symbol: r'$'),
  CurrencyOption(code: 'BRL', name: 'Brazilian real', symbol: r'R$'),
  CurrencyOption(code: 'ARS', name: 'Argentine peso', symbol: r'$'),
  CurrencyOption(code: 'LKR', name: 'Sri Lankan rupee', symbol: 'Rs'),
  CurrencyOption(code: 'CUP', name: 'Cuban peso', symbol: r'$'),
  CurrencyOption(code: 'MAD', name: 'Moroccan dirham', symbol: 'DH'),
  CurrencyOption(code: 'ISK', name: 'Icelandic krona', symbol: 'kr'),
  CurrencyOption(code: 'DKK', name: 'Danish krone', symbol: 'kr'),
  CurrencyOption(code: 'SEK', name: 'Swedish krona', symbol: 'kr'),
  CurrencyOption(code: 'CZK', name: 'Czech koruna', symbol: 'Kč'),
];
