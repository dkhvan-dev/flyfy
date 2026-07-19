import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../domain/saved_status.dart';
import '../../domain/saved_target.dart';

enum SavedRegistryState {
  unknown('UNKNOWN'),
  confirmedSaved('CONFIRMED_SAVED'),
  confirmedUnsaved('CONFIRMED_UNSAVED'),
  pending('PENDING'),
  pendingUnknown('PENDING_UNKNOWN');

  const SavedRegistryState(this.wireValue);

  final String wireValue;
}

@immutable
final class SavedTargetState {
  const SavedTargetState._({
    required this.state,
    required this.confirmedState,
    required this.eligibility,
    required this.effectiveCollectionCount,
    required this.relationshipGeneration,
    required this.resourceVersion,
    required this.operationId,
  });

  const SavedTargetState.unknown()
    : this._(
        state: SavedRegistryState.unknown,
        confirmedState: null,
        eligibility: SavedEligibility.unknown,
        effectiveCollectionCount: null,
        relationshipGeneration: null,
        resourceVersion: null,
        operationId: null,
      );

  final SavedRegistryState state;
  final SavedConfirmation? confirmedState;
  final SavedEligibility eligibility;
  final int? effectiveCollectionCount;
  final String? relationshipGeneration;
  final int? resourceVersion;
  final String? operationId;

  bool get isLocked => operationId != null;

  bool get shouldRenderSaved =>
      state != SavedRegistryState.unknown &&
      confirmedState == SavedConfirmation.saved;

  bool get shouldRenderUnsaved =>
      state != SavedRegistryState.unknown &&
      confirmedState == SavedConfirmation.confirmedUnsaved;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SavedTargetState &&
            state == other.state &&
            confirmedState == other.confirmedState &&
            eligibility == other.eligibility &&
            effectiveCollectionCount == other.effectiveCollectionCount &&
            relationshipGeneration == other.relationshipGeneration &&
            resourceVersion == other.resourceVersion &&
            operationId == other.operationId;
  }

  @override
  int get hashCode => Object.hash(
    state,
    confirmedState,
    eligibility,
    effectiveCollectionCount,
    relationshipGeneration,
    resourceVersion,
    operationId,
  );
}

final class SavedStateRegistry extends ChangeNotifier {
  SavedStateRegistry({int capacity = maxCapacity})
    : capacity = _requireCapacity(capacity);

  static const int maxCapacity = 500;

  final int capacity;
  final LinkedHashMap<SavedTarget, SavedTargetState> _entries =
      LinkedHashMap<SavedTarget, SavedTargetState>();

  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;

  Iterable<SavedTarget> get cachedTargets =>
      List<SavedTarget>.unmodifiable(_entries.keys);

  SavedTargetState stateFor(SavedTarget target) {
    final existing = _entries.remove(target);
    if (existing == null) {
      return const SavedTargetState.unknown();
    }
    _entries[target] = existing;
    return existing;
  }

  SavedTargetState peekStateFor(SavedTarget target) {
    return _entries[target] ?? const SavedTargetState.unknown();
  }

  bool contains(SavedTarget target) => _entries.containsKey(target);

  bool isLocked(SavedTarget target) => _entries[target]?.isLocked ?? false;

