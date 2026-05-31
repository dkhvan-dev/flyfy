import '../../l10n/generated/app_localizations.dart';
import '../attractions/models/attraction_vm.dart';
import 'models/excursion_vm.dart';

String localizedExcursionTitle({
  required String languageCode,
  required ExcursionVm excursion,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _excursionCopyFor(excursion, languageCode)?.title,
    if (_isSameAttraction(excursion, attraction))
      localizedAttractionTitle(
        languageCode: languageCode,
        attraction: attraction,
      ),
    excursion.title,
    excursion.landmarkName,
    fallback,
  ]);
}

String localizedExcursionSummary({
  required String languageCode,
  required ExcursionVm excursion,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _excursionCopyFor(excursion, languageCode)?.summary,
    if (_isSameAttraction(excursion, attraction))
      _localizedAttractionDescription(attraction, languageCode),
    excursion.summary,
    fallback,
  ]);
}

String localizedExcursionDescription({
  required String languageCode,
  required ExcursionVm excursion,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    _excursionCopyFor(excursion, languageCode)?.description,
    if (_isSameAttraction(excursion, attraction))
      _localizedAttractionDescription(attraction, languageCode),
    excursion.description,
    excursion.summary,
    fallback,
  ]);
}

String localizedExcursionLandmarkName({
  required String languageCode,
  required ExcursionVm excursion,
  AttractionVm? attraction,
  String fallback = '',
}) {
  return _firstNonBlank([
    if (_isSameAttraction(excursion, attraction))
      localizedAttractionTitle(
        languageCode: languageCode,
        attraction: attraction,
      ),
    excursion.landmarkName,
    fallback,
  ]);
}

ExcursionLocalizedCopyVm? _excursionCopyFor(
  ExcursionVm excursion,
  String languageCode,
) {
  final normalized = _normalizeLocale(languageCode);
  if (normalized.isEmpty || excursion.translations.isEmpty) return null;
  return excursion.translations[normalized] ??
      excursion.translations[normalized.split('-').first];
}

String localizedAttractionTitle({
  required String languageCode,
  AttractionVm? attraction,
  String fallback = '',
}) {
  if (attraction == null) return fallback.trim();
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
    fallback,
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
        .translations[_normalizeLocale(attraction.defaultLocale)]
        ?.description,
    attraction.description,
  ]);
}

bool _isSameAttraction(ExcursionVm excursion, AttractionVm? attraction) {
  final landmarkId = excursion.landmarkId?.trim();
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

String localizedExcursionLanguageLabel(AppLocalizations l10n, String code) {
  switch (code.trim().toLowerCase()) {
    case 'en':
      return l10n.excursionLanguageEnglish;
    case 'ru':
      return l10n.excursionLanguageRussian;
    case 'kk':
    case 'kz':
      return l10n.excursionLanguageKazakh;
    case 'fr':
      return l10n.excursionLanguageFrench;
    case 'ja':
    case 'jp':
      return l10n.excursionLanguageJapanese;
    case 'de':
      return l10n.excursionLanguageGerman;
    case 'es':
      return l10n.excursionLanguageSpanish;
    case 'tr':
      return l10n.excursionLanguageTurkish;
    default:
      return code.trim().toUpperCase();
  }
}

String formatLocalizedExcursionLanguages(
  AppLocalizations l10n,
  List<String> languageCodes, {
  int? maxItems,
}) {
  final labels = languageCodes
      .map((code) => code.trim())
      .where((code) => code.isNotEmpty)
      .map((code) => localizedExcursionLanguageLabel(l10n, code))
      .toList(growable: false);

  if (labels.isEmpty) return '-';
  final visibleLabels = maxItems == null ? labels : labels.take(maxItems);
  return visibleLabels.join(', ');
}

String localizedExcursionCategoryLabel(
  AppLocalizations l10n,
  String? categorySlug,
) {
  switch (categorySlug?.trim().toLowerCase()) {
    case 'adventure':
      return l10n.createExcursionCategoryAdventure;
    case 'cultural':
    case 'culture':
      return l10n.createExcursionCategoryCultural;
    case 'culinary':
    case 'gourmet':
      return l10n.createExcursionCategoryCulinary;
    case 'market':
      return l10n.attractionFilterCategoryMarket;
    case 'wellness':
      return l10n.createExcursionCategoryWellness;
    default:
      return l10n.serviceExcursions;
  }
}
