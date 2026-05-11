bool guideSearchMatches(String query, Iterable<String?> fields) {
  final tokens = _tokens(query);
  if (tokens.isEmpty) return true;

  final haystack = fields
      .map((field) => _normalize(field ?? ''))
      .where((field) => field.isNotEmpty)
      .join(' ');

  if (haystack.isEmpty) return false;
  return tokens.every(haystack.contains);
}

List<String> _tokens(String value) {
  return _normalize(value)
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

String _normalize(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_foldCharacter(ch));
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9а-яәғқңөұүһі]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _foldCharacter(String ch) {
  switch (ch) {
    case 'à':
    case 'á':
    case 'â':
    case 'ã':
    case 'ä':
    case 'å':
    case 'ā':
      return 'a';
    case 'ç':
    case 'ć':
    case 'č':
      return 'c';
    case 'è':
    case 'é':
    case 'ê':
    case 'ë':
    case 'ē':
      return 'e';
    case 'ì':
    case 'í':
    case 'î':
    case 'ï':
    case 'ī':
      return 'i';
    case 'ñ':
      return 'n';
    case 'ò':
    case 'ó':
    case 'ô':
    case 'õ':
    case 'ö':
    case 'ø':
    case 'ō':
      return 'o';
    case 'ù':
    case 'ú':
    case 'û':
    case 'ü':
    case 'ū':
      return 'u';
    case 'ý':
    case 'ÿ':
      return 'y';
    case 'ё':
      return 'е';
    default:
      return ch;
  }
}
