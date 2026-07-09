import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/filter_sheet_chrome.dart';

void main() {
  testWidgets('filter sheet header matches compact modal chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesignSystem.lightTheme(),
        home: Scaffold(
          body: AppFilterSheetHeader(
            title: 'Filters',
            clearLabel: 'Clear',
            onClear: () {},
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('FILTERS'));
    final clear = tester.widget<TextButton>(
      find.ancestor(of: find.text('CLEAR'), matching: find.byType(TextButton)),
    );

    expect(title.textAlign, TextAlign.start);
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(
      clear.style?.foregroundColor?.resolve({}),
      AppColorSchemes.light.primary,
    );
  });

  test(
    'filter sheet header does not reserve symmetric action width that clips title',
    () async {
      final source = await File(
        'lib/core/ui/filter_sheet_chrome.dart',
      ).readAsString();

      final headerStart = source.indexOf('class AppFilterSheetHeader');
      final applyStart = source.indexOf('class AppFilterApplyButton');
      expect(headerStart, isNonNegative);
      expect(applyStart, greaterThan(headerStart));

      final headerSource = source.substring(headerStart, applyStart);

      expect(headerSource, contains('Row('));
      expect(headerSource, contains('Expanded('));
      expect(headerSource, contains('FittedBox('));
      expect(headerSource, contains('alignment: Alignment.centerLeft'));
      expect(headerSource, contains('textAlign: TextAlign.start'));
      expect(headerSource, contains('fontSize: effectiveTitleSize'));
      expect(headerSource, isNot(contains('Stack(')));
      expect(headerSource, isNot(contains('reservedActionWidth')));
      expect(headerSource, isNot(contains('title.toUpperCase()')));
    },
  );

  testWidgets('filter apply button stretches and keeps entity count label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AppFilterApplyButton(
              label: 'Show 12 stories',
              onTap: () {},
              minHeight: 52,
            ),
          ),
        ),
      ),
    );

    final buttonBox = tester.renderObject<RenderBox>(find.byType(FilledButton));
    final label = tester.widget<Text>(find.text('Show 12 stories'));

    expect(buttonBox.size.width, 360);
    expect(label.maxLines, 2);
    expect(label.textAlign, TextAlign.center);
  });

  test('filter sheet chrome uses compact default typography', () async {
    final source = await File(
      'lib/core/ui/filter_sheet_chrome.dart',
    ).readAsString();

    expect(source, contains('final effectiveTitleSize ='));
    expect(source, contains('final normalizedTitle ='));
    expect(source, contains('titleFontSize ?? 15'));
    expect(source, contains('fontSize ?? 14'));
    expect(source, isNot(contains('fontSize ?? 17')));
  });
}
