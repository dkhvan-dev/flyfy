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

  test(
    'create activity publish action relies on backend auto-publication',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      final submitAndPublishStart = source.indexOf(
        'Future<void> _submitAndPublish() async',
      );
      final sharedHelpersStart = source.indexOf(
        '// ── Shared field extraction helpers',
      );
      expect(submitAndPublishStart, isNonNegative);
      expect(sharedHelpersStart, greaterThan(submitAndPublishStart));

      final submitAndPublishSource = source.substring(
        submitAndPublishStart,
        sharedHelpersStart,
      );

      expect(submitAndPublishSource, contains('provider.createActivity('));
      expect(
        submitAndPublishSource,
        isNot(contains('provider.publishActivity(')),
      );
    },
  );

  test(
    'created activity is passed to details screen to avoid not found flash',
    () async {
      final source = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(
        source,
        contains(
          "context.pushReplacement('/activities/\${created.id}', extra: created)",
        ),
      );
    },
  );
}
