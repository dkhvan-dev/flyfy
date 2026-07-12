import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('chatColors.primary'));
    expect(source, contains('chatColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'chat presence read receipts and status metrics use secondary accents',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      final topBarStart = source.indexOf('class _DirectTopBarContent');
      final statusMetricStart = source.indexOf('class _StatusMetricCard');
      final readSummaryStart = source.indexOf('class _ReadReceiptSummary');
      final bubbleStart = source.indexOf('class _MessageBubble');
      expect(topBarStart, isNonNegative);
      expect(statusMetricStart, greaterThan(topBarStart));
      expect(readSummaryStart, greaterThan(statusMetricStart));
      expect(bubbleStart, greaterThan(readSummaryStart));

      final topBarSource = source.substring(topBarStart, statusMetricStart);
      final metricSource = source.substring(
        statusMetricStart,
        readSummaryStart,
      );
      final readSummarySource = source.substring(readSummaryStart, bubbleStart);
      final bubbleSource = source.substring(bubbleStart);

      expect(topBarSource, contains('color: context.chatColors.secondary'));
      expect(metricSource, contains('context.chatColors.secondaryContainer'));
      expect(metricSource, contains('color: context.chatColors.secondary'));
      expect(
        readSummarySource,
        contains('color: context.chatColors.secondary'),
      );
      expect(bubbleSource, isNot(contains('_formatTime(message.sentAt)')));
      expect(bubbleSource, isNot(contains("readByOthers ? '✓✓' : '✓'")));
    },
  );

  test('chat light theme controls keep visible contrast', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    final colorsStart = source.indexOf('final class _ChatColors');
    final colorsEnd = source.indexOf('extension _ChatColorContext');
    final directTopBarStart = source.indexOf('class _DirectTopBarContent');
    final groupTopBarStart = source.indexOf('class _GroupTopBarContent');
    final badgeStart = source.indexOf('class _AttachmentDownloadBadge');
    final progressLabelStart = source.indexOf(
      'class _AttachmentDownloadProgressLabel',
      badgeStart,
    );
    final attachmentDataStart = source.indexOf('class _ChatAttachmentViewData');
    final avatarStart = source.indexOf('class _ChatAvatar');
    final composerStart = source.indexOf('class _ChatComposer');
    final composerSubwidgetsStart = source.indexOf(
      '// ── Composer sub-widgets / sheet helpers',
    );

    expect(colorsStart, isNonNegative);
    expect(colorsEnd, greaterThan(colorsStart));
    expect(directTopBarStart, isNonNegative);
    expect(groupTopBarStart, greaterThan(directTopBarStart));
    expect(badgeStart, isNonNegative);
    expect(progressLabelStart, greaterThan(badgeStart));
    expect(attachmentDataStart, greaterThan(badgeStart));
    expect(avatarStart, isNonNegative);
    expect(composerStart, isNonNegative);
    expect(composerSubwidgetsStart, greaterThan(composerStart));

    final colorsSource = source.substring(colorsStart, colorsEnd);
    final directTopBarSource = source.substring(
      directTopBarStart,
      groupTopBarStart,
    );
    final badgeSource = source.substring(badgeStart, progressLabelStart);
    final avatarSource = source.substring(avatarStart, composerStart);
    final composerSource = source.substring(
      composerStart,
      composerSubwidgetsStart,
    );

    expect(
      colorsSource,
      contains('Color composerSendButtonSurface(bool disabled)'),
    );
    expect(colorsSource, contains('disabled ? colors.textDisabled'));
    expect(colorsSource, contains(': colors.primary'));

    expect(directTopBarSource, contains(': context.chatColors.textMuted'));
    expect(
      directTopBarSource,
      isNot(contains('context.chatColors.white.withValues')),
    );

    expect(badgeSource, contains('color: context.chatColors.primary'));
    expect(badgeSource, contains('context.chatColors.primaryPressed'));
    expect(badgeSource, contains('color: context.chatColors.actionOnPrimary'));
    expect(
      badgeSource,
      isNot(contains('color: context.chatColors.surfaceHigh')),
    );
    expect(badgeSource, isNot(contains('color: context.chatColors.white')));

    expect(avatarSource, contains('boxShadow: _chatDarkThemeShadow('));
    expect(avatarSource, isNot(contains('boxShadow: [')));

    expect(
      composerSource,
      contains('color: context.chatColors.composerSendButtonSurface('),
    );
    expect(
      composerSource,
      isNot(contains('color: context.chatColors.textMuted')),
    );
  });
}
