List<List<String>> excursionSearchNeedleGroups(String value) {
  final tokens = normalizeExcursionSearchText(value)
      .split(' ')
      .where((token) => token.trim().isNotEmpty)
      .take(6)
      .toList(growable: false);
  return [
    for (final token in tokens) excursionSearchNeedleVariants(token),
  ].where((variants) => variants.isNotEmpty).toList(growable: false);
}

List<String> excursionSearchNeedleVariants(String token) {
  final variants = <String>[];
  final seen = <String>{};
  void add(String value) {
    final normalized = normalizeExcursionSearchText(value);
    if (normalized.isEmpty || !seen.add(normalized)) return;
    variants.add(normalized);
  }

  add(token);
  if (RegExp(r'[a-z]').hasMatch(token)) {
    add(latinToCyrillicExcursionSearchText(token));
  }
  if (RegExp(r'[а-яәғқңөұүһі]').hasMatch(token)) {
    add(cyrillicToLatinExcursionSearchText(token));
  }
  addExcursionLanguageSearchVariants(add, token);
  return variants;
}

String normalizeExcursionSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[@_.,;:\/\\|()\[\]{}<>+\-=]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String latinToCyrillicExcursionSearchText(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return '';

  final buffer = StringBuffer();
  var index = 0;
  while (index < normalized.length) {
    final rest = normalized.substring(index);
    if (rest.startsWith('shch')) {
      buffer.write('щ');
      index += 4;
    } else if (rest.startsWith('sch')) {
      buffer.write('щ');
      index += 3;
    } else if (rest.startsWith('nyo') || rest.startsWith('nio')) {
      buffer.write('ньо');
      index += 3;
    } else if (rest.startsWith('ch')) {
      buffer.write('ч');
      index += 2;
    } else if (rest.startsWith('sh')) {
      buffer.write('ш');
      index += 2;
    } else if (rest.startsWith('zh')) {
      buffer.write('ж');
      index += 2;
    } else if (rest.startsWith('kh')) {
      buffer.write('х');
      index += 2;
    } else if (rest.startsWith('gh')) {
      buffer.write('ғ');
      index += 2;
    } else if (rest.startsWith('ng')) {
      buffer.write('ң');
      index += 2;
    } else if (rest.startsWith('ya') || rest.startsWith('ia')) {
      buffer.write('я');
      index += 2;
    } else if (rest.startsWith('yu') || rest.startsWith('iu')) {
      buffer.write('ю');
      index += 2;
    } else if (rest.startsWith('yo') || rest.startsWith('io')) {
      buffer.write('е');
      index += 2;
    } else if (rest.startsWith('ye')) {
      buffer.write('е');
      index += 2;
    } else {
      buffer.write(_latinCharToCyrillic(normalized[index]));
      index++;
    }
  }
  return buffer.toString();
}

String _latinCharToCyrillic(String char) {
  return switch (char) {
    'a' => 'а',
    'b' => 'б',
    'c' || 'k' => 'к',
    'd' => 'д',
    'e' => 'е',
    'f' => 'ф',
    'g' => 'г',
    'h' => 'х',
    'i' => 'и',
    'j' => 'ж',
    'l' => 'л',
    'm' => 'м',
    'n' => 'н',
    'o' => 'о',
    'p' => 'п',
    'q' => 'қ',
    'r' => 'р',
    's' => 'с',
    't' => 'т',
    'u' || 'w' => 'у',
    'v' => 'в',
    'x' => 'кс',
    'y' => 'ы',
    'z' => 'з',
    _ => char,
  };
}

String cyrillicToLatinExcursionSearchText(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(
      switch (char) {
        'а' || 'ә' => 'a',
        'б' => 'b',
        'в' => 'v',
        'г' || 'ғ' => 'g',
        'д' => 'd',
        'е' || 'э' => 'e',
        'ё' => 'yo',
        'ж' => 'zh',
        'з' => 'z',
        'и' || 'і' => 'i',
        'й' => 'y',
        'к' || 'қ' => 'k',
        'л' => 'l',
        'м' => 'm',
        'н' || 'ң' => 'n',
        'о' || 'ө' => 'o',
        'п' => 'p',
        'р' => 'r',
        'с' => 's',
        'т' => 't',
        'у' || 'ұ' || 'ү' => 'u',
        'ф' => 'f',
        'х' || 'һ' => 'h',
        'ц' => 'ts',
        'ч' => 'ch',
        'ш' => 'sh',
        'щ' => 'shch',
        'ы' || 'ь' => 'y',
        'ъ' => '',
        'ю' => 'yu',
        'я' => 'ya',
        _ => char,
      },
    );
  }
  return buffer.toString();
}

void addExcursionLanguageSearchVariants(
    void Function(String value) add, String token) {
  switch (normalizeExcursionSearchText(token)) {
    case 'en':
    case 'eng':
    case 'english':
    case 'анг':
    case 'английский':
    case 'ағылшын':
      add('en');
      add('english');
      add('английский');
      add('ағылшын');
      return;
    case 'ru':
    case 'rus':
    case 'russian':
    case 'рус':
    case 'русский':
    case 'орыс':
      add('ru');
      add('russian');
      add('русский');
      add('орыс');
      return;
    case 'kk':
    case 'kz':
    case 'kaz':
    case 'kazakh':
    case 'қазақ':
    case 'казахский':
      add('kk');
      add('kz');
      add('kazakh');
      add('қазақ');
      add('казахский');
      return;
    case 'fr':
    case 'fre':
    case 'french':
    case 'француз':
    case 'французский':
      add('fr');
      add('french');
      add('французский');
      return;
    case 'ja':
    case 'jp':
    case 'japanese':
    case 'япон':
    case 'японский':
    case 'жапон':
      add('ja');
      add('jp');
      add('japanese');
      add('японский');
      add('жапон');
      return;
    case 'de':
    case 'ger':
    case 'german':
    case 'немецкий':
    case 'неміс':
      add('de');
      add('german');
      add('немецкий');
      add('неміс');
      return;
    case 'es':
    case 'spa':
    case 'spanish':
    case 'испанский':
    case 'испан':
      add('es');
      add('spanish');
      add('испанский');
      return;
    case 'tr':
    case 'tur':
    case 'turkish':
    case 'турецкий':
    case 'түрік':
      add('tr');
      add('turkish');
      add('турецкий');
      add('түрік');
      return;
  }
}
