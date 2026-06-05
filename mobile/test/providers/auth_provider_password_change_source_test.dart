import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth provider exposes password change state and actions', () async {
    final source = await File(
      'lib/providers/auth_provider.dart',
    ).readAsString();

    expect(source, contains('bool _isPasswordChangeLoading = false;'));
    expect(source, contains('bool get isPasswordChangeLoading'));
    expect(source, contains('Future<bool> startPasswordChange('));
    expect(
      source,
      contains('await _apiClient.startPasswordChange(currentPassword);'),
    );
    expect(source, contains('Future<bool> verifyPasswordChange('));
    expect(
      source,
      contains(
        'await _apiClient.verifyPasswordChange(currentPassword, code, newPassword);',
      ),
    );
  });
}
