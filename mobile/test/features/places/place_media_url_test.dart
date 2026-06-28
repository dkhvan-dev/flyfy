import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/config/app_config.dart';
import 'package:inflap/features/places/place_ui.dart';
import 'package:inflap/features/places/models/place_vm.dart';

void main() {
  test(
    'place cover media prefers mirrored MinIO files over external placeholders',
    () {
      final place = _placeWithMedia([
        const PlaceMediaVm(
          id: 'external-cover',
          fileId: '00000000-0000-0000-0000-000000000000',
          externalUrl: 'https://cdn.example.com/external.jpg',
          sourceUrl: '',
          credit: '',
          license: '',
          mediaType: 'PHOTO',
          position: 0,
        ),
        const PlaceMediaVm(
          id: 'minio-cover',
          fileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
          externalUrl: '',
          sourceUrl: '',
          credit: '',
          license: '',
          mediaType: 'PHOTO',
          position: 1,
        ),
      ]);

      expect(place.coverMedia?.id, 'minio-cover');
    },
  );

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

  test('builds canonical Wikimedia fallback candidates from source file pages', () {
    const media = PlaceMediaVm(
      id: 'media-1',
      fileId: '',
      externalUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Ascension%20Cathedral,%20Almaty%20(LRM%2020240402%20221113-RR).jpg?width=1400',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Ascension_Cathedral,_Almaty_(LRM_20240402_221113-RR).jpg',
      credit: '',
      license: '',
      mediaType: 'PHOTO',
      position: 0,
    );

    expect(resolvePlaceMediaUrls(media, targetWidth: 620), [
      'https://commons.wikimedia.org/wiki/Special:FilePath/Ascension%20Cathedral,%20Almaty%20(LRM%2020240402%20221113-RR).jpg?width=620',
      'https://commons.wikimedia.org/wiki/Special:FilePath/Ascension_Cathedral,_Almaty_(LRM_20240402_221113-RR).jpg?width=620',
      'https://commons.wikimedia.org/wiki/Special:FilePath/Ascension%20Cathedral,%20Almaty%20(LRM%2020240402%20221113-RR).jpg?width=1400',
    ]);
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

PlaceVm _placeWithMedia(List<PlaceMediaVm> media) {
  return PlaceVm(
    id: 'place-1',
    locale: 'ru',
    defaultLocale: 'ru',
    title: 'Место',
    description: 'Описание',
    countryCode: 'KZ',
    cityId: 'almaty',
    locationSourceUrl: '',
    category: 'PARK',
    priceAmount: 1000,
    priceCurrency: 'KZT',
    rating: 4.6,
    reviewCount: 0,
    source: 'IMPORT',
    status: 'PUBLISHED',
    tags: const [],
    visitInfo: PlaceVisitInfoVm.empty,
    translations: const {},
    media: media,
    author: const PlaceAuthorVm(userId: 'seed-author'),
    createdAt: '2026-06-22T00:00:00Z',
    updatedAt: '2026-06-22T00:00:00Z',
  );
}
