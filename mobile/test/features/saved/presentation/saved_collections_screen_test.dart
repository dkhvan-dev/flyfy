import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/presentation/saved_collections_screen.dart';
import 'package:inflap/features/saved/presentation/saved_screen.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../support/saved_test_fakes.dart';

void main() {
  for (final testCase in const [
    (Locale('en'), 'Collections'),
    (Locale('ru'), 'Коллекции'),
    (Locale('kk'), 'Коллекциялар'),
  ]) {
    testWidgets(
      'Collections header is localized for ${testCase.$1.languageCode}',
      (tester) async {
        await _pumpCollectionsScreen(
          tester,
          FakeSavedFeatureRepository(),
          locale: testCase.$1,
        );
        await tester.pumpAndSettle();

        final title = tester.widget<Text>(
          find.byKey(const ValueKey('saved-collections-app-bar-title')),
        );
        expect(title.data, testCase.$2);
        expect(title.style?.color, AppColorSchemes.light.textPrimary);
      },
    );
  }

  testWidgets('shows every collection in a compact two-column grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final collections = _orderedCollections([
      savedCollection(id: collectionA, title: 'Weekend'),
      savedCollection(id: collectionB, title: 'Summer'),
      savedCollection(id: _collectionC, title: 'Almaty'),
      savedCollection(id: _collectionD, title: 'Ideas'),
      savedCollection(id: _collectionE, title: 'Family trip'),
    ]);

    await _pumpCollectionsScreen(
      tester,
      FakeSavedFeatureRepository(initialCollections: collections),
    );
    await tester.pumpAndSettle();

    final all = find.byKey(const ValueKey('saved-collections-screen-all'));
    final first = find.byKey(
      ValueKey('saved-collections-screen-${collections[0].collectionId}'),
    );
    final second = find.byKey(
      ValueKey('saved-collections-screen-${collections[1].collectionId}'),
    );
    expect(all, findsOneWidget);
    expect(first, findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved-collections-screen-$_collectionE')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(all).dy, tester.getTopLeft(first).dy);
    expect(tester.getTopLeft(all).dx, lessThan(tester.getTopLeft(first).dx));
    expect(
      tester.getTopLeft(second).dy,
      greaterThan(tester.getTopLeft(all).dy),
    );
    expect(
      find.byKey(const ValueKey('saved-collections-screen-create-collection')),
      findsOneWidget,
    );
    expect(find.text('Collapse'), findsNothing);
    expect(
      find.byKey(const ValueKey('saved-create-collection-rail')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a collection from the app bar plus button', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    await _pumpCollectionsScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('saved-collections-screen-create-collection')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('saved-collection-title-field')),
      'City weekend',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-title-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.createdTitles, ['City weekend']);
  });

  testWidgets('uses one adaptive column for increased system text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeSavedFeatureRepository(
      initialCollections: _orderedCollections([
        savedCollection(
          id: collectionA,
          title: 'A very long personal travel collection title',
        ),
        savedCollection(id: collectionB),
      ]),
    );

    await _pumpCollectionsScreen(tester, repository, textScale: 2);
    await tester.pumpAndSettle();

    final all = find.byKey(const ValueKey('saved-collections-screen-all'));
    final first = find.byKey(
      const ValueKey('saved-collections-screen-$collectionA'),
    );
    expect(tester.getTopLeft(first).dx, tester.getTopLeft(all).dx);
    expect(tester.getTopLeft(first).dy, greaterThan(tester.getTopLeft(all).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('See all opens the screen and selection returns to Saved', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository(
      initialCollections: _orderedCollections([
        savedCollection(id: collectionA, title: 'Weekend'),
        savedCollection(id: collectionB, title: 'Summer'),
        savedCollection(id: _collectionC, title: 'Almaty'),
        savedCollection(id: _collectionD, title: 'Ideas'),
      ]),
    );
    final controller = SavedScreenController(repository: repository);
    final router = GoRouter(
      initialLocation: '/profile/saved',
      routes: [
        GoRoute(
          path: '/profile/saved',
          builder: (context, state) => const SavedScreen(),
        ),
        GoRoute(
          path: '/profile/saved/collections',
          builder: (context, state) => const SavedCollectionsScreen(),
        ),
      ],
    );
    addTearDown(controller.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SavedScreenController>.value(
        value: controller,
        child: MaterialApp.router(
          theme: AppDesignSystem.lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-collections-see-all')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedCollectionsScreen), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('saved-collections-screen-$collectionB')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SavedScreen), findsOneWidget);
    expect(controller.currentViewId.collectionId, collectionB);
    expect(
      repository.listCalls.any((call) => call.collectionId == collectionB),
      isTrue,
    );
  });
}

Future<SavedScreenController> _pumpCollectionsScreen(
  WidgetTester tester,
  FakeSavedFeatureRepository repository, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final controller = SavedScreenController(repository: repository);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<SavedScreenController>.value(
      value: controller,
      child: MaterialApp(
        theme: AppDesignSystem.lightTheme(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SavedCollectionsScreen(),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

const _collectionC = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const _collectionD = '12345678-1234-1234-1234-123456789abc';
const _collectionE = '87654321-4321-4321-4321-cba987654321';

List<SavedCollectionRecord> _orderedCollections(
  List<SavedCollectionRecord> collections,
) {
  collections.sort(
    (left, right) => right.collectionId.compareTo(left.collectionId),
  );
  return collections;
}
