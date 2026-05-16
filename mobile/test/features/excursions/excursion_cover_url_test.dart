import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/config/app_config.dart';
import 'package:superapp/features/excursions/models/excursion_vm.dart';
import 'package:superapp/features/excursions/excursion_cover_url.dart';

void main() {
  test('resolves backend relative excursion cover urls against api origin', () {
    const excursion = ExcursionVm(
      id: 'excursion-1',
      title: 'Mountain Excursion',
      summary: 'Summary',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      coverFileId: 'file-1',
      coverImageUrl: '/api/v1/excursions/excursion-1/cover',
    );

    final origin = Uri.parse(AppConfig.apiBaseUrl).origin;

    expect(
      resolveExcursionCoverUrl(excursion),
      '$origin/api/v1/excursions/excursion-1/cover',
    );
  });

  test('falls back to public file content url when cover image url is absent',
      () {
    const excursion = ExcursionVm(
      id: 'excursion-1',
      title: 'Mountain Excursion',
      summary: 'Summary',
      status: 'PUBLISHED',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      coverFileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
    );

    expect(
      resolveExcursionCoverUrl(excursion),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });
}
