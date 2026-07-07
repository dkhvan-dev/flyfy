import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/search/data/search_client.dart';
import 'package:inflap/features/search/domain/search_domain.dart';
import 'package:inflap/features/search/domain/search_event.dart';
import 'package:inflap/features/search/domain/search_result.dart';
import 'package:inflap/features/search/presentation/search_view_model.dart';

void main() {
  test(
    'submitSearch uses fixed entity scope and exposes loaded page',
    () async {
      final client = _FakeSearchClient();
      final viewModel = SearchViewModel(
        client: client,
        scope: SearchScope.activity,
        domains: const [SearchDomain.activity],
        debounceDuration: Duration.zero,
      );

      viewModel.updateQuery('  hiking  ');
      await viewModel.submitSearch();

      expect(client.searchCalls.single.query, 'hiking');
      expect(client.searchCalls.single.scope, SearchScope.activity);
      expect(client.searchCalls.single.domains, [SearchDomain.activity]);
      expect(viewModel.state, SearchState.loaded);
      expect(viewModel.page?.query, 'hiking');
      expect(
        client.eventCalls.first.type,
        SearchTrackingEventType.searchSubmitted,
      );
      expect(client.eventCalls.first.scope, SearchScope.activity);
    },
  );

  test(
    'submitSearch tracks zero results and search failures best-effort',
    () async {
      final client = _FakeSearchClient();
      final viewModel = SearchViewModel(
        client: client,
        scope: SearchScope.global,
        debounceDuration: Duration.zero,
      );

      viewModel.updateQuery('missing');
      await viewModel.submitSearch();

      expect(
        client.eventCalls.map((event) => event.type),
        contains(SearchTrackingEventType.zeroResults),
      );

      client.failSearch = true;
      viewModel.updateQuery('network');
      await viewModel.submitSearch();

      expect(viewModel.state, SearchState.error);
      expect(
        client.eventCalls.map((event) => event.type),
        contains(SearchTrackingEventType.searchFailed),
      );
    },
  );

  test(
    'trackResultClick records clicked result without changing state',
    () async {
      final client = _FakeSearchClient();
      final viewModel = SearchViewModel(
        client: client,
        scope: SearchScope.place,
        debounceDuration: Duration.zero,
      );
      const result = SearchResult(
        domain: SearchDomain.place,
        entityId: 'place-1',
        title: 'Almaty',
        deepLink: '/places/place-1',
        score: 1,
      );

      viewModel.updateQuery('almaty');
      viewModel.trackResultClick(result, 4);
      await Future<void>.delayed(Duration.zero);

      expect(
        client.eventCalls.single.type,
        SearchTrackingEventType.resultClicked,
      );
      expect(client.eventCalls.single.domain, SearchDomain.place);
      expect(client.eventCalls.single.entityId, 'place-1');
      expect(client.eventCalls.single.resultPosition, 4);
    },
  );

  test('submitSearch ignores stale results from older requests', () async {
    final client = _FakeSearchClient(useCompleters: true);
    final viewModel = SearchViewModel(
      client: client,
      scope: SearchScope.global,
      debounceDuration: Duration.zero,
    );

    viewModel.updateQuery('first');
    final first = viewModel.submitSearch();
    viewModel.updateQuery('second');
    final second = viewModel.submitSearch();

    client.completeSearch(1, _page('second'));
    await second;
    client.completeSearch(0, _page('first'));
    await first;

    expect(viewModel.state, SearchState.loaded);
    expect(viewModel.page?.query, 'second');
  });

  test('submitSearch requests compact first top-results page', () async {
    final client = _FakeSearchClient();
    final viewModel = SearchViewModel(
      client: client,
      scope: SearchScope.global,
      debounceDuration: Duration.zero,
    );

    viewModel.updateQuery('almaty');
    await viewModel.submitSearch();

    expect(client.searchCalls.single.pageSize, 5);
    expect(client.searchCalls.single.groupPageSize, 5);
  });

  test(
    'loadMoreTopResults appends the next backend top-results page',
    () async {
      final client = _FakeSearchClient(
        pages: [
          const SearchPage(
            query: 'almaty',
            locale: 'en',
            topResults: [
              SearchResult(
                domain: SearchDomain.place,
                entityId: 'top-1',
                title: 'Top 1',
                deepLink: '/places/top-1',
              ),
            ],
            groups: SearchGroups(),
            nextPageToken: 'top-next',
          ),
          const SearchPage(
            query: 'almaty',
            locale: 'en',
            topResults: [
              SearchResult(
                domain: SearchDomain.place,
                entityId: 'top-2',
                title: 'Top 2',
                deepLink: '/places/top-2',
              ),
            ],
            groups: SearchGroups(),
          ),
        ],
      );
      final viewModel = SearchViewModel(
        client: client,
        scope: SearchScope.global,
        debounceDuration: Duration.zero,
      );

      viewModel.updateQuery('almaty');
      await viewModel.submitSearch();
      await viewModel.loadMoreTopResults();

      expect(client.searchCalls, hasLength(2));
      expect(client.searchCalls.last.domains, isEmpty);
      expect(client.searchCalls.last.pageSize, 5);
      expect(client.searchCalls.last.pageToken, 'top-next');
      expect(viewModel.page?.topResults.map((result) => result.entityId), [
        'top-1',
        'top-2',
      ]);
      expect(viewModel.page?.nextPageToken, isNull);
    },
  );

  test('loadMoreGroup requests the next backend page for one domain', () async {
    final client = _FakeSearchClient(
      pages: [
        const SearchPage(
          query: 'charyn',
          locale: 'en',
          topResults: [],
          groups: SearchGroups(
            places: SearchGroupPage(
              items: [
                SearchResult(
                  domain: SearchDomain.place,
                  entityId: 'place-1',
                  title: 'Charyn Canyon',
                  deepLink: '/places/place-1',
                ),
              ],
              nextPageToken: 'places-next',
              hasMore: true,
            ),
          ),
        ),
        const SearchPage(
          query: 'charyn',
          locale: 'en',
          topResults: [],
          groups: SearchGroups(
            places: SearchGroupPage(
              items: [
                SearchResult(
                  domain: SearchDomain.place,
                  entityId: 'place-2',
                  title: 'Charyn Valley',
                  deepLink: '/places/place-2',
                ),
              ],
              hasMore: false,
            ),
          ),
        ),
      ],
    );
    final viewModel = SearchViewModel(
      client: client,
      scope: SearchScope.global,
      debounceDuration: Duration.zero,
      groupPageSize: 5,
    );

    viewModel.updateQuery('charyn');
    await viewModel.submitSearch();
    await viewModel.loadMoreGroup(SearchDomain.place);

    expect(client.searchCalls, hasLength(2));
    expect(client.searchCalls.last.domains, [SearchDomain.place]);
    expect(client.searchCalls.last.pageSize, 5);
    expect(client.searchCalls.last.groupPageSize, 5);
    expect(client.searchCalls.last.pageToken, 'places-next');
    expect(
      viewModel.page?.groups.places.items.map((result) => result.entityId),
      ['place-1', 'place-2'],
    );
    expect(viewModel.page?.groups.places.hasMore, isFalse);
  });
}

