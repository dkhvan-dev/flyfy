import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/file_api.dart';
import '../../../core/network/post_api.dart';
import '../../../core/ui/app_bottom_navigation_bars.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/home_location_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../shared/reference/app_location_label_resolver.dart';
import '../../stories/editor/presentation/post_create_preflight.dart';
import '../../profile/models/user_profile_vm.dart';
import '../../stories/models/post_vm.dart';
import '../../stories/models/story_vm.dart';
import '../../../screens/stories/story_tray_viewer_screen.dart';
import '../data/feed_api.dart';
import '../data/feed_subscriptions_api.dart';
import '../models/feed_block_vm.dart';
import '../widgets/community_discovery_sheet.dart';
import '../widgets/community_display_helpers.dart';
import '../widgets/feed_block_list.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/my_subscriptions_block.dart';

typedef FeedPostShareLauncher =
    Future<void> Function(PostVm post, String shareUrl);

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    super.key,
    this.feedApi,
    this.subscriptionsApi,
    this.postApi,
    this.onStoryOpen,
    this.onPostOpen,
    this.onCommunityOpen,
    this.onCommunityModerationOpen,
    this.locationLabelResolver,
    this.analyticsNow,
    this.postShareLauncher,
  });

  final FeedApi? feedApi;
  final FeedSubscriptionsApi? subscriptionsApi;
  final PostApi? postApi;
  final ValueChanged<StoryVm>? onStoryOpen;
  final ValueChanged<PostVm>? onPostOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityOpen;
  final ValueChanged<FeedCommunityVm>? onCommunityModerationOpen;
  final AppLocationLabelResolver? locationLabelResolver;
  final DateTime Function()? analyticsNow;
  final FeedPostShareLauncher? postShareLauncher;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['for_you', 'following'];

  late final FeedApi _feedApi = widget.feedApi ?? FeedApi();
  late final FeedSubscriptionsApi _subscriptionsApi =
      widget.subscriptionsApi ?? FeedSubscriptionsApi(feedApi: _feedApi);
  late final PostApi _postApi = widget.postApi ?? PostApi();
  late final TabController _tabController;
  late final ScrollController _scrollController;

  var _selectedTabIndex = 0;
  var _isLoading = true;
  var _isLoadingMore = false;
  var _requestGeneration = 0;
  Object? _error;
  Object? _loadMoreError;
  String? _nextCursor;
  List<FeedBlockVm> _items = const [];
  var _postSortMode = FeedPostSortMode.recommended;
  Set<String> _updatingCommunityIds = const {};
  final Set<String> _sentImpressionKeys = <String>{};
  Timer? _storyExpiryTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController = ScrollController()..addListener(_maybeLoadNextPage);
    _loadFeed();
  }

  @override
  void dispose() {
    _storyExpiryTimer?.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed({bool showLoading = true, bool append = false}) async {
    if (append && (_isLoadingMore || _isLoading || _nextCursor == null)) {
      return;
    }

    final generation = ++_requestGeneration;
    final tab = _tabs[_selectedTabIndex];
    final cursor = append ? _nextCursor : null;
    final location = _feedLocationContext();

    if (!append) {
      _sentImpressionKeys.clear();
    }

    if (append && mounted) {
      setState(() {
        _isLoadingMore = true;
        _loadMoreError = null;
      });
    } else if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _error = null;
        _loadMoreError = null;
        _nextCursor = null;
        _items = const [];
      });
    } else if (!append && mounted) {
      setState(() {
        _error = null;
        _loadMoreError = null;
        _nextCursor = null;
      });
    }

    try {
      final page = await _feedApi.getFeed(
        surface: 'home',
        tab: tab,
        cursor: cursor,
        countryCode: location?.countryCode,
        cityId: location?.cityId,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      final visibleItems = _withoutHiddenConversionBlocks(page.items);
      final pageItems = append
          ? _withoutAdditionalStoryTrays(visibleItems)
          : _withTopStoriesTray(visibleItems);
      final hydratedPageItems = !append && tab == 'following'
          ? await _withLoadedMySubscriptions(pageItems)
          : pageItems;
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      final rankedPageItems = append
          ? hydratedPageItems
          : _withSmartPostSections(
              hydratedPageItems,
              includeSystemPosts: tab != 'following',
            );
      final viewerUserId = _maybeSessionProfileForRead(context)?.userId;
      final displayPageItems = _shouldHideViewerOwnedPosts(tab)
          ? _withoutViewerOwnedPosts(rankedPageItems, viewerUserId)
          : rankedPageItems;
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        _items = append
            ? mergeFeedBlockPages(_items, displayPageItems)
            : displayPageItems;
        _nextCursor = _trimmedOrNull(page.nextCursor);
        _error = null;
        _loadMoreError = null;
        _isLoading = false;
        _isLoadingMore = false;
      });
      _scheduleStoryExpiryRefresh();
      _trackLoadedImpressions(displayPageItems, tab);
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }

      setState(() {
        if (append) {
          _loadMoreError = error;
        } else {
          _error = error;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (!append) {
        _storyExpiryTimer?.cancel();
      }
    }
  }

  void _scheduleStoryExpiryRefresh() {
    _storyExpiryTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? nextExpiry;
    for (final block in _items) {
      if (block.type != FeedBlockType.storiesTray) {
        continue;
      }
      for (final story in block.stories) {
        if (!story.isPublished || !story.expiresAt.isAfter(now)) {
          continue;
        }
        if (nextExpiry == null || story.expiresAt.isBefore(nextExpiry)) {
          nextExpiry = story.expiresAt;
        }
      }
    }
    if (nextExpiry == null) {
      return;
    }

    final expiryCutoff = nextExpiry;
    final delay =
        nextExpiry.difference(now) + const Duration(milliseconds: 100);
    _storyExpiryTimer = Timer(
      delay,
      () => _handleStoryExpiryTick(expiryCutoff),
    );
  }

  void _handleStoryExpiryTick(DateTime expiryCutoff) {
    if (!mounted) {
      return;
    }
    setState(() {
      _items = _dropExpiredStoriesFromStoryTrays(_items, expiryCutoff);
    });
    _scheduleStoryExpiryRefresh();
  }

  void _selectTab(int index) {
    if (index == _selectedTabIndex) {
      return;
    }

    setState(() => _selectedTabIndex = index);
    _loadFeed();
  }

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients || _loadMoreError != null) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter > 640) {
      return;
    }
    _loadFeed(showLoading: false, append: true);
  }

  HomeLocationPreference? _feedLocationContext() {
    try {
      return context.read<HomeLocationProvider>().effectiveLocation;
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _handleFeedNavTap() async {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) {
      unawaited(_loadFeed(showLoading: false));
    }
  }

  Future<void> _toggleCommunityFollow(FeedCommunityVm community) async {
    final communityId = community.id.trim();
    if (communityId.isEmpty || _updatingCommunityIds.contains(communityId)) {
      return;
    }
    final wasFollowed = community.followedByViewer;
    final communityBlock = _findCommunityBlock(communityId);

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
        _items = _replaceCommunity(_items, updatedCommunity);
      });
      if (!wasFollowed && updatedCommunity.followedByViewer) {
        _trackCommunitySubscribe(updatedCommunity, communityBlock);
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
        setState(() {
          _updatingCommunityIds = {
            for (final id in _updatingCommunityIds)
              if (id != communityId) id,
          };
        });
      }
    }
  }

  void _trackCommunitySubscribe(
    FeedCommunityVm community,
    (FeedBlockVm, String, int)? communityBlock,
  ) {
    final communityId = community.id.trim();
    if (communityId.isEmpty || communityBlock == null) {
      return;
    }
    final topic = (community.topic ?? '').trim();
    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.subscribe,
        tab: _tabs[_selectedTabIndex],
        block: communityBlock.$1,
        blockType: communityBlock.$2,
        communityId: communityId,
        rank: communityBlock.$3,
        metadata: {
          'entityType': 'community',
          'entityId': communityId,
          if (topic.isNotEmpty) 'topic': topic,
          if ((community.countryCode ?? '').trim().isNotEmpty)
            'countryCode': community.countryCode!.trim(),
          if ((community.cityId ?? '').trim().isNotEmpty)
            'cityId': community.cityId!.trim(),
        },
      ),
    ]);
  }

  void _openCommunityModeration(FeedCommunityVm community) {
    final override = widget.onCommunityModerationOpen;
    if (override != null) {
      override(community);
      return;
    }

    final communityId = community.id.trim();
    if (communityId.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final title = feedCommunityDisplayTitle(community, l10n);
    final uri = Uri(
      path: '/communities/${Uri.encodeComponent(communityId)}/moderation',
      queryParameters: title.isEmpty ? null : {'title': title},
    );
    context.push(uri.toString());
  }

  void _openCommunity(FeedCommunityVm community) {
    final communityId = community.id.trim();
    if (communityId.isNotEmpty) {
      _trackCommunityClick(community, communityId);
    }

    final override = widget.onCommunityOpen;
    if (override != null) {
      override(community);
      return;
    }

    if (communityId.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final title = feedCommunityDisplayTitle(community, l10n);
    final uri = Uri(
      path: '/communities/${Uri.encodeComponent(communityId)}',
      queryParameters: title.isEmpty ? null : {'title': title},
    );
    context.push(uri.toString(), extra: community);
  }

  void _trackCommunityClick(FeedCommunityVm community, String communityId) {
    final block = _findCommunityBlock(communityId);
    if (block == null) {
      return;
    }
    final topic = (community.topic ?? '').trim();
    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.click,
        tab: _tabs[_selectedTabIndex],
        block: block.$1,
        blockType: block.$2,
        communityId: communityId,
        rank: block.$3,
        metadata: {
          'entityType': 'community',
          'entityId': communityId,
          if (topic.isNotEmpty) 'topic': topic,
          if ((community.countryCode ?? '').trim().isNotEmpty)
            'countryCode': community.countryCode!.trim(),
          if ((community.cityId ?? '').trim().isNotEmpty)
            'cityId': community.cityId!.trim(),
        },
      ),
    ]);
  }

  Future<void> _openCommunityDiscoverySheet() async {
    final location = _feedLocationContext();
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: min(height * 0.86, 720),
          child: CommunityDiscoverySheet(
            feedApi: _feedApi,
            initialCountryCode: location?.countryCode,
            initialCityId: location?.cityId,
            initialCityName: location?.cityName,
            locationLabelResolver: widget.locationLabelResolver,
            onCommunityOpen: (community) {
              Navigator.of(sheetContext).maybePop();
              _openCommunity(community);
            },
            onCommunityUpdated: (community) {
              if (!mounted) {
                return;
              }
              setState(() {
                _items = _replaceCommunity(_items, community);
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _openMySubscriptionsSheet() async {
    final subscriptions = _currentSubscriptions();
    if (subscriptions.isEmpty) {
      return;
    }
    final location = _feedLocationContext();

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: min(height * 0.86, 720),
          child: MySubscriptionsSheet(
            subscriptions: subscriptions,
            feedApi: _feedApi,
            locationLabelResolver: widget.locationLabelResolver,
            currentCountryCode: location?.countryCode,
            currentCityId: location?.cityId,
            currentCityName: location?.cityName,
            onCommunityOpen: (community) {
              Navigator.of(sheetContext).maybePop();
              _openCommunity(community);
            },
            onPersonOpen: (person) {
              Navigator.of(sheetContext).maybePop();
              _openPerson(person);
            },
          ),
        );
      },
    );
  }

  Future<void> _openSystemPostsSheet(List<PostVm> posts) async {
    if (posts.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1B1208),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height;
        return SizedBox(
          height: min(height * 0.86, 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.feedSystemPostsSheetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).maybePop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => FeedPostCard(
                    post: posts[index],
                    onOpen: (post) {
                      Navigator.of(sheetContext).maybePop();
                      _openPost(post);
                    },
                    onLike: _toggleFeedPostLike,
                    onShare: _shareFeedPost,
                    onHide: _hideFeedPost,
                    onNotInterested: _markFeedPostNotInterested,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  FeedSubscriptionsVm _currentSubscriptions() {
    for (final block in _items) {
      if (block.type == FeedBlockType.mySubscriptions) {
        return FeedSubscriptionsVm(
          communities: block.communities,
          people: block.people,
        );
      }
    }
    return FeedSubscriptionsVm();
  }

  Future<List<FeedBlockVm>> _withLoadedMySubscriptions(
    List<FeedBlockVm> items,
  ) async {
    try {
      final subscriptions = await _subscriptionsApi.getMySubscriptions(
        limit: 20,
      );
      return _withMySubscriptionsBlock(items, subscriptions);
    } catch (_) {
      return items;
    }
  }

  void _openPerson(FeedPersonVm person) {
    final userId = person.userId.trim();
    if (userId.isEmpty) {
      return;
    }
    context.push('/users/${Uri.encodeComponent(userId)}/profile');
  }

  void _openPost(PostVm post) {
    unawaited(_openPostAndTrackDwell(post));
  }

  Future<FeedPostLikeResult?> _toggleFeedPostLike(
    PostVm post,
    bool likedByViewer,
  ) async {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return null;
    }
    final likes = likedByViewer
        ? await _postApi.unlikePost(postId)
        : await _postApi.likePost(postId);
    if (!likedByViewer) {
      _trackPostAction(
        post,
        FeedEventTypes.like,
        metadata: {'engagementType': FeedEventTypes.like},
      );
    }
    return FeedPostLikeResult(likes: likes, likedByViewer: !likedByViewer);
  }

  Future<void> _shareFeedPost(PostVm post) async {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    final share = await _postApi.sharePost(postId);
    _trackPostAction(
      post,
      FeedEventTypes.share,
      metadata: {
        'engagementType': FeedEventTypes.share,
        if (share.$1.trim().isNotEmpty) 'shareUrl': share.$1.trim(),
      },
    );
    final launcher = widget.postShareLauncher;
    if (launcher != null) {
      await launcher(post, share.$1);
      return;
    }
    await _sharePostViaSystemSheet(post, share.$1);
  }

  Future<void> _hideFeedPost(PostVm post) async {
    _trackPostAction(
      post,
      FeedEventTypes.hide,
      metadata: {'feedbackType': FeedEventTypes.hide},
    );
    _removePostFromFeed(post);
  }

  Future<void> _markFeedPostNotInterested(PostVm post) async {
    _trackPostAction(
      post,
      FeedEventTypes.notInterested,
      metadata: {'feedbackType': FeedEventTypes.notInterested},
    );
    _removePostFromFeed(post);
  }

  void _removePostFromFeed(PostVm post) {
    final postId = post.id.trim();
    if (postId.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _items = _items
          .map((block) {
            if (block.type == FeedBlockType.postCard &&
                block.post?.id.trim() == postId) {
              return null;
            }
            if (block.type != FeedBlockType.systemPosts) {
              return block;
            }
            final remainingPosts = block.posts
                .where((item) => item.id.trim() != postId)
                .toList(growable: false);
            if (remainingPosts.length == block.posts.length) {
              return block;
            }
            return FeedBlockVm(
              id: block.id,
              type: block.type,
              data: block.data,
              stories: block.stories,
              communities: block.communities,
              people: block.people,
              posts: remainingPosts,
              post: block.post,
            );
          })
          .whereType<FeedBlockVm>()
          .toList(growable: false);
    });
  }

  Future<void> _sharePostViaSystemSheet(PostVm post, String shareUrl) async {
    final trimmedShareUrl = shareUrl.trim();
    if (trimmedShareUrl.isEmpty) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: trimmedShareUrl,
        title: post.title,
        subject: post.title,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _openPostAndTrackDwell(PostVm post) async {
    _trackPostClick(post);
    final override = widget.onPostOpen;
    if (override != null) {
      override(post);
      return;
    }
    final openedAt = _analyticsNow();
    if (post.isQuickPost) {
      final communityId = (post.communityId ?? '').trim();
      final postId = post.id.trim();
      if (communityId.isEmpty || postId.isEmpty) {
        return;
      }
      final uri = Uri(
        path: '/communities/${Uri.encodeComponent(communityId)}',
        queryParameters: {'postId': postId},
      );
      await context.push(uri.toString());
      if (mounted) {
        _trackPostDwell(post, openedAt);
      }
      return;
    }
    final slug = post.slug.trim();
    if (slug.isEmpty) {
      return;
    }
    await context.push('/posts/${Uri.encodeComponent(slug)}', extra: post);
    if (mounted) {
      _trackPostDwell(post, openedAt);
    }
  }

  Future<void> _openCreatePost() async {
    const path = '/posts/create';
    final allowed = await ensurePostCreateAllowed(
      context,
      postApi: _postApi,
      loginFrom: path,
    );
    if (!allowed || !mounted) {
      return;
    }
    await context.push(path);
  }

  Future<void> _openCreateStory() async {
    final story = await context.push<StoryVm>('/stories/capture');
    if (!mounted || story == null) {
      return;
    }
    setState(() {
      _items = _appendPublishedStoryToTopStoriesTray(_items, story);
    });
    _scheduleStoryExpiryRefresh();
  }

  void _openConversionBlock(FeedBlockVm block) {
    final blockType = _feedBlockTypeWire(block.type);
    if (blockType == null) {
      return;
    }

    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.click,
        tab: _tabs[_selectedTabIndex],
        block: block,
        blockType: blockType,
        rank: _findBlockRank(block),
        metadata: _conversionMetadata(block),
      ),
    ]);

    final route = _stringData(block, 'route');
    if (route == null || !route.startsWith('/')) {
      return;
    }
    try {
      context.push(route, extra: block.data);
    } catch (_) {
      // Feed analytics should survive staged rollout of destination routes.
    }
  }

  Future<void> _openStoryTray(
    StoryVm story,
    List<StoryVm> stories,
    int index,
  ) async {
    _trackStoryClick(story);
    final override = widget.onStoryOpen;
    if (override != null) {
      override(story);
      return;
    }

    final viewableStories = stories.where(_isTrayViewerStory).toList();
    if (viewableStories.isEmpty) {
      return;
    }

    final tappedStoryIndex = viewableStories.indexWhere((item) {
      final storyId = story.id.trim();
      if (storyId.isNotEmpty && item.id.trim() == storyId) {
        return true;
      }
      return item.slug.trim() == story.slug.trim();
    });
    if (tappedStoryIndex < 0) {
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
      ),
    );
    if (!mounted || seenStoryIds == null || seenStoryIds.isEmpty) {
      return;
    }

    setState(() {
      _items = _markStoriesSeen(_items, seenStoryIds, DateTime.now().toUtc());
    });
  }

  void _trackLoadedImpressions(List<FeedBlockVm> blocks, String tab) {
    final events = <FeedEventRequest>[];
    for (var blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
      final block = blocks[blockIndex];
      final blockType = _feedBlockTypeWire(block.type);
      if (blockType == null) {
        continue;
      }

      switch (block.type) {
        case FeedBlockType.storiesTray:
          for (var index = 0; index < block.stories.length; index++) {
            final story = block.stories[index];
            final storyId = story.id.trim();
            if (storyId.isEmpty) {
              continue;
            }
            final key = 'impression:$tab:${block.id}:story:$storyId';
            if (!_sentImpressionKeys.add(key)) {
              continue;
            }
            events.add(
              _feedEvent(
                eventType: FeedEventTypes.impression,
                tab: tab,
                block: block,
                blockType: blockType,
                rank: blockIndex + index,
                metadata: {'entityType': 'story', 'entityId': storyId},
              ),
            );
          }
        case FeedBlockType.suggestedCommunities:
        case FeedBlockType.mySubscriptions:
          for (var index = 0; index < block.communities.length; index++) {
            final community = block.communities[index];
            final communityId = community.id.trim();
            if (communityId.isEmpty) {
              continue;
            }
            final key = 'impression:$tab:${block.id}:community:$communityId';
            if (!_sentImpressionKeys.add(key)) {
              continue;
            }
            events.add(
              _feedEvent(
                eventType: FeedEventTypes.impression,
                tab: tab,
                block: block,
                blockType: blockType,
                communityId: communityId,
                rank: blockIndex + index,
              ),
            );
          }
        case FeedBlockType.systemPosts:
          for (var index = 0; index < block.posts.length; index++) {
            final post = block.posts[index];
            final postId = post.id.trim();
            if (postId.isEmpty) {
              continue;
            }
            final key = 'impression:$tab:${block.id}:post:$postId';
            if (!_sentImpressionKeys.add(key)) {
              continue;
            }
            events.add(
              _feedEvent(
                eventType: FeedEventTypes.impression,
                tab: tab,
                block: block,
                blockType: blockType,
                post: post,
                rank: blockIndex + index,
              ),
            );
          }
        case FeedBlockType.postCard:
          final post = block.post;
          final postId = post?.id.trim();
          if (postId == null || postId.isEmpty) {
            continue;
          }
          final key = 'impression:$tab:${block.id}:post:$postId';
          if (!_sentImpressionKeys.add(key)) {
            continue;
          }
          events.add(
            _feedEvent(
              eventType: FeedEventTypes.impression,
              tab: tab,
              block: block,
              blockType: blockType,
              post: post,
              rank: blockIndex,
            ),
          );
        case FeedBlockType.tourCard:
        case FeedBlockType.guideCard:
          break;
        case FeedBlockType.profileCard:
        case FeedBlockType.officialNewsCard:
          if (_stringData(block, 'title') == null) {
            break;
          }
          final key = 'impression:$tab:${block.id}:conversion';
          if (!_sentImpressionKeys.add(key)) {
            continue;
          }
          events.add(
            _feedEvent(
              eventType: FeedEventTypes.impression,
              tab: tab,
              block: block,
              blockType: blockType,
              rank: blockIndex,
              metadata: _conversionMetadata(block),
            ),
          );
        case FeedBlockType.unknown:
          break;
      }
    }

    _trackFeedEvents(events);
  }

  void _trackStoryClick(StoryVm story) {
    final storyId = story.id.trim();
    if (storyId.isEmpty) {
      return;
    }
    final block = _findFeedEntityBlock(storyId);
    if (block == null) {
      return;
    }
    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.click,
        tab: _tabs[_selectedTabIndex],
        block: block.$1,
        blockType: block.$2,
        rank: block.$3,
        metadata: {'entityType': 'story', 'entityId': storyId},
      ),
    ]);
  }

  void _trackPostClick(PostVm post) {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    final block = _findFeedEntityBlock(postId);
    if (block == null) {
      return;
    }
    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.click,
        tab: _tabs[_selectedTabIndex],
        block: block.$1,
        blockType: block.$2,
        post: post,
        rank: block.$3,
      ),
    ]);
  }

  void _trackPostAction(
    PostVm post,
    String eventType, {
    Map<String, Object?> metadata = const {},
  }) {
    final postId = post.id.trim();
    final normalizedEventType = eventType.trim();
    if (postId.isEmpty || normalizedEventType.isEmpty) {
      return;
    }
    final block = _findFeedEntityBlock(postId);
    if (block == null) {
      return;
    }
    _trackFeedEvents([
      _feedEvent(
        eventType: normalizedEventType,
        tab: _tabs[_selectedTabIndex],
        block: block.$1,
        blockType: block.$2,
        post: post,
        rank: block.$3,
        metadata: metadata,
      ),
    ]);
  }

  void _trackPostDwell(PostVm post, DateTime openedAt) {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    final dwellMs = _analyticsNow().difference(openedAt).inMilliseconds;
    if (dwellMs < 1000) {
      return;
    }
    final block = _findFeedEntityBlock(postId);
    if (block == null) {
      return;
    }
    _trackFeedEvents([
      _feedEvent(
        eventType: FeedEventTypes.dwell,
        tab: _tabs[_selectedTabIndex],
        block: block.$1,
        blockType: block.$2,
        post: post,
        rank: block.$3,
        metadata: {'dwellMs': dwellMs.clamp(1000, 30 * 60 * 1000)},
      ),
    ]);
  }

  DateTime _analyticsNow() => (widget.analyticsNow ?? DateTime.now)().toUtc();

  (FeedBlockVm, String, int)? _findFeedEntityBlock(String entityId) {
    final normalizedEntityId = entityId.trim();
    if (normalizedEntityId.isEmpty) {
      return null;
    }
    for (var blockIndex = 0; blockIndex < _items.length; blockIndex++) {
      final block = _items[blockIndex];
      final blockType = _feedBlockTypeWire(block.type);
      if (blockType == null) {
        continue;
      }
      if (block.type == FeedBlockType.postCard &&
          block.post?.id.trim() == normalizedEntityId) {
        return (block, blockType, blockIndex);
      }
      if (block.type == FeedBlockType.systemPosts) {
        for (var index = 0; index < block.posts.length; index++) {
          if (block.posts[index].id.trim() == normalizedEntityId) {
            return (block, blockType, blockIndex + index);
          }
        }
      }
      if (block.type == FeedBlockType.storiesTray) {
        for (var index = 0; index < block.stories.length; index++) {
          if (block.stories[index].id.trim() == normalizedEntityId) {
            return (block, blockType, blockIndex + index);
          }
        }
      }
    }
    return null;
  }

  (FeedBlockVm, String, int)? _findCommunityBlock(String communityId) {
    final normalizedCommunityId = communityId.trim();
    if (normalizedCommunityId.isEmpty) {
      return null;
    }
    for (var blockIndex = 0; blockIndex < _items.length; blockIndex++) {
      final block = _items[blockIndex];
      final blockType = _feedBlockTypeWire(block.type);
      if (blockType == null) {
        continue;
      }
      switch (block.type) {
        case FeedBlockType.suggestedCommunities:
        case FeedBlockType.mySubscriptions:
          for (var index = 0; index < block.communities.length; index++) {
            if (block.communities[index].id.trim() == normalizedCommunityId) {
              return (block, blockType, blockIndex + index);
            }
          }
        case FeedBlockType.storiesTray:
        case FeedBlockType.systemPosts:
        case FeedBlockType.postCard:
        case FeedBlockType.tourCard:
        case FeedBlockType.guideCard:
        case FeedBlockType.profileCard:
        case FeedBlockType.officialNewsCard:
        case FeedBlockType.unknown:
          break;
      }
    }
    return null;
  }

  int _findBlockRank(FeedBlockVm target) {
    for (var index = 0; index < _items.length; index++) {
      final block = _items[index];
      if (block.id == target.id && block.type == target.type) {
        return index;
      }
    }
    return 0;
  }

  FeedEventRequest _feedEvent({
    required String eventType,
    required String tab,
    required FeedBlockVm block,
    required String blockType,
    required int rank,
    String? postId,
    String? communityId,
    PostVm? post,
    Map<String, Object?> metadata = const {},
  }) {
    final blockId = block.id.trim().isNotEmpty ? block.id.trim() : blockType;
    const surface = 'content';
    final normalizedPostId = _trimmedOrNull(postId) ?? _trimmedOrNull(post?.id);
    final normalizedCommunityId =
        _trimmedOrNull(communityId) ?? _trimmedOrNull(post?.communityId);
    return FeedEventRequest(
      eventId: _uuidV4(),
      eventType: eventType,
      surface: surface,
      tab: tab,
      blockId: blockId,
      blockType: blockType,
      postId: normalizedPostId,
      communityId: normalizedCommunityId,
      rank: rank,
      occurredAt: DateTime.now().toUtc(),
      metadata: _postTelemetryMetadata(
        _feedBlockTelemetryMetadata(block, metadata),
        post: post,
        communityId: normalizedCommunityId,
        surface: surface,
        tab: tab,
        action: eventType,
      ),
    );
  }

  void _trackFeedEvents(List<FeedEventRequest> events) {
    if (events.isEmpty) {
      return;
    }
    unawaited(_sendFeedEvents(events));
  }

  Future<void> _sendFeedEvents(List<FeedEventRequest> events) async {
    try {
      await _feedApi.trackFeedEvents(events);
    } catch (_) {
      // Feed analytics should never interrupt browsing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1208),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A1A0E),
        foregroundColor: const Color(0xFFFFF7ED),
        elevation: 0,
        centerTitle: false,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D2612), Color(0xFF241509)],
            ),
          ),
        ),
        title: Text(
          l10n.feedTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              key: const ValueKey('open-feed-notifications'),
              tooltip: l10n.notificationsTitle,
              onPressed: () => context.push('/notifications'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                foregroundColor: AppColors.accent,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  onTap: _selectTab,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: const Color(0xFFFFE0B2),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    for (var index = 0; index < _tabs.length; index++)
                      Tab(
                        child: Text(
                          _tabLabel(l10n, index),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF27180B), Color(0xFF18110A)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: const Color(0xFF2A1A0E),
            onRefresh: () => _loadFeed(showLoading: false),
            child: _buildBody(context),
          ),
        ),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.feed,
        showFeedItem: true,
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onFeedTap: () => unawaited(_handleFeedNavTap()),
        onCenterCreateTap: () => unawaited(_openCreatePost()),
        centerCreateSemanticsLabel: l10n.communityProfileCreatePostAction,
        onMapTap: () => context.push('/map'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final profile = _maybeSessionProfile(context);
    final tab = _tabs[_selectedTabIndex];
    final visibleItems = _shouldHideViewerOwnedPosts(tab)
        ? _withoutViewerOwnedPosts(_items, profile?.userId)
        : _items;
    final sortedItems = _withSortedPostCards(visibleItems, _postSortMode);
    if (_isLoading && _items.isEmpty) {
      return const _FeedStateList(child: _FeedLoadingState());
    }

    if (_error != null && _items.isEmpty) {
      return _FeedStateList(child: _FeedErrorState(onRetry: () => _loadFeed()));
    }

    if (visibleItems.isEmpty) {
      return _FeedStateList(
        child: _FeedEmptyState(l10n: AppLocalizations.of(context)!),
      );
    }

    return FeedBlockList(
      blocks: sortedItems,
      controller: _scrollController,
      postSortMode: _postSortMode,
      onPostSortModeChanged: (mode) {
        if (mode == _postSortMode) {
          return;
        }
        setState(() {
          _postSortMode = mode;
        });
      },
      isLoadingMore: _isLoadingMore,
      hasLoadMoreError: _loadMoreError != null,
      onLoadMoreRetry: () => _loadFeed(showLoading: false, append: true),
      updatingCommunityIds: _updatingCommunityIds,
      onCommunityToggle: _toggleCommunityFollow,
      onStoryOpen: widget.onStoryOpen,
      onPostOpen: _openPost,
      onPostLike: _toggleFeedPostLike,
      onPostShare: _shareFeedPost,
      onPostHide: _hideFeedPost,
      onPostNotInterested: _markFeedPostNotInterested,
      onStoryTrayOpen: _openStoryTray,
      onCreateStory: _openCreateStory,
      viewerAvatarUrl: _profileAvatarUrl(profile),
      viewerInitials: profile?.initials ?? 'F',
      viewerUserId: profile?.userId,
      onCommunityOpen: _openCommunity,
      onCommunityModerationOpen: _openCommunityModeration,
      onCommunityExploreOpen: () => unawaited(_openCommunityDiscoverySheet()),
      onMySubscriptionsOpen: () => unawaited(_openMySubscriptionsSheet()),
      onSystemPostsOpen: _openSystemPostsSheet,
      onPersonOpen: _openPerson,
      onConversionBlockOpen: _openConversionBlock,
      locationLabelResolver: widget.locationLabelResolver,
    );
  }

  String _tabLabel(AppLocalizations l10n, int index) {
    return switch (index) {
      0 => l10n.feedTabForYou,
      1 => l10n.feedTabFollowing,
      _ => '',
    };
  }
}

