import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/places/place_ui.dart';

void main() {
  group('placeDiscoverGridColumnCount', () {
    test('keeps two columns on common compact Android content widths', () {
      expect(placeDiscoverGridColumnCount(304), 2);
      expect(placeDiscoverGridColumnCount(323), 2);
    });

    test('uses one column only for extremely narrow content widths', () {
      expect(placeDiscoverGridColumnCount(299), 1);
    });
  });
}
