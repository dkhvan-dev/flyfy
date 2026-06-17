import '../../core/network/reference_api.dart';

typedef ReferenceCountryLookup =
    Future<ReferenceCountry?> Function(String code, {required String lang});

typedef ReferenceCityLookup =
    Future<ReferenceCity?> Function(String id, {required String lang});

typedef ReferenceCitySearchLookup =
    Future<List<ReferenceCity>> Function(
      String query, {
      String? countryCode,
      required String lang,
      int limit,
    });

typedef ReferenceCitiesByCountryLookup =
    Future<List<ReferenceCity>> Function(
      String countryCode, {
      required String lang,
    });

class AppLocationLabelResolver {
  AppLocationLabelResolver({
    ReferenceApi? api,
    this._countryLookup,
    this._cityLookup,
    this._citySearchLookup,
    this._citiesByCountryLookup,
  }) : _api = api ?? ReferenceApi();

  final ReferenceApi _api;
  final ReferenceCountryLookup? _countryLookup;
  final ReferenceCityLookup? _cityLookup;
  final ReferenceCitySearchLookup? _citySearchLookup;
  final ReferenceCitiesByCountryLookup? _citiesByCountryLookup;

  final Map<String, ReferenceCountry?> _countryCache = {};
  final Map<String, ReferenceCity?> _cityCache = {};
  final Map<String, ReferenceCity?> _citySearchCache = {};
  final Map<String, List<ReferenceCity>> _citiesByCountryCache = {};
  final Map<String, Future<ReferenceCountry?>> _countryInFlight = {};
  final Map<String, Future<ReferenceCity?>> _cityInFlight = {};
  final Map<String, Future<ReferenceCity?>> _citySearchInFlight = {};
  final Map<String, Future<List<ReferenceCity>>> _citiesByCountryInFlight = {};

  Future<String> resolve({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) async {
    final labels = await _resolveLabels(
      countryCode: countryCode,
      cityId: cityId,
      cityName: cityName,
      localeName: localeName,
    );

    return formatLocationLabel(city: labels.city, country: labels.country);
  }

  Future<String> resolveCity({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) async {
    final labels = await _resolveLabels(
      countryCode: countryCode,
      cityId: cityId,
      cityName: cityName,
      localeName: localeName,
    );

    return labels.city ?? '';
  }

  Future<String> resolveAddress({
    String? countryCode,
    String? cityId,
    String? cityName,
    String? addressText,
    required String localeName,
  }) async {
    final labels = await _resolveLabels(
      countryCode: countryCode,
      cityId: cityId,
      cityName: cityName,
      localeName: localeName,
    );
    final addressRemainder = _stripLeadingStructuredLocation(
      address: addressText,
      localizedCity: labels.city,
      rawCity: cityName,
      localizedCountry: labels.country,
      countryCode: countryCode,
    );

    return formatLocationAddressLabel(
      city: labels.city,
      country: labels.country,
      address: addressRemainder,
    );
  }

  Future<_ResolvedLocationLabels> _resolveLabels({
    String? countryCode,
    String? cityId,
    String? cityName,
    required String localeName,
  }) async {
    final lang = _normalizeLanguage(localeName);
    final normalizedCountryCode = _normalizeCountryCode(countryCode);
    final normalizedCityId = _normalizeText(cityId);
    final normalizedCityName = _normalizeText(cityName);

    final countryFuture = normalizedCountryCode == null
        ? Future<ReferenceCountry?>.value()
        : _resolveCountry(normalizedCountryCode, lang);
    final cityFuture = normalizedCityId == null
        ? Future<ReferenceCity?>.value()
        : _resolveCity(normalizedCityId, lang);

    final results = await Future.wait([countryFuture, cityFuture]);
    final country = results[0] as ReferenceCountry?;
    var city = results[1] as ReferenceCity?;

    if (city == null && normalizedCityName != null) {
      city = await _resolveCityByName(
        normalizedCityName,
        countryCode: normalizedCountryCode,
        lang: lang,
      );
    }

    if (city == null &&
        normalizedCountryCode != null &&
        normalizedCityId != null) {
      city = await _resolveCityFromCountryCatalog(
        normalizedCountryCode,
        cityId: normalizedCityId,
        cityName: normalizedCityName,
        lang: lang,
      );
    }

    final cityLabel = _normalizeText(city?.name) ?? normalizedCityName;
    final countryLabel = _normalizeText(country?.name);

    return _ResolvedLocationLabels(city: cityLabel, country: countryLabel);
  }

  Future<ReferenceCountry?> _resolveCountry(String code, String lang) async {
    final key = '$lang|$code';
    if (_countryCache.containsKey(key)) {
      return _countryCache[key];
    }
    final inFlight = _countryInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }
    final lookup = (_countryLookup ?? _api.getCountry)(code, lang: lang)
        .then((country) {
          _countryCache[key] = country;
          return country;
        })
        .whenComplete(() {
          _countryInFlight.remove(key);
        });
    _countryInFlight[key] = lookup;
    return lookup;
  }

  Future<ReferenceCity?> _resolveCity(String id, String lang) async {
    final key = '$lang|$id';
    if (_cityCache.containsKey(key)) {
      return _cityCache[key];
    }
    final inFlight = _cityInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }
    final lookup = (_cityLookup ?? _api.getCity)(id, lang: lang)
        .then((city) {
          _cityCache[key] = city;
          return city;
        })
        .whenComplete(() {
          _cityInFlight.remove(key);
        });
    _cityInFlight[key] = lookup;
    return lookup;
  }