UserProfileVm? _maybeSessionProfile(BuildContext context) {
  try {
    return context.watch<SessionProvider>().profile;
  } on ProviderNotFoundException {
    return null;
  }
}

UserProfileVm? _maybeSessionProfileForRead(BuildContext context) {
  try {
    return context.read<SessionProvider>().profile;
  } on ProviderNotFoundException {
    return null;
  }
}

List<FeedBlockVm> _withoutViewerOwnedPosts(
  List<FeedBlockVm> blocks,
  String? viewerUserId,
) {
  final normalizedViewerUserId = (viewerUserId ?? '').trim();
  if (normalizedViewerUserId.isEmpty) {
    return blocks;
  }

  final result = <FeedBlockVm>[];
  for (final block in blocks) {
    if (block.type == FeedBlockType.postCard) {
      final post = block.post;
      if (post == null || post.author.userId.trim() != normalizedViewerUserId) {
        result.add(block);
      }
      continue;
    }

    if (block.type == FeedBlockType.systemPosts) {
      result.addAll(
        _viewerFilteredSystemPostBlock(block, normalizedViewerUserId),
      );
      continue;
    }

    result.add(block);
  }
  return List<FeedBlockVm>.unmodifiable(result);
}

bool _shouldHideViewerOwnedPosts(String tab) {
  return tab.trim().toLowerCase() != 'following';
}

