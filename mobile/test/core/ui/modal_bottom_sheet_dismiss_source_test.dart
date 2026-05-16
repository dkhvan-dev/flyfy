import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom sheets explicitly allow outside-tap dismissal', () {
    final lib = Directory('lib');
    final offenders = <String>[];

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      var searchStart = 0;

      while (true) {
        final callStart = source.indexOf('showModalBottomSheet<', searchStart);
        if (callStart == -1) break;
        final builderStart = source.indexOf('builder:', callStart);
        final callHeader = source.substring(
          callStart,
          builderStart == -1 ? source.length : builderStart,
        );
        if (!callHeader.contains('isDismissible: true')) {
          offenders.add(entity.path);
          break;
        }
        searchStart = callStart + 'showModalBottomSheet<'.length;
      }
    }

    expect(offenders, isEmpty);
  });

  test('full-screen transparent sheet frames dismiss outside taps', () {
    final chrome =
        File('lib/core/ui/filter_sheet_chrome.dart').readAsStringSync();
    expect(chrome, contains('class AppDismissibleModalSheet'));
    expect(chrome, contains('Navigator.maybePop(context)'));

    for (final path in [
      'lib/screens/guides/guides_screen.dart',
      'lib/screens/excursions/excursions_screen.dart',
      'lib/screens/attractions/attractions_filter_sheet.dart',
    ]) {
      expect(
          File(path).readAsStringSync(), contains('AppDismissibleModalSheet'));
    }
  });
}
