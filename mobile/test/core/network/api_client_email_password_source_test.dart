import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client exposes email password auth endpoints', () async {
    final source = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();

    expect(source, contains('Future<AuthResult> loginWithPassword('));
    expect(source, contains("'/auth/login/password'"));
    expect(source, contains("'identifier': identifier"));
    expect(source, contains("'password': password"));

    expect(source, contains('Future<void> startEmailRegistration('));
    expect(source, contains("'/auth/register/email/start'"));
    expect(source, contains("'email': email"));

    expect(source, contains('Future<AuthResult> verifyEmailRegistration('));
    expect(source, contains("'/auth/register/email/verify'"));
    expect(source, contains("'code': code"));
  });
}
