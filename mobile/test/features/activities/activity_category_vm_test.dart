import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/activities/models/activity_category_vm.dart';

void main() {
  test('parses localized category taxonomy with subcategories and system tags',
      () {
    final category = ActivityCategoryVm.fromJson({
      'slug': 'Food_Drinks',
      'name': 'Food & Drinks',
      'nameRu': 'Еда и напитки',
      'nameKk': 'Тамақ және сусындар',
      'aliases': ['dining'],
      'localizedNames': {
        'en': 'Food & Drinks',
        'ru': 'Еда и напитки',
        'kk': 'Тамақ және сусындар',
      },
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
          'localizedNames': {
            'en': 'Solo-friendly',
            'ru': 'Можно одному',
            'kk': 'Жалғыз келуге болады',
          },
        },
      ],
    });

    expect(category.slug, 'food-drinks');
    expect(category.aliases, ['dining']);
    expect(category.localizedName('ru'), 'Еда и напитки');
    expect(category.localizedName('kk'), 'Тамақ және сусындар');
    expect(category.subcategories.single.slug, 'coffee-meetup');
    expect(category.subcategories.single.localizedName('ru'), 'Кофе-встреча');
    expect(category.systemTags.single.slug, 'solo-friendly');
    expect(category.systemTags.single.localizedName('ru'), 'Можно одному');
  });

  test('keeps legacy localized name fields as fallback', () {
    final category = ActivityCategoryVm.fromJson({
      'slug': 'social-nightlife',
      'name': 'Social & Nightlife',
      'nameRu': 'Общение и ночная жизнь',
      'nameKk': 'Әлеуметтік қарым-қатынас және түнгі өмір',
    });

    expect(category.localizedName('ru'), 'Общение и ночная жизнь');
    expect(category.localizedName('kk'),
        'Әлеуметтік қарым-қатынас және түнгі өмір');
    expect(category.localizedName('en'), 'Social & Nightlife');
  });
}
