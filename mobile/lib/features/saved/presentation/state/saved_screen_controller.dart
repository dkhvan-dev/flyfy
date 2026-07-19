import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../data/saved_api.dart';
import '../../data/saved_feature_repository.dart';
import '../../data/saved_repository.dart';
import '../../domain/saved_browse_models.dart';
import '../../domain/saved_operation.dart';
import '../../domain/saved_status.dart';
import '../../domain/saved_target.dart';
import 'saved_state_registry.dart';

enum SavedViewLoadState { idle, loading, loaded, error, disabled }

enum SavedUserActionResult {
  applied,
  noOp,
  pending,
  rejected,
  expired,
  superseded,
}

typedef SavedImageCacheEvictor = Future<bool> Function(String imageUrl);

@immutable
final class SavedViewId {
  const SavedViewId.all() : collectionId = null;
  const SavedViewId.collection(this.collectionId);

  final String? collectionId;
  bool get isAll => collectionId == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedViewId && collectionId == other.collectionId;

  @override
  int get hashCode => collectionId.hashCode;
}

final class SavedViewState {
  SavedViewState(this.id);

  final SavedViewId id;
  SavedViewLoadState loadState = SavedViewLoadState.idle;
  SavedEntityType? selectedType;
  String query = '';
  double scrollOffset = 0;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  bool isStale = false;
  bool paginationBlocked = false;
  bool hasMore = false;
  String? nextCursor;
  Object? error;
  SavedQuotaWarning? quotaWarning;
  final List<SavedListItem> _items = <SavedListItem>[];

  List<SavedListItem> get items => List<SavedListItem>.unmodifiable(_items);
  bool get hasLoadedContent => loadState == SavedViewLoadState.loaded;
  bool get isSearching => query.trim().isNotEmpty;
}

