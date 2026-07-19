import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/saved/data/saved_api.dart';
import 'package:inflap/features/saved/data/saved_repository.dart';
import 'package:inflap/features/saved/domain/saved_error.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';
import 'package:inflap/features/saved/presentation/widgets/saved_bookmark_button.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

import '../../support/saved_test_fakes.dart';

void main() {
  for (final entry in const <String, String>{
    'en': 'Save',
    'ru': 'Сохранить',
    'kk': 'Сақтау',
  }.entries) {
    testWidgets('localizes bookmark semantics and tooltip for ${entry.key}', (
      tester,
    ) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('locale-${entry.key}');
      repository.registry.applySnapshot(
        _status(target, saved: false, version: 1),
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      await _pumpBookmark(
        tester,
        controller: controller,
        target: target,
        locale: Locale(entry.key),
      );

      expect(find.bySemanticsLabel(entry.value), findsOneWidget);
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, entry.value);
    });
  }

  testWidgets(
    'renders UNKNOWN loading, UNSAVED, SAVED, pending, and pending unknown',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('states');
      final bootstrap = Completer<List<SavedTargetSnapshot>>();
      repository.bootstrapHandler = (_) => bootstrap.future;
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      await _pumpBookmark(tester, controller: controller, target: target);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Checking Saved status'), findsOneWidget);
      expect(
        controller.registry.peekStateFor(target).shouldRenderUnsaved,
        isFalse,
      );

      bootstrap.complete(<SavedTargetSnapshot>[
        _status(target, saved: false, version: 1),
      ]);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);

      repository.registry.applySnapshot(
        _status(target, saved: true, version: 2),
      );
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Manage saved item'), findsOneWidget);

      repository.registry.beginMutation(target, operationId);
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Updating Saved'), findsOneWidget);

      repository.registry.markPendingUnknown(target, operationId);
      await tester.pump();
      expect(
        find.bySemanticsLabel("Saved update isn't confirmed. Tap to retry."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    },
  );

  for (final themeCase in <({String name, ThemeData theme, AppColors colors})>[
    (
      name: 'light',
      theme: AppDesignSystem.lightTheme(),
      colors: AppColorSchemes.light,
    ),
    (
      name: 'dark',
      theme: AppDesignSystem.darkTheme(),
      colors: AppColorSchemes.dark,
    ),
  ]) {
    testWidgets(
      'unsaved bookmark has a stable high-contrast surface in ${themeCase.name} theme',
      (tester) async {
        final repository = FakeSavedFeatureRepository();
        final target = _target('contrast-${themeCase.name}');
        repository.registry.applySnapshot(
          _status(target, saved: false, version: 1),
        );
        final controller = SavedScreenController(repository: repository);
        addTearDown(controller.dispose);

        await _pumpBookmark(
          tester,
          controller: controller,
          target: target,
          theme: themeCase.theme,
        );

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.bookmark_border_rounded),
        );
        final button = tester.widget<IconButton>(_bookmarkFinder(target));
        expect(icon.color, themeCase.colors.white);
        expect(
          button.style?.backgroundColor?.resolve(<WidgetState>{}),
          themeCase.colors.black.withValues(alpha: 0.68),
        );
        expect(
          button.style?.side?.resolve(<WidgetState>{})?.color,
          themeCase.colors.white.withValues(alpha: 0.24),
        );
      },
    );

    testWidgets(
      'saved bookmark has a stable high-contrast surface in ${themeCase.name} theme',
      (tester) async {
        final repository = FakeSavedFeatureRepository();
        final target = _target('saved-contrast-${themeCase.name}');
        repository.registry.applySnapshot(
          _status(target, saved: true, version: 1),
        );
        final controller = SavedScreenController(repository: repository);
        addTearDown(controller.dispose);

        await _pumpBookmark(
          tester,
          controller: controller,
          target: target,
          theme: themeCase.theme,
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
        final button = tester.widget<IconButton>(_bookmarkFinder(target));
        expect(icon.color, themeCase.colors.primary);
        expect(
          button.style?.backgroundColor?.resolve(<WidgetState>{}),
          themeCase.colors.black.withValues(alpha: 0.82),
        );
        expect(
          button.style?.side?.resolve(<WidgetState>{})?.color,
          themeCase.colors.primary.withValues(alpha: 0.88),
        );
      },
    );
  }

  testWidgets('bootstrap error stays UNKNOWN and exposes retry', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('bootstrap-error');
    var shouldFail = true;
    repository.bootstrapHandler = (targets) async {
      if (shouldFail) {
        throw DioException(
          requestOptions: RequestOptions(path: '/saved/status:batch'),
          type: DioExceptionType.connectionError,
        );
      }
      return <SavedTargetSnapshot>[
        _status(targets.single, saved: false, version: 2),
      ];
    };
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.pumpAndSettle();

    expect(
      controller.registry.peekStateFor(target).state,
      SavedRegistryState.unknown,
    );
    expect(
      controller.registry.peekStateFor(target).shouldRenderUnsaved,
      isFalse,
    );
    expect(
      find.bySemanticsLabel(
        "Couldn't connect. Check your connection and try again.",
      ),
      findsOneWidget,
    );

    shouldFail = false;
    await tester.tap(_bookmarkFinder(target));
    await tester.pumpAndSettle();

    expect(repository.bootstrapCalls, hasLength(2));
    expect(
      controller.registry.peekStateFor(target).state,
      SavedRegistryState.confirmedUnsaved,
    );
  });

  testWidgets(
    'UNKNOWN save is confirmed before picker and outside dismissal keeps it',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('bootstrap-unknown');
      repository.bootstrapHandler = (targets) async => <SavedTargetSnapshot>[
        SavedTargetSnapshot(
          target: targets.single,
          savedState: SavedConfirmation.unknown,
          eligibility: SavedEligibility.unknown,
          effectiveCollectionCount: 0,
          resourceVersion: 0,
        ),
      ];
      repository.targetCollectionsSnapshot = targetCollections(
        target,
        effectiveIds: const <String>[],
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      await _pumpBookmark(tester, controller: controller, target: target);
      await tester.pumpAndSettle();

      expect(repository.bootstrapCalls, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(repository.bootstrapCalls, hasLength(1));

      await tester.tap(_bookmarkFinder(target));
      await _pumpModalTransition(tester);
      expect(repository.bootstrapCalls, hasLength(1));
      expect(repository.saveCalls.single.target, target);
      expect(
        repository.saveCalls.single.sourceSurface,
        SavedSourceSurface.card,
      );
      expect(
        controller.registry.peekStateFor(target).shouldRenderSaved,
        isTrue,
      );
      expect(find.text('Save to collections'), findsOneWidget);
      expect(repository.desiredAssignments, isEmpty);
      expect(repository.unsaveCalls, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('saved-picker-option-$collectionA')),
      );
      await tester.pump();
      expect(repository.desiredAssignments, isEmpty);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.text('Save to collections'), findsNothing);
      expect(repository.desiredAssignments, isEmpty);
      expect(repository.unsaveCalls, isEmpty);
      expect(
        controller.registry.peekStateFor(target).shouldRenderSaved,
        isTrue,
      );
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    },
  );

  testWidgets('new save can be added to a collection from the picker', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('save-and-organize');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.saveCalls, hasLength(1));
    expect(controller.registry.peekStateFor(target).shouldRenderSaved, isTrue);
    await tester.tap(
      find.byKey(const ValueKey('saved-picker-option-$collectionA')),
    );
    await tester.pump();
    expect(repository.desiredAssignments, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.desiredAssignments.single, <String>{collectionA});
    expect(repository.assignmentSources.single, SavedSourceSurface.card);
    expect(repository.unsaveCalls, isEmpty);
  });

  testWidgets('202 save opens the picker after bounded settlement', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('pending-save-picker');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    repository.saveHandler = (call) async {
      repository.registry.beginMutation(target, operationId);
      return successfulMutationExecution(
        target,
        kind: SavedMutationKind.save,
        sourceSurface: call.sourceSurface,
        state: SavedMutationExecutionState.pending,
      );
    };
    repository.resolveHandler = (resolvedTarget) async {
      repository.registry.confirmMutation(
        resolvedTarget,
        operationId,
        _status(resolvedTarget, saved: true, version: 2),
      );
      return successfulMutationExecution(
        resolvedTarget,
        kind: SavedMutationKind.save,
        sourceSurface: SavedSourceSurface.card,
      );
    };
    final controller = SavedScreenController(
      repository: repository,
      delay: (_) async {},
    );
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.saveCalls, hasLength(1));
    expect(repository.resolveCalls, <SavedTarget>[target]);
    expect(controller.registry.peekStateFor(target).shouldRenderSaved, isTrue);
    expect(find.text('Save to collections'), findsOneWidget);
  });

  testWidgets('picker is compact and renders item and collection covers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final target = _target('compact-preview');
    final collectionCoverTarget = _target('collection-cover');
    final repository = FakeSavedFeatureRepository(
      initialCollections: [
        SavedCollectionRecord(
          collectionId: collectionA,
          title: 'Weekend',
          metadataVersion: 1,
          lifecycleVersion: 1,
          activeItemCount: 3,
          coverPreview: CollectionItemCover(
            target: collectionCoverTarget,
            title: 'Collection cover',
            imageUrl: 'https://images.example.test/collection.jpg',
          ),
          organizedAt: DateTime.utc(2026, 7, 18, 10),
          createdAt: DateTime.utc(2026, 7, 1, 10),
          updatedAt: DateTime.utc(2026, 7, 18, 10),
        ),
      ],
    );
    repository.registry.applySnapshot(
      _status(target, saved: true, version: 1, collectionCount: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(target);
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      previewTitle: 'Sunrise hike',
      previewSubtitle: 'Activities',
      previewImageUrl: 'https://images.example.test/activity.jpg',
    );
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);
    await tester.pump();

    final sheet = find.byKey(const ValueKey('app-modal-custom-sheet-surface'));
    expect(sheet, findsOneWidget);
    expect(tester.getSize(sheet).height, lessThan(844 * 0.6));
    expect(
      find.byKey(const ValueKey('saved-picker-drag-handle')),
      findsOneWidget,
    );
    expect(find.text('Sunrise hike'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved-picker-item-preview-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('saved-picker-cover-image-$collectionA')),
      findsOneWidget,
    );
    expect(find.text('3 saved items'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact picker adapts to long labels and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeSavedFeatureRepository();
    final target = _target('large-text-picker');
    repository.registry.applySnapshot(
      _status(target, saved: true, version: 1, collectionCount: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(target);
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      locale: const Locale('kk'),
      textScaler: const TextScaler.linear(1.6),
      previewTitle: 'Алматыдағы таңғы ұзақ серуен',
      previewSubtitle: 'Белсенділіктер',
    );
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(
      find.byKey(const ValueKey('saved-create-inline-collection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('saved-picker-option-$collectionA')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe dismissal keeps confirmed save without collections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeSavedFeatureRepository();
    final target = _target('swipe-dismiss');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    final sheet = find.byKey(const ValueKey('app-modal-custom-sheet-surface'));
    expect(sheet, findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('saved-picker-option-$collectionA')),
    );
    await tester.pump();
    expect(repository.desiredAssignments, isEmpty);

    final topLeft = tester.getTopLeft(sheet);
    final sheetSize = tester.getSize(sheet);
    await tester.dragFrom(
      Offset(topLeft.dx + (sheetSize.width / 2), topLeft.dy + 24),
      Offset(0, sheetSize.height),
    );
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(repository.saveCalls, hasLength(1));
    expect(repository.desiredAssignments, isEmpty);
    expect(repository.unsaveCalls, isEmpty);
    expect(controller.registry.peekStateFor(target).shouldRenderSaved, isTrue);
  });

  testWidgets('unauthenticated tap calls auth only and not parent action', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('auth');
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);
    var authCalls = 0;
    var parentCalls = 0;

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      isAuthenticated: false,
      onAuthRequired: () => authCalls++,
      onParentTap: () => parentCalls++,
    );
    await tester.tap(_bookmarkFinder(target));
    await tester.pump();

    expect(authCalls, 1);
    expect(parentCalls, 0);
    expect(repository.bootstrapCalls, isEmpty);
    expect(repository.saveCalls, isEmpty);
  });

  testWidgets('unresolved auth disables action and skips bootstrap', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('auth-unresolved');
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);
    var authCalls = 0;

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      isAuthResolved: false,
      isAuthenticated: true,
      onAuthRequired: () => authCalls++,
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

    await tester.tap(_bookmarkFinder(target));
    await tester.pump();

    expect(authCalls, 0);
    expect(repository.bootstrapCalls, isEmpty);
    expect(repository.saveCalls, isEmpty);
    expect(repository.unsaveCalls, isEmpty);
  });

  testWidgets('stale offline hint cannot block a successful explicit save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeSavedFeatureRepository();
    final target = _target('offline');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);
    final online = ValueNotifier<bool>(false);
    addTearDown(online.dispose);

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      online: online,
    );
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.saveCalls.single.target, target);
    expect(repository.saveCalls.single.sourceSurface, SavedSourceSurface.card);
    expect(find.text('Save to collections'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });

  testWidgets('actual connection failure stays unsaved and can be retried', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeSavedFeatureRepository();
    final target = _target('offline-request');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    var requestHasConnection = false;
    repository.saveHandler = (call) async {
      if (!requestHasConnection) {
        throw DioException(
          requestOptions: RequestOptions(path: '/saved/offline-request'),
          type: DioExceptionType.connectionError,
        );
      }
      repository.registry.applySnapshot(
        _status(target, saved: true, version: 2, collectionCount: 0),
      );
      return successfulMutationExecution(
        target,
        kind: SavedMutationKind.save,
        sourceSurface: call.sourceSurface,
      );
    };
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      isOnline: false,
    );
    await tester.tap(_bookmarkFinder(target));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(
      find.text("Couldn't connect. Check your connection and try again."),
      findsOneWidget,
    );
    expect(repository.saveCalls, hasLength(1));

    requestHasConnection = true;
    await tester.tap(find.text('Retry'));
    await _pumpModalTransition(tester);

    expect(repository.saveCalls, hasLength(2));
    expect(repository.saveCalls.last.target, target);
    expect(repository.saveCalls.last.sourceSurface, SavedSourceSurface.card);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'saved item requires explicit removal and uses exact DETAIL source',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = _target('direct-delete');
      repository.registry.applySnapshot(
        _status(target, saved: true, version: 1, collectionCount: 0),
      );
      repository.targetCollectionsSnapshot = targetCollections(
        target,
        effectiveIds: const <String>[],
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      await _pumpBookmark(
        tester,
        controller: controller,
        target: target,
        sourceSurface: SavedSourceSurface.detail,
      );
      await tester.tap(_bookmarkFinder(target));
      await _pumpModalTransition(tester);

      expect(repository.targetCollectionsCalls, <SavedTarget>[target]);
      expect(repository.unsaveCalls, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
      );
      await tester.pumpAndSettle();

      expect(repository.unsaveCalls.single.target, target);
      expect(
        repository.unsaveCalls.single.sourceSurface,
        SavedSourceSurface.detail,
      );
    },
  );

  testWidgets('picker removes selected collections with exact source', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('collections');
    repository.registry.applySnapshot(
      _status(target, saved: true, version: 1, collectionCount: 2),
    );
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[collectionA, collectionB],
    );
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      sourceSurface: SavedSourceSurface.detail,
    );
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.targetCollectionsCalls, <SavedTarget>[target]);
    await tester.tap(
      find.byKey(const ValueKey('saved-picker-option-$collectionA')),
    );
    await tester.pump();
    expect(repository.desiredAssignments, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.desiredAssignments.single, <String>{collectionB});
    expect(repository.assignmentSources.single, SavedSourceSurface.detail);
    expect(repository.unsaveCalls, isEmpty);
  });

  testWidgets('remove everywhere confirmation issues one exact delete', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('confirmed-delete');
    repository.registry.applySnapshot(
      _status(target, saved: true, version: 1, collectionCount: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(target);
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.unsaveCalls, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-cancel-save')),
    );
    await _pumpModalTransition(tester);

    expect(
      find.text(
        'This card is currently in 1 collection. It will be removed from Saved everywhere.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove everywhere'));
    await tester.pumpAndSettle();

    expect(repository.targetCollectionsCalls, <SavedTarget>[target]);
    expect(repository.unsaveCalls, hasLength(1));
    expect(repository.unsaveCalls.single.target, target);
    expect(
      repository.unsaveCalls.single.sourceSurface,
      SavedSourceSurface.card,
    );
  });

  testWidgets('expanded picker preserves inline draft above keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeSavedFeatureRepository();
    final target = _target('expanded-picker');
    repository.registry.applySnapshot(
      _status(target, saved: true, version: 1, collectionCount: 1),
    );
    repository.targetCollectionsSnapshot = targetCollections(target);
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);
    await controller.ensureCapabilities();

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      keyboardHeight: 300,
    );
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(
      find.byKey(const ValueKey('saved-picker-item-preview')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('saved-create-inline-collection')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('saved-inline-collection-title')),
      'Keyboard draft',
    );
    await tester.pump();

    expect(find.text('Keyboard draft'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('saved-collection-picker-submit')),
    );
    await tester.pumpAndSettle();

    expect(repository.createdTitles, <String>['Keyboard draft']);
    expect(repository.desiredAssignments.single, <String>{collectionA});
    expect(repository.assignmentSources.single, SavedSourceSurface.card);
  });

  testWidgets('double tap dispatches only one mutation and skips parent', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('single-flight');
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    final request = Completer<SavedMutationExecution>();
    repository.saveHandler = (_) => request.future;
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);
    var parentCalls = 0;

    await _pumpBookmark(
      tester,
      controller: controller,
      target: target,
      onParentTap: () => parentCalls++,
    );
    await tester.tap(_bookmarkFinder(target));
    await tester.tap(_bookmarkFinder(target), warnIfMissed: false);
    await tester.pump();

    expect(repository.saveCalls, hasLength(1));
    expect(parentCalls, 0);
    request.complete(
      successfulMutationExecution(
        target,
        kind: SavedMutationKind.save,
        sourceSurface: SavedSourceSurface.card,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('rollback explains why a new save is unavailable', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = _target('reduction-only');
    repository.registry.applySnapshot(
      _status(
        target,
        saved: false,
        version: 1,
        eligibility: SavedEligibility.reductionOnly,
      ),
    );
    repository.bootstrapHandler = (targets) async => <SavedTargetSnapshot>[
      _status(
        targets.single,
        saved: false,
        version: 2,
        eligibility: SavedEligibility.reductionOnly,
      ),
    ];
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    expect(
      find.bySemanticsLabel('Saving this item is unavailable'),
      findsOneWidget,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );

    await tester.tap(_bookmarkFinder(target));
    await tester.pumpAndSettle();

    expect(find.text('Saving this item is unavailable'), findsWidgets);
    expect(find.text('Retry'), findsNothing);
    expect(repository.bootstrapCalls, hasLength(1));
    expect(repository.saveCalls, isEmpty);
  });

  testWidgets('explicit tap recovers a stale ineligible USER status', (
    tester,
  ) async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.user,
      entityId: '22222222-3333-4444-8555-666666666666',
    );
    repository.registry.applySnapshot(
      _status(
        target,
        saved: false,
        version: 1,
        eligibility: SavedEligibility.ineligible,
      ),
    );
    repository.bootstrapHandler = (targets) async => <SavedTargetSnapshot>[
      _status(
        targets.single,
        saved: false,
        version: 2,
        eligibility: SavedEligibility.eligible,
      ),
    ];
    repository.targetCollectionsSnapshot = targetCollections(
      target,
      effectiveIds: const <String>[],
    );
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    await _pumpBookmark(tester, controller: controller, target: target);
    await tester.tap(_bookmarkFinder(target));
    await _pumpModalTransition(tester);

    expect(repository.bootstrapCalls, hasLength(1));
    expect(repository.saveCalls, hasLength(1));
    expect(find.text('Save to collections'), findsOneWidget);
  });

  testWidgets(
    'target-unavailable denial refreshes USER status without retry loop',
    (tester) async {
      final repository = FakeSavedFeatureRepository();
      final target = SavedTarget(
        entityType: SavedEntityType.user,
        entityId: '11111111-2222-4333-8444-555555555555',
      );
      repository.registry.applySnapshot(
        _status(target, saved: false, version: 1),
      );
      final requestOptions = RequestOptions(path: '/saved/user');
      repository.saveHandler = (_) async {
        throw SavedApiException.fromDio(
          DioException(
            requestOptions: requestOptions,
            response: Response<Map<String, dynamic>>(
              requestOptions: requestOptions,
              statusCode: 400,
              data: <String, dynamic>{
                'code': SavedErrorCode.targetUnavailable.wireValue,
                'retryable': false,
              },
            ),
          ),
        );
      };
      repository.bootstrapHandler = (targets) async => <SavedTargetSnapshot>[
        _status(
          targets.single,
          saved: false,
          version: 2,
          eligibility: SavedEligibility.ineligible,
        ),
      ];
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      await _pumpBookmark(tester, controller: controller, target: target);
      await tester.tap(_bookmarkFinder(target));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, hasLength(1));
      expect(repository.bootstrapCalls, hasLength(1));
      expect(find.text('Save to collections'), findsNothing);
      expect(find.text('Saving this item is unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(
        controller.registry.peekStateFor(target).eligibility,
        SavedEligibility.ineligible,
      );
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNotNull,
      );

      await tester.tap(_bookmarkFinder(target));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, hasLength(1));
      expect(repository.bootstrapCalls, hasLength(2));
      expect(find.text('Saving this item is unavailable'), findsWidgets);
      expect(find.text('Retry'), findsNothing);
    },
  );
}

