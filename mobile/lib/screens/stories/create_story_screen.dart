import 'package:flutter/material.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_screen.dart';
import 'package:inflap/features/stories/models/story_vm.dart';

class CreateStoryScreen extends StatelessWidget {
  const CreateStoryScreen({super.key, this.storyId, this.initialStory});

  final String? storyId;
  final StoryVm? initialStory;

  bool get isEditMode =>
      (storyId ?? '').trim().isNotEmpty || initialStory != null;

  @override
  Widget build(BuildContext context) {
    return StoryEditorScreen(
      storyId: storyId,
      initialStory: initialStory,
      userId: initialStory?.author.userId ?? 'local-user',
    );
  }
}
