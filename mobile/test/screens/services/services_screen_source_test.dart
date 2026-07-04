import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('services screen uses the adaptive v2 design system', () async {
    final source = await File(
      'lib/screens/services/services_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('Theme('));
    expect(source, contains('data: AppDesignSystem.themeFor(context)'));
    expect(
      source,
      contains('final colors = AppDesignSystem.colorsFor(context)'),
    );
    expect(source, contains('backgroundColor: colors.background'));
    expect(source, contains('colors: colors.screenGradientColors'));
    expect(source, contains('style: AppBottomNavigationBarStyle.v2(context)'));
    expect(source, contains('style: ServiceGridStyle.v2(context)'));
    expect(source, contains('context.appColors.textPrimary'));
    expect(
      source,
      isNot(
        matches(
          RegExp(
            r'AppPalette\.(warm|orange|amber|violet|pink|blue|green|teal)',
          ),
        ),
      ),
    );
  });

  test('services screen header keeps title horizontally centered', () async {
    final source = await File(
      'lib/screens/services/services_screen.dart',
    ).readAsString();

    final headerStart = source.indexOf('class _ServicesHeader');
    expect(headerStart, isNonNegative);

    final headerSource = source.substring(headerStart);

    expect(headerSource, contains('Stack('));
    expect(headerSource, contains('alignment: Alignment.center'));
    expect(headerSource, contains('Align('));
    expect(headerSource, contains('alignment: Alignment.centerLeft'));
    expect(headerSource, contains('textAlign: TextAlign.center'));
  });
}
