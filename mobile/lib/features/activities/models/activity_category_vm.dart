class ActivityCategoryVm {
  ActivityCategoryVm({
    required this.slug,
    required this.name,
    required this.nameRu,
    required this.nameKk,
  });

  final String slug;
  final String name;
  final String nameRu;
  final String nameKk;

  factory ActivityCategoryVm.fromJson(Map<String, dynamic> json) {
    return ActivityCategoryVm(
      slug: json['slug']?.toString().trim().toLowerCase() ?? '',
      name: json['name']?.toString().trim() ?? '',
      nameRu: json['nameRu']?.toString().trim() ?? '',
      nameKk: json['nameKk']?.toString().trim() ?? '',
    );
  }

  String localizedName(String languageCode) {
    final normalizedLanguageCode = languageCode.trim().toLowerCase();

    if (normalizedLanguageCode == 'ru' && nameRu.isNotEmpty) {
      return nameRu;
    }
    if (normalizedLanguageCode == 'kk' && nameKk.isNotEmpty) {
      return nameKk;
    }

    if (name.isNotEmpty) return name;
    if (nameRu.isNotEmpty) return nameRu;
    if (nameKk.isNotEmpty) return nameKk;
    return humanizeSlug(slug);
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
