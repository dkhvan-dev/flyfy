import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'service grid lets service tiles grow vertically from content',
    () async {
      final source = await File(
        'lib/features/services/widgets/service_grid.dart',
      ).readAsString();
      final wrapStart = source.indexOf('Wrap(');

      expect(wrapStart, isNonNegative);

      final textStart = source.indexOf('Text(', wrapStart);
      final textEnd = source.indexOf('style: AppTextStyle(', textStart);

      expect(textStart, greaterThan(wrapStart));
      expect(textEnd, greaterThan(textStart));

      final textSource = source.substring(textStart, textEnd);

      expect(source, isNot(contains('GridView.builder')));
      expect(source, isNot(contains('mainAxisExtent')));
      expect(source, isNot(contains('labelSlotHeight')));
      expect(source, contains('BoxConstraints(minHeight:'));
      expect(source, contains('mainAxisSize: MainAxisSize.min'));
      expect(textSource, contains('maxLines: 2'));
      expect(textSource, contains('TextOverflow.ellipsis'));
    },
  );

  test(
    'unavailable services are disabled and use a separate palette',
    () async {
      final source = await File(
        'lib/features/services/widgets/service_grid.dart',
      ).readAsString();
      final tileStart = source.indexOf('class _ServiceTile');

      expect(tileStart, isNonNegative);

      final tileSource = source.substring(tileStart);

      expect(tileSource, contains('service.isAvailable'));
      expect(
        tileSource,
        contains('service.isAvailable && service.route.trim().isNotEmpty'),
      );
      expect(tileSource, contains('_unavailableForegroundColor'));
      expect(tileSource, contains('_unavailableTextColor'));
      expect(tileSource, contains('_unavailableBackgroundColor'));
      expect(tileSource, contains('_unavailableBorderColor'));
      expect(tileSource, contains('enabled: isEnabled'));
      expect(tileSource, contains('onTap: isEnabled'));
    },
  );
}
