import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'custom route builder copy is localized in all supported locales',
    () async {
      final en = await File('lib/l10n/app_en.arb').readAsString();
      final ru = await File('lib/l10n/app_ru.arb').readAsString();
      final kk = await File('lib/l10n/app_kk.arb').readAsString();

      for (final source in [en, ru, kk]) {
        expect(source, contains('"mapRouteBuilderTitle"'));
        expect(source, contains('"mapRouteBuilderHint"'));
        expect(source, contains('"mapRouteBuilderBuildRoute"'));
        expect(source, contains('"mapRouteBuilderMinPoints"'));
        expect(source, contains('"mapRouteBuilderClear"'));
        expect(source, contains('"mapRouteBuilderRemoveLast"'));
        expect(source, contains('"mapRouteBuilderPointName"'));
      }
    },
  );
}
