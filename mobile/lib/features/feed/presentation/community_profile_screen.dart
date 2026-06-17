import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/file_api.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/network/post_api.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_localized_location_text.dart';
import '../../stories/editor/presentation/post_create_preflight.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/models/post_profile_contract.dart';
import '../../trust/data/trust_moderation_actions_api.dart';
import '../../trust/widgets/trust_status_banner.dart';
import '../data/feed_api.dart';
import '../models/feed_block_vm.dart';
import '../widgets/community_display_helpers.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/quick_post_thread_card.dart';

class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({
    super.key,
    required this.communityId,
    this.initialCommunity,
    this.feedApi,
    this.postApi,
    this.trustActionsApi,
    this.initialPostId,
    this.onCreatePost,
    this.onStoryOpen,
    this.onModerationOpen,
    this.onMembersOpen,
    this.analyticsNow,
  });

  final String communityId;
  final FeedCommunityVm? initialCommunity;
  final FeedApi? feedApi;
  final PostApi? postApi;
  final TrustModerationActionsApi? trustActionsApi;
  final String? initialPostId;
  final ValueChanged<FeedCommunityVm>? onCreatePost;
  final ValueChanged<PostVm>? onStoryOpen;
  final ValueChanged<FeedCommunityVm>? onModerationOpen;
  final ValueChanged<FeedCommunityVm>? onMembersOpen;
  final DateTime Function()? analyticsNow;

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  static const _storiesPageLimit = 10;

  late final FeedApi _feedApi = widget.feedApi ?? FeedApi();
  late final PostApi _postApi = widget.postApi ?? PostApi();
  late final TrustModerationActionsApi _trustActionsApi =
      widget.trustActionsApi ?? GatewayTrustModerationActionsApi();
  late final ScrollController _scrollController;

  FeedCommunityVm? _community;
  List<PostVm> _stories = const [];
  Object? _error;
  Object? _storiesError;
  bool _isLoading = true;
  bool _isLoadingStories = true;
  bool _isLoadingMoreStories = false;
  bool _hasMoreStories = false;
  bool _isUpdatingFollow = false;
  int _storiesRequestGeneration = 0;
  int _publicStoriesLoadedCount = 0;
  String? _pendingScrollPostId;
  final Map<String, GlobalKey> _postItemKeys = <String, GlobalKey>{};
  final Set<String> _sentPostImpressionKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_maybeLoadMoreStories);
    _community = widget.initialCommunity;
    _pendingScrollPostId = _trimmedOrNull(widget.initialPostId);
    _isLoading = widget.initialCommunity == null;
    _loadCommunity(showLoading: widget.initialCommunity == null);
    _loadStories(showLoading: true);
  }

  @override
  void didUpdateWidget(covariant CommunityProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPostId != widget.initialPostId) {
      _pendingScrollPostId = _trimmedOrNull(widget.initialPostId);
      _scheduleScrollToPendingPost();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunity({bool showLoading = true}) async {
    final communityId = widget.communityId.trim();
    if (communityId.isEmpty) {
      return;
    }

    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final community = await _feedApi.getCommunity(communityId);
      if (!mounted) {
        return;
      }
      setState(() {
        _community = community;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStories({
    bool showLoading = true,
    bool append = false,
  }) async {
    if (append &&
        (_isLoadingStories || _isLoadingMoreStories || !_hasMoreStories)) {
      return;
    }

    final communityId = widget.communityId.trim();
    if (communityId.isEmpty) {
      return;
    }

    final generation = ++_storiesRequestGeneration;
    final offset = append ? _publicStoriesLoadedCount : 0;

    if (append && mounted) {
      setState(() {
        _isLoadingMoreStories = true;
      });
    } else if (showLoading && mounted) {
      setState(() {
        _isLoadingStories = true;
        _isLoadingMoreStories = false;
        _hasMoreStories = false;
        _publicStoriesLoadedCount = 0;
        _storiesError = null;
        _stories = const [];
      });
    }

    try {
      final page = await _postApi.listPostsPage(
        communityId: communityId,
        sort: 'newest',
        limit: _storiesPageLimit,
        offset: offset,
      );
      final minePage = append
          ? null
          : await _postApi.listMyPostsPage(
              communityId: communityId,
              status: 'PUBLISHED',
              sort: 'newest',
              limit: _storiesPageLimit,
              offset: 0,
            );
      if (!mounted || generation != _storiesRequestGeneration) {
        return;
      }
      final nextItems = append
          ? [..._stories, ...page.items]
          : _mergeCommunityPosts(
              page.items,
              minePage?.items ?? const <PostVm>[],
            );
      setState(() {
        _publicStoriesLoadedCount = append
            ? _publicStoriesLoadedCount + page.items.length
            : page.items.length;
        _stories = nextItems;
        _hasMoreStories = page.hasMore;
        _storiesError = null;
        _isLoadingStories = false;
        _isLoadingMoreStories = false;
      });
      _trackLoadedPostImpressions(nextItems);
      _handleLoadedStoriesForPendingPost();
    } catch (error) {
      if (!mounted || generation != _storiesRequestGeneration) {
        return;
      }
      setState(() {
        if (!append) {
          _storiesError = error;
        }
        _isLoadingStories = false;
        _isLoadingMoreStories = false;
      });
    }
  }

  GlobalKey _postKeyFor(PostVm post) {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return GlobalKey();
    }
    return _postItemKeys.putIfAbsent(
      postId,
      () => GlobalKey(debugLabel: 'community-post-$postId'),
    );
  }

  void _scheduleScrollToPendingPost() {
    final postId = _trimmedOrNull(_pendingScrollPostId);
    if (postId == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = _postItemKeys[postId]?.currentContext;
      if (targetContext == null) {
        return;
      }
      _pendingScrollPostId = null;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  void _handleLoadedStoriesForPendingPost() {
    _scheduleScrollToPendingPost();
    final postId = _trimmedOrNull(_pendingScrollPostId);
    if (postId == null) {
      return;
    }
    final isLoaded = _stories.any((post) => post.id.trim() == postId);
    if (isLoaded || !_hasMoreStories || _isLoadingMoreStories) {
      return;
    }
    unawaited(_loadStories(showLoading: false, append: true));
  }

  void _maybeLoadMoreStories() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 640) {
      return;
    }
    _loadStories(showLoading: false, append: true);
  }

  Future<void> _toggleFollow() async {
    final community = _community;
    if (community == null || _isUpdatingFollow) {
      return;
    }
    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }

    if (community.followedByViewer) {
      final confirmed = await _confirmUnfollowCommunity();
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _isUpdatingFollow = true);
    try {
      final wasFollowed = community.followedByViewer;
      final updated = community.followedByViewer
          ? await _feedApi.unfollowCommunity(communityId)
          : await _feedApi.followCommunity(communityId);
      if (!mounted) {
        return;
      }
      setState(() {
        _community = updated;
      });
      if (!wasFollowed && updated.followedByViewer) {
        _trackCommunitySubscribe(updated);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.feedCommunityActionFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFollow = false);
      }
    }
  }

  Future<bool?> _confirmUnfollowCommunity() {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _communityAmberPanelColor(),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.28)),
          ),
          title: Text(l10n.communityProfileUnfollowConfirmTitle),
          content: Text(l10n.profileUnfollowDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(l10n.profileUnfollowConfirm),
            ),
          ],
        );
      },
    );
  }

  void _trackCommunitySubscribe(FeedCommunityVm community) {
    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }
    final topic = (community.topic ?? '').trim();
    unawaited(
      _sendFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: FeedEventTypes.subscribe,
          surface: 'content',
          tab: 'for_you',
          blockId: 'community:$communityId:profile',
          blockType: 'community_card',
          communityId: communityId,
          rank: 0,
          occurredAt: _analyticsNow(),
          metadata: {
            'source': 'community_profile',
            'entityType': 'community',
            'entityId': communityId,
            if (topic.isNotEmpty) 'topic': topic,
            if ((community.countryCode ?? '').trim().isNotEmpty)
              'countryCode': community.countryCode!.trim(),
            if ((community.cityId ?? '').trim().isNotEmpty)
              'cityId': community.cityId!.trim(),
          },
        ),
      ]),
    );
  }

  void _trackCommunityFeedback(
    FeedCommunityVm community, {
    required String eventType,
    required String source,
    required String feedbackType,
  }) {
    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }
    final topic = (community.topic ?? '').trim();
    unawaited(
      _sendFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: eventType,
          surface: 'content',
          tab: 'for_you',
          blockId: 'community:$communityId:profile',
          blockType: 'community_card',
          communityId: communityId,
          rank: 0,
          occurredAt: _analyticsNow(),
          metadata: {
            'source': source,
            'entityType': 'community',
            'entityId': communityId,
            'feedbackType': feedbackType,
            if (topic.isNotEmpty) 'topic': topic,
            if ((community.countryCode ?? '').trim().isNotEmpty)
              'countryCode': community.countryCode!.trim(),
            if ((community.cityId ?? '').trim().isNotEmpty)
              'cityId': community.cityId!.trim(),
          },
        ),
      ]),
    );
  }

  void _trackCommunityReport(FeedCommunityVm community) {
    _trackCommunityFeedback(
      community,
      eventType: FeedEventTypes.report,
      source: 'community_profile',
      feedbackType: FeedEventTypes.report,
    );
  }

  void _trackCommunityMute(FeedCommunityVm community) {
    _trackCommunityFeedback(
      community,
      eventType: FeedEventTypes.hide,
      source: 'community_mute',
      feedbackType: FeedEventTypes.hide,
    );
  }

  Future<void> _openCreatePost() async {
    final community = _community;
    if (community == null) {
      return;
    }
    final resolvedPostProfileKey =
        _resolvedPostProfileKey(community) ?? community.defaultPostProfileKey;

    final override = widget.onCreatePost;
    if (override != null) {
      override(
        community.copyWith(defaultPostProfileKey: resolvedPostProfileKey),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final communityTitle = feedCommunityDisplayTitle(community, l10n);
    final uri = Uri(
      path: '/posts/create',
      queryParameters: {
        'communityId': community.id,
        'postProfileKey': resolvedPostProfileKey,
        if (community.postProfileKeys.isNotEmpty)
          'postProfileKeys': community.postProfileKeys.join(','),
        if (communityTitle.isNotEmpty) 'communityTitle': communityTitle,
        if ((community.countryCode ?? '').trim().isNotEmpty)
          'communityCountryCode': community.countryCode!.trim(),
        if ((community.cityId ?? '').trim().isNotEmpty)
          'communityCityId': community.cityId!.trim(),
        if ((community.cityName ?? '').trim().isNotEmpty)
          'communityCityName': community.cityName!.trim(),
      },
    );
    final allowed = await ensurePostCreateAllowed(
      context,
      postApi: _postApi,
      loginFrom: uri.toString(),
    );
    if (!allowed || !mounted) {
      return;
    }

    final createdPost = await context.push<PostVm>(uri.toString());
    if (!mounted) {
      return;
    }
    if (createdPost != null && _belongsToCommunity(createdPost, community.id)) {
      setState(() {
        _stories = _upsertCommunityPost(_stories, createdPost);
      });
    }
    await Future.wait([
      _loadCommunity(showLoading: false),
      _loadStories(showLoading: false),
    ]);
    if (!mounted) {
      return;
    }
    if (createdPost != null && _belongsToCommunity(createdPost, community.id)) {
      setState(() {
        _stories = _upsertCommunityPost(_stories, createdPost);
      });
    }
  }

  void _openStory(PostVm story) {
    final openedAt = _analyticsNow();
    _trackCommunityPostEvent(story, FeedEventTypes.click);

    final override = widget.onStoryOpen;
    if (override != null) {
      override(story);
      return;
    }

    final slug = story.slug.trim().isNotEmpty ? story.slug : story.id;
    if (slug.trim().isEmpty) {
      return;
    }
    unawaited(
      context.push<void>('/posts/${Uri.encodeComponent(slug)}').whenComplete(
        () {
          if (mounted) {
            _trackCommunityPostDwell(story, openedAt);
          }
        },
      ),
    );
  }

  void _trackLoadedPostImpressions(List<PostVm> posts) {
    final communityId = widget.communityId.trim();
    if (communityId.isEmpty || posts.isEmpty) {
      return;
    }

    final events = <FeedEventRequest>[];
    for (var index = 0; index < posts.length; index++) {
      final post = posts[index];
      final postId = post.id.trim();
      if (postId.isEmpty) {
        continue;
      }
      final key = '$communityId:$postId';
      if (!_sentPostImpressionKeys.add(key)) {
        continue;
      }
      events.add(
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: FeedEventTypes.impression,
          surface: 'content',
          tab: 'for_you',
          blockId: 'community:$communityId:posts',
          blockType: 'post_card',
          postId: postId,
          communityId: communityId,
          rank: index,
          occurredAt: _analyticsNow(),
          metadata: {
            'source': 'community_profile',
            if ((post.postProfileKey ?? '').trim().isNotEmpty)
              'postProfileKey': post.postProfileKey!.trim(),
          },
        ),
      );
    }
    if (events.isEmpty) {
      return;
    }
    unawaited(_sendFeedEvents(events));
  }

  Future<void> _sendFeedEvents(List<FeedEventRequest> events) async {
    try {
      await _feedApi.trackFeedEvents(events);
    } catch (_) {
      // Analytics should never block community browsing.
    }
  }

  void _trackQuickPostEngagement(PostVm post, String eventType) {
    _trackCommunityPostEvent(
      post,
      eventType,
      metadata: {'engagementType': eventType.trim()},
    );
  }

  void _trackCommunityPostDwell(PostVm post, DateTime openedAt) {
    final dwellMs = _analyticsNow().difference(openedAt).inMilliseconds;
    if (dwellMs < 1000) {
      return;
    }
    _trackCommunityPostEvent(
      post,
      FeedEventTypes.dwell,
      metadata: {'dwellMs': dwellMs.clamp(1000, 30 * 60 * 1000)},
    );
  }

  void _trackCommunityPostEvent(
    PostVm post,
    String eventType, {
    Map<String, Object?> metadata = const {},
  }) {
    final communityId = widget.communityId.trim();
    final postId = post.id.trim();
    final normalizedEventType = eventType.trim();
    if (communityId.isEmpty || postId.isEmpty || normalizedEventType.isEmpty) {
      return;
    }
    final rank = max(
      0,
      _stories.indexWhere((item) => item.id.trim() == postId),
    );
    unawaited(
      _sendFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: normalizedEventType,
          surface: 'content',
          tab: 'for_you',
          blockId: 'community:$communityId:posts',
          blockType: 'post_card',
          postId: postId,
          communityId: communityId,
          rank: rank,
          occurredAt: _analyticsNow(),
          metadata: {
            'source': 'community_profile',
            'action': normalizedEventType,
            ...metadata,
            if ((post.postProfileKey ?? '').trim().isNotEmpty)
              'postProfileKey': post.postProfileKey!.trim(),
          },
        ),
      ]),
    );
  }

  DateTime _analyticsNow() => (widget.analyticsNow ?? DateTime.now)().toUtc();

  Future<void> _openEditPost(PostVm post) async {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    final uri = Uri(
      path: '/posts/${Uri.encodeComponent(postId)}/edit',
      queryParameters: const {'returnOnSave': '1'},
    );
    final updatedPost = await context.push<PostVm>(uri.toString(), extra: post);
    if (!mounted || updatedPost == null) {
      return;
    }
    setState(() {
      _stories = _upsertCommunityPost(_stories, updatedPost);
    });
  }

  void _openModeration() {
    final community = _community;
    if (community == null) {
      return;
    }

    final override = widget.onModerationOpen;
    if (override != null) {
      override(community);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final title = feedCommunityDisplayTitle(community, l10n);
    final uri = Uri(
      path: '/communities/${Uri.encodeComponent(community.id)}/moderation',
      queryParameters: title.isEmpty ? null : {'title': title},
    );
    context.push(uri.toString());
  }

  void _openMembers() {
    final community = _community;
    if (community == null) {
      return;
    }

    final override = widget.onMembersOpen;
    if (override != null) {
      override(community);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final title = feedCommunityDisplayTitle(community, l10n);
    final uri = Uri(
      path: '/communities/${Uri.encodeComponent(community.id)}/members',
      queryParameters: title.isEmpty ? null : {'title': title},
    );
    context.push(uri.toString());
  }

  Future<void> _reportCommunity() async {
    final community = _community;
    if (community == null) {
      return;
    }
    final submittedMessage = AppLocalizations.of(
      context,
    )!.communityTrustReportSubmitted;

    try {
      await _trustActionsApi.reportContent(
        TrustReportContentRequest(
          target: _communityTrustTarget(community),
          reason: TrustReportReason.other,
          details: 'Community profile report',
        ),
      );
      _trackCommunityReport(community);
      if (!mounted) {
        return;
      }
      _showTrustSnackBar(submittedMessage);
    } catch (error) {
      await _showTrustActionError(error);
    }
  }

  Future<void> _muteCommunity() async {
    final community = _community;
    if (community == null) {
      return;
    }

    try {
      await _trustActionsApi.muteTarget(
        TrustMuteTargetRequest(target: _communityTrustTarget(community)),
      );
      _trackCommunityMute(community);
      if (!mounted) {
        return;
      }
      setState(() => _community = community.copyWith(mutedByViewer: true));
      _showTrustSnackBar(
        AppLocalizations.of(context)!.communityTrustMutedSubmitted,
      );
    } catch (error) {
      await _showTrustActionError(error);
    }
  }

  Future<void> _unmuteCommunity() async {
    final community = _community;
    if (community == null) {
      return;
    }

    try {
      await _trustActionsApi.unmuteTarget(
        TrustMuteTargetRequest(target: _communityTrustTarget(community)),
      );
      if (!mounted) {
        return;
      }
      setState(() => _community = community.copyWith(mutedByViewer: false));
      _showTrustSnackBar(
        AppLocalizations.of(context)!.communityTrustUnmutedSubmitted,
      );
    } catch (error) {
      await _showTrustActionError(error);
    }
  }

  Future<void> _appealCommunityRestriction() async {
    final community = _community;
    final restrictionId = (community?.viewerRestrictionId ?? '').trim();
    if (community == null || restrictionId.isEmpty) {
      return;
    }

    try {
      await _trustActionsApi.appealRestriction(
        TrustRestrictionAppealRequest(
          restrictionId: restrictionId,
          message: AppLocalizations.of(context)!.communityTrustAppealMessage,
          idempotencyKey: 'community:${community.id}:$restrictionId:appeal',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(
        () => _community = community.copyWith(
          viewerTrustStatus: 'APPEAL_PENDING',
        ),
      );
      _showTrustSnackBar(
        AppLocalizations.of(context)!.communityTrustAppealSubmitted,
      );
    } catch (error) {
      await _showTrustActionError(error);
    }
  }

  Future<void> _showTrustActionError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) {
      return Future<void>.value();
    }
    return showErrorDialog(
      context,
      title: l10n.error,
      message: error is UnsupportedError
          ? l10n.communityTrustActionUnavailable
          : l10n.communityTrustActionFailed,
    );
  }

  void _showTrustSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await Future.wait([
              _loadCommunity(showLoading: false),
              _loadStories(showLoading: false),
            ]);
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final community = _community;
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticatedViewer = _isAuthenticatedViewer(context);

    if (_isLoading && community == null) {
      return const _CommunityProfileStateList(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null && community == null) {
      return _CommunityProfileStateList(
        child: _CommunityProfileMessage(
          icon: Icons.wifi_off_rounded,
          title: l10n.communityProfileLoadFailedTitle,
          message: l10n.communityProfileLoadFailedMessage,
          action: FilledButton(
            onPressed: () => _loadCommunity(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: Text(l10n.feedRetryAction),
          ),
        ),
      );
    }

    if (community == null) {
      return const _CommunityProfileStateList(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);
        final trustBanners = _communityTrustBanners(
          context,
          community,
          onAppeal: _appealCommunityRestriction,
        );

        return ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _CommunityProfileHeader(
              community: community,
              isUpdatingFollow: _isUpdatingFollow,
              canCreatePost: _canCreatePost(community),
              onBack: _closeProfile,
              onToggleFollow: _toggleFollow,
              onCreatePost: () => unawaited(_openCreatePost()),
              onModerationOpen: community.viewerCanModerate
                  ? _openModeration
                  : null,
              onMembersOpen: community.viewerCanModerate ? _openMembers : null,
              actionsTooltip: l10n.communityProfileActionsTooltip,
              canUseViewerActions: isAuthenticatedViewer,
              onReport: _reportCommunity,
              onMute: _muteCommunity,
              onUnmute: _unmuteCommunity,
            ),
            if (trustBanners.isNotEmpty)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: trustBanners,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                trustBanners.isEmpty ? 16 : 12,
                0,
                0,
              ),
              child: KeyedSubtree(
                key: const ValueKey('community-profile-posts-section'),
                child: _CommunityPostsSection(
                  horizontalPadding: horizontalPadding,
                  stories: _stories,
                  postApi: _postApi,
                  isLoading: _isLoadingStories,
                  isLoadingMore: _isLoadingMoreStories,
                  error: _storiesError,
                  onRetry: () => _loadStories(),
                  onStoryTap: _openStory,
                  onQuickPostEdit: _openEditPost,
                  onQuickPostEngagement: _trackQuickPostEngagement,
                  canUsePostActions: isAuthenticatedViewer,
                  postKeyFor: _postKeyFor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _closeProfile() {
    Navigator.of(context).maybePop();
  }
}

bool _belongsToCommunity(PostVm post, String communityId) {
  final normalizedCommunityId = communityId.trim();
  if (normalizedCommunityId.isEmpty) {
    return false;
  }
  final postCommunityId = (post.communityId ?? '').trim();
  return postCommunityId.isEmpty || postCommunityId == normalizedCommunityId;
}

String? _resolvedPostProfileKey(
  FeedCommunityVm? community, {
  String? preferred,
}) {
  if (community == null) {
    return null;
  }
  final keys = community.postProfileKeys;
  if (keys.isEmpty) {
    return community.defaultPostProfileKey;
  }
  final preferredKey = PostProfileContract.normalize(preferred);
  if (preferredKey != null && keys.contains(preferredKey)) {
    return preferredKey;
  }
  final defaultKey = PostProfileContract.normalize(
    community.defaultPostProfileKey,
  );
  if (defaultKey != null && keys.contains(defaultKey)) {
    return defaultKey;
  }
  return keys.first;
}

List<PostVm> _upsertCommunityPost(List<PostVm> posts, PostVm post) {
  final postId = post.id.trim();
  final postSlug = post.slug.trim();
  return [
    post,
    for (final item in posts)
      if (!_samePostIdentity(item, postId: postId, postSlug: postSlug)) item,
  ];
}

List<PostVm> _mergeCommunityPosts(List<PostVm> publicPosts, List<PostVm> mine) {
  final byKey = <String, PostVm>{};
  void add(PostVm post) {
    final id = post.id.trim();
    final slug = post.slug.trim();
    final key = id.isNotEmpty ? 'id:$id' : 'slug:$slug';
    if (key == 'slug:') {
      return;
    }
    byKey[key] = post;
  }

  for (final post in publicPosts) {
    add(post);
  }
  for (final post in mine) {
    add(post);
  }

  final merged = byKey.values.toList(growable: false);
  merged.sort((a, b) => b.sortDate.compareTo(a.sortDate));
  return merged;
}

bool _samePostIdentity(
  PostVm item, {
  required String postId,
  required String postSlug,
}) {
  final itemId = item.id.trim();
  final itemSlug = item.slug.trim();
  return (postId.isNotEmpty && itemId == postId) ||
      (postSlug.isNotEmpty && itemSlug == postSlug);
}

class _CommunityPostsSection extends StatelessWidget {
  const _CommunityPostsSection({
    required this.horizontalPadding,
    required this.stories,
    required this.postApi,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.onRetry,
    required this.onStoryTap,
    required this.onQuickPostEdit,
    required this.onQuickPostEngagement,
    required this.canUsePostActions,
    required this.postKeyFor,
  });

  final double horizontalPadding;
  final List<PostVm> stories;
  final PostApi postApi;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final VoidCallback onRetry;
  final ValueChanged<PostVm> onStoryTap;
  final ValueChanged<PostVm> onQuickPostEdit;
  final QuickPostEngagementCallback onQuickPostEngagement;
  final bool canUsePostActions;
  final GlobalKey Function(PostVm post) postKeyFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            l10n.communityProfilePostsSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (error != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _CommunityProfileMessage(
              icon: Icons.wifi_off_rounded,
              title: l10n.communityProfilePostsLoadFailedTitle,
              message: l10n.communityProfileLoadFailedMessage,
              action: TextButton(
                onPressed: onRetry,
                child: Text(l10n.feedRetryAction),
              ),
            ),
          )
        else if (stories.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _CommunityProfileMessage(
              icon: Icons.article_outlined,
              title: l10n.communityProfileNoPostsTitle,
              message: l10n.communityProfileNoPostsMessage,
            ),
          )
        else
          ...stories.map(
            (story) => Padding(
              key: postKeyFor(story),
              padding: const EdgeInsets.only(bottom: 12),
              child: story.isQuickPost
                  ? QuickPostThreadCard(
                      post: story,
                      postApi: postApi,
                      canInteract: canUsePostActions,
                      onEdit: canUsePostActions ? onQuickPostEdit : null,
                      onEngagement: canUsePostActions
                          ? onQuickPostEngagement
                          : null,
                    )
                  : FeedPostCard(post: story, onOpen: onStoryTap),
            ),
          ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
      ],
    );
  }
}

class _CommunityProfileHeader extends StatelessWidget {
  const _CommunityProfileHeader({
    required this.community,
    required this.isUpdatingFollow,
    required this.canCreatePost,
    required this.onBack,
    required this.onToggleFollow,
    required this.onCreatePost,
    required this.actionsTooltip,
    required this.canUseViewerActions,
    required this.onReport,
    required this.onMute,
    required this.onUnmute,
    this.onModerationOpen,
    this.onMembersOpen,
  });

  final FeedCommunityVm community;
  final bool isUpdatingFollow;
  final bool canCreatePost;
  final VoidCallback onBack;
  final VoidCallback onToggleFollow;
  final VoidCallback onCreatePost;
  final String actionsTooltip;
  final bool canUseViewerActions;
  final VoidCallback onReport;
  final VoidCallback onMute;
  final VoidCallback onUnmute;
  final VoidCallback? onModerationOpen;
  final VoidCallback? onMembersOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = feedCommunityDisplayDescription(community, l10n);
    final topic = (community.topic ?? '').trim();
    final displayTitle = feedCommunityDisplayTitle(community, l10n);
    final locationLabel = feedCommunityLocationLabel(community);
    final topicLabel = topic.isEmpty
        ? ''
        : feedCommunityTopicLabel(topic, l10n);
    final width = MediaQuery.sizeOf(context).width;
    final coverHeight = (width * 0.62).clamp(230.0, 340.0);
    const avatarRadius = 52.0;
    const panelOverlap = 34.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CommunityCover(community: community, height: coverHeight),
        Positioned(
          left: 16,
          right: 16,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: _CommunityHeaderControls(
              community: community,
              tooltip: actionsTooltip,
              onBack: onBack,
              showActions: canUseViewerActions,
              onReport: onReport,
              onMute: onMute,
              onUnmute: onUnmute,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: coverHeight - panelOverlap),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: DecoratedBox(
                key: const ValueKey('community-profile-info-panel'),
                decoration: BoxDecoration(
                  color: _communityAmberPanelColor(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                    bottom: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    avatarRadius + 18,
                    18,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: AppColors.accent.withValues(alpha: 0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AppLocalizedLocationText(
                                countryCode: community.countryCode,
                                cityId: community.cityId,
                                cityName: community.cityName,
                                fallbackText: locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                      if (topic.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _CommunityBadge(label: topicLabel),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: [
                          _CommunityStat(
                            icon: Icons.group_outlined,
                            label: l10n.feedCommunityMembersLabel(
                              _formatCompactCount(community.membersCount),
                            ),
                          ),
                          _CommunityStat(
                            icon: Icons.campaign_outlined,
                            label: l10n.communityProfilePostsLabel(
                              _formatCompactCount(community.postCount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isUpdatingFollow ? null : onToggleFollow,
                          style: FilledButton.styleFrom(
                            backgroundColor: community.followedByViewer
                                ? AppColors.surfaceLight
                                : AppColors.accent,
                            foregroundColor: AppColors.textPrimary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: isUpdatingFollow
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  community.followedByViewer
                                      ? Icons.check_rounded
                                      : Icons.add_circle_outline_rounded,
                                ),
                          label: Text(
                            community.followedByViewer
                                ? l10n.feedCommunityJoinedAction
                                : l10n.feedJoinCommunityAction,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (canCreatePost ||
                          onMembersOpen != null ||
                          onModerationOpen != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (canCreatePost)
                              OutlinedButton.icon(
                                onPressed: onCreatePost,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side: const BorderSide(
                                    color: AppColors.accent,
                                  ),
                                ),
                                icon: const Icon(Icons.edit_note_rounded),
                                label: Text(
                                  l10n.communityProfileCreatePostAction,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (onMembersOpen != null)
                              OutlinedButton.icon(
                                onPressed: onMembersOpen,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                icon: const Icon(
                                  Icons.manage_accounts_outlined,
                                ),
                                label: Text(
                                  l10n.communityMembersAction,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (onModerationOpen != null)
                              OutlinedButton.icon(
                                onPressed: onModerationOpen,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentLight,
                                ),
                                icon: const Icon(Icons.shield_outlined),
                                label: Text(
                                  l10n.feedCommunityModerationAction,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (community.rules.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _CommunityRulesList(rules: community.rules),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: coverHeight - panelOverlap - avatarRadius,
          left: 18,
          right: 18,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 604),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CommunityAvatar(
                  community: community,
                  radius: avatarRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CommunityHeaderAction { mute, unmute, report }

class _CommunityHeaderControls extends StatelessWidget {
  const _CommunityHeaderControls({
    required this.community,
    required this.tooltip,
    required this.onBack,
    required this.showActions,
    required this.onReport,
    required this.onMute,
    required this.onUnmute,
  });

  final FeedCommunityVm community;
  final String tooltip;
  final VoidCallback onBack;
  final bool showActions;
  final VoidCallback onReport;
  final VoidCallback onMute;
  final VoidCallback onUnmute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CommunityHeaderRoundButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: onBack,
        ),
        const Spacer(),
        if (showActions)
          _CommunityHeaderActionsMenu(
            community: community,
            tooltip: tooltip,
            onReport: onReport,
            onMute: onMute,
            onUnmute: onUnmute,
          ),
      ],
    );
  }
}

bool _isAuthenticatedViewer(BuildContext context) {
  try {
    return context.watch<AuthProvider>().state == AuthState.authenticated;
  } on ProviderNotFoundException {
    return false;
  }
}

class _CommunityHeaderActionsMenu extends StatelessWidget {
  const _CommunityHeaderActionsMenu({
    required this.community,
    required this.tooltip,
    required this.onReport,
    required this.onMute,
    required this.onUnmute,
  });

  final FeedCommunityVm community;
  final String tooltip;
  final VoidCallback onReport;
  final VoidCallback onMute;
  final VoidCallback onUnmute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<_CommunityHeaderAction>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 10),
      color: _communityAmberMenuColor(),
      elevation: 18,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      onSelected: (action) {
        switch (action) {
          case _CommunityHeaderAction.mute:
            onMute();
          case _CommunityHeaderAction.unmute:
            onUnmute();
          case _CommunityHeaderAction.report:
            onReport();
        }
      },
      child: Material(
        color: AppColors.accent.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: const _CommunityHeaderRoundButtonShell(
          icon: Icons.more_horiz_rounded,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<_CommunityHeaderAction>(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          value: community.mutedByViewer
              ? _CommunityHeaderAction.unmute
              : _CommunityHeaderAction.mute,
          child: _CommunityHeaderMenuTile(
            icon: community.mutedByViewer
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            label: community.mutedByViewer
                ? l10n.communityTrustUnmuteAction
                : l10n.communityTrustMuteAction,
          ),
        ),
        PopupMenuItem<_CommunityHeaderAction>(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          value: _CommunityHeaderAction.report,
          child: _CommunityHeaderMenuTile(
            icon: Icons.flag_outlined,
            label: l10n.communityTrustReportAction,
            isDestructive: true,
          ),
        ),
      ],
    );
  }
}

class _CommunityHeaderMenuTile extends StatelessWidget {
  const _CommunityHeaderMenuTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive ? AppColors.destructive : AppColors.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(icon, color: foreground, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeaderRoundButton extends StatelessWidget {
  const _CommunityHeaderRoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: _CommunityHeaderRoundButtonShell(icon: icon),
        ),
      ),
    );
  }
}

class _CommunityHeaderRoundButtonShell extends StatelessWidget {
  const _CommunityHeaderRoundButtonShell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Icon(icon, color: AppColors.textPrimary, size: 24),
    );
  }
}

class _CommunityRulesList extends StatelessWidget {
  const _CommunityRulesList({required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityProfileRulesTitle,
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...rules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityCover extends StatelessWidget {
  const _CommunityCover({required this.community, required this.height});

  final FeedCommunityVm community;
  final double height;

  @override
  Widget build(BuildContext context) {
    final coverUrl = resolvePublicFileContentUrl(community.coverFileId ?? '');
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = feedCommunityDisplayTitle(community, l10n);

    return SizedBox(
      key: const ValueKey('community-profile-cover'),
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl == null)
            _CommunityCoverFallback(title: displayTitle)
          else
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _CommunityCoverFallback(title: displayTitle);
              },
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.46),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCoverFallback extends StatelessWidget {
  const _CommunityCoverFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final initial = _communityInitial(title);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.surface],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.22),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.community, required this.radius});

  final FeedCommunityVm community;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolvePublicFileContentUrl(community.avatarFileId ?? '');
    final l10n = AppLocalizations.of(context)!;
    final initial = _communityInitial(
      feedCommunityDisplayTitle(community, l10n),
    );

    return Container(
      key: const ValueKey('community-profile-avatar'),
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? _CommunityAvatarFallback(initial: initial)
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _CommunityAvatarFallback(initial: initial);
                },
              ),
      ),
    );
  }
}

class _CommunityAvatarFallback extends StatelessWidget {
  const _CommunityAvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CommunityStat extends StatelessWidget {
  const _CommunityStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityProfileStateList extends StatelessWidget {
  const _CommunityProfileStateList({required this.child});

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

class _CommunityProfileMessage extends StatelessWidget {
  const _CommunityProfileMessage({
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

TrustModerationTarget _communityTrustTarget(FeedCommunityVm community) {
  return TrustModerationTarget(
    entityType: TrustModerationEntityType.community,
    entityId: community.id,
    contextId: community.id,
  );
}

List<Widget> _communityTrustBanners(
  BuildContext context,
  FeedCommunityVm community, {
  required VoidCallback onAppeal,
}) {
  final l10n = AppLocalizations.of(context)!;
  final status = _normalizedTrustStatus(community.viewerTrustStatus);
  final hasRestriction = (community.viewerRestrictionId ?? '')
      .trim()
      .isNotEmpty;
  if (community.mutedByViewer) {
    return [
      TrustStatusBanner(
        kind: TrustStatusBannerKind.muted,
        title: l10n.communityTrustMutedTitle,
        message: l10n.communityTrustMutedMessage,
      ),
      const SizedBox(height: 12),
    ];
  }

  final banner = switch (status) {
    'MUTED' => TrustStatusBanner(
      kind: TrustStatusBannerKind.muted,
      title: l10n.communityTrustMutedTitle,
      message: l10n.communityTrustMutedMessage,
    ),
    'APPEAL_PENDING' => TrustStatusBanner(
      kind: TrustStatusBannerKind.pendingAppeal,
      title: l10n.communityTrustAppealPendingTitle,
      message: l10n.communityTrustAppealPendingMessage,
      actionLabel: hasRestriction ? l10n.communityTrustAppealAction : null,
      onAction: hasRestriction ? onAppeal : null,
    ),
    'APPEAL_REJECTED' => TrustStatusBanner(
      kind: TrustStatusBannerKind.rejected,
      title: l10n.communityTrustAppealRejectedTitle,
      message: l10n.communityTrustAppealRejectedMessage,
      actionLabel: hasRestriction ? l10n.communityTrustAppealAction : null,
      onAction: hasRestriction ? onAppeal : null,
    ),
    'BLOCKED' ||
    'POSTING_BLOCKED' ||
    'BANNED' ||
    'SUSPENDED' => TrustStatusBanner(
      kind: TrustStatusBannerKind.blocked,
      title: l10n.communityTrustBlockedTitle,
      message: l10n.communityTrustBlockedMessage,
      actionLabel: hasRestriction ? l10n.communityTrustAppealAction : null,
      onAction: hasRestriction ? onAppeal : null,
    ),
    _ => null,
  };

  if (banner == null) {
    return const [];
  }
  return [banner, const SizedBox(height: 12)];
}

bool _canCreatePost(FeedCommunityVm community) {
  if (!community.followedByViewer ||
      community.status != 'ACTIVE' ||
      _isCommunityPostingRestricted(community.viewerTrustStatus)) {
    return false;
  }

  final role = (community.viewerRole ?? '').trim().toUpperCase();
  final postingPolicy = community.postingPolicy.trim().toUpperCase();
  return switch (postingPolicy) {
    'OPEN_MEMBERS' || 'MEMBERS_AFTER_MODERATION' => true,
    'TRUSTED_MEMBERS' =>
      role == 'TRUSTED_MEMBER' || role == 'MODERATOR' || role == 'ADMIN',
    'ADMINS_ONLY' => role == 'ADMIN',
    _ => false,
  };
}

bool _isCommunityPostingRestricted(String status) {
  return switch (_normalizedTrustStatus(status)) {
    'MUTED' ||
    'APPEAL_PENDING' ||
    'APPEAL_REJECTED' ||
    'BLOCKED' ||
    'POSTING_BLOCKED' ||
    'BANNED' ||
    'SUSPENDED' => true,
    _ => false,
  };
}

String _normalizedTrustStatus(String status) {
  final normalized = status.trim().replaceAll('-', '_').toUpperCase();
  return normalized.isEmpty ? 'ACTIVE' : normalized;
}

String _communityInitial(String title) {
  final trimmed = title.trim();
  return trimmed.isEmpty ? 'F' : trimmed.characters.first.toUpperCase();
}

Color _communityAmberPanelColor() {
  return Color.alphaBlend(
    AppColors.accent.withValues(alpha: 0.14),
    AppColors.background,
  );
}

Color _communityAmberMenuColor() {
  return Color.alphaBlend(
    AppColors.accent.withValues(alpha: 0.20),
    AppColors.background,
  );
}

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return value.toString();
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(hexByte).join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
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
