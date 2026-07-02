import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile post cards expose a semantic button target', () {
    final source = File(
      'lib/screens/profile/widgets/profile_post_card.dart',
    ).readAsStringSync();

    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('label: post.title'));
    expect(source, contains('onTap: onTap'));
    expect(
      source,
      contains("import 'package:inflap/core/ui/app_design_system.dart';"),
    );
    expect(
      source,
      contains('final colors = AppDesignSystem.colorsFor(context)'),
    );
    expect(source, isNot(contains('AppPalette.')));
  });
}
