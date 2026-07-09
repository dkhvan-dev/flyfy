import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat image viewer uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/screens/chat/chat_image_viewer_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.backgroundDeep'));
    expect(source, contains('colors.scrim'));
    expect(source, contains('colors.white'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('chat image viewer can be dismissed by swiping down', () async {
    final source = await File(
      'lib/screens/chat/chat_image_viewer_screen.dart',
    ).readAsString();

    expect(source, contains('StatefulWidget'));
    expect(source, contains('TransformationController'));
    expect(source, contains('_dismissBySwipeDown'));
    expect(source, contains('onVerticalDragUpdate'));
    expect(source, contains('onVerticalDragEnd'));
    expect(source, contains('primaryVelocity'));
    expect(source, contains('Navigator.of(context).pop'));

    final dismissStart = source.indexOf('void _dismissBySwipeDown');
    final resetStart = source.indexOf('void _resetDragOffset');
    expect(dismissStart, isNonNegative);
    expect(resetStart, greaterThan(dismissStart));

    final dismissSource = source.substring(dismissStart, resetStart);
    expect(dismissSource, contains('_currentScale > 1.05'));
  });
}
