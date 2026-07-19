import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile activity cards use V2 adaptive colors', () async {
    final source = await File(
      'lib/screens/profile/widgets/profile_activity_card.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('_profileActivityCardDecoration(context, colors)'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('profileCardDecoration(context')));
    expect(source, isNot(contains('profileTextSoft')));
    expect(source, isNot(contains('profileTextMuted')));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'profile cards validate canonical public ID before CARD bookmark',
    () async {
      final source = await File(
        'lib/screens/profile/widgets/profile_activity_card.dart',
      ).readAsString();

      final fullCardStart = source.indexOf('class ProfileActivityCard');
      final compactCardStart = source.indexOf(
        'class ProfileCompactActivityCard',
      );
      final bookmarkStart = source.indexOf(
        'class _ProfileActivitySavedBookmarkButton',
      );
      final bookmarkEnd = source.indexOf(
        'String _compactActivityMetaText',
        bookmarkStart,
      );
      expect(fullCardStart, isNonNegative);
      expect(compactCardStart, greaterThan(fullCardStart));
      expect(bookmarkStart, greaterThan(compactCardStart));
      expect(bookmarkEnd, greaterThan(bookmarkStart));

      final fullCardSource = source.substring(fullCardStart, compactCardStart);
      final compactCardSource = source.substring(
        compactCardStart,
        bookmarkStart,
      );
      final bookmarkSource = source.substring(bookmarkStart, bookmarkEnd);
      expect(
        fullCardSource,
        contains('_ProfileActivitySavedBookmarkButton(item: item)'),
      );
      expect(
        compactCardSource,
        contains('_ProfileActivitySavedBookmarkButton('),
      );
      expect(
        bookmarkSource,
        contains("item.visibility.trim().toUpperCase() != 'PUBLIC'"),
      );
      expect(bookmarkSource, contains('return const SizedBox.shrink()'));
      expect(bookmarkSource, contains('SavedTarget.tryCreate('));
      expect(bookmarkSource, contains('if (savedTarget == null)'));
      expect(bookmarkSource, contains('AppSavedBookmarkButton('));
      expect(bookmarkSource, contains('entityType: SavedEntityType.activity'));
      expect(bookmarkSource, contains('entityId: item.id'));
      expect(bookmarkSource, contains('target: savedTarget'));
      expect(bookmarkSource, isNot(contains('target: SavedTarget(')));
      expect(
        bookmarkSource,
        contains('sourceSurface: SavedSourceSurface.card'),
      );
      expect(bookmarkSource, isNot(contains('onTap: () {}')));
    },
  );
}
