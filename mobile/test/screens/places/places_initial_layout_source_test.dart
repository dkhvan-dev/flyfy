import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places waits for initial data before rendering its adaptive grid', () {
    final source = File(
      'lib/screens/places/places_screen.dart',
    ).readAsStringSync();
    final bodyStart = source.indexOf(
      'Widget _buildBody(PlaceAdaptive a, AppLocalizations l10n)',
    );
    final gridStart = source.indexOf(
      'Widget _buildGrid(PlaceAdaptive a, AppLocalizations l10n)',
      bodyStart,
    );

    expect(bodyStart, greaterThanOrEqualTo(0));
    expect(gridStart, greaterThan(bodyStart));

    final bodySource = source.substring(bodyStart, gridStart);
    expect(source, contains('bool _loading = true;'));
    expect(bodySource, contains('if (_loading && _places.isEmpty)'));
    expect(
      bodySource.indexOf('if (_loading && _places.isEmpty)'),
      lessThan(bodySource.indexOf('CustomScrollView(')),
    );
    expect(source, contains('return SliverLayoutBuilder('));
    expect(
      source,
      contains('placeDiscoverGridColumnCount('),
    );
    expect(source, contains('constraints.crossAxisExtent'));
  });
}
