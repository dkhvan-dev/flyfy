import '../../l10n/generated/app_localizations.dart';

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
