import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/config/app_config.dart';
import 'package:superapp/features/attractions/attraction_ui.dart';
import 'package:superapp/features/attractions/models/attraction_vm.dart';

void main() {
  test('resolves attraction media file ids through public file content route',
      () {
    const media = AttractionMediaVm(
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
      resolveAttractionMediaUrl(media),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });

  test('falls back to external attraction media urls for imported content', () {
    const media = AttractionMediaVm(
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
      resolveAttractionMediaUrl(media),
      'https://upload.wikimedia.org/example.jpg',
    );
  });

  test('requests Wikimedia external media at the target display width', () {
    const media = AttractionMediaVm(
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
      resolveAttractionMediaUrl(media, targetWidth: 620),
      'https://commons.wikimedia.org/wiki/Special:FilePath/Da%20Nang%20City%20Square.JPG?width=620',
    );
  });

  test('requests Wikimedia thumbnail URLs at the target display width', () {
    const media = AttractionMediaVm(
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
      resolveAttractionMediaUrl(media, targetWidth: 720),
      'https://commons.wikimedia.org/wiki/Special:FilePath/Golden_Bridge_at_Ba_Na_Hills_20250718.jpg?width=720',
    );
  });

  test('ignores unsafe external attraction media urls', () {
    const media = AttractionMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl: 'javascript:alert(1)',
      sourceUrl: '',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(resolveAttractionMediaUrl(media), isNull);
  });
}
