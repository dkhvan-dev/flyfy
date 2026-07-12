import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/currency/data/currency_api.dart';

void main() {
  test(
    'convert sends a public request and parses the conversion result',
    () async {
      final adapter = _CurrencyConvertAdapter();
      final api = CurrencyApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final result = await api.convert(
        amount: '15000',
        fromCurrency: 'KZT',
        toCurrency: 'USD',
      );

      expect(adapter.requestPath, '/api/v1/currency/convert');
      expect(adapter.requiresAuth, isFalse);
      expect(adapter.body, {
        'amount': '15000',
        'fromCurrency': 'KZT',
        'toCurrency': 'USD',
      });
      expect(result.sourceCurrency, 'KZT');
      expect(result.targetCurrency, 'USD');
      expect(result.sourceAmount, '15000.00');
      expect(result.convertedAmount, '29.59');
      expect(result.rate, '0.001972386587771203');
      expect(result.stale, isFalse);
    },
  );

  test('listCurrencies requests localized reference currencies', () async {
    final adapter = _CurrencyListAdapter();
    final api = CurrencyApi(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
          ..httpClientAdapter = adapter,
        secureStorage: _FakeSecureStorage(),
      ),
    );

    final currencies = await api.listCurrencies(locale: 'ru');

    expect(adapter.requestPath, '/api/v1/reference/currencies');
    expect(adapter.queryParameters, {'lang': 'ru'});
    expect(adapter.requiresAuth, isFalse);
    expect(currencies.single.code, 'USD');
    expect(currencies.single.name, 'Доллар США');
  });

  test(
    'latestRates requests public exchange rates and parses snapshot',
    () async {
      final adapter = _CurrencyRatesAdapter();
      final api = CurrencyApi(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
            ..httpClientAdapter = adapter,
          secureStorage: _FakeSecureStorage(),
        ),
      );

      final rates = await api.latestRates(
        baseCurrency: ' kzt ',
        quoteCurrencies: const [' usd ', 'eur'],
      );

      expect(adapter.requestPath, '/api/v1/exchange-rates/latest');
      expect(adapter.queryParameters, {'base': 'KZT', 'quotes': 'USD,EUR'});
      expect(adapter.requiresAuth, isFalse);
      expect(rates.baseCurrency, 'KZT');
      expect(rates.rateFor('usd'), 0.0019);
      expect(rates.rateFor('EUR'), 0.0017);
      expect(rates.stale, isFalse);
    },
  );

  test('default currency fallback covers popular travel currencies', () {
    final codes = defaultCurrencyOptions
        .map((currency) => currency.code)
        .toSet();

    for (final code in _referenceTravelCurrencyCodes) {
      expect(codes, contains(code), reason: 'Missing fallback currency $code');
    }
  });
}

const _referenceTravelCurrencyCodes = [
  'AED',
  'AMD',
  'ARS',
  'AUD',
  'AZN',
  'BRL',
  'BYN',
  'CAD',
  'CHF',
  'CNY',
  'CUP',
  'CZK',
  'DKK',
  'EGP',
  'EUR',
  'GBP',
  'GEL',
  'IDR',
  'INR',
  'ISK',
  'JPY',
  'KES',
  'KGS',
  'KRW',
  'KZT',
  'LKR',
  'MAD',
  'MDL',
  'MNT',
  'MVR',
  'MXN',
  'MYR',
  'NZD',
  'PHP',
  'PLN',
  'RSD',
  'RUB',
  'SCR',
  'SEK',
  'SGD',
  'THB',
  'TJS',
  'TMT',
  'TRY',
  'TZS',
  'UAH',
  'USD',
  'UZS',
  'VND',
];

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;
}

class _CurrencyConvertAdapter implements HttpClientAdapter {
  String? requestPath;
  bool? requiresAuth;
  Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    final requestBytes = await requestStream?.expand((chunk) => chunk).toList();
    body =
        jsonDecode(utf8.decode(requestBytes ?? const []))
            as Map<String, dynamic>;

    return ResponseBody.fromString(
      jsonEncode({
        'sourceAmount': '15000.00',
        'sourceCurrency': 'KZT',
        'convertedAmount': '29.59',
        'targetCurrency': 'USD',
        'rate': '0.001972386587771203',
        'rateAsOf': '2026-05-31T00:00:00Z',
        'provider': 'frankfurter',
        'stale': false,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CurrencyListAdapter implements HttpClientAdapter {
  String? requestPath;
  bool? requiresAuth;
  Map<String, String>? queryParameters;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    queryParameters = options.uri.queryParameters;

    return ResponseBody.fromString(
      jsonEncode([
        {'code': 'USD', 'name': 'Доллар США', 'symbol': r'$'},
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CurrencyRatesAdapter implements HttpClientAdapter {
  String? requestPath;
  bool? requiresAuth;
  Map<String, String>? queryParameters;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPath = options.uri.path;
    requiresAuth = options.extra['requiresAuth'] as bool?;
    queryParameters = options.uri.queryParameters;

    return ResponseBody.fromString(
      jsonEncode({
        'baseCurrency': 'KZT',
        'rates': {'USD': 0.0019, 'EUR': '0.0017'},
        'rateAsOf': '2026-05-31T00:00:00Z',
        'provider': 'open-er-api',
        'stale': false,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
