import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit profile treats nickname as one-time required contract', () async {
    final source = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final ruL10n = await File('lib/l10n/app_ru.arb').readAsString();
    final enL10n = await File('lib/l10n/app_en.arb').readAsString();
    final kkL10n = await File('lib/l10n/app_kk.arb').readAsString();

    expect(source, contains('_nicknameFieldKey'));
    expect(source, contains('_isNicknameLocked'));
    expect(source, contains('nickname: _isNicknameLocked'));
    expect(source, contains('l10n.nicknameRequired'));
    expect(source, contains('l10n.profileNicknameLockedDescription'));
    expect(source, contains('nickname cannot be changed'));
    expect(source, isNot(contains('_displayNameFieldKey')));
    expect(source, isNot(contains('displayName: _isDisplayNameLocked')));

    expect(ruL10n, contains('"nicknameLabel": "Никнейм"'));
    expect(enL10n, contains('"nicknameLabel": "Nickname"'));
    expect(kkL10n, contains('"nicknameLabel": "Никнейм"'));
  });
}
