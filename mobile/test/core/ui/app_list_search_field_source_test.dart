import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared list search field matches excursions icon sizing and chrome',
    () async {
      final sharedFile = File('lib/core/ui/app_list_search_field.dart');
      expect(sharedFile.existsSync(), isTrue);

      final sharedSource = await sharedFile.readAsString();
      expect(
        sharedSource,
        contains('constraints: const BoxConstraints(minHeight: 58)'),
      );
      expect(
        sharedSource,
        contains('final colors = AppDesignSystem.colorsFor(context)'),
      );
      expect(sharedSource, contains('color: colors.surfaceRaised'));
      expect(
        sharedSource,
        contains('border: Border.all(color: colors.borderSoft)'),
      );
      expect(sharedSource, contains('AppBorderRadius.circular(21)'));
      expect(
        sharedSource,
        contains(
          'padding: const AppEdgeInsetsDirectional.fromSTEB(16, 0, 8, 0)',
        ),
      );
      expect(sharedSource, contains('Icons.search_rounded'));
      expect(sharedSource, contains('size: 27'));
      expect(sharedSource, contains('fontSize: 16'));
      expect(sharedSource, contains('IconButton.styleFrom('));
      expect(
        sharedSource,
        contains('backgroundColor: colors.primary.withValues(alpha: 0.12)'),
      );
      expect(sharedSource, contains('foregroundColor: colors.primary'));
      expect(sharedSource, contains('color: colors.textPrimary'));
      expect(sharedSource, contains('minimumSize: const Size(43, 43)'));
      expect(sharedSource, contains('Icons.tune_rounded, size: 24'));
      expect(sharedSource, contains('activeFilterCount.toString()'));
    },
  );

  test(
    'shared list search placeholder stays close to the search icon',
    () async {
      final sharedFile = File('lib/core/ui/app_list_search_field.dart');
      expect(sharedFile.existsSync(), isTrue);

      final sharedSource = await sharedFile.readAsString();
      final textFieldStart = sharedSource.indexOf('child: TextField(');
      final clearButtonStart = sharedSource.indexOf(
        'if (showClearButton)',
        textFieldStart,
      );

      expect(textFieldStart, isNonNegative);
      expect(clearButtonStart, greaterThan(textFieldStart));

      final textFieldSource = sharedSource.substring(
        textFieldStart,
        clearButtonStart,
      );

      expect(textFieldSource, contains('contentPadding: EdgeInsets.zero'));
    },
  );

  test('shared list search text input stays visually transparent', () async {
    final sharedFile = File('lib/core/ui/app_list_search_field.dart');
    expect(sharedFile.existsSync(), isTrue);

    final sharedSource = await sharedFile.readAsString();
    final textFieldStart = sharedSource.indexOf('child: TextField(');
    final clearButtonStart = sharedSource.indexOf(
      'if (showClearButton)',
      textFieldStart,
    );

    expect(textFieldStart, isNonNegative);
    expect(clearButtonStart, greaterThan(textFieldStart));

    final textFieldSource = sharedSource.substring(
      textFieldStart,
      clearButtonStart,
    );

    expect(textFieldSource, contains('filled: false'));
    expect(textFieldSource, isNot(contains('fillColor:')));
  });

  test(
    'shared list search text input does not draw an inner outline',
    () async {
      final sharedFile = File('lib/core/ui/app_list_search_field.dart');
      expect(sharedFile.existsSync(), isTrue);

      final sharedSource = await sharedFile.readAsString();
      final textFieldStart = sharedSource.indexOf('child: TextField(');
      final clearButtonStart = sharedSource.indexOf(
        'if (showClearButton)',
        textFieldStart,
      );

      expect(textFieldStart, isNonNegative);
      expect(clearButtonStart, greaterThan(textFieldStart));

      final textFieldSource = sharedSource.substring(
        textFieldStart,
        clearButtonStart,
      );

      expect(textFieldSource, contains('filled: false'));
      expect(textFieldSource, contains('border: InputBorder.none'));
      expect(textFieldSource, contains('enabledBorder: InputBorder.none'));
      expect(textFieldSource, contains('focusedBorder: InputBorder.none'));
      expect(textFieldSource, contains('disabledBorder: InputBorder.none'));
      expect(textFieldSource, isNot(contains('filled: true')));
    },
  );

  test('shared list search field supports screens without filters', () async {
    final sharedFile = File('lib/core/ui/app_list_search_field.dart');
    expect(sharedFile.existsSync(), isTrue);

    final sharedSource = await sharedFile.readAsString();

    expect(sharedSource, contains('this.showFilterButton = true'));
    expect(sharedSource, contains('final bool showFilterButton;'));
    expect(sharedSource, contains('if (showFilterButton)'));
    expect(sharedSource, contains('VoidCallback? onFilterTap'));
    expect(sharedSource, contains('String? filterTooltip'));
  });

  test('primary list screens use the shared list search field', () async {
    for (final path in [
      'lib/screens/activities/activities_screen.dart',
      'lib/screens/excursions/excursions_screen.dart',
      'lib/screens/places/places_screen.dart',
      'lib/screens/stories/stories_screen.dart',
      'lib/screens/guides/guides_screen.dart',
    ]) {
      final source = await File(path).readAsString();
      expect(
        source,
        contains("import '../../core/ui/app_list_search_field.dart';"),
        reason: path,
      );
      expect(source, contains('AppListSearchField('), reason: path);
    }
  });

  test('entity list searches stay on their own screen', () async {
    for (final path in [
      'lib/screens/activities/activities_screen.dart',
      'lib/screens/excursions/excursions_screen.dart',
      'lib/screens/places/places_screen.dart',
      'lib/screens/guides/guides_screen.dart',
      'lib/features/feed/presentation/community_discovery_screen.dart',
    ]) {
      final source = await File(path).readAsString();
      expect(source, isNot(contains('SearchRouteConfig(')), reason: path);
      expect(source, isNot(contains("path: '/search'")), reason: path);
      expect(source, isNot(contains('.location()')), reason: path);
    }
  });
}
