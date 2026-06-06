import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/core/reference/country_filter_utils.dart';
import 'package:inflap/core/reference/timezone_filter_utils.dart';

void main() {
  test(
    'resolves localized Almaty location before device timezone fallback',
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
    },
  );

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

  test(
    'compacts legacy localized timezone names from cached API responses',
    () {
      const timezone = ReferenceTimezone(
        id: 'Asia/Dubai',
        name: 'Дубайское время',
        utcOffset: '+04:00',
      );

      final label = referenceTimezoneLabel(timezone, lang: 'ru');

      expect(label, 'Дубай UTC+04:00');
      expect(label, isNot(contains('Дубайское время')));
    },
  );

  test('fallback timezone names stay compact', () {
    final fallback = localizedReferenceTimezoneFallbackName('Asia/Dubai', 'ru');

    expect(fallback, 'Dubai');
    expect(fallback, isNot(contains('часовой пояс')));
  });

  test('recommends Vietnam timezone by selected country', () {
    const timezones = [
      ReferenceTimezone(
        id: 'Asia/Ho_Chi_Minh',
        name: 'Vietnam, Ho Chi Minh City / Hanoi',
        utcOffset: '+07:00',
      ),
      ReferenceTimezone(id: 'Asia/Almaty', name: 'Almaty', utcOffset: '+05:00'),
    ];

    final recommended = recommendedReferenceTimezonesForCountry(
      timezones: timezones,
      countryCode: 'VN',
    );

    expect(recommended.map((timezone) => timezone.id), ['Asia/Ho_Chi_Minh']);
  });

  test('resolves Vietnam timezone before device timezone fallback', () {
    const timezones = [
      ReferenceTimezone(
        id: 'Asia/Ho_Chi_Minh',
        name: 'Vietnam, Ho Chi Minh City / Hanoi',
        utcOffset: '+07:00',
      ),
      ReferenceTimezone(id: 'Asia/Almaty', name: 'Almaty', utcOffset: '+05:00'),
    ];

    final resolved = resolveReferenceTimezoneForLocation(
      timezones: timezones,
      aliases: timezoneSearchAliasMap(timezones),
      countryCode: 'VN',
      deviceTimezoneId: 'Asia/Almaty',
    );

    expect(resolved?.id, 'Asia/Ho_Chi_Minh');
  });

  test(
    'finds Vietnam timezone by localized aliases and compact UTC offset',
    () {
      const timezone = ReferenceTimezone(
        id: 'Asia/Ho_Chi_Minh',
        name: 'Vietnam, Ho Chi Minh City / Hanoi',
        utcOffset: '+07:00',
      );
      const timezones = [timezone];
      final aliases = timezoneSearchAliasMap(timezones);
      final haystack = timezoneFilterSearchHaystack(timezone, aliases);

      expect(haystack, contains(normalizeCountrySearchText('Вьетнам')));
      expect(haystack, contains(normalizeCountrySearchText('Ханой')));
      expect(haystack, contains(normalizeCountrySearchText('Saigon')));
      expect(haystack, contains(normalizeCountrySearchText('UTC+7')));
    },
  );

  test('formats Vietnam timezone as country-aware localized place', () {
    const timezone = ReferenceTimezone(
      id: 'Asia/Ho_Chi_Minh',
      name: 'Vietnam time',
      utcOffset: '+07:00',
    );

    final label = referenceTimezoneLabel(timezone, lang: 'ru');

    expect(label, 'Вьетнам, Хошимин / Ханой UTC+07:00');
  });
}
