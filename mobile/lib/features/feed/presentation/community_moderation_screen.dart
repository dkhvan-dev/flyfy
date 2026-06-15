import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../stories/models/post_vm.dart';
import '../data/community_moderation_api.dart';
import '../models/community_moderation_vm.dart';

class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({
    super.key,
    required this.communityId,
    this.communityTitle,
    this.moderationApi,
  });

  final String communityId;
  final String? communityTitle;
  final CommunityModerationApi? moderationApi;

  @override
  State<CommunityModerationScreen> createState() =>
      _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends State<CommunityModerationScreen> {
  static const _pageLimit = 20;

  late final CommunityModerationApi _moderationApi =
      widget.moderationApi ?? CommunityModerationApi();
  late final ScrollController _scrollController;

  var _isLoading = true;
  var _isLoadingMore = false;
  var _hasMore = false;
  var _requestGeneration = 0;
  Object? _error;
  List<PostVm> _stories = const [];
  Set<String> _reviewingPostIds = const {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_maybeLoadMore);
    _loadQueue();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue({bool append = false}) async {
    if (append && (_isLoading || _isLoadingMore || !_hasMore)) {
      return;
    }

    final generation = ++_requestGeneration;
    final offset = append ? _stories.length : 0;

    if (append && mounted) {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _error = null;
        _hasMore = false;
        _stories = const [];
      });
    }

    try {
      final page = await _moderationApi.listPendingPosts(
        communityId: widget.communityId,
        limit: _pageLimit,
        offset: offset,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _stories = append ? [..._stories, ...page.items] : page.items;
        _hasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 640) {
      return;
    }
    _loadQueue(append: true);
  }

  Future<void> _approvePost(PostVm story) async {
    await _reviewPost(
      story: story,
      action: () => _moderationApi.approvePost(
        communityId: widget.communityId,
        postId: story.id,
      ),
      successMessage: AppLocalizations.of(
        context,
      )!.communityModerationApprovedMessage,
    );
  }

  Future<void> _rejectPost(PostVm story) async {
    final reason = await _showRejectSheet(story);
    if (reason == null || !mounted) {
      return;
    }

    await _reviewPost(
      story: story,
      action: () => _moderationApi.rejectPost(
        communityId: widget.communityId,
        postId: story.id,
        reason: reason,
      ),
      successMessage: AppLocalizations.of(
        context,
      )!.communityModerationRejectedMessage,
    );
  }

  Future<void> _reviewPost({
    required PostVm story,
    required Future<PostVm> Function() action,
    required String successMessage,
  }) async {
    final postId = story.id.trim();
    if (postId.isEmpty || _reviewingPostIds.contains(postId)) {
      return;
    }

    setState(() {
      _reviewingPostIds = {..._reviewingPostIds, postId};
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _stories = [
          for (final item in _stories)
            if (item.id != postId) item,
        ];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityModerationActionFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reviewingPostIds = {
            for (final id in _reviewingPostIds)
              if (id != postId) id,
          };
        });
      }
    }
  }

  Future<String?> _showRejectSheet(PostVm story) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final reasonController = TextEditingController();

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.communityModerationRejectAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('reject-reason-field'),
                  controller: reasonController,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.communityModerationRejectReasonLabel,
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(l10n.communityModerationRejectCancelAction),
                    ),
                    FilledButton(
                      key: ValueKey('confirm-reject-${story.id}'),
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(reasonController.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.destructive,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(
                        l10n.communityModerationRejectConfirmAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDecisionHistory(PostVm story) {
    final future = _moderationApi.listPostDecisions(
      communityId: widget.communityId,
      postId: story.id,
      limit: 20,
      offset: 0,
    );

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.communityModerationDecisionHistoryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: FutureBuilder<PostModerationDecisionPageVm>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _ModerationMessage(
                            icon: Icons.wifi_off_rounded,
                            title:
                                l10n.communityModerationDecisionHistoryFailed,
                            message: l10n.communityModerationLoadFailedMessage,
                          );
                        }

                        final items = snapshot.data?.items ?? const [];
                        if (items.isEmpty) {
                          return _ModerationMessage(
                            icon: Icons.history_rounded,
                            title: l10n.communityModerationDecisionHistoryEmpty,
                            message: story.title,
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _DecisionHistoryTile(decision: item);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final communityTitle = (widget.communityTitle ?? '').trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('community-members-action'),
            tooltip: l10n.communityMembersAction,
            onPressed: () {
              final encodedTitle = Uri.encodeComponent(communityTitle);
              context.push(
                '/communities/${Uri.encodeComponent(widget.communityId)}/members'
                '?title=$encodedTitle',
              );
            },
            icon: const Icon(Icons.group_outlined),
          ),
        ],
        title: Text(
          l10n.communityModerationTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(34),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                communityTitle.isNotEmpty
                    ? communityTitle
                    : l10n.communityModerationSubtitle(_stories.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => _loadQueue(),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _stories.isEmpty) {
      return const _ModerationStateList(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null && _stories.isEmpty) {
      return _ModerationStateList(
        child: _ModerationMessage(
          icon: Icons.wifi_off_rounded,
          title: l10n.communityModerationLoadFailedTitle,
          message: l10n.communityModerationLoadFailedMessage,
          action: FilledButton(
            onPressed: () => _loadQueue(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: Text(l10n.feedRetryAction),
          ),
        ),
      );
    }

    if (_stories.isEmpty) {
      return _ModerationStateList(
        child: _ModerationMessage(
          icon: Icons.fact_check_outlined,
          title: l10n.communityModerationEmptyTitle,
          message: l10n.communityModerationEmptyMessage,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          itemCount: _stories.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _stories.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              );
            }
            final story = _stories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModerationPostCard(
                post: story,
                isReviewing: _reviewingPostIds.contains(story.id),
                onApprove: () => _approvePost(story),
                onReject: () => _rejectPost(story),
                onHistory: () => _showDecisionHistory(story),
              ),
            );
          },
        );
      },
    );
  }
}

class _ModerationPostCard extends StatelessWidget {
  const _ModerationPostCard({
    required this.post,
    required this.isReviewing,
    required this.onApprove,
    required this.onReject,
    required this.onHistory,
  });

  final PostVm post;
  final bool isReviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: post.moderationStatus),
                    _StatusPill(label: post.author.preferredName),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      key: ValueKey('approve-${post.id}'),
                      onPressed: isReviewing ? null : onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.background,
                      ),
                      icon: isReviewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(l10n.communityModerationApproveAction),
                    ),
                    OutlinedButton.icon(
                      key: ValueKey('reject-${post.id}'),
                      onPressed: isReviewing ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(color: AppColors.destructive),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(l10n.communityModerationRejectAction),
                    ),
                    TextButton.icon(
                      key: ValueKey('history-${post.id}'),
                      onPressed: onHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: Text(l10n.communityModerationHistoryAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecisionHistoryTile extends StatelessWidget {
  const _DecisionHistoryTile({required this.decision});

  final PostModerationDecisionVm decision;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reason = decision.reason.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              decision.decision,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${decision.previousStatus} -> ${decision.nextStatus}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ModerationStateList extends StatelessWidget {
  const _ModerationStateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            48,
            horizontalPadding,
            32,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModerationMessage extends StatelessWidget {
  const _ModerationMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 34),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

double _horizontalPadding(double width) {
  if (width >= 840) {
    return 32;
  }
  if (width >= 600) {
    return 24;
  }
  return 16;
}
