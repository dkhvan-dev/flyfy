import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/saved/presentation/widgets/saved_collections_navigation.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

import '../../support/saved_test_fakes.dart';

void main() {
  testWidgets('compact preview opens all collections without expanding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final collections = [
      savedCollection(id: collectionA, title: 'Weekend'),
      savedCollection(id: collectionB, title: 'Summer'),
      savedCollection(id: _collectionC, title: 'Almaty'),
      savedCollection(id: _collectionD, title: 'Ideas'),
    ];
    var seeAllTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesignSystem.lightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SavedCollectionsNavigation(
            collections: collections,
            selectedCollectionId: null,
            expanded: false,
            isRefreshing: false,
            hasError: false,
            onAllTap: () {},
            onCollectionTap: (_) {},
            onRetry: () {},
            onSeeAllTap: () => seeAllTapCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final all = find.byKey(const ValueKey('saved-all-navigation'));
    final first = find.byKey(
      const ValueKey('saved-collection-navigation-$collectionA'),
    );
    final second = find.byKey(
      const ValueKey('saved-collection-navigation-$collectionB'),
    );
    final fourth = find.byKey(
      const ValueKey('saved-collection-navigation-$_collectionD'),
    );
    expect(all, findsOneWidget);
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(fourth, findsNothing);
    expect(tester.getTopLeft(all).dy, tester.getTopLeft(first).dy);
    expect(tester.getTopLeft(all).dx, lessThan(tester.getTopLeft(first).dx));
    expect(
      tester.getTopLeft(second).dy,
      greaterThan(tester.getTopLeft(all).dy),
    );
    expect(tester.getSize(first).height, 72);
    expect(
      tester.getSize(
        find.descendant(of: first, matching: find.byIcon(Icons.folder_rounded)),
      ),
      const Size.square(64),
    );
    expect(find.text('See all'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-collections-see-all')));
    await tester.pumpAndSettle();

    expect(seeAllTapCount, 1);
    expect(fourth, findsNothing);
    expect(find.text('Collapse'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact navigation stacks safely for large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesignSystem.lightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SavedCollectionsNavigation(
            collections: [
              savedCollection(
                id: collectionA,
                title: 'A very long personal travel collection title',
              ),
              savedCollection(id: collectionB),
              savedCollection(id: _collectionC),
              savedCollection(id: _collectionD),
            ],
            selectedCollectionId: null,
            expanded: false,
            isRefreshing: false,
            hasError: false,
            onAllTap: () {},
            onCollectionTap: (_) {},
            onRetry: () {},
            onSeeAllTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final all = find.byKey(const ValueKey('saved-all-navigation'));
    final first = find.byKey(
      const ValueKey('saved-collection-navigation-$collectionA'),
    );
    expect(tester.getTopLeft(first).dx, tester.getTopLeft(all).dx);
    expect(tester.getTopLeft(first).dy, greaterThan(tester.getTopLeft(all).dy));
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('saved-collections-see-all')),
          )
          .tooltip,
      'See all',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('generic collection cover stays distinct in the dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesignSystem.darkTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SavedCollectionsNavigation(
            collections: [savedCollection()],
            selectedCollectionId: null,
            expanded: false,
            isRefreshing: false,
            hasError: false,
            onAllTap: () {},
            onCollectionTap: (_) {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final folderFinder = find.byIcon(Icons.folder_rounded);
    final icon = tester.widget<Icon>(folderFinder);
    final iconElement = tester.element(folderFinder);
    DecoratedBox? cover;
    iconElement.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is DecoratedBox) {
        cover = widget;
        return false;
      }
      return true;
    });

    final decoration = cover!.decoration as BoxDecoration;
    final border = decoration.border! as Border;
    expect(decoration.color, AppColorSchemes.dark.primaryContainer);
    expect(icon.color, AppColorSchemes.dark.primary);
    expect(border.top.color, AppColorSchemes.dark.primary);
    expect(decoration.color, isNot(AppColorSchemes.dark.surfaceRaised));
    expect(
      _contrastRatio(icon.color!, decoration.color!),
      greaterThanOrEqualTo(3),
    );
  });
}

const _collectionC = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const _collectionD = '12345678-1234-1234-1234-123456789abc';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance();
  final darker = background.computeLuminance();
  final high = lighter > darker ? lighter : darker;
  final low = lighter > darker ? darker : lighter;
  return (high + 0.05) / (low + 0.05);
}
