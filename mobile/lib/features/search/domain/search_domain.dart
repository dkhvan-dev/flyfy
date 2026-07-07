enum SearchDomain {
  activity('activity'),
  excursion('excursion'),
  place('place'),
  guide('guide'),
  community('community'),
  user('user'),
  helpArticle('help_article');

  const SearchDomain(this.apiValue);

  final String apiValue;

  static SearchDomain? fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final domain in SearchDomain.values) {
      if (domain.apiValue == normalized) return domain;
    }
    return null;
  }
}

enum SearchScope {
  global('global'),
  activity('activity'),
  excursion('excursion'),
  place('place'),
  guide('guide'),
  community('community'),
  user('user'),
  helpArticle('help_article');

  const SearchScope(this.apiValue);

  final String apiValue;

  static SearchScope? fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final scope in SearchScope.values) {
      if (scope.apiValue == normalized) return scope;
    }
    return null;
  }

  SearchDomain? get matchingDomain {
    return switch (this) {
      SearchScope.global => null,
      SearchScope.activity => SearchDomain.activity,
      SearchScope.excursion => SearchDomain.excursion,
      SearchScope.place => SearchDomain.place,
      SearchScope.guide => SearchDomain.guide,
      SearchScope.community => SearchDomain.community,
      SearchScope.user => SearchDomain.user,
      SearchScope.helpArticle => SearchDomain.helpArticle,
    };
  }
}
