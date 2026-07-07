import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/search_domain.dart';
import '../domain/search_event.dart';
import '../domain/search_result.dart';
import 'search_client.dart';

class SearchApi implements SearchClient {
  SearchApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<SearchPage> search({
    required String query,
    required SearchScope scope,
    Iterable<SearchDomain> domains = const [],
    String? locale,
    double? latitude,
    double? longitude,
    int pageSize = 20,
    int? groupPageSize,
    String? pageToken,
  }) async {
    final params = <String, dynamic>{
      'scope': scope.apiValue,
      'page_size': pageSize,
    };
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) params['q'] = normalizedQuery;
    final domainParam = _domainParam(domains);
    if (domainParam.isNotEmpty) params['domains'] = domainParam;
    if (locale != null && locale.trim().isNotEmpty) {
      params['locale'] = locale.trim();
    }
    if (latitude != null) params['lat'] = latitude;
    if (longitude != null) params['lng'] = longitude;
    if (groupPageSize != null && groupPageSize > 0) {
      params['group_page_size'] = groupPageSize;
    }
    if (pageToken != null && pageToken.trim().isNotEmpty) {
      params['page_token'] = pageToken.trim();
    }

    final response = await _apiClient.dio.get(
      '/search',
      queryParameters: params,
      options: Options(
        extra: const {'requiresAuth': false, 'optionalAuth': true},
      ),
    );
    return SearchPage.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  @override
  Future<List<SearchSuggestion>> suggest({
    required String query,
    required SearchScope scope,
    Iterable<SearchDomain> domains = const [],
    int limit = 5,
    String? locale,
  }) async {
    final params = <String, dynamic>{'scope': scope.apiValue, 'limit': limit};
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) params['q'] = normalizedQuery;
    final domainParam = _domainParam(domains);
    if (domainParam.isNotEmpty) params['domains'] = domainParam;
    if (locale != null && locale.trim().isNotEmpty) {
      params['locale'] = locale.trim();
    }

    final response = await _apiClient.dio.get(
      '/search/suggest',
      queryParameters: params,
      options: Options(
        extra: const {'requiresAuth': false, 'optionalAuth': true},
      ),
    );
    final data = response.data as Map<String, dynamic>? ?? {};
    final items = data['suggestions'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SearchSuggestion.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> trackEvent(SearchTrackingEvent event) async {
    final body = <String, dynamic>{
      'eventType': event.type.apiValue,
      'scope': event.scope.apiValue,
    };

    void putString(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        body[key] = normalized;
      }
    }

    putString('searchSessionId', event.searchSessionId);
    putString('query', event.query);
    putString('domain', event.domain?.apiValue);
    putString('entityId', event.entityId);
    putString('locale', event.locale);
    if (event.resultPosition != null) {
      body['resultPosition'] = event.resultPosition;
    }

    await _apiClient.dio.post(
      '/search/events',
      data: body,
      options: Options(
        extra: const {'requiresAuth': false, 'optionalAuth': true},
      ),
    );
  }

  String _domainParam(Iterable<SearchDomain> domains) {
    final values = <String>[];
    final seen = <SearchDomain>{};
    for (final domain in domains) {
      if (seen.add(domain)) values.add(domain.apiValue);
    }
    return values.join(',');
  }
}
