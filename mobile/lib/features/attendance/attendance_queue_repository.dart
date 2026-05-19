import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../core/storage/secure_storage.dart';
import 'models/attendance_queue_item.dart';

class AttendanceQueueRepository {
  AttendanceQueueRepository({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  static const _queueKey = 'attendance_pending_queue_v1';
  static const _installationKey = 'attendance_installation_id_v1';

  final SecureStorage _secureStorage;
  final Random _random = Random.secure();

  Future<String> getOrCreateInstallationId() async {
    final existing = await _secureStorage.readString(_installationKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final value = _generateUuidV4();
    await _secureStorage.writeString(key: _installationKey, value: value);
    return value;
  }

  Future<List<AttendanceQueueItem>> readAll() async {
    final raw = await _secureStorage.readString(_queueKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AttendanceQueueItem.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<AttendanceQueueItem> items) async {
    await _secureStorage.writeString(
      key: _queueKey,
      value: jsonEncode(
          items.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  Future<AttendanceQueueItem?> findPendingForActivity({
    required String participantUserId,
    required String activityId,
  }) async {
    return findPending(
      participantUserId: participantUserId,
      type: AttendanceQueueItem.typeActivity,
      subjectId: activityId,
    );
  }

  Future<AttendanceQueueItem?> findPending({
    required String participantUserId,
    required String type,
    required String subjectId,
  }) async {
    final items = await readAll();
    for (final item in items) {
      if (item.participantUserId == participantUserId &&
          item.type == type &&
          item.activityId == subjectId) {
        return item;
      }
    }
    return null;
  }

  Future<void> enqueue(AttendanceQueueItem item) async {
    final items = await readAll();
    final updated = <AttendanceQueueItem>[
      for (final existing in items)
        if (!(existing.participantUserId == item.participantUserId &&
            existing.type == item.type &&
            existing.activityId == item.activityId))
          existing,
      item,
    ];
    await writeAll(updated);
  }

  String generateScanId() => _generateUuidV4();

  String _generateUuidV4() {
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
