import 'search_domain.dart';

class SearchResult {
  const SearchResult({
    required this.domain,
    required this.entityId,
    required this.title,
    required this.deepLink,
    this.subtitle,
    this.score = 0,
  });

  final SearchDomain domain;
  final String entityId;
  final String title;
  final String? subtitle;
  final String deepLink;
  final double score;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final domain = SearchDomain.fromApiValue(json['domain']?.toString());
    if (domain == null) {
      throw FormatException('Unsupported search domain: ${json['domain']}');
    }
    return SearchResult(
      domain: domain,
      entityId: json['entityId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: _nullableString(json['subtitle']),
      deepLink: json['deepLink']?.toString() ?? '',
      score: _double(json['score']),
    );
  }
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.domain,
    required this.entityId,
    required this.text,
    required this.deepLink,
  });

  final SearchDomain domain;
  final String entityId;
  final String text;
  final String deepLink;

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    final domain = SearchDomain.fromApiValue(json['domain']?.toString());
    if (domain == null) {
      throw FormatException(
        'Unsupported search suggestion domain: ${json['domain']}',
      );
    }
    return SearchSuggestion(
      domain: domain,
      entityId: json['entityId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      deepLink: json['deepLink']?.toString() ?? '',
    );
  }
}

class SearchGroups {
  const SearchGroups({
    this.places = const SearchGroupPage(),
    this.activities = const SearchGroupPage(),
    this.excursions = const SearchGroupPage(),
    this.guides = const SearchGroupPage(),
    this.communities = const SearchGroupPage(),
    this.users = const SearchGroupPage(),
    this.helpArticles = const SearchGroupPage(),
  });

  final SearchGroupPage places;
  final SearchGroupPage activities;
  final SearchGroupPage excursions;
  final SearchGroupPage guides;
  final SearchGroupPage communities;
  final SearchGroupPage users;
  final SearchGroupPage helpArticles;

  factory SearchGroups.fromJson(Map<String, dynamic>? json) {
    return SearchGroups(
      places: SearchGroupPage.fromJson(json?['places']),
      activities: SearchGroupPage.fromJson(json?['activities']),
      excursions: SearchGroupPage.fromJson(json?['excursions']),
      guides: SearchGroupPage.fromJson(json?['guides']),
      communities: SearchGroupPage.fromJson(json?['communities']),
      users: SearchGroupPage.fromJson(json?['users']),
      helpArticles: SearchGroupPage.fromJson(json?['helpArticles']),
    );
  }

  factory SearchGroups.fromResults(List<SearchResult> results) {
    final activities = <SearchResult>[];
    final excursions = <SearchResult>[];
    final places = <SearchResult>[];
    final guides = <SearchResult>[];
    final communities = <SearchResult>[];
    final users = <SearchResult>[];
    final helpArticles = <SearchResult>[];

    for (final result in results) {
      switch (result.domain) {
        case SearchDomain.activity:
          activities.add(result);
        case SearchDomain.excursion:
          excursions.add(result);
        case SearchDomain.place:
          places.add(result);
        case SearchDomain.guide:
          guides.add(result);
        case SearchDomain.community:
          communities.add(result);
        case SearchDomain.user:
          users.add(result);
        case SearchDomain.helpArticle:
          helpArticles.add(result);
      }
    }

    return SearchGroups(
      activities: SearchGroupPage(items: activities),
      excursions: SearchGroupPage(items: excursions),
      places: SearchGroupPage(items: places),
      guides: SearchGroupPage(items: guides),
      communities: SearchGroupPage(items: communities),
      users: SearchGroupPage(items: users),
      helpArticles: SearchGroupPage(items: helpArticles),
    );
  }

  SearchGroupPage byDomain(SearchDomain domain) {
    return switch (domain) {
      SearchDomain.activity => activities,
      SearchDomain.excursion => excursions,
      SearchDomain.place => places,
      SearchDomain.guide => guides,
      SearchDomain.community => communities,
      SearchDomain.user => users,
      SearchDomain.helpArticle => helpArticles,
    };
  }