SearchPage _page(String query) => SearchPage(
  query: query,
  locale: 'en',
  topResults: const [],
  groups: const SearchGroups(),
);

class _FakeSearchClient implements SearchClient {
  _FakeSearchClient({this.useCompleters = false, List<SearchPage>? pages})
    : _pages = pages ?? const [];

  final bool useCompleters;
  final List<SearchPage> _pages;
  final searchCalls = <SearchRequest>[];
  final eventCalls = <SearchTrackingEvent>[];
  final _searchCompleters = <Completer<SearchPage>>[];
  bool failSearch = false;

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
  }) {
    if (failSearch) {
      return Future<SearchPage>.error(StateError('network'));
    }
    searchCalls.add(
      SearchRequest(
        query: query,
        scope: scope,
        domains: domains.toList(growable: false),
        pageSize: pageSize,
        groupPageSize: groupPageSize,
        pageToken: pageToken,
      ),
    );
    if (_pages.isNotEmpty) {
      final index = searchCalls.length - 1;
      return Future.value(_pages[index.clamp(0, _pages.length - 1)]);
    }
    if (!useCompleters) {
      return Future.value(_page(query));
    }
    final completer = Completer<SearchPage>();
    _searchCompleters.add(completer);
    return completer.future;
  }

  void completeSearch(int index, SearchPage page) {
    _searchCompleters[index].complete(page);
  }

  @override
  Future<List<SearchSuggestion>> suggest({
    required String query,
    required SearchScope scope,
    Iterable<SearchDomain> domains = const [],
    int limit = 5,
    String? locale,
  }) async {
    return const [];
  }

  @override
  Future<void> trackEvent(SearchTrackingEvent event) async {
    eventCalls.add(event);
  }
}

class SearchRequest {
  const SearchRequest({
    required this.query,
    required this.scope,
    required this.domains,
    required this.pageSize,
    this.groupPageSize,
    this.pageToken,
  });

  final String query;
  final SearchScope scope;
  final List<SearchDomain> domains;
  final int pageSize;
  final int? groupPageSize;
  final String? pageToken;
}
