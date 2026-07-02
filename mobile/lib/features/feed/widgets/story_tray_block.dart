import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../stories/models/story_vm.dart';
import '../../../l10n/generated/app_localizations.dart';

typedef StoryTrayOpenCallback =
    void Function(StoryVm story, List<StoryVm> stories, int index);

class StoryTrayBlock extends StatelessWidget {
  const StoryTrayBlock({
    super.key,
    required this.stories,
    this.onStoryOpen,
    this.onCreateStory,
    this.viewerAvatarUrl,
    this.viewerInitials = 'F',
    this.viewerUserId,
  });

  final List<StoryVm> stories;
  final StoryTrayOpenCallback? onStoryOpen;
  final VoidCallback? onCreateStory;
  final String? viewerAvatarUrl;
  final String viewerInitials;
  final String? viewerUserId;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty && onCreateStory == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final ownStories = stories
        .where((story) => story.isOwnedBy(viewerUserId))
        .toList(growable: false);
    final otherStoryGroups = _storyTrayAuthorGroups(stories, viewerUserId);
    final sortedOwnViewableStories = ownStories
        .where(_isTrayStoryViewable)
        .toList(growable: false);
    final hasUnseenOwnStories = sortedOwnViewableStories.any(
      (story) => !story.isSeenByViewer,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = _storyItemWidth(constraints.maxWidth);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final avatarSize = _storyAvatarSize(constraints.maxWidth);
        final createStoryLabel = l10n.feedCreateStoryAction;
        final createStoryItemWidth = _createStoryItemWidth(
          context,
          createStoryLabel,
          avatarSize,
        );
        final trayHeight = (112 * textScale).clamp(112.0, 138.0);
        final itemCount =
            otherStoryGroups.length + (onCreateStory == null ? 0 : 1);

        return Semantics(
          label: l10n.feedStoriesSectionTitle,
          container: true,
          child: SizedBox(
            height: trayHeight,
            child: ListView.separated(
              key: const ValueKey('feed-stories-circle-tray'),
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (onCreateStory != null && index == 0) {
                  return SizedBox(
                    width: createStoryItemWidth,
                    child: _CreateStoryTrayItem(
                      label: createStoryLabel,
                      avatarUrl: viewerAvatarUrl,
                      initials: viewerInitials,
                      avatarSize: avatarSize,
                      hasViewableStories: sortedOwnViewableStories.isNotEmpty,
                      hasUnseenStories: hasUnseenOwnStories,
                      onOpenStories:
                          onStoryOpen == null ||
                              sortedOwnViewableStories.isEmpty
                          ? null
                          : () => onStoryOpen!(
                              sortedOwnViewableStories.first,
                              sortedOwnViewableStories,
                              0,
                            ),
                      onCreateStory: onCreateStory!,
                    ),
                  );
                }

                final storyIndex = index - (onCreateStory == null ? 0 : 1);
                final group = otherStoryGroups[storyIndex];
                final story = group.representative;
                return SizedBox(
                  width: itemWidth,
                  child: _StoryTrayItem(
                    story: story,
                    avatarSize: avatarSize,
                    onOpen: onStoryOpen == null
                        ? null
                        : () => onStoryOpen!(story, group.stories, 0),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CreateStoryTrayItem extends StatelessWidget {
  const _CreateStoryTrayItem({
    required this.label,
    required this.initials,
    required this.avatarSize,
    required this.hasViewableStories,
    required this.hasUnseenStories,
    required this.onCreateStory,
    this.onOpenStories,
    this.avatarUrl,
  });

  final String label;
  final String initials;
  final double avatarSize;
  final bool hasViewableStories;
  final bool hasUnseenStories;
  final VoidCallback onCreateStory;
  final VoidCallback? onOpenStories;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return _StoryTrayScaffold(
      key: const ValueKey('open-feed-create-story'),
      label: label,
      onTap: hasViewableStories && onOpenStories != null
          ? onOpenStories
          : onCreateStory,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          key: const ValueKey('open-feed-create-story-visual'),
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _StoryCircleFrame(
                key: const ValueKey('open-feed-create-story-avatar'),
                size: avatarSize,
                state: hasUnseenStories
                    ? _StoryCircleState.unseen
                    : _StoryCircleState.seen,
                child: _StoryCircleImage(
                  imageUrl: avatarUrl,
                  initials: initials,
                  icon: Icons.person_rounded,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Tooltip(
                  message: label,
                  child: Material(
                    color: colors.transparent,
                    child: InkWell(
                      key: const ValueKey('open-feed-create-story-plus'),
                      onTap: onCreateStory,
                      customBorder: const CircleBorder(),
                      child: DecoratedBox(
                        decoration: AppBoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.background,
                            width: 3,
                          ),
                        ),
                        child: SizedBox.square(
                          dimension: 24,
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryTrayItem extends StatelessWidget {
  const _StoryTrayItem({
    required this.story,
    required this.avatarSize,
    this.onOpen,
  });

  final StoryVm story;
  final double avatarSize;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final isSeen = story.isSeenByViewer;
    final isExpired = story.isExpired;
    final isInteractive = !isExpired && onOpen != null;
    final circleState = isExpired
        ? _StoryCircleState.expired
        : isSeen
        ? _StoryCircleState.seen
        : _StoryCircleState.unseen;
    final label = _storyTrayLabel(story);

    return Opacity(
      opacity: isExpired ? 0.48 : (isSeen ? 0.72 : 1),
      child: _StoryTrayScaffold(
        key: ValueKey('open-feed-tray-story-${story.id}'),
        label: label,
        onTap: isInteractive ? onOpen : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _StoryCircleFrame(
              key: ValueKey('feed-tray-story-circle-${story.id}'),
              size: avatarSize,
              state: circleState,
              child: _StoryCircleImage(
                imageUrl: _storyTrayImageUrl(story),
                initials: story.author.initials,
                icon: Icons.auto_stories_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTrayScaffold extends StatelessWidget {
  const _StoryTrayScaffold({
    super.key,
    required this.child,
    required this.label,
    this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.circular(999),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(vertical: 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth,
                          child: Center(child: child),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: constraints.maxWidth,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: labelStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _StoryCircleState { create, unseen, seen, expired }

class _StoryCircleFrame extends StatelessWidget {
  const _StoryCircleFrame({
    super.key,
    required this.size,
    required this.state,
    required this.child,
  });

  final double size;
  final _StoryCircleState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final ringWidth = state == _StoryCircleState.create ? 2.0 : 3.0;
    final gradient = switch (state) {
      _StoryCircleState.unseen => LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [colors.primarySoft, colors.primary, colors.secondary],
      ),
      _StoryCircleState.create => LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          colors.primary.withValues(alpha: 0.34),
          colors.primary.withValues(alpha: 0.70),
        ],
      ),
      _ => LinearGradient(colors: [colors.border, colors.borderSoft]),
    };

    return Container(
      width: size,
      height: size,
      padding: AppEdgeInsets.all(ringWidth),
      decoration: AppBoxDecoration(shape: BoxShape.circle, gradient: gradient),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          shape: BoxShape.circle,
          color: colors.background,
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(3),
          child: ClipOval(child: child),
        ),
      ),
    );
  }
}

class _StoryCircleImage extends StatelessWidget {
  const _StoryCircleImage({
    required this.initials,
    required this.icon,
    this.imageUrl,
  });

  final String? imageUrl;
  final String initials;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final normalized = initials.trim().isEmpty
        ? 'F'
        : initials.trim().toUpperCase();
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _StoryCircleFallback(initials: normalized, icon: icon);
        },
      );
    }

    return _StoryCircleFallback(initials: normalized, icon: icon);
  }
}

class _StoryCircleFallback extends StatelessWidget {
  const _StoryCircleFallback({required this.initials, required this.icon});

  final String initials;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(color: colors.surfaceWarm),
      child: Center(
        child: initials.trim().isEmpty
            ? Icon(icon, color: colors.primary, size: 28)
            : Text(
                initials.characters.take(2).toString().toUpperCase(),
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

double _createStoryItemWidth(
  BuildContext context,
  String label,
  double avatarSize,
) {
  final textStyle =
      Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  final painter = TextPainter(
    text: TextSpan(text: label, style: textStyle),
    maxLines: 1,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();

  final labelWidth = painter.width.ceilToDouble();
  final visualWidth = avatarSize;
  return math.max(labelWidth, visualWidth);
}

double _storyItemWidth(double availableWidth) {
  if (availableWidth >= 600) {
    return 164;
  }
  if (availableWidth >= 360) {
    return 156;
  }
  return 148;
}

double _storyAvatarSize(double availableWidth) {
  if (availableWidth >= 600) {
    return 76;
  }
  if (availableWidth >= 360) {
    return 70;
  }
  return 64;
}

String _storyTrayLabel(StoryVm story) {
  final authorName = story.author.preferredName.trim();
  if (authorName.isNotEmpty) {
    return authorName;
  }
  return story.title.trim().isEmpty ? 'Inflap' : story.title.trim();
}

String? _storyTrayImageUrl(StoryVm story) {
  final cover = story.coverUrl?.trim();
  if (cover != null && cover.isNotEmpty) {
    return cover;
  }
  final avatar = story.author.avatarUrl?.trim();
  if (avatar != null && avatar.isNotEmpty) {
    return avatar;
  }
  return null;
}

bool _isTrayStoryViewable(StoryVm story) {
  return story.isPublished && !story.isExpired && story.slug.trim().isNotEmpty;
}

class _StoryTrayAuthorGroup {
  const _StoryTrayAuthorGroup({
    required this.representative,
    required this.stories,
    required this.firstSourceIndex,
    required this.relevanceScore,
  });

  final StoryVm representative;
  final List<StoryVm> stories;
  final int firstSourceIndex;
  final double relevanceScore;
}

class _MutableStoryTrayAuthorGroup {
  _MutableStoryTrayAuthorGroup({required this.firstSourceIndex});

  final int firstSourceIndex;
  final List<_StoryTrayEntry> entries = <_StoryTrayEntry>[];
}

class _StoryTrayEntry {
  const _StoryTrayEntry({required this.story, required this.sourceIndex});

  final StoryVm story;
  final int sourceIndex;
}

List<_StoryTrayAuthorGroup> _storyTrayAuthorGroups(
  List<StoryVm> stories,
  String? viewerUserId,
) {
  final grouped = <String, _MutableStoryTrayAuthorGroup>{};

  for (var index = 0; index < stories.length; index++) {
    final story = stories[index];
    if (story.isOwnedBy(viewerUserId) || !_isTrayStoryViewable(story)) {
      continue;
    }
    final key = _storyTrayAuthorKey(story);
    if (key.isEmpty) {
      continue;
    }
    final group = grouped.putIfAbsent(
      key,
      () => _MutableStoryTrayAuthorGroup(firstSourceIndex: index),
    );
    group.entries.add(_StoryTrayEntry(story: story, sourceIndex: index));
  }

  final result = <_StoryTrayAuthorGroup>[];
  for (final group in grouped.values) {
    group.entries.sort(_compareStoryTrayEntries);
    final groupStories = [for (final entry in group.entries) entry.story];
    final representative = groupStories.first;
    result.add(
      _StoryTrayAuthorGroup(
        representative: representative,
        stories: List<StoryVm>.unmodifiable(groupStories),
        firstSourceIndex: group.firstSourceIndex,
        relevanceScore: _storyTrayRelevanceScore(representative, viewerUserId),
      ),
    );
  }

  result.sort(_compareStoryTrayAuthorGroups);
  return List<_StoryTrayAuthorGroup>.unmodifiable(result);
}

int _compareStoryTrayAuthorGroups(
  _StoryTrayAuthorGroup a,
  _StoryTrayAuthorGroup b,
) {
  final unseenCompare = _storyTraySeenRank(
    a.representative,
  ).compareTo(_storyTraySeenRank(b.representative));
  if (unseenCompare != 0) {
    return unseenCompare;
  }

  final systemCompare = _storyTraySystemRank(
    a.representative,
  ).compareTo(_storyTraySystemRank(b.representative));
  if (systemCompare != 0) {
    return systemCompare;
  }

  final relevanceCompare = b.relevanceScore.compareTo(a.relevanceScore);
  if (relevanceCompare != 0) {
    return relevanceCompare;
  }

  return a.firstSourceIndex.compareTo(b.firstSourceIndex);
}

int _compareStoryTrayEntries(_StoryTrayEntry a, _StoryTrayEntry b) {
  final dateCompare = b.story.sortDate.compareTo(a.story.sortDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  return a.sourceIndex.compareTo(b.sourceIndex);
}

int _storyTraySeenRank(StoryVm story) => story.isSeenByViewer ? 1 : 0;

int _storyTraySystemRank(StoryVm story) => _isSystemStoryAuthor(story) ? 0 : 1;

String _storyTrayAuthorKey(StoryVm story) {
  final authorId = story.author.userId.trim();
  if (authorId.isNotEmpty) {
    return 'author:$authorId';
  }
  final authorName = story.author.preferredName.trim().toLowerCase();
  if (authorName.isNotEmpty) {
    return 'name:$authorName';
  }
  final storyId = story.id.trim();
  return storyId.isEmpty ? story.slug.trim() : storyId;
}

double _storyTrayRelevanceScore(StoryVm story, String? viewerUserId) {
  final stats = story.stats;
  final engagement =
      stats.views * 0.05 +
      stats.likes * 1.4 +
      stats.comments * 2.2 +
      stats.shares * 2.8;
  final recencyHours = DateTime.now()
      .toUtc()
      .difference(story.sortDate.toUtc())
      .inHours
      .clamp(0, 168);
  final recencyBoost = (168 - recencyHours) / 168 * 8;
  return engagement +
      recencyBoost +
      _storyTrayStableJitter(story, viewerUserId);
}

double _storyTrayStableJitter(StoryVm story, String? viewerUserId) {
  final seed = '${viewerUserId ?? ''}:${story.author.userId}:${story.id}';
  var hash = 17;
  for (final codeUnit in seed.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return (hash % 1000) / 1000.0;
}

bool _isSystemStoryAuthor(StoryVm story) {
  final values = [
    story.author.preferredName,
    story.author.nickname ?? '',
    story.title,
    ...story.tags,
  ].join(' ').toLowerCase();
  return values.contains('inflap') ||
      values.contains('official') ||
      values.contains('system') ||
      values.contains('admin') ||
      values.contains('официаль') ||
      values.contains('админ');
}
