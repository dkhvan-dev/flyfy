import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/ui/keyboard_dismiss_on_scroll.dart';

void main() {
  testWidgets('dismisses focused text field when the user scrolls', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppKeyboardDismissOnScroll(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                Expanded(
                  child: ListView.builder(
                    itemCount: 40,
                    itemBuilder: (context, index) {
                      return SizedBox(height: 56, child: Text('Item $index'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}
