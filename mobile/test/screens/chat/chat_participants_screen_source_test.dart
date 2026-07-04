import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat participants screen uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/screens/chat/chat_participants_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.background'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('colors.secondary'));
    expect(source, contains('colors.secondaryContainer'));
    expect(source, contains('colors.borderSecondary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'chat participants role and online metadata use secondary accents',
    () async {
      final source = await File(
        'lib/screens/chat/chat_participants_screen.dart',
      ).readAsString();
      final headerStart = source.indexOf('class _ParticipantsHeader');
      final avatarStart = source.indexOf('class _ParticipantAvatar');
      final avatarEnd = source.indexOf('class _AvatarFallback', avatarStart);

      expect(headerStart, isNonNegative);
      expect(avatarStart, greaterThan(headerStart));
      expect(avatarEnd, greaterThan(avatarStart));

      final participantChromeSource = source.substring(
        headerStart,
        avatarStart,
      );
      final avatarSource = source.substring(avatarStart, avatarEnd);

      expect(participantChromeSource, contains('color: colors.secondary'));
      expect(participantChromeSource, contains('colors.secondaryContainer'));
      expect(participantChromeSource, contains('colors.borderSecondary'));
      expect(participantChromeSource, contains('online ? colors.secondary'));
      expect(avatarSource, contains('color: highlighted ? colors.secondary'));
    },
  );
}
