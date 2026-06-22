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

  test(
    'story editor route reference creation is gated with user routes',
    () async {
      final screenSource = await File(
        'lib/features/stories/editor/presentation/story_editor_screen.dart',
      ).readAsString();
      final sheetSource = await File(
        'lib/features/stories/editor/presentation/widgets/story_add_block_sheet.dart',
      ).readAsString();

      expect(sheetSource, contains("user_route_feature_flags.dart"));
      expect(screenSource, contains("user_route_feature_flags.dart"));
      expect(
        sheetSource,
        contains('if (UserRouteFeatureFlags.customRoutesEnabled)'),
      );
      expect(
        screenSource,
        contains(
          'type == StoryBlockType.routeReference &&\n'
          '        UserRouteFeatureFlags.customRoutesEnabled',
        ),
      );
      expect(sheetSource, contains('StoryBlockType.routeReference'));
      expect(screenSource, contains('class _RouteReferencePickerSheet'));
      expect(
        screenSource,
        contains('route.visibility != UserRouteVisibility.private'),
      );
      expect(screenSource, contains('StoryBlock.routeReference('));
      expect(screenSource, contains('StoryRouteReference('));
      expect(screenSource, contains('route.snapshot.distanceMeters'));
      expect(screenSource, contains('route.snapshot.durationSeconds'));
      expect(screenSource, contains('https://inflap.app/user-routes/'));
    },
  );
}
