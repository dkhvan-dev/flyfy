import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/core/network/story_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/chat/models/message_vm.dart';
import 'package:inflap/features/stories/models/story_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/auth_provider.dart';
import 'package:inflap/screens/stories/story_tray_viewer_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('marks authenticated viewer seen for current and next story', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      secureStorage: _AuthenticatedSecureStorage(),
    );
    await authProvider.checkAuthStatus();
    final storyApi = _FakeStoryApi();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StoryTrayViewerScreen(
            storyApi: storyApi,
            data: StoryTrayViewerRouteData(
              stories: [_story('one'), _story('two')],
              initialIndex: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(storyApi.seenStoryIds, ['one']);
    expect(
      find.byKey(const ValueKey('story-sequence-title-one')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-sequence-next')));
    await tester.pump();
    await tester.pump();

    expect(storyApi.seenStoryIds, ['one', 'two']);
    expect(
      find.byKey(const ValueKey('story-sequence-title-two')),
      findsOneWidget,
    );
  });

  testWidgets('auto-advances but pauses while the viewer is long pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 2),
          data: StoryTrayViewerRouteData(
            stories: [_story('one'), _story('two')],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('story-sequence-next'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(seconds: 3));

    expect(
      find.byKey(const ValueKey('story-sequence-title-one')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2200));

    expect(
      find.byKey(const ValueKey('story-sequence-title-two')),
      findsOneWidget,
    );
  });

  testWidgets('previous tap on the first story keeps auto-advance running', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 1),
          data: StoryTrayViewerRouteData(
            stories: [_story('one'), _story('two')],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-sequence-previous')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(
      find.byKey(const ValueKey('story-sequence-title-two')),
      findsOneWidget,
    );
  });

  testWidgets('swipe down closes the viewer and returns seen ids', (
    tester,
  ) async {
    Set<String>? seenStoryIds;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                seenStoryIds = await Navigator.of(context).push<Set<String>>(
                  MaterialPageRoute(
                    builder: (_) => StoryTrayViewerScreen(
                      storyDuration: const Duration(seconds: 30),
                      data: StoryTrayViewerRouteData(stories: [_story('one')]),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.drag(
      find.byKey(const ValueKey('story-sequence-viewer')),
      const Offset(0, 360),
    );
    await tester.pumpAndSettle();

    expect(seenStoryIds, contains('one'));
    expect(find.byKey(const ValueKey('story-sequence-viewer')), findsNothing);
  });

  testWidgets('sends story replies to a direct chat with story context', (
    tester,
  ) async {
    final chatApi = _FakeChatApi();
    final story = _story(
      'one',
      title: 'Morning route',
      expiresAt: DateTime.utc(2027),
    ).copyWith(coverFileId: 'cover-one');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          chatApi: chatApi,
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(stories: [story]),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('story-sequence-reply-field')),
      'Looks great',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-sequence-send-reply')));
    await tester.pump();

    expect(chatApi.directRecipientIds, ['user-one']);
    expect(chatApi.sentConversationIds, ['direct-user-one']);
    expect(chatApi.sentContents, ['Looks great']);
    expect(chatApi.sentStoryReplies.single?.storyId, 'one');
    expect(chatApi.sentStoryReplies.single?.storyAuthorUserId, 'user-one');
    expect(chatApi.sentStoryReplies.single?.storyTitle, 'Morning route');
    expect(chatApi.sentStoryReplies.single?.storyPreviewFileId, 'cover-one');
  });

  testWidgets('sends story like from the reply composer heart button', (
    tester,
  ) async {
    final storyApi = _FakeStoryApi();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyApi: storyApi,
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(stories: [_story('one')]),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-sequence-like-story')));
    await tester.pump();

    expect(storyApi.likedStoryIds, ['one']);
    final Icon icon = tester.widget(
      find.descendant(
        of: find.byKey(const ValueKey('story-sequence-like-story')),
        matching: find.byIcon(Icons.favorite_rounded),
      ),
    );
    expect(icon.icon, Icons.favorite_rounded);

    await tester.tap(find.byKey(const ValueKey('story-sequence-like-story')));
    await tester.pump();

    expect(storyApi.likedStoryIds, ['one']);
  });

  testWidgets('empty root viewer close falls back to feed', (tester) async {
    final router = GoRouter(
      initialLocation: '/stories/viewer',
      routes: [
        GoRoute(
          path: '/stories/viewer',
          builder: (context, state) => const StoryTrayViewerScreen(
            data: StoryTrayViewerRouteData(stories: []),
          ),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) =>
              const Scaffold(body: Text('Feed fallback')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-sequence-close')));
    await tester.pumpAndSettle();

    expect(find.text('Feed fallback'), findsOneWidget);
  });

  testWidgets('caps progress indicators around the current story', (
    tester,
  ) async {
    final stories = [
      for (var index = 0; index < 12; index++) _story('story-$index'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(stories: stories, initialIndex: 6),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
    expect(
      find.byKey(const ValueKey('story-sequence-progress-story-6')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('story-sequence-progress-story-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('story-sequence-progress-story-11')),
      findsNothing,
    );
  });

  testWidgets(
    'keeps metadata below top controls on compact large text screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            );
          },
          home: StoryTrayViewerScreen(
            storyDuration: const Duration(seconds: 30),
            data: StoryTrayViewerRouteData(
              stories: [
                _story(
                  'compact',
                  title:
                      'A very long localized story title for compact screens',
                  excerpt:
                      'A long preview that simulates verbose translated copy, '
                      'larger accessibility fonts, and a very small viewport.',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final closeBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('story-sequence-close')))
          .dy;
      final metadataTop = tester
          .getTopLeft(find.byKey(const ValueKey('story-sequence-metadata')))
          .dy;
      final replyBottom = tester
          .getBottomLeft(
            find.byKey(const ValueKey('story-sequence-reply-field')),
          )
          .dy;

      expect(metadataTop, greaterThan(closeBottom + 8));
      expect(replyBottom, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('handles very short compact screens without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          );
        },
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(
            stories: [
              _story(
                'ultra-compact',
                title: 'Very small viewport story',
                excerpt: 'Still keeps controls reachable.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('story-sequence-viewer')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-sequence-close')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps selected story after filtering expired tray items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(
            stories: [
              _story('expired-before-selected', expiresAt: DateTime.utc(2020)),
              _story('target'),
              _story('other'),
            ],
            initialIndex: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('story-sequence-title-target')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('story-sequence-title-other')),
      findsNothing,
    );
  });

  testWidgets('viewer can be disposed before deferred startup completes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoryTrayViewerScreen(
          storyDuration: const Duration(seconds: 30),
          data: StoryTrayViewerRouteData(stories: [_story('one')]),
        ),
      ),
      phase: EnginePhase.build,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

class _AuthenticatedSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _FakeStoryApi extends StoryApi {
  final List<String> seenStoryIds = [];
  final List<String> likedStoryIds = [];

  @override
  Future<DateTime?> markStorySeen(String storyId) async {
    seenStoryIds.add(storyId);
    return DateTime.utc(2026, 6, 12, 12);
  }

  @override
  Future<int> likeStory(String storyId) async {
    likedStoryIds.add(storyId);
    return likedStoryIds.length;
  }
}

class _FakeChatApi extends ChatApi {
  final List<String> directRecipientIds = [];
  final List<String> sentConversationIds = [];
  final List<String> sentContents = [];
  final List<StoryReplyContextVm?> sentStoryReplies = [];

  @override
  Future<String> createDirectConversation(String participantUserId) async {
    directRecipientIds.add(participantUserId);
    return 'direct-$participantUserId';
  }

  @override
  Future<MessageVm> sendMessage(
    String conversationId, {
    required String content,
    String type = 'text',
    List<String>? fileIds,
    String? stickerId,
    String? replyToMessageId,
    String? clientMessageId,
    StoryReplyContextVm? storyReply,
  }) async {
    sentConversationIds.add(conversationId);
    sentContents.add(content);
    sentStoryReplies.add(storyReply);
    return MessageVm(
      id: 'message-1',
      senderUserId: 'viewer',
      senderDisplayName: 'Viewer',
      type: type,
      content: content,
      storyReply: storyReply,
      sentAt: DateTime.utc(2026, 6, 12),
    );
  }
}

StoryVm _story(
  String id, {
  String? title,
  String? excerpt,
  DateTime? expiresAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return StoryVm(
    id: id,
    slug: id,
    title: title ?? id,
    excerpt: excerpt ?? 'Story $id',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const ['travel'],
    stats: StoryStatsVm(views: 1, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: 'user-$id',
      locale: 'en',
      timezone: 'Asia/Almaty',
      nickname: 'Author $id',
    ),
    likedByViewer: false,
    expiresAt: expiresAt ?? DateTime.utc(2027),
    shareUrl: 'https://inflap.test/stories/$id',
    createdAt: now,
    updatedAt: now,
  );
}
