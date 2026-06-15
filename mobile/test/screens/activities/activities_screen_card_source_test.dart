import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activities screen renders the activities story tray surface', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    expect(source, contains('SurfaceStoryTray('));
    expect(source, contains("surface: 'activities'"));
    expect(source, contains('viewerAvatarFileId: profile?.avatarFileId'));
    expect(source, contains('viewerInitials: profile?.initials ??'));

    final trayStart = source.indexOf('SurfaceStoryTray(');
    final authGuardStart = source.lastIndexOf(
      'if (isLoggedIn) ...[',
      trayStart,
    );
    expect(authGuardStart, isNonNegative);
    expect(trayStart - authGuardStart, lessThan(180));
  });

  test(
    'activities card does not duplicate location under category label',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final cardStart = source.indexOf('class _DiscoverActivityCard');
      final metaStart = source.indexOf('class _CardMetaItem');
      expect(cardStart, isNonNegative);
      expect(metaStart, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, metaStart);
      final categoryLabelStart = cardSource.indexOf(
        'categoryLabel.toUpperCase()',
      );
      final titleStart = cardSource.indexOf(
        'Text(\n                      item.title',
      );
      expect(categoryLabelStart, isNonNegative);
      expect(titleStart, greaterThan(categoryLabelStart));

      final categoryHeaderSource = cardSource.substring(
        categoryLabelStart,
        titleStart,
      );

      expect(categoryHeaderSource, isNot(contains('locationText')));
    },
  );

  test('activities card location meta uses localized location text', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final cardStart = source.indexOf('class _DiscoverActivityCard');
    final metaStart = source.indexOf('class _CardMetaItem');
    expect(cardStart, isNonNegative);
    expect(metaStart, greaterThan(cardStart));

    final cardSource = source.substring(cardStart, metaStart);

    expect(
      cardSource,
      contains('labelBuilder: (style) => AppLocalizedLocationText('),
    );
    expect(cardSource, contains('countryCode: item.countryCode'));
    expect(cardSource, contains('cityId: item.cityId'));
    expect(
      cardSource,
      isNot(
        contains(
          '_CardMetaData(icon: Icons.place_outlined, label: locationText)',
        ),
      ),
    );
  });

  test('activities screen exposes nearby activities map preview', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();
    final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

    expect(source, contains("import '../map/map_screen.dart';"));
    expect(source, contains('activitiesNearbyTitle'));
    expect(source, contains('_ActivitiesNearbyMapSection('));
    expect(source, contains('_buildActivityMapTargets('));
    expect(source, contains('MapActivityTarget('));
    expect(source, contains("context.push("));
    expect(source, contains('extra: MapActivityCollection('));
    expect(source, contains('item.latitude'));
    expect(source, contains('item.longitude'));
    expect(ruArb, contains('"activitiesNearbyTitle": "Активности рядом"'));
  });
}
