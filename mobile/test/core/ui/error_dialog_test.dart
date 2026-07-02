import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/error_dialog.dart';

void main() {
  test('error dialog is composed from the app modal template', () {
    final source = File('lib/core/ui/error_dialog.dart').readAsStringSync();

    expect(source, contains('showAppModalDialog<void>('));
    expect(source, contains('AppModalDialogCard('));
    expect(source, contains('Icons.warning_amber_rounded'));
    expect(
      source,
      contains('constraints: const BoxConstraints(maxWidth: 360)'),
    );
    expect(source, contains('AppButtonStyles.primary(dialogColors)'));
    expect(source, isNot(contains('AppPalette.')));
    expect(source, isNot(contains('ElevatedButton(')));
  });

  test('feature error popups reuse showErrorDialog', () {
    final chatSharedSource = File(
      'lib/screens/chat/chat_shared_content_screen.dart',
    ).readAsStringSync();

    expect(chatSharedSource, contains('showErrorDialog('));
    expect(
      chatSharedSource,
      isNot(contains('_showSharedFileError(String message)')),
    );
  });

  testWidgets('error dialog content is rendered inside Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _ErrorDialogLauncher())),
    );

    await tester.tap(find.text('Show error'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save'), findsOneWidget);
    expect(
      find.text('Please check your connection and try again.'),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Could not save'),
        matching: find.byType(Material),
      ),
      findsWidgets,
    );

    final okButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'OK'),
    );
    expect(
      okButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColorSchemes.light.textPrimary,
    );
  });
}

class _ErrorDialogLauncher extends StatelessWidget {
  const _ErrorDialogLauncher();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showErrorDialog(
          context,
          title: 'Could not save',
          message: 'Please check your connection and try again.',
        );
      },
      child: const Text('Show error'),
    );
  }
}
