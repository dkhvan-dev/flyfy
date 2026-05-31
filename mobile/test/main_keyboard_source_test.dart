import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app wraps routed content with keyboard dismiss on scroll', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source,
      contains("import 'core/ui/keyboard_dismiss_on_scroll.dart';"),
    );
    expect(source, contains('AppKeyboardDismissOnScroll('));
    expect(
      source.indexOf('_DismissKeyboardOnTap('),
      lessThan(source.indexOf('AppKeyboardDismissOnScroll(')),
    );
  });
}
