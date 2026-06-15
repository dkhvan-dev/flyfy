import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client exposes nickname availability endpoint', () async {
    final source = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();
    final profileApi = await File(
      'lib/features/profile/data/profile_api.dart',
    ).readAsString();

    expect(
      source,
      contains('Future<Map<String, dynamic>> nicknameAvailability('),
    );
    expect(source, contains("'/users/nickname-availability'"));
    expect(source, contains("'nickname': nickname"));
    expect(profileApi, contains('Future<bool> isNicknameAvailable('));
    expect(profileApi, contains('nicknameAvailability(nickname)'));
  });
}
