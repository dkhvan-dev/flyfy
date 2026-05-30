import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_schedule_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursion_booking_screen.dart';

void main() {
  testWidgets('renders booking content with schedule, travelers and summary', (
    tester,
  ) async {
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
            slots: [_slot],
            selectedSlot: _slot,
            isScheduleLoading: false,
            adults: 1,
            children: 0,
            maxTravelers: 4,
            isSubmitting: false,
            onBackTap: () {},
            onSelectSlot: (_) {},
            onReloadSchedule: () {},
            onIncrementAdults: () {},
            onDecrementAdults: () {},
            onIncrementChildren: () {},
            onDecrementChildren: () {},
            onConfirm: () {},
            existingBooking: null,
            onOpenMyExcursions: () {},
          ),
        ),
      ),
    );

    expect(find.text('Booking Excursion'), findsOneWidget);
    expect(find.text('Almaty Mountain Escape'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Jun 1, 2026'), findsWidgets);
    expect(find.text('08:00'), findsWidgets);
    expect(find.text('Travelers'), findsOneWidget);
    expect(find.text('Adults'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('CONFIRM & PAY'), findsOneWidget);
  });

  testWidgets('stacks date and time schedule cards vertically', (
    tester,
  ) async {
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
            slots: [_slot],
            selectedSlot: _slot,
            isScheduleLoading: false,
            adults: 1,
            children: 0,
            maxTravelers: 4,
            isSubmitting: false,
            onBackTap: () {},
            onSelectSlot: (_) {},
            onReloadSchedule: () {},
            onIncrementAdults: () {},
            onDecrementAdults: () {},
            onIncrementChildren: () {},
            onDecrementChildren: () {},
            onConfirm: () {},
            existingBooking: null,
            onOpenMyExcursions: () {},
          ),
        ),
      ),
    );

    final dateBottom = tester.getBottomLeft(find.text('Date')).dy;
    final timeTop = tester.getTopLeft(find.text('Time Slot')).dy;

    expect(timeTop, greaterThan(dateBottom));
  });

  testWidgets('opens slot selector from change action and selects slot', (
    tester,
  ) async {
    ExcursionScheduleSlotVm? selected;

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
            slots: [_slot, _laterSlot],
            selectedSlot: _slot,
            isScheduleLoading: false,
            adults: 1,
            children: 0,
            maxTravelers: 4,
            isSubmitting: false,
            onBackTap: () {},
            onSelectSlot: (slot) => selected = slot,
            onReloadSchedule: () {},
            onIncrementAdults: () {},
            onDecrementAdults: () {},
            onIncrementChildren: () {},
            onDecrementChildren: () {},
            onConfirm: () {},
            existingBooking: null,
            onOpenMyExcursions: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Select an available time'), findsOneWidget);

    await tester.tap(find.text('10:00').last);
    await tester.pumpAndSettle();

    expect(selected?.id, 'slot-2');
  });

  testWidgets('caps traveler increments by selected slot available seats', (
    tester,
  ) async {
    var childIncrementCount = 0;

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
            slots: [_slot],
            selectedSlot: _slot,
            isScheduleLoading: false,
            adults: 2,
            children: 1,
            maxTravelers: 8,
            isSubmitting: false,
            onBackTap: () {},
            onSelectSlot: (_) {},
            onReloadSchedule: () {},
            onIncrementAdults: () {},
            onDecrementAdults: () {},
            onIncrementChildren: () => childIncrementCount++,
            onDecrementChildren: () {},
            onConfirm: () {},
            existingBooking: null,
            onOpenMyExcursions: () {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Children'));
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pump();

    expect(childIncrementCount, 0);
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

final _slot = ExcursionScheduleSlotVm(
  id: 'slot-1',
  offerId: 'offer-1',
  productId: 'excursion-1',
  startAt: DateTime(2026, 6, 1, 8),
  endAt: DateTime(2026, 6, 1, 11),
  timezone: 'Asia/Almaty',
  capacity: 4,
  bookedSeats: 1,
  status: ExcursionScheduleSlotStatus.booked,
  title: 'Almaty Mountain Escape',
);

final _laterSlot = ExcursionScheduleSlotVm(
  id: 'slot-2',
  offerId: 'offer-1',
  productId: 'excursion-1',
  startAt: DateTime(2026, 6, 1, 10),
  endAt: DateTime(2026, 6, 1, 13),
  timezone: 'Asia/Almaty',
  capacity: 6,
  bookedSeats: 0,
  status: ExcursionScheduleSlotStatus.available,
  title: 'Almaty Mountain Escape',
);