List<FeedBlockVm> _withSortedPostCards(
  List<FeedBlockVm> blocks,
  FeedPostSortMode sortMode,
) {
  if (sortMode == FeedPostSortMode.recommended) {
    return blocks;
  }

  final postBlocks = [
    for (final block in blocks)
      if (block.type == FeedBlockType.postCard && block.post != null) block,
  ];
  if (postBlocks.length < 2) {
    return blocks;
  }

  postBlocks.sort((a, b) => _comparePostBlocks(a.post!, b.post!, sortMode));

  var postIndex = 0;
  return List<FeedBlockVm>.unmodifiable([
    for (final block in blocks)
      if (block.type == FeedBlockType.postCard && block.post != null)
        postBlocks[postIndex++]
      else
        block,
  ]);
}

int _comparePostBlocks(PostVm a, PostVm b, FeedPostSortMode sortMode) {
  final primary = switch (sortMode) {
    FeedPostSortMode.recommended => 0,
    FeedPostSortMode.newest => b.sortDate.compareTo(a.sortDate),
    FeedPostSortMode.popular => _postPopularityScore(
      b,
    ).compareTo(_postPopularityScore(a)),
    FeedPostSortMode.discussed => b.stats.comments.compareTo(a.stats.comments),
  };
  if (primary != 0) {
    return primary;
  }

  final dateFallback = b.sortDate.compareTo(a.sortDate);
  if (dateFallback != 0) {
    return dateFallback;
  }
  return a.id.compareTo(b.id);
}

