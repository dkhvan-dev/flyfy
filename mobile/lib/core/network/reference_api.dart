import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ReferenceApi {
  ReferenceApi()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        );

  final Dio _dio;

  Future<ReferenceCountry?> getCountry(
    String code, {
    String lang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        '/reference/countries/${code.trim().toUpperCase()}',
        queryParameters: {'lang': lang},
        options: Options(extra: {'requiresAuth': false}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;
      final country = data['country'] as Map<String, dynamic>?;
      if (country == null) return null;
      return ReferenceCountry.fromJson(country);
    } catch (_) {
      return null;
    }
  }

  Future<List<ReferenceCountry>> listCountries({
    String lang = 'en',
  }) async {
    final response = await _dio.get(
      '/reference/countries',
      queryParameters: {'lang': lang},
      options: Options(extra: {'requiresAuth': false}),
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ReferenceCountry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<ReferenceCountry>> searchCountries(
    String query, {
    String lang = 'en',
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return const [];
    final response = await _dio.get(
      '/reference/countries/search',
      queryParameters: {'q': query.trim(), 'lang': lang, 'limit': limit},
      options: Options(extra: {'requiresAuth': false}),
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ReferenceCountry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<ReferenceCity>> searchCities(
    String query, {
    String? countryCode,
    String lang = 'en',
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return const [];
    final params = <String, dynamic>{
      'q': query.trim(),
      'lang': lang,
      'limit': limit,
    };
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      params['country'] = countryCode.trim();
    }
    final response = await _dio.get(
      '/reference/cities/search',
      queryParameters: params,
      options: Options(extra: {'requiresAuth': false}),
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ReferenceCity.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<ReferenceCity>> citiesByCountry(
    String countryCode, {
    String lang = 'en',
  }) async {
    final response = await _dio.get(
      '/reference/countries/${countryCode.trim().toUpperCase()}/cities',
      queryParameters: {'lang': lang},
      options: Options(extra: {'requiresAuth': false}),
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => ReferenceCity.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class ReferenceCountry {
  const ReferenceCountry({
    required this.code,
    required this.name,
    this.phoneCode,
  });

  final String code;
  final String name;
  final String? phoneCode;

  factory ReferenceCountry.fromJson(Map<String, dynamic> json) {
    return ReferenceCountry(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneCode: json['phoneCode']?.toString(),
    );
  }
}

class ReferenceCity {
  const ReferenceCity({
    required this.id,
    required this.countryCode,
    required this.name,
    this.population = 0,
  });

  final String id;
  final String countryCode;
  final String name;
  final int population;

  factory ReferenceCity.fromJson(Map<String, dynamic> json) {
    return ReferenceCity(
      id: json['id']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      population: int.tryParse(json['population']?.toString() ?? '') ?? 0,
    );
  }
}
