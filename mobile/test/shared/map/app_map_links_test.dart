import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/shared/map/app_map_links.dart';

void main() {
  const latitude = 43.238949;
  const longitude = 76.889709;

  void expectPoint(String value) {
    final point = AppMapLinks.tryParseCoordinates(value);
    expect(point, isNotNull);
    expect(point!.latitude, closeTo(latitude, 0.000001));
    expect(point.longitude, closeTo(longitude, 0.000001));
  }

  test('parses app and common map links with explicit coordinates', () {
    expectPoint('https://inflap.app/map?lat=43.238949&lon=76.889709');
    expectPoint(
      'Адрес встречи: https://inflap.app/map?lat=43.238949&lon=76.889709',
    );
    expectPoint('https://www.openstreetmap.org/#map=17/43.238949/76.889709');
    expectPoint('https://maps.google.com/?q=43.238949,76.889709');
    expectPoint('https://www.google.com/maps/search/43.238949,+76.889709');
    expectPoint(
      'https://www.google.com/maps?pb=!1m18!1m12!1m3!1d1234!2d76.889709!3d43.238949',
    );
    expectPoint(
      'https://www.google.com/maps/place/Medeu/@43.238949,76.889709,17z',
    );
    expectPoint('https://maps.apple.com/?ll=43.238949,76.889709');
    expectPoint('https://yandex.kz/maps/?ll=76.889709%2C43.238949&z=16');
    expectPoint('https://yandex.kz/maps/?pt=76.889709,43.238949&z=16');
    expectPoint(
      'https://2gis.kz/almaty/geo/76.889709%2C43.238949?m=76.889709%2C43.238949%2F16',
    );
    expectPoint('https://2gis.kz/almaty/geo/76.889709%2C43.238949');
    expectPoint(
      'https://yandex.kz/maps/?whatshere%5Bpoint%5D=76.889709%2C43.238949&whatshere%5Bzoom%5D=16',
    );
    expectPoint('https://maps.apple.com/?daddr=43.238949,76.889709');
    expectPoint('43.238949, 76.889709');
  });

  test('normalizes pasted text by trimming everything before http', () {
    expect(
      AppMapLinks.normalizePastedMapLink(
        'Откройте карту: https://maps.app.goo.gl/Cb4k8jRaCBGaNW6s7?g_st=ic',
      ),
      'https://maps.app.goo.gl/Cb4k8jRaCBGaNW6s7?g_st=ic',
    );
    expect(
      AppMapLinks.normalizePastedMapLink('  HTTPS://maps.google.com/?q=1,2'),
      'HTTPS://maps.google.com/?q=1,2',
    );
    expect(
      AppMapLinks.normalizePastedMapLink('координаты 43.238949,76.889709'),
      'координаты 43.238949,76.889709',
    );
  });

  test(
    'does not guess coordinates from short links without explicit values',
    () {
      expect(
        AppMapLinks.tryParseCoordinates('https://maps.app.goo.gl/example'),
        isNull,
      );
      expect(
        AppMapLinks.tryParseCoordinates('https://go.2gis.com/example'),
        isNull,
      );
    },
  );

  test('prefers 2GIS geo object coordinates over viewport center', () {
    final point = AppMapLinks.tryParseCoordinates(
      'https://2gis.kz/almaty/geo/70030076169750575/76.902211,43.242839?m=76.910701,43.236941/14.5',
    );

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(43.242839, 0.000001));
    expect(point.longitude, closeTo(76.902211, 0.000001));
  });

  test('does not throw on text with malformed percent encoding', () {
    expect(
      () => AppMapLinks.tryParseCoordinates('<html>100% ready %ZZ</html>'),
      returnsNormally,
    );
    expect(
      AppMapLinks.tryParseCoordinates('<html>100% ready %ZZ</html>'),
      isNull,
    );
  });

  test('parses encoded Google data when surrounding text has bad percents', () {
    final point = AppMapLinks.tryParseCoordinates(
      '<html>100% ready <a href="/maps?pb=%211m3%212d76.889709%213d43.238949">map</a></html>',
    );

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(latitude, 0.000001));
    expect(point.longitude, closeTo(longitude, 0.000001));
  });
}
