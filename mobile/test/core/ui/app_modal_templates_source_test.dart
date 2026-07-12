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
    expect(source, contains('final mediaQuery = MediaQuery.of(routeContext)'));
    expect(
      source,
      contains('final keyboardInset = mediaQuery.viewInsets.bottom'),
    );
    expect(source, contains('bool isScrollControlled = true'));
    expect(source, contains('bool isDismissible = true'));
    expect(source, contains('bool contentHandlesBottomSafeArea = false'));
    expect(source, contains('const _maxModalHeightRatio = 0.92'));
    expect(source, contains('.clamp(0.1, _maxModalHeightRatio)'));
    expect(source, contains('BoxConstraints(maxHeight: customSheetMaxHeight)'));
    expect(source, isNot(contains('extendToBottom')));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('AppButtonStyles.primary(colors)'));
    expect(source, isNot(contains('AppPalette.')));
    expect(source, isNot(contains('AlertDialog(')));
    expect(source, isNot(contains('AppColor(')));
    expect(source, isNot(contains('AppColors.')));
  });

  test('all custom app modal sheets use physical-bottom surfaces', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();
    final sheetStart = source.indexOf('Future<T?> showAppModalBottomSheet<T>');
    final actionSheetStart = source.indexOf('Future<T?> showAppActionSheet<T>');
    final sheetSource = source.substring(sheetStart, actionSheetStart);

    expect(sheetSource, contains("ValueKey('app-modal-custom-sheet-surface')"));
    expect(sheetSource, contains('final navigationSafeInset ='));
    expect(sheetSource, contains('final customContentBottomPadding ='));
    expect(
      sheetSource,
      contains('AppEdgeInsets.only(bottom: customContentBottomPadding)'),
    );
    expect(sheetSource, contains('backgroundColor: colors.transparent'));
    expect(sheetSource, contains('useSafeArea: false'));
    expect(sheetSource, isNot(contains('extendToBottom')));
  });

  test('app modal bottom sheets use full viewport width by default', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();

    expect(source, contains('BoxConstraints _fullWidthBottomSheetConstraints'));
    expect(
      source,
      contains('final viewportWidth = MediaQuery.sizeOf(context).width'),
    );
    expect(source, contains('minWidth: viewportWidth'));
    expect(source, contains('maxWidth: viewportWidth'));
    expect(
      source,
      contains(
        'constraints: _fullWidthBottomSheetConstraints(context, constraints)',
      ),
    );
    expect(source, contains('width: double.infinity'));
  });

  test(
    'titled app modal bottom sheets keep the surface anchored to screen bottom',
    () {
      final source = File(
        'lib/core/ui/app_modal_templates.dart',
      ).readAsStringSync();

      final sheetStart = source.indexOf(
        'Future<T?> showAppModalBottomSheet<T>',
      );
      final actionSheetStart = source.indexOf(
        'Future<T?> showAppActionSheet<T>',
      );
      expect(sheetStart, isNonNegative);
      expect(actionSheetStart, greaterThan(sheetStart));

      final sheetSource = source.substring(sheetStart, actionSheetStart);
      expect(
        sheetSource,
        matches(RegExp(r'SafeArea\(\s*top:\s*false,\s*bottom:\s*false,')),
      );
      expect(
        sheetSource,
        matches(RegExp(r'AppModalSheetFrame\(\s*useSafeArea:\s*false,')),
      );
      expect(
        sheetSource,
        isNot(
          contains(
            'SafeArea(\n          top: false,\n          child: DraggableScrollableSheet(',
          ),
        ),
      );
      expect(sheetSource, contains('surfaceBorderRadius: AppRadius.sheetTop'));
    },
  );

  test(
    'titled app modal bottom sheets reserve Android navigation safe padding',
    () {
      final source = File(
        'lib/core/ui/app_modal_templates.dart',
      ).readAsStringSync();

      final scaffoldStart = source.indexOf('class AppModalScaffold<T>');
      final dialogStart = source.indexOf('class AppModalDialogCard');
      final sheetStart = source.indexOf(
        'Future<T?> showAppModalBottomSheet<T>',
      );
      final actionSheetStart = source.indexOf(
        'Future<T?> showAppActionSheet<T>',
      );

      expect(scaffoldStart, isNonNegative);
      expect(dialogStart, greaterThan(scaffoldStart));
      expect(sheetStart, isNonNegative);
      expect(actionSheetStart, greaterThan(sheetStart));

      final scaffoldSource = source.substring(scaffoldStart, dialogStart);
      final sheetSource = source.substring(sheetStart, actionSheetStart);

      expect(scaffoldSource, contains('this.bottomSafeAreaPadding = 0'));
      expect(scaffoldSource, contains('final double bottomSafeAreaPadding'));
      expect(
        scaffoldSource,
        contains('contentPadding.bottom + bottomSafeAreaPadding'),
      );
      expect(scaffoldSource, contains('AppSpacing.xl + bottomSafeAreaPadding'));
      expect(
        sheetSource,
        contains('final systemBottomPadding = mediaQuery.viewPadding.bottom'),
      );
      expect(
        sheetSource,
        contains('bottomSafeAreaPadding: navigationSafeInset'),
      );
      expect(sheetSource, contains("'app-modal-titled-sheet-surface'"));
      expect(
        sheetSource,
        isNot(contains('AppEdgeInsets.only(bottom: systemBottomPadding)')),
      );
    },
  );

  test('app modal scaffold can use sheet-only top corners', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();

    final scaffoldStart = source.indexOf('class AppModalScaffold<T>');
    final dialogStart = source.indexOf('class AppModalDialogCard');
    expect(scaffoldStart, isNonNegative);
    expect(dialogStart, greaterThan(scaffoldStart));

    final scaffoldSource = source.substring(scaffoldStart, dialogStart);
    expect(
      scaffoldSource,
      contains('this.surfaceBorderRadius = AppRadius.panel'),
    );
    expect(
      scaffoldSource,
      contains('final BorderRadiusGeometry surfaceBorderRadius'),
    );
    expect(scaffoldSource, contains('borderRadius: surfaceBorderRadius'));
  });

  test('app modal scaffold uses compact typography by default', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();

    final scaffoldStart = source.indexOf('class AppModalScaffold<T>');
    final dialogCardStart = source.indexOf('class AppModalDialogCard');
    final actionsStart = source.indexOf('class _AppModalActions<T>');
    final actionSheetStart = source.indexOf('class _AppActionSheetList<T>');
    expect(scaffoldStart, isNonNegative);
    expect(dialogCardStart, greaterThan(scaffoldStart));
    expect(actionsStart, greaterThan(dialogCardStart));
    expect(actionSheetStart, greaterThan(actionsStart));

    final scaffoldSource = source.substring(scaffoldStart, dialogCardStart);
    final dialogSource = source.substring(dialogCardStart, actionsStart);
    final actionButtonSource = source.substring(actionsStart, actionSheetStart);

    expect(scaffoldSource, contains('fontSize: adaptive.isNarrow ? 18 : 20'));
    expect(scaffoldSource, contains('maxLines: 2'));
    expect(scaffoldSource, contains('fontSize: 13'));
    expect(dialogSource, contains('fontSize: adaptive.isNarrow ? 18 : 20'));
    expect(dialogSource, contains('fontSize: 13'));
    expect(actionButtonSource, contains('TextStyle _modalActionTextStyle'));
    expect(actionButtonSource, contains('fontSize: 14'));
    expect(
      actionButtonSource,
      isNot(contains('fontSize: adaptive.isNarrow ? 20 : 22')),
    );
  });

  test('app modal dialogs cannot disable outside tap dismissal', () {
    final source = File(
      'lib/core/ui/app_modal_templates.dart',
    ).readAsStringSync();
    final dialogStart = source.indexOf('Future<T?> showAppModalDialog<T>');
    final bottomSheetStart = source.indexOf(
      'Future<T?> showAppModalBottomSheet<T>',
    );

    expect(dialogStart, isNonNegative);
    expect(bottomSheetStart, greaterThan(dialogStart));

    final dialogSource = source.substring(dialogStart, bottomSheetStart);

    expect(dialogSource, isNot(contains('bool barrierDismissible')));
    expect(dialogSource, contains('barrierDismissible: true,'));
    expect(dialogSource, isNot(contains('barrierDismissible: false')));
  });

  test('mobile UI does not opt out of outside tap modal dismissal', () {
    final libDir = Directory('lib');
    final violations = <String>[];
    final bannedPatterns = <String, RegExp>{
      'barrierDismissible false': RegExp(r'barrierDismissible\s*:\s*false'),
      'isDismissible false': RegExp(r'isDismissible\s*:\s*false'),
    };

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.startsWith('lib/l10n/generated/')) continue;

      final source = entity.readAsStringSync();
      for (final entry in bannedPatterns.entries) {
        if (entry.value.hasMatch(source)) {
          violations.add('${entity.path} uses ${entry.key}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
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
        'showBottomSheet': RegExp(r'\bshowBottomSheet\s*(?:<|\()'),
        'showCupertinoModalPopup': RegExp(
          r'\bshowCupertinoModalPopup\s*(?:<|\()',
        ),
        'ModalBottomSheetRoute': RegExp(r'\bModalBottomSheetRoute\s*(?:<|\()'),
        'BottomSheet': RegExp(r'\bBottomSheet\s*\('),
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
