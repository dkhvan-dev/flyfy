import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

void main() {
  testWidgets('titled bottom sheet closes when tapping above visible sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      title: 'Theme',
                      subtitle: 'Choose app theme',
                      icon: Icons.contrast_rounded,
                      initialChildSize: 0.42,
                      minChildSize: 0.28,
                      maxChildSize: 0.72,
                      child: const Text('Theme options'),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Theme options'), findsOneWidget);

    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsNothing);
    expect(find.text('Theme options'), findsNothing);
  });

  testWidgets('titled bottom sheet stays open when tapping visible content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      title: 'Theme',
                      subtitle: 'Choose app theme',
                      icon: Icons.contrast_rounded,
                      initialChildSize: 0.42,
                      minChildSize: 0.28,
                      maxChildSize: 0.72,
                      child: const Text('Theme options'),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Theme options'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Theme options'), findsOneWidget);
  });
}
