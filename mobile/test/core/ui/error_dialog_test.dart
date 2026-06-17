import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_colors.dart';
import 'package:inflap/core/ui/error_dialog.dart';

void main() {
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

    final okButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'OK'),
    );
    expect(
      okButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.textPrimary,
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
