import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/router/app_router.dart';

void main() {
  testWidgets('keyboard focus is cleared when navigator route changes', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode)),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);

    KeyboardDismissRouteObserver().didPush(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      null,
    );
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}
