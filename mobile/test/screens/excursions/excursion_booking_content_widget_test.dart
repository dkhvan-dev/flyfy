import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/models/excursion_schedule_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/excursions/excursion_booking_screen.dart';
import 'package:intl/intl.dart';

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
    expect(
      find.text(DateFormat.yMMMd('en').format(_slot.startAt)),
      findsWidgets,
    );
    expect(find.text('08:00'), findsWidgets);
    expect(find.text('Travelers'), findsOneWidget);
    expect(find.text('Adults'), findsOneWidget);
    expect(find.text('Children'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('CONFIRM BOOKING'), findsOneWidget);
    expect(find.textContaining('No payment is charged now'), findsOneWidget);
  });

  testWidgets('stacks date and time schedule cards vertically', (tester) async {
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

  testWidgets('uses the active accent styling for both date and time cards', (
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

    final dateLabel = DateFormat.yMMMd('en').format(_slot.startAt);
    final dateText = tester
        .widgetList<Text>(find.text(dateLabel))
        .firstWhere((widget) => widget.style?.fontSize == 17);
    final timeText = tester
        .widgetList<Text>(find.text('08:00'))
        .firstWhere((widget) => widget.style?.fontSize == 17);

    expect(dateText.style?.color, AppPalette.primary);
    expect(timeText.style?.color, AppPalette.primary);

    final dateIcon = tester.widget<Icon>(
      find.byIcon(Icons.calendar_month_rounded),
    );
    final timeIcon = tester.widget<Icon>(find.byIcon(Icons.schedule_rounded));
    final dateIconBox = _scheduleIconBoxFor(
      tester,
      find.byIcon(Icons.calendar_month_rounded),
    );
    final timeIconBox = _scheduleIconBoxFor(
      tester,
      find.byIcon(Icons.schedule_rounded),
    );

    expect(dateIcon.color, timeIcon.color);
    expect(
      (dateIconBox.decoration! as BoxDecoration).color,
      (timeIconBox.decoration! as BoxDecoration).color,
    );
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

    final slotChip = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byKey(const ValueKey('booking-slot-chip-slot-2')),
    );
    expect(slotChip, findsOneWidget);

    await tester.tap(slotChip);
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

Container _scheduleIconBoxFor(WidgetTester tester, Finder iconFinder) {
  return tester
      .widgetList<Container>(
        find.ancestor(of: iconFinder, matching: find.byType(Container)),
      )
      .firstWhere((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
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

final _slotDate = DateTime(DateTime.now().year + 1, 6, 1);
final _slotStart = DateTime(_slotDate.year, _slotDate.month, _slotDate.day, 8);
final _slotEnd = _slotStart.add(const Duration(hours: 3));
final _laterSlotStart = _slotStart.add(const Duration(hours: 2));
final _laterSlotEnd = _laterSlotStart.add(const Duration(hours: 3));

final _slot = ExcursionScheduleSlotVm(
  id: 'slot-1',
  offerId: 'offer-1',
  productId: 'excursion-1',
  startAt: _slotStart,
  endAt: _slotEnd,
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
  startAt: _laterSlotStart,
  endAt: _laterSlotEnd,
  timezone: 'Asia/Almaty',
  capacity: 6,
  bookedSeats: 0,
  status: ExcursionScheduleSlotStatus.available,
  title: 'Almaty Mountain Escape',
);
