import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/filter_sheet_chrome.dart';

void main() {
  testWidgets('filter sheet header matches activity modal chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
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

    expect(title.textAlign, TextAlign.center);
    expect(title.maxLines, 1);
    expect(clear.style?.foregroundColor?.resolve({}), AppPalette.primary);
  });

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
}
