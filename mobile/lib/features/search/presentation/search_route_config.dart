import '../domain/search_domain.dart';

class SearchRouteConfig {
  const SearchRouteConfig({
    this.query = '',
    this.scope = SearchScope.global,
    this.domains = const [],
  });

  final String query;
  final SearchScope scope;
  final List<SearchDomain> domains;

  factory SearchRouteConfig.fromQueryParameters(Map<String, String> params) {
    final scope =
        SearchScope.fromApiValue(params['scope']) ?? SearchScope.global;
    final matchingDomain = scope.matchingDomain;

    return SearchRouteConfig(
      query: (params['q'] ?? params['query'] ?? '').trim(),
      scope: scope,
      domains: matchingDomain == null
          ? _parseDomains(params['domains'])
          : [matchingDomain],
    );
  }

  String location() {
    final params = <String, String>{};
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (scope != SearchScope.global) params['scope'] = scope.apiValue;
    if (domains.isNotEmpty) {
      params['domains'] = domains.map((domain) => domain.apiValue).join(',');
    }
    final uri = Uri(path: '/search', queryParameters: params);
    return uri.toString();
  }
}

List<SearchDomain> _parseDomains(String? raw) {
  final domains = <SearchDomain>[];
  final seen = <SearchDomain>{};
  for (final token in (raw ?? '').split(',')) {
    final domain = SearchDomain.fromApiValue(token);
    if (domain == null || !seen.add(domain)) continue;
    domains.add(domain);
  }
  return domains;
}
