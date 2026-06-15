import 'package:flutter/material.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_screen.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_trust_context.dart';
import 'package:inflap/features/stories/models/post_vm.dart';

class CreateStoryScreen extends StatelessWidget {
  const CreateStoryScreen({
    super.key,
    this.storyId,
    this.initialStory,
    this.communityId,
    this.postProfileKey,
    this.availablePostProfileKeys,
    this.communityCountryCode,
    this.communityCityId,
    this.communityCityName,
    this.communityTrustContext,
    this.returnOnSave = false,
  });

  final String? storyId;
  final PostVm? initialStory;
  final String? communityId;
  final String? postProfileKey;
  final List<String>? availablePostProfileKeys;
  final String? communityCountryCode;
  final String? communityCityId;
  final String? communityCityName;
  final StoryEditorTrustContext? communityTrustContext;
  final bool returnOnSave;

  bool get isEditMode =>
      (storyId ?? '').trim().isNotEmpty || initialStory != null;

  @override
  Widget build(BuildContext context) {
    final communityKeySegment = (communityId ?? '').trim();

    return KeyedSubtree(
      key: ValueKey(
        'create-story-screen-community-'
        '${communityKeySegment.isEmpty ? 'none' : communityKeySegment}',
      ),
      child: StoryEditorScreen(
        storyId: storyId,
        initialStory: initialStory,
        communityId: communityId,
        postProfileKey: postProfileKey,
        availablePostProfileKeys: availablePostProfileKeys,
        communityCountryCode: communityCountryCode,
        communityCityId: communityCityId,
        communityCityName: communityCityName,
        communityTrustContext: communityTrustContext,
        returnOnSave: returnOnSave,
        userId: initialStory?.author.userId ?? 'local-user',
      ),
    );
  }
}
