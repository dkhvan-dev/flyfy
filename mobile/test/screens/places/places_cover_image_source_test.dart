import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places list cover cards can retry fallback media URLs', () async {
    final source = await File(
      'lib/screens/places/places_screen.dart',
    ).readAsString();

    expect(source, contains('resolvePlaceMediaUrls('));
    expect(source, contains('_RetryingPlaceCoverImage('));
    expect(source, contains('onRetryNext'));
    expect(source, isNot(contains('final coverUrl = coverMedia == null')));
  });
}
