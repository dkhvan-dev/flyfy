import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone login action exposes a semantic button target', () async {
    final source = await File(
      'lib/screens/auth/login_screen.dart',
    ).readAsString();
    final buttonStart = source.indexOf('Consumer<AuthProvider>(');
    final buttonEnd = source.indexOf('const SizedBox(height: 12)', buttonStart);

    expect(buttonStart, isNonNegative);
    expect(buttonEnd, greaterThan(buttonStart));

    final buttonSource = source.substring(buttonStart, buttonEnd);

    expect(buttonSource, contains('Semantics('));
    expect(buttonSource, contains('container: true'));
    expect(buttonSource, contains('button: true'));
    expect(buttonSource, contains('enabled: canSubmitPhone'));
    expect(buttonSource, contains('label: l10n.authByPhone'));
    expect(buttonSource, contains('onTap: canSubmitPhone'));
    expect(buttonSource, contains('? _submit'));
    expect(buttonSource, contains(': null'));
    expect(buttonSource, contains('ExcludeSemantics('));
  });
}