  Future<ReferenceCity?> _resolveCityByName(
    String cityName, {
    required String? countryCode,
    required String lang,
  }) async {
    final normalizedCityName = _normalizeText(cityName);
    if (normalizedCityName == null) {
      return null;
    }

    final normalizedCountryCode = _normalizeCountryCode(countryCode);
    final key = '$lang|${normalizedCountryCode ?? ''}|$normalizedCityName';
    if (_citySearchCache.containsKey(key)) {
      return _citySearchCache[key];
    }
    final inFlight = _citySearchInFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final lookup =
        (_citySearchLookup ?? _api.searchCities)(
              normalizedCityName,
              countryCode: normalizedCountryCode,
              lang: lang,
              limit: 5,
            )
            .then(
              (cities) => _pickBestCityMatch(
                cities,
                cityName: normalizedCityName,
                countryCode: normalizedCountryCode,
              ),
            )
            .then((city) {
              _citySearchCache[key] = city;
              return city;
            })
            .whenComplete(() {
              _citySearchInFlight.remove(key);
            });
    _citySearchInFlight[key] = lookup;
    return lookup;
  }

  Future<ReferenceCity?> _resolveCityFromCountryCatalog(
    String countryCode, {
    required String? cityId,
    required String? cityName,
    required String lang,
  }) async {
    final cities = await _resolveCitiesByCountry(countryCode, lang);
    if (cities.isEmpty) return null;

    final normalizedCityId = cityId?.trim().toLowerCase();
    if (normalizedCityId != null && normalizedCityId.isNotEmpty) {
      for (final city in cities) {
        if (city.id.trim().toLowerCase() == normalizedCityId) {
          return city;
        }
      }
    }

    final normalizedCityName = cityName?.trim().toLowerCase();
    if (normalizedCityName != null && normalizedCityName.isNotEmpty) {
      return _pickBestCityMatch(
        cities,
        cityName: normalizedCityName,
        countryCode: countryCode,
      );
    }

    return null;
  }

