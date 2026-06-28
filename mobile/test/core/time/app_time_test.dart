import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/time/app_calendar_export.dart';
import 'package:inflap/core/time/app_time.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('formats event instant in the event timezone', () {
    final instant = DateTime.utc(2026, 6, 1, 3);
    final eventTime = eventDateTime(instant, 'Asia/Ho_Chi_Minh');

    expect(eventTime.year, 2026);
    expect(eventTime.month, 6);
    expect(eventTime.day, 1);
    expect(eventTime.hour, 10);
    expect(formatUtcOffset(eventTime.timeZoneOffset), 'UTC+07:00');
  });

  test('converts event wall-clock time to UTC using IANA timezone', () {
    final utc = eventWallClockToUtc(
      DateTime(2026, 6, 1, 10),
      'Asia/Ho_Chi_Minh',
    );

    expect(utc, DateTime.utc(2026, 6, 1, 3));
  });

  test('builds user timezone hint only when user timezone differs', () {
    final instant = DateTime.utc(2026, 6, 1, 3);

    final hint = formatUserTimezoneHint(
      instant: instant,
      eventTimezoneId: 'Asia/Ho_Chi_Minh',
      userTimezoneId: 'Asia/Almaty',
      localeName: 'en',
    );
    final sameTimezoneHint = formatUserTimezoneHint(
      instant: instant,
      eventTimezoneId: 'Asia/Ho_Chi_Minh',
      userTimezoneId: 'Asia/Ho_Chi_Minh',
      localeName: 'en',
    );

    expect(hint, contains('UTC+05:00'));
    expect(sameTimezoneHint, isNull);
  });

  test('calendar export keeps timezone id in DTSTART and DTEND', () {
    final ics = buildCalendarEventIcs(
      CalendarExportEvent(
        uid: 'activity-1@inflap',
        title: 'Hanoi breakfast walk',
        startAt: DateTime.utc(2026, 6, 1, 3),
        endAt: DateTime.utc(2026, 6, 1, 5),
        timezoneId: 'Asia/Ho_Chi_Minh',
        generatedAt: DateTime.utc(2026, 5, 1),
      ),
    );

    expect(ics, contains('X-WR-TIMEZONE:Asia/Ho_Chi_Minh'));
    expect(ics, contains('DTSTART;TZID=Asia/Ho_Chi_Minh:20260601T100000'));
    expect(ics, contains('DTEND;TZID=Asia/Ho_Chi_Minh:20260601T120000'));
    expect(ics, contains('DTSTAMP:20260501T000000Z'));
  });
}
