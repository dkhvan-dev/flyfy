import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'V2 design system is exposed through the main design system entrypoint',
    () async {
      final source = await File(
        'lib/core/ui/app_design_system.dart',
      ).readAsString();

      expect(
        source,
        contains("static const name = 'Inflap Mobile Design System'"),
      );
      expect(
        source,
        contains('static ThemeData themeFor(BuildContext context)'),
      );
      expect(
        source,
        contains('static AppColors colorsFor(BuildContext context)'),
      );
      expect(source, contains('class AppColors'));
      expect(source, contains('abstract final class AppColorSchemes'));
      expect(source, contains('abstract final class AppButtonStyles'));
      expect(source, contains('extension AppDesignSystemContext'));
      expect(
        source,
        isNot(
          contains(
            'AppDesignSystem'
            'V2',
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains(
            'AppPalette'
            'V2',
          ),
        ),
      );
      expect(
        source,
        isNot(
          contains(
            'AppColors'
            'V2',
          ),
        ),
      );
    },
  );

  test('mobile source imports only the main design system entrypoint', () {
    final offenders =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) {
              final source = file.readAsStringSync();
              return source.contains(
                    'app_design_system_'
                    'v2.dart',
                  ) ||
                  source.contains(
                    'AppDesignSystem'
                    'V2',
                  ) ||
                  source.contains(
                    'AppPalette'
                    'V2',
                  ) ||
                  source.contains(
                    'AppColors'
                    'V2',
                  ) ||
                  source.contains(
                    'AppColorSchemes'
                    'V2',
                  ) ||
                  source.contains(
                    'AppButtonStyles'
                    'V2',
                  ) ||
                  source.contains(
                    'AppInputDecorations'
                    'V2',
                  ) ||
                  source.contains(
                    'AppBorders'
                    'V2',
                  ) ||
                  source.contains(
                    'AppTheme'
                    'V2',
                  ) ||
                  source.contains('v2Colors');
            })
            .map(
              (file) =>
                  file.path.replaceFirst('${Directory.current.path}/', ''),
            )
            .toList()
          ..sort();

    expect(offenders, isEmpty);
  });
}
