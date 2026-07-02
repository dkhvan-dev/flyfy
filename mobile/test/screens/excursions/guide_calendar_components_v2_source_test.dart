import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guide calendar day strip and slot card use V2 colors', () async {
    final dayStripSource = await File(
      'lib/screens/excursions/widgets/guide_calendar_day_strip.dart',
    ).readAsString();
    final slotCardSource = await File(
      'lib/screens/excursions/widgets/guide_schedule_slot_card.dart',
    ).readAsString();

    for (final source in [dayStripSource, slotCardSource]) {
      expect(source, contains('app_design_system.dart'));
      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      expect(source, contains('colors.primary'));
      expect(source, contains('colors.textPrimary'));
      expect(source, isNot(contains('AppPalette.')));
    }

    expect(slotCardSource, contains('guideScheduleStatusColor('));
    expect(slotCardSource, contains('BuildContext context'));
    expect(dayStripSource, contains('guideScheduleStatusColor(context,'));
  });
}
