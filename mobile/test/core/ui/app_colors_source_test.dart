import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses semantic destructive color token in hex notation', () {
    final source = File('lib/core/ui/app_colors.dart').readAsStringSync();

    expect(source, contains('static const destructive = Color(0xFFFF0000);'));
    expect(source, isNot(contains('static const red')));
    expect(source, isNot(contains('Color.fromARGB(255, 255, 0, 0)')));
  });
}
