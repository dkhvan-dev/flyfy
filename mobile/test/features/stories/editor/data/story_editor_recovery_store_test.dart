import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/data/story_editor_recovery_store.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StoryEditorRecoveryStore', () {
    test('saves and loads a complete remote story snapshot', () async {
      final store = StoryEditorRecoveryStore();
      final snapshot = _snapshot(
        userId: ' user-1 ',
        storyId: ' story-1 ',
        lastRemoteRevision: 42,
      );

      await store.save(snapshot);

      final loaded = await store.load(userId: 'user-1', storyId: 'story-1');

      expect(loaded, isNotNull);
      expect(loaded!.userId, 'user-1');
      expect(loaded.storyId, 'story-1');
      expect(loaded.localDraftId, isNull);
      expect(loaded.metadata.title, 'Morning in Almaty');
      expect(loaded.metadata.tags, ['mountains', 'food']);
      expect(loaded.document.blocks, hasLength(3));
      expect(loaded.document.blocks[0].type, StoryBlockType.heading);
      expect(
        loaded.document.blocks[0].marks.single.type,
        StoryInlineMarkType.bold,
      );
      expect(loaded.document.blocks[1].image?.fileId, 'file-1');
      expect(loaded.document.blocks[2].gallery?.images.single.fileId, 'file-2');
      expect(
        loaded.pendingMediaReferences.single.localMediaId,
        'local-media-1',
      );
      expect(loaded.pendingMediaReferences.single.galleryImageIndex, 1);
      expect(loaded.lastRemoteRevision, 42);
      expect(loaded.lastLocalEditAt, DateTime.utc(2026, 6, 8, 6, 30));
    });

    test('keys unsynced drafts by temporary local id', () async {
      final store = StoryEditorRecoveryStore();
      final snapshot = _snapshot(
        userId: 'user-1',
        localDraftId: 'draft-device-1',
        storyId: null,
      );

      await store.save(snapshot);

      expect(
        await store.load(userId: 'user-1', localDraftId: 'draft-device-1'),
        isNotNull,
      );
      expect(await store.load(userId: 'user-1', storyId: 'story-1'), isNull);
    });

    test('clear removes only the selected snapshot', () async {
      final store = StoryEditorRecoveryStore();
      await store.save(_snapshot(userId: 'user-1', storyId: 'story-1'));
      await store.save(_snapshot(userId: 'user-1', storyId: 'story-2'));

      await store.clear(userId: 'user-1', storyId: 'story-1');

      expect(await store.load(userId: 'user-1', storyId: 'story-1'), isNull);
      expect(await store.load(userId: 'user-1', storyId: 'story-2'), isNotNull);
    });

    test('corrupt snapshot returns null and removes the bad value', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StoryEditorRecoveryStore.storageKey(
          userId: 'user-1',
          storyId: 'story-1',
        ),
        '{not-json',
      );
      final store = StoryEditorRecoveryStore();

      final loaded = await store.load(userId: 'user-1', storyId: 'story-1');

      expect(loaded, isNull);
      expect(
        prefs.getString(
          StoryEditorRecoveryStore.storageKey(
            userId: 'user-1',
            storyId: 'story-1',
          ),
        ),
        isNull,
      );
    });

    test('isolates snapshots by user id', () async {
      final store = StoryEditorRecoveryStore();
      await store.save(_snapshot(userId: 'user-1', storyId: 'story-1'));
      await store.save(
        _snapshot(
          userId: 'user-2',
          storyId: 'story-1',
          title: 'Different traveler',
        ),
      );

      final first = await store.load(userId: 'user-1', storyId: 'story-1');
      final second = await store.load(userId: 'user-2', storyId: 'story-1');

      expect(first?.metadata.title, 'Morning in Almaty');
      expect(second?.metadata.title, 'Different traveler');
    });

    test('does not persist secret-like metadata keys', () async {
      final store = StoryEditorRecoveryStore();
      await store.save(
        _snapshot(
          userId: 'user-1',
          storyId: 'story-1',
          metadata: const {
            'clientTraceId': 'trace-1',
            'accessToken': 'secret-token',
            'refresh_token': 'refresh-token',
            'password': 'nope',
          },
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(
        StoryEditorRecoveryStore.storageKey(
          userId: 'user-1',
          storyId: 'story-1',
        ),
      );

      expect(raw, contains('clientTraceId'));
      expect(raw, isNot(contains('secret-token')));
      expect(raw, isNot(contains('refresh-token')));
      expect(raw, isNot(contains('nope')));
    });

    test(
      'allowlists recoverable metadata and drops sensitive variants',
      () async {
        final store = StoryEditorRecoveryStore();
        await store.save(
          _snapshot(
            userId: 'user-1',
            storyId: 'story-1',
            metadata: const {
              'clientTraceId': 'trace-1',
              'editorSessionId': 'session-safe-id',
              'draftSource': 'editor',
              'authorization': 'Bearer secret',
              'cookie': 'session=secret',
              'apiKey': 'api-key-secret',
              'privateKey': 'private-key-secret',
              'jwt': 'jwt-secret',
              'otp': '123456',
              'pin': '1111',
              'idToken': 'id-token-secret',
              'unexpectedSafeLookingKey': 'must-not-persist',
            },
          ),
        );

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(
          StoryEditorRecoveryStore.storageKey(
            userId: 'user-1',
            storyId: 'story-1',
          ),
        );

        expect(raw, contains('trace-1'));
        expect(raw, contains('session-safe-id'));
        expect(raw, contains('editor'));
        for (final secret in const [
          'Bearer secret',
          'session=secret',
          'api-key-secret',
          'private-key-secret',
          'jwt-secret',
          '123456',
          '1111',
          'id-token-secret',
          'must-not-persist',
        ]) {
          expect(raw, isNot(contains(secret)));
        }
      },
    );

    test(
      'rejects oversized snapshots and preserves previous valid value',
      () async {
        final store = StoryEditorRecoveryStore(maxSnapshotBytes: 4096);
        await store.save(_snapshot(userId: 'user-1', storyId: 'story-1'));

        final saved = await store.save(
          _snapshot(userId: 'user-1', storyId: 'story-1', title: 'A' * 10000),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(saved, isFalse);
        final loaded = await store.load(userId: 'user-1', storyId: 'story-1');
        expect(prefs.getString(loaded!.storageKey), isNotNull);
        expect(loaded.metadata.title, 'Morning in Almaty');
      },
    );

    test('rejects stale snapshot writes by local edit timestamp', () async {
      final store = StoryEditorRecoveryStore();
      await store.save(
        _snapshot(
          userId: 'user-1',
          storyId: 'story-1',
          title: 'Newer',
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 10),
        ),
      );

      final saved = await store.save(
        _snapshot(
          userId: 'user-1',
          storyId: 'story-1',
          title: 'Older',
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 9),
        ),
      );

      final loaded = await store.load(userId: 'user-1', storyId: 'story-1');
      expect(saved, isFalse);
      expect(loaded?.metadata.title, 'Newer');
    });

    test('reports failed SharedPreferences setString results', () async {
      final storage = _MemoryRecoveryStorage(failSetString: true);
      final store = StoryEditorRecoveryStore(storage: storage);

      final saved = await store.save(_snapshot(userId: 'user-1'));

      expect(saved, isFalse);
      expect(storage.values, isEmpty);
    });

    test('reports failed clear remove results', () async {
      final key = StoryEditorRecoveryStore.storageKey(
        userId: 'user-1',
        storyId: 'story-1',
      );
      final storage = _MemoryRecoveryStorage(
        initialValues: {key: jsonEncode(_snapshot(userId: 'user-1').toJson())},
        failRemoveKeys: {key},
      );
      final store = StoryEditorRecoveryStore(storage: storage);

      final cleared = await store.clear(userId: 'user-1', storyId: 'story-1');

      expect(cleared, isFalse);
      expect(storage.values, contains(key));
    });

    test(
      'cleans up oldest user snapshots when the user limit is exceeded',
      () async {
        final store = StoryEditorRecoveryStore(maxSnapshotsPerUser: 2);
        await store.save(
          _snapshot(
            userId: 'user-1',
            storyId: 'story-old',
            lastLocalEditAt: DateTime.utc(2026, 6, 8, 1),
          ),
        );
        await store.save(
          _snapshot(
            userId: 'user-1',
            storyId: 'story-middle',
            lastLocalEditAt: DateTime.utc(2026, 6, 8, 2),
          ),
        );
        await store.save(
          _snapshot(
            userId: 'user-1',
            storyId: 'story-new',
            lastLocalEditAt: DateTime.utc(2026, 6, 8, 3),
          ),
        );

        expect(
          await store.load(userId: 'user-1', storyId: 'story-old'),
          isNull,
        );
        expect(
          await store.load(userId: 'user-1', storyId: 'story-middle'),
          isNotNull,
        );
        expect(
          await store.load(userId: 'user-1', storyId: 'story-new'),
          isNotNull,
        );
      },
    );

    test(
      'unsupported future schema is ignored without deleting the value',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final key = StoryEditorRecoveryStore.storageKey(
          userId: 'user-1',
          storyId: 'story-1',
        );
        await prefs.setString(
          key,
          jsonEncode(
            _snapshot(userId: 'user-1', storyId: 'story-1').toJson()
              ..['schemaVersion'] = 99,
          ),
        );
        final store = StoryEditorRecoveryStore();

        final loaded = await store.load(userId: 'user-1', storyId: 'story-1');

        expect(loaded, isNull);
        expect(prefs.getString(key), isNotNull);
      },
    );

    test(
      'storage-key mismatch returns null and removes the bad value',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final key = StoryEditorRecoveryStore.storageKey(
          userId: 'user-1',
          storyId: 'story-1',
        );
        await prefs.setString(
          key,
          jsonEncode(_snapshot(userId: 'user-2', storyId: 'story-1').toJson()),
        );
        final store = StoryEditorRecoveryStore();

        final loaded = await store.load(userId: 'user-1', storyId: 'story-1');

        expect(loaded, isNull);
        expect(prefs.getString(key), isNull);
      },
    );

    test('invalid non-string required fields are rejected safely', () async {
      final prefs = await SharedPreferences.getInstance();
      final key = StoryEditorRecoveryStore.storageKey(
        userId: '123',
        storyId: 'story-1',
      );
      await prefs.setString(
        key,
        jsonEncode(
          _snapshot(userId: '123', storyId: 'story-1').toJson()
            ..['userId'] = 123,
        ),
      );
      final store = StoryEditorRecoveryStore();

      final loaded = await store.load(userId: '123', storyId: 'story-1');

      expect(loaded, isNull);
      expect(prefs.getString(key), isNull);
    });
  });
}

