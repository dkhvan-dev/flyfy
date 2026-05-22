import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/activities/activity_category_art.dart';
import 'package:superapp/features/activities/models/activity_list_item_vm.dart';
import 'package:superapp/l10n/generated/app_localizations.dart';
import 'package:superapp/screens/profile/widgets/profile_activity_card.dart';

void main() {
  testWidgets(
    'activity category cover does not overflow inside compact profile previews',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 84,
                child: ActivityDecorativeCoverFallback(
                  spec: ActivityCardArtSpec(
                    icon: Icons.forest_rounded,
                    colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact activity card keeps cover responsive', (tester) async {
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
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: ProfileCompactActivityCard(
                item: _activityWithoutCover(),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

ActivityListItemVm _activityWithoutCover() {
  return ActivityListItemVm(
    id: 'activity-1',
    hostUserId: 'host-1',
    title: 'Очень длинное название активности',
    description: 'Description',
    format: 'OFFLINE',
    status: 'COMPLETED',
    moderationStatus: 'APPROVED',
    visibility: 'PUBLIC',
    joinMode: 'OPEN',
    categorySlug: 'nature-outdoor',
    languageCode: 'ru',
    timezone: 'Asia/Almaty',
    startAt: DateTime.utc(2026, 5, 20, 5),
    endAt: DateTime.utc(2026, 5, 20, 10),
    capacityType: 'UNLIMITED',
    priceType: 'FREE',
    requiresProfileCompletion: false,
    requiresAttendanceConfirmation: false,
    completedAt: DateTime.utc(2026, 5, 20, 10),
  );
}
