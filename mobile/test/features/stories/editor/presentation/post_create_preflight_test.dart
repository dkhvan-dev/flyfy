import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/presentation/post_create_preflight.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('post publish cooldown renders a live mm:ss countdown', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 7, 11, 12);
    var elapsedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PostRateLimitCountdownText(
            retryAfter: const Duration(minutes: 5),
            now: () => now,
            onElapsed: () => elapsedCalls += 1,
          ),
        ),
      ),
    );

    expect(find.text('You can publish another post in 05:00.'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You can publish another post in 04:59.'), findsOneWidget);

    now = now.add(const Duration(minutes: 4, seconds: 59));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You can publish another post in 00:00.'), findsOneWidget);
    expect(elapsedCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(elapsedCalls, 1);
  });
}
