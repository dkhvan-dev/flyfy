import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activities screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('activitiesColors.primary'));
    expect(source, contains('activitiesColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

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

  test(
    'activities backdrop uses shared graphite without scroll dimming',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final backdropStart = source.indexOf('class _DiscoverScreenBackdrop');
      final nextWidgetStart = source.indexOf('class _DiscoverSearchField');
      expect(backdropStart, isNonNegative);
      expect(nextWidgetStart, greaterThan(backdropStart));

      final backdropSource = source.substring(backdropStart, nextWidgetStart);

      expect(
        backdropSource,
        contains('return ColoredBox(color: colors.background, child: child);'),
      );
      expect(
        backdropSource,
        isNot(contains('_isLightActivitiesTheme(context)')),
      );
      expect(backdropSource, isNot(contains('Stack(')));
      expect(backdropSource, isNot(contains('LinearGradient(')));
      expect(backdropSource, isNot(contains('RadialGradient(')));
      expect(backdropSource, isNot(contains('Positioned.fill(')));
      expect(backdropSource, isNot(contains('colors.black.withValues')));
      expect(backdropSource, isNot(contains('colors.secondary.withValues')));
      expect(backdropSource, isNot(contains('colors.surfaceTeal.withValues')));
    },
  );

  test('activities empty state uses readable secondary text', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final emptyStart = source.indexOf('class _ActivitiesEmptyView');
    final filtersStart = source.indexOf('class _DiscoverFiltersSheet');
    expect(emptyStart, isNonNegative);
    expect(filtersStart, greaterThan(emptyStart));

    final emptySource = source.substring(emptyStart, filtersStart);

    expect(emptySource, contains('context.activitiesColors.textSecondary'));
    expect(emptySource, isNot(contains('orangeOverlayWash09')));
  });

  test(
    'activities sort uses primary amber accent for the selected field',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final sortStart = source.indexOf('class _DiscoverSortBar');
      final sortEnd = source.indexOf('class _ActivitiesNearbyMapSection');
      expect(sortStart, isNonNegative);
      expect(sortEnd, greaterThan(sortStart));

      final sortSource = source.substring(sortStart, sortEnd);

      expect(
        sortSource,
        contains('activeColor: context.activitiesColors.primary'),
      );
      expect(
        sortSource,
        isNot(contains('activeColor: context.activitiesColors.primaryText')),
      );
    },
  );

  test(
    'activities discover screen uses teal for informational secondary accents',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final colorsStart = source.indexOf('final class _ActivitiesColors');
      final colorsEnd = source.indexOf('extension _ActivitiesColorContext');
      final mapStart = source.indexOf('class _ActivitiesNearbyMapSection');
      final mapEnd = source.indexOf('class _ActivityPreviewMarker');
      final cardStart = source.indexOf('class _DiscoverActivityCard');
      final metaStart = source.indexOf('class _CardMetaItem');
      final metaEnd = source.indexOf('class _ActivitiesEmptyView');

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(mapStart, isNonNegative);
      expect(mapEnd, greaterThan(mapStart));
      expect(cardStart, isNonNegative);
      expect(metaStart, greaterThan(cardStart));
      expect(metaEnd, greaterThan(metaStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final mapSource = source.substring(mapStart, mapEnd);
      final cardSource = source.substring(cardStart, metaStart);
      final metaSource = source.substring(metaStart, metaEnd);

      expect(colorsSource, contains('Color get secondaryText'));
      expect(colorsSource, contains('colors.secondaryPressed'));
      expect(colorsSource, contains('Color get secondarySurface'));
      expect(colorsSource, contains('Color get secondaryBorder'));
      expect(colorsSource, contains('colors.secondary.withValues'));

      expect(mapSource, contains('Icons.near_me_rounded'));
      expect(mapSource, contains('context.activitiesColors.secondarySurface'));
      expect(mapSource, contains('context.activitiesColors.secondaryBorder'));
      expect(mapSource, contains('context.activitiesColors.secondaryText'));

      expect(cardSource, contains('color: item.isFree'));
      expect(cardSource, contains('context.activitiesColors.secondarySurface'));
      expect(cardSource, contains('context.activitiesColors.secondaryText'));
      expect(cardSource, isNot(contains('context.activitiesColors.success')));

      expect(metaSource, contains('context.activitiesColors.secondaryText'));
      expect(metaSource, isNot(contains('orangeOverlayWash07')));
      expect(metaSource, isNot(contains('orangeOverlayWash08')));
    },
  );

  test(
    'activities card visibility badge stays readable on cover photos',
    () async {
      final source = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();

      final badgeStart = source.indexOf(
        '_VisibilityBadgeStyle _visibilityBadge',
      );
      final end = source.indexOf(
        'bool _isDiscoverRegistrationOpen',
        badgeStart,
      );

      expect(badgeStart, isNonNegative);
      expect(end, greaterThan(badgeStart));

      final badgeSource = source.substring(badgeStart, end);

      expect(badgeSource, contains('colors.isLight'));
      expect(badgeSource, contains('colors.white.withValues(alpha: 0.92)'));
      expect(
        badgeSource,
        contains('colors.surfaceRaised.withValues(alpha: 0.88)'),
      );
      expect(badgeSource, contains('foreground: colors.textPrimary'));
    },
  );

  test('activities cards and map preview do not render image scrims', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final helperStart = source.indexOf(
      'List<BoxShadow>? _activitiesDarkThemeShadow',
    );
    final mapStart = source.indexOf('class _ActivitiesNearbyMapSection');
    final mapEnd = source.indexOf('class _ActivityPreviewMarker');
    final cardStart = source.indexOf('class _DiscoverActivityCard');
    final metaStart = source.indexOf('class _CardMetaItem');

    expect(helperStart, isNonNegative);
    expect(mapStart, isNonNegative);
    expect(mapEnd, greaterThan(mapStart));
    expect(cardStart, isNonNegative);
    expect(metaStart, greaterThan(cardStart));

    final helperSource = source.substring(helperStart, mapStart);
    final mapSource = source.substring(mapStart, mapEnd);
    final cardSource = source.substring(cardStart, metaStart);

    expect(helperSource, contains('if (_isLightActivitiesTheme(context))'));
    expect(helperSource, contains('return null;'));
    expect(mapSource, contains('boxShadow: _activitiesDarkThemeShadow('));
    expect(cardSource, contains('boxShadow: _activitiesDarkThemeShadow('));
    expect(mapSource, isNot(contains('context.activitiesColors.black')));
    expect(cardSource, isNot(contains('context.activitiesColors.black')));
  });

  test('activities category avatar avoids white halo in light theme', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final helperStart = source.indexOf(
      'AppBoxDecoration _activityCategoryAvatarDecoration',
    );
    final nextClassStart = source.indexOf(
      'class _VisibilityBadgeStyle',
      helperStart,
    );

    expect(helperStart, isNonNegative);
    expect(nextClassStart, greaterThan(helperStart));

    final helperSource = source.substring(helperStart, nextClassStart);
    final lightStart = helperSource.indexOf('if (colors.isLight)');
    final darkStart = helperSource.indexOf(
      '\n\n  return AppBoxDecoration(',
      lightStart,
    );

    expect(lightStart, isNonNegative);
    expect(darkStart, greaterThan(lightStart));

    final lightSource = helperSource.substring(lightStart, darkStart);

    expect(lightSource, contains('color: colors.secondary'));
    expect(lightSource, contains('colors.borderSecondary'));
    expect(lightSource, isNot(contains('LinearGradient(')));
    expect(lightSource, isNot(contains('colors.white.withValues')));
  });

  test('activities card shell uses visible light-theme border', () async {
    final source = await File(
      'lib/screens/activities/activities_screen.dart',
    ).readAsString();

    final colorsStart = source.indexOf('final class _ActivitiesColors');
    final colorsEnd = source.indexOf('extension _ActivitiesColorContext');
    final cardStart = source.indexOf('class _DiscoverActivityCard');
    final metaStart = source.indexOf('class _CardMetaItem');

    expect(colorsStart, isNonNegative);
    expect(colorsEnd, greaterThan(colorsStart));
    expect(cardStart, isNonNegative);
    expect(metaStart, greaterThan(cardStart));

    final colorsSource = source.substring(colorsStart, colorsEnd);
    final cardSource = source.substring(cardStart, metaStart);
    final shellDecorationStart = cardSource.indexOf(
      'decoration: AppBoxDecoration(',
    );
    final shellDecorationEnd = cardSource.indexOf(
      'child: Column(',
      shellDecorationStart,
    );

    expect(shellDecorationStart, isNonNegative);
    expect(shellDecorationEnd, greaterThan(shellDecorationStart));

    final shellDecorationSource = cardSource.substring(
      shellDecorationStart,
      shellDecorationEnd,
    );

    expect(colorsSource, contains('Color get activityCardSurface'));
    expect(colorsSource, contains('Color get activityCardBorder'));
    expect(
      shellDecorationSource,
      contains('color: context.activitiesColors.activityCardSurface'),
    );
    expect(
      shellDecorationSource,
      contains('color: context.activitiesColors.activityCardBorder'),
    );
    expect(shellDecorationSource, isNot(contains('LinearGradient(')));
    expect(
      shellDecorationSource,
      isNot(contains('primary.withValues(alpha: 0.08)')),
    );
  });

  test(
    'activities light cover fallbacks and map preview avoid dimming layers',
    () async {
      final activitiesSource = await File(
        'lib/screens/activities/activities_screen.dart',
      ).readAsString();
      final artSource = await File(
        'lib/features/activities/activity_category_art.dart',
      ).readAsString();

      final painterStart = activitiesSource.indexOf(
        'class _ActivitiesNearbyMapPainter',
      );
      final painterEnd = activitiesSource.indexOf(
        'class _DiscoverActivityCard',
        painterStart,
      );
      final fallbackStart = artSource.indexOf(
        'class ActivityDecorativeCoverFallback',
      );
      final fallbackEnd = artSource.indexOf(
        'ActivityCardArtSpec activityCategoryVisual',
        fallbackStart,
      );

      expect(painterStart, isNonNegative);
      expect(painterEnd, greaterThan(painterStart));
      expect(fallbackStart, isNonNegative);
      expect(fallbackEnd, greaterThan(fallbackStart));

      final painterSource = activitiesSource.substring(
        painterStart,
        painterEnd,
      );
      final fallbackSource = artSource.substring(fallbackStart, fallbackEnd);

      expect(painterSource, contains('final isLight = colors.isLight;'));
      expect(painterSource, contains('final backgroundColors = isLight'));
      expect(painterSource, contains('final parkColor = isLight'));
      expect(painterSource, isNot(contains('greenOverlayMuted01')));

      expect(fallbackSource, contains('final backgroundColors = isDark'));
      expect(fallbackSource, contains('final topCircleColor = isDark'));
      expect(fallbackSource, contains('final bottomCircleColor = isDark'));
      expect(
        fallbackSource,
        isNot(contains(': colors.white.withValues(alpha:')),
      );
      expect(
        fallbackSource,
        isNot(contains(': colors.primaryContainer.withValues(alpha:')),
      );
      expect(
        fallbackSource,
        isNot(contains('colors.black.withValues(alpha: isDark ? 0.14 : 0.08)')),
      );
    },
  );
}