int _postPopularityScore(PostVm post) {
  return post.stats.likes * 4 +
      post.stats.comments * 3 +
      post.stats.shares * 5 +
      post.stats.views;
}

List<FeedBlockVm> _viewerFilteredSystemPostBlock(
  FeedBlockVm block,
  String viewerUserId,
) {
  final posts = [
    for (final post in block.posts)
      if (post.author.userId.trim() != viewerUserId) post,
  ];
  if (posts.isEmpty) {
    return const [];
  }
  return [
    FeedBlockVm(
      id: block.id,
      type: block.type,
      data: block.data,
      stories: block.stories,
      communities: block.communities,
      people: block.people,
      posts: posts,
      post: block.post,
    ),
  ];
}

bool _isTrayViewerStory(StoryVm story) {
  return _isTrayViewerStoryAt(story, DateTime.now().toUtc());
}

bool _isTrayViewerStoryAt(StoryVm story, DateTime now) {
  return story.isPublished &&
      story.expiresAt.isAfter(now.toUtc()) &&
      story.slug.trim().isNotEmpty;
}

List<FeedBlockVm> _withTopStoriesTray(List<FeedBlockVm> blocks) {
  final stories = <StoryVm>[];
  final seenStoryIds = <String>{};
  String? trayId;
  final rest = <FeedBlockVm>[];

  for (final block in blocks) {
    if (block.type != FeedBlockType.storiesTray) {
      rest.add(block);
      continue;
    }

    trayId ??= block.id.trim().isEmpty ? null : block.id.trim();
    for (final story in block.stories) {
      if (!_isTrayViewerStory(story)) {
        continue;
      }
      final storyId = story.id.trim();
      final identity = storyId.isEmpty ? story.slug.trim() : storyId;
      if (identity.isEmpty || !seenStoryIds.add(identity)) {
        continue;
      }
      stories.add(story);
    }
  }

  return [
    FeedBlockVm(
      id: trayId ?? 'stories:top',
      type: FeedBlockType.storiesTray,
      stories: stories,
    ),
    ...rest,
  ];
}

