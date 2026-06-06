import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/activities/activity_formatters.dart';
import 'package:inflap/l10n/generated/app_localizations_ru.dart';

void main() {
  test(
    'confirmed activity status is localized for attended activity cards',
    () {
      final l10n = AppLocalizationsRu();

      expect(formatActivityStatus('CONFIRMED', l10n), 'Подтверждено');
      expect(formatActivityStatus('Confirmed', l10n), 'Подтверждено');
    },
  );
}
