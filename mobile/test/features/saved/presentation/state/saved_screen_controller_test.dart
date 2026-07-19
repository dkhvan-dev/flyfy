import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/data/saved_feature_repository.dart';
import 'package:inflap/features/saved/data/saved_repository.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_operation.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_screen_controller.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';

import '../../support/saved_test_fakes.dart';

void main() {
  test(
    'capabilities gate categories and first page keeps server order',
    () async {
      final newer = savedListItem(id: 'newer');
      final older = savedListItem(
        id: 'older',
        savedAt: DateTime.utc(2026, 7, 15),
      );
      final repository = FakeSavedFeatureRepository(
        capabilities: enabledCapabilities(
          supportedTypes: {
            SavedEntityType.activity,
            SavedEntityType.attraction,
            SavedEntityType.user,
          },
        ),
        initialItems: [newer, older],
      );
      final controller = SavedScreenController(repository: repository);

      await controller.initialize();

      expect(controller.currentView.items.map((item) => item.target.entityId), [
        'newer',
        'older',
      ]);
      expect(controller.availableCategories, <SavedEntityType>[
        SavedEntityType.activity,
        SavedEntityType.user,
        SavedEntityType.attraction,
      ]);
      expect(controller.registry.length, 2);
    },
  );

  test(
    'pagination appends cursor pages and rejects duplicate targets',
    () async {
      final first = savedListItem(id: 'first');
      final second = savedListItem(
        id: 'second',
        savedAt: DateTime.utc(2026, 7, 15),
      );
      final repository = FakeSavedFeatureRepository();
      repository.listHandler = (call) async {
        if (call.cursor == null) {
          return SavedPage<SavedListItem>(
            items: [first],
            nextCursor: 'cursor-1',
            hasMore: true,
            validateDateOrder: true,
          );
        }
        return SavedPage<SavedListItem>(
          items: [second],
          nextCursor: null,
          hasMore: false,
          validateDateOrder: true,
        );
      };
      final controller = SavedScreenController(repository: repository);

      await controller.initialize();
      await controller.loadMore();

      expect(controller.currentView.items.map((item) => item.target.entityId), [
        'first',
        'second',
      ]);
      expect(repository.listCalls.last.cursor, 'cursor-1');
      expect(controller.currentView.hasMore, isFalse);
    },
  );

  test('new category response wins and stale response is ignored', () async {
    final firstRequest = Completer<SavedPage<SavedListItem>>();
    final secondRequest = Completer<SavedPage<SavedListItem>>();
    final repository = FakeSavedFeatureRepository();
    var callCount = 0;
    repository.listHandler = (call) {
      callCount++;
      return callCount == 1 ? firstRequest.future : secondRequest.future;
    };
    final controller = SavedScreenController(repository: repository);
    final initialization = controller.initialize();
    await _flush();

    final categoryChange = controller.selectCategory(SavedEntityType.activity);
    await _flush();
    expect(repository.listCalls.first.cancelToken?.isCancelled, isTrue);
    secondRequest.complete(
      SavedPage<SavedListItem>(
        items: [savedListItem(id: 'current')],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      ),
    );
    await categoryChange;
    firstRequest.complete(
      SavedPage<SavedListItem>(
        items: [savedListItem(id: 'stale')],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      ),
    );
    await initialization;

    expect(controller.currentView.items.single.target.entityId, 'current');
  });

  test(
    'debounced search cancels old request and ignores late result',
    () async {
      final oldRequest = Completer<SavedPage<SavedSearchItem>>();
      final newRequest = Completer<SavedPage<SavedSearchItem>>();
      final repository = FakeSavedFeatureRepository();
      repository.searchHandler = (call) => switch (call.search) {
        'old' => oldRequest.future,
        'new' => newRequest.future,
        _ => throw StateError('Unexpected search'),
      };
      final controller = SavedScreenController(
        repository: repository,
        searchDebounce: Duration.zero,
      );
      await controller.initialize();

      controller.updateSearch('old');
      await _flush();
      controller.updateSearch('new');
      await _flush();
      expect(repository.searchCalls.first.cancelToken?.isCancelled, isTrue);
      newRequest.complete(_searchPage('new-result'));
      await _flush();
      oldRequest.complete(_searchPage('old-result'));
      await _flush();

      expect(controller.currentView.query, 'new');
      expect(controller.currentView.items.single.target.entityId, 'new-result');
    },
  );

  test('loaded page survives network failure and blocks pagination', () async {
    final repository = FakeSavedFeatureRepository(
      initialItems: [savedListItem(id: 'loaded')],
    );
    final controller = SavedScreenController(repository: repository);
    await controller.initialize();
    final callsAfterLoad = repository.listCalls.length;
    repository.listHandler = (_) => Future.error(
      DioException(
        requestOptions: RequestOptions(path: '/saved'),
        type: DioExceptionType.connectionError,
      ),
    );

    await controller.refreshCurrent();
    await controller.loadMore();

    expect(controller.currentView.items.single.target.entityId, 'loaded');
    expect(controller.currentView.isStale, isTrue);
    expect(controller.currentView.paginationBlocked, isTrue);
    expect(repository.listCalls.length, callsAfterLoad + 1);

    repository.listHandler = (_) async => SavedPage<SavedListItem>(
      items: [savedListItem(id: 'reconnected')],
      nextCursor: null,
      hasMore: false,
      validateDateOrder: true,
    );
    await controller.handleConnectivityRestored();
    expect(controller.currentView.items.single.target.entityId, 'reconnected');
    expect(controller.currentView.isStale, isFalse);
  });

  test(
    'authoritative replacement evicts old images on deny or URL replacement',
    () async {
      const deniedUrl = 'https://cdn.example.com/saved/denied.jpg';
      const changedUrl = 'https://cdn.example.com/saved/changed-old.jpg';
      const replacementUrl = 'https://cdn.example.com/saved/changed-new.jpg';
      const removedUrl = 'https://cdn.example.com/saved/removed.jpg';
      final denied = _savedListItemWithImage(id: 'denied', imageUrl: deniedUrl);
      final changed = _savedListItemWithImage(
        id: 'changed',
        imageUrl: changedUrl,
      );
      final removed = _savedListItemWithImage(
        id: 'removed',
        imageUrl: removedUrl,
      );
      final repository = FakeSavedFeatureRepository(
        initialItems: [denied, changed, removed],
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      repository.listHandler = (_) async => SavedPage<SavedListItem>(
        items: [
          savedListItem(id: 'denied', available: false),
          _savedListItemWithImage(id: 'changed', imageUrl: replacementUrl),
          savedListItem(id: 'removed'),
        ],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );

      await controller.refreshCurrent();
      await _flush();

      expect(
        evictedUrls,
        unorderedEquals(<String>[deniedUrl, changedUrl, removedUrl]),
      );
      expect(evictedUrls, isNot(contains(replacementUrl)));
      expect(
        controller.currentView.items.first.projection,
        isA<UnavailableSavedCardProjection>(),
      );
    },
  );

  test(
    'authoritative projections replace payloads in every remembered view',
    () async {
      const deniedOldUrl =
          'https://cdn.example.com/saved/cross-view-denied.jpg';
      const changedOldUrl = 'https://cdn.example.com/saved/cross-view-old.jpg';
      const changedNewUrl = 'https://cdn.example.com/saved/cross-view-new.jpg';
      final deniedAllItem = _savedListItemWithImage(
        id: 'cross-view-denied',
        imageUrl: deniedOldUrl,
        collectionCount: 3,
      );
      final changedAllItem = _savedListItemWithImage(
        id: 'cross-view-changed',
        imageUrl: changedOldUrl,
        title: 'Old title',
        collectionCount: 4,
      );
      final deniedSearchItem = _savedSearchItem(deniedAllItem, matchRank: 1);
      final changedSearchItem = _savedSearchItem(changedAllItem, matchRank: 2);
      final collection = savedCollection();
      final repository = FakeSavedFeatureRepository(
        initialItems: [deniedAllItem, changedAllItem],
        initialCollections: [collection],
      );
      repository.searchHandler = (_) async => SavedPage<SavedSearchItem>(
        items: [deniedSearchItem, changedSearchItem],
        nextCursor: null,
        hasMore: false,
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      controller.updateSearch('remembered target');
      await controller.submitSearch();

      repository.listHandler = (_) async => SavedPage<SavedListItem>(
        items: [deniedAllItem, changedAllItem],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );
      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );
      repository.listHandler = (_) async => SavedPage<SavedListItem>(
        items: [
          savedListItem(
            id: deniedAllItem.target.entityId,
            available: false,
            collectionCount: 21,
          ),
          _savedListItemWithImage(
            id: changedAllItem.target.entityId,
            imageUrl: changedNewUrl,
            title: 'New title',
            collectionCount: 22,
          ),
        ],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );

      await controller.refreshCurrent();

      expect(
        controller.currentView.items.map(
          (item) => item.effectiveCollectionCount,
        ),
        <int>[21, 22],
      );
      await controller.selectView(const SavedViewId.all());
      final rememberedItems = <SavedTarget, SavedListItem>{
        for (final item in controller.currentView.items) item.target: item,
      };
      final rememberedDenied =
          rememberedItems[deniedAllItem.target]! as SavedSearchItem;
      final rememberedChanged =
          rememberedItems[changedAllItem.target]! as SavedSearchItem;

      expect(
        rememberedDenied.projection,
        isA<UnavailableSavedCardProjection>(),
      );
      expect(rememberedDenied.effectiveCollectionCount, 3);
      expect(
        identical(rememberedDenied.relationship, deniedSearchItem.relationship),
        isTrue,
      );
      expect(identical(rememberedDenied.match, deniedSearchItem.match), isTrue);
      final changedProjection =
          rememberedChanged.projection as AvailableSavedCardProjection;
      expect(changedProjection.title, 'New title');
      expect(changedProjection.imageUrl.toString(), changedNewUrl);
      expect(rememberedChanged.effectiveCollectionCount, 4);
      expect(
        identical(
          rememberedChanged.relationship,
          changedSearchItem.relationship,
        ),
        isTrue,
      );
      expect(
        identical(rememberedChanged.match, changedSearchItem.match),
        isTrue,
      );
      await _flush();
      expect(
        evictedUrls,
        unorderedEquals(<String>[deniedOldUrl, changedOldUrl]),
      );
    },
  );

  test(
    'authoritative replacement keeps an unchanged image URL cached',
    () async {
      const imageUrl = 'https://cdn.example.com/saved/unchanged.jpg';
      final repository = FakeSavedFeatureRepository(
        initialItems: [
          _savedListItemWithImage(id: 'unchanged', imageUrl: imageUrl),
        ],
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      repository.listHandler = (_) async => SavedPage<SavedListItem>(
        items: [_savedListItemWithImage(id: 'unchanged', imageUrl: imageUrl)],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );

      await controller.refreshCurrent();
      await _flush();

      expect(evictedUrls, isEmpty);
    },
  );

  test(
    'confirmed global unsave evicts removed remembered item images',
    () async {
      const imageUrl = 'https://cdn.example.com/saved/unsaved.jpg';
      final item = _savedListItemWithImage(
        id: 'globally-unsaved',
        imageUrl: imageUrl,
      );
      final repository = FakeSavedFeatureRepository(initialItems: [item]);
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();

      final result = await controller.globallyUnsave(item);
      await _flush();

      expect(result, SavedUserActionResult.applied);
      expect(controller.currentView.items, isEmpty);
      expect(evictedUrls, <String>[imageUrl]);
    },
  );

  test(
    'confirmed global unsave replaces a removed cover and refreshes collections',
    () async {
      const imageUrl = 'https://cdn.example.com/saved/removed-cover.jpg';
      final item = savedListItem(id: 'collection-cover-target');
      final repository = FakeSavedFeatureRepository(
        initialItems: [item],
        initialCollections: [
          _savedCollectionWithCover(target: item.target, imageUrl: imageUrl),
        ],
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      var collectionRefreshes = 0;
      repository.collectionsHandler = () async {
        collectionRefreshes++;
        return SavedCollectionsList(
          collections: [savedCollection(itemCount: 0)],
        );
      };

      final result = await controller.globallyUnsave(item);
      await _flush();

      expect(result, SavedUserActionResult.applied);
      expect(collectionRefreshes, 1);
      expect(
        controller.collections.single.coverPreview,
        isA<GenericCollectionCover>(),
      );
      expect(evictedUrls, contains(imageUrl));
    },
  );

  test(
    'global mutation polling stops after its bounded attempt budget',
    () async {
      final item = savedListItem(id: 'pending-global-unsave');
      final repository = FakeSavedFeatureRepository(initialItems: [item]);
      repository.unsaveHandler = (call) async => successfulMutationExecution(
        call.target,
        kind: SavedMutationKind.unsave,
        sourceSurface: call.sourceSurface,
        state: SavedMutationExecutionState.pending,
      );
      repository.resolveHandler = (target) async => successfulMutationExecution(
        target,
        kind: SavedMutationKind.unsave,
        sourceSurface: SavedSourceSurface.savedAll,
        state: SavedMutationExecutionState.pending,
      );
      final controller = SavedScreenController(
        repository: repository,
        maxMutationPollAttempts: 3,
        delay: (_) async {},
      );
      await controller.initialize();

      final result = await controller.globallyUnsave(item);

      expect(result, SavedUserActionResult.pending);
      expect(repository.resolveCalls, hasLength(3));
      expect(controller.isTargetMutationRequestInFlight(item.target), isFalse);
      expect(controller.isTargetPending(item.target), isTrue);
    },
  );

  test(
    'image eviction failure cannot change confirmed Saved behavior',
    () async {
      final item = _savedListItemWithImage(
        id: 'eviction-failure',
        imageUrl: 'https://cdn.example.com/saved/failure.jpg',
      );
      final repository = FakeSavedFeatureRepository(initialItems: [item]);
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: (_) => throw StateError('Image cache unavailable'),
      );
      await controller.initialize();

      final result = await controller.globallyUnsave(item);
      await _flush();

      expect(result, SavedUserActionResult.applied);
      expect(controller.currentView.items, isEmpty);
      expect(
        controller.registry.peekStateFor(item.target).state,
        SavedRegistryState.confirmedUnsaved,
      );
    },
  );

  test(
    'All and collection retain independent query and scroll memory',
    () async {
      final collection = savedCollection();
      final repository = FakeSavedFeatureRepository(
        initialCollections: [collection],
      );
      final controller = SavedScreenController(
        repository: repository,
        searchDebounce: Duration.zero,
      );
      await controller.initialize();
      controller.updateSearch('all query');
      controller.rememberScrollOffset(120);

      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );
      controller.updateSearch('collection query');
      controller.rememberScrollOffset(340);
      await controller.selectView(const SavedViewId.all());

      expect(controller.currentView.query, 'all query');
      expect(controller.currentView.scrollOffset, 120);
      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );
      expect(controller.currentView.query, 'collection query');
      expect(controller.currentView.scrollOffset, 340);
    },
  );

  test(
    'collection refresh evicts generic and replaced cover image URLs',
    () async {
      const genericOldUrl =
          'https://cdn.example.com/saved/cover-generic-old.jpg';
      const changedOldUrl =
          'https://cdn.example.com/saved/cover-changed-old.jpg';
      const changedNewUrl =
          'https://cdn.example.com/saved/cover-changed-new.jpg';
      final genericTarget = savedListItem(id: 'cover-generic').target;
      final changedTarget = savedListItem(id: 'cover-changed').target;
      final genericReplacement = _savedCollectionWithCover(
        id: collectionA,
        target: genericTarget,
        imageUrl: genericOldUrl,
      );
      final changedReplacement = _savedCollectionWithCover(
        id: collectionB,
        target: changedTarget,
        imageUrl: changedOldUrl,
      );
      final repository = FakeSavedFeatureRepository(
        initialCollections: [changedReplacement, genericReplacement],
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      repository.collectionsHandler = () async => SavedCollectionsList(
        collections: [
          _savedCollectionWithCover(
            id: collectionB,
            target: changedTarget,
            imageUrl: changedNewUrl,
            title: 'Changed cover',
          ),
          savedCollection(id: collectionA, title: 'Generic now'),
        ],
      );

      await controller.refreshCollections();
      await _flush();

      expect(
        evictedUrls,
        unorderedEquals(<String>[genericOldUrl, changedOldUrl]),
      );
      expect(evictedUrls, isNot(contains(changedNewUrl)));
      final refreshed = <String, SavedCollectionRecord>{
        for (final collection in controller.collections)
          collection.collectionId: collection,
      };
      expect(
        refreshed[collectionA]!.coverPreview,
        isA<GenericCollectionCover>(),
      );
      expect(
        (refreshed[collectionB]!.coverPreview as CollectionItemCover).imageUrl,
        changedNewUrl,
      );
    },
  );

  test('collection refresh keeps an unchanged cover URL cached', () async {
    const imageUrl = 'https://cdn.example.com/saved/cover-unchanged.jpg';
    final target = savedListItem(id: 'cover-unchanged').target;
    final repository = FakeSavedFeatureRepository(
      initialCollections: [
        _savedCollectionWithCover(target: target, imageUrl: imageUrl),
      ],
    );
    final evictedUrls = <String>[];
    final controller = SavedScreenController(
      repository: repository,
      imageCacheEvictor: _recordingEvictor(evictedUrls),
    );
    await controller.initialize();
    repository.collectionsHandler = () async => SavedCollectionsList(
      collections: [
        _savedCollectionWithCover(
          target: target,
          imageUrl: imageUrl,
          title: 'Metadata changed',
        ),
      ],
    );

    await controller.refreshCollections();
    await _flush();

    expect(evictedUrls, isEmpty);
    expect(controller.collections.single.title, 'Metadata changed');
  });

  test(
    'collection cover eviction failure preserves refreshed collections',
    () async {
      const oldImageUrl = 'https://cdn.example.com/saved/cover-failure-old.jpg';
      final target = savedListItem(id: 'cover-failure').target;
      final repository = FakeSavedFeatureRepository(
        initialCollections: [
          _savedCollectionWithCover(target: target, imageUrl: oldImageUrl),
        ],
      );
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: (_) =>
            Future<bool>.error(StateError('Image cache unavailable')),
      );
      await controller.initialize();
      repository.collectionsHandler = () async => SavedCollectionsList(
        collections: [
          savedCollection(id: collectionA, title: 'Refreshed collection'),
        ],
      );

      await controller.refreshCollections();
      await _flush();

      expect(controller.collectionsError, isNull);
      expect(controller.collections.single.title, 'Refreshed collection');
      expect(
        controller.collections.single.coverPreview,
        isA<GenericCollectionCover>(),
      );
    },
  );

  test(
    'collection CRUD and assignment remain one-card explicit flows',
    () async {
      final item = savedListItem();
      final collection = savedCollection();
      final repository = FakeSavedFeatureRepository(
        initialItems: [item],
        initialCollections: [collection],
      );
      repository.targetCollectionsSnapshot = targetCollections(item.target);
      final controller = SavedScreenController(repository: repository);
      await controller.initialize();

      expect(
        await controller.createCollection('  New trip  '),
        SavedUserActionResult.applied,
      );
      expect(
        await controller.renameCollection(collection, '  Renamed  '),
        SavedUserActionResult.applied,
      );
      final snapshot = await controller.loadTargetCollections(item.target);
      expect(
        await controller.replaceTargetCollections(
          current: snapshot,
          desiredCollectionIds: const [collectionB],
          newCollectionTitle: '  Assigned trip  ',
        ),
        SavedUserActionResult.applied,
      );
      expect(
        await controller.deleteCollection(collection),
        SavedUserActionResult.applied,
      );

      expect(
        repository.createdTitles,
        containsAll(['New trip', 'Assigned trip']),
      );
      expect(repository.renamedTitles, ['Renamed']);
      expect(repository.desiredAssignments.single, {collectionB});
      expect(repository.deletedCollectionIds, [collection.collectionId]);
    },
  );

  test(
    'profile save assignment reloads a remembered collection on navigation',
    () async {
      final assignedItem = savedListItem(
        id: 'profile-assigned-activity',
        savedAt: DateTime.utc(2026, 7, 16, 11),
      );
      final existingItem = savedListItem(
        id: 'existing-collection-activity',
        savedAt: DateTime.utc(2026, 7, 16, 10),
      );
      final collection = savedCollection(id: collectionA);
      var isSaved = false;
      var isAssigned = false;
      var collectionLoads = 0;
      final repository = FakeSavedFeatureRepository(
        initialCollections: [collection],
      );
      repository.listHandler = (call) async {
        final items = switch (call.collectionId) {
          collectionA => <SavedListItem>[
            if (isAssigned) assignedItem,
            existingItem,
          ],
          _ => <SavedListItem>[if (isSaved) assignedItem],
        };
        if (call.collectionId == collectionA) collectionLoads++;
        return SavedPage<SavedListItem>(
          items: items,
          nextCursor: null,
          hasMore: false,
          validateDateOrder: true,
        );
      };
      repository.registry.applySnapshot(
        _status(assignedItem.target, saved: false, version: 1),
      );
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();

      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );
      expect(controller.currentView.items, [existingItem]);
      expect(collectionLoads, 1);
      await controller.selectView(const SavedViewId.all());

      isSaved = true;
      expect(
        await controller.saveBookmark(
          assignedItem.target,
          sourceSurface: SavedSourceSurface.card,
        ),
        SavedUserActionResult.applied,
      );
      await _flush();
      await _flush();
      expect(controller.currentView.items, [assignedItem]);

      repository.commandHandler = () async {
        isAssigned = true;
        return successfulCommand(
          SavedCommandKey.assignment(assignedItem.target),
        );
      };
      expect(
        await controller.replaceTargetCollections(
          current: targetCollections(
            assignedItem.target,
            effectiveIds: const [],
          ),
          desiredCollectionIds: const [collectionA],
          sourceSurface: SavedSourceSurface.card,
        ),
        SavedUserActionResult.applied,
      );
      expect(collectionLoads, 1);

      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );

      expect(collectionLoads, 2);
      expect(controller.currentView.items, [assignedItem, existingItem]);
    },
  );

  test(
    'unknown assignment blocks duplicates without a sticky loading state',
    () {
      final repository = FakeSavedFeatureRepository();
      final target = SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: 'pending-assignment',
      );
      repository.activeCommands.add(SavedCommandKey.assignment(target));
      final controller = SavedScreenController(repository: repository);

      expect(controller.isAssignmentPending(target), isTrue);
      expect(controller.isAssignmentRequestInFlight(target), isFalse);
    },
  );

  test(
    'flag rollback keeps personal data and reduction actions available',
    () async {
      final item = savedListItem();
      final collection = savedCollection();
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
        initialCollections: [collection],
      );
      final snapshot = targetCollections(item.target);
      final controller = SavedScreenController(repository: repository);

      await controller.initialize();

      expect(controller.savedEnabled, isTrue);
      expect(controller.collectionsEnabled, isTrue);
      expect(controller.collectionsExpansionEnabled, isFalse);
      expect(controller.currentView.items, hasLength(1));
      expect(controller.collections, hasLength(1));
      expect(
        await controller.createCollection('Blocked'),
        SavedUserActionResult.rejected,
      );
      expect(
        await controller.replaceTargetCollections(
          current: snapshot,
          desiredCollectionIds: const [collectionA, collectionB],
        ),
        SavedUserActionResult.rejected,
      );
      expect(repository.createdTitles, isEmpty);
      expect(repository.desiredAssignments, isEmpty);

      expect(
        await controller.replaceTargetCollections(
          current: snapshot,
          desiredCollectionIds: const <String>[],
        ),
        SavedUserActionResult.applied,
      );
      expect(repository.desiredAssignments.single, isEmpty);
      expect(
        await controller.renameCollection(collection, 'Kept'),
        SavedUserActionResult.applied,
      );
      expect(
        await controller.deleteCollection(collection),
        SavedUserActionResult.applied,
      );
    },
  );

  test('bookmark batch bootstrap hydrates the singleton registry', () async {
    final repository = FakeSavedFeatureRepository();
    final first = SavedTarget(
      entityType: SavedEntityType.activity,
      entityId: 'batch-activity',
    );
    final second = SavedTarget(
      entityType: SavedEntityType.guide,
      entityId: 'batch-guide',
    );
    repository.bootstrapHandler = (targets) async => <SavedTargetSnapshot>[
      _status(targets[0], saved: true, version: 5),
      _status(targets[1], saved: false, version: 6),
    ];
    final controller = SavedScreenController(repository: repository);

    final statuses = await controller.bootstrapTargetStatuses(<SavedTarget>[
      first,
      second,
      first,
    ]);

    expect(identical(controller.registry, repository.registry), isTrue);
    expect(repository.bootstrapCalls.single, <SavedTarget>[first, second]);
    expect(statuses, hasLength(2));
    expect(
      controller.registry.peekStateFor(first).state,
      SavedRegistryState.confirmedSaved,
    );
    expect(
      controller.registry.peekStateFor(second).state,
      SavedRegistryState.confirmedUnsaved,
    );
  });

  test('visible bookmark queue coalesces one frame into one batch', () async {
    final repository = FakeSavedFeatureRepository();
    final first = SavedTarget(
      entityType: SavedEntityType.activity,
      entityId: 'queued-activity',
    );
    final second = SavedTarget(
      entityType: SavedEntityType.guide,
      entityId: 'queued-guide',
    );
    repository.bootstrapHandler = (targets) async => targets
        .map((target) => _status(target, saved: false, version: 1))
        .toList(growable: false);
    final controller = SavedScreenController(repository: repository);
    addTearDown(controller.dispose);

    controller.queueTargetStatusBootstrap(first);
    controller.queueTargetStatusBootstrap(second);
    controller.queueTargetStatusBootstrap(first);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.bootstrapCalls, hasLength(1));
    expect(repository.bootstrapCalls.single, <SavedTarget>[first, second]);
  });

  test(
    'successful UNKNOWN bootstrap is cached until an explicit retry',
    () async {
      final repository = FakeSavedFeatureRepository();
      final target = SavedTarget(
        entityType: SavedEntityType.attraction,
        entityId: 'unknown-bootstrap',
      );
      repository.bootstrapHandler = (targets) async => targets
          .map(
            (target) => SavedTargetSnapshot(
              target: target,
              savedState: SavedConfirmation.unknown,
              eligibility: SavedEligibility.unknown,
              effectiveCollectionCount: 0,
              resourceVersion: 0,
            ),
          )
          .toList(growable: false);
      final controller = SavedScreenController(repository: repository);
      addTearDown(controller.dispose);

      controller.queueTargetStatusBootstrap(target);
      await _flush();

      expect(repository.bootstrapCalls, hasLength(1));
      expect(controller.hasTargetStatusSnapshot(target), isTrue);
      expect(
        controller.registry.peekStateFor(target).state,
        SavedRegistryState.unknown,
      );

      controller.queueTargetStatusBootstrap(target);
      await controller.bootstrapTargetStatuses(<SavedTarget>[target]);
      await _flush();
      expect(repository.bootstrapCalls, hasLength(1));

      await controller.bootstrapTargetStatuses(<SavedTarget>[
        target,
      ], force: true);
      expect(repository.bootstrapCalls, hasLength(2));
    },
  );

  test('bookmark UNKNOWN sends an authoritative save intent', () async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.attraction,
      entityId: 'unknown-target',
    );
    repository.registry.applySnapshot(
      SavedTargetSnapshot(
        target: target,
        savedState: SavedConfirmation.unknown,
        eligibility: SavedEligibility.eligible,
        effectiveCollectionCount: 0,
        resourceVersion: 1,
      ),
    );
    final controller = SavedScreenController(repository: repository);

    expect(
      controller.registry.peekStateFor(target).shouldRenderUnsaved,
      isFalse,
    );

    final result = await controller.saveBookmark(
      target,
      sourceSurface: SavedSourceSurface.card,
    );

    expect(result, SavedUserActionResult.applied);
    expect(repository.saveCalls.single.target, target);
    expect(repository.saveCalls.single.sourceSurface, SavedSourceSurface.card);
    expect(controller.registry.peekStateFor(target).shouldRenderSaved, isTrue);
  });

  test('confirmed bookmark save refreshes an initialized All view', () async {
    final item = savedListItem(id: 'profile-recent-activity');
    final repository = FakeSavedFeatureRepository();
    final controller = SavedScreenController(repository: repository);
    await controller.initialize();
    await controller.bootstrapTargetStatuses(<SavedTarget>[item.target]);
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
    await _flush();
    await _flush();

    expect(result, SavedUserActionResult.applied);
    expect(controller.currentView.items.single.target, item.target);
    expect(repository.listCalls, hasLength(2));
  });

  test('bookmark mutations preserve exact target and source surface', () async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.user,
      entityId: 'user-source',
    );
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    final controller = SavedScreenController(repository: repository);

    expect(
      await controller.saveBookmark(
        target,
        sourceSurface: SavedSourceSurface.card,
      ),
      SavedUserActionResult.applied,
    );
    expect(
      await controller.unsaveBookmark(
        target,
        sourceSurface: SavedSourceSurface.detail,
      ),
      SavedUserActionResult.applied,
    );

    expect(repository.saveCalls.single.target, target);
    expect(repository.saveCalls.single.sourceSurface, SavedSourceSurface.card);
    expect(repository.unsaveCalls.single.target, target);
    expect(
      repository.unsaveCalls.single.sourceSurface,
      SavedSourceSurface.detail,
    );
  });

  test('rollback allows reduction but blocks new saves', () async {
    final repository = FakeSavedFeatureRepository(
      capabilities: SavedCapabilities(
        capabilityRevision: 'bookmark-rollback',
        productFlags: const SavedProductFlags(
          savedItemsEnabled: false,
          searchEnabled: false,
          collectionsEnabled: false,
        ),
        hasConfirmedSavedData: true,
        supportedEntityTypes: const <SavedEntityType>{
          SavedEntityType.activity,
          SavedEntityType.guide,
        },
        effectiveLocale: SavedDisplayLocale.en,
      ),
    );
    final saved = SavedTarget(
      entityType: SavedEntityType.activity,
      entityId: 'reduction-saved',
    );
    final unsaved = SavedTarget(
      entityType: SavedEntityType.guide,
      entityId: 'reduction-unsaved',
    );
    repository.registry.hydrateBatch(<SavedTargetSnapshot>[
      _status(
        saved,
        saved: true,
        version: 1,
        eligibility: SavedEligibility.reductionOnly,
      ),
      _status(
        unsaved,
        saved: false,
        version: 1,
        eligibility: SavedEligibility.eligible,
      ),
    ]);
    final controller = SavedScreenController(repository: repository);
    await controller.initialize();

    expect(
      await controller.unsaveBookmark(
        saved,
        sourceSurface: SavedSourceSurface.card,
      ),
      SavedUserActionResult.applied,
    );
    expect(
      await controller.saveBookmark(
        unsaved,
        sourceSurface: SavedSourceSurface.card,
      ),
      SavedUserActionResult.rejected,
    );
    expect(repository.unsaveCalls, hasLength(1));
    expect(repository.saveCalls, isEmpty);
  });

  test('bookmark pending lock prevents duplicate mutation requests', () async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.activity,
      entityId: 'single-flight',
    );
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    final request = Completer<SavedMutationExecution>();
    repository.saveHandler = (_) => request.future;
    final controller = SavedScreenController(repository: repository);

    final first = controller.saveBookmark(
      target,
      sourceSurface: SavedSourceSurface.card,
    );
    await _flush();
    final duplicate = await controller.saveBookmark(
      target,
      sourceSurface: SavedSourceSurface.card,
    );

    expect(duplicate, SavedUserActionResult.pending);
    expect(repository.saveCalls, hasLength(1));
    request.complete(
      successfulMutationExecution(
        target,
        kind: SavedMutationKind.save,
        sourceSurface: SavedSourceSurface.card,
      ),
    );
    await first;
  });

  test('bookmark 202 settles before returning a confirmed save', () async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.activity,
      entityId: 'pending-save',
    );
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
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

    expect(
      await controller.saveBookmark(
        target,
        sourceSurface: SavedSourceSurface.card,
      ),
      SavedUserActionResult.applied,
    );
    expect(repository.saveCalls, hasLength(1));
    expect(repository.resolveCalls, <SavedTarget>[target]);
    expect(
      controller.registry.peekStateFor(target).state,
      SavedRegistryState.confirmedSaved,
    );
  });

  test('pending unknown resolves only through the live operation', () async {
    final repository = FakeSavedFeatureRepository();
    final target = SavedTarget(
      entityType: SavedEntityType.attraction,
      entityId: 'live-operation',
    );
    repository.registry.applySnapshot(
      _status(target, saved: false, version: 1),
    );
    repository.saveHandler = (call) async {
      repository.registry.beginMutation(target, operationId);
      return successfulMutationExecution(
        target,
        kind: SavedMutationKind.save,
        sourceSurface: call.sourceSurface,
        state: SavedMutationExecutionState.pendingUnknown,
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
    final controller = SavedScreenController(repository: repository);

    expect(
      await controller.saveBookmark(
        target,
        sourceSurface: SavedSourceSurface.card,
      ),
      SavedUserActionResult.pending,
    );
    expect(repository.registry.isLocked(target), isTrue);
    expect(
      await controller.resolveBookmarkMutation(target),
      SavedUserActionResult.applied,
    );
    expect(repository.resolveCalls, <SavedTarget>[target]);
    expect(
      repository.registry.peekStateFor(target).state,
      SavedRegistryState.confirmedSaved,
    );
  });

  test(
    'logout clears pages, operations, registry, and rejects late response',
    () async {
      final response = Completer<SavedPage<SavedListItem>>();
      final repository = FakeSavedFeatureRepository();
      repository.listHandler = (_) => response.future;
      final controller = SavedScreenController(repository: repository);
      final initialization = controller.initialize();
      await _flush();

      controller.clearForLogout();
      response.complete(
        SavedPage<SavedListItem>(
          items: [savedListItem(id: 'late')],
          nextCursor: null,
          hasMore: false,
          validateDateOrder: true,
        ),
      );
      await initialization;

      expect(controller.initialized, isFalse);
      expect(controller.currentView.items, isEmpty);
      expect(controller.registry, isEmpty);
      expect(repository.clearCount, 1);
    },
  );

  test(
    'logout evicts every remembered item and collection-cover image',
    () async {
      const allImageUrl = 'https://cdn.example.com/saved/all.jpg';
      const collectionImageUrl =
          'https://cdn.example.com/saved/collection-item.jpg';
      const coverImageUrl = 'https://cdn.example.com/saved/cover.jpg';
      final allItem = _savedListItemWithImage(
        id: 'all-item',
        imageUrl: allImageUrl,
      );
      final collectionItem = _savedListItemWithImage(
        id: 'collection-item',
        imageUrl: collectionImageUrl,
      );
      final collection = _savedCollectionWithCover(
        target: collectionItem.target,
        imageUrl: coverImageUrl,
      );
      final repository = FakeSavedFeatureRepository(
        initialCollections: [collection],
      );
      repository.listHandler = (call) async => SavedPage<SavedListItem>(
        items: call.collectionId == null ? [allItem] : [collectionItem],
        nextCursor: null,
        hasMore: false,
        validateDateOrder: true,
      );
      final evictedUrls = <String>[];
      final controller = SavedScreenController(
        repository: repository,
        imageCacheEvictor: _recordingEvictor(evictedUrls),
      );
      await controller.initialize();
      await controller.selectView(
        SavedViewId.collection(collection.collectionId),
      );

      controller.clearForLogout();
      await _flush();

      expect(
        evictedUrls,
        unorderedEquals(<String>[
          allImageUrl,
          collectionImageUrl,
          coverImageUrl,
        ]),
      );
      expect(controller.currentView.items, isEmpty);
      expect(controller.collections, isEmpty);
    },
  );
}

SavedPage<SavedSearchItem> _searchPage(String id) {
  final item = savedListItem(id: id);
  return SavedPage<SavedSearchItem>(
    items: [
      SavedSearchItem(
        target: item.target,
        relationship: item.relationship,
        effectiveCollectionCount: item.effectiveCollectionCount,
        projection: item.projection,
        match: SavedSearchMatch(
          matchRank: 0,
          matchKind: SavedSearchMatchKind.exact,
          matchedField: SavedSearchMatchedField.title,
          matchedLocale: SavedDisplayLocale.en,
        ),
      ),
    ],
    nextCursor: null,
    hasMore: false,
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

SavedImageCacheEvictor _recordingEvictor(List<String> evictedUrls) {
  return (imageUrl) async {
    evictedUrls.add(imageUrl);
    return true;
  };
}

SavedListItem _savedListItemWithImage({
  required String id,
  required String? imageUrl,
  String title = 'Mountain walk',
  int collectionCount = 1,
}) {
  final item = savedListItem(
    id: id,
    title: title,
    collectionCount: collectionCount,
  );
  final projection = item.projection as AvailableSavedCardProjection;
  return SavedListItem(
    target: item.target,
    relationship: item.relationship,
    effectiveCollectionCount: item.effectiveCollectionCount,
    projection: AvailableSavedCardProjection(
      projectionVersion: projection.projectionVersion,
      displayLocale: projection.displayLocale,
      title: projection.title,
      canonicalDetailRoute: projection.canonicalDetailRoute,
      subtitle: projection.subtitle,
      imageUrl: imageUrl == null ? null : Uri.parse(imageUrl),
      sourceUpdatedAt: projection.sourceUpdatedAt,
    ),
  );
}

SavedSearchItem _savedSearchItem(SavedListItem item, {required int matchRank}) {
  return SavedSearchItem(
    target: item.target,
    relationship: item.relationship,
    effectiveCollectionCount: item.effectiveCollectionCount,
    projection: item.projection,
    match: SavedSearchMatch(
      matchRank: matchRank,
      matchKind: SavedSearchMatchKind.exact,
      matchedField: SavedSearchMatchedField.title,
      matchedLocale: SavedDisplayLocale.en,
    ),
  );
}

SavedCollectionRecord _savedCollectionWithCover({
  required SavedTarget target,
  required String imageUrl,
  String id = collectionA,
  String title = 'Weekend',
}) {
  final collection = savedCollection(id: id, title: title);
  return SavedCollectionRecord(
    collectionId: collection.collectionId,
    title: collection.title,
    metadataVersion: collection.metadataVersion,
    lifecycleVersion: collection.lifecycleVersion,
    activeItemCount: collection.activeItemCount,
    coverPreview: CollectionItemCover(
      target: target,
      title: 'Collection cover',
      imageUrl: imageUrl,
    ),
    organizedAt: collection.organizedAt,
    createdAt: collection.createdAt,
    updatedAt: collection.updatedAt,
  );
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
