import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('place cards use attraction IDs and CARD Saved surface', () async {
    final source = await File(
      'lib/screens/places/places_screen.dart',
    ).readAsString();
    final mustVisitStart = source.indexOf('class _MustVisitCard');
    final mustVisitEnd = source.indexOf(
      'class _RetryingPlaceCoverImage',
      mustVisitStart,
    );
    final discoverStart = source.indexOf('class _DiscoverCard');

    expect(mustVisitStart, isNonNegative);
    expect(mustVisitEnd, greaterThan(mustVisitStart));
    expect(discoverStart, greaterThan(mustVisitEnd));

    final mustVisitSource = source.substring(mustVisitStart, mustVisitEnd);
    final discoverSource = source.substring(discoverStart);
    for (final cardSource in [mustVisitSource, discoverSource]) {
      expect(cardSource, contains('SavedTarget.tryCreate('));
      expect(cardSource, contains('AppSavedBookmarkButton('));
      expect(cardSource, contains('entityType: SavedEntityType.attraction'));
      expect(cardSource, contains('entityId: place.id'));
      expect(cardSource, contains('if (savedTarget != null)'));
      expect(cardSource, contains('target: savedTarget'));
      expect(cardSource, contains('sourceSurface: SavedSourceSurface.card'));
    }

    expect(
      RegExp(r'SavedTarget\.tryCreate\(').allMatches(source),
      hasLength(2),
    );
    expect(
      RegExp(r'AppSavedBookmarkButton\(').allMatches(source),
      hasLength(2),
    );
    expect(RegExp(r'SavedTarget\(').allMatches(source), isEmpty);
    expect(source, isNot(contains('Icons.bookmark_border_rounded')));
    expect(source, isNot(contains('SavedEntityType.excursion')));
  });

  test(
    'place detail top bar alone uses canonical attraction DETAIL target',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();
      final topBarStart = source.indexOf('Widget _buildTopBar');
      final topBarEnd = source.indexOf('Widget _circleIconButton', topBarStart);

      expect(topBarStart, isNonNegative);
      expect(topBarEnd, greaterThan(topBarStart));
      final topBarSource = source.substring(topBarStart, topBarEnd);

      expect(topBarSource, contains('final place = _place!'));
      expect(topBarSource, contains('SavedTarget.tryCreate('));
      expect(topBarSource, contains('AppSavedBookmarkButton('));
      expect(topBarSource, contains('entityType: SavedEntityType.attraction'));
      expect(topBarSource, contains('entityId: place.id'));
      expect(topBarSource, contains('if (savedTarget != null)'));
      expect(topBarSource, contains('target: savedTarget'));
      expect(
        topBarSource,
        contains('sourceSurface: SavedSourceSurface.detail'),
      );
      expect(topBarSource, contains('const SizedBox.square(dimension: 48)'));
      expect(
        RegExp(r'AppSavedBookmarkButton\(').allMatches(source),
        hasLength(1),
      );
      expect(RegExp(r'SavedTarget\(').allMatches(source), isEmpty);
      expect(source, isNot(contains('SavedSourceSurface.card')));
      expect(source, isNot(contains('Icons.bookmark_border_rounded')));
      expect(source, isNot(contains('SavedEntityType.excursion')));
    },
  );
}
