import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/search/data/search_client.dart';
import 'package:inflap/features/search/domain/search_domain.dart';
import 'package:inflap/features/search/domain/search_event.dart';
import 'package:inflap/features/search/domain/search_result.dart';
import 'package:inflap/features/search/presentation/search_route_config.dart';
import 'package:inflap/features/search/presentation/search_screen.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('runs initial scoped search and renders result', (tester) async {
    final client = _FakeSearchClient(
      page: const SearchPage(
        query: 'hiking',
        locale: 'en',
        topResults: [
          SearchResult(
            domain: SearchDomain.activity,
            entityId: 'activity-1',
            title: 'Mountain hike',
            deepLink: '/activities/activity-1',
            score: 0.91,
          ),
        ],
        groups: SearchGroups(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(
          client: client,
          config: const SearchRouteConfig(
            query: 'hiking',
            scope: SearchScope.activity,
            domains: [SearchDomain.activity],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(client.searchCalls, hasLength(1));
    expect(client.searchCalls.single.query, 'hiking');
    expect(client.searchCalls.single.scope, SearchScope.activity);
    expect(client.searchCalls.single.domains, [SearchDomain.activity]);
    expect(find.text('Mountain hike'), findsOneWidget);
  });

  testWidgets('loads the next result block page from backend', (tester) async {
    final client = _FakeSearchClient(
      pages: const [
        SearchPage(
          query: 'almaty',
          locale: 'en',
          topResults: [],
          groups: SearchGroups(
            places: SearchGroupPage(
              items: [
                SearchResult(
                  domain: SearchDomain.place,
                  entityId: 'place-1',
                  title: 'Place 1',
                  deepLink: '/places/place-1',
                  score: 1,
                ),
              ],
              nextPageToken: 'places-next',
              hasMore: true,
            ),
          ),
        ),
        SearchPage(
          query: 'almaty',
          locale: 'en',
          topResults: [],
          groups: SearchGroups(
            places: SearchGroupPage(
              items: [
                SearchResult(
                  domain: SearchDomain.place,
                  entityId: 'place-2',
                  title: 'Place 2',
                  deepLink: '/places/place-2',
                  score: 0.9,
                ),
              ],
              hasMore: false,
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(
          client: client,
          config: const SearchRouteConfig(query: 'almaty'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Place 1'), findsOneWidget);
    expect(find.text('Place 2'), findsNothing);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Place 1'), findsOneWidget);
    expect(find.text('Place 2'), findsOneWidget);
    expect(client.searchCalls, hasLength(2));
    expect(client.searchCalls.last.domains, [SearchDomain.place]);
    expect(client.searchCalls.last.pageToken, 'places-next');
  });

  testWidgets('limits top results and loads more from backend', (tester) async {
    final client = _FakeSearchClient(
      pages: [
        SearchPage(
          query: 'almaty',
          locale: 'en',
          topResults: List<SearchResult>.generate(
            5,
            (index) => SearchResult(
              domain: SearchDomain.place,
              entityId: 'top-$index',
              title: 'Top ${index + 1}',
              deepLink: '/places/top-$index',
            ),
          ),
          groups: const SearchGroups(),
          nextPageToken: 'top-next',
        ),
        const SearchPage(
          query: 'almaty',
          locale: 'en',
          topResults: [
            SearchResult(
              domain: SearchDomain.place,
              entityId: 'top-6',
              title: 'Top 6',
              deepLink: '/places/top-6',
            ),
          ],
          groups: SearchGroups(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(
          client: client,
          config: const SearchRouteConfig(query: 'almaty'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(client.searchCalls.single.pageSize, 5);
    expect(find.text('Top 1'), findsOneWidget);
    expect(find.text('Top 5'), findsOneWidget);
    expect(find.text('Top 6'), findsNothing);
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Top 6'), findsOneWidget);
    expect(client.searchCalls, hasLength(2));
    expect(client.searchCalls.last.domains, isEmpty);
    expect(client.searchCalls.last.pageToken, 'top-next');
  });

  testWidgets('shows entity type only inside top results', (tester) async {
    final client = _FakeSearchClient(
      page: const SearchPage(
        query: 'almaty',
        locale: 'en',
        topResults: [
          SearchResult(
            domain: SearchDomain.place,
            entityId: 'top-place',
            title: 'Top mixed result',
            deepLink: '/places/top-place',
          ),
        ],
        groups: SearchGroups(
          places: SearchGroupPage(
            items: [
              SearchResult(
                domain: SearchDomain.place,
                entityId: 'place-block',
                title: 'Place block result',
                deepLink: '/places/place-block',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SearchScreen(
          client: client,
          config: const SearchRouteConfig(query: 'almaty'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Top mixed result'), findsOneWidget);
    expect(find.text('Place block result'), findsOneWidget);
    expect(find.text('Place'), findsOneWidget);
  });
}

class _FakeSearchClient implements SearchClient {
  _FakeSearchClient({SearchPage? page, List<SearchPage>? pages})
    : _pages = pages ?? [?page];

  final List<SearchPage> _pages;
  final searchCalls = <SearchRequest>[];

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
    searchCalls.add(
      SearchRequest(
        query: query,
        scope: scope,
        domains: domains.toList(growable: false),
        pageSize: pageSize,
        pageToken: pageToken,
      ),
    );
    final index = searchCalls.length - 1;
    return _pages[index.clamp(0, _pages.length - 1)];
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
  Future<void> trackEvent(SearchTrackingEvent event) async {}
}

class SearchRequest {
  const SearchRequest({
    required this.query,
    required this.scope,
    required this.domains,
    required this.pageSize,
    this.pageToken,
  });

  final String query;
  final SearchScope scope;
  final List<SearchDomain> domains;
  final int pageSize;
  final String? pageToken;
}
