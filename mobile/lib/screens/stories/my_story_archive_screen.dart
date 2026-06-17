import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import 'story_tray_viewer_screen.dart';

class MyStoryArchiveScreen extends StatefulWidget {
  const MyStoryArchiveScreen({super.key, StoryApi? storyApi})
    : _storyApiOverride = storyApi;

  final StoryApi? _storyApiOverride;

  @override
  State<MyStoryArchiveScreen> createState() => _MyStoryArchiveScreenState();
}

class _MyStoryArchiveScreenState extends State<MyStoryArchiveScreen> {
  static const _pageLimit = 24;

  late final StoryApi _storyApi = widget._storyApiOverride ?? StoryApi();
  final Map<_StoryArchiveTab, _StoryTabState> _tabStates = {
    _StoryArchiveTab.active: _StoryTabState(),
    _StoryArchiveTab.archive: _StoryTabState(),
  };
  _StoryArchiveTab _selectedTab = _StoryArchiveTab.active;

  @override
  void initState() {
    super.initState();
    _loadStories(_StoryArchiveTab.active, reset: true);
  }

  _StoryTabState _stateFor(_StoryArchiveTab tab) => _tabStates[tab]!;

  _StoryTabState get _currentState => _stateFor(_selectedTab);

  Future<void> _selectTab(_StoryArchiveTab tab) async {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
    final state = _stateFor(tab);
    if (!state.hasLoaded && !state.isLoading) {
      await _loadStories(tab, reset: true);
    }
  }

  Future<void> _loadStories(_StoryArchiveTab tab, {bool reset = false}) async {
    final state = _stateFor(tab);
    if ((state.isLoadingMore && !reset) || (state.isLoading && !reset)) {
      return;
    }

    setState(() {
      if (reset) {
        state.isLoading = true;
        state.error = null;
      } else {
        state.isLoadingMore = true;
      }
    });

    try {
      final page = tab == _StoryArchiveTab.archive
          ? await _storyApi.listMyArchivedStories(
              limit: _pageLimit,
              offset: reset ? 0 : state.stories.length,
            )
          : await _storyApi.listMyActiveStories(
              limit: _pageLimit,
              offset: reset ? 0 : state.stories.length,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          state.stories
            ..clear()
            ..addAll(page.items);
        } else {
          state.stories.addAll(page.items);
        }
        state.hasLoaded = true;
        state.hasMore = page.hasMore;
        state.isLoading = false;
        state.isLoadingMore = false;
        state.error = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        state.hasLoaded = true;
        state.isLoading = false;
        state.isLoadingMore = false;
        state.error = 'load_failed';
      });
    }
  }

  Future<void> _refreshCurrentTab() {
    return _loadStories(_selectedTab, reset: true);
  }

  Future<void> _loadMoreCurrentTab() {
    return _loadStories(_selectedTab);
  }

  void _openStory(List<StoryVm> stories, int index) {
    if (index < 0 || index >= stories.length) {
      return;
    }
    final isArchive = _selectedTab == _StoryArchiveTab.archive;
    context.push(
      '/stories/viewer',
      extra: StoryTrayViewerRouteData(
        stories: List<StoryVm>.unmodifiable(stories),
        initialIndex: index,
        source: isArchive ? 'story_archive' : 'story_active',
        allowExpired: isArchive,
        trackSeen: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: StoryPalette.backgroundDeep,
      appBar: AppBar(
        backgroundColor: StoryPalette.backgroundDeep,
        foregroundColor: StoryPalette.text,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.myStoryArchiveTitle),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              StoryPalette.backgroundTop,
              StoryPalette.background,
              StoryPalette.backgroundDeep,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _StoryArchiveTabs(
                  selectedTab: _selectedTab,
                  onSelected: (tab) => unawaited(_selectTab(tab)),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: StoryPalette.surfaceRaised,
                  onRefresh: _refreshCurrentTab,
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _currentState;
    final isArchive = _selectedTab == _StoryArchiveTab.archive;

    if (state.isLoading && state.stories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (state.error != null && state.stories.isEmpty) {
      return _ArchiveMessage(
        icon: Icons.cloud_off_rounded,
        title: l10n.storyArchiveLoadFailedTitle,
        subtitle: l10n.storyArchiveLoadFailedMessage,
      );
    }

    if (state.stories.isEmpty) {
      return _ArchiveMessage(
        icon: isArchive ? Icons.history_rounded : Icons.auto_stories_rounded,
        title: isArchive
            ? l10n.storyArchiveEmptyTitle
            : l10n.storyArchiveActiveEmptyTitle,
        subtitle: isArchive
            ? l10n.storyArchiveEmptySubtitle
            : l10n.storyArchiveActiveEmptySubtitle,
      );
    }

    final groupedStories = _groupStoriesByPublicationDate(state.stories);
    final visibleStories = groupedStories
        .expand((group) => group.stories)
        .toList(growable: false);
    final storySlivers = <Widget>[];
    var visibleIndexOffset = 0;
    for (final group in groupedStories) {
      final groupStartIndex = visibleIndexOffset;
      storySlivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Text(
              formatStoryDate(context, group.date),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
      storySlivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          sliver: SliverGrid.builder(
            itemCount: group.stories.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 14,
            ),
            itemBuilder: (context, index) {
              return _ArchivedStoryTile(
                story: group.stories[index],
                isArchive: isArchive,
                onTap: () =>
                    _openStory(visibleStories, groupStartIndex + index),
              );
            },
          ),
        ),
      );
      visibleIndexOffset += group.stories.length;
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Text(
              isArchive
                  ? l10n.storyArchiveSubtitle
                  : l10n.storyArchiveActiveSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StoryPalette.textSoft,
                height: 1.35,
              ),
            ),
          ),
        ),
        ...storySlivers,
        if (state.hasMore || state.isLoadingMore)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverToBoxAdapter(
              child: FilledButton.icon(
                onPressed: state.isLoadingMore ? null : _loadMoreCurrentTab,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: 0.32,
                  ),
                  foregroundColor: const Color(0xFF241405),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: state.isLoadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(l10n.storyArchiveLoadMoreAction),
              ),
            ),
          ),
      ],
    );
  }
}

