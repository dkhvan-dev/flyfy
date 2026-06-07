import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursions_screen.dart';

void main() {
  testWidgets(
    'excursion list card stays within compact grid cell and exposes semantics',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 236,
                child: ExcursionListCard(
                  excursion: _longExcursion,
                  languageCode: 'en',
                  seed: 7,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExcursionListCard));
      expect(tapped, isTrue);

      final semanticsData = tester
          .getSemantics(find.byType(ExcursionListCard))
          .getSemanticsData();
      expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticsData.label, contains('Long compact-grid excursion'));
    },
  );
}

const _longExcursion = ExcursionVm(
  id: 'excursion-compact-card',
  title: 'Long compact-grid excursion through old city and mountain viewpoints',
  summary: 'Compact responsive card regression fixture',
  categorySlug: 'culture',
  durationMinutes: 480,
  maxGroupSize: 12,
  languageCodes: ['en', 'ru', 'kk'],
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 250000,
  currency: 'KZT',
  cityName: 'Almaty',
  landmarkName: 'Long compact-grid excursion',
);
