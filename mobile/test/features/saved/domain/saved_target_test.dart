import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';

void main() {
  test('SavedTarget strictly maps every supported entity type', () {
    for (final entityType in SavedEntityType.values) {
      final target = SavedTarget(
        entityType: entityType,
        entityId: 'opaque / key-${entityType.index}',
      );

      final decoded = SavedTarget.fromJson(target.toJson());

      expect(decoded, target);
      expect(decoded.entityId, 'opaque / key-${entityType.index}');
      expect(decoded.toJson()['entity_type'], entityType.wireValue);
    }
  });

  test('entity IDs enforce UTF-8 bytes without normalizing opaque values', () {
    final ascii512 = List<String>.filled(512, 'a').join();
    final twoByteCharacter = String.fromCharCode(0x00e9);
    final utf8Bytes512 = List<String>.filled(256, twoByteCharacter).join();
    final utf8Bytes514 = List<String>.filled(257, twoByteCharacter).join();

    expect(
      SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: ascii512,
      ).entityId,
      ascii512,
    );
    expect(
      SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: utf8Bytes512,
      ).entityId,
      utf8Bytes512,
    );
    expect(
      () => SavedTarget(
        entityType: SavedEntityType.activity,
        entityId: utf8Bytes514,
      ),
      throwsArgumentError,
    );
  });

  test('entity IDs reject empty, surrounding whitespace, and controls', () {
    for (final invalid in <String>[
      '',
      ' leading',
      'trailing ',
      '\tleading-tab',
      'line\nbreak',
      'nul\u0000byte',
      'delete\u007fcontrol',
    ]) {
      expect(
        () => SavedTarget(entityType: SavedEntityType.guide, entityId: invalid),
        throwsArgumentError,
        reason: 'Expected ${invalid.codeUnits} to be rejected.',
      );
    }
  });

  test(
    'tryCreate omits malformed source IDs without throwing from UI build',
    () {
      expect(
        SavedTarget.tryCreate(
          entityType: SavedEntityType.attraction,
          entityId: 'place-1',
        ),
        SavedTarget(
          entityType: SavedEntityType.attraction,
          entityId: 'place-1',
        ),
      );
      for (final invalid in <String?>[null, '', ' activity-1', 'guide-1\n']) {
        expect(
          SavedTarget.tryCreate(
            entityType: SavedEntityType.activity,
            entityId: invalid,
          ),
          isNull,
        );
      }
    },
  );

  test(
    'SavedTarget rejects unknown, retired, malformed, and extended JSON',
    () {
      for (final entityType in <String>['CHECKLIST', 'EXCURSION']) {
        expect(
          () => SavedTarget.fromJson(<String, dynamic>{
            'entity_type': entityType,
            'entity_id': 'unsupported-1',
          }),
          throwsFormatException,
        );
      }
      expect(
        () => SavedTarget.fromJson(const <String, dynamic>{
          'entity_type': 'ACTIVITY',
          'entity_id': 42,
        }),
        throwsFormatException,
      );
      expect(
        () => SavedTarget.fromJson(const <String, dynamic>{
          'entity_type': 'GUIDE',
          'entity_id': 'guide-1',
          'unexpected': true,
        }),
        throwsFormatException,
      );
    },
  );
}
