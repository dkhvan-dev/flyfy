import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/shared/map/app_map_link_resolver.dart';

void main() {
  const latitude = 43.250784;
  const longitude = 76.901190;

  test(
    'resolves Google Maps short links through an allowlisted redirect',
    () async {
      final resolver = AppMapLinkResolver(
        expandShortLink: (uri) async {
          expect(uri.host, 'maps.app.goo.gl');
          return Uri.parse(
            'https://www.google.com/maps/search/43.250784,+76.901190?entry=tts',
          );
        },
      );

      final point = await resolver.resolveCoordinates(
        'https://maps.app.goo.gl/o89UnzWr89XkcnUH8',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
    },
  );

  test(
    'resolves pasted Google Maps text by trimming everything before http',
    () async {
      final resolver = AppMapLinkResolver(
        expandShortLink: (uri) async {
          expect(uri.host, 'maps.app.goo.gl');
          return Uri.parse(
            'https://www.google.com/maps/search/43.250784,+76.901190?entry=tts',
          );
        },
      );

      final point = await resolver.resolveCoordinates(
        'Открыть на карте: https://maps.app.goo.gl/o89UnzWr89XkcnUH8',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
    },
  );

  test('resolves Google Maps short links from page bootstrap data', () async {
    final resolver = AppMapLinkResolver(
      expandShortLink: (uri) async {
        expect(uri.host, 'maps.app.goo.gl');
        return Uri.parse(
          'https://www.google.com/maps?q=Crystal+Talent+Appraisal&ftid=0x3883694e9555cdc7:0xb10bcd1b0e18ec4d',
        );
      },
      loadMapPage: (uri) async {
        expect(uri.host, 'www.google.com');
        return r'''
          <script>
            window.APP_OPTIONS=[
              "kz",
              [[23249.75806995484,76.901190,43.250784],[0,0,0],[1024,768],13.1],
              "place"
            ];
          </script>
        ''';
      },
    );

    final point = await resolver.resolveCoordinates(
      'https://maps.app.goo.gl/Cb4k8jRaCBGaNW6s7?g_st=ic',
    );

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(latitude, 0.000001));
    expect(point.longitude, closeTo(longitude, 0.000001));
  });

  test(
    'resolves encoded Google Maps page data with malformed percents',
    () async {
      final resolver = AppMapLinkResolver(
        expandShortLink: (_) async =>
            Uri.parse('https://www.google.com/maps?q=Crystal+Talent+Appraisal'),
        loadMapPage: (_) async =>
            '<html>100% ready <a href="/maps?pb=%211m3%212d76.901190%213d43.250784">map</a></html>',
      );

      final point = await resolver.resolveCoordinates(
        'https://maps.app.goo.gl/Cb4k8jRaCBGaNW6s7?g_st=ic',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
    },
  );

  test(
    'expands Google Maps short links without a browser user agent',
    () async {
      late _RecordingHttpClient client;

      final point = await HttpOverrides.runZoned(
        () => const AppMapLinkResolver().resolveCoordinates(
          'https://maps.app.goo.gl/Cb4k8jRaCBGaNW6s7?g_st=ic',
        ),
        createHttpClient: (_) {
          client = _RecordingHttpClient(
            response: _FakeHttpClientResponse(
              statusCode: HttpStatus.found,
              location:
                  'https://www.google.com/maps/search/43.250784,+76.901190',
            ),
          );
          return client;
        },
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
      expect(client.requests, hasLength(1));
      expect(
        client.requests.single.headers.value(HttpHeaders.userAgentHeader),
        isNull,
      );
    },
  );

  test('resolves 2GIS short links through an allowlisted redirect', () async {
    final resolver = AppMapLinkResolver(
      expandShortLink: (uri) async {
        expect(uri.host, 'go.2gis.com');
        return Uri.parse(
          'https://2gis.kz/almaty/geo/70030076169750575/76.901190,43.250784?m=76.902211,43.242839/16',
        );
      },
    );

    final point = await resolver.resolveCoordinates(
      'https://go.2gis.com/CqOPe',
    );

    expect(point, isNotNull);
    expect(point!.latitude, closeTo(latitude, 0.000001));
    expect(point.longitude, closeTo(longitude, 0.000001));
  });

  test(
    'resolves direct 2GIS object pages when page data has coordinates',
    () async {
      final resolver = AppMapLinkResolver(
        loadMapPage: (uri) async {
          expect(uri.host, '2gis.kz');
          return r'''
          <script>
            window.__OBJECT__={
              "id":"70000001091302735",
              "point":{"lon":76.901190,"lat":43.250784}
            };
          </script>
        ''';
        },
      );

      final point = await resolver.resolveCoordinates(
        'https://2gis.kz/almaty/geo/70000001091302735',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
    },
  );

  test(
    'prioritizes 2GIS object coordinates over generic page coordinate pairs',
    () async {
      final resolver = AppMapLinkResolver(
        loadMapPage: (uri) async {
          expect(uri.host, '2gis.kz');
          return r'''
          <script>
            window.__BOOTSTRAP__={
              "canonical":"https://2gis.kz/almaty?m=0,0/13",
              "object":{
                "id":"70000001091302735",
                "point":{"lon":76.901190,"lat":43.250784}
              }
            };
          </script>
        ''';
        },
      );

      final point = await resolver.resolveCoordinates(
        'https://2gis.kz/almaty/geo/70000001091302735',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(latitude, 0.000001));
      expect(point.longitude, closeTo(longitude, 0.000001));
    },
  );

  test('does not resolve arbitrary short links', () async {
    var called = false;
    final resolver = AppMapLinkResolver(
      expandShortLink: (_) async {
        called = true;
        return Uri.parse(
          'https://www.google.com/maps/search/$latitude,$longitude',
        );
      },
    );

    final point = await resolver.resolveCoordinates('https://short.test/place');

    expect(point, isNull);
    expect(called, isFalse);
  });
}

final class _RecordingHttpClient implements HttpClient {
  _RecordingHttpClient({required this.response});

  final _FakeHttpClientResponse response;
  final requests = <_RecordingHttpClientRequest>[];

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = _RecordingHttpClientRequest(url: url, response: response);
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingHttpClientRequest implements HttpClientRequest {
  _RecordingHttpClientRequest({required this.url, required this.response});

  final Uri url;
  final _FakeHttpClientResponse response;

  @override
  final _RecordingHttpHeaders headers = _RecordingHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeHttpClientResponse implements HttpClientResponse {
  _FakeHttpClientResponse({required this.statusCode, String? location})
    : headers = _RecordingHttpHeaders() {
    if (location != null) {
      headers.set(HttpHeaders.locationHeader, location);
    }
  }

  @override
  final int statusCode;

  @override
  final _RecordingHttpHeaders headers;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[_normalize(name)] = <String>[value.toString()];
  }

  @override
  String? value(String name) => _values[_normalize(name)]?.join(',');

  String _normalize(String name) => name.toLowerCase();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
