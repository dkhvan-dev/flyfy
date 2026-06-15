import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/feed_api.dart';
import '../models/feed_block_vm.dart';
import '../widgets/community_list_item.dart';

class CommunityDiscoveryScreen extends StatefulWidget {
  const CommunityDiscoveryScreen({
    super.key,
    this.feedApi,
    this.onCommunityOpen,
  });

  final FeedApi? feedApi;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;

  @override
  State<CommunityDiscoveryScreen> createState() =>
      _CommunityDiscoveryScreenState();
}

class _CommunityDiscoveryScreenState extends State<CommunityDiscoveryScreen> {
  static const _pageLimit = 20;

  late final FeedApi _feedApi = widget.feedApi ?? FeedApi();
  late final ScrollController _scrollController;

  List<FeedCommunityVm> _communities = const [];
  Set<String> _updatingCommunityIds = const {};
  Object? _error;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_maybeLoadMore);
    _loadCommunities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities({
    bool showLoading = true,
    bool append = false,
  }) async {
    if (append && (_isLoading || _isLoadingMore || !_hasMore)) {
      return;
    }

    final generation = ++_requestGeneration;
    final offset = append ? _communities.length : 0;

    if (append && mounted) {
      setState(() => _isLoadingMore = true);
    } else if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _error = null;
        _hasMore = false;
        _communities = const [];
      });
    }

    try {
      final page = await _feedApi.listCommunities(
        limit: _pageLimit,
        offset: offset,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _communities = append
            ? _mergeCommunities(_communities, page.items)
            : page.items;
        _hasMore = page.hasMore;
        _error = null;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        if (!append) {
          _error = error;
        }
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
    _loadCommunities(showLoading: false, append: true);
  }

  Future<void> _toggleCommunityFollow(FeedCommunityVm community) async {
    final communityId = community.id.trim();
    if (communityId.isEmpty || _updatingCommunityIds.contains(communityId)) {
      return;
    }

    setState(() {
      _updatingCommunityIds = {..._updatingCommunityIds, communityId};
    });

    try {
      final updatedCommunity = community.followedByViewer
          ? await _feedApi.unfollowCommunity(communityId)
          : await _feedApi.followCommunity(communityId);
      if (!mounted) {
        return;
      }
      setState(() {
        _communities = [
          for (final item in _communities)
            item.id == updatedCommunity.id ? updatedCommunity : item,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.feedCommunityActionFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCommunityIds = {
            for (final id in _updatingCommunityIds)
              if (id != communityId) id,
          };
        });
      }
    }
  }

  void _openCommunity(FeedCommunityVm community) {
    final override = widget.onCommunityOpen;
    if (override != null) {
      override(community);
      return;
    }

    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }
    context.push(
      '/communities/${Uri.encodeComponent(communityId)}',
      extra: community,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          l10n.communityDiscoveryTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => _loadCommunities(showLoading: false),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _communities.isEmpty) {
      return const _CommunityDiscoveryStateList(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null && _communities.isEmpty) {
      return _CommunityDiscoveryStateList(
        child: _CommunityDiscoveryMessage(
          icon: Icons.wifi_off_rounded,
          title: l10n.communityDiscoveryLoadFailedTitle,
          message: l10n.communityDiscoveryLoadFailedMessage,
          action: FilledButton(
            onPressed: () => _loadCommunities(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: Text(l10n.feedRetryAction),
          ),
        ),
      );
    }

    if (_communities.isEmpty) {
      return _CommunityDiscoveryStateList(
        child: _CommunityDiscoveryMessage(
          icon: Icons.groups_2_outlined,
          title: l10n.communityDiscoveryEmptyTitle,
          message: l10n.communityDiscoveryEmptyMessage,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);
        return ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          itemCount: _communities.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
            ),
          ),
          itemBuilder: (context, index) {
            if (index >= _communities.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              );
            }

            final community = _communities[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: CommunityListItem(
                  community: community,
                  isUpdating: _updatingCommunityIds.contains(community.id),
                  openKeyPrefix: 'community-discovery-open',
                  onToggle: _toggleCommunityFollow,
                  onOpen: _openCommunity,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CommunityDiscoveryStateList extends StatelessWidget {
  const _CommunityDiscoveryStateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}

class _CommunityDiscoveryMessage extends StatelessWidget {
  const _CommunityDiscoveryMessage({
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

List<FeedCommunityVm> _mergeCommunities(
  List<FeedCommunityVm> existing,
  List<FeedCommunityVm> incoming,
) {
  if (existing.isEmpty) {
    return List<FeedCommunityVm>.unmodifiable(incoming);
  }
  if (incoming.isEmpty) {
    return List<FeedCommunityVm>.unmodifiable(existing);
  }

  final seen = <String>{
    for (final community in existing)
      if (community.id.trim().isNotEmpty) community.id,
  };
  final merged = <FeedCommunityVm>[...existing];
  for (final community in incoming) {
    if (community.id.trim().isNotEmpty && !seen.add(community.id)) {
      continue;
    }
    merged.add(community);
  }
  return List<FeedCommunityVm>.unmodifiable(merged);
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
