import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/core/reference/timezone_filter_utils.dart';

void main() {
  test('resolves localized Almaty location before device timezone fallback',
      () {
    const timezones = [
      ReferenceTimezone(
        id: 'Asia/Dubai',
        name: 'Dubai time',
        utcOffset: '+04:00',
      ),
      ReferenceTimezone(
        id: 'Asia/Almaty',
        name: 'Алматы уақыты',
        utcOffset: '+05:00',
      ),
    ];

    final resolved = resolveReferenceTimezoneForLocation(
      timezones: timezones,
      aliases: timezoneSearchAliasMap(timezones),
      cityName: 'Алматы',
      countryCode: 'KZ',
      deviceTimezoneId: 'Asia/Dubai',
    );

    expect(resolved?.id, 'Asia/Almaty');
  });

  test('formats timezone as localized place and UTC offset', () {
    const timezone = ReferenceTimezone(
      id: 'Asia/Almaty',
      name: 'Алматы',
      utcOffset: '+05:00',
    );

    final label = referenceTimezoneLabel(timezone);

    expect(label, 'Алматы UTC+05:00');
    expect(label, isNot(contains('время')));
  });

  test('compacts legacy localized timezone names from cached API responses',
      () {
    const timezone = ReferenceTimezone(
      id: 'Asia/Dubai',
      name: 'Дубайское время',
      utcOffset: '+04:00',
    );

    final label = referenceTimezoneLabel(timezone, lang: 'ru');

    expect(label, 'Дубай UTC+04:00');
    expect(label, isNot(contains('Дубайское время')));
  });

  test('fallback timezone names stay compact', () {
    final fallback = localizedReferenceTimezoneFallbackName(
      'Asia/Dubai',
      'ru',
    );

    expect(fallback, 'Dubai');
    expect(fallback, isNot(contains('часовой пояс')));
  });
}
