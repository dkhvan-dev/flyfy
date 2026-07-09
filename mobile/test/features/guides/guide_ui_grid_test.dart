import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/guides/guide_ui.dart';

void main() {
  group('guideGridColumnCount', () {
    test('keeps two columns on common compact Android content widths', () {
      expect(guideGridColumnCount(crossAxisExtent: 324, textScale: 1.0), 2);
      expect(guideGridColumnCount(crossAxisExtent: 324, textScale: 1.3), 2);
      expect(guideGridColumnCount(crossAxisExtent: 296, textScale: 1.0), 2);
    });

    test('uses one column only when content cannot fit two usable cards', () {
      expect(guideGridColumnCount(crossAxisExtent: 287, textScale: 1.0), 1);
      expect(guideGridColumnCount(crossAxisExtent: 319, textScale: 1.45), 1);
    });

    test('uses three columns on expanded content widths', () {
      expect(guideGridColumnCount(crossAxisExtent: 680, textScale: 1.0), 3);
    });
  });
}
