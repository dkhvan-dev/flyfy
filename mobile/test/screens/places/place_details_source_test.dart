import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('place details screen uses adaptive V2 colors only', () async {
    final source = await File(
      'lib/screens/places/place_details_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('placeColors.primary'));
    expect(source, contains('placeColors.textPrimary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'place details hero disables cover fade overlay in light theme',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf(
        'LinearGradient? _placeHeroOverlayGradient',
      );
      final heroStart = source.indexOf('Widget _buildHero');
      final mediaPageStart = source.indexOf('Widget _buildHeroMediaPage');

      expect(helperStart, isNonNegative);
      expect(heroStart, isNonNegative);
      expect(mediaPageStart, greaterThan(heroStart));

      final helperSource = source.substring(helperStart, heroStart);
      final heroSource = source.substring(heroStart, mediaPageStart);

      expect(helperSource, contains('Brightness.light'));
      expect(helperSource, contains('return null;'));
      expect(heroSource, contains('final heroOverlayGradient ='));
      expect(heroSource, contains('if (heroOverlayGradient != null)'));
      expect(heroSource, contains('gradient: heroOverlayGradient'));
    },
  );

  test(
    'place details stat and location cards use visible V2 borders',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();
      final colorsStart = source.indexOf('final class _PlaceDetailsColors');
      final colorsEnd = source.indexOf(
        'extension _PlaceDetailsColorContext',
        colorsStart,
      );
      final locationStart = source.indexOf('Widget _buildLocationBlock');
      final statsStart = source.indexOf('Widget _buildStats');
      final experienceStart = source.indexOf('Widget _buildExperience');

      expect(colorsStart, isNonNegative);
      expect(colorsEnd, greaterThan(colorsStart));
      expect(locationStart, isNonNegative);
      expect(statsStart, greaterThan(locationStart));
      expect(experienceStart, greaterThan(statsStart));

      final colorsSource = source.substring(colorsStart, colorsEnd);
      final locationSource = source.substring(locationStart, statsStart);
      final statsSource = source.substring(statsStart, experienceStart);

      expect(
        colorsSource,
        contains('Color get detailCardSurface => colors.surfaceRaised'),
      );
      expect(
        colorsSource,
        contains('Color get detailCardBorder => colors.border'),
      );
      expect(locationSource, contains('context.placeColors.detailCardSurface'));
      expect(locationSource, contains('context.placeColors.detailCardBorder'));
      expect(statsSource, contains('context.placeColors.detailCardSurface'));
      expect(statsSource, contains('context.placeColors.detailCardBorder'));
      expect(statsSource, isNot(contains('white.withValues(alpha: 0.05)')));
      expect(statsSource, isNot(contains('white.withValues(alpha: 0.035)')));
      expect(
        locationSource,
        isNot(contains('primary.withValues(alpha: 0.22)')),
      );
    },
  );

  test(
    'place details content starts with a visible divider after hero',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      final contentStart = source.indexOf('Widget _buildContent');
      final locationStart = source.indexOf('Widget _buildLocationBlock');
      expect(contentStart, isNonNegative);
      expect(locationStart, greaterThan(contentStart));

      final contentSource = source.substring(contentStart, locationStart);

      expect(contentSource, contains('DecoratedBox('));
      expect(contentSource, contains('Border('));
      expect(contentSource, contains('top: BorderSide('));
      expect(contentSource, contains('context.placeColors.detailCardBorder'));
      expect(contentSource, contains('child: Padding('));
    },
  );

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
        'context.placeColors.primary',
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

  test(
    'tourist reviews sit directly after practical visit content before help',
    () async {
      final source = await File(
        'lib/screens/places/place_details_screen.dart',
      ).readAsString();

      final contentStart = source.indexOf('Widget _buildContent');
      expect(contentStart, isNonNegative);
      final contentEnd = source.indexOf('  Widget _buildLocationBlock');
      expect(contentEnd, greaterThan(contentStart));
      final contentSource = source.substring(contentStart, contentEnd);

      final practicalIndex = contentSource.indexOf(
        '_buildPracticalNotesBlock(place, a, l10n)',
      );
      final reviewsIndex = contentSource.indexOf('_buildReviews(a, l10n)');
      final helpIndex = contentSource.indexOf('ContextualHelpSection(');

      expect(practicalIndex, isNonNegative);
      expect(reviewsIndex, isNonNegative);
      expect(helpIndex, isNonNegative);
      expect(reviewsIndex, greaterThan(practicalIndex));
      expect(helpIndex, greaterThan(reviewsIndex));
      expect(
        contentSource,
        contains('SizedBox(height: a.scale(24, minFactor: 0.72))'),
      );
      expect(
        contentSource,
        isNot(contains('SizedBox(height: a.scale(hasStructuredVisitPlanning')),
      );
    },
  );

  test('place description is rendered as a readable paragraph card', () async {
    final source = await File(
      'lib/screens/places/place_details_screen.dart',
    ).readAsString();

    final experienceStart = source.indexOf('Widget _buildExperience');
    expect(experienceStart, isNonNegative);
    final experienceEnd = source.indexOf('  Widget _buildFeeDetails');
    expect(experienceEnd, greaterThan(experienceStart));
    final experienceSource = source.substring(experienceStart, experienceEnd);

    expect(
      experienceSource,
      contains('_buildReadableDescriptionCard(v.description, a)'),
    );

    final cardStart = source.indexOf('Widget _buildReadableDescriptionCard');
    expect(cardStart, isNonNegative);
    final cardEnd = source.indexOf('  Widget _buildFeeDetails', cardStart);
    expect(cardEnd, greaterThan(cardStart));
    final cardSource = source.substring(cardStart, cardEnd);

    expect(cardSource, contains('color: context.placeColors.surfaceHigh'));
    expect(cardSource, contains('border: Border.all('));
    expect(cardSource, contains('color: context.placeColors.border'));
    expect(cardSource, contains('color: context.placeColors.textPrimary'));
    expect(cardSource, contains('height: 1.62'));
    expect(cardSource, contains('letterSpacing: 0'));
    expect(cardSource, isNot(contains('context.placeColors.primary')));
    expect(cardSource, isNot(contains('letterSpacing: -0.45')));
  });
}
