import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation list uses the adaptive v2 design system', () async {
    final source = await File(
      'lib/screens/chat/conversations_screen.dart',
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
    expect(source, contains('AppPalette.primary'));
    expect(source, contains('AppPalette.secondary'));
    expect(source, contains('CommonBottomNavigationBar('));
    expect(source, contains('activeItem: AppBottomNavItem.chats'));
    expect(source, contains('style: AppBottomNavigationBarStyle.v2(context)'));
    expect(source, contains('AppButtonStyles.icon(context.appColors)'));
    final legacyPaletteSource = source
        .replaceAll('AppPalette.primary', '')
        .replaceAll('AppPalette.secondary', '')
        .replaceAll('AppPalette.transparent', '');
    expect(
      legacyPaletteSource,
      isNot(
        matches(
          RegExp(
            r'AppPalette\.(warm|orange|amber|violet|pink|blue|green|teal)',
          ),
        ),
      ),
    );
  });
}
