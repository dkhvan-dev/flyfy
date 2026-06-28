import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom sheets use app modal helper dismissal default', () {
    final modalSource = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();
    final lib = Directory('lib');
    final offenders = <String>[];

    expect(modalSource, contains('bool isDismissible = true'));

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == 'lib/core/ui/app_modal_templates.dart') continue;
      final source = entity.readAsStringSync();
      if (source.contains('showModalBottomSheet')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('app modal template owns sheet framing and dismissal defaults', () {
    final modalSource = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();
    expect(modalSource, contains('class AppModalSheetFrame'));
    expect(modalSource, contains('bool isDismissible = true'));

    for (final path in [
      'lib/screens/guides/guides_screen.dart',
      'lib/screens/excursions/excursions_screen.dart',
      'lib/screens/places/places_filter_sheet.dart',
    ]) {
      expect(File(path).readAsStringSync(), contains('AppModalSheetFrame'));
    }
  });
}
