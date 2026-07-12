import '../models/currency_conversion_result.dart';
import 'currency_api.dart';

class CurrencyCatalogRepository {
  CurrencyCatalogRepository({CurrencyApi? api}) : _api = api ?? CurrencyApi();

  static final shared = CurrencyCatalogRepository();

  final CurrencyApi _api;
  final Map<String, List<CurrencyOption>> _cache = {};

  List<CurrencyOption> cachedCurrencies({String? locale}) {
    return _cache[_localeKey(locale)] ?? defaultCurrencyOptions;
  }

  Future<List<CurrencyOption>> listCurrencies({String? locale}) async {
    final cacheKey = _localeKey(locale);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final remote = await _api.listCurrencies(locale: locale);
      final merged = _mergeWithFallback(remote);
      _cache[cacheKey] = merged;
      return merged;
    } catch (_) {
      return defaultCurrencyOptions;
    }
  }

  List<CurrencyOption> _mergeWithFallback(List<CurrencyOption> remote) {
    final byCode = <String, CurrencyOption>{
      for (final option in defaultCurrencyOptions) option.code: option,
    };
    final remoteOrder = <String>[];
    for (final option in remote) {
      final code = option.code.trim().toUpperCase();
      if (code.isEmpty) continue;
      if (!remoteOrder.contains(code)) remoteOrder.add(code);
      final fallback = byCode[code];
      byCode[code] = CurrencyOption(
        code: code,
        name: option.name.trim().isEmpty
            ? (fallback?.name ?? code)
            : option.name.trim(),
        symbol: option.symbol.trim().isEmpty
            ? (fallback?.symbol ?? '')
            : option.symbol.trim(),
      );
    }

    final fallbackOrder = defaultCurrencyOptions.map((item) => item.code);
    final orderedCodes = <String>{...remoteOrder, ...fallbackOrder};
    final extraCodes =
        byCode.keys
            .where((code) => !orderedCodes.contains(code))
            .toList(growable: false)
          ..sort();
    return List.unmodifiable([
      for (final code in [...orderedCodes, ...extraCodes]) byCode[code]!,
    ]);
  }

  String _localeKey(String? locale) {
    final normalized = locale?.trim().toLowerCase().split(RegExp('[-_]')).first;
    return switch (normalized) {
      'ru' || 'kk' => normalized!,
      _ => 'en',
    };
  }
}