List<FeedBlockVm> _dropExpiredStoriesFromStoryTrays(
  List<FeedBlockVm> blocks,
  DateTime now,
) {
  return [
    for (final block in blocks)
      if (block.type == FeedBlockType.storiesTray)
        FeedBlockVm(
          id: block.id,
          type: block.type,
          data: block.data,
          stories: [
            for (final story in block.stories)
              if (_isTrayViewerStoryAt(story, now)) story,
          ],
          communities: block.communities,
          people: block.people,
          posts: block.posts,
          post: block.post,
        )
      else
        block,
  ];
}

List<FeedBlockVm> _withMySubscriptionsBlock(
  List<FeedBlockVm> blocks,
  FeedSubscriptionsVm subscriptions,
) {
  final visibleBlocks = [
    for (final block in blocks)
      if (block.type != FeedBlockType.mySubscriptions) block,
  ];
  if (subscriptions.isEmpty) {
    return visibleBlocks;
  }

  final subscriptionBlock = FeedBlockVm(
    id: 'subscriptions:mine',
    type: FeedBlockType.mySubscriptions,
    communities: subscriptions.communities,
    people: subscriptions.people,
  );
  final storiesTrayIndex = visibleBlocks.indexWhere(
    (block) => block.type == FeedBlockType.storiesTray,
  );
  if (storiesTrayIndex < 0) {
    return [subscriptionBlock, ...visibleBlocks];
  }

  return [
    ...visibleBlocks.take(storiesTrayIndex + 1),
    subscriptionBlock,
    ...visibleBlocks.skip(storiesTrayIndex + 1),
  ];
}

