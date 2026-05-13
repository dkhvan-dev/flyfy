import '../../l10n/generated/app_localizations.dart';
import '../attractions/models/attraction_vm.dart';
import 'models/tour_vm.dart';

String localizedTourTitle({
  required String languageCode,
  required TourVm tour,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _tourCopyFor(tour, languageCode)?.title,
    if (_isSameAttraction(tour, attraction))
      _localizedAttractionTitle(attraction, languageCode),
    tour.title,
    tour.landmarkName,
    fallback,
  ]);
}

String localizedTourSummary({
  required String languageCode,
  required TourVm tour,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _tourCopyFor(tour, languageCode)?.summary,
    if (_isSameAttraction(tour, attraction))
      _localizedAttractionDescription(attraction, languageCode),
    tour.summary,
    fallback,
  ]);
}

String localizedTourDescription({
  required String languageCode,
  required TourVm tour,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _tourCopyFor(tour, languageCode)?.description,
    if (_isSameAttraction(tour, attraction))
      _localizedAttractionDescription(attraction, languageCode),
    tour.description,
    tour.summary,
    fallback,
  ]);
}

String localizedTourLandmarkName({
  required String languageCode,
  required TourVm tour,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    if (_isSameAttraction(tour, attraction))
      _localizedAttractionTitle(attraction, languageCode),
    tour.landmarkName,
    fallback,
  ]);
}

TourLocalizedCopyVm? _tourCopyFor(TourVm tour, String languageCode) {
  final normalized = _normalizeLocale(languageCode);
  if (normalized.isEmpty || tour.translations.isEmpty) return null;
  return tour.translations[normalized] ??
      tour.translations[normalized.split('-').first];
}

String _localizedAttractionTitle(
  AttractionVm? attraction,
  String languageCode,
) {
  if (attraction == null) return '';
  final normalized = _normalizeLocale(languageCode);
  final requested = attraction.translations[normalized]?.title;
  final requestedLanguage =
      attraction.translations[normalized.split('-').first]?.title;

  return _firstNonBlank([
    requested,
    requestedLanguage,
    if (_normalizeLocale(attraction.locale) == normalized) attraction.title,
    if (_normalizeLocale(attraction.locale) == normalized.split('-').first)
      attraction.title,
    attraction.translations[_normalizeLocale(attraction.defaultLocale)]?.title,
    attraction.title,
  ]);
}

String _localizedAttractionDescription(
  AttractionVm? attraction,
  String languageCode,
) {
  if (attraction == null) return '';
  final normalized = _normalizeLocale(languageCode);
  final requested = attraction.translations[normalized]?.description;
  final requestedLanguage =
      attraction.translations[normalized.split('-').first]?.description;

  return _firstNonBlank([
    requested,
    requestedLanguage,
    if (_normalizeLocale(attraction.locale) == normalized)
      attraction.description,
    if (_normalizeLocale(attraction.locale) == normalized.split('-').first)
      attraction.description,
    attraction
        .translations[_normalizeLocale(attraction.defaultLocale)]?.description,
    attraction.description,
  ]);
}

bool _isSameAttraction(TourVm tour, AttractionVm? attraction) {
  final landmarkId = tour.landmarkId?.trim();
  if (landmarkId == null || landmarkId.isEmpty || attraction == null) {
    return false;
  }
  return landmarkId == attraction.id.trim();
}

String _normalizeLocale(String value) {
  return value.trim().replaceAll('_', '-').toLowerCase();
}

String _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String localizedTourLanguageLabel(AppLocalizations l10n, String code) {
  switch (code.trim().toLowerCase()) {
    case 'en':
      return l10n.tourLanguageEnglish;
    case 'ru':
      return l10n.tourLanguageRussian;
    case 'kk':
    case 'kz':
      return l10n.tourLanguageKazakh;
    case 'fr':
      return l10n.tourLanguageFrench;
    case 'ja':
    case 'jp':
      return l10n.tourLanguageJapanese;
    case 'de':
      return l10n.tourLanguageGerman;
    case 'es':
      return l10n.tourLanguageSpanish;
    case 'tr':
      return l10n.tourLanguageTurkish;
    default:
      return code.trim().toUpperCase();
  }
}

String formatLocalizedTourLanguages(
  AppLocalizations l10n,
  List<String> languageCodes, {
  int maxItems = 2,
}) {
  final labels = languageCodes
      .map((code) => code.trim())
      .where((code) => code.isNotEmpty)
      .map((code) => localizedTourLanguageLabel(l10n, code))
      .toList(growable: false);

  if (labels.isEmpty) return '-';
  return labels.take(maxItems).join(', ');
}

String localizedTourCategoryLabel(AppLocalizations l10n, String? categorySlug) {
  switch (categorySlug?.trim().toLowerCase()) {
    case 'adventure':
      return l10n.createTourCategoryAdventure;
    case 'cultural':
    case 'culture':
      return l10n.createTourCategoryCultural;
    case 'culinary':
    case 'gourmet':
      return l10n.createTourCategoryCulinary;
    case 'wellness':
      return l10n.createTourCategoryWellness;
    default:
      return l10n.serviceTours;
  }
}
