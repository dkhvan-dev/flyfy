import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client exposes authenticated password change endpoints', () async {
    final source = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();

    expect(source, contains('Future<void> startPasswordChange('));
    expect(source, contains("'/auth/password/change/start'"));
    expect(source, contains("'current_password': currentPassword"));

    expect(source, contains('Future<void> verifyPasswordChange('));
    expect(source, contains("'/auth/password/change/verify'"));
    expect(source, contains("'code': code"));
    expect(source, contains("'new_password': newPassword"));
    expect(source, contains("Options(extra: {'requiresAuth': true})"));
    expect(source, contains('if (requiresAuthFromExtra == true)'));
  });
}
