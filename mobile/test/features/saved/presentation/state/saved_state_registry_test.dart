import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/domain/saved_status.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';
import 'package:inflap/features/saved/presentation/state/saved_state_registry.dart';

void main() {
  test('cache miss remains UNKNOWN and is never rendered as unsaved', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final state = registry.stateFor(_target('missing'));

    expect(state.state, SavedRegistryState.unknown);
    expect(state.shouldRenderSaved, isFalse);
    expect(state.shouldRenderUnsaved, isFalse);
    expect(state.effectiveCollectionCount, isNull);
    expect(registry.length, 0);
  });

  test('global LRU stays bounded and access refreshes recency', () {
    final registry = SavedStateRegistry(capacity: 2);
    addTearDown(registry.dispose);
    final first = _target('first');
    final second = _target('second');
    final third = _target('third');

    registry.hydrateBatch(<SavedTargetSnapshot>[
      _snapshot(first, saved: true, version: 1),
      _snapshot(second, saved: false, version: 1),
    ]);
    registry.stateFor(first);
    registry.applySnapshot(_snapshot(third, saved: true, version: 1));

    expect(registry.length, 2);
    expect(registry.contains(first), isTrue);
    expect(registry.contains(second), isFalse);
    expect(registry.contains(third), isTrue);
    expect(registry.stateFor(second).state, SavedRegistryState.unknown);
  });

  test('default registry is a bounded 500-entry LRU', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);

    for (var index = 0; index <= 500; index++) {
      final target = _target('target-$index');
      registry.applySnapshot(_snapshot(target, saved: true, version: 1));
    }

    expect(registry.capacity, 500);
    expect(registry.length, 500);
    expect(registry.contains(_target('target-0')), isFalse);
    expect(registry.contains(_target('target-500')), isTrue);
    expect(() => SavedStateRegistry(capacity: 501), throwsArgumentError);
  });

  test('explicit batch UNKNOWN remains unresolved and never looks unsaved', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('explicit-unknown');
    registry.applySnapshot(_snapshot(target, saved: true, version: 3));

    registry.applySnapshot(
      SavedTargetSnapshot(
        target: target,
        savedState: SavedConfirmation.unknown,
        eligibility: SavedEligibility.unknown,
        effectiveCollectionCount: 0,
        resourceVersion: 4,
      ),
    );

    final state = registry.stateFor(target);
    expect(state.state, SavedRegistryState.unknown);
    expect(state.confirmedState, isNull);
    expect(state.shouldRenderSaved, isFalse);
    expect(state.shouldRenderUnsaved, isFalse);
    expect(state.resourceVersion, 4);
  });

  test('identical explicit UNKNOWN snapshot is idempotent', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('idempotent-unknown');
    final snapshot = SavedTargetSnapshot(
      target: target,
      savedState: SavedConfirmation.unknown,
      eligibility: SavedEligibility.unknown,
      effectiveCollectionCount: 0,
      resourceVersion: 0,
    );
    var notifications = 0;
    registry.addListener(() => notifications++);

    expect(registry.applySnapshot(snapshot), isTrue);
    expect(registry.applySnapshot(snapshot), isFalse);

    expect(notifications, 1);
    expect(registry.contains(target), isTrue);
  });

  test('older and equal resource versions cannot roll state back', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('versioned');

    expect(
      registry.applySnapshot(_snapshot(target, saved: true, version: 10)),
      isTrue,
    );
    expect(
      registry.applySnapshot(_snapshot(target, saved: false, version: 9)),
      isFalse,
    );
    expect(
      registry.applySnapshot(_snapshot(target, saved: false, version: 10)),
      isFalse,
    );

    final state = registry.stateFor(target);
    expect(state.state, SavedRegistryState.confirmedSaved);
    expect(state.resourceVersion, 10);
    expect(state.shouldRenderSaved, isTrue);
  });

  test('target remains locked through pending and pending unknown states', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('locked');
    registry.applySnapshot(_snapshot(target, saved: false, version: 2));

    registry.beginMutation(target, 'operation-1');
    expect(registry.stateFor(target).state, SavedRegistryState.pending);
    expect(registry.stateFor(target).shouldRenderUnsaved, isTrue);
    expect(
      () => registry.beginMutation(target, 'operation-2'),
      throwsA(isA<SavedTargetLockedException>()),
    );

    registry.markPendingUnknown(target, 'operation-1');
    expect(registry.stateFor(target).state, SavedRegistryState.pendingUnknown);
    expect(registry.isLocked(target), isTrue);
  });

  test('unknown terminal state preserves monotonic version for rehydrate', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('unknown-terminal');
    registry.applySnapshot(_snapshot(target, saved: false, version: 10));
    registry.beginMutation(target, 'operation-unknown');

    registry.finishMutationAsUnknown(target, 'operation-unknown');

    expect(registry.stateFor(target).state, SavedRegistryState.unknown);
    expect(registry.stateFor(target).resourceVersion, 10);
    expect(
      registry.applySnapshot(_snapshot(target, saved: true, version: 9)),
      isFalse,
    );
    expect(
      registry.applySnapshot(_snapshot(target, saved: true, version: 10)),
      isTrue,
    );
    expect(registry.stateFor(target).state, SavedRegistryState.confirmedSaved);
  });

  test('logout hook clears all personal and operation state', () {
    final registry = SavedStateRegistry();
    addTearDown(registry.dispose);
    final target = _target('logout');
    registry.applySnapshot(_snapshot(target, saved: true, version: 7));
    registry.beginMutation(target, 'operation-logout');

    registry.clearForLogout();

    expect(registry.isEmpty, isTrue);
    expect(registry.isLocked(target), isFalse);
    expect(registry.stateFor(target).state, SavedRegistryState.unknown);
  });
}

SavedTarget _target(String id) {
  return SavedTarget(entityType: SavedEntityType.guide, entityId: id);
}

SavedTargetSnapshot _snapshot(
  SavedTarget target, {
  required bool saved,
  required int version,
}) {
  return SavedTargetSnapshot(
    target: target,
    savedState: saved
        ? SavedConfirmation.saved
        : SavedConfirmation.confirmedUnsaved,
    eligibility: SavedEligibility.eligible,
    effectiveCollectionCount: 0,
    relationshipGeneration: saved
        ? 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
        : null,
    resourceVersion: version,
  );
}
