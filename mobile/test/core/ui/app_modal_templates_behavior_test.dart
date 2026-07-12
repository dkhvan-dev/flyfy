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

  testWidgets(
    'custom sheet surface reaches physical bottom and content clears navigation',
    (tester) async {
      const navigationBarHeight = 48.0;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                padding: const EdgeInsets.only(bottom: navigationBarHeight),
                viewPadding: const EdgeInsets.only(bottom: navigationBarHeight),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      builder: (sheetContext) => SizedBox(
                        height: 220,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'inner-bottom:'
                                '${MediaQuery.viewPaddingOf(sheetContext).bottom}',
                              ),
                              const Spacer(),
                              FilledButton(
                                key: const ValueKey('custom-sheet-action'),
                                onPressed: () {},
                                child: const Text('Continue'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open custom'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open custom'));
      await tester.pumpAndSettle();

      final surface = find.byKey(
        const ValueKey('app-modal-custom-sheet-surface'),
      );
      final action = find.byKey(const ValueKey('custom-sheet-action'));
      expect(surface, findsOneWidget);
      expect(action, findsOneWidget);
      expect(find.text('inner-bottom:0.0'), findsOneWidget);
      expect(tester.getBottomRight(surface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );
    },
  );

  testWidgets(
    'titled sheet surface reaches bottom and actions clear navigation',
    (tester) async {
      const navigationBarHeight = 48.0;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                padding: const EdgeInsets.only(bottom: navigationBarHeight),
                viewPadding: const EdgeInsets.only(bottom: navigationBarHeight),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      title: 'Confirm',
                      initialChildSize: 0.42,
                      minChildSize: 0.28,
                      maxChildSize: 0.72,
                      child: const Text('Review changes'),
                      actions: const [
                        AppModalAction<void>(
                          label: 'Apply',
                          variant: AppModalActionVariant.primary,
                          dismissesModal: false,
                        ),
                      ],
                    );
                  },
                  child: const Text('Open titled'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open titled'));
      await tester.pumpAndSettle();

      final surface = find.byKey(
        const ValueKey('app-modal-titled-sheet-surface'),
      );
      final action = find.widgetWithText(FilledButton, 'Apply');
      expect(surface, findsOneWidget);
      expect(action, findsOneWidget);
      expect(tester.getBottomRight(surface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );
    },
  );

  testWidgets('custom sheet moves once above keyboard without double inset', (
    tester,
  ) async {
    const keyboardHeight = 300.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              viewInsets: const EdgeInsets.only(bottom: keyboardHeight),
              padding: EdgeInsets.zero,
              viewPadding: const EdgeInsets.only(bottom: 48),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                onPressed: () {
                  showAppModalBottomSheet<void>(
                    context: context,
                    builder: (sheetContext) => SizedBox(
                      height: 180,
                      child: Column(
                        children: [
                          Text(
                            'inner-keyboard:'
                            '${MediaQuery.viewInsetsOf(sheetContext).bottom}',
                          ),
                          const Spacer(),
                          const Text('Keyboard content'),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open with keyboard'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open with keyboard'));
    await tester.pumpAndSettle();

    final surface = find.byKey(
      const ValueKey('app-modal-custom-sheet-surface'),
    );
    expect(surface, findsOneWidget);
    expect(find.text('inner-keyboard:0.0'), findsOneWidget);
    expect(
      tester.getBottomRight(surface).dy,
      closeTo(844 - keyboardHeight, 0.1),
    );
  });

  testWidgets(
    'custom transparent sheet preserves the scrim and never fills the viewport',
    (tester) async {
      const navigationBarHeight = 48.0;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                padding: const EdgeInsets.only(bottom: navigationBarHeight),
                viewPadding: const EdgeInsets.only(bottom: navigationBarHeight),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      contentHandlesBottomSafeArea: true,
                      builder: (sheetContext) => AppModalSheetFrame(
                        onTapOutside: () =>
                            Navigator.of(sheetContext).maybePop(),
                        child: Container(
                          key: const ValueKey('child-owned-sheet-surface'),
                          height: 900,
                          color: Colors.red,
                          child: SafeArea(
                            top: false,
                            child: Column(
                              children: [
                                Text(
                                  'inner-bottom:'
                                  '${MediaQuery.paddingOf(sheetContext).bottom}',
                                ),
                                const Spacer(),
                                FilledButton(
                                  key: const ValueKey('child-owned-action'),
                                  onPressed: () {},
                                  child: const Text('Custom content'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open transparent'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open transparent'));
      await tester.pumpAndSettle();

      final surfaceFinder = find.byKey(
        const ValueKey('app-modal-custom-sheet-surface'),
      );
      final surface = tester.widget<Material>(surfaceFinder);
      final childSurface = find.byKey(
        const ValueKey('child-owned-sheet-surface'),
      );
      final action = find.byKey(const ValueKey('child-owned-action'));
      expect(surface.color, Colors.transparent);
      expect(tester.getSize(surfaceFinder).height, lessThan(844));
      expect(tester.getSize(surfaceFinder).height, closeTo(844 * 0.92, 0.1));
      expect(find.text('inner-bottom:48.0'), findsOneWidget);
      expect(tester.getBottomRight(childSurface).dy, closeTo(844, 0.1));
      expect(
        tester.getBottomRight(action).dy,
        lessThanOrEqualTo(844 - navigationBarHeight),
      );
    },
  );

  testWidgets('titled sheet clamps caller height to the modal ceiling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppModalBottomSheet<void>(
                    context: context,
                    title: 'Bounded sheet',
                    initialChildSize: 1,
                    maxChildSize: 1,
                    child: const SizedBox(
                      height: 1200,
                      child: Text('Bounded content'),
                    ),
                  );
                },
                child: const Text('Open bounded'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open bounded'));
    await tester.pumpAndSettle();

    final surface = find.byKey(
      const ValueKey('app-modal-titled-sheet-surface'),
    );
    expect(tester.getSize(surface).height, lessThan(844));
    expect(tester.getSize(surface).height, closeTo(844 * 0.92, 0.1));
  });
}
