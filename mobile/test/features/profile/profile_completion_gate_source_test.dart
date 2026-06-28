import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile completion gate uses app modal template', () {
    final gateSource = File(
      'lib/features/profile/profile_completion_gate.dart',
    ).readAsStringSync();
    final modalSource = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();

    expect(
      gateSource,
      contains("import 'package:inflap/core/ui/app_modal_templates.dart';"),
    );
    expect(gateSource, contains('showAppModalDialog<bool>('));
    expect(gateSource, contains('AppModalAction<bool>('));
    expect(gateSource, contains('Icons.manage_accounts_rounded'));
    expect(gateSource, isNot(contains('AlertDialog(')));
    expect(gateSource, isNot(contains('AppFilterPaletteDialog(')));

    expect(modalSource, contains('class AppModalScaffold'));
    expect(modalSource, contains('class AppModalAction'));
  });
}
