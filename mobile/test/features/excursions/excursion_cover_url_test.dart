import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/config/app_config.dart';
import 'package:inflap/features/excursions/models/excursion_booking_vm.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';
import 'package:inflap/features/excursions/excursion_cover_url.dart';

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

  test('resolves owned excursion covers from file ids before public routes',
      () {
    const excursion = ExcursionVm(
      id: 'excursion-1',
      title: 'Mountain Excursion',
      summary: 'Summary',
      status: 'PENDING_REVIEW',
      visibility: 'PUBLIC',
      priceAmount: 0,
      currency: 'KZT',
      coverFileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
      coverImageUrl: '/api/v1/excursions/excursion-1/cover',
    );

    expect(
      resolveOwnedExcursionCoverUrl(excursion),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });

  test('resolves guide booking cover file ids for dashboard cards', () {
    final booking = ExcursionBookingVm(
      id: 'booking-1',
      productId: 'product-1',
      offerId: 'offer-1',
      touristUserId: 'tourist-1',
      guideUserId: 'guide-1',
      guideProfileId: 'guide-profile-1',
      guideDisplayName: 'Guide',
      title: 'Mountain route',
      summary: 'Private route',
      scheduledFor: DateTime.utc(2026, 5, 17, 10),
      adults: 2,
      children: 0,
      totalSeats: 2,
      totalPriceAmount: 240,
      currency: 'KZT',
      status: 'CONFIRMED',
      coverFileId: '7ec7955e-0e4e-4a2f-aa31-3e41aa345211',
    );

    expect(
      resolveExcursionBookingCoverUrl(booking),
      '${AppConfig.apiBaseUrl}/public/files/7ec7955e-0e4e-4a2f-aa31-3e41aa345211/content',
    );
  });
}
