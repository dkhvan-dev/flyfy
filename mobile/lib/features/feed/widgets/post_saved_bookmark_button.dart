import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/session_provider.dart';
import '../../../shared/widgets/app_saved_bookmark_button.dart';
import '../../saved/domain/saved_operation.dart';
import '../../saved/domain/saved_target.dart';
import '../../saved/presentation/state/saved_screen_controller.dart';
import '../../stories/models/post_vm.dart';

class PostSavedBookmarkButton extends StatelessWidget {
  const PostSavedBookmarkButton({
    super.key,
    required this.post,
    this.sourceSurface = SavedSourceSurface.card,
  });

  final PostVm post;
  final SavedSourceSurface sourceSurface;

  @override
  Widget build(BuildContext context) {
    // Some isolated post widgets are intentionally usable without app-level
    // providers (for example previews and golden tests).
    if (context.read<SessionProvider?>() == null ||
        context.read<SavedScreenController?>() == null ||
        !_isPostSavable(post)) {
      return const SizedBox.shrink();
    }

    final target = SavedTarget.tryCreate(
      entityType: SavedEntityType.post,
      entityId: post.id,
    );
    if (target == null) {
      return const SizedBox.shrink();
    }

    final title = _postPreviewTitle(post);
    final subtitle = post.excerpt.trim();
    return AppSavedBookmarkButton(
      target: target,
      sourceSurface: sourceSurface,
      previewTitle: title,
      previewSubtitle: subtitle.isEmpty || subtitle == title ? null : subtitle,
      previewImageUrl: post.coverUrl,
    );
  }
}

bool _isPostSavable(PostVm post) {
  final moderationStatus = post.moderationStatus.trim().toUpperCase();
  return _canonicalUuidPattern.hasMatch(post.id) &&
      post.isPublished &&
      post.archivedAt == null &&
      !post.isExpired &&
      (moderationStatus == 'NOT_REQUIRED' || moderationStatus == 'APPROVED');
}

String _postPreviewTitle(PostVm post) {
  for (final value in [post.title, post.excerpt, post.content ?? '']) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

final RegExp _canonicalUuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
