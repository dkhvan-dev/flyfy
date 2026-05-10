import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/config/app_config.dart';
import 'package:superapp/features/tours/models/tour_vm.dart';
import 'package:superapp/features/tours/tour_cover_url.dart';

void main() {
  test('resolves backend relative tour cover urls against api origin', () {
    const tour = TourVm(
      id: 'tour-1',
      title: 'Mountain Tour',
      summary: 'Summary',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      coverFileId: 'file-1',
      coverImageUrl: '/api/v1/tours/tour-1/cover',
    );

    final origin = Uri.parse(AppConfig.apiBaseUrl).origin;

    expect(
      resolveTourCoverUrl(tour),
      '$origin/api/v1/tours/tour-1/cover',
    );
  });

  test('falls back to public file content url when cover image url is absent',
      () {
    const tour = TourVm(
      id: 'tour-1',
      title: 'Mountain Tour',
      summary: 'Summary',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      coverFileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
    );

    expect(
      resolveTourCoverUrl(tour),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });
}
