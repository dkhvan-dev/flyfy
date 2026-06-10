import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create story delegates UI internals to the block editor screen',
    () async {
      final source = await File(
        'lib/screens/stories/create_story_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('class CreateStoryScreen extends StatelessWidget'),
      );
      expect(source, contains('StoryEditorScreen('));
      expect(source, isNot(contains('TextEditingController')));
      expect(source, isNot(contains('ImagePicker')));
    },
  );

  test('story editor screen does not instantiate StoryApi directly', () async {
    final source = await File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsString();

    expect(
      source,
      isNot(contains("import '../../../../core/network/story_api.dart'")),
    );
    expect(source, isNot(contains('StoryApi()')));
  });
}
