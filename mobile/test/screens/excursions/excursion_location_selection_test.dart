import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/attractions/models/attraction_vm.dart';
import 'package:inflap/screens/excursions/excursion_select_location_screen.dart';

void main() {
  test('selection keeps localized filter city name for excursion payload', () {
    final selection = ExcursionLocationSelection.fromAttraction(
      _attraction(cityId: 'da-nang'),
      fallbackCityName: 'Дананг',
    );

    expect(selection.cityId, 'da-nang');
    expect(selection.cityName, 'Дананг');
  });

  test(
    'selection falls back to attraction city id when city name is missing',
    () {
      final selection = ExcursionLocationSelection.fromAttraction(
        _attraction(cityId: 'da-nang'),
      );

      expect(selection.cityId, 'da-nang');
      expect(selection.cityName, 'da-nang');
    },
  );

  test(
    'selection keeps external cover when imported media has no file mirror',
    () {
      final selection = ExcursionLocationSelection.fromAttraction(
        _attraction(
          cityId: 'da-nang',
          media: const [
            AttractionMediaVm(
              id: 'media-id',
              fileId: '00000000-0000-0000-0000-000000000000',
              externalUrl: 'https://upload.wikimedia.org/dragon-bridge.jpg',
              sourceUrl: '',
              credit: '',
              license: '',
              mediaType: 'PHOTO',
              position: 0,
            ),
          ],
        ),
      );

      expect(selection.coverFileId, isNull);
      expect(
        selection.coverImageUrl,
        'https://upload.wikimedia.org/dragon-bridge.jpg',
      );
    },
  );
}

AttractionVm _attraction({
  required String cityId,
  List<AttractionMediaVm> media = const [],
}) {
  return AttractionVm(
    id: '5841aaeb-c597-4b89-992d-26a844dd2054',
    locale: 'en',
    defaultLocale: 'en',
    title: 'Dragon Bridge',
    description: 'A modern bridge across the Han River.',
    countryCode: 'VN',
    cityId: cityId,
    latitude: 16.0617,
    longitude: 108.2278,
    locationSourceUrl: 'https://maps.example.test/dragon-bridge',
    category: 'architecture',
    rating: 4.8,
    reviewCount: 120,
    source: 'IMPORT',
    status: 'PUBLISHED',
    tags: const [],
    visitInfo: AttractionVisitInfoVm.empty,
    translations: const {},
    media: media,
    author: const AttractionAuthorVm(userId: ''),
    createdAt: '2026-05-27T00:00:00Z',
    updatedAt: '2026-05-27T00:00:00Z',
  );
}