  SearchGroups replaceDomain(SearchDomain domain, SearchGroupPage page) {
    return switch (domain) {
      SearchDomain.activity => SearchGroups(
        places: places,
        activities: page,
        excursions: excursions,
        guides: guides,
        communities: communities,
        users: users,
        helpArticles: helpArticles,
      ),
      SearchDomain.excursion => SearchGroups(
        places: places,
        activities: activities,
        excursions: page,
        guides: guides,
        communities: communities,
        users: users,
        helpArticles: helpArticles,
      ),
      SearchDomain.place => SearchGroups(
        places: page,
        activities: activities,
        excursions: excursions,
        guides: guides,
        communities: communities,
        users: users,
        helpArticles: helpArticles,
      ),
      SearchDomain.guide => SearchGroups(
        places: places,
        activities: activities,
        excursions: excursions,
        guides: page,
        communities: communities,
        users: users,
        helpArticles: helpArticles,
      ),
      SearchDomain.community => SearchGroups(
        places: places,
        activities: activities,
        excursions: excursions,
        guides: guides,
        communities: page,
        users: users,
        helpArticles: helpArticles,
      ),
      SearchDomain.user => SearchGroups(
        places: places,
        activities: activities,
        excursions: excursions,
        guides: guides,
        communities: communities,
        users: page,
        helpArticles: helpArticles,
      ),
      SearchDomain.helpArticle => SearchGroups(
        places: places,
        activities: activities,
        excursions: excursions,
        guides: guides,
        communities: communities,
        users: users,
        helpArticles: page,
      ),
    };
  }
}

class SearchGroupPage {
  const SearchGroupPage({
    this.items = const [],
    this.nextPageToken,
    this.hasMore = false,
  });

  final List<SearchResult> items;
  final String? nextPageToken;
  final bool hasMore;

  factory SearchGroupPage.fromJson(dynamic json) {
    if (json is List) {
      return SearchGroupPage(items: _resultList(json));
    }
    if (json is! Map<String, dynamic>) {
      return const SearchGroupPage();
    }
    final nextPageToken = _nullableString(json['nextPageToken']);
    final hasMore = json['hasMore'] is bool
        ? json['hasMore'] as bool
        : nextPageToken != null;
    return SearchGroupPage(
      items: _resultList(json['items']),
      nextPageToken: nextPageToken,
      hasMore: hasMore,
    );
  }

  SearchGroupPage append(SearchGroupPage nextPage) {
    return SearchGroupPage(
      items: [...items, ...nextPage.items],
      nextPageToken: nextPage.nextPageToken,
      hasMore: nextPage.hasMore,
    );
  }
}

class SearchPage {
  const SearchPage({
    required this.query,
    required this.locale,
    required this.topResults,
    required this.groups,
    this.nextPageToken,
  });

  final String query;
  final String locale;
  final List<SearchResult> topResults;
  final SearchGroups groups;
  final String? nextPageToken;

  SearchPage copyWith({
    String? query,
    String? locale,
    List<SearchResult>? topResults,
    SearchGroups? groups,
    String? nextPageToken,
  }) {
    return SearchPage(
      query: query ?? this.query,
      locale: locale ?? this.locale,
      topResults: topResults ?? this.topResults,
      groups: groups ?? this.groups,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }

  factory SearchPage.fromJson(Map<String, dynamic> json) {
    return SearchPage(
      query: json['query']?.toString() ?? '',
      locale: json['locale']?.toString() ?? 'en',
      topResults: _resultList(json['topResults']),
      groups: SearchGroups.fromJson(json['groups'] as Map<String, dynamic>?),
      nextPageToken: _nullableString(json['nextPageToken']),
    );
  }

  factory SearchPage.fromResponse(
    dynamic value, {
    String? fallbackQuery,
    String? fallbackLocale,
  }) {
    if (value is Map) {
      return SearchPage.fromJson(value.cast<String, dynamic>());
    }
    if (value is List) {
      final results = _resultList(value);
      return SearchPage(
        query: fallbackQuery?.trim() ?? '',
        locale: fallbackLocale?.trim().isNotEmpty == true
            ? fallbackLocale!.trim()
            : 'en',
        topResults: results,
        groups: SearchGroups.fromResults(results),
      );
    }
    return SearchPage(
      query: fallbackQuery?.trim() ?? '',
      locale: fallbackLocale?.trim().isNotEmpty == true
          ? fallbackLocale!.trim()
          : 'en',
      topResults: const [],
      groups: const SearchGroups(),
    );
  }
}

List<SearchResult> _resultList(dynamic value) {
  if (value is! List) return const [];
  final results = <SearchResult>[];
  for (final item in value) {
    if (item is! Map) continue;
    final result = _trySearchResultFromJson(item.cast<String, dynamic>());
    if (result != null) results.add(result);
  }
  return List<SearchResult>.unmodifiable(results);
}

SearchResult? _trySearchResultFromJson(Map<String, dynamic> json) {
  try {
    return SearchResult.fromJson(json);
  } on FormatException {
    return null;
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
