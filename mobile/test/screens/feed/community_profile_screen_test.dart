import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/presentation/community_profile_screen.dart';
import 'package:inflap/features/stories/models/post_profile_contract.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/features/trust/data/trust_moderation_actions_api.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';

void main() {
  testWidgets('renders community profile and refreshes details', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      community: _community(
        title: 'Investments',
        description: 'Practical investing guides and market discussions.',
        membersCount: 6326,
        postCount: 82,
        followedByViewer: true,
      ),
    );

    await tester.pumpWidget(
      _profileApp(
        api,
        initialCommunity: _community(
          title: 'Investments',
          description: 'Cached short description.',
          membersCount: 6000,
          postCount: 80,
          followedByViewer: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.loadedCommunityIds, ['community-1']);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Community'), findsNothing);
    expect(
      find.byKey(const ValueKey('community-profile-cover')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-profile-info-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-profile-avatar')),
      findsOneWidget,
    );
    expect(find.text('Investments'), findsOneWidget);
    expect(
      find.text('Practical investing guides and market discussions.'),
      findsOneWidget,
    );
    expect(find.text('6.3K members'), findsOneWidget);
    expect(find.text('82 posts'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets(
    'renders clean community title, localized city, and topic label',
    (tester) async {
      final api = _FakeFeedApi(
        community: _community(
          title: 'Football · da-nang',
          description: 'Pickup games and local sports meetups.',
          topic: 'SPORTS',
          countryCode: 'VN',
          cityId: 'da-nang',
          cityName: 'Da Nang',
        ),
      );

      await tester.pumpWidget(_profileApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Football · da-nang'), findsNothing);
      expect(find.text('Da Nang'), findsOneWidget);
      expect(find.text('Sports'), findsOneWidget);
      expect(find.text('SPORTS'), findsNothing);
    },
  );

  testWidgets('renders community rules in profile trust block', (tester) async {
    final api = _FakeFeedApi(
      community: _community(
        rules: const [
          'Share firsthand travel advice.',
          'Keep commercial offers transparent.',
        ],
      ),
    );

    await tester.pumpWidget(_profileApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Community rules'), findsOneWidget);
    expect(find.text('Share firsthand travel advice.'), findsOneWidget);
    expect(find.text('Keep commercial offers transparent.'), findsOneWidget);
  });

  testWidgets('renders viewer restriction banner and appeal action', (
    tester,
  ) async {
    final trustApi = _FakeTrustModerationActionsApi();
    final api = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        viewerTrustStatus: 'APPEAL_PENDING',
        viewerRestrictionId: 'restriction-123',
      ),
    );

    await tester.pumpWidget(_profileApp(api, trustApi: trustApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Appeal in review'));

    expect(find.text('Appeal in review'), findsOneWidget);
    expect(
      find.text('Moderators are reviewing your appeal for this community.'),
      findsOneWidget,
    );
    expect(find.text('Create post'), findsNothing);

    await tester.ensureVisible(find.text('Appeal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appeal'));
    await tester.pumpAndSettle();

    expect(trustApi.appealRequest?.restrictionId, 'restriction-123');
  });

  testWidgets('keeps community trust actions inside header menu only', (
    tester,
  ) async {
    final trustApi = _FakeTrustModerationActionsApi();
    final api = _FakeFeedApi(community: _community());

    await tester.pumpWidget(_profileApp(api, trustApi: trustApi));
    await tester.pumpAndSettle();

    expect(find.text('Report community'), findsNothing);
    expect(find.text('Mute community'), findsNothing);

    await tester.tap(find.byTooltip('Community actions'));
    await tester.pumpAndSettle();

    expect(find.text('Report community'), findsOneWidget);
    expect(find.text('Mute community'), findsOneWidget);
    expect(trustApi.reportRequest, isNull);
    expect(trustApi.muteTargetRequest, isNull);
  });

  testWidgets('shows friendly message when trust endpoint is not ready', (
    tester,
  ) async {
    final trustApi = _FakeTrustModerationActionsApi(
      reportError: UnsupportedError('not ready'),
    );
    final api = _FakeFeedApi(community: _community());

    await tester.pumpWidget(_profileApp(api, trustApi: trustApi));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Community actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report community').last);
    await tester.pumpAndSettle();

    expect(
      find.text('This trust action is not available yet.'),
      findsOneWidget,
    );
  });

  testWidgets('toggles community follow from profile', (tester) async {
    final api = _FakeFeedApi(
      community: _community(
        followedByViewer: false,
        membersCount: 42,
        countryCode: 'KZ',
        cityId: 'almaty',
      ),
    );

    await tester.pumpWidget(_profileApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(api.followedCommunityIds, ['community-1']);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('43 members'), findsOneWidget);
    final subscribeEvent = api.trackedEvents.lastWhere(
      (event) =>
          event.eventType == 'subscribe' && event.communityId == 'community-1',
    );
    expect(subscribeEvent.blockType, 'community_card');
    expect(
      subscribeEvent.metadata,
      containsPair('source', 'community_profile'),
    );
    expect(subscribeEvent.metadata, containsPair('entityType', 'community'));
    expect(subscribeEvent.metadata, containsPair('entityId', 'community-1'));
    expect(subscribeEvent.metadata, containsPair('topic', 'FINANCE'));
    expect(subscribeEvent.metadata, containsPair('countryCode', 'KZ'));
    expect(subscribeEvent.metadata, containsPair('cityId', 'almaty'));
  });

  testWidgets('confirms before unfollowing community from profile', (
    tester,
  ) async {
    final api = _FakeFeedApi(
      community: _community(followedByViewer: true, membersCount: 43),
    );

    await tester.pumpWidget(_profileApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();

    expect(find.text('Unfollow community?'), findsOneWidget);
    expect(api.unfollowedCommunityIds, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(api.unfollowedCommunityIds, isEmpty);
    expect(find.text('Following'), findsOneWidget);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unfollow'));
    await tester.pumpAndSettle();

    expect(api.unfollowedCommunityIds, ['community-1']);
    expect(find.text('Join'), findsOneWidget);
    expect(find.text('42 members'), findsOneWidget);
  });

  testWidgets('runs hide and show community actions from header menu', (
    tester,
  ) async {
    final trustApi = _FakeTrustModerationActionsApi();
    final api = _FakeFeedApi(community: _community());

    await tester.pumpWidget(_profileApp(api, trustApi: trustApi));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Community actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mute community').last);
    await tester.pumpAndSettle();

    expect(trustApi.muteTargetRequest?.target.entityId, 'community-1');
    await _scrollUntilVisible(tester, find.text('Community muted'));
    expect(find.text('Community muted'), findsOneWidget);
    expect(find.text('Community muted.'), findsOneWidget);
    final muteEvent = api.trackedEvents.singleWhere(
      (event) => event.eventType == FeedEventTypes.hide,
    );
    expect(muteEvent.communityId, 'community-1');
    expect(muteEvent.blockId, 'community:community-1:profile');
    expect(muteEvent.blockType, 'community_card');
    expect(muteEvent.metadata, containsPair('source', 'community_mute'));
    expect(muteEvent.metadata, containsPair('entityType', 'community'));
    expect(muteEvent.metadata, containsPair('entityId', 'community-1'));
    expect(
      muteEvent.metadata,
      containsPair('feedbackType', FeedEventTypes.hide),
    );

    await _scrollProfileToTop(tester);
    expect(find.byTooltip('Community actions'), findsOneWidget);
    await tester.tap(find.byTooltip('Community actions'));
    await tester.pumpAndSettle();
    expect(find.text('Unmute community'), findsWidgets);

    await tester.tap(find.text('Unmute community').last);
    await tester.pumpAndSettle();

    expect(trustApi.unmuteTargetRequest?.target.entityId, 'community-1');
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('community-profile-posts-section')),
    );
    expect(find.text('Community muted'), findsNothing);
    expect(find.text('Community unmuted.'), findsOneWidget);
  });

  testWidgets('runs report community action from header menu', (tester) async {
    final trustApi = _FakeTrustModerationActionsApi();
    final api = _FakeFeedApi(community: _community());

    await tester.pumpWidget(_profileApp(api, trustApi: trustApi));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Community actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report community').last);
    await tester.pumpAndSettle();

    expect(trustApi.reportRequest?.target.entityId, 'community-1');
    expect(find.text('Community sent to moderation.'), findsOneWidget);
    final reportEvent = api.trackedEvents.singleWhere(
      (event) => event.eventType == FeedEventTypes.report,
    );
    expect(reportEvent.communityId, 'community-1');
    expect(reportEvent.blockId, 'community:community-1:profile');
    expect(reportEvent.blockType, 'community_card');
    expect(reportEvent.metadata, containsPair('source', 'community_profile'));
    expect(reportEvent.metadata, containsPair('entityType', 'community'));
    expect(reportEvent.metadata, containsPair('entityId', 'community-1'));
    expect(
      reportEvent.metadata,
      containsPair('feedbackType', FeedEventTypes.report),
    );
  });

  testWidgets('opens community post composer when viewer can post', (
    tester,
  ) async {
    FeedCommunityVm? selectedCommunity;
    final api = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );

    await tester.pumpWidget(
      _profileApp(
        api,
        onCreatePost: (community) {
          selectedCommunity = community;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Create post'));

    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    expect(selectedCommunity?.id, 'community-1');
  });

  testWidgets('hides post composer action for non-followers', (tester) async {
    final api = _FakeFeedApi(
      community: _community(
        followedByViewer: false,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );

    await tester.pumpWidget(_profileApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Create post'), findsNothing);
  });

  testWidgets('shows single create post action after following community', (
    tester,
  ) async {
    FeedCommunityVm? selectedCommunity;
    final api = _FakeFeedApi(
      community: _community(
        followedByViewer: false,
        postingPolicy: 'OPEN_MEMBERS',
        defaultPostProfileKey: PostProfileKeys.quickPost,
        allowedPostProfileKeys: const [
          PostProfileKeys.quickPost,
          PostProfileKeys.listing,
        ],
      ),
    );

    await tester.pumpWidget(
      _profileApp(
        api,
        onCreatePost: (community) {
          selectedCommunity = community;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create post'), findsNothing);

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Create post'));
    expect(
      find.byKey(const ValueKey('community-post-mode-quick_post_v1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('community-post-mode-listing_v1')),
      findsNothing,
    );

    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    expect(selectedCommunity?.defaultPostProfileKey, PostProfileKeys.quickPost);
  });

  testWidgets('loads and opens community posts', (tester) async {
    PostVm? openedStory;
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final storyApi = _FakePostApi(
      stories: [_story('story-1', postProfileKey: 'article_v1')],
    );

    await tester.pumpWidget(
      _profileApp(
        feedApi,
        postApi: storyApi,
        onStoryOpen: (story) {
          openedStory = story;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(storyApi.communityIds, ['community-1']);
    await _scrollUntilVisible(tester, find.text('Community story story-1'));
    expect(find.text('Community story story-1'), findsOneWidget);

    await tester.ensureVisible(find.text('Community story story-1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community story story-1'));
    await tester.pumpAndSettle();

    expect(openedStory?.id, 'story-1');
    final clickEvent = feedApi.trackedEvents.lastWhere(
      (event) => event.eventType == 'click' && event.postId == 'story-1',
    );
    expect(clickEvent.communityId, 'community-1');
    expect(clickEvent.metadata, containsPair('source', 'community_profile'));
    expect(clickEvent.metadata, containsPair('action', 'click'));
    expect(clickEvent.metadata, containsPair('postProfileKey', 'article_v1'));
  });

  testWidgets('shows community posts to guests without action controls', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(community: _community(title: 'Travel club'));
    final postApi = _FakePostApi(
      stories: [
        _story('quick-guest', postProfileKey: PostProfileKeys.quickPost),
      ],
    );

    await tester.pumpWidget(
      _profileApp(feedApi, postApi: postApi, authenticated: false),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('quick-post-thread-quick-guest')),
    );

    expect(
      find.byKey(const ValueKey('quick-post-thread-quick-guest')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    expect(
      find.byKey(const ValueKey('quick-post-like-quick-guest')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('quick-post-comment-field-quick-guest')),
      findsNothing,
    );
  });

  testWidgets('tracks community post dwell after returning from details', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 16, 12);
    final feedApi = _FakeFeedApi(community: _community());
    final postApi = _FakePostApi(
      stories: [_story('story-1', postProfileKey: 'article_v1')],
    );

    await tester.pumpWidget(
      _profileRouterApp(feedApi, postApi: postApi, analyticsNow: () => now),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Community story story-1'));
    await tester.tap(find.text('Community story story-1'));
    await tester.pumpAndSettle();

    expect(find.text('Post details story-1'), findsOneWidget);

    now = now.add(const Duration(seconds: 4));
    await tester.tap(find.byKey(const ValueKey('close-post-details')));
    await tester.pumpAndSettle();

    final dwellEvent = feedApi.trackedEvents.lastWhere(
      (event) => event.eventType == 'dwell' && event.postId == 'story-1',
    );
    expect(dwellEvent.communityId, 'community-1');
    expect(dwellEvent.metadata, containsPair('source', 'community_profile'));
    expect(
      dwellEvent.metadata,
      containsPair('dwellMs', greaterThanOrEqualTo(1000)),
    );
    expect(dwellEvent.metadata, containsPair('postProfileKey', 'article_v1'));
  });

  testWidgets('merges viewer community posts from mine list after reload', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi.pages(
      [const PostListPage(items: [], hasMore: false, total: 0)],
      myPages: [
        PostListPage(
          items: [_story('pending-mine', moderationStatus: 'PENDING')],
          hasMore: false,
          total: 1,
        ),
      ],
    );

    await tester.pumpWidget(_profileApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    expect(postApi.communityIds, ['community-1']);
    expect(postApi.mineCommunityIds, ['community-1']);
    await _scrollUntilVisible(
      tester,
      find.text('Community story pending-mine'),
    );
    expect(find.text('Community story pending-mine'), findsOneWidget);
  });

  testWidgets('renders quick posts as inline threads without opening details', (
    tester,
  ) async {
    PostVm? openedStory;
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi(
      stories: [_story('quick-1', postProfileKey: 'quick_post_v1')],
      commentsByPostId: {
        'quick-1': [_comment('comment-1', postId: 'quick-1', body: 'First!')],
      },
    );

    await tester.pumpWidget(
      _profileApp(
        feedApi,
        postApi: postApi,
        onStoryOpen: (story) {
          openedStory = story;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Community story quick-1'));
    final quickPostFinder = find.byKey(
      const ValueKey('quick-post-thread-quick-1'),
    );
    expect(quickPostFinder, findsOneWidget);
    final quickPostRect = tester.getRect(quickPostFinder);
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(quickPostRect.left, lessThanOrEqualTo(8));
    expect(screenWidth - quickPostRect.right, lessThanOrEqualTo(8));
    expect(find.text('First!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('quick-post-comment-field-quick-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Community story quick-1'));
    await tester.pumpAndSettle();

    expect(openedStory, isNull);
  });

  testWidgets('submits quick post inline comments from community feed', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi(
      stories: [_story('quick-1', postProfileKey: 'quick_post_v1')],
    );

    await tester.pumpWidget(_profileApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('quick-post-comment-field-quick-1')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('quick-post-comment-field-quick-1')),
      'Подскажите детали?',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('quick-post-comment-send-quick-1')),
    );
    await tester.pumpAndSettle();

    expect(postApi.createdComments, {'quick-1': 'Подскажите детали?'});
    expect(find.text('Подскажите детали?'), findsOneWidget);
    final commentEvent = feedApi.trackedEvents.lastWhere(
      (event) => event.eventType == 'comment' && event.postId == 'quick-1',
    );
    expect(commentEvent.communityId, 'community-1');
    expect(commentEvent.metadata, containsPair('action', 'comment'));
    expect(commentEvent.metadata, containsPair('engagementType', 'comment'));
    expect(
      commentEvent.metadata,
      containsPair('postProfileKey', 'quick_post_v1'),
    );
  });

  testWidgets('shows quick post views and toggles likes inline', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi(
      stories: [_story('quick-1', postProfileKey: 'quick_post_v1')],
    );

    await tester.pumpWidget(_profileApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('quick-post-like-quick-1')),
    );

    expect(
      find.byKey(const ValueKey('quick-post-views-quick-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-post-like-quick-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('quick-post-like-quick-1')));
    await tester.pumpAndSettle();

    expect(postApi.likedPostIds, ['quick-1']);
    final likeEvent = feedApi.trackedEvents.lastWhere(
      (event) => event.eventType == 'like' && event.postId == 'quick-1',
    );
    expect(likeEvent.communityId, 'community-1');
    expect(likeEvent.metadata, containsPair('action', 'like'));
    expect(likeEvent.metadata, containsPair('engagementType', 'like'));
    expect(likeEvent.metadata, containsPair('postProfileKey', 'quick_post_v1'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quick-post-like-quick-1')),
        matching: find.text('8'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tracks community post impressions after posts load', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi(
      stories: [_story('quick-1', postProfileKey: 'quick_post_v1')],
    );

    await tester.pumpWidget(_profileApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    expect(feedApi.trackedEvents, hasLength(1));
    final event = feedApi.trackedEvents.single;
    expect(event.eventType, 'impression');
    expect(event.blockType, 'post_card');
    expect(event.postId, 'quick-1');
    expect(event.communityId, 'community-1');
    expect(event.metadata['source'], 'community_profile');
  });

  testWidgets('places quick post metrics above the comment input', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi(
      stories: [_story('quick-1', postProfileKey: 'quick_post_v1')],
    );

    await tester.pumpWidget(_profileApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('quick-post-comment-field-quick-1')),
    );

    final metricsRow = find.byKey(
      const ValueKey('quick-post-engagement-row-quick-1'),
    );
    final commentField = find.byKey(
      const ValueKey('quick-post-comment-field-quick-1'),
    );

    expect(metricsRow, findsOneWidget);
    expect(
      tester.getBottomLeft(metricsRow).dy,
      lessThan(tester.getTopLeft(commentField).dy),
    );
  });

  testWidgets('loads more community posts to resolve initial post anchor', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(community: _community());
    final postApi = _FakePostApi.pages([
      PostListPage(
        items: [_story('story-1')],
        hasMore: true,
        total: 2,
        limit: 1,
        offset: 0,
      ),
      PostListPage(
        items: [_story('quick-2', postProfileKey: 'quick_post_v1')],
        hasMore: false,
        total: 2,
        limit: 1,
        offset: 1,
      ),
    ]);

    await tester.pumpWidget(
      _profileApp(feedApi, postApi: postApi, initialPostId: 'quick-2'),
    );
    await tester.pumpAndSettle();

    expect(postApi.offsets, [0, 1]);
    expect(
      find.byKey(const ValueKey('quick-post-thread-quick-2')),
      findsOneWidget,
    );
  });

  testWidgets('refreshes community posts after returning from post creation', (
    tester,
  ) async {
    final feedApi = _FakeFeedApi(
      community: _community(
        followedByViewer: true,
        postingPolicy: 'MEMBERS_AFTER_MODERATION',
      ),
    );
    final postApi = _FakePostApi.pages([
      PostListPage(items: [], hasMore: false, total: 0, limit: 10, offset: 0),
      PostListPage(
        items: [_story('created-post')],
        hasMore: false,
        total: 1,
        limit: 10,
        offset: 0,
      ),
    ]);

    await tester.pumpWidget(_profileRouterApp(feedApi, postApi: postApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Create post'));
    await tester.tap(find.text('Create post'));
    await tester.pumpAndSettle();

    expect(find.text('Create route'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish-create-post')));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.text('Community story created-post'),
    );
    expect(find.text('Community story created-post'), findsOneWidget);
    expect(postApi.communityIds, ['community-1', 'community-1']);
  });

  testWidgets(
    'shows seen community post state and keeps expiry independent from opens',
    (tester) async {
      PostVm? openedStory;
      final feedApi = _FakeFeedApi(community: _community());
      final storyApi = _FakePostApi(
        stories: [
          _story('seen-story', seenByViewer: true),
          _story('expired-story', expiresAt: DateTime.utc(2020)),
        ],
      );

      await tester.pumpWidget(
        _profileApp(
          feedApi,
          postApi: storyApi,
          onStoryOpen: (story) {
            openedStory = story;
          },
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.text('Community story seen-story'),
      );
      expect(
        find.byKey(const ValueKey('feed-post-card-seen-seen-story')),
        findsNothing,
      );
      await _scrollUntilVisible(
        tester,
        find.text('Community story expired-story'),
      );
      expect(find.text('Community story expired-story'), findsOneWidget);

      await tester.ensureVisible(find.text('Community story seen-story'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Community story seen-story'));
      await tester.pumpAndSettle();
      expect(openedStory?.id, 'seen-story');

      openedStory = null;
      await tester.ensureVisible(find.text('Community story expired-story'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Community story expired-story'));
      await tester.pumpAndSettle();

      expect(openedStory?.id, 'expired-story');
    },
  );

  testWidgets('loads more community posts near list bottom', (tester) async {
    final feedApi = _FakeFeedApi(community: _community(postCount: 2));
    final storyApi = _FakePostApi.pages([
      PostListPage(
        items: [_story('story-1')],
        hasMore: true,
        total: 2,
        limit: 1,
        offset: 0,
      ),
      PostListPage(
        items: [_story('story-2')],
        hasMore: false,
        total: 2,
        limit: 1,
        offset: 1,
      ),
    ]);

    await tester.pumpWidget(_profileApp(feedApi, postApi: storyApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Community story story-1'));
    expect(find.text('Community story story-1'), findsOneWidget);

    if (!tester.any(find.text('Community story story-2'))) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
    }

    expect(storyApi.offsets, [0, 1]);
    expect(find.text('Community story story-1'), findsOneWidget);
    expect(find.text('Community story story-2'), findsOneWidget);
  });

  testWidgets('shows empty state when community has no posts', (tester) async {
    final feedApi = _FakeFeedApi(community: _community(postCount: 0));
    final storyApi = _FakePostApi(stories: const []);

    await tester.pumpWidget(_profileApp(feedApi, postApi: storyApi));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('No posts yet'));

    expect(find.text('No posts yet'), findsOneWidget);
  });
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(ListView).first;
  for (var attempt = 0; attempt < 10 && !tester.any(finder); attempt += 1) {
    await tester.drag(scrollable, const Offset(0, -360));
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _scrollProfileToTop(WidgetTester tester) async {
  final scrollable = find.byType(ListView).first;
  final cover = find.byKey(const ValueKey('community-profile-cover'));
  for (var attempt = 0; attempt < 10 && !tester.any(cover); attempt += 1) {
    await tester.drag(scrollable, const Offset(0, 720));
    await tester.pumpAndSettle();
  }
  expect(cover, findsOneWidget);
  await tester.ensureVisible(cover);
  await tester.pumpAndSettle();
}

Widget _profileApp(
  FeedApi api, {
  FeedCommunityVm? initialCommunity,
  PostApi? postApi,
  TrustModerationActionsApi? trustApi,
  String? initialPostId,
  ValueChanged<FeedCommunityVm>? onCreatePost,
  ValueChanged<PostVm>? onStoryOpen,
  DateTime Function()? analyticsNow,
  bool authenticated = true,
}) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => authenticated
        ? _AuthenticatedAuthProvider()
        : _UnauthenticatedAuthProvider(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CommunityProfileScreen(
        communityId: 'community-1',
        initialCommunity: initialCommunity,
        feedApi: api,
        postApi: postApi ?? _FakePostApi(stories: const []),
        trustActionsApi: trustApi,
        initialPostId: initialPostId,
        onCreatePost: onCreatePost,
        onStoryOpen: onStoryOpen,
        analyticsNow: analyticsNow,
      ),
    ),
  );
}

Widget _profileRouterApp(
  FeedApi api, {
  PostApi? postApi,
  DateTime Function()? analyticsNow,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => CommunityProfileScreen(
          communityId: 'community-1',
          feedApi: api,
          postApi: postApi ?? _FakePostApi(stories: const []),
          analyticsNow: analyticsNow,
        ),
      ),
      GoRoute(
        path: '/posts/create',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('Create route'),
              ElevatedButton(
                key: const ValueKey('finish-create-post'),
                onPressed: () => context.pop(_story('created-post')),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/posts/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return Scaffold(
            body: Column(
              children: [
                Text('Post details $slug'),
                ElevatedButton(
                  key: const ValueKey('close-post-details'),
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => _AuthenticatedAuthProvider(),
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

PostVm _story(
  String id, {
  bool seenByViewer = false,
  DateTime? expiresAt,
  String? postProfileKey,
  String moderationStatus = 'NOT_REQUIRED',
}) {
  return PostVm(
    id: id,
    slug: id,
    title: 'Community story $id',
    excerpt: 'Community post excerpt',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    moderationStatus: moderationStatus,
    postProfileKey: postProfileKey,
    tags: const [],
    stats: PostStatsVm(views: 120, likes: 7, comments: 2, shares: 1),
    author: PostAuthorVm(
      userId: 'author-1',
      nickname: 'Author',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    seenAt: seenByViewer ? DateTime.utc(2026, 6, 12, 10) : null,
    expiresAt: expiresAt,
    shareUrl: 'https://inflap.test/stories/$id',
    communityId: 'community-1',
    createdAt: DateTime.utc(2026, 5, 10),
    updatedAt: DateTime.utc(2026, 5, 10),
  );
}

PostCommentVm _comment(
  String id, {
  required String postId,
  required String body,
}) {
  return PostCommentVm(
    id: id,
    postId: postId,
    body: body,
    editable: false,
    deletable: false,
    edited: false,
    likes: 0,
    likedByMe: false,
    shareUrl: 'https://inflap.test/posts/$postId?comment=$id',
    author: PostAuthorVm(
      userId: 'commenter-1',
      nickname: 'Commenter',
      locale: 'ru',
      timezone: 'Asia/Almaty',
    ),
    createdAt: DateTime.utc(2026, 6, 13, 12),
    updatedAt: DateTime.utc(2026, 6, 13, 12),
  );
}

FeedCommunityVm _community({
  String title = 'Investments',
  String? description = 'Investment conversations.',
  int membersCount = 42,
  int postCount = 12,
  bool followedByViewer = false,
  String postingPolicy = 'OPEN_MEMBERS',
  String defaultPostProfileKey = PostProfileKeys.article,
  List<String> allowedPostProfileKeys = const [],
  String? viewerRole,
  bool viewerCanModerate = false,
  String viewerTrustStatus = 'ACTIVE',
  String? viewerRestrictionId,
  bool mutedByViewer = false,
  String? topic = 'FINANCE',
  String? countryCode,
  String? cityId,
  String? cityName,
  List<String> rules = const [],
}) {
  return FeedCommunityVm(
    id: 'community-1',
    title: title,
    subtitle: description,
    description: description,
    topic: topic,
    countryCode: countryCode,
    cityId: cityId,
    cityName: cityName,
    membersCount: membersCount,
    postCount: postCount,
    followedByViewer: followedByViewer,
    postingPolicy: postingPolicy,
    defaultPostProfileKey: defaultPostProfileKey,
    allowedPostProfileKeys: allowedPostProfileKeys,
    viewerRole: viewerRole,
    viewerCanModerate: viewerCanModerate,
    viewerTrustStatus: viewerTrustStatus,
    viewerRestrictionId: viewerRestrictionId,
    mutedByViewer: mutedByViewer,
    rules: rules,
  );
}

class _FakeTrustModerationActionsApi implements TrustModerationActionsApi {
  _FakeTrustModerationActionsApi({this.reportError});

  final Object? reportError;
  TrustReportContentRequest? reportRequest;
  TrustMuteTargetRequest? muteTargetRequest;
  TrustMuteTargetRequest? unmuteTargetRequest;
  TrustMuteUserRequest? muteUserRequest;
  TrustMuteUserRequest? unmuteUserRequest;
  TrustRestrictionAppealRequest? appealRequest;

  @override
  Future<void> reportContent(TrustReportContentRequest request) async {
    final error = reportError;
    if (error != null) {
      throw error;
    }
    reportRequest = request;
  }

  @override
  Future<void> muteTarget(TrustMuteTargetRequest request) async {
    muteTargetRequest = request;
  }

  @override
  Future<void> unmuteTarget(TrustMuteTargetRequest request) async {
    unmuteTargetRequest = request;
  }

  @override
  Future<void> muteUser(TrustMuteUserRequest request) async {
    muteUserRequest = request;
  }

  @override
  Future<void> unmuteUser(TrustMuteUserRequest request) async {
    unmuteUserRequest = request;
  }

  @override
  Future<void> appealRestriction(TrustRestrictionAppealRequest request) async {
    appealRequest = request;
  }
}

class _FakeFeedApi implements FeedApi {
  _FakeFeedApi({required this.community});

  FeedCommunityVm community;
  final List<String> loadedCommunityIds = [];
  final List<String> followedCommunityIds = [];
  final List<String> unfollowedCommunityIds = [];
  final List<FeedEventRequest> trackedEvents = [];

  @override
  Future<FeedCommunityVm> getCommunity(String communityId) async {
    loadedCommunityIds.add(communityId);
    return community;
  }

  @override
  Future<FeedCommunityVm> followCommunity(String communityId) async {
    followedCommunityIds.add(communityId);
    community = community.copyWith(
      followedByViewer: true,
      membersCount: community.membersCount + 1,
    );
    return community;
  }

  @override
  Future<FeedCommunityVm> unfollowCommunity(String communityId) async {
    unfollowedCommunityIds.add(communityId);
    community = community.copyWith(
      followedByViewer: false,
      membersCount: community.membersCount - 1,
    );
    return community;
  }

  @override
  Future<CommunityListPageVm> listCommunities({
    String? topic,
    String? countryCode,
    String? cityId,
    String? search,
    bool excludeFollowed = false,
    bool onlyFollowed = false,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FeedPageVm> getFeed({
    String surface = 'home',
    String tab = 'for_you',
    String? cursor,
    String? countryCode,
    String? cityId,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> trackFeedEvents(List<FeedEventRequest> events) {
    trackedEvents.addAll(events);
    return Future.value(events.length);
  }
}

class _FakePostApi extends PostApi {
  _FakePostApi({
    required List<PostVm> stories,
    this.commentsByPostId = const {},
  }) : pages = [
         PostListPage(
           items: stories,
           hasMore: false,
           total: stories.length,
           limit: stories.length,
           offset: 0,
         ),
       ],
       myPages = const [];

  _FakePostApi.pages(this.pages, {this.myPages = const []})
    : commentsByPostId = const {};

  final List<PostListPage> pages;
  final List<PostListPage> myPages;
  final Map<String, List<PostCommentVm>> commentsByPostId;
  final List<String?> communityIds = [];
  final List<String?> mineCommunityIds = [];
  final List<int> offsets = [];
  final List<int> limits = [];
  final List<int> mineOffsets = [];
  final Map<String, String> createdComments = {};
  final List<String> likedPostIds = [];
  final List<String> unlikedPostIds = [];

  @override
  Future<PostCreateEligibilityVm> checkCreateEligibility() async {
    return const PostCreateEligibilityVm(
      canCreate: true,
      limit: 10,
      remaining: 10,
      window: Duration(hours: 1),
      retryAfter: Duration.zero,
    );
  }

  @override
  Future<PostListPage> listPostsPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    int limit = 20,
    int offset = 0,
    String? authorId,
    String? communityId,
  }) async {
    communityIds.add(communityId);
    offsets.add(offset);
    limits.add(limit);
    final index = offsets.length - 1;
    if (index >= pages.length) {
      return PostListPage(
        items: const [],
        hasMore: false,
        total: pages.fold<int>(0, (value, page) => value + page.items.length),
        limit: limit,
        offset: offset,
      );
    }
    return pages[index];
  }

  @override
  Future<PostListPage> listMyPostsPage({
    String? search,
    List<String>? formats,
    List<String>? categories,
    List<String>? moderationStatuses,
    String? place,
    String? countryCode,
    String? cityId,
    String? sort,
    String? status,
    String? communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    mineCommunityIds.add(communityId);
    mineOffsets.add(offset);
    final index = mineOffsets.length - 1;
    if (index >= myPages.length) {
      return PostListPage(
        items: const [],
        hasMore: false,
        total: myPages.fold<int>(0, (value, page) => value + page.items.length),
        limit: limit,
        offset: offset,
      );
    }
    return myPages[index];
  }

  @override
  Future<List<PostCommentVm>> listComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final comments = commentsByPostId[postId] ?? const <PostCommentVm>[];
    return comments.skip(offset).take(limit).toList(growable: false);
  }

  @override
  Future<PostCommentVm> createComment(String postId, String body) async {
    createdComments[postId] = body.trim();
    return _comment(
      'created-${createdComments.length}',
      postId: postId,
      body: body.trim(),
    );
  }

  @override
  Future<int> likePost(String postId) async {
    likedPostIds.add(postId);
    return 8;
  }

  @override
  Future<int> unlikePost(String postId) async {
    unlikedPostIds.add(postId);
    return 7;
  }
}

class _AuthenticatedAuthProvider extends AuthProvider {
  _AuthenticatedAuthProvider() : super(secureStorage: _TestSecureStorage());

  @override
  AuthState get state => AuthState.authenticated;
}

class _UnauthenticatedAuthProvider extends AuthProvider {
  _UnauthenticatedAuthProvider() : super(secureStorage: _TestSecureStorage());

  @override
  AuthState get state => AuthState.unauthenticated;
}

class _TestSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => 'refresh-token';
}
