import 'models/excursion_vm.dart';

List<ExcursionVm> activeGuideOffers(List<ExcursionVm> items) {
  return _sortedGuideOffers(items.where(isPublishedPublicGuideOffer));
}

List<ExcursionVm> archivedGuideOffers(List<ExcursionVm> items) {
  return _sortedGuideOffers(items.where(isArchivedGuideOffer));
}

List<ExcursionVm> draftGuideOffers(List<ExcursionVm> items) {
  return _sortedGuideOffers(items.where(isDraftGuideOffer));
}

List<ExcursionVm> reviewGuideOffers(List<ExcursionVm> items) {
  return _sortedGuideOffers(items.where(isReviewGuideOffer));
}

List<ExcursionVm> rejectedGuideOffers(List<ExcursionVm> items) {
  return _sortedGuideOffers(items.where(isRejectedGuideOffer));
}

bool isPublishedPublicGuideOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'PUBLISHED' &&
      excursion.visibility.trim().toUpperCase() == 'PUBLIC';
}

bool isArchivedGuideOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'ARCHIVED';
}

bool isDraftGuideOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'DRAFT';
}

bool isReviewGuideOffer(ExcursionVm excursion) {
  final status = excursion.status.trim().toUpperCase();
  if (status.isEmpty) return false;
  if (isPublishedPublicGuideOffer(excursion) ||
      isDraftGuideOffer(excursion) ||
      isArchivedGuideOffer(excursion) ||
      isRejectedGuideOffer(excursion) ||
      isCancelledGuideOffer(excursion)) {
    return false;
  }
  return status.contains('REVIEW') ||
      status.contains('MODERAT') ||
      status == 'PENDING';
}

bool isRejectedGuideOffer(ExcursionVm excursion) {
  final status = excursion.status.trim().toUpperCase();
  return status.contains('REJECT') || status.contains('DECLIN');
}

bool isCancelledGuideOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase().contains('CANCEL');
}

String editableGuideExcursionId(ExcursionVm excursion) {
  final legacyId = excursion.primaryOffer?.legacyExcursionId?.trim() ?? '';
  if (legacyId.isNotEmpty) return legacyId;
  return excursion.id.trim();
}

List<ExcursionVm> _sortedGuideOffers(Iterable<ExcursionVm> items) {
  final result = items.toList(growable: false);
  result.sort((a, b) => _createdAtOrEpoch(b).compareTo(_createdAtOrEpoch(a)));
  return result;
}

DateTime _createdAtOrEpoch(ExcursionVm excursion) {
  return excursion.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}
