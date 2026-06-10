import 'dart:async';

enum StoryEditorAutosavePhase {
  idle,
  waiting,
  saving,
  retrying,
  saved,
  offlineSnapshotSaved,
  failed,
}

class StoryEditorAutosaveState {
  const StoryEditorAutosaveState({
    required this.phase,
    this.attempt = 0,
    this.nextRetryDelay,
    this.error,
  });

  const StoryEditorAutosaveState.idle()
    : this(phase: StoryEditorAutosavePhase.idle);

  final StoryEditorAutosavePhase phase;
  final int attempt;
  final Duration? nextRetryDelay;
  final Object? error;
}

class StoryEditorAutosaveWork {
  StoryEditorAutosaveWork({
    required this.storyId,
    required this.saveRemote,
    required this.saveLocalSnapshot,
    this.isTransientFailure,
  });

  final String? storyId;
  final Future<void> Function() saveRemote;
  final Future<bool> Function() saveLocalSnapshot;
  final bool Function(Object error)? isTransientFailure;

  bool get hasRemoteStory => (storyId ?? '').trim().isNotEmpty;
}

class StoryEditorTransientAutosaveException implements Exception {
  const StoryEditorTransientAutosaveException(this.message);

  final String message;

  @override
  String toString() => 'StoryEditorTransientAutosaveException: $message';
}

class StoryEditorLocalSnapshotFailed implements Exception {
  const StoryEditorLocalSnapshotFailed([
    this.message = 'Story editor recovery snapshot was not persisted.',
  ]);

  final String message;

  @override
  String toString() => 'StoryEditorLocalSnapshotFailed: $message';
}

class StoryEditorAutosavePolicy {
  StoryEditorAutosavePolicy({
    this.debounceDuration = const Duration(milliseconds: 750),
    this.initialRetryDelay = const Duration(seconds: 1),
    this.maxRemoteAttempts = 3,
    this.retryBackoffFactor = 2,
    this.onStateChanged,
  }) : assert(maxRemoteAttempts > 0),
       assert(retryBackoffFactor >= 1);

  final Duration debounceDuration;
  final Duration initialRetryDelay;
  final int maxRemoteAttempts;
  final num retryBackoffFactor;
  final void Function(StoryEditorAutosaveState state)? onStateChanged;

  StoryEditorAutosaveState _state = const StoryEditorAutosaveState.idle();
  Timer? _debounceTimer;
  Timer? _retryTimer;
  int _sequence = 0;
  bool _isDisposed = false;
  bool _remoteInProgress = false;
  _QueuedAutosaveWork? _queuedRemoteWork;
  Future<void> _localSnapshotChain = Future<void>.value();

  StoryEditorAutosaveState get state => _state;

  void recordMeaningfulEdit(StoryEditorAutosaveWork work) {
    if (_isDisposed) return;
    final queuedWork = _nextWork(work);
    _emit(
      const StoryEditorAutosaveState(phase: StoryEditorAutosavePhase.waiting),
    );
    _debounceTimer = Timer(debounceDuration, () {
      _prepareWork(queuedWork);
    });
  }

  void recordPublishCriticalMetadataChange(StoryEditorAutosaveWork work) {
    if (_isDisposed) return;
    _prepareWork(_nextWork(work));
  }

  void dispose() {
    _isDisposed = true;
    _sequence++;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _queuedRemoteWork = null;
  }

  _QueuedAutosaveWork _nextWork(StoryEditorAutosaveWork work) {
    _debounceTimer?.cancel();
    if (_retryTimer != null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _remoteInProgress = false;
    }
    _sequence++;
    return _QueuedAutosaveWork(work: work, sequence: _sequence);
  }

  void _prepareWork(_QueuedAutosaveWork queuedWork) {
    if (!_isCurrent(queuedWork.sequence)) return;
    _emit(
      const StoryEditorAutosaveState(phase: StoryEditorAutosavePhase.saving),
    );
    unawaited(_saveLocalSnapshotThenQueue(queuedWork));
  }

  Future<void> _saveLocalSnapshotThenQueue(
    _QueuedAutosaveWork queuedWork,
  ) async {
    if (!_isCurrent(queuedWork.sequence)) return;

    final localSnapshotSaved = await _enqueueLocalSnapshotWrite(queuedWork);
    if (!_isCurrent(queuedWork.sequence)) return;
    if (!localSnapshotSaved) {
      return;
    }

    if (!queuedWork.work.hasRemoteStory) {
      _emit(
        const StoryEditorAutosaveState(
          phase: StoryEditorAutosavePhase.offlineSnapshotSaved,
        ),
      );
      return;
    }

    _enqueueRemoteWork(queuedWork);
  }

