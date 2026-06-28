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
      expect(sharedSource, contains('color: AppPalette.surfaceRaised'));
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
        contains('backgroundColor: AppPalette.primary.withValues(alpha: 0.12)'),
      );
      expect(sharedSource, contains('foregroundColor: AppPalette.primary'));
      expect(sharedSource, contains('minimumSize: const Size(43, 43)'));
      expect(sharedSource, contains('Icons.tune_rounded, size: 24'));
      expect(sharedSource, contains('activeFilterCount.toString()'));
    },
  );

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
}
