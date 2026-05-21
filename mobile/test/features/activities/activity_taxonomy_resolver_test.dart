import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/activities/activity_taxonomy_resolver.dart';
import 'package:superapp/features/activities/models/activity_category_vm.dart';

void main() {
  final categories = [
    ActivityCategoryVm.fromJson({
      'slug': 'food-drinks',
      'name': 'Food & Drinks',
      'nameRu': 'Еда и напитки',
      'nameKk': 'Тамақ және сусындар',
      'aliases': ['food'],
      'subcategories': [
        {
          'slug': 'coffee-meetup',
          'name': 'Coffee meetup',
          'nameRu': 'Кофе-встреча',
          'nameKk': 'Кофе кездесуі',
        },
      ],
      'systemTags': [
        {
          'slug': 'solo-friendly',
          'name': 'Solo-friendly',
          'nameRu': 'Можно одному',
          'nameKk': 'Жалғыз келуге болады',
        },
      ],
    }),
  ];

  test('localizes category by slug and alias', () {
    expect(
      localizedActivityCategoryLabel(
        categories: categories,
        slug: 'food',
        languageCode: 'ru',
      ),
      'Еда и напитки',
    );
  });

  test('localizes subcategories and system tags from category catalog', () {
    expect(
      localizedActivitySubcategoryLabel(
        categories: categories,
        categorySlug: 'food-drinks',
        subcategorySlug: 'coffee-meetup',
        languageCode: 'ru',
      ),
      'Кофе-встреча',
    );

    expect(
      localizedActivityTagLabel(
        categories: categories,
        tagSlug: 'solo-friendly',
        languageCode: 'ru',
      ),
      'Можно одному',
    );
  });

  test('falls back to human-readable custom tag label', () {
    expect(
      localizedActivityTagLabel(
        categories: categories,
        tagSlug: 'morning-run',
        languageCode: 'ru',
      ),
      'Morning Run',
    );
  });
}
