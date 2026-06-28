import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app modal templates expose unified dialog and bottom sheet APIs', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();

    expect(source, contains('class AppModalScaffold'));
    expect(source, contains('class AppModalDialogCard'));
    expect(source, contains('class AppModalSheetFrame'));
    expect(source, contains('class AppModalDraggableSheet'));
    expect(source, contains('class AppModalAction'));
    expect(source, contains('class AppActionSheetItem'));
    expect(source, contains('Future<T?> showAppModalDialog<T>'));
    expect(source, contains('Future<T?> showAppModalBottomSheet<T>'));
    expect(source, contains('Future<T?> showAppActionSheet<T>'));
    expect(source, contains('DraggableScrollableSheet('));
    expect(source, contains('SafeArea('));
    expect(source, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(source, contains('bool isScrollControlled = true'));
    expect(source, contains('bool isDismissible = true'));
    expect(source, contains('AppPalette.'));
    expect(source, isNot(contains('AlertDialog(')));
    expect(source, isNot(contains('AppColor(')));
    expect(source, isNot(contains('AppColors.')));
  });

  test(
    'mobile UI uses app modal templates instead of raw modal primitives',
    () {
      final libDir = Directory('lib');
      final violations = <String>[];
      final bannedPatterns = <String, RegExp>{
        'showDialog': RegExp(r'\bshowDialog\s*(?:<|\()'),
        'showGeneralDialog': RegExp(r'\bshowGeneralDialog\s*(?:<|\()'),
        'showModalBottomSheet': RegExp(r'\bshowModalBottomSheet\s*(?:<|\()'),
        'AlertDialog': RegExp(r'\bAlertDialog\s*\('),
        'SimpleDialog': RegExp(r'\bSimpleDialog\s*\('),
        'DraggableScrollableSheet': RegExp(r'\bDraggableScrollableSheet\s*\('),
        'AppDismissibleModalSheet': RegExp(r'\bAppDismissibleModalSheet\b'),
        'AppFilterPaletteDialog': RegExp(r'\bAppFilterPaletteDialog\b'),
      };

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path == 'lib/core/ui/app_modal_templates.dart') continue;
        if (entity.path.startsWith('lib/l10n/generated/')) continue;

        final source = entity.readAsStringSync();
        for (final entry in bannedPatterns.entries) {
          if (entry.value.hasMatch(source)) {
            violations.add('${entity.path} uses ${entry.key}');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}
