import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/file_api.dart';
import '../../../screens/stories/story_tray_viewer_screen.dart';
import '../../stories/models/story_vm.dart';
import '../data/feed_api.dart';
import '../models/feed_block_vm.dart';
import 'story_tray_block.dart';

class SurfaceStoryTray extends StatefulWidget {
  const SurfaceStoryTray({
    super.key,
    required this.surface,
    this.feedApi,
    this.viewerAvatarUrl,
    this.viewerAvatarFileId,
    this.viewerInitials = 'F',
    this.viewerUserId,
    this.padding = EdgeInsets.zero,
    this.limit = 10,
  });

  final String surface;
  final FeedApi? feedApi;
  final String? viewerAvatarUrl;
  final String? viewerAvatarFileId;
  final String viewerInitials;
  final String? viewerUserId;
  final EdgeInsetsGeometry padding;
  final int limit;

  @override
  State<SurfaceStoryTray> createState() => _SurfaceStoryTrayState();
}

class _SurfaceStoryTrayState extends State<SurfaceStoryTray> {
  late FeedApi _feedApi = widget.feedApi ?? FeedApi();
  List<StoryVm> _stories = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadStories());
  }

  @override
  void didUpdateWidget(covariant SurfaceStoryTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedApi != widget.feedApi) {
      _feedApi = widget.feedApi ?? FeedApi();
    }
    if (oldWidget.surface != widget.surface ||
        oldWidget.feedApi != widget.feedApi ||
        oldWidget.limit != widget.limit) {
      unawaited(_loadStories());
    }
  }

  Future<void> _loadStories() async {
    final requestedSurface = widget.surface;
    try {
      final page = await _feedApi.getFeed(
        surface: requestedSurface,
        tab: 'for_you',
        limit: widget.limit,
      );
      if (!mounted || requestedSurface != widget.surface) {
        return;
      }
      setState(() {
        _stories = _storiesFromFeedBlocks(page.items);
      });
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ContextualStoryTrayBlock(
        surface: widget.surface,
        stories: _stories,
        viewerAvatarUrl: widget.viewerAvatarUrl,
        viewerAvatarFileId: widget.viewerAvatarFileId,
        viewerInitials: widget.viewerInitials,
        viewerUserId: widget.viewerUserId,
      ),
    );
  }
}

class ContextualStoryTrayBlock extends StatefulWidget {
  const ContextualStoryTrayBlock({
    super.key,
    required this.surface,
    required this.stories,
    this.viewerAvatarUrl,
    this.viewerAvatarFileId,
    this.viewerInitials = 'F',
    this.viewerUserId,
  });

  final String surface;
  final List<StoryVm> stories;
  final String? viewerAvatarUrl;
  final String? viewerAvatarFileId;
  final String viewerInitials;
  final String? viewerUserId;

  @override
  State<ContextualStoryTrayBlock> createState() =>
      _ContextualStoryTrayBlockState();
}

class _ContextualStoryTrayBlockState extends State<ContextualStoryTrayBlock> {
  late List<StoryVm> _stories = List<StoryVm>.of(widget.stories);
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _scheduleStoryExpiryRefresh();
  }

  @override
  void didUpdateWidget(covariant ContextualStoryTrayBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stories != widget.stories) {
      _stories = List<StoryVm>.of(widget.stories);
      _scheduleStoryExpiryRefresh();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCreateStory() async {
    final story = await context.push<StoryVm>('/stories/capture');
    if (!mounted || story == null) {
      return;
    }
    setState(() {
      _stories = _appendPublishedStory(_stories, story);
    });
    _scheduleStoryExpiryRefresh();
  }

  Future<void> _openStoryTray(
    StoryVm story,
    List<StoryVm> stories,
    int index,
  ) async {
    final viewableStories = stories.where(_isTrayViewerStory).toList();
    if (viewableStories.isEmpty) {
      return;
    }
    final firstUnseenIndex = viewableStories.indexWhere(
      (item) => !item.isSeenByViewer,
    );
    final initialIndex = firstUnseenIndex < 0 ? 0 : firstUnseenIndex;
    final seenStoryIds = await context.push<Set<String>>(
      '/stories/viewer',
      extra: StoryTrayViewerRouteData(
        stories: viewableStories,
        initialIndex: initialIndex,
        source: '${widget.surface}_tray',
      ),
    );
    if (!mounted || seenStoryIds == null || seenStoryIds.isEmpty) {
      return;
    }
    setState(() {
      _stories = _markStoriesSeen(
        _stories,
        seenStoryIds,
        DateTime.now().toUtc(),
      );
    });
  }

  void _scheduleStoryExpiryRefresh() {
    _expiryTimer?.cancel();
    final now = DateTime.now().toUtc();
    final expiries =
        _stories
            .map((story) => story.expiresAt)
            .where((expiresAt) => expiresAt.isAfter(now))
            .toList(growable: false)
          ..sort();
    if (expiries.isEmpty) {
      return;
    }
    final delay = expiries.first.difference(now) + const Duration(seconds: 1);
    _expiryTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      final cutoff = DateTime.now().toUtc();
      setState(() {
        _stories = [
          for (final story in _stories)
            if (story.expiresAt.isAfter(cutoff)) story,
        ];
      });
      _scheduleStoryExpiryRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoryTrayBlock(
      stories: _stories,
      onStoryOpen: _openStoryTray,
      onCreateStory: _openCreateStory,
      viewerAvatarUrl:
          widget.viewerAvatarUrl ??
          _avatarUrlFromFileId(widget.viewerAvatarFileId),
      viewerInitials: widget.viewerInitials,
      viewerUserId: widget.viewerUserId,
    );
  }
}

List<StoryVm> _storiesFromFeedBlocks(List<FeedBlockVm> blocks) {
  for (final block in blocks) {
    if (block.type == FeedBlockType.storiesTray) {
      return block.stories;
    }
  }
  return const [];
}

List<StoryVm> _appendPublishedStory(List<StoryVm> stories, StoryVm story) {
  final key = _storyKey(story);
  if (key.isEmpty) {
    return [...stories, story];
  }
  return [
    for (final item in stories)
      if (_storyKey(item) != key) item,
    story,
  ];
}

List<StoryVm> _markStoriesSeen(
  List<StoryVm> stories,
  Set<String> seenStoryIds,
  DateTime seenAt,
) {
  return [
    for (final story in stories)
      if (seenStoryIds.contains(story.id.trim()) ||
          seenStoryIds.contains(story.slug.trim()))
        story.copyWith(seenByViewer: true, seenAt: seenAt)
      else
        story,
  ];
}

bool _isTrayViewerStory(StoryVm story) {
  return story.isPublished && !story.isExpired && story.slug.trim().isNotEmpty;
}

String _storyKey(StoryVm story) {
  final id = story.id.trim();
  if (id.isNotEmpty) {
    return 'id:$id';
  }
  final slug = story.slug.trim();
  if (slug.isNotEmpty) {
    return 'slug:$slug';
  }
  return '';
}

String? _avatarUrlFromFileId(String? avatarFileId) {
  final trimmed = (avatarFileId ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return resolvePublicFileContentUrl(trimmed);
}
