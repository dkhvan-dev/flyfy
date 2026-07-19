import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/activities/activity_category_art.dart';
import 'package:inflap/features/activities/models/activity_list_item_vm.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/screens/profile/widgets/profile_activity_card.dart';
import 'package:inflap/shared/widgets/app_saved_bookmark_button.dart';
import 'package:provider/provider.dart';

import '../../features/saved/support/saved_test_fakes.dart';

void main() {
  testWidgets(
    'activity category cover does not overflow inside compact profile previews',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 84,
                child: ActivityDecorativeCoverFallback(
                  spec: ActivityCardArtSpec(
                    icon: Icons.forest_rounded,
                    colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact public activity bookmark is stable and consumes tap', (
    tester,
  ) async {
    var cardTapCount = 0;
    await _pumpCompactActivityCard(
      tester,
      item: _activityWithoutCover(),
      onCardTap: () => cardTapCount++,
      resolveSessionAsGuest: true,
    );

    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    final bookmark = find.byKey(
      const ValueKey('saved-bookmark-ACTIVITY-activity-1'),
    );
    expect(bookmark, findsOneWidget);
    expect(tester.getSize(bookmark), const Size.square(48));

    await tester.tap(bookmark);
    await tester.pumpAndSettle();

    expect(cardTapCount, 0);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('compact bookmark does not treat unresolved session as guest', (
    tester,
  ) async {
    var cardTapCount = 0;
    final session = await _pumpCompactActivityCard(
      tester,
      item: _activityWithoutCover(),
      onCardTap: () => cardTapCount++,
    );

    expect(session.status, SessionStatus.initial);
    final bookmark = find.byKey(
      const ValueKey('saved-bookmark-ACTIVITY-activity-1'),
    );
    expect(bookmark, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<IconButton>(bookmark).onPressed, isNull);

    await tester.tap(bookmark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(cardTapCount, 0);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('compact private activity does not expose bookmark', (
    tester,
  ) async {
    await _pumpCompactActivityCard(
      tester,
      item: _activityWithoutCover(visibility: 'PRIVATE'),
      onCardTap: () {},
    );

    expect(
      find.byKey(const ValueKey('saved-bookmark-ACTIVITY-activity-1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final testCase in const [
    (label: 'blank', id: ''),
    (label: 'whitespace-only', id: '   '),
    (label: 'surrounding-whitespace', id: ' activity-1 '),
    (label: 'control-character', id: 'activity-\n1'),
  ]) {
    testWidgets('compact public activity omits ${testCase.label} Saved ID', (
      tester,
    ) async {
      await _pumpCompactActivityCard(
        tester,
        item: _activityWithoutCover(id: testCase.id),
        onCardTap: () {},
      );

      expect(find.byType(AppSavedBookmarkButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<SessionProvider> _pumpCompactActivityCard(
  WidgetTester tester, {
  required ActivityListItemVm item,
  required VoidCallback onCardTap,
  bool resolveSessionAsGuest = false,
}) async {
  final session = SessionProvider();
  if (resolveSessionAsGuest) {
    await session.clearSession();
  }
  final controller = SavedScreenController(
    repository: FakeSavedFeatureRepository(),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: ProfileCompactActivityCard(item: item, onTap: onCardTap),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
    ],
  );
  addTearDown(session.dispose);
  addTearDown(controller.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<SavedScreenController>.value(value: controller),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  return session;
}

ActivityListItemVm _activityWithoutCover({
  String id = 'activity-1',
  String visibility = 'PUBLIC',
}) {
  return ActivityListItemVm(
    id: id,
    hostUserId: 'host-1',
    title: 'Очень длинное название активности',
    description: 'Description',
    format: 'OFFLINE',
    status: 'COMPLETED',
    moderationStatus: 'APPROVED',
    visibility: visibility,
    joinMode: 'OPEN',
    categorySlug: 'nature-outdoor',
    languageCode: 'ru',
    timezone: 'Asia/Almaty',
    startAt: DateTime.utc(2026, 5, 20, 5),
    endAt: DateTime.utc(2026, 5, 20, 10),
    capacityType: 'UNLIMITED',
    priceType: 'FREE',
    requiresProfileCompletion: false,
    requiresAttendanceConfirmation: false,
    completedAt: DateTime.utc(2026, 5, 20, 10),
  );
}
