import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/public_guide_vm.dart';

class GuideDiscoveryApi {
  GuideDiscoveryApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PublicGuidesPage> listPublicGuides({
    int limit = 20,
    int offset = 0,
    String? query,
    String? sort,
    double? minRating,
    int? minExperienceYears,
    Iterable<String> countryCodes = const [],
    Iterable<String> languageCodes = const [],
    Iterable<String> specializationCodes = const [],
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit, 'offset': offset};

    final normalizedQuery = query?.trim();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      queryParameters['q'] = normalizedQuery;
    }

    final normalizedSort = sort?.trim();
    if (normalizedSort != null && normalizedSort.isNotEmpty) {
      queryParameters['sort'] = normalizedSort;
    }

    if (minRating != null) {
      queryParameters['minRating'] = minRating;
    }
    if (minExperienceYears != null) {
      queryParameters['minExperienceYears'] = minExperienceYears;
    }

    final countries = _compactCodes(countryCodes);
    if (countries.isNotEmpty) {
      queryParameters['countries'] = countries.join(',');
    }

    final languages = _compactCodes(languageCodes);
    if (languages.isNotEmpty) {
      queryParameters['languages'] = languages.join(',');
    }

    final specializations = _compactCodes(specializationCodes);
    if (specializations.isNotEmpty) {
      queryParameters['specializations'] = specializations.join(',');
    }

    final response = await _apiClient.dio.get(
      '/guides/public',
      queryParameters: queryParameters,
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    final items = data is Map<String, dynamic>
        ? data['items'] as List<dynamic>? ?? const []
        : data is List<dynamic>
            ? data
            : const [];

    final guides = items
        .whereType<Map<String, dynamic>>()
        .map(PublicGuideVm.fromJson)
        .toList(growable: false);

    if (data is! Map<String, dynamic>) {
      return PublicGuidesPage(
        items: guides,
        total: guides.length,
        limit: limit,
        offset: offset,
      );
    }

    return PublicGuidesPage(
      items: guides,
      total: _int(data['total']) ?? guides.length,
      limit: _int(data['limit']) ?? limit,
      offset: _int(data['offset']) ?? offset,
    );
  }
}

class PublicGuidesPage {
  const PublicGuidesPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<PublicGuideVm> items;
  final int total;
  final int limit;
  final int offset;
}

List<String> _compactCodes(Iterable<String> codes) {
  final result = <String>[];
  final seen = <String>{};
  for (final code in codes) {
    final normalized = code.trim();
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    result.add(normalized);
  }
  return result;
}

int? _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
