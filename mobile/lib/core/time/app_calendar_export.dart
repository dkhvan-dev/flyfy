import 'app_time.dart';

class CalendarExportEvent {
  const CalendarExportEvent({
    required this.uid,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.timezoneId,
    this.description,
    this.location,
    this.generatedAt,
  });

  final String uid;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String timezoneId;
  final String? description;
  final String? location;
  final DateTime? generatedAt;
}

String buildCalendarEventIcs(CalendarExportEvent event) {
  final timezoneId = event.timezoneId.trim().isEmpty
      ? 'UTC'
      : event.timezoneId.trim();
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Inflap//Inflap Calendar//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-WR-TIMEZONE:$timezoneId',
    'BEGIN:VEVENT',
    'UID:${_escapeIcsText(event.uid)}',
    'DTSTAMP:${buildIcsDateTime(event.generatedAt ?? DateTime.now().toUtc())}',
    'DTSTART;TZID=$timezoneId:${buildIcsLocalDateTime(event.startAt, timezoneId)}',
    'DTEND;TZID=$timezoneId:${buildIcsLocalDateTime(event.endAt, timezoneId)}',
    'SUMMARY:${_escapeIcsText(event.title)}',
  ];

  final description = event.description?.trim();
  if (description != null && description.isNotEmpty) {
    lines.add('DESCRIPTION:${_escapeIcsText(description)}');
  }

  final location = event.location?.trim();
  if (location != null && location.isNotEmpty) {
    lines.add('LOCATION:${_escapeIcsText(location)}');
  }

  lines
    ..add('END:VEVENT')
    ..add('END:VCALENDAR');

  return '${lines.join('\r\n')}\r\n';
}

String _escapeIcsText(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\n');
}