List<FeedBlockVm> _withSmartPostSections(
  List<FeedBlockVm> blocks, {
  required bool includeSystemPosts,
}) {
  final systemPosts = <PostVm>[];
  final subscriptionPostBlocks = <FeedBlockVm>[];
  final discoveryPostBlocks = <FeedBlockVm>[];
  final nonPostBlocks = <FeedBlockVm>[];

  for (final block in blocks) {
    if (block.type == FeedBlockType.systemPosts) {
      if (includeSystemPosts) {
        systemPosts.addAll(block.posts);
      }
      continue;
    }
    if (block.type != FeedBlockType.postCard || block.post == null) {
      nonPostBlocks.add(block);
      continue;
    }

    if (_isSystemPostBlock(block)) {
      if (includeSystemPosts) {
        systemPosts.add(block.post!);
      }
      continue;
    }

    if (_isSubscriptionPostBlock(block)) {
      subscriptionPostBlocks.add(block);
    } else {
      discoveryPostBlocks.add(block);
    }
  }

  final result = <FeedBlockVm>[...nonPostBlocks];
  if (includeSystemPosts && systemPosts.isNotEmpty) {
    final insertIndex = _systemPostsInsertIndex(result);
    result.insert(
      insertIndex,
      FeedBlockVm(
        id: 'system-posts',
        type: FeedBlockType.systemPosts,
        posts: systemPosts,
      ),
    );
  }

  result.addAll(subscriptionPostBlocks);
  result.addAll(discoveryPostBlocks);
  return List<FeedBlockVm>.unmodifiable(result);
}

