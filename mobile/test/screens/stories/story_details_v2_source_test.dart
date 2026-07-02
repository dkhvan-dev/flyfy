import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story details screen uses adaptive V2 design system colors', () async {
    final source = await File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'story details light theme keeps hero and author card free of dirty shadows',
    () async {
      final source = await File(
        'lib/screens/stories/story_details_screen.dart',
      ).readAsString();

      expect(source, contains('_storyHeroOverlayGradient(context)'));
      expect(source, contains('List<BoxShadow> _storyAuthorCardShadow'));
      expect(
        source,
        contains('Theme.of(context).brightness == Brightness.dark'),
      );
      expect(source, contains('return const <BoxShadow>[];'));

      final heroStart = source.indexOf('class _StoryHero');
      final overlayButtonStart = source.indexOf(
        'class _OverlayIconButton',
        heroStart,
      );
      expect(heroStart, isNonNegative);
      expect(overlayButtonStart, greaterThan(heroStart));

      final heroSource = source.substring(heroStart, overlayButtonStart);
      expect(
        heroSource,
        contains('gradient: _storyHeroOverlayGradient(context)'),
      );
      expect(
        heroSource,
        isNot(contains('_StoryDetailsColors.of(context).backgroundDeep')),
      );

      final authorStart = source.indexOf('class _AuthorCard');
      final statStart = source.indexOf('class _StatItem', authorStart);
      expect(authorStart, isNonNegative);
      expect(statStart, greaterThan(authorStart));

      final authorSource = source.substring(authorStart, statStart);
      expect(
        authorSource,
        contains('color: _StoryDetailsColors.of(context).surfaceRaised'),
      );
      expect(
        authorSource,
        contains('color: _StoryDetailsColors.of(context).border'),
      );
      expect(
        authorSource,
        contains('boxShadow: _storyAuthorCardShadow(context, adaptive)'),
      );
      expect(authorSource, isNot(contains('LinearGradient(')));
    },
  );

  test(
    'story details author stats keep icon number and label compact and readable',
    () async {
      final source = await File(
        'lib/screens/stories/story_details_screen.dart',
      ).readAsString();

      final statStart = source.indexOf('class _StatItem');
      final articleStart = source.indexOf('class _StoryArticle', statStart);
      expect(statStart, isNonNegative);
      expect(articleStart, greaterThan(statStart));

      final statSource = source.substring(statStart, articleStart);
      expect(statSource, contains('vertical: adaptive.scale(4)'));
      expect(statSource, contains('SizedBox(height: adaptive.scale(2))'));
      expect(statSource, contains('SizedBox(height: adaptive.scale(1))'));
      expect(
        statSource,
        contains(': _StoryDetailsColors.of(context).textPrimary'),
      );
      expect(
        statSource,
        isNot(
          contains(
            '_StoryDetailsColors.of(context).white.withValues(alpha: 0.82)',
          ),
        ),
      );
    },
  );
}
