import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story tray avatar and create badge use adaptive v2 colors', () async {
    final source = await File(
      'lib/features/feed/widgets/story_tray_block.dart',
    ).readAsString();

    final createStart = source.indexOf('class _CreateStoryTrayItem');
    final createEnd = source.indexOf('class _StoryTrayItem', createStart);
    final scaffoldStart = source.indexOf('class _StoryTrayScaffold');
    final scaffoldEnd = source.indexOf('enum _StoryCircleState', scaffoldStart);
    final frameStart = source.indexOf('class _StoryCircleFrame');
    final frameEnd = source.indexOf('class _StoryCircleImage', frameStart);
    final fallbackStart = source.indexOf('class _StoryCircleFallback');
    final fallbackEnd = source.indexOf('double _storyItemWidth', fallbackStart);

    expect(createStart, isNonNegative);
    expect(createEnd, greaterThan(createStart));
    expect(scaffoldStart, isNonNegative);
    expect(scaffoldEnd, greaterThan(scaffoldStart));
    expect(frameStart, isNonNegative);
    expect(frameEnd, greaterThan(frameStart));
    expect(fallbackStart, isNonNegative);
    expect(fallbackEnd, greaterThan(fallbackStart));

    final createSource = source.substring(createStart, createEnd);
    final scaffoldSource = source.substring(scaffoldStart, scaffoldEnd);
    final frameSource = source.substring(frameStart, frameEnd);
    final fallbackSource = source.substring(fallbackStart, fallbackEnd);

    expect(source, contains('app_design_system.dart'));
    expect(createSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(createSource, contains('color: colors.primary'));
    expect(createSource, contains('color: colors.background'));
    expect(createSource, contains('width: avatarSize'));
    expect(createSource, contains('height: avatarSize'));
    expect(createSource, contains('right: 0'));
    expect(createSource, contains('bottom: 0'));
    expect(createSource, isNot(contains('fit: StackFit.expand')));
    expect(createSource, isNot(contains('AppPalette.backgroundWarm')));
    expect(scaffoldSource, contains('alignment: Alignment.topCenter'));
    expect(scaffoldSource, contains('CrossAxisAlignment.center'));
    expect(scaffoldSource, contains('child: Center('));
    expect(scaffoldSource, isNot(contains('width: double.infinity')));
    expect(scaffoldSource, isNot(contains('Transform.translate')));
    expect(scaffoldSource, contains('color: colors.textSecondary'));
    expect(frameSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(frameSource, contains('color: colors.background'));
    expect(frameSource, isNot(contains('AppPalette.backgroundWarm')));
    expect(fallbackSource, contains('color: colors.surfaceWarm'));
    expect(fallbackSource, isNot(contains('gradient:')));
  });
}
