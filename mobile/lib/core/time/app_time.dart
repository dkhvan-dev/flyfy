import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _isTimezoneDatabaseReady = false;

void ensureAppTimezoneDatabaseInitialized() {
  if (_isTimezoneDatabaseReady) return;
  tz_data.initializeTimeZones();
  _isTimezoneDatabaseReady = true;
}

tz.Location appTimezoneLocation(String? timezoneId) {
  ensureAppTimezoneDatabaseInitialized();

  final normalized = timezoneId?.trim();
  if (normalized == null || normalized.isEmpty) {
    return tz.UTC;
  }

  try {
    return tz.getLocation(normalized);
  } catch (_) {
    return tz.UTC;
  }
}

tz.TZDateTime eventDateTime(DateTime instant, String? timezoneId) {
  final location = appTimezoneLocation(timezoneId);
  return tz.TZDateTime.from(instant.toUtc(), location);
}

DateTime eventWallClockToUtc(DateTime wallClock, String? timezoneId) {
  final location = appTimezoneLocation(timezoneId);
  final zoned = tz.TZDateTime(
    location,
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
  return zoned.toUtc();
}

DateTime eventDateOnly(DateTime instant, String? timezoneId) {
  final zoned = eventDateTime(instant, timezoneId);
  return DateTime(zoned.year, zoned.month, zoned.day);
}

bool isSameEventDate(DateTime instant, DateTime date, String? timezoneId) {
  final eventDate = eventDateOnly(instant, timezoneId);
  final target = DateTime(date.year, date.month, date.day);
  return eventDate == target;
}

String formatEventDateTime(
  DateTime instant, {
  required String? timezoneId,
  required String localeName,
}) {
  final zoned = eventDateTime(instant, timezoneId);
  final formatted = DateFormat.MMMd(localeName).add_Hm().format(zoned);
  return '$formatted · ${formatUtcOffset(zoned.timeZoneOffset)}';
}

String formatEventDate(
  DateTime instant, {
  required String? timezoneId,
  required String localeName,
}) {
  return DateFormat.MMMd(localeName).format(eventDateTime(instant, timezoneId));
}

String formatEventTime(
  DateTime instant, {
  required String? timezoneId,
  required String localeName,
}) {
  return DateFormat.Hm(localeName).format(eventDateTime(instant, timezoneId));
}

String formatEventTimeRange({
  required DateTime start,
  required DateTime end,
  required String? timezoneId,
  required String localeName,
  bool includeTimezone = true,
}) {
  final startZoned = eventDateTime(start, timezoneId);
  final endZoned = eventDateTime(end, timezoneId);
  final timeFormat = DateFormat.Hm(localeName);
  final label =
      '${timeFormat.format(startZoned)} - ${timeFormat.format(endZoned)}';
  if (!includeTimezone) return label;
  return '$label · ${formatUtcOffset(startZoned.timeZoneOffset)}';
}

String? formatUserTimezoneHint({
  required DateTime instant,
  required String? eventTimezoneId,
  required String? userTimezoneId,
  required String localeName,
}) {
  final normalizedEventTimezoneId = eventTimezoneId?.trim();
  final normalizedUserTimezoneId = userTimezoneId?.trim();
  if (normalizedEventTimezoneId == null ||
      normalizedEventTimezoneId.isEmpty ||
      normalizedUserTimezoneId == null ||
      normalizedUserTimezoneId.isEmpty ||
      normalizedEventTimezoneId == normalizedUserTimezoneId) {
    return null;
  }

  return formatEventDateTime(
    instant,
    timezoneId: normalizedUserTimezoneId,
    localeName: localeName,
  );
}

String formatUserMetadataDateTime(
  DateTime instant, {
  required String localeName,
}) {
  return DateFormat.MMMd(localeName).add_Hm().format(instant.toLocal());
}

String formatUtcOffset(Duration offset) {
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours.toString().padLeft(2, '0');
  final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

String buildIcsDateTime(DateTime instant) {
  final utc = instant.toUtc();
  final year = utc.year.toString().padLeft(4, '0');
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  final hour = utc.hour.toString().padLeft(2, '0');
  final minute = utc.minute.toString().padLeft(2, '0');
  final second = utc.second.toString().padLeft(2, '0');
  return '$year$month${day}T$hour$minute${second}Z';
}

String buildIcsLocalDateTime(DateTime instant, String? timezoneId) {
  final zoned = eventDateTime(instant, timezoneId);
  final year = zoned.year.toString().padLeft(4, '0');
  final month = zoned.month.toString().padLeft(2, '0');
  final day = zoned.day.toString().padLeft(2, '0');
  final hour = zoned.hour.toString().padLeft(2, '0');
  final minute = zoned.minute.toString().padLeft(2, '0');
  final second = zoned.second.toString().padLeft(2, '0');
  return '$year$month${day}T$hour$minute$second';
}
