import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'attractions screen renders current-city must visit block before sort',
    () async {
      final source = await File(
        'lib/screens/attractions/attractions_screen.dart',
      ).readAsString();

      expect(source, contains('class _MustVisitSection'));
      expect(source, contains('class _MustVisitCard'));
      expect(source, contains('_mustVisitAttractions('));
      expect(source, contains('provider.effectiveLocation'));
      expect(source, contains('AppCityFilterValue.fromParts('));
      expect(source, contains('l10n.attractionMustVisitBadge'));

      final bodyStart = source.indexOf('Widget _buildBody');
      final sortBarCall = source.indexOf('_AttractionSortBar(', bodyStart);
      final mustVisitCall = source.indexOf('_MustVisitSection(', bodyStart);
      expect(bodyStart, isNonNegative);
      expect(mustVisitCall, isNonNegative);
      expect(sortBarCall, greaterThan(mustVisitCall));

      final sectionStart = source.indexOf('class _MustVisitSection');
      final sectionEnd = source.indexOf('class _MustVisitCard');
      expect(sectionStart, isNonNegative);
      expect(sectionEnd, greaterThan(sectionStart));
      final sectionSource = source.substring(sectionStart, sectionEnd);

      expect(sectionSource, contains('SingleChildScrollView'));
      expect(sectionSource, contains('scrollDirection: Axis.horizontal'));
      expect(sectionSource, contains('BouncingScrollPhysics'));
      expect(sectionSource, contains('AppLocalizedLocationText'));
      expect(sectionSource, contains('maxLines: 1'));
      expect(sectionSource, contains('TextOverflow.ellipsis'));
    },
  );

  test(
    'must visit section is derived from current city attractions safely',
    () async {
      final source = await File(
        'lib/screens/attractions/attractions_screen.dart',
      ).readAsString();

      final helperStart = source.indexOf(
        'List<AttractionVm> _mustVisitAttractions',
      );
      final bodyStart = source.indexOf('Widget _buildBody');
      expect(helperStart, isNonNegative);
      expect(bodyStart, greaterThan(helperStart));
      final helperSource = source.substring(helperStart, bodyStart);

      expect(helperSource, contains('city.matches('));
      expect(helperSource, contains('rating.compareTo'));
      expect(helperSource, contains('reviewCount.compareTo'));
      expect(helperSource, contains('take(5)'));
    },
  );
}
