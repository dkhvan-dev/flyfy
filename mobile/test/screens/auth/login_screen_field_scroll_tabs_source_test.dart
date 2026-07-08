import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth form fields fit panel width and tabs resolve readable state colors',
    () async {
      final source = await File(
        'lib/screens/auth/login_screen.dart',
      ).readAsString();

      expect(source, contains('class _AuthFieldsScrollView'));
      expect(source, isNot(contains('scrollDirection: Axis.horizontal')));
      expect(source, isNot(contains('minContentWidth')));
      expect(source, contains('_AuthFieldsScrollView('));
      expect(source, contains('maxLines: 1'));
      expect(source, contains('scrollPhysics: const BouncingScrollPhysics()'));
      expect(
        source,
        contains('foregroundColor: WidgetStateProperty.resolveWith<Color>'),
      );
      expect(
        source,
        contains('iconColor: WidgetStateProperty.resolveWith<Color>'),
      );
      expect(source, contains('states.contains(WidgetState.selected)'));
      expect(
        source,
        matches(
          RegExp(
            r'states\.contains\(WidgetState\.selected\)[\s\S]*?\?\s*AppPalette\.textPrimary[\s\S]*?:\s*context\.appColors\.textPrimary',
          ),
        ),
      );
    },
  );
}
