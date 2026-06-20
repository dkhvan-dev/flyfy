import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/config/app_config.dart';
import 'package:inflap/features/places/place_ui.dart';
import 'package:inflap/features/places/models/place_vm.dart';

void main() {
  test('resolves place media file ids through public file content route', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
      externalUrl: 'https://cdn.example.com/fallback.jpg',
      sourceUrl: '',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(
      resolvePlaceMediaUrl(media),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });

  test('falls back to external place media urls for imported content', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '00000000-0000-0000-0000-000000000000',
      externalUrl: 'https://upload.wikimedia.org/example.jpg',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Example.jpg',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(
      resolvePlaceMediaUrl(media),
      'https://upload.wikimedia.org/example.jpg',
    );
  });

  test('requests Wikimedia external media at the target display width', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20City%20Square.JPG?width=1400',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Da_Nang_City_Square.JPG',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(
      resolvePlaceMediaUrl(media, targetWidth: 620),
      'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20City%20Square.JPG?width=620',
    );
  });

  test('uses a compact Wikimedia thumbnail when target width is omitted', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Toompea_Castle.jpg?width=1400',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Toompea_Castle.jpg',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(
      resolvePlaceMediaUrl(media),
      'https://commons.wikimedia.org/wiki/Special:FilePath/Toompea_Castle.jpg?width=480',
    );
  });

  test('requests Wikimedia thumbnail URLs at the target display width', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg/3840px-Golden_Bridge_at_Ba_Na_Hills_20250718.jpg',
      sourceUrl: 'https://en.wikipedia.org/wiki/Golden_Bridge_(Vietnam)',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(
      resolvePlaceMediaUrl(media, targetWidth: 720),
      'https://commons.wikimedia.org/wiki/Special:FilePath/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg?width=720',
    );
  });

  test('ignores unsafe external place media urls', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl: 'javascript:alert(1)',
      sourceUrl: '',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(resolvePlaceMediaUrl(media), isNull);
  });
}
