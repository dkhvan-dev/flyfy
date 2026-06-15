import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'story cards expose content format labels instead of blog copy',
    () async {
      final screenSource = await File(
        'lib/screens/stories/stories_screen.dart',
      ).readAsString();
      final uiSource = await File(
        'lib/features/stories/story_ui.dart',
      ).readAsString();

      final cardStart = screenSource.indexOf('class _StoryListCard');
      final locationTagStart = screenSource.indexOf('class _LocationTag');
      expect(cardStart, isNonNegative);
      expect(locationTagStart, greaterThan(cardStart));

      final cardSource = screenSource.substring(cardStart, locationTagStart);

      expect(uiSource, contains('String formatStoryFormat('));
      expect(uiSource, contains("case 'ARTICLE':"));
      expect(uiSource, contains('storyFormatArticle'));
      expect(cardSource, contains('formatStoryFormat('));
      expect(cardSource, contains('formatStoryCategory('));
      expect(cardSource, contains('formatStoryDate('));
      expect(cardSource, contains('story.publishedAt ?? story.createdAt'));
      expect(cardSource, contains('_StoryMetaChip('));
      expect(cardSource, contains('Wrap('));
      expect(cardSource, contains('Semantics('));
      expect(cardSource, contains('button: true'));
      expect(cardSource, contains('onTap: state.disablesEntry ? null : onTap'));
      expect(cardSource, isNot(contains('Blog')));
    },
  );
}
