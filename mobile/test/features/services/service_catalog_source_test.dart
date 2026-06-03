import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future services are marked unavailable in the catalog', () async {
    final source = await File(
      'lib/features/services/service_catalog.dart',
    ).readAsString();

    expect(source, contains('this.isAvailable = true'));
    expect(source, contains('final bool isAvailable;'));

    for (final titleGetter in [
      'l10n.homeServiceStays',
      'l10n.serviceTransport',
      'l10n.homeServiceDelivery',
      'l10n.homeServiceTaxi',
    ]) {
      final titleIndex = source.indexOf('title: $titleGetter');
      expect(titleIndex, isNonNegative);

      final entryEnd = source.indexOf('),', titleIndex);
      expect(entryEnd, greaterThan(titleIndex));

      final entrySource = source.substring(titleIndex, entryEnd);
      expect(entrySource, contains('isAvailable: false'));
    }
  });
}