class _MemoryRecoveryStorage implements StoryEditorRecoveryStorage {
  _MemoryRecoveryStorage({
    Map<String, String> initialValues = const {},
    this.failSetString = false,
    Set<String> failRemoveKeys = const {},
  }) : values = Map<String, String>.from(initialValues),
       _failRemoveKeys = Set<String>.from(failRemoveKeys);

  final Map<String, String> values;
  final bool failSetString;
  final Set<String> _failRemoveKeys;

  @override
  Future<Set<String>> getKeys() async => values.keys.toSet();

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<bool> remove(String key) async {
    if (_failRemoveKeys.contains(key)) {
      return false;
    }
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (failSetString) {
      return false;
    }
    values[key] = value;
    return true;
  }
}

StoryEditorRecoverySnapshot _snapshot({
  required String userId,
  String? storyId = 'story-1',
  String? localDraftId,
  String title = 'Morning in Almaty',
  int? lastRemoteRevision = 7,
  Map<String, Object?> metadata = const {'clientTraceId': 'trace-1'},
  DateTime? lastLocalEditAt,
}) {
  return StoryEditorRecoverySnapshot(
    userId: userId,
    storyId: storyId,
    localDraftId: localDraftId,
    metadata: StoryEditorMetadataDraft(
      title: title,
      format: 'guide',
      category: 'journal',
      status: 'draft',
      coverFileId: 'cover-1',
      placeName: 'Almaty',
      placeCountryCode: 'kz',
      placeCityId: 'almaty',
      tags: const [' mountains ', '', 'food'],
      metadata: metadata,
    ),
    document: StoryDocument(
      blocks: [
        StoryBlock.heading(
          id: 'heading-1',
          text: 'Arrival',
          level: 2,
          marks: const [StoryInlineMark.bold(start: 0, end: 7)],
        ),
        StoryBlock.image(
          id: 'image-1',
          image: const StoryImagePayload(fileId: 'file-1'),
        ),
        StoryBlock.gallery(
          id: 'gallery-1',
          gallery: StoryGalleryPayload(
            images: const [StoryImagePayload(fileId: 'file-2')],
          ),
        ),
      ],
    ),
    pendingMediaReferences: const [
      StoryEditorPendingMediaReference(
        localMediaId: 'local-media-1',
        blockId: 'image-2',
        galleryImageIndex: 1,
        fileName: 'draft.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1200,
      ),
    ],
    lastRemoteRevision: lastRemoteRevision,
    lastLocalEditAt: lastLocalEditAt ?? DateTime.utc(2026, 6, 8, 6, 30),
  );
}
