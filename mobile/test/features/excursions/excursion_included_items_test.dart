import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/excursion_included_items.dart';

void main() {
  test('recognizes deprecated included item keys and localized values', () {
    for (final value in [
      'guide',
      'Guide: included',
      'Гид',
      'photo',
      'photos',
      'Фото: включено',
    ]) {
      expect(
        ExcursionIncludedItemKey.isDeprecated(value),
        isTrue,
        reason: value,
      );
    }

    for (final value in [
      ExcursionIncludedItemKey.transport,
      ExcursionIncludedItemKey.accommodation,
      ExcursionIncludedItemKey.permitsFees,
      'professional photography session',
    ]) {
      expect(
        ExcursionIncludedItemKey.isDeprecated(value),
        isFalse,
        reason: value,
      );
    }
  });
}
