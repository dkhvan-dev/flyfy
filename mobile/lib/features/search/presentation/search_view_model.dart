import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/search_client.dart';
import '../domain/search_domain.dart';
import '../domain/search_event.dart';
import '../domain/search_result.dart';

enum SearchState { idle, loading, loaded, error }

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required this.client,
    this.scope = SearchScope.global,
    Iterable<SearchDomain> domains = const [],
    this.debounceDuration = const Duration(milliseconds: 300),
    this.pageSize = 5,
    this.groupPageSize = 5,
    this.locale,
    String? searchSessionId,
  }) : domains = List<SearchDomain>.unmodifiable(domains),
       searchSessionId = searchSessionId ?? _newSearchSessionId();

  final SearchClient client;
  final SearchScope scope;
  final List<SearchDomain> domains;
  final Duration debounceDuration;
  final int pageSize;
  final int groupPageSize;
  final String? locale;
  final String searchSessionId;

  Timer? _debounceTimer;
  int _requestSerial = 0;
  String _query = '';
  SearchState _state = SearchState.idle;
  SearchPage? _page;
  Object? _error;
  bool _isLoadingMoreTopResults = false;
  Object? _loadMoreTopResultsError;
  final Set<SearchDomain> _loadingMoreDomains = <SearchDomain>{};
  final Map<SearchDomain, Object> _loadMoreErrors = <SearchDomain, Object>{};

  String get query => _query;
  SearchState get state => _state;
  SearchPage? get page => _page;
  Object? get error => _error;
  bool get isLoading => _state == SearchState.loading;
  bool get isLoadingMoreTopResults => _isLoadingMoreTopResults;
  Object? get loadMoreTopResultsError => _loadMoreTopResultsError;
  bool isLoadingMore(SearchDomain domain) =>
      _loadingMoreDomains.contains(domain);
  Object? loadMoreError(SearchDomain domain) => _loadMoreErrors[domain];

  void updateQuery(String value) {
    _query = value;
    _error = null;
    notifyListeners();
  }

  void scheduleSearch() {
    _debounceTimer?.cancel();
    if (debounceDuration == Duration.zero) {
      unawaited(submitSearch());
      return;
    }
    _debounceTimer = Timer(debounceDuration, () {
      unawaited(submitSearch());
    });
  }

  void reset() {
    _debounceTimer?.cancel();
    _requestSerial++;
    _state = SearchState.idle;
    _page = null;
    _error = null;
    _isLoadingMoreTopResults = false;
    _loadMoreTopResultsError = null;
    _loadingMoreDomains.clear();
    _loadMoreErrors.clear();
    notifyListeners();
  }

  Future<void> submitSearch() async {
    _debounceTimer?.cancel();
    final requestId = ++_requestSerial;
    final normalizedQuery = _query.trim();
    _state = SearchState.loading;
    _error = null;
    _isLoadingMoreTopResults = false;
    _loadMoreTopResultsError = null;
    _loadingMoreDomains.clear();
    _loadMoreErrors.clear();
    notifyListeners();

    try {
      final nextPage = await client.search(
        query: normalizedQuery,
        scope: scope,
        domains: domains,
        locale: locale,
        pageSize: pageSize,
        groupPageSize: groupPageSize,
      );
      if (requestId != _requestSerial) return;
      _page = nextPage;
      _state = SearchState.loaded;
      _trackEvent(
        SearchTrackingEventType.searchSubmitted,
        query: normalizedQuery,
      );
      if (!_hasResults(nextPage)) {
        _trackEvent(
          SearchTrackingEventType.zeroResults,
          query: normalizedQuery,
        );
      }
    } catch (exception) {
      if (requestId != _requestSerial) return;
      _error = exception;
      _state = SearchState.error;
      _trackEvent(SearchTrackingEventType.searchFailed, query: normalizedQuery);
    }
    notifyListeners();
  }

  Future<void> loadMoreTopResults() async {
    final currentPage = _page;
    if (currentPage == null || _isLoadingMoreTopResults) return;

    final pageToken = currentPage.nextPageToken?.trim();
    if (pageToken == null || pageToken.isEmpty) return;

    final requestId = _requestSerial;
    _isLoadingMoreTopResults = true;
    _loadMoreTopResultsError = null;
    notifyListeners();

    try {
      final nextPage = await client.search(
        query: _query.trim(),
        scope: scope,
        domains: domains,
        locale: locale,
        pageSize: pageSize,
        groupPageSize: groupPageSize,
        pageToken: pageToken,
      );
      if (requestId != _requestSerial || _page == null) return;

      _page = SearchPage(
        query: _page!.query,
        locale: _page!.locale,
        topResults: [..._page!.topResults, ...nextPage.topResults],
        groups: _page!.groups,
        nextPageToken: nextPage.nextPageToken,
      );
    } catch (exception) {
      if (requestId == _requestSerial) {
        _loadMoreTopResultsError = exception;
      }
    } finally {
      _isLoadingMoreTopResults = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreGroup(SearchDomain domain) async {
    final currentPage = _page;
    if (currentPage == null || _loadingMoreDomains.contains(domain)) return;

    final currentGroup = currentPage.groups.byDomain(domain);
    final pageToken = currentGroup.nextPageToken?.trim();
    if (pageToken == null || pageToken.isEmpty) return;

    final requestId = _requestSerial;
    _loadingMoreDomains.add(domain);
    _loadMoreErrors.remove(domain);
    notifyListeners();

    try {
      final nextPage = await client.search(
        query: _query.trim(),
        scope: scope,
        domains: [domain],
        locale: locale,
        pageSize: groupPageSize,
        groupPageSize: groupPageSize,
        pageToken: pageToken,
      );
      if (requestId != _requestSerial || _page == null) return;

      final nextGroup = nextPage.groups.byDomain(domain);
      final mergedGroup = _page!.groups.byDomain(domain).append(nextGroup);
      _page = _page!.copyWith(
        groups: _page!.groups.replaceDomain(domain, mergedGroup),
      );
    } catch (exception) {
      if (requestId == _requestSerial) {
        _loadMoreErrors[domain] = exception;
      }
    } finally {
      _loadingMoreDomains.remove(domain);
      notifyListeners();
    }
  }

  void trackResultClick(SearchResult result, int resultPosition) {
    _trackEvent(
      SearchTrackingEventType.resultClicked,
      query: _query.trim(),
      domain: result.domain,
      entityId: result.entityId,
      resultPosition: resultPosition,
    );
  }

  void _trackEvent(
    SearchTrackingEventType type, {
    String? query,
    SearchDomain? domain,
    String? entityId,
    int? resultPosition,
  }) {
    unawaited(
      _trackEventSafely(
        SearchTrackingEvent(
          type: type,
          scope: scope,
          searchSessionId: searchSessionId,
          query: query,
          domain: domain,
          entityId: entityId,
          resultPosition: resultPosition,
          locale: locale,
        ),
      ),
    );
  }

  Future<void> _trackEventSafely(SearchTrackingEvent event) async {
    try {
      await client.trackEvent(event);
    } catch (_) {
      // Search telemetry is best-effort and must not block discovery UX.
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static String _newSearchSessionId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}

bool _hasResults(SearchPage page) {
  if (page.topResults.isNotEmpty) return true;
  final groups = page.groups;
  return groups.activities.items.isNotEmpty ||
      groups.excursions.items.isNotEmpty ||
      groups.places.items.isNotEmpty ||
      groups.guides.items.isNotEmpty ||
      groups.communities.items.isNotEmpty ||
      groups.users.items.isNotEmpty;
}
