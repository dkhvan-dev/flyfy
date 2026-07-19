import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/saved_screen.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../support/saved_test_fakes.dart';

void main() {
  for (final testCase in const [
    (Locale('en'), 'Saved'),
    (Locale('ru'), 'Сохраненное'),
    (Locale('kk'), 'Сақталғандар'),
  ]) {
    testWidgets('Saved header is localized for ${testCase.$1.languageCode}', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        FakeSavedFeatureRepository(),
        locale: testCase.$1,
      );
      await tester.pump(const Duration(milliseconds: 50));

      final title = tester.widget<Text>(
        find.byKey(const ValueKey('saved-screen-app-bar-title')),
      );
      expect(title.data, testCase.$2);
      expect(title.style?.color, AppColorSchemes.light.textPrimary);
    });
  }

  testWidgets('renders first-page loading and empty states', (tester) async {
    final capabilities = Completer<SavedCapabilities>();
    final repository = FakeSavedFeatureRepository();
    repository.capabilitiesHandler = () => capabilities.future;
    await _pumpScreen(tester, repository);

    expect(find.byKey(const ValueKey('saved-initial-loading')), findsOneWidget);

    capabilities.complete(enabledCapabilities());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(repository.listCalls, hasLength(1));
  });

  testWidgets('compact cards keep several saved items scannable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem(collectionCount: 1)],
    );

    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 100));

    final card = find.byKey(const ValueKey('saved-card-ACTIVITY-activity-1'));
    final media = find.byKey(const ValueKey('saved-media-ACTIVITY-activity-1'));
    final bookmark = find.byKey(
      const ValueKey('saved-bookmark-ACTIVITY-activity-1'),
    );
    final title = find.text('Mountain walk');
    expect(tester.getSize(card).height, lessThan(220));
    expect(tester.getSize(media), const Size.square(112));
    expect(bookmark, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.bookmark_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.bookmark_remove_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.folder_copy_outlined),
      ),
      findsNothing,
    );
    expect(
      tester.getTopLeft(bookmark).dx,
      greaterThan(tester.getRect(media).right),
    );
    expect(
      (tester.getTopLeft(bookmark).dy - tester.getTopLeft(title).dy).abs(),
      lessThan(AppSpacing.sm),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('back button matches the profile connections inset and colors', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();

    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    final buttonFinder = find.ancestor(
      of: find.byIcon(Icons.arrow_back_ios_new_rounded),
      matching: find.byType(IconButton),
    );
    final button = tester.widget<IconButton>(buttonFinder);
    expect(tester.getTopLeft(buttonFinder).dx, 18);
    expect(tester.getSize(buttonFinder), const Size.square(48));
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColorSchemes.light.surfaceRaised,
    );
    expect(
      button.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColorSchemes.light.textPrimary,
    );
  });

  testWidgets('keeps manual reload out of the Saved header', (tester) async {
    await _pumpScreen(tester, FakeSavedFeatureRepository());
    await tester.pump(const Duration(milliseconds: 50));

    final appBar = find.byType(AppBar);
    expect(appBar, findsOneWidget);
    expect(
      find.descendant(of: appBar, matching: find.byIcon(Icons.refresh_rounded)),
      findsNothing,
    );
    expect(
      find.descendant(of: appBar, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('saved-create-collection-rail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('saved-create-collection-sidebar')),
      findsNothing,
    );
  });

  testWidgets('card renders the cover URL supplied by Saved projection', (
    tester,
  ) async {
    const imageUrl = 'https://media.example.test/saved/activity-1.jpg';
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem(collectionCount: 0, imageUrl: imageUrl)],
    );

    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('saved-network-image-ACTIVITY-activity-1')),
    );
    final provider = image.image;
    final networkProvider = provider is ResizeImage
        ? provider.imageProvider as NetworkImage
        : provider as NetworkImage;
    expect(networkProvider.url, imageUrl);
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('uses Places for attractions in the category and card', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [
        savedListItem(
          id: 'place-1',
          type: SavedEntityType.attraction,
          title: 'Горное озеро',
        ),
      ],
    );

    await _pumpScreen(tester, repository, locale: const Locale('ru'));
    await tester.pump(const Duration(milliseconds: 50));

    final card = find.byKey(const ValueKey('saved-card-ATTRACTION-place-1'));
    expect(find.text('Места'), findsNWidgets(2));
    expect(
      find.descendant(of: card, matching: find.text('Места')),
      findsOneWidget,
    );
    expect(find.textContaining('Достопримечатель'), findsNothing);
  });

  testWidgets('uses Users for profile category and card', (tester) async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [
        savedListItem(
          id: 'user-1',
          type: SavedEntityType.user,
          title: 'Алия',
          canonicalDetailRoute: '/users/user-1/profile',
        ),
      ],
    );

    await _pumpScreen(tester, repository, locale: const Locale('ru'));
    await tester.pump(const Duration(milliseconds: 50));

    final card = find.byKey(const ValueKey('saved-card-USER-user-1'));
    expect(find.text('Пользователи'), findsNWidgets(2));
    expect(
      find.descendant(of: card, matching: find.text('Пользователи')),
      findsOneWidget,
    );
    expect(find.text('Гиды'), findsNothing);
  });

  testWidgets('uses Posts for post category and card', (tester) async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [
        savedListItem(
          id: 'post-1',
          type: SavedEntityType.post,
          title: 'Путеводитель по Алматы',
          canonicalDetailRoute: '/posts/post-1',
        ),
      ],
    );

    await _pumpScreen(tester, repository, locale: const Locale('ru'));
    await tester.pump(const Duration(milliseconds: 50));

    final card = find.byKey(const ValueKey('saved-card-POST-post-1'));
    expect(find.text('Посты'), findsNWidgets(2));
    expect(
      find.descendant(of: card, matching: find.text('Посты')),
      findsOneWidget,
    );
  });

  testWidgets(
    'profile card save refreshes an initialized Saved view before navigation',
    (tester) async {
      final item = savedListItem(id: 'profile-activity');
      final repository = FakeSavedFeatureRepository();
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.bootstrapTargetStatuses([item.target]);

      repository.listPage = SavedPage<SavedListItem>(
        items: [item],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );

      final result = await controller.saveBookmark(
        item.target,
        sourceSurface: SavedSourceSurface.card,
      );
      await tester.pump();

      expect(result, SavedUserActionResult.applied);
      expect(controller.currentView.items.single.target, item.target);
      expect(repository.listCalls, hasLength(2));

      await _pumpScreenWithController(tester, controller);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mountain walk'), findsOneWidget);
      expect(repository.listCalls, hasLength(3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.listCalls, hasLength(3));
    },
  );

  testWidgets('reboots canonical state after an in-process session clear', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem()],
    );
    var capabilityCalls = 0;
    repository.capabilitiesHandler = () async {
      capabilityCalls++;
      return repository.capabilities;
    };
    final controller = await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));
    expect(capabilityCalls, 1);

    controller.clearForLogout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(capabilityCalls, 2);
    expect(find.text('Mountain walk'), findsOneWidget);
  });

  testWidgets('renders non-replacing network error with retry', (tester) async {
    final repository = FakeSavedFeatureRepository();
    repository.listHandler = (_) => Future.error(
      DioException(
        requestOptions: RequestOptions(path: '/saved'),
        type: DioExceptionType.connectionError,
      ),
    );
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text("Couldn't connect. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('keeps an in-memory page visible when refresh loses network', (
    tester,
  ) async {
    const canonicalRoute = '/activities/activity-1';
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem(canonicalDetailRoute: canonicalRoute)],
    );
    var offline = false;
    repository.listHandler = (_) {
      if (offline) {
        return Future<SavedPage<SavedListItem>>.error(
          DioException(
            requestOptions: RequestOptions(path: '/saved'),
            type: DioExceptionType.connectionError,
          ),
        );
      }
      return Future<SavedPage<SavedListItem>>.value(repository.listPage);
    };
    final harness = await _pumpRoutedScreen(
      tester,
      repository,
      canonicalRoute: canonicalRoute,
    );
    final controller = harness.controller;
    await tester.pump(const Duration(milliseconds: 50));
    offline = true;

    await controller.refreshCurrent();
    await tester.pump();

    expect(find.text('Mountain walk'), findsOneWidget);
    expect(
      find.text('Connection lost. Showing items loaded on this device.'),
      findsOneWidget,
    );
    expect(controller.currentView.paginationBlocked, isTrue);

    final savedCallsBeforeOpen = repository.listCalls.length;
    final card = find.byKey(const ValueKey('saved-card-ACTIVITY-activity-1'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(card) + const Offset(24, 24));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('canonical-detail-destination-/activities/activity-1'),
      ),
      findsOneWidget,
    );
    expect(repository.listCalls, hasLength(savedCallsBeforeOpen));
  });

  for (final testCase in <({SavedEntityType type, String id, String route})>[
    (type: SavedEntityType.attraction, id: 'place-1', route: '/places/place-1'),
    (
      type: SavedEntityType.activity,
      id: 'activity-1',
      route: '/activities/activity-1',
    ),
    (
      type: SavedEntityType.guide,
      id: 'guide-1',
      route: '/users/guide-1/profile',
    ),
    (type: SavedEntityType.user, id: 'user-1', route: '/users/user-1/profile'),
    (type: SavedEntityType.post, id: 'post-1', route: '/posts/post-1'),
  ]) {
    testWidgets(
      'AVAILABLE ${testCase.type.wireValue} opens its canonical route',
      (tester) async {
        final repository = FakeSavedFeatureRepository(
          initialItems: [
            savedListItem(
              id: testCase.id,
              type: testCase.type,
              canonicalDetailRoute: testCase.route,
            ),
          ],
        );
        await _pumpRoutedScreen(
          tester,
          repository,
          canonicalRoute: testCase.route,
        );
        await tester.pump(const Duration(milliseconds: 50));

        final semanticsData = tester
            .getSemantics(
              find.byKey(
                ValueKey(
                  'saved-card-semantics-${testCase.type.wireValue}-${testCase.id}',
                ),
              ),
            )
            .getSemanticsData();
        expect(semanticsData.flagsCollection.isButton, isTrue);
        expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
        expect(semanticsData.label, contains('Mountain walk'));
        expect(find.text(testCase.route), findsNothing);

        final savedCallsBeforeOpen = repository.listCalls.length;
        final card = find.byKey(
          ValueKey('saved-card-${testCase.type.wireValue}-${testCase.id}'),
        );
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getTopLeft(card) + const Offset(24, 24));
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            ValueKey('canonical-detail-destination-${testCase.route}'),
          ),
          findsOneWidget,
        );
        expect(find.text('Canonical detail destination'), findsOneWidget);
        expect(repository.listCalls, hasLength(savedCallsBeforeOpen));
      },
    );
  }

  testWidgets(
    'UNAVAILABLE placeholder has no tap navigation or button semantics',
    (tester) async {
      final repository = FakeSavedFeatureRepository(
        initialItems: [
          savedListItem(
            id: 'user-unavailable-1',
            type: SavedEntityType.user,
            available: false,
          ),
        ],
      );
      await _pumpRoutedScreen(
        tester,
        repository,
        canonicalRoute: '/activities/activity-1',
      );
      await tester.pump(const Duration(milliseconds: 50));

      final semanticsData = tester
          .getSemantics(
            find.byKey(
              const ValueKey('saved-card-semantics-USER-user-unavailable-1'),
            ),
          )
          .getSemanticsData();
      expect(semanticsData.flagsCollection.isButton, isFalse);
      expect(semanticsData.hasAction(SemanticsAction.tap), isFalse);

      final savedCallsBeforeTap = repository.listCalls.length;
      final card = find.byKey(
        const ValueKey('saved-card-USER-user-unavailable-1'),
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getTopLeft(card) + const Offset(24, 24));
      await tester.pumpAndSettle();

      expect(find.text('Canonical detail destination'), findsNothing);
      expect(repository.listCalls, hasLength(savedCallsBeforeTap));
    },
  );

  testWidgets('collection load failure is non-blocking and retryable', (
    tester,
  ) async {
    final collection = savedCollection();
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem()],
      initialCollections: [collection],
    );
    var attempts = 0;
    repository.collectionsHandler = () {
      attempts++;
      if (attempts == 1) {
        return Future<SavedCollectionsList>.error(
          DioException(
            requestOptions: RequestOptions(path: '/saved-collections'),
            type: DioExceptionType.connectionError,
          ),
        );
      }
      return Future<SavedCollectionsList>.value(repository.collectionsList);
    };

    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Mountain walk'), findsOneWidget);
    expect(find.text("Collections couldn't be loaded"), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saved-collections-retry')));
    await tester.pumpAndSettle();

    expect(find.text("Collections couldn't be loaded"), findsNothing);
    expect(find.text(collection.title), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('empty collection offers a direct return to All saved', (
    tester,
  ) async {
    final collection = savedCollection(itemCount: 0);
    final repository = FakeSavedFeatureRepository(
      initialCollections: [collection],
    );
    final controller = await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(
      find.byKey(
        ValueKey('saved-collection-navigation-${collection.collectionId}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This collection is empty'), findsOneWidget);
    final goAll = find.text('Go to All saved');
    await tester.ensureVisible(goAll);
    await tester.pumpAndSettle();
    await tester.tap(goAll);
    await tester.pumpAndSettle();

    expect(controller.currentViewId.isAll, isTrue);
  });

  testWidgets('loaded state supports category and cancellable server search', (
    tester,
  ) async {
    final initial = savedListItem(id: 'initial', title: 'Initial activity');
    final result = savedListItem(id: 'search-hit', title: 'Mountain result');
    final repository = FakeSavedFeatureRepository(initialItems: [initial]);
    repository.searchHandler = (_) async => _searchPage(result);
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Initial activity'), findsOneWidget);
    await tester.tap(find.text('Activities').first);
    await tester.pump();
    expect(repository.listCalls.last.entityType, isNotNull);

    await tester.enterText(
      find.byKey(const ValueKey('saved-search-field')),
      'mountain',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(repository.searchCalls.single.search, 'mountain');
    expect(find.text('Mountain result'), findsOneWidget);
  });

  testWidgets('search explains an alternate-locale match in the card', (
    tester,
  ) async {
    final result = savedListItem(id: 'search-hit', title: 'Mountain route');
    final repository = FakeSavedFeatureRepository();
    repository.searchHandler = (_) async => _searchPage(
      result,
      matchedField: SavedSearchMatchedField.city,
      matchedLocale: SavedDisplayLocale.ru,
      alternatePublicDisplayValue: 'Алматы',
    );
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
      find.byKey(const ValueKey('saved-search-field')),
      'алматы',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Matched city: Алматы'), findsOneWidget);
    final semantics = tester
        .getSemantics(
          find.byKey(
            const ValueKey('saved-card-semantics-ACTIVITY-search-hit'),
          ),
        )
        .getSemanticsData();
    expect(semantics.label, contains('Matched city: Алматы'));
  });

  testWidgets('create, rename, and delete collection preserve Saved cards', (
    tester,
  ) async {
    final item = savedListItem();
    final collection = savedCollection();
    final repository = FakeSavedFeatureRepository(
      initialItems: [item],
      initialCollections: [collection],
    );
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.byKey(const ValueKey('saved-create-collection-app-bar')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('saved-collection-title-field')),
      'City weekend',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('saved-collection-title-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-title-submit')),
    );
    await tester.pumpAndSettle();
    expect(repository.createdTitles, contains('City weekend'));

    await tester.tap(
      find.byKey(
        ValueKey('saved-collection-navigation-${collection.collectionId}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Collection actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('saved-collection-title-field')),
      'Renamed trip',
    );
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-title-submit')),
    );
    await tester.pumpAndSettle();
    expect(repository.renamedTitles, ['Renamed trip']);

    await tester.tap(find.byTooltip('Collection actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete collection').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Only the collection will be deleted. Its cards will remain in All saved.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('saved-confirm-delete-collection')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedCollectionIds, [collection.collectionId]);
    expect(find.text('Mountain walk'), findsOneWidget);
  });

  testWidgets(
    'collection title sheet stays keyboard-safe and outside tap discards draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = FakeSavedFeatureRepository(
        initialItems: [savedListItem()],
      );
      await _pumpScreen(tester, repository);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(
        find.byKey(const ValueKey('saved-create-collection-app-bar')),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('saved-collection-title-field'));
      await tester.enterText(field, 'Uncommitted weekend');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      final submit = find.byKey(
        const ValueKey('saved-collection-title-submit'),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(500));
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(field, findsNothing);
      expect(repository.createdTitles, isEmpty);
    },
  );

  testWidgets(
    'expanded collection title dialog keeps primary action above keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = FakeSavedFeatureRepository(
        initialItems: [savedListItem()],
      );
      await _pumpScreen(tester, repository);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(
        find.byKey(const ValueKey('saved-create-collection-app-bar')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('saved-collection-title-field')),
        'Keyboard-safe draft',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      await tester.pumpAndSettle();

      final submit = find.byKey(
        const ValueKey('saved-collection-title-submit'),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(540));
      expect(tester.takeException(), isNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.createdTitles, contains('Keyboard-safe draft'));
    },
  );

  testWidgets('session clear closes and discards a collection title draft', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem()],
    );
    final controller = await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.byKey(const ValueKey('saved-create-collection-app-bar')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('saved-collection-title-field')),
      'Stale draft',
    );

    controller.clearForLogout();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-collection-title-field')),
      findsNothing,
    );
    expect(repository.createdTitles, isEmpty);
  });

  testWidgets(
    'collection rollback hides expansion but keeps reduction controls',
    (tester) async {
      final item = savedListItem();
      final repository = FakeSavedFeatureRepository(
        capabilities: SavedCapabilities(
          capabilityRevision: 'rollback',
          productFlags: const SavedProductFlags(
            savedItemsEnabled: false,
            searchEnabled: false,
            collectionsEnabled: false,
          ),
          hasConfirmedSavedData: true,
          supportedEntityTypes: const {SavedEntityType.activity},
          effectiveLocale: SavedDisplayLocale.en,
        ),
        initialItems: [item],
        initialCollections: [savedCollection()],
      );
      repository.targetCollectionsSnapshot = targetCollections(item.target);
      await _pumpScreen(tester, repository);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Mountain walk'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('saved-create-collection-app-bar')),
        findsNothing,
      );
      final bookmark = find.byKey(
        const ValueKey('saved-bookmark-ACTIVITY-activity-1'),
      );
      final bookmarkButton = tester.widget<IconButton>(bookmark);
      expect(bookmarkButton.onPressed, isNotNull);
      bookmarkButton.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('saved-create-inline-collection')),
        findsNothing,
      );
      final selected = tester.widget<InkWell>(
        find.byKey(const ValueKey('saved-picker-option-action-$collectionA')),
      );
      final unselected = tester.widget<InkWell>(
        find.byKey(const ValueKey('saved-picker-option-action-$collectionB')),
      );
      expect(selected.onTap, isNotNull);
      expect(unselected.onTap, isNull);
    },
  );

  testWidgets('collection context prioritizes remove-here over global delete', (
    tester,
  ) async {
    final item = savedListItem(collectionCount: 1);
    final collection = savedCollection();
    final repository = FakeSavedFeatureRepository(
      initialItems: [item],
      initialCollections: [collection],
    );
    repository.targetCollectionsSnapshot = targetCollections(item.target);
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(
      find.byKey(
        ValueKey('saved-collection-navigation-${collection.collectionId}'),
      ),
    );
    await tester.pumpAndSettle();

    final removeHere = find.byKey(
      ValueKey(
        'saved-remove-current-${item.target.entityType.wireValue}-${item.target.entityId}',
      ),
    );
    expect(removeHere, findsOneWidget);
    await tester.ensureVisible(removeHere);
    await tester.pumpAndSettle();
    await tester.tap(removeHere);
    await tester.pumpAndSettle();

    expect(repository.desiredAssignments.single, isEmpty);
  });

  testWidgets('collection picker manually applies one-card assignments', (
    tester,
  ) async {
    final item = savedListItem(collectionCount: 1);
    final repository = FakeSavedFeatureRepository(initialItems: [item]);
    repository.targetCollectionsSnapshot = targetCollections(item.target);
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    await _openCardSavedPicker(tester, item);
    await tester.tap(
      find.byKey(const ValueKey('saved-picker-option-$collectionB')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.desiredAssignments.single, {collectionA, collectionB});
  });

  testWidgets('session clear closes a stale picker without carrying intent', (
    tester,
  ) async {
    final item = savedListItem(collectionCount: 1);
    final repository = FakeSavedFeatureRepository(initialItems: [item]);
    repository.targetCollectionsSnapshot = targetCollections(item.target);
    final controller = await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));
    await _openCardSavedPicker(tester, item);
    await tester.tap(
      find.byKey(const ValueKey('saved-picker-option-$collectionB')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
      findsOneWidget,
    );

    controller.clearForLogout();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
      findsNothing,
    );
    expect(repository.desiredAssignments, isEmpty);
  });

  testWidgets(
    'remove everywhere confirms current N and issues one global delete',
    (tester) async {
      final item = savedListItem(collectionCount: 9);
      final repository = FakeSavedFeatureRepository(initialItems: [item]);
      repository.targetCollectionsSnapshot = targetCollections(
        item.target,
        effectiveIds: const [collectionA, collectionB],
      );
      var deleteCount = 0;
      repository.globalHandler = (target) async {
        deleteCount++;
        return successfulGlobalExecution(target);
      };
      await _pumpScreen(tester, repository);
      await tester.pump(const Duration(milliseconds: 50));

      await _openCardSavedPicker(tester, item);
      await tester.tap(
        find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          'This card is currently in 2 collections. It will be removed from Saved everywhere.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Remove everywhere'));
      await tester.pumpAndSettle();

      expect(deleteCount, 1);
      expect(find.text('Mountain walk'), findsNothing);
    },
  );

  testWidgets('outside tap cancels remove-everywhere confirmation', (
    tester,
  ) async {
    final item = savedListItem(collectionCount: 2);
    final repository = FakeSavedFeatureRepository(initialItems: [item]);
    repository.targetCollectionsSnapshot = targetCollections(
      item.target,
      effectiveIds: const [collectionA, collectionB],
    );
    var deleteCount = 0;
    repository.globalHandler = (target) async {
      deleteCount++;
      return successfulGlobalExecution(target);
    };
    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 50));

    await _openCardSavedPicker(tester, item);
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Remove everywhere'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(deleteCount, 0);
    expect(
      find.byKey(const ValueKey('saved-card-ACTIVITY-activity-1')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(deleteCount, 0);
    expect(find.text('Mountain walk'), findsOneWidget);
  });

  testWidgets(
    'global delete skips confirmation when fresh collection N is zero',
    (tester) async {
      final item = savedListItem(collectionCount: 4);
      final repository = FakeSavedFeatureRepository(initialItems: [item]);
      repository.targetCollectionsSnapshot = targetCollections(
        item.target,
        effectiveIds: const [],
      );
      var deleteCount = 0;
      repository.globalHandler = (target) async {
        deleteCount++;
        return successfulGlobalExecution(target);
      };
      await _pumpScreen(tester, repository);
      await tester.pump(const Duration(milliseconds: 50));

      await _openCardSavedPicker(tester, item);
      await tester.tap(
        find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove everywhere'), findsNothing);
      expect(deleteCount, 1);
      expect(find.text('Mountain walk'), findsNothing);
    },
  );

  testWidgets('expanded layout uses a collection sidebar and two-column rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final first = savedListItem(id: 'first', title: 'First saved card');
    final second = savedListItem(id: 'second', title: 'Second saved card');
    final repository = FakeSavedFeatureRepository(
      initialItems: [first, second],
      initialCollections: [savedCollection()],
    );

    await _pumpScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('saved-create-collection-app-bar')),
      findsOneWidget,
    );
    final firstCard = find.byKey(const ValueKey('saved-card-ACTIVITY-first'));
    final secondCard = find.byKey(const ValueKey('saved-card-ACTIVITY-second'));
    expect(tester.getTopLeft(firstCard).dy, tester.getTopLeft(secondCard).dy);
    expect(
      tester.getTopLeft(firstCard).dx,
      lessThan(tester.getTopLeft(secondCard).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout and long Russian text tolerate large type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = savedListItem(
      title:
          'Очень длинное название сохраненной активности для поездки всей семьей',
    );
    final repository = FakeSavedFeatureRepository(
      initialItems: [item],
      initialCollections: [
        savedCollection(
          title: 'Очень длинное название личной коллекции путешествия',
        ),
      ],
    );
    repository.targetCollectionsSnapshot = targetCollections(
      item.target,
      effectiveIds: const [collectionA, collectionB],
    );
    await _pumpScreen(
      tester,
      repository,
      locale: const Locale('ru'),
      textScale: 2,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Сохраненное'), findsOneWidget);

    await _openCardSavedPicker(tester, item);
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Удалить везде'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openCardSavedPicker(
  WidgetTester tester,
  SavedListItem item,
) async {
  final bookmark = find.byKey(
    ValueKey(
      'saved-bookmark-${item.target.entityType.wireValue}-${item.target.entityId}',
    ),
  );
  await tester.ensureVisible(bookmark);
  await tester.pumpAndSettle();
  await tester.tap(bookmark);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<SavedScreenController> _pumpScreen(
  WidgetTester tester,
  FakeSavedFeatureRepository repository, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final controller = SavedScreenController(repository: repository);
  addTearDown(controller.dispose);
  await _pumpScreenWithController(
    tester,
    controller,
    locale: locale,
    textScale: textScale,
  );
  return controller;
}

Future<void> _pumpScreenWithController(
  WidgetTester tester,
  SavedScreenController controller, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SavedScreenController>.value(
      value: controller,
      child: MaterialApp(
        locale: locale,
        theme: AppDesignSystem.lightTheme(),
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
        home: const SavedScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<({SavedScreenController controller, GoRouter router})> _pumpRoutedScreen(
  WidgetTester tester,
  FakeSavedFeatureRepository repository, {
  required String canonicalRoute,
}) async {
  final controller = SavedScreenController(repository: repository);
  final router = GoRouter(
    initialLocation: '/saved',
    routes: [
      GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
      GoRoute(
        path: canonicalRoute,
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              key: ValueKey('canonical-detail-destination-${state.uri.path}'),
              child: const Text('Canonical detail destination'),
            ),
          ),
        ),
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
  await tester.pump();
  return (controller: controller, router: router);
}

SavedPage<SavedSearchItem> _searchPage(
  SavedListItem item, {
  SavedSearchMatchedField matchedField = SavedSearchMatchedField.title,
  SavedDisplayLocale matchedLocale = SavedDisplayLocale.en,
  String? alternatePublicDisplayValue,
}) {
  return SavedPage<SavedSearchItem>(
    items: [
      SavedSearchItem(
        target: item.target,
        relationship: item.relationship,
        effectiveCollectionCount: item.effectiveCollectionCount,
        projection: item.projection,
        match: SavedSearchMatch(
          matchRank: 0,
          matchKind: SavedSearchMatchKind.token,
          matchedField: matchedField,
          matchedLocale: matchedLocale,
          alternatePublicDisplayValue: alternatePublicDisplayValue,
        ),
      ),
    ],
    nextCursor: null,
    hasMore: false,
  );
}
