class ActivityTaxonomyItemVm {
  ActivityTaxonomyItemVm({
    required this.slug,
    required this.name,
    required this.nameRu,
    required this.nameKk,
    this.localizedNames = const {},
  });

  final String slug;
  final String name;
  final String nameRu;
  final String nameKk;
  final Map<String, String> localizedNames;

  factory ActivityTaxonomyItemVm.fromJson(Map<String, dynamic> json) {
    final slug = _normalizeTaxonomySlug(json['slug']?.toString());
    return ActivityTaxonomyItemVm(
      slug: slug,
      name: json['name']?.toString().trim() ?? '',
      nameRu: json['nameRu']?.toString().trim() ?? '',
      nameKk: json['nameKk']?.toString().trim() ?? '',
      localizedNames: _parseLocalizedNames(json['localizedNames']),
    );
  }

  String localizedName(String languageCode) {
    return _localizedTaxonomyName(
      languageCode: languageCode,
      localizedNames: localizedNames,
      name: name,
      nameRu: nameRu,
      nameKk: nameKk,
      slug: slug,
    );
  }
}

class ActivityCategoryVm {
  ActivityCategoryVm({
    required this.slug,
    required this.name,
    required this.nameRu,
    required this.nameKk,
    this.aliases = const [],
    this.localizedNames = const {},
    this.subcategories = const [],
    this.systemTags = const [],
  });

  final String slug;
  final String name;
  final String nameRu;
  final String nameKk;
  final List<String> aliases;
  final Map<String, String> localizedNames;
  final List<ActivityTaxonomyItemVm> subcategories;
  final List<ActivityTaxonomyItemVm> systemTags;

  factory ActivityCategoryVm.fromJson(Map<String, dynamic> json) {
    return ActivityCategoryVm(
      slug: _normalizeTaxonomySlug(json['slug']?.toString()),
      name: json['name']?.toString().trim() ?? '',
      nameRu: json['nameRu']?.toString().trim() ?? '',
      nameKk: json['nameKk']?.toString().trim() ?? '',
      aliases: _parseStringList(json['aliases']),
      localizedNames: _parseLocalizedNames(json['localizedNames']),
      subcategories: _parseTaxonomyItems(json['subcategories']),
      systemTags: _parseTaxonomyItems(json['systemTags']),
    );
  }

  String localizedName(String languageCode) {
    return _localizedTaxonomyName(
      languageCode: languageCode,
      localizedNames: localizedNames,
      name: name,
      nameRu: nameRu,
      nameKk: nameKk,
      slug: slug,
    );
  }

  static String humanizeSlug(String raw) {
    final normalized = raw.trim().replaceAll('_', '-');
    if (normalized.isEmpty) return '';

    final parts = normalized
        .split('-')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .toList();

    if (parts.isEmpty) return normalized;
    return parts.join(' ');
  }
}

Map<String, String> _parseLocalizedNames(dynamic value) {
  if (value is! Map) return const {};

  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString().trim().toLowerCase() ?? '';
    final label = entry.value?.toString().trim() ?? '';
    if (key.isNotEmpty && label.isNotEmpty) {
      result[key] = label;
    }
  }
  return Map.unmodifiable(result);
}

List<String> _parseStringList(dynamic value) {
  final items = value is List ? value : const [];
  return items
      .map((item) => _normalizeTaxonomySlug(item?.toString()))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _normalizeTaxonomySlug(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll('_', '-');
}

List<ActivityTaxonomyItemVm> _parseTaxonomyItems(dynamic value) {
  final items = value is List ? value : const [];
  return items
      .whereType<Map<String, dynamic>>()
      .map(ActivityTaxonomyItemVm.fromJson)
      .where((item) => item.slug.isNotEmpty)
      .toList(growable: false);
}

String _localizedTaxonomyName({
  required String languageCode,
  required Map<String, String> localizedNames,
  required String name,
  required String nameRu,
  required String nameKk,
  required String slug,
}) {
  final normalizedLanguageCode = languageCode.trim().toLowerCase();
  final exact = localizedNames[normalizedLanguageCode];
  if (exact != null && exact.isNotEmpty) return exact;

  if (normalizedLanguageCode == 'ru' && nameRu.isNotEmpty) {
    return nameRu;
  }
  if (normalizedLanguageCode == 'kk' && nameKk.isNotEmpty) {
    return nameKk;
  }

  final english = localizedNames['en'];
  if (english != null && english.isNotEmpty) return english;

  if (name.isNotEmpty) return name;
  if (nameRu.isNotEmpty) return nameRu;
  if (nameKk.isNotEmpty) return nameKk;
  return ActivityCategoryVm.humanizeSlug(slug);
}
