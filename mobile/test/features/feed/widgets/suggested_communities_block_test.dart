import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';
import 'package:inflap/features/feed/widgets/suggested_communities_block.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/shared/reference/app_location_label_resolver.dart';

void main() {
  testWidgets(
    'renders unsubscribed community recommendations in a two-row rail',
    (tester) async {
      var openAllCount = 0;
      final locationResolver = AppLocationLabelResolver(
        countryLookup: (code, {required lang}) async => ReferenceCountry(
          code: code,
          name: lang == 'ru' ? 'Вьетнам' : 'Vietnam',
        ),
        cityLookup: (id, {required lang}) async => ReferenceCity(
          id: id,
          countryCode: 'VN',
          name: lang == 'ru' ? 'Дананг' : 'Da Nang',
        ),
      );

      await tester.pumpWidget(
        _app(
          SuggestedCommunitiesBlock(
            locationLabelResolver: locationResolver,
            communities: [
              _community('investments', title: 'Инвестиции · da-nang'),
              _community(
                'joined',
                title: 'Уже подписан',
                followedByViewer: true,
              ),
              _community('crypto', title: 'Blockchain&Crypto'),
              _community('food', title: 'Food routes'),
            ],
            onCommunityToggle: (_) {},
            onOpenAll: () => openAllCount += 1,
          ),
          locale: const Locale('ru'),
        ),
      );
      await tester.pumpAndSettle();

      final blockDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('suggested-communities-block')),
      );
      final blockBoxDecoration = blockDecoration.decoration as BoxDecoration;
      expect(blockBoxDecoration.color, const Color(0xFF2A1A0E));
      expect(find.text('Инвестиции'), findsOneWidget);
      expect(find.text('Инвестиции · da-nang'), findsNothing);
      expect(find.text('Дананг'), findsNWidgets(3));
      expect(find.text('1200 подписчиков'), findsNWidgets(3));
      expect(find.text('Route ideas'), findsNothing);
      expect(find.text('Blockchain&Crypto'), findsOneWidget);
      expect(find.text('Food routes'), findsOneWidget);
      expect(find.text('Уже подписан'), findsNothing);
      expect(
        find.byKey(const ValueKey('suggested-communities-rail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('suggested-communities-clip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('suggested-communities-row-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('suggested-communities-row-1')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('open-community-discovery-sheet')),
      );
      await tester.pump();

      expect(openAllCount, 1);
    },
  );
}

Widget _app(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

FeedCommunityVm _community(
  String id, {
  required String title,
  bool followedByViewer = false,
}) {
  return FeedCommunityVm(
    id: id,
    title: title,
    subtitle: 'Route ideas',
    cityId: 'da-nang',
    cityName: 'Da Nang',
    membersCount: 1200,
    followedByViewer: followedByViewer,
  );
}
