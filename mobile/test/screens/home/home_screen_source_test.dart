import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home screen uses the adaptive v2 design system', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('Theme('));
    expect(source, contains('data: AppDesignSystem.themeFor(context)'));
    expect(
      source,
      contains('final colors = AppDesignSystem.colorsFor(context)'),
    );
    expect(source, contains('AppPalette.primary'));
    expect(source, contains('AppPalette.secondary'));
    expect(source, contains('style: ServiceGridStyle.v2(context)'));
    expect(source, contains('style: AppBottomNavigationBarStyle.v2(context)'));
    final locationIconStart = source.indexOf('Icons.location_on_rounded');
    expect(locationIconStart, isNonNegative);
    final locationIconBlockStart = source.lastIndexOf(
      'Container(',
      locationIconStart,
    );
    final locationIconBlockEnd = source.indexOf(
      'SizedBox(width: isCompact ? 8 : 10)',
      locationIconStart,
    );
    expect(locationIconBlockStart, isNonNegative);
    expect(locationIconBlockEnd, greaterThan(locationIconStart));
    final locationIconBlock = source.substring(
      locationIconBlockStart,
      locationIconBlockEnd,
    );
    expect(locationIconBlock, contains('color: AppPalette.primary'));
    expect(locationIconBlock, isNot(contains('AppPalette.secondary')));
    expect(
      source,
      isNot(
        matches(
          RegExp(
            r'AppPalette\.(warm|orange|amber|violet|pink|blue|green|teal)',
          ),
        ),
      ),
    );
  });

  test(
    'home top chrome uses a status-bar gradient without warm glow',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final bodyStart = source.indexOf('body: DecoratedBox(');
      final headerUsageStart = source.indexOf('_HomeHeader(', bodyStart);
      final headerClassStart = source.indexOf('class _HomeHeader');
      final headerClassEnd = source.indexOf(
        'class _HeaderAvatarButton',
        headerClassStart,
      );

      expect(bodyStart, isNonNegative);
      expect(headerUsageStart, greaterThan(bodyStart));
      expect(headerClassStart, isNonNegative);
      expect(headerClassEnd, greaterThan(headerClassStart));

      final topChromeSource = source.substring(bodyStart, headerUsageStart);
      final headerSource = source.substring(headerClassStart, headerClassEnd);

      expect(source, contains("import 'package:flutter/services.dart';"));
      expect(source, contains('AnnotatedRegion<SystemUiOverlayStyle>'));
      expect(source, contains('statusBarColor: colors.transparent'));
      expect(topChromeSource, isNot(contains('RadialGradient(')));
      expect(topChromeSource, isNot(contains('top: -120')));
      expect(topChromeSource, isNot(contains('AppPalette.primary.withValues')));
      expect(topChromeSource, contains('colors.background'));
      expect(topChromeSource, contains('_homeBackgroundGradientColors('));
      expect(topChromeSource, contains('_homeBackgroundGradientStops('));
      expect(headerSource, contains('color: AppPalette.transparent'));
      expect(headerSource, isNot(contains('color: AppPalette.surface')));
      expect(headerSource, isNot(contains('color: AppPalette.backgroundDeep')));
      expect(headerSource, isNot(contains('gradient:')));
    },
  );

  test('home dark background keeps the approved graphite balance', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final gradientHelperStart = source.indexOf(
      'List<Color> _homeBackgroundGradientColors',
    );
    final stopsHelperStart = source.indexOf(
      'List<double> _homeBackgroundGradientStops',
    );
    final nextHelperStart = source.indexOf(
      'LinearGradient? _homePromoImageScrimGradient',
    );

    expect(gradientHelperStart, isNonNegative);
    expect(stopsHelperStart, greaterThan(gradientHelperStart));
    expect(nextHelperStart, greaterThan(stopsHelperStart));

    final gradientHelperSource = source.substring(
      gradientHelperStart,
      stopsHelperStart,
    );
    final stopsHelperSource = source.substring(
      stopsHelperStart,
      nextHelperStart,
    );

    expect(gradientHelperSource, contains('Brightness.dark'));
    expect(
      gradientHelperSource,
      contains('return [colors.surface, colors.background, colors.background]'),
    );
    expect(
      gradientHelperSource,
      contains('return colors.screenGradientColors'),
    );
    expect(gradientHelperSource, isNot(contains('colors.backgroundDeep')));
    expect(gradientHelperSource, isNot(contains('colors.backgroundWarm')));
    expect(stopsHelperSource, contains('Brightness.dark'));
    expect(stopsHelperSource, contains('return const [0, 0.18, 1]'));
    expect(stopsHelperSource, contains('return const [0, 0.22, 1]'));
  });

  test('home search bar only uses shadow in dark v2', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final searchBarStart = source.indexOf('class _SearchBar');
    final searchBarEnd = source.indexOf('class _SectionHeader', searchBarStart);

    expect(searchBarStart, isNonNegative);
    expect(searchBarEnd, greaterThan(searchBarStart));

    final searchBarSource = source.substring(searchBarStart, searchBarEnd);
    expect(searchBarSource, contains('final isDarkV2'));
    expect(
      searchBarSource,
      contains('Theme.of(context).brightness == Brightness.dark'),
    );
    expect(searchBarSource, contains('boxShadow: isDarkV2'));
    expect(searchBarSource, contains(': null'));
  });

  test('home image cards only use external shadows in dark v2', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final helperStart = source.indexOf(
      'List<BoxShadow>? _homeDarkV2CardShadow',
    );
    final helperEnd = helperStart < 0
        ? -1
        : source.indexOf('double _homeTextScaleFactor', helperStart);
    final promoStart = source.indexOf('class _PromoCard');
    final promoEnd = source.indexOf('class _TopDestinationsRow', promoStart);
    final destinationStart = source.indexOf('class _TopDestinationPlaceCard');
    final destinationEnd = source.indexOf(
      'class _DestinationBookmarkBadge',
      destinationStart,
    );
    final topPostStart = source.indexOf('class _TopPostCard');
    final topPostEnd = source.indexOf('class _TopPostTag', topPostStart);

    expect(helperStart, isNonNegative);
    expect(helperEnd, greaterThan(helperStart));
    expect(promoStart, isNonNegative);
    expect(promoEnd, greaterThan(promoStart));
    expect(destinationStart, isNonNegative);
    expect(destinationEnd, greaterThan(destinationStart));
    expect(topPostStart, isNonNegative);
    expect(topPostEnd, greaterThan(topPostStart));

    final helperSource = source.substring(helperStart, helperEnd);
    final promoSource = source.substring(promoStart, promoEnd);
    final destinationSource = source.substring(
      destinationStart,
      destinationEnd,
    );
    final topPostSource = source.substring(topPostStart, topPostEnd);

    expect(helperSource, contains('Brightness.dark'));
    expect(helperSource, contains('return null'));
    expect(promoSource, contains('_homeDarkV2CardShadow('));
    expect(destinationSource, contains('_homeDarkV2CardShadow('));
    expect(topPostSource, contains('_homeDarkV2CardShadow('));
    expect(promoSource, isNot(contains('boxShadow: [')));
    expect(destinationSource, isNot(contains('boxShadow: [')));
    expect(topPostSource, isNot(contains('boxShadow: [')));
  });

  test('home image scrims avoid dark shadow overlays in light v2', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final promoHelperStart = source.indexOf('_homePromoImageScrimGradient');
    final bottomHelperStart = source.indexOf(
      'LinearGradient? _homeBottomImageScrimGradient',
    );
    final helperEnd = bottomHelperStart < 0
        ? -1
        : source.indexOf('List<BoxShadow>? _homeDarkV2CardShadow');
    final promoStart = source.indexOf('class _PromoCard');
    final promoEnd = source.indexOf('class _TopDestinationsRow', promoStart);
    final destinationStart = source.indexOf('class _TopDestinationPlaceCard');
    final destinationEnd = source.indexOf(
      'class _DestinationBookmarkBadge',
      destinationStart,
    );
    final topPostStart = source.indexOf('class _TopPostCard');
    final topPostEnd = source.indexOf('class _TopPostTag', topPostStart);

    expect(promoHelperStart, isNonNegative);
    expect(bottomHelperStart, greaterThan(promoHelperStart));
    expect(helperEnd, greaterThan(bottomHelperStart));
    expect(promoStart, isNonNegative);
    expect(promoEnd, greaterThan(promoStart));
    expect(destinationStart, isNonNegative);
    expect(destinationEnd, greaterThan(destinationStart));
    expect(topPostStart, isNonNegative);
    expect(topPostEnd, greaterThan(topPostStart));

    final helperSource = source.substring(promoHelperStart, helperEnd);
    final promoSource = source.substring(promoStart, promoEnd);
    final destinationSource = source.substring(
      destinationStart,
      destinationEnd,
    );
    final topPostSource = source.substring(topPostStart, topPostEnd);

    expect(helperSource, contains('Brightness.dark'));
    expect(helperSource, contains('return null'));
    expect(helperSource, isNot(contains('colors.white.withValues')));
    expect(
      helperSource,
      contains('LinearGradient? _homePromoImageScrimGradient'),
    );
    expect(promoSource, contains('final promoScrimGradient'));
    expect(promoSource, contains('if (promoScrimGradient != null)'));
    expect(destinationSource, contains('_homeBottomImageScrimGradient('));
    expect(topPostSource, contains('_homeBottomImageScrimGradient('));
    expect(
      promoSource,
      isNot(contains('AppPalette.black.withValues(alpha: 0.82)')),
    );
    expect(
      destinationSource,
      isNot(contains('AppPalette.black.withValues(alpha: 0.58)')),
    );
    expect(
      topPostSource,
      isNot(contains('AppPalette.black.withValues(alpha: 0.62)')),
    );
  });

  test('home promo text uses a local contrast panel in light v2', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final promoStart = source.indexOf('class _PromoCard');
    final panelStart = source.indexOf('class _PromoTextContrastPanel');
    final promoEnd = panelStart < 0
        ? source.indexOf('class _TopDestinationsRow', promoStart)
        : panelStart;
    final panelEnd = panelStart < 0
        ? -1
        : source.indexOf('class _TopDestinationsRow', panelStart);

    expect(promoStart, isNonNegative);
    expect(promoEnd, greaterThan(promoStart));
    expect(panelStart, isNonNegative);
    expect(panelEnd, greaterThan(panelStart));

    final promoSource = source.substring(promoStart, promoEnd);
    final panelSource = source.substring(panelStart, panelEnd);

    expect(promoSource, contains('_PromoTextContrastPanel('));
    expect(panelSource, contains('class _PromoTextContrastPanel'));
    expect(panelSource, contains('Brightness.dark'));
    expect(panelSource, contains('return child'));
    expect(panelSource, contains('colors.surface.withValues(alpha: 0.82)'));
    expect(panelSource, contains('Border.all'));
    expect(panelSource, contains('ClipRRect('));
  });

  test(
    'home top destination price uses secondary and save affordance is secondary',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final destinationStart = source.indexOf('class _TopDestinationPlaceCard');
      final destinationEnd = source.indexOf(
        'class _DestinationBookmarkBadge',
        destinationStart,
      );

      expect(destinationStart, isNonNegative);
      expect(destinationEnd, greaterThan(destinationStart));

      final destinationSource = source.substring(
        destinationStart,
        destinationEnd,
      );
      final priceLabelStart = destinationSource.indexOf(
        'formatPlacePriceLabel(',
      );
      final ratingStart = destinationSource.indexOf(
        "'★ \${place.rating.toStringAsFixed(1)}'",
        priceLabelStart,
      );
      expect(priceLabelStart, isNonNegative);
      expect(ratingStart, greaterThan(priceLabelStart));
      final priceLabelSource = destinationSource.substring(
        priceLabelStart,
        ratingStart,
      );

      expect(priceLabelSource, contains('color: context.appColors.secondary'));
      expect(priceLabelSource, isNot(contains('color: AppPalette.primary')));
      expect(
        destinationSource,
        isNot(contains('color: AppPalette.secondarySoft')),
      );

      final bookmarkStart = source.indexOf('class _DestinationBookmarkBadge');
      final tagStart = source.indexOf('class _DestinationTag', bookmarkStart);
      expect(bookmarkStart, isNonNegative);
      expect(tagStart, greaterThan(bookmarkStart));
      final bookmarkSource = source.substring(bookmarkStart, tagStart);

      expect(bookmarkSource, contains('AppPalette.secondary.withValues'));
      expect(bookmarkSource, contains('color: AppPalette.secondarySoft'));
    },
  );

  test('home body does not draw a shadow overlay above bottom nav', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final bodyStart = source.indexOf('body: DecoratedBox(');
    final bottomNavigationStart = source.indexOf(
      'bottomNavigationBar: CommonBottomNavigationBar(',
    );
    expect(bodyStart, isNonNegative);
    expect(bottomNavigationStart, isNonNegative);

    expect(source, isNot(contains('const _HomeBottomNavGradient()')));
    expect(source, isNot(contains('class _HomeBottomNavGradient')));

    final bodySource = source.substring(bodyStart);
    expect(
      bodySource,
      isNot(contains('bottom: 1,\n      child: IgnorePointer')),
    );
    expect(bodySource, isNot(contains('child: const SizedBox(height: 24)')));
    expect(
      bodySource,
      isNot(
        contains('colors: [AppPalette.transparent, context.appColors.surface]'),
      ),
    );
  });

  test(
    'unauthenticated home header avatar uses profile icon and notification color',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final avatarButtonStart = source.indexOf('class _HeaderAvatarButton');
      final initialsStart = source.indexOf('class _HeaderAvatarInitials');
      final fallbackStart = source.indexOf('class _HeaderAvatarFallbackIcon');
      final fallbackEnd = source.indexOf('class _SearchBar');
      expect(avatarButtonStart, isNonNegative);
      expect(initialsStart, isNonNegative);
      expect(fallbackStart, greaterThan(initialsStart));
      expect(fallbackEnd, greaterThan(fallbackStart));

      final avatarButtonSource = source.substring(
        avatarButtonStart,
        initialsStart,
      );
      expect(avatarButtonSource, contains('profile == null'));
      expect(avatarButtonSource, contains('_HeaderAvatarFallbackIcon('));
      expect(avatarButtonSource, contains('_HeaderAvatarInitials('));
      expect(
        avatarButtonSource,
        contains('color: AppPalette.primary.withValues(alpha: 0.12)'),
      );
      expect(avatarButtonSource, contains('alpha: 0.24'));
      expect(avatarButtonSource, isNot(contains('boxShadow:')));

      final initialsSource = source.substring(initialsStart, fallbackStart);
      expect(initialsSource, contains('color: context.appColors.textPrimary'));
      expect(initialsSource, isNot(contains('color: AppPalette.onPrimary')));
      expect(initialsSource, isNot(contains('LinearGradient(')));
      expect(initialsSource, contains('color: AppPalette.transparent'));

      final fallbackSource = source.substring(fallbackStart, fallbackEnd);
      expect(fallbackSource, contains('Icons.person_rounded'));
      expect(fallbackSource, contains('color: AppPalette.primary'));
      expect(fallbackSource, contains('size: iconSize'));
      expect(fallbackSource, isNot(contains('Text(')));
    },
  );

  test(
    'home screen renders contextual story tray from the home feed',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      expect(source, contains('ContextualStoryTrayBlock('));
      expect(source, contains("surface: 'home'"));
      expect(source, contains('forYouResult!.page!.items'));
      expect(source, contains('viewerAvatarFileId:'));

      final trayStart = source.indexOf('ContextualStoryTrayBlock(');
      final authGuardStart = source.lastIndexOf(
        'if (isLoggedIn) ...[',
        trayStart,
      );
      expect(authGuardStart, isNonNegative);
      expect(trayStart - authGuardStart, lessThan(220));
    },
  );

  test('home keeps story tray close to services section', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    final trayStart = source.indexOf('ContextualStoryTrayBlock(');
    final servicesStart = source.indexOf(
      'title: l10n.servicesSectionTitle',
      trayStart,
    );
    final loggedInBranchEnd = source.indexOf('] else', trayStart);

    expect(trayStart, isNonNegative);
    expect(servicesStart, greaterThan(trayStart));
    expect(loggedInBranchEnd, greaterThan(trayStart));

    final trayToServicesSource = source.substring(trayStart, loggedInBranchEnd);

    expect(trayToServicesSource, contains('height: isCompact ? 10 : 14'));
    expect(
      trayToServicesSource,
      isNot(contains('height: isCompact ? 24 : 30')),
    );
  });

  test(
    'top destinations cards size their footer from scaled text metrics',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final rowStart = source.indexOf('class _TopDestinationsRow');
      final rowEnd = source.indexOf('class _TopDestinationPlaceCard');
      final cardStart = rowEnd;
      final cardEnd = source.indexOf('class _DestinationBookmarkBadge');

      expect(rowStart, isNonNegative);
      expect(rowEnd, greaterThan(rowStart));
      expect(cardEnd, greaterThan(cardStart));

      final rowSource = source.substring(rowStart, rowEnd);
      final cardSource = source.substring(cardStart, cardEnd);

      expect(rowSource, contains('_homeTopDestinationCardHeight'));
      expect(rowSource, isNot(contains('final infoHeight =')));
      expect(
        cardSource,
        contains('final textScale = _homeTextScaleFactor(context);'),
      );
      expect(cardSource, contains('_homeTopDestinationTitleBlockHeight'));
    },
  );

  test(
    'top destinations cards keep media flexible above the fixed footer',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class _TopDestinationPlaceCard');
      final cardEnd = source.indexOf('class _DestinationBookmarkBadge');

      expect(cardStart, isNonNegative);
      expect(cardEnd, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, cardEnd);

      expect(cardSource, contains('Flexible('));
      expect(cardSource, contains('fit: FlexFit.tight'));
      expect(cardSource, contains('child: AspectRatio('));
      expect(cardSource, contains('const SizedBox(height: 13)'));
      expect(cardSource, contains('height: titleBlockHeight'));
    },
  );

  test(
    'top posts reserve runtime layout safety padding for the footer row',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final helperStart = source.indexOf('double _homePostCardHeight({');
      final helperEnd = source.indexOf('double _measureHomePostTextHeight');

      expect(helperStart, isNonNegative);
      expect(helperEnd, greaterThan(helperStart));

      final helperSource = source.substring(helperStart, helperEnd);

      expect(helperSource, contains('final safetyPadding ='));
      expect(helperSource, contains('isCompact ? 24.0 : 26.0'));
      expect(helperSource, contains('contentBodyHeight + safetyPadding'));
      expect(helperSource, isNot(contains('contentBodyHeight + 4')));
    },
  );

  test('language sheet is height constrained and scrollable', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final sheetSource = await File(
      'lib/core/ui/app_language_sheet.dart',
    ).readAsString();

    expect(source, isNot(contains('Future<void> _showLanguageSheet()')));
    expect(source, isNot(contains('showAppLanguageSheet(context)')));
    expect(source, isNot(contains('class _LanguageOptionTile')));
    expect(sheetSource, contains('maxSheetHeight'));
    expect(sheetSource, contains('ConstrainedBox'));
    expect(sheetSource, contains('SingleChildScrollView'));
  });

  test('home screen no longer owns drawer logout confirmation UI', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('Future<void> _confirmLogout()')));
    expect(source, isNot(contains('class _LogoutConfirmDialog')));
    expect(source, isNot(contains('class _LogoutDialogActionButton')));
    expect(source, isNot(contains('Icons.logout_rounded')));
    expect(source, isNot(contains('AlertDialog(')));
  });

  test('excursions service opens the excursions list screen', () async {
    final catalogSource = await File(
      'lib/features/services/service_catalog.dart',
    ).readAsString();

    expect(catalogSource, contains('l10n.serviceExcursions'));
    expect(catalogSource, contains("route: '/excursions'"));
  });

  test('quick actions expose semantic button targets', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final gridSource = await File(
      'lib/features/services/widgets/service_grid.dart',
    ).readAsString();

    expect(source, contains('ServiceGrid('));
    expect(gridSource, contains('Semantics('));
    expect(gridSource, contains('button: true'));
    expect(gridSource, contains('enabled: isEnabled'));
    expect(gridSource, contains('label: service.title'));
    expect(gridSource, contains('onTap: isEnabled'));
    expect(gridSource, contains('ExcludeSemantics('));
  });

  test(
    'home nav tap scrolls the current home feed to the top and refreshes it',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final stateStart = source.indexOf('class _HomeScreenState');
      final buildStart = source.indexOf('@override\n  Widget build');

      expect(stateStart, isNonNegative);
      expect(buildStart, greaterThan(stateStart));

      final stateSource = source.substring(stateStart, buildStart);

      expect(stateSource, contains('final ScrollController _scrollController'));
      expect(
        stateSource,
        contains('final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey'),
      );
      expect(stateSource, contains('void _handleHomeNavTap()'));
      expect(
        stateSource,
        contains('_refreshIndicatorKey.currentState?.show()'),
      );
      expect(stateSource, contains('_scrollController.animateTo('));
      expect(stateSource, contains('void dispose()'));
      expect(source, contains('key: _refreshIndicatorKey'));
      expect(source, contains('controller: _scrollController'));
      expect(source, contains('onHomeTap: _handleHomeNavTap'));
      expect(source, isNot(contains("onHomeTap: () => context.go('/')")));
    },
  );

  test(
    'home location is managed by a discovery provider and resolver',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      expect(source, contains('HomeLocationProvider'));
      expect(source, contains('HomeLocationPickerSheet'));
      expect(source, contains('AppLocalizedLocationText'));
      expect(source, contains('onLocationTap: _openLocationSheet'));
      expect(source, isNot(contains('currentLocationLabel')));
      expect(source, isNot(contains('homeCurrentLocationLabel')));
      expect(source, isNot(contains('_localizedCountryNames')));
      expect(source, isNot(contains('_localizedCityNames')));
    },
  );

  test(
    'home location sheet uses city search and localized selected preview',
    () async {
      final sheetSource = await File(
        'lib/screens/home/widgets/home_location_picker_sheet.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();

      final previewStart = sheetSource.indexOf('class _CurrentLocationPreview');
      final previewEnd = sheetSource.indexOf('class _DetectLocationButton');
      final cityTileStart = sheetSource.indexOf('class _CityResultTile');
      final cityTileEnd = sheetSource.indexOf(
        'class _LocationMessage',
        cityTileStart,
      );

      expect(previewStart, isNonNegative);
      expect(previewEnd, greaterThan(previewStart));
      expect(cityTileStart, isNonNegative);
      expect(cityTileEnd, greaterThan(cityTileStart));

      final previewSource = sheetSource.substring(previewStart, previewEnd);
      final cityTileSource = sheetSource.substring(cityTileStart, cityTileEnd);

      expect(ruArb, contains('"homeLocationSearchHint": "Город"'));
      expect(previewSource, contains('AppLocalizedLocationText'));
      expect(previewSource, contains('countryCode: location.countryCode'));
      expect(previewSource, contains('cityId: location.cityId'));
      expect(previewSource, contains('cityName: location.cityName'));
      expect(previewSource, isNot(contains('Text(\n                  value,')));
      expect(cityTileSource, contains('AppLocalizedLocationText'));
      expect(cityTileSource, contains('countryCode: city.countryCode'));
      expect(cityTileSource, contains('fallbackText: city.countryCode'));
      expect(cityTileSource, isNot(contains('city.countryCode.toUpperCase()')));
      expect(sheetSource, contains('_loadInitialCountryCities();'));
      expect(sheetSource, contains('_initialCountryCities'));
      expect(sheetSource, contains('citiesByCountry('));
      expect(sheetSource, contains('.take(_initialCountryCityLimit)'));
      expect(sheetSource, contains('Icons.location_off_rounded'));
      expect(sheetSource, contains('color: colors.primary'));
    },
  );

  test('home location sheet uses adaptive V2 design system colors', () async {
    final sheetSource = await File(
      'lib/screens/home/widgets/home_location_picker_sheet.dart',
    ).readAsString();

    expect(
      sheetSource,
      contains("import 'package:inflap/core/ui/app_design_system.dart';"),
    );
    expect(sheetSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(sheetSource, contains('colors.screenGradientColors'));
    expect(sheetSource, contains('colors.surface'));
    expect(sheetSource, contains('colors.surfaceRaised'));
    expect(sheetSource, contains('colors.primary'));
    expect(sheetSource, isNot(contains('AppPalette.')));
  });

  test(
    'home discovery location can prefill activity creation location',
    () async {
      final providerSource = await File(
        'lib/providers/home_location_provider.dart',
      ).readAsString();
      final createActivitySource = await File(
        'lib/screens/activities/create_activity_screen.dart',
      ).readAsString();

      expect(providerSource, contains('class HomeLocationProvider'));
      expect(providerSource, contains('inflap_home_location_preference'));
      expect(createActivitySource, contains('HomeLocationProvider'));
      expect(
        createActivitySource,
        contains('_prefillAuthorLocationFromHomeLocation'),
      );
      expect(createActivitySource, contains('provider.effectiveLocation'));
      expect(
        createActivitySource,
        isNot(contains('provider.selectedLocation')),
      );
    },
  );

  test(
    'home services preview replaces exchange rates with all services tile',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
      final enArb = await File('lib/l10n/app_en.arb').readAsString();
      final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

      expect(
        source,
        contains("import '../../features/services/service_catalog.dart';"),
      );
      expect(
        source,
        contains("import '../../features/services/widgets/service_grid.dart';"),
      );
      expect(source, contains('void _openServices()'));
      expect(source, contains("context.push('/services')"));
      expect(source, contains('buildTravelServiceCatalog('));
      expect(source, contains('l10n,'));
      expect(source, contains('_homeServicesPreview('));
      expect(source, contains('.take(5)'));
      expect(source, contains("service.route != '/travel-checklist'"));
      expect(source, contains("service.route != '/currency-converter'"));
      expect(source, contains('title: l10n.homeServiceAllServices'));
      expect(source, contains('icon: Icons.apps_rounded'));
      expect(source, contains("route: '/services'"));
      expect(source, isNot(contains('actionLabel: l10n.servicesAllButton')));
      expect(source, contains('ServiceGrid('));
      expect(source, contains('onServiceTap: _openService'));
      expect(source, isNot(contains('_FeatureEntriesGrid(')));
      expect(source, isNot(contains('_buildFeatureEntries(')));
      expect(source, isNot(contains('homeFeaturedStays')));
      expect(source, isNot(contains('homeCarRentals')));
      expect(ruArb, contains('"homeServiceAllServices": "Все сервисы"'));
      expect(enArb, contains('"homeServiceAllServices": "All services"'));
      expect(kkArb, contains('"homeServiceAllServices": "Барлық қызметтер"'));
      expect(ruArb, isNot(contains('"servicesAllButton"')));
      expect(enArb, isNot(contains('"servicesAllButton"')));
      expect(kkArb, isNot(contains('"servicesAllButton"')));
      expect(ruArb, contains('"homeRecommendedActivities": "Топ активности"'));
      expect(enArb, contains('"homeRecommendedActivities": "Top activities"'));
      expect(
        kkArb,
        contains('"homeRecommendedActivities": "Үздік белсенділіктер"'),
      );
    },
  );

  test(
    'home all actions are conditional and carousel end cards use totals',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final ruArb = await File('lib/l10n/app_ru.arb').readAsString();
      final enArb = await File('lib/l10n/app_en.arb').readAsString();
      final kkArb = await File('lib/l10n/app_kk.arb').readAsString();

      expect(source, contains('_topPlaces.isNotEmpty'));
      expect(source, contains('topPosts.isNotEmpty'));
      expect(source, contains('recommendedActivities.isNotEmpty'));
      expect(source, contains('homePostStreamItems.isNotEmpty'));
      expect(source, contains('_topPlacesTotal > _topPlaces.length'));
      expect(source, contains('final hasMoreTopPosts = _homeTrendingHasMore;'));
      expect(source, contains('class _HomeShowAllCarouselCard'));
      expect(source, contains('Icons.arrow_forward_rounded'));
      expect(
        RegExp(
          r'itemCount: items\.length \+ \(showAllAction \? 1 : 0\)',
        ).allMatches(source).length,
        2,
      );
      expect(ruArb, contains('"homeSeeAll": "Всё"'));
      expect(enArb, contains('"homeSeeAll": "All"'));
      expect(kkArb, contains('"homeSeeAll": "Барлығы"'));
      expect(ruArb, contains('"homeShowAllCard": "Показать все"'));
      expect(enArb, contains('"homeShowAllCard": "Show all"'));
      expect(kkArb, contains('"homeShowAllCard": "Барлығын көрсету"'));
    },
  );

  test(
    'home header opens current profile from avatar instead of drawer',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final buildStart = source.indexOf('@override\n  Widget build');
      final scaffoldStart = source.indexOf('child: Scaffold(', buildStart);
      final headerStart = source.indexOf('class _HomeHeader');
      final headerEnd = source.indexOf('class _SearchBar', headerStart);

      expect(buildStart, isNonNegative);
      expect(scaffoldStart, greaterThan(buildStart));
      expect(headerStart, isNonNegative);
      expect(headerEnd, greaterThan(headerStart));

      final scaffoldSource = source.substring(scaffoldStart, headerStart);
      final headerSource = source.substring(headerStart, headerEnd);

      expect(
        source,
        isNot(contains("import '../common/app_side_drawer.dart';")),
      );
      expect(scaffoldSource, isNot(contains('drawer: AppSideDrawer(')));
      expect(scaffoldSource, isNot(contains('onDrawerChanged:')));
      expect(source, isNot(contains('void _openDrawer()')));
      expect(headerSource, contains('required this.profile'));
      expect(headerSource, contains('required this.onProfileTap'));
      expect(headerSource, contains('_HeaderAvatarButton('));
      expect(headerSource, contains('onTap: onProfileTap'));
      expect(headerSource, isNot(contains('Icons.menu_rounded')));
      expect(source, contains('profile: profile'));
      expect(source, contains('onProfileTap: _openProfile'));
    },
  );

  test('home guest avatar opens public app settings', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final methodStart = source.indexOf('void _openProfile()');
    final methodEnd = source.indexOf('void _openActivities()', methodStart);

    expect(methodStart, isNonNegative);
    expect(methodEnd, greaterThan(methodStart));

    final methodSource = source.substring(methodStart, methodEnd);
    expect(methodSource, contains('context.read<AuthProvider>()'));
    expect(methodSource, contains("'/profile' : '/app-settings'"));
    expect(source, contains("ValueKey('home-profile-button')"));
    expect(source, contains('l10n.profileSettingsPageTitle'));
  });

  test(
    'promo carousel is passive and sizes cards from content metrics',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final carouselStart = source.indexOf('class _PromoCarousel');
      final carouselEnd = source.indexOf('class _PromoCard');
      final cardStart = carouselEnd;
      final cardEnd = source.indexOf('class _TopDestinationsRow');
      final dataStart = source.indexOf('class _PromoCardData');
      final dataEnd = source.indexOf('double _homeTextScaleFactor', dataStart);

      expect(carouselStart, isNonNegative);
      expect(carouselEnd, greaterThan(carouselStart));
      expect(cardEnd, greaterThan(cardStart));
      expect(dataStart, isNonNegative);
      expect(dataEnd, greaterThan(dataStart));

      final carouselSource = source.substring(carouselStart, carouselEnd);
      final cardSource = source.substring(cardStart, cardEnd);
      final dataSource = source.substring(dataStart, dataEnd);

      expect(carouselSource, contains('_homePromoCardHeight('));
      expect(carouselSource, isNot(contains('required this.onTap')));
      expect(cardSource, isNot(contains('InkWell(')));
      expect(cardSource, isNot(contains('_HomePrimaryPill')));
      expect(cardSource, isNot(contains('data.buttonLabel')));
      expect(dataSource, isNot(contains('buttonLabel')));
      expect(source, isNot(contains('homePromoExplore')));
    },
  );

  test(
    'promo card text block cannot overflow with accessibility text scale',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final cardStart = source.indexOf('class _PromoCard');
      final cardEnd = source.indexOf('class _TopDestinationsRow');

      expect(cardStart, isNonNegative);
      expect(cardEnd, greaterThan(cardStart));

      final cardSource = source.substring(cardStart, cardEnd);

      expect(cardSource, contains('FittedBox('));
      expect(cardSource, contains('fit: BoxFit.scaleDown'));
      expect(cardSource, contains('alignment: Alignment.centerLeft'));
      expect(cardSource, contains('child: ConstrainedBox('));
      expect(cardSource, contains('maxWidth:'));
      expect(
        cardSource,
        isNot(contains('mainAxisAlignment: MainAxisAlignment.center')),
      );
    },
  );

  test(
    'top destinations use backend place categories, not tag fallback',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final labelMatch = RegExp(
        r'String\?? _homePlaceCategoryLabel\(',
      ).firstMatch(source);
      final labelStart = labelMatch?.start ?? -1;
      final nextFunctionStart = source.indexOf(
        'String _homePostTagLabel',
        labelStart < 0 ? 0 : labelStart,
      );

      expect(labelStart, isNonNegative);
      expect(nextFunctionStart, greaterThan(labelStart));

      final labelSource = source.substring(labelStart, nextFunctionStart);

      for (final category in [
        'NATURE',
        'ARCHITECTURE',
        'MUSEUM',
        'BEACH',
        'PARK',
        'TEMPLE',
        'ENTERTAINMENT',
        'FOOD',
        'MARKET',
        'SHOPPING',
        'OTHER',
      ]) {
        expect(labelSource, contains("case '$category':"));
      }

      expect(labelSource, contains('l10n.placeFilterCategoryOther'));
      expect(labelSource, isNot(contains('for (final tag in place.tags)')));
    },
  );

  test(
    'recommended activities use localized taxonomy labels and compact text',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final sectionStart = source.indexOf(
        'class _RecommendedActivitiesSection',
      );
      final cardStart = source.indexOf('class _RecommendedActivityCard');
      final buttonStart = source.indexOf('class _ActivityJoinButton');

      expect(sectionStart, isNonNegative);
      expect(cardStart, greaterThan(sectionStart));
      expect(buttonStart, greaterThan(cardStart));

      final sectionSource = source.substring(sectionStart, cardStart);
      final cardSource = source.substring(cardStart, buttonStart);

      expect(
        source,
        contains(
          "import '../../features/activities/activity_taxonomy_resolver.dart';",
        ),
      );
      expect(source, contains('provider.loadActivityCategories();'));
      expect(sectionSource, contains('categories: provider.categoryItems'));
      expect(sectionSource, contains('languageCode:'));
      expect(cardSource, contains('localizedActivityCategoryLabel('));
      expect(cardSource, contains('localizedActivitySubcategoryLabel('));
      expect(
        cardSource,
        contains("return '\$categoryLabel / \$subcategoryLabel';"),
      );
      expect(cardSource, isNot(contains('ActivityCategoryVm.humanizeSlug')));
      expect(cardSource, contains('fontSize: isCompact ? 15 : 16'));
      expect(cardSource, contains('fontSize: isCompact ? 11.5 : 12'));
      expect(cardSource, contains('fontSize: isCompact ? 16 : 17'));
    },
  );

  test(
    'recommended activities do not hide current user hosted items',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final filterStart = source.indexOf(
        'List<ActivityListItemVm> _filterHomeRecommendedItems',
      );
      final locationStart = source.indexOf(
        'bool _matchesHomeLocation',
        filterStart,
      );

      expect(filterStart, isNonNegative);
      expect(locationStart, greaterThan(filterStart));

      final filterSource = source.substring(filterStart, locationStart);

      expect(
        filterSource,
        isNot(contains('hostUserId.trim() == currentUserId')),
      );
      expect(filterSource, isNot(contains('normalizedUserId')));
      expect(filterSource, contains('_isHomeRecommendedActivity(item)'));
    },
  );

  test(
    'recommended activities use effective user location except fallback',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();
      final filterStart = source.indexOf(
        'List<ActivityListItemVm> _filterHomeRecommendedItems',
      );
      final matchStart = source.indexOf(
        'bool _matchesHomeLocation',
        filterStart,
      );
      final statusStart = source.indexOf(
        'bool _isHomeRegistrationOpenStatus',
        matchStart,
      );

      expect(filterStart, isNonNegative);
      expect(matchStart, greaterThan(filterStart));
      expect(statusStart, greaterThan(matchStart));

      final filterSource = source.substring(filterStart, matchStart);
      final locationSource = source.substring(matchStart, statusStart);

      expect(filterSource, contains('final shouldFilterByLocation ='));
      expect(
        filterSource,
        contains('_shouldFilterHomeRecommendationsByLocation('),
      );
      expect(
        filterSource,
        contains(
          '(!shouldFilterByLocation || _matchesHomeLocation(item, location))',
        ),
      );
      expect(
        locationSource,
        contains('location.source != HomeLocationSource.fallback'),
      );
      expect(locationSource, contains('AppCityFilterValue.fromParts('));
      expect(locationSource, isNot(contains('location.isUserSelected')));
    },
  );

  test(
    'home screen stages initial discovery requests after first frame',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      final initStart = source.indexOf('@override\n  void initState()');
      final initEnd = source.indexOf(
        'void _scheduleInitialDataLoad()',
        initStart,
      );
      final scheduleStart = initEnd;
      final runStart = source.indexOf(
        'Future<void> _runInitialDataLoad()',
        scheduleStart,
      );
      final runEnd = source.indexOf('@override\n  void dispose()', runStart);

      expect(initStart, isNonNegative);
      expect(initEnd, greaterThan(initStart));
      expect(runStart, greaterThan(scheduleStart));
      expect(runEnd, greaterThan(runStart));

      final initSource = source.substring(initStart, initEnd);
      final scheduleSource = source.substring(scheduleStart, runStart);
      final runSource = source.substring(runStart, runEnd);

      expect(source, contains('static const _initialHomeDataDelay'));
      expect(source, contains('static const _initialHomeDataStagger'));
      expect(source, contains('this.initialDataLoadDelay'));
      expect(source, contains('this.initialDataLoadStagger'));
      expect(source, contains('this.waitForFirstFrameRasterized = true'));
      expect(initSource, contains('_scheduleInitialDataLoad();'));
      expect(initSource, isNot(contains('provider.loadActivities();')));
      expect(initSource, isNot(contains('provider.loadActivityCategories();')));
      expect(initSource, isNot(contains('_loadTopPlaces();')));
      expect(initSource, isNot(contains('_loadHomeFeed();')));
      expect(
        scheduleSource,
        contains('WidgetsBinding.instance.addPostFrameCallback'),
      );
      expect(scheduleSource, contains('unawaited(_runInitialDataLoad())'));
      expect(runSource, contains('if (widget.waitForFirstFrameRasterized)'));
      expect(runSource, contains('waitUntilFirstFrameRasterized'));
      expect(
        runSource,
        contains('Future<void>.delayed(widget.initialDataLoadDelay)'),
      );
      expect(
        runSource,
        contains('Future<void>.delayed(widget.initialDataLoadStagger)'),
      );
      expect(runSource, contains('provider.loadActivityCategories();'));
      expect(runSource, contains('unawaited(categoryLoad);'));
      expect(runSource, contains('unawaited(_loadTopPlaces());'));
      expect(runSource, contains('unawaited(_loadHomeFeed());'));
    },
  );

  test(
    'home startup does not block public content on slow location load',
    () async {
      final source = await File(
        'lib/screens/home/home_screen.dart',
      ).readAsString();

      expect(source, contains('_homeLocationStartupTimeout'));
      expect(source, contains('.timeout(_homeLocationStartupTimeout)'));
      expect(
        source,
        contains('must not block public home content from loading'),
      );
    },
  );

  test('home post and activity empty states share arrow-free design', () async {
    final source = await File(
      'lib/screens/home/home_screen.dart',
    ).readAsString();
    final cardStart = source.indexOf('class _HomeEmptyStateCard');
    final smartPostsStart = source.indexOf('class _HomeSmartPostsSection');
    final emptyStateStart = source.indexOf('if (recommendedItems.isEmpty)');
    final populatedStateStart = source.indexOf(
      'final items = recommendedItems.take(3)',
      emptyStateStart,
    );

    expect(cardStart, isNonNegative);
    expect(smartPostsStart, greaterThan(cardStart));
    expect(emptyStateStart, isNonNegative);
    expect(populatedStateStart, greaterThan(emptyStateStart));

    final cardSource = source.substring(cardStart, smartPostsStart);
    final activityEmptyStateSource = source.substring(
      emptyStateStart,
      populatedStateStart,
    );
    final smartPostsSource = source.substring(
      smartPostsStart,
      source.indexOf('class _HomeSmartPostLoadingCard', smartPostsStart),
    );

    expect(cardSource, isNot(contains('Icons.arrow_forward_ios_rounded')));
    expect(cardSource, isNot(contains('InkWell(')));
    expect(cardSource, isNot(contains('GestureDetector(')));
    expect(cardSource, isNot(contains('onTap')));
    expect(cardSource, contains('width: 56'));
    expect(cardSource, contains('fontSize: 16'));
    expect(cardSource, contains('fontSize: 13'));
    expect(activityEmptyStateSource, contains('_HomeEmptyStateCard('));
    expect(activityEmptyStateSource, contains('title: l10n.noActivitiesYet'));
    expect(smartPostsSource, contains('_HomeEmptyStateCard('));
    expect(smartPostsSource, contains('title: l10n.storyEmptyTitle'));
    expect(smartPostsSource, contains('subtitle: l10n.homeSmartPostsEmpty'));
    expect(source, isNot(contains('onEmptyTap')));
  });
}
