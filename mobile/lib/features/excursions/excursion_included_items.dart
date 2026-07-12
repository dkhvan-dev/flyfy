abstract final class ExcursionIncludedItemKey {
  static const transport = 'transport';
  static const food = 'food';
  static const tickets = 'tickets';
  static const equipment = 'equipment';
  static const accommodation = 'accommodation';
  static const permitsFees = 'permits_fees';

  static bool isDeprecated(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    final separatorIndex = value.indexOf(':');
    final prefix = separatorIndex > 0
        ? value.substring(0, separatorIndex)
        : value;
    final normalized = prefix
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return switch (normalized) {
      'guide' || 'гид' || 'photo' || 'photos' || 'фото' => true,
      _ => false,
    };
  }
}
