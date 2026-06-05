import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router exposes public password reset route', () async {
    final source = await File('lib/core/router/app_router.dart').readAsString();

    expect(
      source,
      contains("import '../../screens/auth/password_reset_screen.dart';"),
    );
    expect(source, contains("path: '/password-reset'"));
    expect(source, contains('PasswordResetScreen'));
    expect(source, contains("location == '/password-reset'"));
  });
}
