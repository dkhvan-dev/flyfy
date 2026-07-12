import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/currency/data/currency_api.dart';
import 'package:inflap/features/currency/data/currency_catalog_repository.dart';
import 'package:inflap/features/currency/models/currency_conversion_result.dart';

void main() {
  test(
    'merges localized reference currencies with the offline catalog',
    () async {
      final repository = CurrencyCatalogRepository(
        api: _CurrencyApiStub([
          const CurrencyOption(
            code: 'VND',
            name: 'Вьетнамский донг',
            symbol: '',
          ),
          const CurrencyOption(code: 'THB', name: 'Тайский бат', symbol: '฿'),
        ]),
      );

      final currencies = await repository.listCurrencies(locale: 'ru');
      final byCode = {for (final item in currencies) item.code: item};

      expect(byCode['VND']?.name, 'Вьетнамский донг');
      expect(byCode['VND']?.symbol, '₫');
      expect(byCode['THB']?.name, 'Тайский бат');
      expect(byCode, contains('KZT'));
      expect(repository.cachedCurrencies(locale: 'ru'), same(currencies));
    },
  );

  test(
    'returns the complete offline catalog when reference loading fails',
    () async {
      final repository = CurrencyCatalogRepository(api: _FailingCurrencyApi());

      final currencies = await repository.listCurrencies(locale: 'kk');
      final codes = currencies.map((item) => item.code).toSet();

      expect(codes, containsAll(['KZT', 'VND', 'THB']));
    },
  );
}

class _CurrencyApiStub extends CurrencyApi {
  _CurrencyApiStub(this.items);

  final List<CurrencyOption> items;

  @override
  Future<List<CurrencyOption>> listCurrencies({String? locale}) async => items;
}

class _FailingCurrencyApi extends CurrencyApi {
  @override
  Future<List<CurrencyOption>> listCurrencies({String? locale}) {
    throw StateError('reference unavailable');
  }
}
