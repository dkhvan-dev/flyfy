import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth form fields scroll horizontally and tabs use primary action foreground',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      expect(source, contains('class _AuthFieldsScrollView'));
      expect(source, contains('scrollDirection: Axis.horizontal'));
      expect(source, contains('_AuthFieldsScrollView('));
      expect(source, contains('maxLines: 1'));
      expect(source, contains('scrollPhysics: const BouncingScrollPhysics()'));
      expect(
        source,
        contains(
          'foregroundColor: WidgetStateProperty.all(AppColors.textPrimary)',
        ),
      );
      expect(
        source,
        contains('iconColor: WidgetStateProperty.all(AppColors.textPrimary)'),
      );
    },
  );
}
