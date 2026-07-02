import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_inline_field_error.dart';

void main() {
  testWidgets('inline field error uses icon, red text, and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesignSystem.lightTheme(),
        home: const Scaffold(
          body: AppInlineFieldError(message: 'Choose at least one option'),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Choose at least one option'), findsOneWidget);

    final text = tester.widget<Text>(find.text('Choose at least one option'));
    expect(text.style?.color, AppColorSchemes.light.danger);
    expect(text.maxLines, 3);
    expect(text.overflow, TextOverflow.ellipsis);

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
    );
    expect(semantics.properties.liveRegion, isTrue);
  });
}
