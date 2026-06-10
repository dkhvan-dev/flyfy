import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story feed cards and bottom navigation expose semantic buttons', () {
    final source = File(
      'lib/screens/stories/stories_screen.dart',
    ).readAsStringSync();

    final cardStart = source.indexOf('class _StoryListCard');
    final formatTagStart = source.indexOf('class _FormatTag');
    expect(cardStart, isNonNegative);
    expect(formatTagStart, greaterThan(cardStart));
    final cardSource = source.substring(cardStart, formatTagStart);

    expect(cardSource, contains('Semantics('));
    expect(cardSource, contains('button: true'));
    expect(cardSource, contains('label: story.title'));
    expect(cardSource, contains('onTap: onTap'));

    final navStart = source.indexOf('class _StoriesNavButton');
    expect(navStart, isNonNegative);
    final navSource = source.substring(navStart);

    expect(navSource, contains('Semantics('));
    expect(navSource, contains('button: true'));
    expect(navSource, contains('selected: active'));
    expect(navSource, contains('label: label'));
    expect(navSource, contains('onTap: onTap'));
  });

  test('story detail hero overlay actions expose semantic buttons', () {
    final source = File(
      'lib/screens/stories/story_details_screen.dart',
    ).readAsStringSync();

    final overlayStart = source.indexOf('class _OverlayIconButton');
    final heroChipStart = source.indexOf('class _HeroChip');
    expect(overlayStart, isNonNegative);
    expect(heroChipStart, greaterThan(overlayStart));
    final overlaySource = source.substring(overlayStart, heroChipStart);

    expect(source, contains('semanticLabel: MaterialLocalizations.of('));
    expect(source, contains(')!.storyCommentShareAction'));
    expect(overlaySource, contains('Semantics('));
    expect(overlaySource, contains('button: true'));
    expect(overlaySource, contains('label: semanticLabel'));
    expect(overlaySource, contains('onTap: onTap'));
  });
}
