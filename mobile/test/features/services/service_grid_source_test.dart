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
      expect(tileSource, contains('style.unavailableForegroundColor'));
      expect(tileSource, contains('style.unavailableTextColor'));
      expect(tileSource, contains('style.unavailableBackgroundColor'));
      expect(tileSource, contains('style.unavailableBorderColor'));
      expect(tileSource, contains('enabled: isEnabled'));
      expect(tileSource, contains('onTap: isEnabled'));
    },
  );

  test('available services use a dedicated visible border color', () async {
    final source = await File(
      'lib/features/services/widgets/service_grid.dart',
    ).readAsString();

    expect(source, contains('required this.availableBorderColor'));
    expect(source, contains('final Color availableBorderColor'));
    expect(source, contains('style.availableBorderColor'));
    expect(source, isNot(contains('? style.highlightColor')));
  });

  test('service tiles do not render secondary availability dots', () async {
    final source = await File(
      'lib/features/services/widgets/service_grid.dart',
    ).readAsString();

    final tileStart = source.indexOf('class _ServiceTile');
    expect(tileStart, isNonNegative);

    final tileSource = source.substring(tileStart);

    expect(source, isNot(contains('availableStatusColor')));
    expect(source, isNot(contains('availableStatusBackgroundColor')));
    expect(tileSource, isNot(contains('BoxShape.circle')));
    expect(tileSource, isNot(contains('Positioned(')));
    expect(tileSource, isNot(contains('style.availableStatusColor')));
  });

  test(
    'service grid defaults to adaptive v2 colors without legacy palette',
    () async {
      final source = await File(
        'lib/features/services/widgets/service_grid.dart',
      ).readAsString();

      expect(source, contains('this.style,'));
      expect(source, contains('final ServiceGridStyle? style;'));
      expect(
        source,
        contains(
          'final resolvedStyle = style ?? ServiceGridStyle.v2(context);',
        ),
      );
      expect(source, contains('style: resolvedStyle'));
      expect(source, isNot(contains('ServiceGridStyle.legacy')));
      expect(source, isNot(contains('AppPalette.')));
    },
  );
}
