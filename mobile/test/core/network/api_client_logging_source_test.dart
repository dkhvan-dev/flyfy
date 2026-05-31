import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug HTTP logging is compact and does not dump headers', () async {
    final source = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();

    expect(source, contains('_CompactNetworkLogInterceptor'));
    expect(source, contains('debugPrint'));
    expect(source, isNot(contains('LogInterceptor(\n')));
    expect(source, isNot(contains('responseHeader: true')));
    expect(source, isNot(contains('requestHeader: true')));
  });
}
