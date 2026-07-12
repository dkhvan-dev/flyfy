import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/trust/widgets/trust_restriction_notice.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('restricted creation notice is localized and adaptive', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.35),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: TrustRestrictionNotice(creation: true),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Доступ ограничен'), findsOneWidget);
    expect(
      find.textContaining('Создание ограничено администратором'),
      findsOneWidget,
    );
    expect(find.text('Обратиться в поддержку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
