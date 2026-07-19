import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/feed/widgets/post_saved_bookmark_button.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/shared/widgets/app_saved_bookmark_button.dart';
import 'package:provider/provider.dart';

import '../../saved/support/saved_test_fakes.dart';

void main() {
  testWidgets('published post exposes canonical POST Saved target', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final controller = SavedScreenController(repository: repository);
    final session = _AuthenticatedSessionProvider();
    addTearDown(controller.dispose);
    addTearDown(session.dispose);
    final post = _post();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<SavedScreenController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostSavedBookmarkButton(
              post: post,
              sourceSurface: SavedSourceSurface.detail,
            ),
          ),
        ),
      ),
    );

    final bookmark = tester.widget<AppSavedBookmarkButton>(
      find.byType(AppSavedBookmarkButton),
    );
    expect(bookmark.target.entityType, SavedEntityType.post);
    expect(bookmark.target.entityId, post.id);
    expect(bookmark.sourceSurface, SavedSourceSurface.detail);
    expect(bookmark.previewTitle, post.title);
    expect(bookmark.previewSubtitle, post.excerpt);
    expect(bookmark.previewImageUrl, post.coverUrl);
  });

  testWidgets('draft, expired, and non-canonical posts do not offer saving', (
    tester,
  ) async {
    final cases = <PostVm>[
      _post(status: 'DRAFT'),
      _post(expiresAt: DateTime.utc(2020)),
      _post(id: 'post-slug-is-not-canonical'),
      _post(moderationStatus: 'PENDING'),
    ];

    for (final post in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostSavedBookmarkButton(post: post)),
        ),
      );
      expect(find.byType(AppSavedBookmarkButton), findsNothing);
    }
  });

  testWidgets('post card remains reusable without app-level providers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PostSavedBookmarkButton(post: _post())),
      ),
    );

    expect(find.byType(AppSavedBookmarkButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _AuthenticatedSessionProvider extends SessionProvider {
  @override
  SessionStatus get status => SessionStatus.authenticated;
}

PostVm _post({
  String id = '81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de',
  String status = 'PUBLISHED',
  String moderationStatus = 'APPROVED',
  DateTime? expiresAt,
}) {
  final now = DateTime.utc(2026, 7, 18, 12);
  return PostVm(
    id: id,
    slug: 'almaty-weekend',
    title: 'Almaty weekend',
    excerpt: 'A compact itinerary',
    category: 'JOURNAL',
    status: status,
    moderationStatus: moderationStatus,
    tags: const [],
    stats: PostStatsVm(views: 1, likes: 2, comments: 3, shares: 4),
    author: PostAuthorVm(
      userId: '301d2c5e-cd67-45e9-9c6f-6323b5016254',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: 'https://inflap.app/posts/almaty-weekend',
    coverImageUrl: 'https://cdn.inflap.test/post.jpg',
    expiresAt: expiresAt,
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now,
    publishedAt: now,
  );
}
