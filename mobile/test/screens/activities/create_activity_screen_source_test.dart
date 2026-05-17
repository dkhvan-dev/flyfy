import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create activity clears keyboard focus before switching steps',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(
        source,
        contains('void _goToStep(int step, {bool animate = true})'),
      );
      expect(
        source,
        contains('FocusManager.instance.primaryFocus?.unfocus();'),
      );
      expect(source, contains('_pageController.animateToPage('));
    },
  );
}
