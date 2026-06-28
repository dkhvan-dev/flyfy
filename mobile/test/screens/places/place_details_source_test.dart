import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'place fee details use same collapsible dropdown pattern as visit plan',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      final feeStart = source.indexOf('Widget _buildFeeDetails');
      expect(feeStart, isNonNegative);
      final feeEnd = source.indexOf('  Widget _eyebrow', feeStart);
      expect(feeEnd, isNonNegative);
      final feeSource = source.substring(feeStart, feeEnd);

      final visitStart = source.indexOf('Widget _buildVisitPlan');
      expect(visitStart, isNonNegative);
      final visitEnd = source.indexOf('  Widget _buildReviews', visitStart);
      expect(visitEnd, isNonNegative);
      final visitSource = source.substring(visitStart, visitEnd);

      for (final fragment in [
        'Theme(',
        'ClipRRect(',
        'ExpansionTile(',
        'initiallyExpanded: false',
        'maintainState: true',
        'tilePadding: AppEdgeInsets.fromLTRB',
        'childrenPadding: AppEdgeInsets.fromLTRB',
      ]) {
        expect(feeSource, contains(fragment));
        expect(visitSource, contains(fragment));
      }

      expect(
        feeSource,
        contains("PageStorageKey<String>('place-fee-details-\${v.id}')"),
      );
      expect(feeSource, contains('title: Text('));
      expect(feeSource, contains('l10n.placeFeeDetailsTitle'));
      expect(feeSource, contains('subtitle: Padding('));
      expect(feeSource, contains('l10n.placeFeeDetailsNote'));
      expect(
        feeSource,
        isNot(contains('_eyebrow(l10n.placeFeeDetailsSection')),
      );
    },
  );

  test(
    'place details find excursions CTA opens matching excursion or list fallback',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      final ctaStart = source.indexOf('Widget _buildBottomCta');
      expect(ctaStart, isNonNegative);
      final ctaEnd = source.indexOf(
        '\n}\n\nclass _PlaceImageGallery',
        ctaStart,
      );
      expect(ctaEnd, isNonNegative);
      final ctaSource = source.substring(ctaStart, ctaEnd);

      expect(source, contains('Future<void> _openExcursionsForPlace()'));
      expect(source, contains('findFirstExcursionForPlace('));
      expect(
        source,
        contains("'/excursions/\${Uri.encodeComponent(excursionId)}'"),
      );
      expect(source, contains('ExcursionsRouteArgs.noPlaceExcursions('));
      expect(ctaSource, contains('_isOpeningExcursions'));
      expect(ctaSource, contains('? null'));
      expect(ctaSource, contains(': _openExcursionsForPlace'));
      expect(ctaSource, isNot(contains('onPressed: () {}')));
      expect(ctaSource, contains('l10n.placeFindExcursions'));
      expect(ctaSource, isNot(contains('placeFindExcursions.toUpperCase()')));
      expect(ctaSource, isNot(contains('Icons.check_rounded')));
      expect(ctaSource, contains('Icons.chevron_right_rounded'));
      expect(ctaSource, isNot(contains('Icons.arrow_forward_rounded')));
      expect(ctaSource, contains('fontWeight: FontWeight.w800'));
      expect(ctaSource, contains('letterSpacing: 0.4'));
    },
  );

  test(
    'place details exposes structured Amber visit planning sections',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      for (final fragment in [
        'Widget _buildVisitOverview',
        'Widget _buildVisitCostBlock',
        'Widget _buildVisitSeasonBlock',
        'Widget _buildVisitAccessBlock',
        'Widget _buildVisitTimeBlock',
        'Widget _buildRecommendedItemsBlock',
        'Widget _buildPracticalNotesBlock',
        'place.visitInfo.recommendedItems.isNotEmpty',
        'Wrap(',
        'Icons.water_drop_rounded',
        'Icons.hiking_rounded',
        'AppPalette.primary',
      ]) {
        expect(source, contains(fragment));
      }
    },
  );

  test('structured visit planning detail blocks are dropdowns', () async {
    final source = await File(
      'lib/screens/places/place_details_screen.dart',
    ).readAsString();

    final helperStart = source.indexOf('Widget _buildVisitInfoBlock');
    expect(helperStart, isNonNegative);
    final helperEnd = source.indexOf('  Widget _visitInfoDivider', helperStart);
    expect(helperEnd, isNonNegative);
    final helperSource = source.substring(helperStart, helperEnd);

    for (final fragment in [
      'bool initiallyExpanded = false',
      'Theme(',
      'ExpansionTile(',
      'initiallyExpanded: initiallyExpanded',
      'maintainState: true',
      'PageStorageKey<String>',
    ]) {
      expect(helperSource, contains(fragment));
    }

    final contentStart = source.indexOf('Widget _buildContent');
    expect(contentStart, isNonNegative);
    final contentEnd = source.indexOf('  Widget _buildStats', contentStart);
    expect(contentEnd, isNonNegative);
    final contentSource = source.substring(contentStart, contentEnd);

    expect(contentSource, contains('_buildVisitOverview(place, a, l10n)'));
    expect(contentSource, contains('_buildVisitCostBlock(place, a, l10n)'));
    expect(contentSource, contains('_buildVisitSeasonBlock(place, a, l10n)'));
    expect(contentSource, contains('_buildVisitAccessBlock(place, a, l10n)'));
    expect(contentSource, contains('_buildVisitTimeBlock(place, a, l10n)'));
    expect(
      contentSource,
      contains('_buildRecommendedItemsBlock(place, a, l10n)'),
    );
  });

  test('reviews section uses tourist title and empty review CTA', () async {
    final source = await File(
      'lib/screens/places/place_details_screen.dart',
    ).readAsString();

    final reviewStart = source.indexOf('Widget _buildReviews');
    expect(reviewStart, isNonNegative);
    final reviewEnd = source.indexOf(
      '  // ---------------------------------------------------------------------------\n  // Bottom CTA',
      reviewStart,
    );
    expect(reviewEnd, isNonNegative);
    final reviewSource = source.substring(reviewStart, reviewEnd);

    expect(reviewSource, contains('l10n.placeReviewsTitle'));
    expect(reviewSource, contains('l10n.placeAddReview'));
    expect(reviewSource, contains('ElevatedButton.icon'));
    expect(reviewSource, isNot(contains('l10n.placeReviewsSection')));
    expect(source, isNot(contains('Голоса путешественников')));
  });
}