Future<void> _pumpBookmark(
  WidgetTester tester, {
  required SavedScreenController controller,
  required SavedTarget target,
  SavedSourceSurface sourceSurface = SavedSourceSurface.card,
  bool isAuthResolved = true,
  bool isAuthenticated = true,
  bool isOnline = true,
  ValueListenable<bool>? online,
  Locale locale = const Locale('en'),
  double keyboardHeight = 0,
  TextScaler? textScaler,
  ThemeData? theme,
  String? previewTitle,
  String? previewSubtitle,
  String? previewImageUrl,
  VoidCallback? onAuthRequired,
  VoidCallback? onParentTap,
}) {
  Widget bookmark(bool onlineValue) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onParentTap,
    child: SavedBookmarkButton(
      controller: controller,
      target: target,
      sourceSurface: sourceSurface,
      isAuthResolved: isAuthResolved,
      isAuthenticated: isAuthenticated,
      isOnline: onlineValue,
      previewTitle: previewTitle,
      previewSubtitle: previewSubtitle,
      previewImageUrl: previewImageUrl,
      onAuthRequired: onAuthRequired ?? () {},
    ),
  );

  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            viewInsets: EdgeInsets.only(bottom: keyboardHeight),
            textScaler: textScaler,
          ),
          child: child!,
        );
      },
      home: Scaffold(
        body: Center(
          child: online == null
              ? bookmark(isOnline)
              : ValueListenableBuilder<bool>(
                  valueListenable: online,
                  builder: (context, value, child) => bookmark(value),
                ),
        ),
      ),
    ),
  );
}

Finder _bookmarkFinder(SavedTarget target) {
  return find.byKey(
    ValueKey(
      'saved-bookmark-${target.entityType.wireValue}-${target.entityId}',
    ),
  );
}

Future<void> _pumpModalTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

SavedTarget _target(String id) {
  return SavedTarget(entityType: SavedEntityType.activity, entityId: id);
}

SavedTargetSnapshot _status(
  SavedTarget target, {
  required bool saved,
  required int version,
  SavedEligibility eligibility = SavedEligibility.eligible,
  int collectionCount = 0,
}) {
  return SavedTargetSnapshot(
    target: target,
    savedState: saved
        ? SavedConfirmation.saved
        : SavedConfirmation.confirmedUnsaved,
    eligibility: eligibility,
    effectiveCollectionCount: collectionCount,
    relationshipGeneration: saved ? relationshipGeneration : null,
    resourceVersion: version,
  );
}
