import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
import 'package:superapp/l10n/generated/app_localizations.dart';
import 'package:superapp/screens/excursions/excursion_booking_screen.dart';

void main() {
  testWidgets('renders booking content with schedule, travelers and summary',
      (tester) async {
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
          body: ExcursionBookingContent(
            excursion: _excursion,
            selectedDate: DateTime(2026, 5, 12),
            selectedTime: const TimeOfDay(hour: 10, minute: 0),
            adults: 1,
            children: 0,
            maxTravelers: 4,
            isSubmitting: false,
            onBackTap: () {},
            onChangeSchedule: () {},
            onIncrementAdults: () {},
            onDecrementAdults: () {},
            onIncrementChildren: () {},
            onDecrementChildren: () {},
            onConfirm: () {},
          ),
        ),
      ),
    );

    expect(find.text('Booking Excursion'), findsOneWidget);
    expect(find.text('Almaty Mountain Escape'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Travelers'), findsOneWidget);
    expect(find.text('Adults'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('CONFIRM & PAY'), findsOneWidget);
  });
}

const _excursion = ExcursionVm(
  id: 'excursion-1',
  title: 'Almaty Mountain Escape',
  summary: 'Private mountain route',
  description: 'A private alpine route through Shymbulak and Medeu.',
  categorySlug: 'adventure',
  durationMinutes: 480,
  maxGroupSize: 4,
  languageCodes: ['en'],
  includedItems: ['Private SUV'],
  status: 'PUBLISHED',
  visibility: 'PUBLIC',
  priceAmount: 240,
  currency: 'USD',
  cityName: 'Almaty',
  meetingPoint: 'Hotel pickup',
);
