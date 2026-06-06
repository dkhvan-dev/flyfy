import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth fields scroll view reserves top space for floating labels',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      expect(source, contains('final floatingLabelReserve = authScaled('));
      expect(source, contains('padding: EdgeInsets.only('));
      expect(source, contains('top: floatingLabelReserve'));
      expect(
        source,
        contains('child: SizedBox(width: availableWidth, child: child)'),
      );
    },
  );
}
