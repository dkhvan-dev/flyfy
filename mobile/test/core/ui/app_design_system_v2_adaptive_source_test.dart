import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrated v2 screens use adaptive v2 theme', () async {
    final screenPaths = [
      'lib/screens/home/home_screen.dart',
      'lib/screens/services/services_screen.dart',
      'lib/screens/auth/login_screen.dart',
      'lib/screens/auth/otp_screen.dart',
      'lib/screens/auth/password_reset_screen.dart',
      'lib/screens/attendance/attendance_scanner_screen.dart',
      'lib/screens/chat/conversations_screen.dart',
      'lib/screens/notifications/notifications_screen.dart',
    ];

    for (final path in screenPaths) {
      final source = await File(path).readAsString();

      expect(
        source,
        contains('data: AppDesignSystem.themeFor(context)'),
        reason: path,
      );
      expect(
        source,
        isNot(contains('data: AppDesignSystem.darkTheme()')),
        reason: path,
      );
    }
  });

  test('v2 shared styles expose adaptive constructors', () async {
    final bottomNavSource = await File(
      'lib/core/ui/app_bottom_navigation_bars.dart',
    ).readAsString();
    final serviceGridSource = await File(
      'lib/features/services/widgets/service_grid.dart',
    ).readAsString();

    expect(
      bottomNavSource,
      contains('static AppBottomNavigationBarStyle v2(BuildContext context)'),
    );
    expect(
      serviceGridSource,
      contains('static ServiceGridStyle v2(BuildContext context)'),
    );
  });

  test(
    'bottom navigation chrome is fully migrated to adaptive v2 colors',
    () async {
      final source = await File(
        'lib/core/ui/app_bottom_navigation_bars.dart',
      ).readAsString();

      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('AppBottomNavigationBarStyle.v2(context)'));
      expect(source, isNot(contains('AppBottomNavigationBarStyle.legacy')));
      expect(source, isNot(contains('AppPalette.')));
    },
  );

  test('migrated core list controls consume adaptive v2 colors', () async {
    final componentPaths = [
      'lib/core/ui/app_list_search_field.dart',
      'lib/core/ui/app_inline_sort_row.dart',
      'lib/core/ui/app_inline_field_error.dart',
      'lib/core/ui/pagination_bar.dart',
    ];

    for (final path in componentPaths) {
      final source = await File(path).readAsString();

      expect(
        source,
        contains('AppDesignSystem.colorsFor(context)'),
        reason: path,
      );
      expect(source, isNot(contains('AppPalette.')), reason: path);
    }
  });

  test('migrated core modal chrome consumes adaptive v2 colors', () async {
    final componentPaths = [
      'lib/core/ui/app_modal_templates.dart',
      'lib/core/ui/error_dialog.dart',
      'lib/core/ui/error_view.dart',
      'lib/core/ui/filter_sheet_chrome.dart',
      'lib/core/ui/app_list_screen_header.dart',
      'lib/core/ui/app_language_sheet.dart',
      'lib/core/ui/tag_chip.dart',
    ];

    for (final path in componentPaths) {
      final source = await File(path).readAsString();

      expect(
        source,
        contains('AppDesignSystem.colorsFor(context)'),
        reason: path,
      );
      expect(source, isNot(contains('AppPalette.')), reason: path);
    }
  });

  test(
    'common modal header icon uses secondary informational accent',
    () async {
      final source = await File(
        'lib/core/ui/app_modal_templates.dart',
      ).readAsString();

      expect(source, contains('color: colors.secondaryContainer'));
      expect(source, contains('Border.all(color: colors.borderSecondary)'));
      expect(source, contains('Icon(icon, color: colors.secondary'));
    },
  );
}