  Future<List<ReferenceCity>> _resolveCitiesByCountry(
    String countryCode,
    String lang,
  ) async {
    final key = '$lang|$countryCode';
    final cached = _citiesByCountryCache[key];
    if (cached != null) return cached;
    final inFlight = _citiesByCountryInFlight[key];
    if (inFlight != null) return inFlight;

    final lookup =
        (_citiesByCountryLookup ?? _api.citiesByCountry)(
              countryCode,
              lang: lang,
            )
            .then((cities) {
              _citiesByCountryCache[key] = cities;
              return cities;
            })
            .catchError((Object _) {
              _citiesByCountryCache[key] = const <ReferenceCity>[];
              return const <ReferenceCity>[];
            })
            .whenComplete(() {
              _citiesByCountryInFlight.remove(key);
            });
    _citiesByCountryInFlight[key] = lookup;
    return lookup;
  }
}

class _ResolvedLocationLabels {
  const _ResolvedLocationLabels({this.city, this.country});

  final String? city;
  final String? country;
}

ReferenceCity? _pickBestCityMatch(
  List<ReferenceCity> cities, {
  required String cityName,
  required String? countryCode,
}) {
  if (cities.isEmpty) {
    return null;
  }

  final normalizedCountryCode = _normalizeCountryCode(countryCode);
  final normalizedCityName = cityName.toLowerCase();
  final countryMatches = normalizedCountryCode == null
      ? cities
      : cities
            .where(
              (city) =>
                  city.countryCode.trim().toUpperCase() ==
                  normalizedCountryCode,
            )
            .toList(growable: false);
  final candidates = countryMatches.isEmpty ? cities : countryMatches;

  for (final city in candidates) {
    if (city.name.trim().toLowerCase() == normalizedCityName) {
      return city;
    }
  }

  return candidates.first;
}

String formatLocationLabel({String? city, String? country}) {
  final parts = [
    _normalizeText(city),
    _normalizeText(country),
  ].whereType<String>().toList(growable: false);
  return parts.join(', ');
}

String formatLocationAddressLabel({
  String? city,
  String? country,
  String? address,
}) {
  final parts = <String>[];

  void addPart(String? value) {
    final normalized = _normalizeText(value);
    if (normalized == null) return;

    final normalizedKey = normalized.toLowerCase();
    final alreadyAdded = parts.any(
      (part) => part.toLowerCase() == normalizedKey,
    );
    if (alreadyAdded) return;

    parts.add(normalized);
  }

  addPart(city);
  addPart(country);
  final addressParts = _normalizeText(address)?.split(',') ?? const <String>[];
  for (final part in addressParts) {
    addPart(part);
  }

  return parts.join(', ');
}

String? _stripLeadingStructuredLocation({
  required String? address,
  required String? localizedCity,
  required String? rawCity,
  required String? localizedCountry,
  required String? countryCode,
}) {
  final normalizedAddress = _normalizeText(address);
  if (normalizedAddress == null) return null;

  final parts = normalizedAddress
      .split(',')
      .map((part) => _normalizeText(part))
      .whereType<String>()
      .toList(growable: false);
  if (parts.length < 2) {
    return normalizedAddress;
  }

  var start = 0;
  if (_matchesAny(parts[start], [localizedCity, rawCity])) {
    start = 1;
    if (parts.length > 2) {
      start = 2;
    }
  } else if (_matchesAny(parts[start], [localizedCountry, countryCode])) {
    start = 1;
  }

  if (start <= 0 || start >= parts.length) {
    return normalizedAddress;
  }
  return parts.skip(start).join(', ');
}

bool _matchesAny(String value, Iterable<String?> candidates) {
  final normalizedValue = value.trim().toLowerCase();
  if (normalizedValue.isEmpty) return false;

  for (final candidate in candidates) {
    final normalizedCandidate = candidate?.trim().toLowerCase();
    if (normalizedCandidate != null &&
        normalizedCandidate.isNotEmpty &&
        normalizedCandidate == normalizedValue) {
      return true;
    }
  }
  return false;
}

String _normalizeLanguage(String localeName) {
  final value = localeName.trim();
  if (value.isEmpty) return 'en';
  return value.split(RegExp('[-_]')).first.toLowerCase();
}

String? _normalizeCountryCode(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

String? _normalizeText(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
