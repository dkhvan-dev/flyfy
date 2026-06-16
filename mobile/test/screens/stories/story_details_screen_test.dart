import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/file_api.dart';
import 'package:inflap/core/network/post_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/feed/data/feed_api.dart';
import 'package:inflap/features/profile/data/profile_api.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/stories/story_details_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('StoryDetailsScreen', () {
    testWidgets('draft story images open through render-safe story media', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'draft-story',
            fileApi: _FakeStoryFileApi(),
            initialStory: _storyVm(
              status: 'DRAFT',
              contentBlocks: const [
                {
                  'id': 'image-1',
                  'type': 'image',
                  'image': {'fileId': 'story-inline-file-1'},
                },
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final image = find.byKey(
        const ValueKey('story-document-image-story-inline-file-1-0'),
      );
      await tester.ensureVisible(image);
      await tester.pump();
      await tester.tap(image);
      await tester.pump();

      final fullscreenImages = tester.widgetList<Image>(find.byType(Image));
      expect(
        fullscreenImages.any(
          (image) =>
              image.fit == BoxFit.contain &&
              image.width == null &&
              image.height == null,
        ),
        isTrue,
      );
      expect(find.byType(FutureBuilder<FileContentVm>), findsNothing);
    });

    testWidgets('draft story hides comments and related stories sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'draft-story',
            fileApi: _FakeStoryFileApi(),
            initialStory: _storyVm(status: 'DRAFT'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Leave a thoughtful comment'), findsNothing);
      expect(
        find.text('No comments yet. Start the conversation.'),
        findsNothing,
      );
      expect(find.text('Related Stories'), findsNothing);
      expect(find.text('No related stories yet'), findsNothing);
    });

    testWidgets(
      'fullscreen story gallery supports swipe navigation and close',
      (tester) async {
        await tester.pumpWidget(
          _app(
            StoryDetailsScreen(
              slug: 'draft-story',
              fileApi: _FakeStoryFileApi(),
              initialStory: _storyVm(
                status: 'DRAFT',
                contentBlocks: const [
                  {
                    'id': 'gallery-1',
                    'type': 'gallery',
                    'gallery': {
                      'images': [
                        {'fileId': 'story-inline-file-1'},
                        {'fileId': 'story-inline-file-2'},
                      ],
                    },
                  },
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        final firstImage = find.byKey(
          const ValueKey('story-document-image-story-inline-file-1-0'),
        );
        await tester.ensureVisible(firstImage);
        await tester.pump();
        await tester.tap(firstImage);
        await tester.pump();

        expect(find.text('1/2'), findsOneWidget);

        await tester.drag(find.text('1/2'), const Offset(-260, 0));
        await tester.pump();

        expect(find.text('2/2'), findsOneWidget);

        await tester.drag(find.text('2/2'), const Offset(0, 280));
        await tester.pumpAndSettle();

        expect(find.text('2/2'), findsNothing);
        expect(firstImage, findsOneWidget);
      },
    );

    testWidgets('published story submits a moderation report', (tester) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
          ),
          related: const [],
          comments: const [],
        ),
      );
      final feedApi = _FakeFeedApi();

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            feedApi: feedApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Report'));
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('story-report-details-field')),
        'Copied listing',
      );
      await tester.ensureVisible(find.text('Submit report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();

      expect(storyApi.reportedStoryIds, ['published-story']);
      expect(storyApi.reportedReasons, ['SPAM']);
      expect(storyApi.reportedDetails, ['Copied listing']);
      final reportEvent = feedApi.trackedEvents.singleWhere(
        (event) => event.eventType == FeedEventTypes.report,
      );
      expect(reportEvent.surface, 'content');
      expect(reportEvent.tab, 'details');
      expect(reportEvent.blockType, 'post_card');
      expect(reportEvent.postId, 'published-story');
      expect(reportEvent.metadata, containsPair('source', 'post_details'));
      expect(reportEvent.metadata, containsPair('entityType', 'post'));
      expect(reportEvent.metadata, containsPair('entityId', 'published-story'));
      expect(reportEvent.metadata, containsPair('feedbackType', 'report'));
      expect(reportEvent.metadata, containsPair('reason', 'SPAM'));
      expect(reportEvent.metadata, containsPair('categorySlug', 'journal'));
      expect(reportEvent.metadata, containsPair('countryCode', 'KZ'));
      expect(reportEvent.metadata, containsPair('cityId', 'almaty'));
      expect(
        find.text('Thanks. We sent this post to moderation.'),
        findsOneWidget,
      );
    });

    testWidgets('published story tracks like share and comment events', (
      tester,
    ) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
          ),
          related: const [],
          comments: const [],
        ),
      );
      final feedApi = _FakeFeedApi();

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            feedApi: feedApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Likes'));
      await tester.tap(find.text('Likes'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Great tip');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(storyApi.likedStoryIds, ['published-story']);
      expect(storyApi.createdComments, ['Great tip']);
      expect(storyApi.sharedStoryIds, ['published-story']);

      final likeEvent = feedApi.trackedEvents.singleWhere(
        (event) => event.eventType == FeedEventTypes.like,
      );
      expect(likeEvent.postId, 'published-story');
      expect(likeEvent.metadata, containsPair('source', 'post_details'));
      expect(likeEvent.metadata, containsPair('engagementType', 'like'));

      final commentEvent = feedApi.trackedEvents.singleWhere(
        (event) => event.eventType == FeedEventTypes.comment,
      );
      expect(commentEvent.postId, 'published-story');
      expect(commentEvent.metadata, containsPair('source', 'post_details'));
      expect(commentEvent.metadata, containsPair('engagementType', 'comment'));
      expect(commentEvent.metadata, containsPair('commentId', 'comment-1'));

      final shareEvent = feedApi.trackedEvents.singleWhere(
        (event) => event.eventType == FeedEventTypes.share,
      );
      expect(shareEvent.postId, 'published-story');
      expect(shareEvent.metadata, containsPair('source', 'post_details'));
      expect(shareEvent.metadata, containsPair('engagementType', 'share'));
      expect(
        shareEvent.metadata,
        containsPair('shareUrl', 'https://flyfy.test/posts/published-story'),
      );
    });

    testWidgets('published story marks authenticated viewer as seen', (
      tester,
    ) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
          ),
          related: const [],
          comments: const [],
        ),
      );

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(storyApi.seenStoryIds, ['published-story']);
    });

    testWidgets('published story skips mark seen for guest viewer', (
      tester,
    ) async {
      final authProvider = AuthProvider(
        secureStorage: _UnauthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
          ),
          related: const [],
          comments: const [],
        ),
      );

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(storyApi.seenStoryIds, isEmpty);
    });

    testWidgets('published story skips mark seen for already seen story', (
      tester,
    ) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
            seenByViewer: true,
          ),
          related: const [],
          comments: const [],
        ),
      );

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(storyApi.seenStoryIds, isEmpty);
    });

    testWidgets(
      'published story skips mark seen for expired or empty-id story',
      (tester) async {
        final authProvider = AuthProvider(
          secureStorage: _AuthenticatedSecureStorage(),
        );
        await authProvider.checkAuthStatus();
        final expiredApi = _FakePostApi(
          detail: PostDetailVm(
            post: _storyVm(
              id: 'expired-story',
              title: 'Expired story',
              status: 'PUBLISHED',
              expiresAt: DateTime.utc(2020),
            ),
            related: const [],
            comments: const [],
          ),
        );

        await tester.pumpWidget(
          _app(
            StoryDetailsScreen(
              slug: 'expired-story',
              postApi: expiredApi,
              profileApi: _FakeProfileApi(),
              initialStory: _storyVm(
                id: 'expired-story',
                title: 'Expired story',
                status: 'PUBLISHED',
              ),
            ),
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        expect(expiredApi.seenStoryIds, isEmpty);

        final emptyIdApi = _FakePostApi(
          detail: PostDetailVm(
            post: _storyVm(
              id: '',
              title: 'Empty id story',
              status: 'PUBLISHED',
            ),
            related: const [],
            comments: const [],
          ),
        );

        await tester.pumpWidget(
          _app(
            StoryDetailsScreen(
              slug: 'empty-id-story',
              postApi: emptyIdApi,
              profileApi: _FakeProfileApi(),
              initialStory: _storyVm(
                id: 'empty-id-story',
                title: 'Empty id story',
                status: 'PUBLISHED',
              ),
            ),
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        expect(emptyIdApi.seenStoryIds, isEmpty);
      },
    );

    testWidgets('published story mark seen failure does not block rendering', (
      tester,
    ) async {
      final authProvider = AuthProvider(
        secureStorage: _AuthenticatedSecureStorage(),
      );
      await authProvider.checkAuthStatus();
      final storyApi = _FakePostApi(
        failMarkSeen: true,
        detail: PostDetailVm(
          post: _storyVm(
            id: 'published-story',
            title: 'Published story',
            status: 'PUBLISHED',
          ),
          related: const [],
          comments: const [],
        ),
      );

      await tester.pumpWidget(
        _app(
          StoryDetailsScreen(
            slug: 'published-story',
            postApi: storyApi,
            profileApi: _FakeProfileApi(),
            initialStory: _storyVm(
              id: 'published-story',
              title: 'Published story',
              status: 'PUBLISHED',
            ),
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(storyApi.seenStoryIds, ['published-story']);
      expect(find.text('Published story'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(Widget child, {AuthProvider? authProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) =>
            authProvider ??
            AuthProvider(secureStorage: _UnauthenticatedSecureStorage()),
      ),
      ChangeNotifierProvider<SessionProvider>(create: (_) => SessionProvider()),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _AuthenticatedSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _UnauthenticatedSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;
}

class _FakeStoryFileApi extends FileApi {
  @override
  Future<FileContentVm> downloadContent(String fileId) async {
    return FileContentVm(
      bytes: Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
        ),
      ),
      contentType: 'image/png',
    );
  }
}

class _FakePostApi extends PostApi {
  _FakePostApi({required this.detail, this.failMarkSeen = false});

  final PostDetailVm detail;
  final bool failMarkSeen;
  final List<String> reportedStoryIds = [];
  final List<String> reportedReasons = [];
  final List<String> reportedDetails = [];
  final List<String> seenStoryIds = [];
  final List<String> likedStoryIds = [];
  final List<String> unlikedStoryIds = [];
  final List<String> sharedStoryIds = [];
  final List<String> createdComments = [];

  @override
  Future<PostDetailVm> getPublicPostBySlug(String slug) async => detail;

  @override
  Future<DateTime?> markPostSeen(String storyId) async {
    seenStoryIds.add(storyId);
    if (failMarkSeen) {
      throw Exception('mark seen failed');
    }
    return DateTime.utc(2026, 6, 12, 12);
  }

  @override
  Future<PostReportSubmissionVm> reportPost(
    String storyId, {
    required String reason,
    String details = '',
  }) async {
    reportedStoryIds.add(storyId);
    reportedReasons.add(reason);
    reportedDetails.add(details);
    return PostReportSubmissionVm(
      openReportsCount: 1,
      autoHidden: false,
      reportId: 'report-1',
      reportStatus: 'OPEN',
    );
  }

  @override
  Future<int> likePost(String storyId) async {
    likedStoryIds.add(storyId);
    return 1;
  }

  @override
  Future<int> unlikePost(String storyId) async {
    unlikedStoryIds.add(storyId);
    return 0;
  }

  @override
  Future<PostCommentVm> createComment(String storyId, String body) async {
    createdComments.add(body);
    return PostCommentVm(
      id: 'comment-1',
      postId: storyId,
      body: body,
      editable: true,
      deletable: true,
      edited: false,
      likes: 0,
      likedByMe: false,
      shareUrl: '',
      author: detail.post.author,
      createdAt: DateTime.utc(2026, 6, 12, 13),
      updatedAt: DateTime.utc(2026, 6, 12, 13),
    );
  }

  @override
  Future<(String shareUrl, int shares)> sharePost(String storyId) async {
    sharedStoryIds.add(storyId);
    return ('https://flyfy.test/posts/$storyId', 1);
  }
}

class _FakeFeedApi extends FeedApi {
  final List<FeedEventRequest> trackedEvents = [];

  @override
  Future<int> trackFeedEvents(List<FeedEventRequest> events) async {
    trackedEvents.addAll(events);
    return events.length;
  }
}

class _FakeProfileApi extends ProfileApi {
  @override
  Future<UserProfileVm> getUserById(String userId) async {
    return UserProfileVm(
      userId: userId,
      status: 'ACTIVE',
      locale: 'en',
      timezone: 'Asia/Almaty',
      isProfileCompleted: true,
      roles: const [],
      followersCount: 12,
      isFollowedByMe: false,
      friendshipStatus: UserFriendshipStatus.none,
      nickname: 'Travel Author',
    );
  }
}

PostVm _storyVm({
  String id = 'story-1',
  String title = 'Draft story',
  String status = 'DRAFT',
  bool seenByViewer = false,
  DateTime? expiresAt,
  List<Map<String, dynamic>> contentBlocks = const [],
}) {
  return PostVm(
    id: id,
    slug: id,
    title: title,
    excerpt: '',
    content: '',
    format: 'STORY',
    contentBlocks: contentBlocks,
    revision: 1,
    category: 'JOURNAL',
    status: status,
    coverFileId: null,
    placeName: 'Almaty',
    placeCountryCode: 'KZ',
    placeCityId: 'almaty',
    tags: const ['mountains'],
    stats: PostStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    seenByViewer: seenByViewer,
    seenAt: seenByViewer ? DateTime.utc(2026, 6, 12, 12) : null,
    expiresAt: expiresAt,
    shareUrl: '',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 8),
  );
}
