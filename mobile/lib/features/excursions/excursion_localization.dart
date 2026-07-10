import '../../l10n/generated/app_localizations.dart';
import '../places/models/place_vm.dart';
import 'models/excursion_vm.dart';

String localizedExcursionTitle({
  required String languageCode,
  required ExcursionVm excursion,
  PlaceVm? place,
  Map<String, PlaceVm> placesById = const {},
  String fallback = '',
}) {
  return _firstNonBlank([
    _localizedCombinedRouteTitle(
      languageCode: languageCode,
      excursion: excursion,
      placesById: placesById,
    ),
    if (_isSamePlace(excursion, place))
      localizedPlaceTitle(languageCode: languageCode, place: place),
    _excursionCopyFor(excursion, languageCode)?.title,
    excursion.title,
    excursion.landmarkName,
    fallback,
  ]);
}

String _localizedCombinedRouteTitle({
  required String languageCode,
  required ExcursionVm excursion,
  required Map<String, PlaceVm> placesById,
}) {
  if (excursion.routeKind.trim().toUpperCase() != 'COMBINED_ROUTE') {
    return '';
  }

  final placeIds = <String>[];
  final seen = <String>{};
  for (final value in excursion.placeIds) {
    final placeId = value.trim();
    if (placeId.isNotEmpty && seen.add(placeId)) {
      placeIds.add(placeId);
    }
  }
  if (placeIds.length < 2) return '';

  final titles = <String>[];
  for (final placeId in placeIds) {
    final place = placesById[placeId];
    if (place == null) return '';

    final title = localizedPlaceTitle(languageCode: languageCode, place: place);
    if (title.isEmpty) return '';
    titles.add(title);
  }
  return titles.join(' + ');
}

String localizedExcursionSummary({
  required String languageCode,
  required ExcursionVm excursion,
  PlaceVm? place,
  String fallback = '',
}) {
  return _firstNonBlank([
    if (_isSamePlace(excursion, place))
      _localizedPlaceDescription(place, languageCode),
    _excursionCopyFor(excursion, languageCode)?.summary,
    excursion.summary,
    fallback,
  ]);
}

String localizedExcursionDescription({
  required String languageCode,
  required ExcursionVm excursion,
  PlaceVm? place,
  String fallback = '',
}) {
  return _firstNonBlank([
    if (_isSamePlace(excursion, place))
      _localizedPlaceDescription(place, languageCode),
    _excursionCopyFor(excursion, languageCode)?.description,
    excursion.description,
    excursion.summary,
    fallback,
  ]);
}

String localizedExcursionLandmarkName({
  required String languageCode,
  required ExcursionVm excursion,
  PlaceVm? place,
  String fallback = '',
}) {
  return _firstNonBlank([
    if (_isSamePlace(excursion, place))
      localizedPlaceTitle(languageCode: languageCode, place: place),
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

String localizedPlaceTitle({
  required String languageCode,
  PlaceVm? place,
  String fallback = '',
}) {
  if (place == null) return fallback.trim();
  final normalized = _normalizeLocale(languageCode);
  final requested = place.translations[normalized]?.title;
  final requestedLanguage =
      place.translations[normalized.split('-').first]?.title;

  return _firstNonBlank([
    requested,
    requestedLanguage,
    if (_normalizeLocale(place.locale) == normalized) place.title,
    if (_normalizeLocale(place.locale) == normalized.split('-').first)
      place.title,
    place.translations[_normalizeLocale(place.defaultLocale)]?.title,
    place.title,
    fallback,
  ]);
}

String _localizedPlaceDescription(PlaceVm? place, String languageCode) {
  if (place == null) return '';
  final normalized = _normalizeLocale(languageCode);
  final requested = place.translations[normalized]?.description;
  final requestedLanguage =
      place.translations[normalized.split('-').first]?.description;

  return _firstNonBlank([
    requested,
    requestedLanguage,
    if (_normalizeLocale(place.locale) == normalized) place.description,
    if (_normalizeLocale(place.locale) == normalized.split('-').first)
      place.description,
    place.translations[_normalizeLocale(place.defaultLocale)]?.description,
    place.description,
  ]);
}

bool _isSamePlace(ExcursionVm excursion, PlaceVm? place) {
  final landmarkId = excursion.landmarkId?.trim();
  if (landmarkId == null || landmarkId.isEmpty || place == null) {
    return false;
  }
  return landmarkId == place.id.trim();
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

String localizedExcursionTranslationSourceLanguageLabel(
  AppLocalizations l10n,
  String code,
) {
  switch (code.trim().toLowerCase()) {
    case 'en':
      return l10n.excursionTranslationSourceLanguageEnglish;
    case 'ru':
      return l10n.excursionTranslationSourceLanguageRussian;
    case 'kk':
    case 'kz':
      return l10n.excursionTranslationSourceLanguageKazakh;
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
      return l10n.placeFilterCategoryMarket;
    case 'wellness':
      return l10n.createExcursionCategoryWellness;
    default:
      return l10n.serviceExcursions;
  }
}
