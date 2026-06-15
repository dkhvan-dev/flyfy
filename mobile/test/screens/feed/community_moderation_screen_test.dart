import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/data/community_moderation_api.dart';
import 'package:inflap/features/feed/models/community_moderation_vm.dart';
import 'package:inflap/features/feed/presentation/community_moderation_screen.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('loads moderation queue and approves a pending story', (
    tester,
  ) async {
    final api = _FakeCommunityModerationApi(
      initialStories: [_story(id: 'story-1', title: 'AI route notes')],
    );

    await tester.pumpWidget(_moderationApp(api));
    await tester.pumpAndSettle();

    expect(api.listCalls, ['community-1:0']);
    expect(find.text('Moderation queue'), findsOneWidget);
    expect(find.text('AI route notes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('approve-story-1')));
    await tester.pumpAndSettle();

    expect(api.approvedPostIds, ['story-1']);
    expect(find.text('AI route notes'), findsNothing);
    expect(find.text('Post approved'), findsOneWidget);
  });

  testWidgets('rejects a pending story with moderator reason', (tester) async {
    final api = _FakeCommunityModerationApi(
      initialStories: [_story(id: 'story-2', title: 'Off-topic promo')],
    );

    await tester.pumpWidget(_moderationApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reject-story-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reject-reason-field')),
      'Not relevant to this community',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-reject-story-2')));
    await tester.pumpAndSettle();

    expect(api.rejectedStories, {'story-2': 'Not relevant to this community'});
    expect(find.text('Off-topic promo'), findsNothing);
    expect(find.text('Post rejected'), findsOneWidget);
  });

  testWidgets('opens moderation decision history for a story', (tester) async {
    final api = _FakeCommunityModerationApi(
      initialStories: [_story(id: 'story-3', title: 'Investment guide')],
      decisions: {
        'story-3': [
          PostModerationDecisionVm(
            id: 'decision-1',
            postId: 'story-3',
            communityId: 'community-1',
            moderatorUserId: 'moderator-1',
            decision: 'APPROVE',
            previousStatus: 'PENDING',
            nextStatus: 'APPROVED',
            postRevision: 3,
            reason: 'Useful and clear',
            createdAt: DateTime.utc(2026, 6, 11, 10),
          ),
        ],
      },
    );

    await tester.pumpWidget(_moderationApp(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-story-3')));
    await tester.pumpAndSettle();

    expect(api.decisionCalls, ['story-3']);
    expect(find.text('Decision history'), findsOneWidget);
    expect(find.text('APPROVE'), findsOneWidget);
    expect(find.text('Useful and clear'), findsOneWidget);
  });

  testWidgets('renders error state and retries queue loading', (tester) async {
    var attempts = 0;
    final api = _FakeCommunityModerationApi(
      onList: ({required communityId, required limit, required offset}) {
        attempts += 1;
        if (attempts == 1) {
          return Future<CommunityModerationPostPageVm>.error(
            Exception('network down'),
          );
        }
        return Future.value(
          CommunityModerationPostPageVm(
            items: [_story(id: 'story-4', title: 'Recovered post')],
            limit: limit,
            offset: offset,
          ),
        );
      },
    );

    await tester.pumpWidget(_moderationApp(api));
    await tester.pumpAndSettle();

    expect(find.text('Could not load moderation queue'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered post'), findsOneWidget);
  });

  testWidgets('renders on narrow width without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeCommunityModerationApi(
      initialStories: [
        _story(
          id: 'story-5',
          title: 'A very long localized post title that should not overflow',
        ),
      ],
    );

    await tester.pumpWidget(_moderationApp(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('very long localized'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _moderationApp(CommunityModerationApi api) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CommunityModerationScreen(
      communityId: 'community-1',
      communityTitle: 'Investments',
      moderationApi: api,
    ),
  );
}

PostVm _story({required String id, required String title}) {
  final now = DateTime.utc(2026, 1, 1);
  return PostVm(
    id: id,
    slug: id,
    title: title,
    excerpt: 'A compact route for a slow travel day.',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    moderationStatus: 'PENDING',
    tags: const ['travel'],
    stats: PostStatsVm(views: 42, likes: 7, comments: 3, shares: 1),
    author: PostAuthorVm(
      userId: 'author-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: 'Aigerim',
    ),
    likedByViewer: false,
    shareUrl: 'https://inflap.test/stories/$id',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCommunityModerationApi implements CommunityModerationApi {
  _FakeCommunityModerationApi({
    List<PostVm> initialStories = const [],
    this.decisions = const {},
    this.onList,
  }) : _stories = [...initialStories];

  final List<PostVm> _stories;
  final Map<String, List<PostModerationDecisionVm>> decisions;
  final Future<CommunityModerationPostPageVm> Function({
    required String communityId,
    required int limit,
    required int offset,
  })?
  onList;

  final List<String> listCalls = [];
  final List<String> approvedPostIds = [];
  final Map<String, String> rejectedStories = {};
  final List<String> decisionCalls = [];

  @override
  Future<CommunityModerationPostPageVm> listPendingPosts({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    listCalls.add('$communityId:$offset');
    final handler = onList;
    if (handler != null) {
      return handler(communityId: communityId, limit: limit, offset: offset);
    }
    return CommunityModerationPostPageVm(
      items: _stories,
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<PostVm> approvePost({
    required String communityId,
    required String postId,
    String? reason,
  }) async {
    approvedPostIds.add(postId);
    final story = _removeStory(postId);
    return story.copyWith(moderationStatus: 'APPROVED');
  }

  @override
  Future<PostVm> rejectPost({
    required String communityId,
    required String postId,
    String? reason,
  }) async {
    rejectedStories[postId] = reason ?? '';
    final story = _removeStory(postId);
    return story.copyWith(moderationStatus: 'REJECTED');
  }

  @override
  Future<PostModerationDecisionPageVm> listPostDecisions({
    required String communityId,
    required String postId,
    int limit = 20,
    int offset = 0,
  }) async {
    decisionCalls.add(postId);
    return PostModerationDecisionPageVm(
      items: decisions[postId] ?? const [],
      limit: limit,
      offset: offset,
      hasMore: false,
    );
  }

  @override
  Future<CommunityMemberPageVm> listMembers({
    required String communityId,
    String? role,
    String? status,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CommunityMembershipVm> updateMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CommunityMembershipVm> updateMemberStatus({
    required String communityId,
    required String userId,
    required String status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CommunityMemberRoleChangePageVm> listMemberRoleChanges({
    required String communityId,
    required String userId,
    int limit = 20,
    int offset = 0,
  }) {
    throw UnimplementedError();
  }

  PostVm _removeStory(String postId) {
    final index = _stories.indexWhere((story) => story.id == postId);
    if (index < 0) {
      throw StateError('Missing story $postId');
    }
    return _stories.removeAt(index);
  }
}