final class SavedScreenController extends ChangeNotifier {
  SavedScreenController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 350),
    this.maxRememberedViews = 12,
    this.mutationPollInterval = const Duration(seconds: 1),
    this.maxMutationPollDuration = const Duration(seconds: 17),
    this.maxMutationPollAttempts = 17,
    Future<void> Function(Duration duration)? delay,
    SavedImageCacheEvictor? imageCacheEvictor,
  }) : _delay = delay ?? Future<void>.delayed,
       _imageCacheEvictor = imageCacheEvictor ?? _evictNetworkImage {
    if (searchDebounce.isNegative ||
        maxRememberedViews < 1 ||
        mutationPollInterval <= Duration.zero ||
        maxMutationPollDuration <= Duration.zero ||
        maxMutationPollAttempts < 1) {
      throw ArgumentError('Invalid Saved controller bounds.');
    }
    _views[const SavedViewId.all()] = SavedViewState(const SavedViewId.all());
  }

  final SavedFeatureRepository repository;
  final Future<void> Function(Duration duration) _delay;
  final SavedImageCacheEvictor _imageCacheEvictor;
  final Duration searchDebounce;
  final int maxRememberedViews;
  final Duration mutationPollInterval;
  final Duration maxMutationPollDuration;
  final int maxMutationPollAttempts;

  final LinkedHashMap<SavedViewId, SavedViewState> _views =
      LinkedHashMap<SavedViewId, SavedViewState>();
  final Map<SavedViewId, CancelToken> _requestTokens =
      <SavedViewId, CancelToken>{};
  final Map<SavedViewId, Timer> _searchTimers = <SavedViewId, Timer>{};
  final Map<SavedViewId, int> _requestEpochs = <SavedViewId, int>{};
  final Set<SavedTarget> _bootstrappingTargets = <SavedTarget>{};
  final LinkedHashSet<SavedTarget> _queuedBootstrapTargets =
      LinkedHashSet<SavedTarget>();
  final Map<SavedTarget, Object> _targetStatusErrors = <SavedTarget, Object>{};
  final Set<SavedTarget> _settlingGlobalTargets = <SavedTarget>{};
  final Set<SavedTarget> _pendingGlobalTargets = <SavedTarget>{};
  final Set<SavedCommandKey> _busyCommands = <SavedCommandKey>{};
  final Set<SavedCommandKey> _pendingCommands = <SavedCommandKey>{};

  SavedViewId _currentViewId = const SavedViewId.all();
  SavedCapabilities? _capabilities;
  List<SavedCollectionRecord> _collections = const [];
  Object? _initializationError;
  Object? _collectionsError;
  bool _isInitializing = false;
  bool _isRefreshingCollections = false;
  bool _initialized = false;
  bool _disposed = false;
  int _lifecycleEpoch = 0;
  CancelToken? _bootstrapToken;
  CancelToken? _capabilitiesToken;
  Future<void>? _capabilitiesRequest;
  Future<void>? _collectionsRefreshRequest;
  bool _bootstrapFlushScheduled = false;
  bool _isOnline = true;

  SavedCapabilities? get capabilities => _capabilities;
  List<SavedCollectionRecord> get collections => _collections;
  Object? get initializationError => _initializationError;
  Object? get collectionsError => _collectionsError;
  bool get isInitializing => _isInitializing;
  bool get isRefreshingCollections => _isRefreshingCollections;
  bool get initialized => _initialized;
  int get lifecycleEpoch => _lifecycleEpoch;
  bool get isOnline => _isOnline;
  SavedViewId get currentViewId => _currentViewId;
  SavedViewState get currentView => _viewFor(_currentViewId);
  SavedStateRegistry get registry => repository.registry;

  SavedCollectionRecord? get currentCollection {
    final id = _currentViewId.collectionId;
    if (id == null) return null;
    for (final collection in _collections) {
      if (collection.collectionId == id) return collection;
    }
    return null;
  }

  List<SavedEntityType> get availableCategories {
    final supported = _capabilities?.supportedEntityTypes ?? const {};
    const productOrder = <SavedEntityType>[
      SavedEntityType.activity,
      SavedEntityType.post,
      SavedEntityType.user,
      SavedEntityType.attraction,
    ];
    return productOrder.where(supported.contains).toList(growable: false);
  }

  bool get savedEnabled {
    final capabilities = _capabilities;
    return capabilities != null &&
        (capabilities.productFlags.savedItemsEnabled ||
            capabilities.hasConfirmedSavedData);
  }

  bool get searchEnabled => _capabilities?.productFlags.searchEnabled ?? false;
  bool get collectionsExpansionEnabled =>
      _capabilities?.productFlags.collectionsEnabled ?? false;
  bool get collectionsEnabled =>
      collectionsExpansionEnabled || _collections.isNotEmpty;
  bool get isCreatingCollection =>
      collectionsExpansionEnabled &&
      isCommandBusy(SavedCommandKey.createCollection());

  bool isTargetPending(SavedTarget target) =>
      repository.registry.isLocked(target) ||
      _settlingGlobalTargets.contains(target) ||
      _pendingGlobalTargets.contains(target);

  bool isBookmarkExpansionAvailable(SavedTarget target) {
    final capabilities = _capabilities;
    return capabilities == null ||
        (capabilities.productFlags.savedItemsEnabled &&
            capabilities.supportedEntityTypes.contains(target.entityType));
  }

  bool isTargetBootstrapping(SavedTarget target) =>
      _bootstrappingTargets.contains(target);

  bool hasTargetStatusSnapshot(SavedTarget target) => registry.contains(target);

  bool isTargetMutationRequestInFlight(SavedTarget target) =>
      _settlingGlobalTargets.contains(target);

  Object? targetStatusError(SavedTarget target) => _targetStatusErrors[target];

  bool isAssignmentPending(SavedTarget target) =>
      isCommandBusy(SavedCommandKey.assignment(target));

  bool isAssignmentRequestInFlight(SavedTarget target) =>
      _busyCommands.contains(SavedCommandKey.assignment(target));

  bool isCollectionPending(String collectionId) =>
      isCommandBusy(SavedCommandKey.collection(collectionId));

  bool isCommandBusy(SavedCommandKey key) =>
      _busyCommands.contains(key) || repository.isCommandActive(key);

  Future<void> initialize({bool force = false}) async {
    if (_isInitializing || (_initialized && !force)) return;
    final epoch = _lifecycleEpoch;
    _bootstrapToken?.cancel('Saved bootstrap superseded.');
    final token = CancelToken();
    _bootstrapToken = token;
    _isInitializing = true;
    _initializationError = null;
    _notify();
    try {
      await ensureCapabilities(force: force);
      if (!_isCurrentLifecycle(epoch) || token.isCancelled) return;
      if (_capabilities == null) return;
      _initialized = true;
      if (!savedEnabled) {
        for (final view in _views.values) {
          view.loadState = SavedViewLoadState.disabled;
          view._items.clear();
        }
        return;
      }

      final futures = <Future<void>>[
        loadCurrent(replace: true),
        refreshCollections(silent: true),
      ];
      await Future.wait(futures);
    } on Object catch (error) {
      if (_isCancellation(error) || !_isCurrentLifecycle(epoch)) return;
      _initializationError = error;
      _initialized = false;
    } finally {
      if (_isCurrentLifecycle(epoch) && identical(_bootstrapToken, token)) {
        _isInitializing = false;
        _bootstrapToken = null;
        _notify();
      }
    }
  }

  Future<void> synchronizeOnScreenEntry() async {
    if (_disposed || _isInitializing) return;
    if (!_initialized) {
      await initialize(force: _initializationError != null);
      return;
    }
    if (!savedEnabled) return;

    final view = currentView;
    if (!view.isRefreshing &&
        !view.isLoadingMore &&
        view.loadState != SavedViewLoadState.loading) {
      await refreshCurrent();
    }
  }

  Future<void> ensureCapabilities({bool force = false}) {
    if (_disposed || (!force && _capabilities != null)) {
      return Future<void>.value();
    }
    final active = _capabilitiesRequest;
    if (active != null) return active;

    final epoch = _lifecycleEpoch;
    _capabilitiesToken?.cancel('Saved capabilities superseded.');
    final token = CancelToken();
    _capabilitiesToken = token;
    final request = _loadCapabilities(epoch, token);
    _capabilitiesRequest = request;
    return request;
  }

  Future<void> _loadCapabilities(int epoch, CancelToken token) async {
    try {
      final capabilities = await repository.getCapabilities(cancelToken: token);
      if (!_isCurrentLifecycle(epoch) || token.isCancelled) return;
      _capabilities = capabilities;
      _initializationError = null;
    } on Object catch (error) {
      if (_isCancellation(error) || !_isCurrentLifecycle(epoch)) return;
      _initializationError = error;
    } finally {
      if (_isCurrentLifecycle(epoch) && identical(_capabilitiesToken, token)) {
        _capabilitiesToken = null;
        _capabilitiesRequest = null;
        _notify();
      }
    }
  }

  Future<void> selectView(SavedViewId id) async {
    if (_currentViewId == id) return;
    _currentViewId = id;
    final view = _touchView(id);
    _notify();
    if (view.loadState == SavedViewLoadState.idle ||
        view.loadState == SavedViewLoadState.error ||
        (_isOnline && (view.isStale || view.paginationBlocked))) {
      await _load(view, replace: true, refreshing: view._items.isNotEmpty);
    }
  }

  Future<void> selectCategory(SavedEntityType? type) async {
    final view = currentView;
    if (type != null && !availableCategories.contains(type)) return;
    if (view.selectedType == type) return;
    view.selectedType = type;
    view.scrollOffset = 0;
    await _load(view, replace: true);
  }

  void updateSearch(String value) {
    final view = currentView;
    if (value.runes.length > 200) return;
    view.query = value;
    _searchTimers.remove(view.id)?.cancel();
    _cancelViewRequest(view.id);
    final epoch = _lifecycleEpoch;
    if (searchDebounce == Duration.zero) {
      unawaited(_submitSearchFor(view, epoch));
    } else {
      _searchTimers[view.id] = Timer(searchDebounce, () {
        _searchTimers.remove(view.id);
        unawaited(_submitSearchFor(view, epoch));
      });
    }
    _notify();
  }

  Future<void> submitSearch() async {
    final view = currentView;
    _searchTimers.remove(view.id)?.cancel();
    await _submitSearchFor(view, _lifecycleEpoch);
  }

  Future<void> _submitSearchFor(SavedViewState view, int epoch) async {
    if (!_isCurrentLifecycle(epoch)) return;
    view.scrollOffset = 0;
    await _load(view, replace: true);
  }

  Future<void> loadCurrent({required bool replace}) {
    return _load(currentView, replace: replace);
  }

  Future<void> loadMore() async {
    final view = currentView;
    if (!view.hasMore ||
        view.isRefreshing ||
        view.loadState == SavedViewLoadState.loading ||
        view.isLoadingMore ||
        view.paginationBlocked ||
        view.nextCursor == null) {
      return;
    }
    await _load(view, replace: false);
  }

  Future<void> retryCurrent() async {
    final view = currentView;
    view.paginationBlocked = false;
    view.isStale = false;
    await _load(view, replace: true);
  }

  Future<void> refreshCurrent() async {
    final view = currentView;
    view.paginationBlocked = false;
    await _load(view, replace: true, refreshing: view._items.isNotEmpty);
  }

  void rememberScrollOffset(double offset) {
    if (!offset.isFinite || offset < 0) return;
    currentView.scrollOffset = offset;
  }

  void handleConnectivityLost() {
    final view = currentView;
    final connectivityChanged = _isOnline;
    _isOnline = false;
    if (view._items.isNotEmpty) {
      view.isStale = true;
      view.paginationBlocked = true;
    }
    if (connectivityChanged || view._items.isNotEmpty) {
      _notify();
    }
  }

  Future<void> handleConnectivityRestored() async {
    final connectivityChanged = !_isOnline;
    _isOnline = true;
    if (connectivityChanged) _notify();
    final view = currentView;
    final work = <Future<void>>[];
    if (_capabilities == null) {
      work.add(ensureCapabilities());
    }
    if (view.isStale ||
        view.paginationBlocked ||
        view.loadState == SavedViewLoadState.error) {
      work.add(retryCurrent());
    }
    for (final target in _pendingGlobalTargets.toList(growable: false)) {
      work.add(_retryPendingGlobal(target));
    }
    for (final key in _pendingCommands.toList(growable: false)) {
      work.add(_retryPendingCommand(key));
    }
    await Future.wait(work);
  }

  Future<void> refreshCollections({bool silent = false}) {
    if (!savedEnabled) return Future<void>.value();
    final activeRequest = _collectionsRefreshRequest;
    if (activeRequest != null) return activeRequest;

    late final Future<void> request;
    request = _performCollectionsRefresh(silent: silent).whenComplete(() {
      if (identical(_collectionsRefreshRequest, request)) {
        _collectionsRefreshRequest = null;
      }
    });
    _collectionsRefreshRequest = request;
    return request;
  }

  Future<void> _performCollectionsRefresh({required bool silent}) async {
    _isRefreshingCollections = true;
    if (!silent) _notify();
    final epoch = _lifecycleEpoch;
    try {
      final result = await repository.listCollections();
      if (!_isCurrentLifecycle(epoch)) return;
      final imageUrlsToEvict = _supersededCollectionCoverImageUrls(
        _collections,
        result.collections,
      );
      _collections = result.collections;
      _collectionsError = null;
      _evictImageUrlsBestEffort(imageUrlsToEvict);
      final selectedId = _currentViewId.collectionId;
      if (selectedId != null &&
          !_collections.any((item) => item.collectionId == selectedId)) {
        _currentViewId = const SavedViewId.all();
      }
    } on Object catch (error) {
      if (!_isCancellation(error) && _isCurrentLifecycle(epoch)) {
        _collectionsError = error;
      }
    } finally {
      if (_isCurrentLifecycle(epoch)) {
        _isRefreshingCollections = false;
        _notify();
      }
    }
  }

  Future<SavedTargetCollectionsSnapshot> loadTargetCollections(
    SavedTarget target, {
    CancelToken? cancelToken,
  }) {
    return repository.getTargetCollections(target, cancelToken: cancelToken);
  }

  Future<List<SavedTargetSnapshot>> bootstrapTargetStatuses(
    Iterable<SavedTarget> targets, {
    bool force = false,
  }) async {
    final requested = LinkedHashSet<SavedTarget>.of(targets)
        .where(
          (target) =>
              !_bootstrappingTargets.contains(target) &&
              (force ||
                  (!hasTargetStatusSnapshot(target) &&
                      registry.peekStateFor(target).state ==
                          SavedRegistryState.unknown)),
        )
        .toList(growable: false);
    if (requested.isEmpty) return const <SavedTargetSnapshot>[];

    final epoch = _lifecycleEpoch;
    _bootstrappingTargets.addAll(requested);
    for (final target in requested) {
      _targetStatusErrors.remove(target);
    }
    _notify();
    try {
      final statuses = await repository.bootstrapTargetStatuses(requested);
      if (!_isCurrentLifecycle(epoch)) {
        return const <SavedTargetSnapshot>[];
      }
      return statuses;
    } on Object catch (error) {
      if (_isCurrentLifecycle(epoch)) {
        for (final target in requested) {
          _targetStatusErrors[target] = error;
        }
      }
      rethrow;
    } finally {
      if (_isCurrentLifecycle(epoch)) {
        _bootstrappingTargets.removeAll(requested);
        _notify();
      }
    }
  }

  void queueTargetStatusBootstrap(SavedTarget target) {
    if (_disposed || !_isOnline) {
      return;
    }
    final state = registry.peekStateFor(target);
    if (hasTargetStatusSnapshot(target) ||
        state.state != SavedRegistryState.unknown ||
        _bootstrappingTargets.contains(target) ||
        _targetStatusErrors.containsKey(target)) {
      return;
    }
    _queuedBootstrapTargets.add(target);
    if (_bootstrapFlushScheduled) return;
    _bootstrapFlushScheduled = true;
    scheduleMicrotask(() => unawaited(_flushQueuedTargetStatuses()));
  }

  Future<void> _flushQueuedTargetStatuses() async {
    _bootstrapFlushScheduled = false;
    if (_disposed || !_isOnline || _queuedBootstrapTargets.isEmpty) return;
    final targets = _queuedBootstrapTargets
        .take(SavedApi.maxBatchSize)
        .toList(growable: false);
    _queuedBootstrapTargets.removeAll(targets);
    try {
      await bootstrapTargetStatuses(targets);
    } on Object {
      // bootstrapTargetStatuses stores one bounded error per requested target.
    }
    if (_queuedBootstrapTargets.isNotEmpty && !_bootstrapFlushScheduled) {
      _bootstrapFlushScheduled = true;
      scheduleMicrotask(() => unawaited(_flushQueuedTargetStatuses()));
    }
  }

  Future<SavedUserActionResult> saveBookmark(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  }) async {
    _requireBookmarkSurface(sourceSurface);
    if (_capabilities == null) {
      await ensureCapabilities();
    }
    if (!isBookmarkExpansionAvailable(target)) {
      return SavedUserActionResult.rejected;
    }
    final state = registry.peekStateFor(target);
    if (state.isLocked) {
      return SavedUserActionResult.pending;
    }
    if (state.shouldRenderSaved) {
      return SavedUserActionResult.noOp;
    }
    final canAttemptFromUnknown =
        state.state == SavedRegistryState.unknown &&
        hasTargetStatusSnapshot(target);
    if (!canAttemptFromUnknown &&
        (!state.shouldRenderUnsaved ||
            state.eligibility != SavedEligibility.eligible)) {
      return SavedUserActionResult.rejected;
    }
    return _runBookmarkMutation(
      target,
      () => repository.save(target, sourceSurface: sourceSurface),
    );
  }

  Future<SavedUserActionResult> unsaveBookmark(
    SavedTarget target, {
    required SavedSourceSurface sourceSurface,
  }) {
    _requireBookmarkSurface(sourceSurface);
    final state = registry.peekStateFor(target);
    if (state.isLocked) {
      return Future<SavedUserActionResult>.value(SavedUserActionResult.pending);
    }
    if (state.shouldRenderUnsaved) {
      return Future<SavedUserActionResult>.value(SavedUserActionResult.noOp);
    }
    if (!state.shouldRenderSaved) {
      return Future<SavedUserActionResult>.value(
        SavedUserActionResult.rejected,
      );
    }
    return _runBookmarkMutation(
      target,
      () => repository.unsave(target, sourceSurface: sourceSurface),
    );
  }

  Future<SavedUserActionResult> resolveBookmarkMutation(SavedTarget target) {
    if (!registry.isLocked(target)) {
      return Future<SavedUserActionResult>.value(
        SavedUserActionResult.rejected,
      );
    }
    return _runBookmarkMutation(
      target,
      () => repository.resolveLiveMutation(target),
      resolving: true,
    );
  }

  Future<SavedUserActionResult> globallyUnsave(SavedListItem item) async {
    final target = item.target;
    if (isTargetPending(target)) return SavedUserActionResult.pending;
    final epoch = _lifecycleEpoch;
    _settlingGlobalTargets.add(target);
    _notify();
    try {
      var execution = await repository.unsave(
        target,
        sourceSurface: _sourceSurfaceFor(currentViewId),
      );
      if (!_isCurrentLifecycle(epoch)) {
        return SavedUserActionResult.superseded;
      }
      if (execution.state == SavedMutationExecutionState.pending) {
        execution = await _settleGlobalMutation(target, execution, epoch);
      }
      final actionResult = _mapMutationExecution(execution);
      if (actionResult == SavedUserActionResult.pending) {
        _pendingGlobalTargets.add(target);
      } else {
        _pendingGlobalTargets.remove(target);
      }
      if (actionResult == SavedUserActionResult.applied ||
          actionResult == SavedUserActionResult.noOp) {
        _removeTargetFromRememberedViews(target, knownItem: item);
        await _refreshCollectionsAfterMutation(epoch);
      } else if (actionResult == SavedUserActionResult.expired) {
        unawaited(refreshCurrent());
      }
      return actionResult;
    } finally {
      if (_isCurrentLifecycle(epoch)) {
        _settlingGlobalTargets.remove(target);
        _notify();
      }
    }
  }

  Future<SavedUserActionResult> replaceTargetCollections({
    required SavedTargetCollectionsSnapshot current,
    required Iterable<String> desiredCollectionIds,
    String? newCollectionTitle,
    SavedSourceSurface? sourceSurface,
  }) async {
    final normalizedNewTitle = newCollectionTitle?.trim();
    if (newCollectionTitle != null && normalizedNewTitle!.isEmpty) {
      throw ArgumentError.value(
        newCollectionTitle,
        'newCollectionTitle',
        'Collection title must not be blank.',
      );
    }
    final desired = desiredCollectionIds.toSet();
    if (!collectionsExpansionEnabled &&
        (normalizedNewTitle != null ||
            desired.any(
              (collectionId) =>
                  !current.effectiveCollectionIds.contains(collectionId),
            ))) {
      return SavedUserActionResult.rejected;
    }
    final key = SavedCommandKey.assignment(current.target);
    final affectedCollectionIds = <String>{
      ...current.effectiveCollectionIds,
      ...desired,
    };
    return _runCommand(
      key,
      () => repository.replaceTargetCollections(
        current: current,
        desiredCollectionIds: desired,
        newCollectionTitle: normalizedNewTitle,
        sourceSurface: sourceSurface ?? _sourceSurfaceFor(currentViewId),
      ),
      onApplied: (execution) async {
        final snapshot = execution.serverResult?.currentResourceSnapshot;
        if (snapshot is TargetCollectionsCurrentSnapshot) {
          affectedCollectionIds.addAll(snapshot.effectiveCollectionIds);
          _replaceCollectionCount(
            snapshot.target,
            snapshot.effectiveCollectionIds.length,
          );
        }
        _invalidateRememberedCollectionViews(affectedCollectionIds);
        await _refreshCollectionsAfterMutation(_lifecycleEpoch);
        await refreshCurrent();
      },
    );
  }

  Future<SavedUserActionResult> removeFromCurrentCollection(
    SavedTargetCollectionsSnapshot current,
  ) async {
    final collectionId = currentViewId.collectionId;
    if (collectionId == null) return SavedUserActionResult.noOp;
    final desiredIds = current.effectiveCollectionIds
        .where((id) => id != collectionId)
        .toList(growable: false);
    return replaceTargetCollections(
      current: current,
      desiredCollectionIds: desiredIds,
    );
  }

  Future<SavedUserActionResult> createCollection(String title) {
    if (!collectionsExpansionEnabled) {
      return Future<SavedUserActionResult>.value(
        SavedUserActionResult.rejected,
      );
    }
    final normalizedTitle = title.trim();
    return _runCommand(
      SavedCommandKey.createCollection(),
      () => repository.createCollection(
        title: normalizedTitle,
        sourceSurface: _sourceSurfaceFor(currentViewId),
      ),
      onApplied: (_) => _refreshCollectionsAfterMutation(_lifecycleEpoch),
    );
  }

  Future<SavedUserActionResult> renameCollection(
    SavedCollectionRecord collection,
    String title,
  ) {
    final normalizedTitle = title.trim();
    return _runCommand(
      SavedCommandKey.collection(collection.collectionId),
      () => repository.renameCollection(
        collection: collection,
        title: normalizedTitle,
        sourceSurface: SavedSourceSurface.savedCollection,
      ),
      onApplied: (_) => _refreshCollectionsAfterMutation(_lifecycleEpoch),
    );
  }

  Future<SavedUserActionResult> deleteCollection(
    SavedCollectionRecord collection,
  ) {
    return _runCommand(
      SavedCommandKey.collection(collection.collectionId),
      () => repository.deleteCollection(
        collection: collection,
        sourceSurface: SavedSourceSurface.savedCollection,
      ),
      onApplied: (_) async {
        _views.remove(SavedViewId.collection(collection.collectionId));
        if (_currentViewId.collectionId == collection.collectionId) {
          _currentViewId = const SavedViewId.all();
        }
        await _refreshCollectionsAfterMutation(_lifecycleEpoch);
      },
    );
  }

  Future<SavedUserActionResult> retryCommand(
    SavedCommandKey key, {
    Future<void> Function(SavedCommandExecution execution)? onApplied,
  }) {
    return _runCommand(
      key,
      () => repository.retryCommand(key),
      onApplied: onApplied,
      allowAlreadyActive: true,
    );
  }

  void clearForLogout() {
    _evictImageUrlsBestEffort(_knownSavedImageUrls());
    _lifecycleEpoch++;
    _bootstrapToken?.cancel('Saved session cleared.');
    _bootstrapToken = null;
    _capabilitiesToken?.cancel('Saved session cleared.');
    _capabilitiesToken = null;
    _capabilitiesRequest = null;
    _collectionsRefreshRequest = null;
    for (final token in _requestTokens.values) {
      token.cancel('Saved session cleared.');
    }
    _requestTokens.clear();
    for (final timer in _searchTimers.values) {
      timer.cancel();
    }
    _searchTimers.clear();
    _requestEpochs.clear();
    _bootstrappingTargets.clear();
    _queuedBootstrapTargets.clear();
    _bootstrapFlushScheduled = false;
    _targetStatusErrors.clear();
    _settlingGlobalTargets.clear();
    _pendingGlobalTargets.clear();
    _busyCommands.clear();
    _pendingCommands.clear();
    _views
      ..clear()
      ..[const SavedViewId.all()] = SavedViewState(const SavedViewId.all());
    _currentViewId = const SavedViewId.all();
    _capabilities = null;
    _collections = const [];
    _initializationError = null;
    _collectionsError = null;
    _isInitializing = false;
    _isRefreshingCollections = false;
    _initialized = false;
    repository.clearForLogout();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _bootstrapToken?.cancel('Saved controller disposed.');
    _capabilitiesToken?.cancel('Saved controller disposed.');
    _queuedBootstrapTargets.clear();
    for (final token in _requestTokens.values) {
      token.cancel('Saved controller disposed.');
    }
    for (final timer in _searchTimers.values) {
      timer.cancel();
    }
    _requestTokens.clear();
    _searchTimers.clear();
    super.dispose();
  }

  Future<void> _load(
    SavedViewState view, {
    required bool replace,
    bool refreshing = false,
  }) async {
    if (!savedEnabled) {
      view.loadState = SavedViewLoadState.disabled;
      _notify();
      return;
    }
    if (!replace &&
        (view.isRefreshing ||
            view.loadState == SavedViewLoadState.loading ||
            view.isLoadingMore ||
            view.paginationBlocked ||
            !view.hasMore)) {
      return;
    }
    final query = view.query.trim();
    if (query.isNotEmpty && !searchEnabled) return;

    final token = CancelToken();
    if (replace) _cancelViewRequest(view.id);
    _requestTokens[view.id] = token;
    final requestEpoch = (_requestEpochs[view.id] ?? 0) + 1;
    _requestEpochs[view.id] = requestEpoch;
    final lifecycleEpoch = _lifecycleEpoch;
    if (replace) {
      if (refreshing || view._items.isNotEmpty) {
        view.isRefreshing = true;
      } else {
        view.loadState = SavedViewLoadState.loading;
      }
      view.error = null;
    } else {
      view.isLoadingMore = true;
    }
    _notify();

    try {
      final SavedPage<SavedListItem> page;
      if (query.isEmpty) {
        page = await repository.listItems(
          entityType: view.selectedType,
          collectionId: view.id.collectionId,
          cursor: replace ? null : view.nextCursor,
          cancelToken: token,
        );
      } else {
        page = await repository.searchItems(
          search: query,
          entityType: view.selectedType,
          collectionId: view.id.collectionId,
          cursor: replace ? null : view.nextCursor,
          cancelToken: token,
        );
      }
      if (!_isCurrentRequest(view.id, requestEpoch, lifecycleEpoch, token)) {
        return;
      }
      _applyPage(view, page, replace: replace, isSearch: query.isNotEmpty);
      view.loadState = SavedViewLoadState.loaded;
      view.error = null;
      view.isStale = false;
      view.paginationBlocked = false;
      _hydrateRegistry(page.items);
    } on Object catch (error) {
      if (_isCancellation(error) ||
          !_isCurrentRequest(view.id, requestEpoch, lifecycleEpoch, token)) {
        return;
      }
      view.error = error;
      if (view._items.isNotEmpty) {
        view.loadState = SavedViewLoadState.loaded;
        view.isStale = true;
        view.paginationBlocked = true;
      } else {
        view.loadState = SavedViewLoadState.error;
      }
    } finally {
      if (_isCurrentRequest(view.id, requestEpoch, lifecycleEpoch, token)) {
        view.isRefreshing = false;
        view.isLoadingMore = false;
        _requestTokens.remove(view.id);
        _notify();
      }
    }
  }

  void _applyPage(
    SavedViewState view,
    SavedPage<SavedListItem> page, {
    required bool replace,
    required bool isSearch,
  }) {
    final existingTargets = replace
        ? <SavedTarget>{}
        : view._items.map((item) => item.target).toSet();
    for (final item in page.items) {
      if (!existingTargets.add(item.target)) {
        throw const FormatException(
          'Saved pagination returned a duplicate target.',
        );
      }
    }
    if (!replace &&
        !isSearch &&
        view._items.isNotEmpty &&
        page.items.isNotEmpty) {
      final previous = view._items.last.relationship.savedAt;
      final next = page.items.first.relationship.savedAt;
      if (next.isAfter(previous)) {
        throw const FormatException(
          'Saved pagination crossed the saved_at ordering boundary.',
        );
      }
    }
    final imageUrlsToEvict = replace
        ? _supersededProjectionImageUrls(page.items)
        : const <String>{};
    if (replace) {
      _propagateAuthoritativeProjections(view, page.items);
      view._items
        ..clear()
        ..addAll(page.items);
    } else {
      view._items.addAll(page.items);
    }
    view.nextCursor = page.nextCursor;
    view.hasMore = page.hasMore;
    view.quotaWarning = page.quotaWarning;
    _evictImageUrlsBestEffort(imageUrlsToEvict);
  }

  void _hydrateRegistry(Iterable<SavedListItem> items) {
    repository.registry.hydrateBatch(
      items.map(
        (item) => SavedTargetSnapshot(
          target: item.target,
          savedState: SavedConfirmation.saved,
          eligibility: SavedEligibility.unknown,
          effectiveCollectionCount: item.effectiveCollectionCount,
          relationshipGeneration: item.relationship.generation,
          resourceVersion: item.relationship.version,
        ),
      ),
    );
  }

  Future<SavedUserActionResult> _runBookmarkMutation(
    SavedTarget target,
    Future<SavedMutationExecution> Function() action, {
    bool resolving = false,
  }) async {
    if (_settlingGlobalTargets.contains(target)) {
      return SavedUserActionResult.pending;
    }
    if (resolving) {
      if (!registry.isLocked(target)) {
        return SavedUserActionResult.rejected;
      }
    } else if (registry.isLocked(target) ||
        _pendingGlobalTargets.contains(target)) {
      return SavedUserActionResult.pending;
    }

    final epoch = _lifecycleEpoch;
    _settlingGlobalTargets.add(target);
    _targetStatusErrors.remove(target);
    _notify();
    try {
      var execution = await action();
      if (!_isCurrentLifecycle(epoch)) {
        return SavedUserActionResult.superseded;
      }
      if (execution.state == SavedMutationExecutionState.pending) {
        execution = await _settleGlobalMutation(target, execution, epoch);
      }
      if (!_isCurrentLifecycle(epoch)) {
        return SavedUserActionResult.superseded;
      }
      final result = _mapMutationExecution(execution);
      if (result == SavedUserActionResult.pending) {
        _pendingGlobalTargets.add(target);
      } else {
        _pendingGlobalTargets.remove(target);
      }
      if ((result == SavedUserActionResult.applied ||
          result == SavedUserActionResult.noOp)) {
        switch (execution.operation.kind) {
          case SavedMutationKind.save:
            unawaited(_refreshAllViewAfterConfirmedSave(epoch));
            break;
          case SavedMutationKind.unsave:
            _removeTargetFromRememberedViews(target);
            unawaited(_refreshCollectionsAfterMutation(epoch));
            break;
        }
      }
      return result;
    } on Object catch (error) {
      if (_isCurrentLifecycle(epoch)) {
        _targetStatusErrors[target] = error;
        if (!registry.isLocked(target)) {
          _pendingGlobalTargets.remove(target);
        }
      }
      rethrow;
    } finally {
      if (_isCurrentLifecycle(epoch)) {
        _settlingGlobalTargets.remove(target);
        _notify();
      }
    }
  }

  Future<SavedMutationExecution> _settleGlobalMutation(
    SavedTarget target,
    SavedMutationExecution initial,
    int epoch,
  ) async {
    var execution = initial;
    var pollAttempts = 0;
    final pollBudget = _mutationPollBudget(initial.serverResult);
    final stopwatch = Stopwatch()..start();
    while (_isCurrentLifecycle(epoch) &&
        execution.state == SavedMutationExecutionState.pending &&
        pollAttempts < maxMutationPollAttempts &&
        stopwatch.elapsed < pollBudget) {
      final remainingBudget = pollBudget - stopwatch.elapsed;
      await _delay(
        mutationPollInterval < remainingBudget
            ? mutationPollInterval
            : remainingBudget,
      );
      if (!_isCurrentLifecycle(epoch)) break;
      execution = await repository.resolveLiveMutation(target);
      pollAttempts++;
    }
    stopwatch.stop();
    return execution;
  }

  Duration _mutationPollBudget(SavedOperationResult? result) {
    if (result == null) return maxMutationPollDuration;
    final serverRemaining = result.commitDeadline.difference(
      result.resultRecordedAt,
    );
    if (serverRemaining <= Duration.zero) return Duration.zero;
    const deadlineGrace = Duration(seconds: 2);
    final budget = serverRemaining + deadlineGrace;
    return budget < maxMutationPollDuration ? budget : maxMutationPollDuration;
  }

  SavedUserActionResult _mapMutationExecution(
    SavedMutationExecution execution,
  ) {
    return switch (execution.state) {
      SavedMutationExecutionState.succeeded =>
        execution.serverResult?.outcome == SavedOperationOutcome.noOp
            ? SavedUserActionResult.noOp
            : SavedUserActionResult.applied,
      SavedMutationExecutionState.pending ||
      SavedMutationExecutionState.pendingUnknown =>
        SavedUserActionResult.pending,
      SavedMutationExecutionState.rejected => SavedUserActionResult.rejected,
      SavedMutationExecutionState.expired => SavedUserActionResult.expired,
      SavedMutationExecutionState.superseded =>
        SavedUserActionResult.superseded,
    };
  }

  Future<SavedUserActionResult> _runCommand(
    SavedCommandKey key,
    Future<SavedCommandExecution> Function() action, {
    Future<void> Function(SavedCommandExecution execution)? onApplied,
    bool allowAlreadyActive = false,
  }) async {
    if (_busyCommands.contains(key) ||
        (!allowAlreadyActive && repository.isCommandActive(key))) {
      return SavedUserActionResult.pending;
    }
    final epoch = _lifecycleEpoch;
    _busyCommands.add(key);
    _notify();
    try {
      final execution = await action();
      if (!_isCurrentLifecycle(epoch)) {
        return SavedUserActionResult.superseded;
      }
      final result = switch (execution.state) {
        SavedCommandExecutionState.succeeded =>
          execution.serverResult?.outcome == SavedOperationOutcome.noOp
              ? SavedUserActionResult.noOp
              : SavedUserActionResult.applied,
        SavedCommandExecutionState.rejected => SavedUserActionResult.rejected,
        SavedCommandExecutionState.expired => SavedUserActionResult.expired,
        SavedCommandExecutionState.pendingUnknown =>
          SavedUserActionResult.pending,
        SavedCommandExecutionState.superseded =>
          SavedUserActionResult.superseded,
      };
      if (result == SavedUserActionResult.pending) {
        _pendingCommands.add(key);
      } else {
        _pendingCommands.remove(key);
      }
      if ((result == SavedUserActionResult.applied ||
              result == SavedUserActionResult.noOp) &&
          onApplied != null) {
        await onApplied(execution);
      }
      return result;
    } finally {
      if (_isCurrentLifecycle(epoch)) {
        _busyCommands.remove(key);
        _notify();
      }
    }
  }

  Future<void> _retryPendingGlobal(SavedTarget target) async {
    try {
      await _runBookmarkMutation(
        target,
        () => repository.resolveLiveMutation(target),
        resolving: true,
      );
    } on Object {
      if (!repository.registry.isLocked(target)) {
        _pendingGlobalTargets.remove(target);
        unawaited(refreshCurrent());
      }
    }
  }

  Future<void> _retryPendingCommand(SavedCommandKey key) async {
    try {
      final result = await retryCommand(
        key,
        onApplied: (_) async {
          if (key.value.startsWith('assignment:')) {
            _invalidateAllRememberedCollectionViews();
          }
          await _refreshCollectionsAfterMutation(_lifecycleEpoch);
          await refreshCurrent();
        },
      );
      if (result != SavedUserActionResult.pending) {
        _pendingCommands.remove(key);
        _notify();
      }
    } on Object {
      if (!repository.isCommandActive(key)) {
        _pendingCommands.remove(key);
        _notify();
      }
    }
  }

  void _removeTargetFromRememberedViews(
    SavedTarget target, {
    SavedListItem? knownItem,
  }) {
    final imageUrls = <String>{};
    var collectionCoverChanged = false;
    _addImageUrl(imageUrls, _projectionImageUrl(knownItem?.projection));
    for (final view in _views.values) {
      for (final item in view._items) {
        if (item.target == target) {
          _addImageUrl(imageUrls, _projectionImageUrl(item.projection));
        }
      }
      view._items.removeWhere((item) => item.target == target);
    }
    final updatedCollections = <SavedCollectionRecord>[];
    for (final collection in _collections) {
      final cover = collection.coverPreview;
      if (cover is CollectionItemCover && cover.target == target) {
        _addImageUrl(imageUrls, cover.imageUrl);
        collectionCoverChanged = true;
        updatedCollections.add(
          _copyCollectionWithCover(collection, const GenericCollectionCover()),
        );
      } else {
        updatedCollections.add(collection);
      }
    }
    if (collectionCoverChanged) {
      _collections = List<SavedCollectionRecord>.unmodifiable(
        updatedCollections,
      );
    }
    _evictImageUrlsBestEffort(imageUrls);
    _notify();
  }

  void _invalidateRememberedCollectionViews(Iterable<String> collectionIds) {
    var changed = false;
    for (final collectionId in collectionIds.toSet()) {
      final id = SavedViewId.collection(collectionId);
      final view = _views[id];
      if (view == null) continue;
      _cancelViewRequest(id);
      _searchTimers.remove(id)?.cancel();
      view.isRefreshing = false;
      view.isLoadingMore = false;
      if (view.loadState == SavedViewLoadState.loading && view._items.isEmpty) {
        view.loadState = SavedViewLoadState.idle;
      }
      view.isStale = true;
      view.paginationBlocked = true;
      changed = true;
    }
    if (changed) _notify();
  }

  void _invalidateAllRememberedCollectionViews() {
    _invalidateRememberedCollectionViews(
      _views.keys
          .map((id) => id.collectionId)
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Future<void> _refreshAllViewAfterConfirmedSave(int epoch) async {
    if (_disposed || !_isCurrentLifecycle(epoch)) return;
    final view = _views[const SavedViewId.all()];
    if (view == null) return;
    view.isStale = true;
    view.paginationBlocked = true;
    _notify();
    if (!_initialized || !savedEnabled) return;
    await _load(view, replace: true, refreshing: view._items.isNotEmpty);
  }

  Future<void> _refreshCollectionsAfterMutation(int epoch) async {
    if (_disposed || !_isCurrentLifecycle(epoch)) return;
    final activeRequest = _collectionsRefreshRequest;
    if (activeRequest != null) {
      await activeRequest;
    }
    if (_disposed || !_isCurrentLifecycle(epoch) || !savedEnabled) return;
    await refreshCollections(silent: true);
  }

  Set<String> _supersededProjectionImageUrls(
    Iterable<SavedListItem> replacements,
  ) {
    final replacementUrls = <SavedTarget, String?>{
      for (final item in replacements)
        item.target: _projectionImageUrl(item.projection),
    };
    final imageUrls = <String>{};
    for (final view in _views.values) {
      for (final item in view._items) {
        if (!replacementUrls.containsKey(item.target)) continue;
        final oldUrl = _projectionImageUrl(item.projection);
        if (oldUrl != null && oldUrl != replacementUrls[item.target]) {
          imageUrls.add(oldUrl);
        }
      }
    }
    return imageUrls;
  }

  void _propagateAuthoritativeProjections(
    SavedViewState replacedView,
    Iterable<SavedListItem> replacements,
  ) {
    final projections = <SavedTarget, SavedCardProjection>{
      for (final item in replacements) item.target: item.projection,
    };
    for (final view in _views.values) {
      if (identical(view, replacedView)) continue;
      for (var index = 0; index < view._items.length; index++) {
        final item = view._items[index];
        final projection = projections[item.target];
        if (projection == null) continue;
        view._items[index] = _copyWithProjection(item, projection);
      }
    }
  }

  Set<String> _supersededCollectionCoverImageUrls(
    Iterable<SavedCollectionRecord> existing,
    Iterable<SavedCollectionRecord> replacements,
  ) {
    final replacementUrls = <String, String?>{
      for (final collection in replacements)
        collection.collectionId: _collectionCoverImageUrl(
          collection.coverPreview,
        ),
    };
    final imageUrls = <String>{};
    for (final collection in existing) {
      final oldUrl = _collectionCoverImageUrl(collection.coverPreview);
      if (oldUrl == null) continue;
      if (!replacementUrls.containsKey(collection.collectionId) ||
          oldUrl != replacementUrls[collection.collectionId]) {
        imageUrls.add(oldUrl);
      }
    }
    return imageUrls;
  }

  Set<String> _knownSavedImageUrls() {
    final imageUrls = <String>{};
    for (final view in _views.values) {
      for (final item in view._items) {
        _addImageUrl(imageUrls, _projectionImageUrl(item.projection));
      }
    }
    for (final collection in _collections) {
      _addImageUrl(
        imageUrls,
        _collectionCoverImageUrl(collection.coverPreview),
      );
    }
    return imageUrls;
  }

  void _evictImageUrlsBestEffort(Iterable<String> imageUrls) {
    final uniqueUrls = LinkedHashSet<String>.of(imageUrls);
    if (uniqueUrls.isEmpty) return;
    unawaited(_evictImageUrls(uniqueUrls));
  }

  Future<void> _evictImageUrls(Iterable<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      try {
        await _imageCacheEvictor(imageUrl);
      } on Object {
        // Cached image cleanup must never affect canonical Saved state.
      }
    }
  }

  void _replaceCollectionCount(SavedTarget target, int count) {
    for (final view in _views.values) {
      final index = view._items.indexWhere((item) => item.target == target);
      if (index < 0) continue;
      final item = view._items[index];
      view._items[index] = item is SavedSearchItem
          ? SavedSearchItem(
              target: item.target,
              relationship: item.relationship,
              effectiveCollectionCount: count,
              projection: item.projection,
              match: item.match,
            )
          : SavedListItem(
              target: item.target,
              relationship: item.relationship,
              effectiveCollectionCount: count,
              projection: item.projection,
            );
    }
  }

  SavedViewState _viewFor(SavedViewId id) {
    return _views[id] ?? _touchView(id);
  }

  SavedViewState _touchView(SavedViewId id) {
    final existing = _views.remove(id);
    final view = existing ?? SavedViewState(id);
    _views[id] = view;
    while (_views.length > maxRememberedViews) {
      final candidate = _views.keys.firstWhere(
        (key) => key != _currentViewId,
        orElse: () => _views.keys.first,
      );
      _cancelViewRequest(candidate);
      _searchTimers.remove(candidate)?.cancel();
      _requestEpochs.remove(candidate);
      _views.remove(candidate);
    }
    return view;
  }

  void _cancelViewRequest(SavedViewId id) {
    _requestTokens.remove(id)?.cancel('Saved view request superseded.');
  }

  bool _isCurrentRequest(
    SavedViewId id,
    int requestEpoch,
    int lifecycleEpoch,
    CancelToken token,
  ) {
    return _isCurrentLifecycle(lifecycleEpoch) &&
        !token.isCancelled &&
        _requestEpochs[id] == requestEpoch &&
        identical(_requestTokens[id], token);
  }

  bool _isCurrentLifecycle(int epoch) => !_disposed && epoch == _lifecycleEpoch;

  bool _isCancellation(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel ||
        error is SavedApiException &&
            error.cause.type == DioExceptionType.cancel;
  }

  SavedSourceSurface _sourceSurfaceFor(SavedViewId id) {
    return id.isAll
        ? SavedSourceSurface.savedAll
        : SavedSourceSurface.savedCollection;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

void _requireBookmarkSurface(SavedSourceSurface sourceSurface) {
  if (sourceSurface != SavedSourceSurface.card &&
      sourceSurface != SavedSourceSurface.detail) {
    throw ArgumentError.value(
      sourceSurface,
      'sourceSurface',
      'Bookmark mutations must originate from CARD or DETAIL.',
    );
  }
}

String? _projectionImageUrl(SavedCardProjection? projection) {
  if (projection is! AvailableSavedCardProjection) return null;
  return projection.imageUrl?.toString();
}

SavedListItem _copyWithProjection(
  SavedListItem item,
  SavedCardProjection projection,
) {
  if (item is SavedSearchItem) {
    return SavedSearchItem(
      target: item.target,
      relationship: item.relationship,
      effectiveCollectionCount: item.effectiveCollectionCount,
      projection: projection,
      match: item.match,
    );
  }
  return SavedListItem(
    target: item.target,
    relationship: item.relationship,
    effectiveCollectionCount: item.effectiveCollectionCount,
    projection: projection,
  );
}

SavedCollectionRecord _copyCollectionWithCover(
  SavedCollectionRecord collection,
  CollectionCoverPreview coverPreview,
) {
  return SavedCollectionRecord(
    collectionId: collection.collectionId,
    title: collection.title,
    metadataVersion: collection.metadataVersion,
    lifecycleVersion: collection.lifecycleVersion,
    activeItemCount: collection.activeItemCount,
    coverPreview: coverPreview,
    organizedAt: collection.organizedAt,
    createdAt: collection.createdAt,
    updatedAt: collection.updatedAt,
  );
}

String? _collectionCoverImageUrl(CollectionCoverPreview cover) {
  if (cover is! CollectionItemCover) return null;
  return cover.imageUrl;
}

void _addImageUrl(Set<String> imageUrls, String? imageUrl) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    imageUrls.add(imageUrl);
  }
}

Future<bool> _evictNetworkImage(String imageUrl) {
  return NetworkImage(imageUrl).evict();
}
