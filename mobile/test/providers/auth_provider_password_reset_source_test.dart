import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth provider exposes password reset state and actions', () async {
    final source = await File(
      'lib/providers/auth_provider.dart',
    ).readAsString();

    expect(source, contains('bool _isPasswordResetLoading = false;'));
    expect(source, contains('bool get isPasswordResetLoading'));
    expect(source, contains('Future<bool> startPasswordReset('));
    expect(
      source,
      contains('await _apiClient.startPasswordReset(identifier);'),
    );
    expect(source, contains('Future<bool> verifyPasswordReset('));
    expect(
      source,
      contains(
        'await _apiClient.verifyPasswordReset(identifier, code, password);',
      ),
    );
  });
}
