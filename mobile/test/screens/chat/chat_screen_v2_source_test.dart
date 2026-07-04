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
      expect(
        bubbleSource,
        contains(
          'readByOthers\n                                    ? context.chatColors.secondary',
        ),
      );
    },
  );
}
