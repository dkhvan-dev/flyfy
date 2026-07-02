import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stories screen uses adaptive V2 colors instead of legacy palette',
    () async {
      final source = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();

      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('storyScreenBackground(context)'));
      expect(source, isNot(contains('AppPalette.')));
      expect(source, isNot(contains('StoryPalette.')));
    },
  );

  test('shared story visual primitives use adaptive V2 colors', () async {
    final source = await File(
      'lib/features/stories/story_ui.dart',
    ).readAsString();

    final stateStart = source.indexOf('extension StoryEntryStateX');
    final stateEnd = source.indexOf('StoryEntryState resolveStoryEntryState');
    final backgroundStart = source.indexOf(
      'BoxDecoration storyScreenBackground',
    );
    final avatarStart = source.indexOf('class StoryAvatar');
    final seenStart = source.indexOf('class StorySeenMarker');
    final coverStart = source.indexOf('class StoryCoverImage');
    final videoStart = source.indexOf('class _StoryVideoCover');
    final loadingStart = source.indexOf('class _StoryImageLoadingPlaceholder');

    expect(source, isNot(contains('AppPalette.')));
    expect(stateStart, isNonNegative);
    expect(stateEnd, greaterThan(stateStart));
    expect(backgroundStart, isNonNegative);
    expect(avatarStart, greaterThan(backgroundStart));
    expect(seenStart, greaterThan(avatarStart));
    expect(coverStart, greaterThan(seenStart));
    expect(videoStart, greaterThan(coverStart));
    expect(loadingStart, greaterThan(videoStart));

    final stateSource = source.substring(stateStart, stateEnd);
    final backgroundSource = source.substring(backgroundStart, avatarStart);
    final avatarSource = source.substring(avatarStart, seenStart);
    final seenSource = source.substring(seenStart, coverStart);
    final mediaSource = source.substring(videoStart);

    expect(stateSource, contains('Color foreground(BuildContext context)'));
    expect(stateSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(stateSource, isNot(contains('AppPalette.')));
    expect(
      backgroundSource,
      contains('storyScreenBackground(BuildContext context)'),
    );
    expect(backgroundSource, contains('colors.screenGradientColors'));
    expect(backgroundSource, isNot(contains('StoryPalette.')));
    expect(avatarSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(avatarSource, contains('color: colors.surfaceWarm'));
    expect(avatarSource, isNot(contains('LinearGradient(')));
    expect(avatarSource, isNot(contains('AppPalette.')));
    expect(seenSource, contains('color: colors.success'));
    expect(seenSource, isNot(contains('AppPalette.')));
    expect(mediaSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(mediaSource, isNot(contains('AppPalette.')));
  });
}
