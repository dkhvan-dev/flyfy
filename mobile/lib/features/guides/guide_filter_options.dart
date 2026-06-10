class GuideFilterOptions {
  const GuideFilterOptions({
    required this.languageCodes,
    required this.specializationCodes,
  });

  static const fallback = GuideFilterOptions(
    languageCodes: ['en', 'ru', 'kk', 'fr', 'ja', 'de', 'es', 'tr'],
    specializationCodes: [
      'mountain_guide',
      'city_historian',
      'culinary_expert',
      'nature_photographer',
    ],
  );

  final List<String> languageCodes;
  final List<String> specializationCodes;

  bool get isEmpty => languageCodes.isEmpty && specializationCodes.isEmpty;

  factory GuideFilterOptions.fromJson(Map<String, dynamic> json) {
    return GuideFilterOptions(
      languageCodes: _codes(json['languages']),
      specializationCodes: _codes(json['specializations']),
    );
  }

  List<String> languageAliases(String code) {
    return switch (code.trim().toLowerCase()) {
      'en' => const ['english', 'английский', 'ағылшын'],
      'ru' => const ['russian', 'русский', 'орыс'],
      'kk' || 'kz' => const ['kazakh', 'казахский', 'қазақ'],
      'fr' => const ['french', 'французский', 'француз'],
      'ja' || 'jp' => const ['japanese', 'японский', 'жапон'],
      'de' => const ['german', 'немецкий', 'неміс'],
      'es' => const ['spanish', 'испанский', 'испан'],
      'tr' => const ['turkish', 'турецкий', 'түрік'],
      _ => const <String>[],
    };
  }
}

List<String> _codes(dynamic raw) {
  if (raw is! List) return const [];

  final result = <String>[];
  final seen = <String>{};
  for (final value in raw) {
    final code = value.toString().trim().toLowerCase();
    if (code.isEmpty || !seen.add(code)) continue;
    result.add(code);
  }
  return result;
}