int _systemPostsInsertIndex(List<FeedBlockVm> blocks) {
  final suggestedIndex = blocks.lastIndexWhere(
    (block) => block.type == FeedBlockType.suggestedCommunities,
  );
  if (suggestedIndex >= 0) {
    return suggestedIndex + 1;
  }

  final subscriptionsIndex = blocks.lastIndexWhere(
    (block) => block.type == FeedBlockType.mySubscriptions,
  );
  if (subscriptionsIndex >= 0) {
    return subscriptionsIndex + 1;
  }

  final storiesIndex = blocks.lastIndexWhere(
    (block) => block.type == FeedBlockType.storiesTray,
  );
  return storiesIndex >= 0 ? storiesIndex + 1 : 0;
}

bool _isSystemPostBlock(FeedBlockVm block) {
  final post = block.post;
  final signals = <String>[
    _stringData(block, 'source') ?? '',
    _stringData(block, 'ownerType') ?? '',
    _stringData(block, 'authorType') ?? '',
    _stringData(block, 'audience') ?? '',
    _stringData(block, 'bucket') ?? '',
    post?.category ?? '',
    post?.format ?? '',
    post?.author.userId ?? '',
    post?.author.nickname ?? '',
    ...?post?.tags,
  ];
  return signals.any((signal) {
    final normalized = signal.trim().replaceAll('-', '_').toLowerCase();
    return normalized == 'system' ||
        normalized == 'official' ||
        normalized == 'app_news' ||
        normalized == 'inflap' ||
        normalized == 'system_user' ||
        normalized.contains('official') ||
        normalized.contains('system');
  });
}

bool _isSubscriptionPostBlock(FeedBlockVm block) {
  final signals = <String>[
    _stringData(block, 'source') ?? '',
    _stringData(block, 'relationship') ?? '',
    _stringData(block, 'audience') ?? '',
    _stringData(block, 'bucket') ?? '',
    _stringData(block, 'feedReason') ?? '',
  ];
  return signals.any((signal) {
    final normalized = signal.trim().replaceAll('-', '_').toLowerCase();
    return normalized == 'following' ||
        normalized == 'friend' ||
        normalized == 'friends' ||
        normalized == 'subscribed' ||
        normalized == 'subscription' ||
        normalized.contains('following') ||
        normalized.contains('friend') ||
        normalized.contains('subscribed') ||
        normalized.contains('subscription');
  });
}

List<FeedBlockVm> _appendPublishedStoryToTopStoriesTray(
  List<FeedBlockVm> blocks,
  StoryVm story,
) {
  if (!_isTrayViewerStory(story)) {
    return blocks;
  }

  final identity = _storyTrayIdentity(story);
  final updatedBlocks = <FeedBlockVm>[];
  var hasStoriesTray = false;

  for (final block in blocks) {
    if (block.type != FeedBlockType.storiesTray || hasStoriesTray) {
      updatedBlocks.add(block);
      continue;
    }

    hasStoriesTray = true;
    final hasStory = block.stories.any(
      (item) => _storyTrayIdentity(item) == identity,
    );
    updatedBlocks.add(
      hasStory
          ? block
          : FeedBlockVm(
              id: block.id,
              type: block.type,
              data: block.data,
              stories: [...block.stories, story],
              communities: block.communities,
              people: block.people,
              posts: block.posts,
              post: block.post,
            ),
    );
  }

  if (hasStoriesTray) {
    return updatedBlocks;
  }

  return [
    FeedBlockVm(
      id: 'stories:top',
      type: FeedBlockType.storiesTray,
      stories: [story],
    ),
    ...blocks,
  ];
}

String _storyTrayIdentity(StoryVm story) {
  final storyId = story.id.trim();
  if (storyId.isNotEmpty) {
    return 'id:$storyId';
  }
  return 'slug:${story.slug.trim()}';
}

List<FeedBlockVm> _withoutAdditionalStoryTrays(List<FeedBlockVm> blocks) {
  return [
    for (final block in blocks)
      if (block.type != FeedBlockType.storiesTray) block,
  ];
}

String? _profileAvatarUrl(UserProfileVm? profile) {
  final avatarFileId = (profile?.avatarFileId ?? '').trim();
  if (avatarFileId.isEmpty) {
    return null;
  }
  return resolvePublicFileContentUrl(avatarFileId);
}

