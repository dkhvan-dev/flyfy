String? appCountryNameForCode(
  String? countryCode, {
  required String localeName,
}) {
  final normalizedCode = countryCode?.trim().toUpperCase();
  if (normalizedCode == null || normalizedCode.isEmpty) return null;

  final names = appLocalizedCountryNames[normalizedCode];
  if (names == null) return null;

  final languageCode = localeName
      .trim()
      .toLowerCase()
      .split(RegExp('[-_]'))
      .first;
  return names[languageCode] ??
      names['en'] ??
      names['ru'] ??
      names.values.first;
}

const Map<String, Map<String, String>> appLocalizedCountryNames = {
  'KZ': {'en': 'Kazakhstan', 'ru': 'Казахстан', 'kk': 'Қазақстан'},
  'RU': {'en': 'Russia', 'ru': 'Россия', 'kk': 'Ресей'},
  'RS': {'en': 'Serbia', 'ru': 'Сербия', 'kk': 'Сербия'},
  'GR': {'en': 'Greece', 'ru': 'Греция', 'kk': 'Грекия'},
  'UZ': {'en': 'Uzbekistan', 'ru': 'Узбекистан', 'kk': 'Өзбекстан'},
  'KG': {'en': 'Kyrgyzstan', 'ru': 'Кыргызстан', 'kk': 'Қырғызстан'},
  'TJ': {'en': 'Tajikistan', 'ru': 'Таджикистан', 'kk': 'Тәжікстан'},
  'TM': {'en': 'Turkmenistan', 'ru': 'Туркменистан', 'kk': 'Түрікменстан'},
  'GE': {'en': 'Georgia', 'ru': 'Грузия', 'kk': 'Грузия'},
  'AZ': {'en': 'Azerbaijan', 'ru': 'Азербайджан', 'kk': 'Әзірбайжан'},
  'AM': {'en': 'Armenia', 'ru': 'Армения', 'kk': 'Армения'},
  'BY': {'en': 'Belarus', 'ru': 'Беларусь', 'kk': 'Беларусь'},
  'UA': {'en': 'Ukraine', 'ru': 'Украина', 'kk': 'Украина'},
  'MD': {'en': 'Moldova', 'ru': 'Молдова', 'kk': 'Молдова'},
  'TR': {'en': 'Turkey', 'ru': 'Турция', 'kk': 'Түркия'},
  'AE': {'en': 'United Arab Emirates', 'ru': 'ОАЭ', 'kk': 'БАЭ'},
  'VN': {'en': 'Vietnam', 'ru': 'Вьетнам', 'kk': 'Вьетнам'},
  'TH': {'en': 'Thailand', 'ru': 'Таиланд', 'kk': 'Тайланд'},
  'PH': {'en': 'Philippines', 'ru': 'Филиппины', 'kk': 'Филиппин'},
  'EG': {'en': 'Egypt', 'ru': 'Египет', 'kk': 'Мысыр'},
  'CN': {'en': 'China', 'ru': 'Китай', 'kk': 'Қытай'},
  'KR': {'en': 'South Korea', 'ru': 'Южная Корея', 'kk': 'Оңтүстік Корея'},
  'JP': {'en': 'Japan', 'ru': 'Япония', 'kk': 'Жапония'},
  'IN': {'en': 'India', 'ru': 'Индия', 'kk': 'Үндістан'},
  'US': {'en': 'United States', 'ru': 'США', 'kk': 'АҚШ'},
  'CA': {'en': 'Canada', 'ru': 'Канада', 'kk': 'Канада'},
  'SG': {'en': 'Singapore', 'ru': 'Сингапур', 'kk': 'Сингапур'},
  'GB': {'en': 'United Kingdom', 'ru': 'Великобритания', 'kk': 'Ұлыбритания'},
  'DE': {'en': 'Germany', 'ru': 'Германия', 'kk': 'Германия'},
  'AT': {'en': 'Austria', 'ru': 'Австрия', 'kk': 'Австрия'},
  'CH': {'en': 'Switzerland', 'ru': 'Швейцария', 'kk': 'Швейцария'},
  'AU': {'en': 'Australia', 'ru': 'Австралия', 'kk': 'Австралия'},
  'NZ': {'en': 'New Zealand', 'ru': 'Новая Зеландия', 'kk': 'Жаңа Зеландия'},
  'TZ': {'en': 'Tanzania', 'ru': 'Танзания', 'kk': 'Танзания'},
  'KE': {'en': 'Kenya', 'ru': 'Кения', 'kk': 'Кения'},
  'FR': {'en': 'France', 'ru': 'Франция', 'kk': 'Франция'},
  'IT': {'en': 'Italy', 'ru': 'Италия', 'kk': 'Италия'},
  'ES': {'en': 'Spain', 'ru': 'Испания', 'kk': 'Испания'},
  'MN': {'en': 'Mongolia', 'ru': 'Монголия', 'kk': 'Моңғолия'},
  'MY': {'en': 'Malaysia', 'ru': 'Малайзия', 'kk': 'Малайзия'},
  'ID': {'en': 'Indonesia', 'ru': 'Индонезия', 'kk': 'Индонезия'},
  'MV': {'en': 'Maldives', 'ru': 'Мальдивы', 'kk': 'Мальдив аралдары'},
  'SC': {'en': 'Seychelles', 'ru': 'Сейшелы', 'kk': 'Сейшел аралдары'},
  'PL': {'en': 'Poland', 'ru': 'Польша', 'kk': 'Польша'},
  'MX': {'en': 'Mexico', 'ru': 'Мексика', 'kk': 'Мексика'},
  'BR': {'en': 'Brazil', 'ru': 'Бразилия', 'kk': 'Бразилия'},
  'AR': {'en': 'Argentina', 'ru': 'Аргентина', 'kk': 'Аргентина'},
  'AB': {'en': 'Abkhazia', 'ru': 'Абхазия', 'kk': 'Абхазия'},
  'LK': {'en': 'Sri Lanka', 'ru': 'Шри-Ланка', 'kk': 'Шри-Ланка'},
  'MT': {'en': 'Malta', 'ru': 'Мальта', 'kk': 'Мальта'},
  'CY': {'en': 'Cyprus', 'ru': 'Кипр', 'kk': 'Кипр'},
  'ME': {'en': 'Montenegro', 'ru': 'Черногория', 'kk': 'Черногория'},
  'CU': {'en': 'Cuba', 'ru': 'Куба', 'kk': 'Куба'},
  'MA': {'en': 'Morocco', 'ru': 'Марокко', 'kk': 'Марокко'},
  'PT': {'en': 'Portugal', 'ru': 'Португалия', 'kk': 'Португалия'},
  'LU': {'en': 'Luxembourg', 'ru': 'Люксембург', 'kk': 'Люксембург'},
  'IS': {'en': 'Iceland', 'ru': 'Исландия', 'kk': 'Исландия'},
  'IE': {'en': 'Ireland', 'ru': 'Ирландия', 'kk': 'Ирландия'},
  'NL': {'en': 'Netherlands', 'ru': 'Нидерланды', 'kk': 'Нидерланд'},
  'DK': {'en': 'Denmark', 'ru': 'Дания', 'kk': 'Дания'},
  'FI': {'en': 'Finland', 'ru': 'Финляндия', 'kk': 'Финляндия'},
  'EE': {'en': 'Estonia', 'ru': 'Эстония', 'kk': 'Эстония'},
  'SE': {'en': 'Sweden', 'ru': 'Швеция', 'kk': 'Швеция'},
  'CZ': {'en': 'Czechia', 'ru': 'Чехия', 'kk': 'Чехия'},
};