  Future<bool> _enqueueLocalSnapshotWrite(_QueuedAutosaveWork queuedWork) {
    final write = _localSnapshotChain.then((_) async {
      try {
        final saved = await queuedWork.work.saveLocalSnapshot();
        if (!saved) {
          if (_isCurrent(queuedWork.sequence)) {
            _emit(
              const StoryEditorAutosaveState(
                phase: StoryEditorAutosavePhase.failed,
                error: StoryEditorLocalSnapshotFailed(),
              ),
            );
          }
          return false;
        }
        return saved;
      } catch (snapshotError) {
        if (_isCurrent(queuedWork.sequence)) {
          _emit(
            StoryEditorAutosaveState(
              phase: StoryEditorAutosavePhase.failed,
              error: snapshotError,
            ),
          );
        }
        return false;
      }
    });
    _localSnapshotChain = write.then<void>((_) {}, onError: (_) {});
    return write;
  }

  void _enqueueRemoteWork(_QueuedAutosaveWork queuedWork) {
    if (!_isCurrent(queuedWork.sequence)) return;

    _queuedRemoteWork = queuedWork;
    if (_retryTimer != null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _remoteInProgress = false;
    }
    _drainRemoteQueue();
  }

  void _drainRemoteQueue() {
    if (_isDisposed || _remoteInProgress) return;
    final nextWork = _queuedRemoteWork;
    if (nextWork == null) return;

    _queuedRemoteWork = null;
    unawaited(
      _attemptRemoteSave(nextWork, attempt: 1, retryDelay: initialRetryDelay),
    );
  }

  Future<void> _attemptRemoteSave(
    _QueuedAutosaveWork queuedWork, {
    required int attempt,
    required Duration retryDelay,
  }) async {
    if (_isDisposed) return;
    _remoteInProgress = true;
    _emit(
      StoryEditorAutosaveState(
        phase: StoryEditorAutosavePhase.saving,
        attempt: attempt,
      ),
    );

    try {
      await queuedWork.work.saveRemote();
      if (_isDisposed) return;
      _remoteInProgress = false;
      if (_queuedRemoteWork != null) {
        _drainRemoteQueue();
        return;
      }
      if (_isCurrent(queuedWork.sequence)) {
        _emit(
          StoryEditorAutosaveState(
            phase: StoryEditorAutosavePhase.saved,
            attempt: attempt,
          ),
        );
      }
    } catch (error) {
      if (_isDisposed) return;
      if (_queuedRemoteWork != null) {
        _remoteInProgress = false;
        _drainRemoteQueue();
        return;
      }
      final shouldRetry =
          _isTransient(error, queuedWork.work) && attempt < maxRemoteAttempts;
      if (shouldRetry) {
        _emit(
          StoryEditorAutosaveState(
            phase: StoryEditorAutosavePhase.retrying,
            attempt: attempt,
            nextRetryDelay: retryDelay,
            error: error,
          ),
        );
        _retryTimer = Timer(retryDelay, () {
          _retryTimer = null;
          if (!_isCurrent(queuedWork.sequence)) {
            _remoteInProgress = false;
            _drainRemoteQueue();
            return;
          }
          unawaited(
            _attemptRemoteSave(
              queuedWork,
              attempt: attempt + 1,
              retryDelay: _nextRetryDelay(retryDelay),
            ),
          );
        });
        return;
      }

      _remoteInProgress = false;
      if (_isCurrent(queuedWork.sequence)) {
        _emit(
          StoryEditorAutosaveState(
            phase: StoryEditorAutosavePhase.offlineSnapshotSaved,
            attempt: attempt,
            error: error,
          ),
        );
      }
      _drainRemoteQueue();
    }
  }

  bool _isTransient(Object error, StoryEditorAutosaveWork work) {
    return error is StoryEditorTransientAutosaveException ||
        (work.isTransientFailure?.call(error) ?? false);
  }

  Duration _nextRetryDelay(Duration current) {
    final nextMilliseconds = (current.inMilliseconds * retryBackoffFactor)
        .round();
    return Duration(milliseconds: nextMilliseconds);
  }

  bool _isCurrent(int sequence) {
    return !_isDisposed && sequence == _sequence;
  }

  void _emit(StoryEditorAutosaveState state) {
    if (_isDisposed) return;
    _state = state;
    onStateChanged?.call(state);
  }
}

class _QueuedAutosaveWork {
  const _QueuedAutosaveWork({required this.work, required this.sequence});

  final StoryEditorAutosaveWork work;
  final int sequence;
}
