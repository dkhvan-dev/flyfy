import '../../../l10n/generated/app_localizations.dart';
import '../models/feed_block_vm.dart';

const feedCommunityTopicFilterValues = <String>[
  '',
  'LANGUAGES',
  'HOUSING',
  'TRANSPORT',
  'SPORTS',
  'OUTDOOR',
  'HOBBIES',
  'WELLNESS',
  'PETS',
  'CITY_LIFE',
  'CONTENT',
  'FAMILY',
  'GENERAL',
];

String feedCommunityDisplayTitle(
  FeedCommunityVm community, [
  AppLocalizations? l10n,
]) {
  final rawTitle =
      (l10n == null
              ? community.title
              : community.localizedTitle(l10n.localeName))
          .trim();
  if (rawTitle.isEmpty) {
    return rawTitle;
  }

  final parts = rawTitle
      .split(RegExp(r'\s+[·•]\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length > 1 && _looksLikeLocationToken(parts.last, community)) {
    return parts.first;
  }

  final cityId = _trimmedOrNull(community.cityId);
  if (cityId != null && rawTitle.endsWith(' $cityId')) {
    return rawTitle.substring(0, rawTitle.length - cityId.length).trim();
  }

  return rawTitle;
}

String feedCommunityDisplayDescription(
  FeedCommunityVm community, [
  AppLocalizations? l10n,
]) {
  final description =
      (l10n == null
              ? (community.description ?? community.subtitle ?? '')
              : community.localizedDescription(l10n.localeName))
          .trim();
  return description;
}

String feedCommunityLocationLabel(
  FeedCommunityVm community, {
  bool includeCountry = false,
}) {
  final cityName = _trimmedOrNull(community.cityName);
  final cityId = _trimmedOrNull(community.cityId);
  final city = cityName != null
      ? _cityOnlyLabel(cityName)
      : cityId == null
      ? null
      : _humanizeLocationCode(cityId);
  final countryCode = _trimmedOrNull(community.countryCode);
  if (!includeCountry) {
    return city ?? countryCode ?? '';
  }
  return [
    city,
    countryCode,
  ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
}

String feedCommunityMembersLabel(
  FeedCommunityVm community,
  AppLocalizations l10n,
) {
  return l10n.feedCommunityMembersLabel(community.membersCount.toString());
}

String feedCommunityTopicLabel(String? topic, AppLocalizations l10n) {
  final normalized = (topic ?? '').trim().replaceAll('-', '_').toUpperCase();
  return switch (normalized) {
    '' => l10n.communityDiscoveryTopicAll,
    'LANGUAGES' || 'LANGUAGE' => l10n.communityTopicLanguages,
    'HOUSING' ||
    'REAL_ESTATE' ||
    'REAL_ESTATE_RENT' => l10n.communityTopicHousing,
    'TRANSPORT' || 'TRANSPORTATION' => l10n.communityTopicTransport,
    'SPORTS' || 'SPORT' => l10n.communityTopicSports,
    'OUTDOOR' ||
    'TRIPS' ||
    'HIKING' ||
    'TREKKING' => l10n.communityTopicOutdoor,
    'HOBBIES' ||
    'ART' ||
    'POTTERY' ||
    'MASTER_CLASSES' => l10n.communityTopicHobbies,
    'WELLNESS' || 'YOGA' || 'HEALTH_WELLNESS' => l10n.communityTopicWellness,
    'PETS' || 'PET_OWNERS' => l10n.communityTopicPets,
    'CITY_LIFE' ||
    'CITY' ||
    'EVENTS' ||
    'MARKETPLACE' => l10n.communityTopicCityLife,
    'CONTENT' ||
    'NEWS' ||
    'TRAVEL_TIPS' ||
    'APP_NEWS' => l10n.communityTopicContent,
    'FAMILY' || 'FAMILIES' => l10n.communityTopicFamily,
    'TRAVEL' => l10n.communityDiscoveryTopicTravel,
    'GUIDES' => l10n.communityDiscoveryTopicGuides,
    'GENERAL' => l10n.communityTopicGeneral,
    _ => _humanizeTopicCode(normalized),
  };
}

bool _looksLikeLocationToken(String token, FeedCommunityVm community) {
  final normalizedToken = _normalizeToken(token);
  if (normalizedToken == null) {
    return false;
  }

  for (final candidate in [
    community.cityId,
    community.cityName,
    community.countryCode,
  ]) {
    final normalizedCandidate = _normalizeToken(candidate);
    if (normalizedCandidate != null && normalizedToken == normalizedCandidate) {
      return true;
    }
  }

  return normalizedToken.contains('-') ||
      RegExp(r'^[A-Z]{2,3}$').hasMatch(token);
}

String? _normalizeToken(String? value) {
  final normalized = _trimmedOrNull(
    value,
  )?.toLowerCase().replaceAll(RegExp(r'[_\s]+'), '-');
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _trimmedOrNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _cityOnlyLabel(String value) {
  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  return parts.isEmpty ? value.trim() : parts.first;
}

String _humanizeLocationCode(String code) {
  final words = code
      .trim()
      .split(RegExp(r'[-_]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return code;
  }
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _humanizeTopicCode(String code) {
  final words = code
      .toLowerCase()
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return code;
  }
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
