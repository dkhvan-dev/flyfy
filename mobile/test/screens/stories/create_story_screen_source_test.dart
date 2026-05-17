import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'create story clears keyboard focus when switching form steps',
    () async {
      final source = await File(
        'lib/screens/stories/create_story_screen.dart',
      ).readAsString();

      expect(source, contains('void _goToStep(int step)'));
      expect(source, contains('FocusScope.of(context).unfocus();'));
      expect(source, contains('_goToStep(0);'));
      expect(source, contains('_goToStep(1);'));
    },
  );
}