  void hydrateBatch(Iterable<SavedTargetSnapshot> snapshots) {
    var changed = false;
    for (final snapshot in snapshots) {
      changed = _applySnapshot(snapshot) || changed;
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool applySnapshot(SavedTargetSnapshot snapshot) {
    final changed = _applySnapshot(snapshot);
    if (changed) {
      notifyListeners();
    }
    return changed;
  }

  void beginMutation(SavedTarget target, String operationId) {
    if (operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Must not be empty.',
      );
    }
    final current = _entries.remove(target) ?? const SavedTargetState.unknown();
    if (current.isLocked) {
      _entries[target] = current;
      throw SavedTargetLockedException(target);
    }
    _makeRoomFor(target);
    _entries[target] = SavedTargetState._(
      state: SavedRegistryState.pending,
      confirmedState: current.confirmedState,
      eligibility: current.eligibility,
      effectiveCollectionCount: current.effectiveCollectionCount,
      relationshipGeneration: current.relationshipGeneration,
      resourceVersion: current.resourceVersion,
      operationId: operationId,
    );
    notifyListeners();
  }

  bool markPending(SavedTarget target, String operationId) {
    return _setPendingState(target, operationId, SavedRegistryState.pending);
  }

  bool markPendingUnknown(SavedTarget target, String operationId) {
    return _setPendingState(
      target,
      operationId,
      SavedRegistryState.pendingUnknown,
    );
  }

  bool confirmMutation(
    SavedTarget target,
    String operationId,
    SavedTargetSnapshot snapshot,
  ) {
    if (snapshot.target != target) {
      throw ArgumentError.value(
        snapshot.target,
        'snapshot',
        'Snapshot target does not match the mutation target.',
      );
    }
    final current = _entries[target];
    if (!_matchesOperation(current, operationId)) {
      return false;
    }

    _applySnapshot(snapshot);
    final hydrated = _entries.remove(target);
    if (hydrated == null || hydrated.operationId != operationId) {
      return false;
    }
    _entries[target] = _withoutOperation(hydrated);
    notifyListeners();
    return true;
  }

  bool rejectMutation(SavedTarget target, String operationId) {
    final current = _entries.remove(target);
    if (!_matchesOperation(current, operationId)) {
      if (current != null) {
        _entries[target] = current;
      }
      return false;
    }
    _entries[target] = _withoutOperation(current!);
    notifyListeners();
    return true;
  }

  bool finishMutationAsUnknown(SavedTarget target, String operationId) {
    final current = _entries.remove(target);
    if (!_matchesOperation(current, operationId)) {
      if (current != null) {
        _entries[target] = current;
      }
      return false;
    }
    _entries[target] = SavedTargetState._(
      state: SavedRegistryState.unknown,
      confirmedState: null,
      eligibility: current!.eligibility,
      effectiveCollectionCount: null,
      relationshipGeneration: null,
      resourceVersion: current.resourceVersion,
      operationId: null,
    );
    notifyListeners();
    return true;
  }

  int evictLeastRecentlyUsed({int count = 1}) {
    if (count <= 0 || _entries.isEmpty) {
      return 0;
    }

    var removed = 0;
    final candidates = _entries.entries
        .where((entry) => !entry.value.isLocked)
        .map((entry) => entry.key)
        .take(count)
        .toList(growable: false);
    for (final target in candidates) {
      if (_entries.remove(target) != null) {
        removed++;
      }
    }
    if (removed > 0) {
      notifyListeners();
    }
    return removed;
  }

  void clearForLogout() {
    if (_entries.isEmpty) {
      return;
    }
    _entries.clear();
    notifyListeners();
  }

  bool _setPendingState(
    SavedTarget target,
    String operationId,
    SavedRegistryState state,
  ) {
    final current = _entries.remove(target);
    if (!_matchesOperation(current, operationId)) {
      if (current != null) {
        _entries[target] = current;
      }
      return false;
    }
    if (current!.state == state) {
      _entries[target] = current;
      return false;
    }
    _entries[target] = SavedTargetState._(
      state: state,
      confirmedState: current.confirmedState,
      eligibility: current.eligibility,
      effectiveCollectionCount: current.effectiveCollectionCount,
      relationshipGeneration: current.relationshipGeneration,
      resourceVersion: current.resourceVersion,
      operationId: current.operationId,
    );
    notifyListeners();
    return true;
  }

  bool _applySnapshot(SavedTargetSnapshot snapshot) {
    final current = _entries.remove(snapshot.target);
    if (current != null) {
      final currentVersion = current.resourceVersion;
      if (currentVersion != null &&
          (snapshot.resourceVersion < currentVersion ||
              (snapshot.resourceVersion == currentVersion &&
                  current.confirmedState != null))) {
        _entries[snapshot.target] = current;
        return false;
      }
    } else {
      _makeRoomFor(snapshot.target);
    }

    final confirmedState = snapshot.savedState == SavedConfirmation.unknown
        ? null
        : snapshot.savedState;
    final state = current?.isLocked == true
        ? current!.state
        : _confirmedRegistryState(snapshot.savedState);
    final next = SavedTargetState._(
      state: state,
      confirmedState: confirmedState,
      eligibility: snapshot.eligibility,
      effectiveCollectionCount: snapshot.effectiveCollectionCount,
      relationshipGeneration: snapshot.relationshipGeneration,
      resourceVersion: snapshot.resourceVersion,
      operationId: current?.operationId,
    );
    _entries[snapshot.target] = next;
    return current != next;
  }

  void _makeRoomFor(SavedTarget target) {
    if (_entries.containsKey(target)) {
      return;
    }
    while (_entries.length >= capacity) {
      SavedTarget? evictionTarget;
      for (final entry in _entries.entries) {
        if (!entry.value.isLocked) {
          evictionTarget = entry.key;
          break;
        }
      }
      if (evictionTarget == null) {
        throw SavedRegistryCapacityException(capacity);
      }
      _entries.remove(evictionTarget);
    }
  }

  SavedTargetState _withoutOperation(SavedTargetState state) {
    final confirmedState = state.confirmedState;
    return SavedTargetState._(
      state: confirmedState == null
          ? SavedRegistryState.unknown
          : _confirmedRegistryState(confirmedState),
      confirmedState: confirmedState,
      eligibility: state.eligibility,
      effectiveCollectionCount: state.effectiveCollectionCount,
      relationshipGeneration: state.relationshipGeneration,
      resourceVersion: state.resourceVersion,
      operationId: null,
    );
  }

  bool _matchesOperation(SavedTargetState? state, String operationId) {
    return state != null && state.operationId == operationId;
  }
}

SavedRegistryState _confirmedRegistryState(SavedConfirmation confirmation) {
  return switch (confirmation) {
    SavedConfirmation.saved => SavedRegistryState.confirmedSaved,
    SavedConfirmation.confirmedUnsaved => SavedRegistryState.confirmedUnsaved,
    SavedConfirmation.unknown => SavedRegistryState.unknown,
  };
}

int _requireCapacity(int value) {
  if (value <= 0 || value > SavedStateRegistry.maxCapacity) {
    throw ArgumentError.value(
      value,
      'capacity',
      'Must be between 1 and ${SavedStateRegistry.maxCapacity}.',
    );
  }
  return value;
}

final class SavedTargetLockedException implements Exception {
  const SavedTargetLockedException(this.target);

  final SavedTarget target;

  @override
  String toString() => 'A Saved mutation is already active for this target.';
}

final class SavedRegistryCapacityException implements Exception {
  const SavedRegistryCapacityException(this.capacity);

  final int capacity;

  @override
  String toString() => 'Saved state registry capacity is exhausted.';
}
