import '../../l10n/generated/app_localizations.dart';
import '../excursions/excursion_localization.dart';
import 'models/public_guide_vm.dart';

String localizedGuideLanguageLabel(AppLocalizations l10n, String code) {
  return localizedExcursionLanguageLabel(l10n, code);
}

String localizedGuideSpecializationLabel(
  AppLocalizations l10n,
  String code,
) {
  final normalized = code.trim().toLowerCase().replaceAll('-', '_');
  switch (normalized) {
    case 'mountain':
    case 'mountain_guide':
    case 'alpine':
    case 'adventure':
      return l10n.guidesSpecialtyMountainGuide;
    case 'city':
    case 'city_guide':
    case 'city_historian':
    case 'historian':
    case 'history':
      return l10n.guidesSpecialtyCityHistorian;
    case 'culinary':
    case 'culinary_expert':
    case 'food':
    case 'gourmet':
      return l10n.guidesSpecialtyCulinaryExpert;
    case 'nature':
    case 'nature_photographer':
    case 'photographer':
      return l10n.guidesSpecialtyNaturePhotographer;
    default:
      return _humanizeCode(code);
  }
}

String guideRoleLabel(AppLocalizations l10n, PublicGuideVm guide) {
  final headline = guide.headline.trim();
  if (headline.isNotEmpty) return headline;

  if (guide.specializationCodes.isNotEmpty) {
    return localizedGuideSpecializationLabel(
      l10n,
      guide.specializationCodes.first,
    );
  }

  return l10n.guidesRoleLocalExpert;
}

String guideExcursionLanguageLabel(AppLocalizations l10n, PublicGuideVm guide) {
  final labels = <String>[];
  final seenCodes = <String>{};

  for (final rawCode in guide.excursionLanguageCodes) {
    final code = rawCode.trim().toLowerCase();
    if (code.isEmpty || !seenCodes.add(code)) continue;
    labels.add(localizedGuideLanguageLabel(l10n, code));
  }

  return labels.join(', ');
}

List<String> guideServiceLabels(AppLocalizations l10n, PublicGuideVm guide) {
  return [
    if (guide.isPrivateGuideAvailable) l10n.guidesFilterPrivateExcursions,
    if (guide.isActivityHostAvailable) l10n.guidesFilterActivities,
    if (guide.isExcursionGuideAvailable) l10n.guidesFilterExcursions,
  ];
}

String _humanizeCode(String code) {
  final words = code
      .trim()
      .replaceAll('-', '_')
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) {
    if (word.length == 1) return word.toUpperCase();
    return '${word.substring(0, 1).toUpperCase()}${word.substring(1)}';
  });
  final label = words.join(' ');
  return label.isEmpty ? code.trim().toUpperCase() : label;
}
