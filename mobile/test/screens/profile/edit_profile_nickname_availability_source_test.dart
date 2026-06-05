import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit profile checks nickname availability while typing', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final ruL10n = await File('lib/l10n/app_ru.arb').readAsString();
    final enL10n = await File('lib/l10n/app_en.arb').readAsString();
    final kkL10n = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('_nicknameAvailabilityDebounce'));
    expect(source, contains('_scheduleNicknameAvailabilityCheck'));
    expect(source, contains('_checkNicknameAvailability'));
    expect(source, contains('_isCheckingNickname'));
    expect(source, contains('_isNicknameTaken'));
    expect(source, contains('l10n.profileNicknameOneTimeHint'));
    expect(source, contains('l10n.profileNicknameChecking'));
    expect(source, contains('l10n.profileNicknameAvailable'));
    expect(source, contains('l10n.profileNicknameTaken'));
    expect(source, contains('isNicknameAvailable('));

    expect(
      ruL10n,
      contains(
        '"profileNicknameOneTimeHint": "Никнейм можно задать только один раз. После сохранения он не меняется."',
      ),
    );
    expect(
      enL10n,
      contains(
        '"profileNicknameOneTimeHint": "Nickname can be set only once. After saving, it cannot be changed."',
      ),
    );
    expect(
      kkL10n,
      contains(
        '"profileNicknameOneTimeHint": "Никнеймді тек бір рет қоюға болады. Сақталғаннан кейін оны өзгерту мүмкін емес."',
      ),
    );
  });
}
