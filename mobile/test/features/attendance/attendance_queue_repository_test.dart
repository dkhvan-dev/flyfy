import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/attendance/attendance_queue_repository.dart';
import 'package:inflap/features/attendance/models/attendance_queue_item.dart';

void main() {
  group('AttendanceQueueRepository.scanIdForProof', () {
    late AttendanceQueueRepository repository;

    setUp(() {
      repository = AttendanceQueueRepository();
    });

    test('returns the same scan id for the same QR proof', () {
      final first = repository.scanIdForProof(
        participantUserId: 'A64E2E6B-5F0A-4F36-B6F2-8A099C1D4191',
        type: AttendanceQueueItem.typeActivity,
        subjectId: '2C3D191C-BE8C-46E6-BBD8-65A4D6D8481E',
        qrJti: 'QR-JTI-001',
      );
      final second = repository.scanIdForProof(
        participantUserId: ' a64e2e6b-5f0a-4f36-b6f2-8a099c1d4191 ',
        type: ' ${AttendanceQueueItem.typeActivity.toUpperCase()} ',
        subjectId: ' 2c3d191c-be8c-46e6-bbd8-65a4d6d8481e ',
        qrJti: ' qr-jti-001 ',
      );

      expect(second, first);
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('returns different scan ids for different QR proofs', () {
      final first = repository.scanIdForProof(
        participantUserId: 'a64e2e6b-5f0a-4f36-b6f2-8a099c1d4191',
        type: AttendanceQueueItem.typeActivity,
        subjectId: '2c3d191c-be8c-46e6-bbd8-65a4d6d8481e',
        qrJti: 'qr-jti-001',
      );
      final second = repository.scanIdForProof(
        participantUserId: 'a64e2e6b-5f0a-4f36-b6f2-8a099c1d4191',
        type: AttendanceQueueItem.typeActivity,
        subjectId: '2c3d191c-be8c-46e6-bbd8-65a4d6d8481e',
        qrJti: 'qr-jti-002',
      );

      expect(second, isNot(first));
    });
  });
}