enum _StoryArchiveTab { active, archive }

class _StoryTabState {
  final List<StoryVm> stories = <StoryVm>[];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasLoaded = false;
  bool hasMore = false;
  String? error;
}

class _StoryDateGroup {
  const _StoryDateGroup({required this.date, required this.stories});

  final DateTime date;
  final List<StoryVm> stories;
}

List<_StoryDateGroup> _groupStoriesByPublicationDate(List<StoryVm> stories) {
  final orderedStories = List<StoryVm>.of(stories)
    ..sort(
      (left, right) => _storyPublicationInstant(
        right,
      ).compareTo(_storyPublicationInstant(left)),
    );
  final grouped = <DateTime, List<StoryVm>>{};
  for (final story in orderedStories) {
    final publishedAt = _storyPublicationInstant(story).toLocal();
    final date = DateTime(publishedAt.year, publishedAt.month, publishedAt.day);
    grouped.putIfAbsent(date, () => <StoryVm>[]).add(story);
  }

  return grouped.entries
      .map((entry) => _StoryDateGroup(date: entry.key, stories: entry.value))
      .toList(growable: false);
}

DateTime _storyPublicationInstant(StoryVm story) =>
    story.publishedAt ?? story.createdAt;

class _StoryArchiveTabs extends StatelessWidget {
  const _StoryArchiveTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  final _StoryArchiveTab selectedTab;
  final ValueChanged<_StoryArchiveTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryPalette.surfaceRaised.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _StoryArchiveTabButton(
                label: l10n.storyArchiveActiveTab,
                selected: selectedTab == _StoryArchiveTab.active,
                onTap: () => onSelected(_StoryArchiveTab.active),
              ),
            ),
            Expanded(
              child: _StoryArchiveTabButton(
                label: l10n.storyArchiveArchiveTab,
                selected: selectedTab == _StoryArchiveTab.archive,
                onTap: () => onSelected(_StoryArchiveTab.archive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryArchiveTabButton extends StatelessWidget {
  const _StoryArchiveTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchivedStoryTile extends StatelessWidget {
  const _ArchivedStoryTile({
    required this.story,
    required this.isArchive,
    required this.onTap,
  });

  final StoryVm story;
  final bool isArchive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: StoryPalette.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                StoryCoverImage(url: story.coverUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatStoryTimeline(context, l10n, story, isArchive),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveMessage extends StatelessWidget {
  const _ArchiveMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            24,
            constraints.maxHeight > 520 ? 96 : 40,
            24,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: StoryPalette.surfaceRaised.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.16),
                        ),
                        child: Icon(icon, color: AppColors.accent, size: 30),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          color: StoryPalette.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: StoryPalette.textSoft,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatStoryTimeline(
  BuildContext context,
  AppLocalizations l10n,
  StoryVm story,
  bool isArchive,
) {
  final local = story.expiresAt.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  final prefix = isArchive
      ? l10n.storyArchiveExpiredPrefix
      : l10n.storyArchiveActiveUntilPrefix;
  return '$prefix $date, $time';
}