List<FeedBlockVm> _withoutHiddenConversionBlocks(List<FeedBlockVm> blocks) {
  return [
    for (final block in blocks)
      if (!_isHiddenConversionBlock(block)) block,
  ];
}

bool _isHiddenConversionBlock(FeedBlockVm block) {
  return switch (block.type) {
    FeedBlockType.profileCard || FeedBlockType.officialNewsCard => true,
    _ => false,
  };
}

List<FeedBlockVm> _markStoriesSeen(
  List<FeedBlockVm> blocks,
  Set<String> seenStoryIds,
  DateTime seenAt,
) {
  return [
    for (final block in blocks)
      FeedBlockVm(
        id: block.id,
        type: block.type,
        data: block.data,
        stories: [
          for (final story in block.stories)
            _markStorySeenIfNeeded(story, seenStoryIds, seenAt),
        ],
        communities: block.communities,
        people: block.people,
        posts: block.posts,
        post: block.post,
      ),
  ];
}

StoryVm _markStorySeenIfNeeded(
  StoryVm story,
  Set<String> seenStoryIds,
  DateTime seenAt,
) {
  if (!seenStoryIds.contains(story.id.trim()) || story.isSeenByViewer) {
    return story;
  }
  return story.copyWith(seenByViewer: true, seenAt: seenAt);
}

List<FeedBlockVm> _replaceCommunity(
  List<FeedBlockVm> blocks,
  FeedCommunityVm updatedCommunity,
) {
  return [
    for (final block in blocks)
      FeedBlockVm(
        id: block.id,
        type: block.type,
        data: block.data,
        stories: block.stories,
        communities: [
          for (final community in block.communities)
            community.id == updatedCommunity.id ? updatedCommunity : community,
        ],
        people: block.people,
        posts: block.posts,
        post: block.post,
      ),
  ];
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, Object?> _feedBlockTelemetryMetadata(
  FeedBlockVm block,
  Map<String, Object?> metadata,
) {
  final enriched = <String, Object?>{...metadata};
  final candidateSource = _stringData(block, 'candidateSource');
  if (candidateSource != null) {
    enriched.putIfAbsent('candidateSource', () => candidateSource);
  }
  return enriched;
}

Map<String, Object?> _postTelemetryMetadata(
  Map<String, Object?> metadata, {
  required PostVm? post,
  required String? communityId,
  required String surface,
  required String tab,
  required String action,
}) {
  if (post == null) {
    return metadata;
  }

  final enriched = <String, Object?>{...metadata};

  void putString(String key, String? value) {
    final normalized = _trimmedOrNull(value);
    if (normalized != null) {
      enriched.putIfAbsent(key, () => normalized);
    }
  }

  final tags = _postTelemetryTags(post.tags);
  putString(
    'postProfileKey',
    _trimmedOrNull(post.postProfileKey) ?? post.postProfileContract.key,
  );
  putString('communityId', communityId);
  putString('authorUserId', post.author.userId);
  putString('cityId', post.placeCityId);
  putString(
    'countryCode',
    _trimmedOrNull(post.placeCountryCode)?.toUpperCase(),
  );
  putString('category', post.category);
  putString('categorySlug', _postCategorySlug(post.category));
  if (tags.isNotEmpty) {
    enriched.putIfAbsent('tags', () => tags);
    enriched.putIfAbsent('postTags', () => tags);
  }
  putString('surface', surface);
  putString('tab', tab);
  putString('action', action);

  return enriched;
}

List<String> _postTelemetryTags(List<String> tags) {
  final seen = <String>{};
  final normalizedTags = <String>[];
  for (final tag in tags) {
    final normalized = _trimmedOrNull(tag);
    if (normalized == null || !seen.add(normalized)) {
      continue;
    }
    normalizedTags.add(normalized);
  }
  return normalizedTags;
}

String? _postCategorySlug(String category) {
  final trimmed = _trimmedOrNull(category);
  if (trimmed == null) {
    return null;
  }
  final slug = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return _trimmedOrNull(slug);
}

Map<String, Object?> _conversionMetadata(FeedBlockVm block) {
  final semanticTags = _stringListData(block, 'semanticTags');
  return {
    'action': 'conversion',
    if (_stringData(block, 'entityType') != null)
      'entityType': _stringData(block, 'entityType'),
    if (_stringData(block, 'entityId') != null)
      'entityId': _stringData(block, 'entityId'),
    if (_stringData(block, 'source') != null)
      'source': _stringData(block, 'source'),
    if (semanticTags.isNotEmpty) 'semanticTags': semanticTags,
  };
}

String? _stringData(FeedBlockVm block, String key) {
  final value = block.data[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

List<String> _stringListData(FeedBlockVm block, String key) {
  final value = block.data[key];
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item.toString().trim().isNotEmpty) item.toString().trim(),
  ];
}

String? _feedBlockTypeWire(FeedBlockType type) {
  return switch (type) {
    FeedBlockType.storiesTray => 'stories_tray',
    FeedBlockType.suggestedCommunities => 'suggested_communities',
    FeedBlockType.mySubscriptions => 'my_subscriptions',
    FeedBlockType.systemPosts => 'official_news_card',
    FeedBlockType.postCard => 'post_card',
    FeedBlockType.tourCard => 'tour_card',
    FeedBlockType.guideCard => 'guide_card',
    FeedBlockType.profileCard => 'profile_card',
    FeedBlockType.officialNewsCard => 'official_news_card',
    FeedBlockType.unknown => null,
  };
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

class _FeedStateList extends StatelessWidget {
  const _FeedStateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalFeedPadding(constraints.maxWidth);

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

class _FeedLoadingState extends StatelessWidget {
  const _FeedLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _FeedMessageState(
      icon: Icons.auto_awesome_outlined,
      title: l10n.feedEmptyTitle,
      message: l10n.feedEmptyMessage,
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  const _FeedErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _FeedMessageState(
      icon: Icons.wifi_off_rounded,
      title: l10n.feedLoadFailedTitle,
      message: l10n.feedLoadFailedMessage,
      action: FilledButton(
        onPressed: onRetry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
        ),
        child: Text(
          l10n.feedRetryAction,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FeedMessageState extends StatelessWidget {
  const _FeedMessageState({
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

double _horizontalFeedPadding(double width) {
  if (width >= 840) {
    return 32;
  }
  if (width >= 600) {
    return 24;
  }
  return 16;
}
