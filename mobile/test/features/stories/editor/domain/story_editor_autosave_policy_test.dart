import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/domain/story_editor_autosave_policy.dart';

void main() {
  group('StoryEditorAutosavePolicy', () {
    testWidgets('debounces meaningful text and block edits', (tester) async {
      var remoteSaves = 0;
      final policy = StoryEditorAutosavePolicy(
        debounceDuration: const Duration(milliseconds: 300),
      );

      policy.recordMeaningfulEdit(
        _work(onRemoteSave: () async => remoteSaves++),
      );
      policy.recordMeaningfulEdit(
        _work(onRemoteSave: () async => remoteSaves++),
      );

      await tester.pump(const Duration(milliseconds: 299));
      expect(remoteSaves, 0);
      expect(policy.state.phase, StoryEditorAutosavePhase.waiting);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(remoteSaves, 1);
      expect(policy.state.phase, StoryEditorAutosavePhase.saved);

      policy.dispose();
    });

    testWidgets(
      'saves publish-critical metadata immediately for remote stories',
      (tester) async {
        var remoteSaves = 0;
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(seconds: 30),
        );

        policy.recordPublishCriticalMetadataChange(
          _work(onRemoteSave: () async => remoteSaves++),
        );
        await tester.pump();

        expect(remoteSaves, 1);
        expect(policy.state.phase, StoryEditorAutosavePhase.saved);

        policy.dispose();
      },
    );

    testWidgets('retries transient remote failures with exponential backoff', (
      tester,
    ) async {
      var attempts = 0;
      final phases = <StoryEditorAutosavePhase>[];
      final retryDelays = <Duration>[];
      final policy = StoryEditorAutosavePolicy(
        debounceDuration: const Duration(milliseconds: 10),
        initialRetryDelay: const Duration(seconds: 1),
        maxRemoteAttempts: 3,
        onStateChanged: (state) {
          phases.add(state.phase);
          if (state.nextRetryDelay != null) {
            retryDelays.add(state.nextRetryDelay!);
          }
        },
      );

      policy.recordMeaningfulEdit(
        _work(
          onRemoteSave: () async {
            attempts++;
            if (attempts < 3) {
              throw const StoryEditorTransientAutosaveException('offline');
            }
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(attempts, 1);
      expect(policy.state.phase, StoryEditorAutosavePhase.retrying);
      expect(retryDelays, [const Duration(seconds: 1)]);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(attempts, 2);
      expect(policy.state.phase, StoryEditorAutosavePhase.retrying);
      expect(retryDelays, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(attempts, 3);
      expect(policy.state.phase, StoryEditorAutosavePhase.saved);
      expect(phases, contains(StoryEditorAutosavePhase.saving));

      policy.dispose();
    });

    testWidgets(
      'serializes remote saves and coalesces a new edit while one is in flight',
      (tester) async {
        final firstRemote = Completer<void>();
        final remoteCalls = <String>[];
        final localSnapshots = <String>[];
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
        );

        policy.recordMeaningfulEdit(
          _work(
            label: 'first',
            onRemoteSave: () {
              remoteCalls.add('first');
              return firstRemote.future;
            },
            onLocalSnapshotSave: () async {
              localSnapshots.add('first');
              return true;
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        policy.recordMeaningfulEdit(
          _work(
            label: 'second',
            onRemoteSave: () async => remoteCalls.add('second'),
            onLocalSnapshotSave: () async {
              localSnapshots.add('second');
              return true;
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(localSnapshots, ['first', 'second']);
        expect(remoteCalls, ['first']);

        firstRemote.complete();
        await tester.pump();
        await tester.pump();

        expect(remoteCalls, ['first', 'second']);
        expect(policy.state.phase, StoryEditorAutosavePhase.saved);

        policy.dispose();
      },
    );

    testWidgets(
      'writes local recovery before remote autosave completes or retries',
      (tester) async {
        final remote = Completer<void>();
        final events = <String>[];
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
          initialRetryDelay: const Duration(seconds: 1),
        );

        policy.recordMeaningfulEdit(
          _work(
            onLocalSnapshotSave: () async {
              events.add('local');
              return true;
            },
            onRemoteSave: () {
              events.add('remote-start');
              return remote.future;
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(events, ['local', 'remote-start']);
        expect(policy.state.phase, StoryEditorAutosavePhase.saving);

        remote.completeError(
          const StoryEditorTransientAutosaveException('timeout'),
        );
        await tester.pump();

        expect(events, ['local', 'remote-start']);
        expect(policy.state.phase, StoryEditorAutosavePhase.retrying);

        policy.dispose();
      },
    );

    testWidgets('new edit during retry backoff cancels stale retry payload', (
      tester,
    ) async {
      final secondLocal = Completer<bool>();
      final remoteCalls = <String>[];
      final policy = StoryEditorAutosavePolicy(
        debounceDuration: const Duration(milliseconds: 10),
        initialRetryDelay: const Duration(seconds: 1),
        maxRemoteAttempts: 3,
      );

      policy.recordMeaningfulEdit(
        _work(
          onRemoteSave: () async {
            remoteCalls.add('old');
            throw const StoryEditorTransientAutosaveException('timeout');
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(policy.state.phase, StoryEditorAutosavePhase.retrying);
      expect(remoteCalls, ['old']);

      policy.recordMeaningfulEdit(
        _work(
          onLocalSnapshotSave: () => secondLocal.future,
          onRemoteSave: () async => remoteCalls.add('new'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(remoteCalls, ['old']);

      secondLocal.complete(true);
      await tester.pump();
      await tester.pump();
      expect(remoteCalls, ['old', 'new']);

      policy.dispose();
    });

    testWidgets(
      'serializes local snapshot writes so older completion cannot overwrite newer',
      (tester) async {
        final firstLocal = Completer<void>();
        final localEvents = <String>[];
        var secondLocalStarted = false;
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
        );

        policy.recordMeaningfulEdit(
          _work(
            storyId: null,
            onLocalSnapshotSave: () {
              localEvents.add('first-start');
              return firstLocal.future.then((_) {
                localEvents.add('first-end');
                return true;
              });
            },
            onRemoteSave: () async {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        policy.recordMeaningfulEdit(
          _work(
            storyId: null,
            onLocalSnapshotSave: () async {
              secondLocalStarted = true;
              localEvents.add('second');
              return true;
            },
            onRemoteSave: () async {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(secondLocalStarted, isFalse);
        expect(localEvents, ['first-start']);

        firstLocal.complete();
        await tester.pump();
        await tester.pump();

        expect(secondLocalStarted, isTrue);
        expect(localEvents, ['first-start', 'first-end', 'second']);
        expect(
          policy.state.phase,
          StoryEditorAutosavePhase.offlineSnapshotSaved,
        );

        policy.dispose();
      },
    );

    testWidgets(
      'remote story local snapshot false stops remote save and preserves error details',
      (tester) async {
        var remoteSaves = 0;
        final phases = <StoryEditorAutosaveState>[];
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
          onStateChanged: phases.add,
        );

        policy.recordMeaningfulEdit(
          _work(
            onLocalSnapshotSave: () async => false,
            onRemoteSave: () async => remoteSaves++,
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(remoteSaves, 0);
        expect(policy.state.phase, StoryEditorAutosavePhase.failed);
        expect(policy.state.error, isA<StoryEditorLocalSnapshotFailed>());
        expect(
          phases.map((state) => state.phase),
          isNot(contains(StoryEditorAutosavePhase.offlineSnapshotSaved)),
        );

        policy.dispose();
      },
    );

    testWidgets(
      'local draft snapshot false emits failed without offlineSnapshotSaved',
      (tester) async {
        final phases = <StoryEditorAutosaveState>[];
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
          onStateChanged: phases.add,
        );

        policy.recordMeaningfulEdit(
          _work(
            storyId: null,
            onLocalSnapshotSave: () async => false,
            onRemoteSave: () async {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(policy.state.phase, StoryEditorAutosavePhase.failed);
        expect(policy.state.error, isA<StoryEditorLocalSnapshotFailed>());
        expect(
          phases.map((state) => state.phase),
          isNot(contains(StoryEditorAutosavePhase.offlineSnapshotSaved)),
        );

        policy.dispose();
      },
    );

    testWidgets(
      'remote story local snapshot failure stops remote save and reports failed state',
      (tester) async {
        var remoteSaves = 0;
        final phases = <StoryEditorAutosavePhase>[];
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
          onStateChanged: (state) => phases.add(state.phase),
        );

        policy.recordMeaningfulEdit(
          _work(
            onLocalSnapshotSave: () async => throw StateError('disk full'),
            onRemoteSave: () async => remoteSaves++,
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(remoteSaves, 0);
        expect(policy.state.phase, StoryEditorAutosavePhase.failed);
        expect(
          phases,
          isNot(contains(StoryEditorAutosavePhase.offlineSnapshotSaved)),
        );

        policy.dispose();
      },
    );

    testWidgets(
      'stores an offline local snapshot after remote retries are exhausted',
      (tester) async {
        var attempts = 0;
        var localSnapshots = 0;
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
          initialRetryDelay: const Duration(seconds: 1),
          maxRemoteAttempts: 2,
        );

        policy.recordMeaningfulEdit(
          _work(
            onRemoteSave: () async {
              attempts++;
              throw const StoryEditorTransientAutosaveException('timeout');
            },
            onLocalSnapshotSave: () async {
              localSnapshots++;
              return true;
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(attempts, 2);
        expect(localSnapshots, 1);
        expect(
          policy.state.phase,
          StoryEditorAutosavePhase.offlineSnapshotSaved,
        );
        expect(policy.state.attempt, 2);

        policy.dispose();
      },
    );

    testWidgets(
      'new local drafts save a local snapshot without remote autosave',
      (tester) async {
        var remoteSaves = 0;
        var localSnapshots = 0;
        final policy = StoryEditorAutosavePolicy(
          debounceDuration: const Duration(milliseconds: 10),
        );

        policy.recordMeaningfulEdit(
          _work(
            storyId: null,
            onRemoteSave: () async => remoteSaves++,
            onLocalSnapshotSave: () async {
              localSnapshots++;
              return true;
            },
          ),
        );

        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();

        expect(remoteSaves, 0);
        expect(localSnapshots, 1);
        expect(
          policy.state.phase,
          StoryEditorAutosavePhase.offlineSnapshotSaved,
        );

        policy.dispose();
      },
    );
  });
}

StoryEditorAutosaveWork _work({
  String label = 'work',
  String? storyId = 'story-1',
  required Future<void> Function() onRemoteSave,
  Future<bool> Function()? onLocalSnapshotSave,
}) {
  return StoryEditorAutosaveWork(
    storyId: storyId,
    saveRemote: onRemoteSave,
    saveLocalSnapshot: onLocalSnapshotSave ?? () async => true,
  );
}
