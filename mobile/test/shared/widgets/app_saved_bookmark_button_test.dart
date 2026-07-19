import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/session_provider.dart';
import 'package:inflap/shared/widgets/app_saved_bookmark_button.dart';
import 'package:provider/provider.dart';

import '../../features/saved/support/saved_test_fakes.dart';

void main() {
  testWidgets('stays inert outside the app-level Saved provider tree', (
    tester,
  ) async {
    final session = _TestSessionProvider(SessionStatus.unauthenticated);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>.value(
        value: session,
        child: MaterialApp(
          home: Scaffold(
            body: AppSavedBookmarkButton(
              target: _target('isolated'),
              sourceSurface: SavedSourceSurface.card,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final status in const <SessionStatus>[
    SessionStatus.initial,
    SessionStatus.loading,
  ]) {
    testWidgets(
      '${status.name} auth is checking, inert, and isolated from parent taps',
      (tester) async {
        final repository = FakeSavedFeatureRepository();
        final target = _target('unresolved-${status.name}');
        final controller = SavedScreenController(repository: repository);
        addTearDown(controller.dispose);
        var parentTaps = 0;

        await _pumpAppBookmark(
          tester,
          controller: controller,
          target: target,
          sessionStatus: status,
          onParentTap: () => parentTaps++,
        );
        await tester.pump();

        expect(find.bySemanticsLabel('Checking Saved status'), findsOneWidget);
        expect(
          tester.widget<Tooltip>(find.byType(Tooltip)).message,
          'Checking Saved status',
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byType(IconButton)).onPressed,
          isNull,
        );

        final tapConsumer = find.descendant(
          of: find.byType(AppSavedBookmarkButton),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is GestureDetector &&
                widget.behavior == HitTestBehavior.opaque &&
                widget.excludeFromSemantics &&
                widget.onTap != null,
          ),
        );
        expect(tapConsumer, findsOneWidget);
        expect(
          tester.widget<GestureDetector>(tapConsumer).behavior,
          HitTestBehavior.opaque,
        );
        expect(
          tester.widget<GestureDetector>(tapConsumer).excludeFromSemantics,
          isTrue,
        );
        expect(tester.getSize(tapConsumer), const Size.square(48));

        await tester.tap(_bookmarkFinder(target));
        await tester.pump();

        expect(parentTaps, 0);
        expect(repository.bootstrapCalls, isEmpty);
        expect(repository.saveCalls, isEmpty);
        expect(repository.unsaveCalls, isEmpty);
        expect(find.byKey(const ValueKey('login-route')), findsNothing);
      },
    );
  }

  testWidgets(
    'unauthenticated tap opens login without mutating or parent tap',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('unauthenticated');
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);
      var parentTaps = 0;

      await _pumpAppBookmark(
        tester,
        controller: controller,
        target: target,
        sessionStatus: SessionStatus.unauthenticated,
        onParentTap: () => parentTaps++,
      );
      await tester.tap(_bookmarkFinder(target));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('login-route')), findsOneWidget);
      expect(parentTaps, 0);
      expect(repository.bootstrapCalls, isEmpty);
      expect(repository.saveCalls, isEmpty);
      expect(repository.unsaveCalls, isEmpty);
    },
  );

  testWidgets(
    'authenticated bookmark saves before opening its collection picker',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('authenticated');
      repository.registry.applySnapshot(_unsavedStatus(target));
      repository.targetCollectionsSnapshot = targetCollections(
        target,
        effectiveIds: const <String>[],
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);
      var parentTaps = 0;

      await _pumpAppBookmark(
        tester,
        controller: controller,
        target: target,
        sessionStatus: SessionStatus.authenticated,
        onParentTap: () => parentTaps++,
      );
      await tester.tap(_bookmarkFinder(target));
      await _pumpModalTransition(tester);

      expect(repository.saveCalls, hasLength(1));
      expect(repository.saveCalls.single.target, target);
      expect(
        find.byKey(const ValueKey('saved-picker-item-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('saved-collection-picker-submit')),
        findsNothing,
      );
      expect(repository.desiredAssignments, isEmpty);
      expect(parentTaps, 0);
      expect(find.byKey(const ValueKey('login-route')), findsNothing);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(repository.desiredAssignments, isEmpty);
      expect(repository.unsaveCalls, isEmpty);
    },
  );

  testWidgets(
    'USER bookmark refreshes stale capabilities and saves on the same tap',
    (tester) async {
      var capabilityCalls = 0;
      final repository = FakeSavedFeatureRepository();
      repository.capabilitiesHandler = () async {
        capabilityCalls++;
        return enabledCapabilities(
          supportedTypes: capabilityCalls == 1
              ? <SavedEntityType>{SavedEntityType.activity}
              : null,
        );
      };
      final target = _target(
        '11111111-2222-4333-8444-555555555555',
        type: SavedEntityType.user,
      );
      repository.registry.applySnapshot(_unsavedStatus(target));
      repository.targetCollectionsSnapshot = targetCollections(
        target,
        effectiveIds: const <String>[],
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);
      await controller.ensureCapabilities();

      await _pumpAppBookmark(
        tester,
        controller: controller,
        target: target,
        sessionStatus: SessionStatus.authenticated,
      );

      expect(controller.isBookmarkExpansionAvailable(target), isFalse);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNotNull,
      );

      await tester.tap(_bookmarkFinder(target));
      await _pumpModalTransition(tester);

      expect(capabilityCalls, 2);
      expect(controller.isBookmarkExpansionAvailable(target), isTrue);
      expect(repository.saveCalls.single.target, target);
      expect(
        find.byKey(const ValueKey('saved-picker-item-preview')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpModalTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _pumpAppBookmark(
  WidgetTester tester, {
  required SavedScreenController controller,
  required SavedTarget target,
  required SessionStatus sessionStatus,
  VoidCallback? onParentTap,
}) async {
  final session = _TestSessionProvider(sessionStatus);
  addTearDown(session.dispose);
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onParentTap,
              child: AppSavedBookmarkButton(
                target: target,
                sourceSurface: SavedSourceSurface.card,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(
          key: ValueKey('login-route'),
          body: SizedBox.shrink(),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: session),
        ChangeNotifierProvider<SavedScreenController>.value(value: controller),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

class _TestSessionProvider extends SessionProvider {
  _TestSessionProvider(this._testStatus);

  final SessionStatus _testStatus;

  @override
  SessionStatus get status => _testStatus;
}

Finder _bookmarkFinder(SavedTarget target) {
  return find.byKey(
    ValueKey(
      'saved-bookmark-${target.entityType.wireValue}-${target.entityId}',
    ),
  );
}

SavedTarget _target(
  String id, {
  SavedEntityType type = SavedEntityType.activity,
}) {
  return SavedTarget(entityType: type, entityId: id);
}

SavedTargetSnapshot _unsavedStatus(SavedTarget target) {
  return SavedTargetSnapshot(
    target: target,
    savedState: SavedConfirmation.confirmedUnsaved,
    eligibility: SavedEligibility.eligible,
    effectiveCollectionCount: 0,
    resourceVersion: 1,
  );
}
