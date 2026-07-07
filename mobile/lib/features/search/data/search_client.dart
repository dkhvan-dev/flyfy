import '../domain/search_domain.dart';
import '../domain/search_event.dart';
import '../domain/search_result.dart';

abstract class SearchClient {
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
  });

  Future<List<SearchSuggestion>> suggest({
    required String query,
    required SearchScope scope,
    Iterable<SearchDomain> domains = const [],
    int limit = 5,
    String? locale,
  });

  Future<void> trackEvent(SearchTrackingEvent event);
}
