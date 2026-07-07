import 'search_domain.dart';

enum SearchTrackingEventType {
  searchSubmitted('search_submitted'),
  resultClicked('result_clicked'),
  zeroResults('zero_results'),
  searchFailed('search_failed');

  const SearchTrackingEventType(this.apiValue);

  final String apiValue;
}

class SearchTrackingEvent {
  const SearchTrackingEvent({
    required this.type,
    required this.scope,
    this.searchSessionId,
    this.query,
    this.domain,
    this.entityId,
    this.resultPosition,
    this.locale,
  });

  final SearchTrackingEventType type;
  final SearchScope scope;
  final String? searchSessionId;
  final String? query;
  final SearchDomain? domain;
  final String? entityId;
  final int? resultPosition;
  final String? locale;
}
