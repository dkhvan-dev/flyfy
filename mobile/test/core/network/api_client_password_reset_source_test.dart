import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api client exposes password reset endpoints', () async {
    final source = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();

    expect(source, contains('Future<void> startPasswordReset('));
    expect(source, contains("'/auth/password/reset/start'"));
    expect(source, contains("'identifier': identifier"));

    expect(source, contains('Future<void> verifyPasswordReset('));
    expect(source, contains("'/auth/password/reset/verify'"));
    expect(source, contains("'code': code"));
    expect(source, contains("'password': password"));
  });
}
