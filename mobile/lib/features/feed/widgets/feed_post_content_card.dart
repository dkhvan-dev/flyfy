import 'package:flutter/material.dart';

import '../../../core/network/post_api.dart';
import '../../stories/models/post_vm.dart';
import 'feed_post_card.dart';
import 'quick_post_thread_card.dart';

class FeedPostContentCard extends StatelessWidget {
  const FeedPostContentCard({
    super.key,
    required this.post,
    required this.postApi,
    this.canInteract = true,
    this.style,
    this.onOpen,
    this.onLike,
    this.onShare,
    this.onHide,
    this.onNotInterested,
    this.onQuickPostEngagement,
  });

  final PostVm post;
  final PostApi postApi;
  final bool canInteract;
  final FeedPostCardStyle? style;
  final ValueChanged<PostVm>? onOpen;
  final FeedPostLikeCallback? onLike;
  final FeedPostActionCallback? onShare;
  final FeedPostActionCallback? onHide;
  final FeedPostActionCallback? onNotInterested;
  final QuickPostEngagementCallback? onQuickPostEngagement;

  @override
  Widget build(BuildContext context) {
    if (post.isQuickPost) {
      return QuickPostThreadCard(
        post: post,
        postApi: postApi,
        canInteract: canInteract,
        onOpen: onOpen,
        onShare: onShare,
        onHide: onHide,
        onNotInterested: onNotInterested,
        onEngagement: onQuickPostEngagement,
      );
    }

    return FeedPostCard(
      post: post,
      style: style,
      onOpen: onOpen,
      onLike: onLike,
      onShare: onShare,
      onHide: onHide,
      onNotInterested: onNotInterested,
    );
  }
}
