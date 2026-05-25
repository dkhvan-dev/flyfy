import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen wires pull-to-refresh to a profile reload', () async {
    final source = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();

    expect(source, contains('Future<void> _refreshProfile() async'));
    expect(source, contains('RefreshIndicator('));
    expect(source, contains('onRefresh: _refreshProfile'));
    expect(source, contains('reloadProfile()'));
  });

  test('profile settings screen wires pull-to-refresh to a profile reload',
      () async {
    final source = await File(
      'lib/screens/profile/profile_settings_screen.dart',
    ).readAsString();

    expect(source, contains('Future<void> _refreshProfileSettings() async'));
    expect(source, contains('RefreshIndicator('));
    expect(source, contains('onRefresh: _refreshProfileSettings'));
    expect(source, contains('reloadProfile()'));
  });
}
