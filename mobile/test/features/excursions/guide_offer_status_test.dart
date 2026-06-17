import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/excursions/guide_offer_status.dart';
import 'package:inflap/features/excursions/models/excursion_vm.dart';

void main() {
  test('groups guide offers by publishing status and sorts newest first', () {
    final items = [
      _offer('old-draft', 'DRAFT', createdAt: DateTime.utc(2026, 1, 1)),
      _offer('active', 'PUBLISHED', visibility: 'PUBLIC'),
      _offer('archived', 'ARCHIVED'),
      _offer('pending', 'PENDING_REVIEW', createdAt: DateTime.utc(2026, 1, 15)),
      _offer(
        'moderation',
        'IN_MODERATION',
        createdAt: DateTime.utc(2026, 1, 20),
      ),
      _offer('rejected', 'REJECTED'),
      _offer('new-draft', 'DRAFT', createdAt: DateTime.utc(2026, 2, 1)),
    ];

    expect(activeGuideOffers(items).map((item) => item.id), ['active']);
    expect(draftGuideOffers(items).map((item) => item.id), [
      'new-draft',
      'old-draft',
    ]);
    expect(reviewGuideOffers(items).map((item) => item.id), [
      'moderation',
      'pending',
    ]);
    expect(archivedGuideOffers(items).map((item) => item.id), ['archived']);
    expect(rejectedGuideOffers(items).map((item) => item.id), ['rejected']);
  });

  test('editable guide excursion id prefers legacy offer id', () {
    const excursion = ExcursionVm(
      id: 'product-id',
      title: 'Charyn Canyon',
      summary: 'Draft offer',
      status: 'DRAFT',
      visibility: 'PRIVATE',
      priceAmount: 0,
      currency: 'KZT',
      offers: [
        ExcursionOfferVm(
          id: 'offer-id',
          productId: 'product-id',
          legacyExcursionId: 'legacy-offer-id',
          guideProfileId: 'guide-profile-id',
          guideUserId: 'guide-user-id',
          status: 'DRAFT',
          visibility: 'PRIVATE',
          durationMinutes: 120,
          maxGroupSize: 4,
          meetingPoint: 'Entrance',
          priceAmount: 10000,
          currency: 'KZT',
        ),
      ],
    );

    expect(editableGuideExcursionId(excursion), 'legacy-offer-id');
  });
}

ExcursionVm _offer(
  String id,
  String status, {
  String visibility = 'PRIVATE',
  DateTime? createdAt,
}) {
  return ExcursionVm(
    id: id,
    title: id,
    summary: 'Guide offer',
    status: status,
    visibility: visibility,
    priceAmount: 10000,
    currency: 'KZT',
    createdAt: createdAt,
  );
}
