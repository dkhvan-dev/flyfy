import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/search/domain/search_domain.dart';
import 'package:inflap/features/search/presentation/search_route_config.dart';

void main() {
  test('uses global scope by default', () {
    final config = SearchRouteConfig.fromQueryParameters(const {});

    expect(config.scope, SearchScope.global);
    expect(config.domains, isEmpty);
    expect(config.query, isEmpty);
  });

  test('normalizes entity scope to its matching domain', () {
    final config = SearchRouteConfig.fromQueryParameters(const {
      'q': '  hiking  ',
      'scope': 'activity',
      'domains': 'guide,place',
    });

    expect(config.query, 'hiking');
    expect(config.scope, SearchScope.activity);
    expect(config.domains, [SearchDomain.activity]);
  });

  test('keeps only supported global domains', () {
    final config = SearchRouteConfig.fromQueryParameters(const {
      'query': 'astana',
      'domains': 'place,routes,checklists,chats,guide,place',
    });

    expect(config.query, 'astana');
    expect(config.scope, SearchScope.global);
    expect(config.domains, [SearchDomain.place, SearchDomain.guide]);
  });
}
