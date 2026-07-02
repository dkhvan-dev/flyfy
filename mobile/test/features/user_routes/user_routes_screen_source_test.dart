import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'user routes list screen exposes public, own and saved route tabs',
    () async {
      final source = await File(
        'lib/features/user_routes/presentation/user_routes_screen.dart',
      ).readAsString();

      expect(source, contains('class UserRoutesScreen'));
      expect(source, contains('TabController'));
      expect(source, contains('loadPublicRoutes('));
      expect(source, contains('loadMyRoutes('));
      expect(source, contains('loadSavedRoutes('));
      expect(source, contains('RefreshIndicator('));
      expect(source, contains('ErrorView('));
      expect(source, contains('context.push('));
      expect(source, contains("'/user-routes/"));
    },
  );

  test('user routes list screen gates custom route creation entry', () async {
    final source = await File(
      'lib/features/user_routes/presentation/user_routes_screen.dart',
    ).readAsString();

    expect(source, contains("user_route_feature_flags.dart"));
    expect(source, contains('if (UserRouteFeatureFlags.customRoutesEnabled)'));
    expect(source, contains("context.push('/map?mode=route-builder')"));
  });

  test('user routes list screen uses adaptive V2 colors', () async {
    final source = await File(
      'lib/features/user_routes/presentation/user_routes_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.screenGradientColors'));
    expect(source, contains('_userRouteCardDecoration('));
    expect(source, contains('AppColors colors'));
    expect(source, contains('colors.surface'));
    expect(source, contains('colors.surfaceRaised'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.textSecondary'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('user route details can save, copy and open the route on map', () async {
    final source = await File(
      'lib/features/user_routes/presentation/user_route_details_screen.dart',
    ).readAsString();

    expect(source, contains('class UserRouteDetailsScreen'));
    expect(source, contains('getRoute('));
    expect(source, contains('saveRoute('));
    expect(source, contains('unsaveRoute('));
    expect(source, contains('copyRoute('));
    expect(source, contains('MapRoutePreview('));
    expect(source, contains("'/map'"));
    expect(source, contains('RouteSummaryCard('));
  });

  test(
    'user route details let route owner edit visibility and copy share link',
    () async {
      final source = await File(
        'lib/features/user_routes/presentation/user_route_details_screen.dart',
      ).readAsString();

      expect(source, contains('SessionProvider'));
      expect(source, contains('route.ownerUserId'));
      expect(source, contains('_editRoute('));
      expect(source, contains('showAppModalBottomSheet'));
      expect(source, contains('UpdateUserRouteRequestVm('));
      expect(source, contains('updateRoute('));
      expect(source, contains('userRoutesEditRoute'));
      expect(source, contains('userRoutesShareRoute'));
      expect(source, contains('Clipboard.setData'));
      expect(source, contains('_buildRouteShareLink('));
    },
  );

  test(
    'user route owner can edit stops and rebuild route before saving',
    () async {
      final source = await File(
        'lib/features/user_routes/presentation/user_route_details_screen.dart',
      ).readAsString();

      expect(source, contains('RoutingProvider'));
      expect(source, contains('_editRoutePoints('));
      expect(source, contains('_EditRoutePointsSheet'));
      expect(source, contains('RouteRequestVm('));
      expect(source, contains('buildRoute('));
      expect(source, contains('UserRouteSnapshotVm.fromRouteResponse'));
      expect(source, contains('points: result.points'));
      expect(source, contains('userRoutesEditStops'));
      expect(source, contains('userRoutesRebuildAndSave'));
    },
  );

  test(
    'user route stop editing copy is localized in all supported locales',
    () async {
      for (final path in [
        'lib/l10n/app_en.arb',
        'lib/l10n/app_ru.arb',
        'lib/l10n/app_kk.arb',
      ]) {
        final source = await File(path).readAsString();

        expect(source, contains('"userRoutesEditStops"'));
        expect(source, contains('"userRoutesEditStopsHint"'));
        expect(source, contains('"userRoutesEditStopNameLabel"'));
        expect(source, contains('"userRoutesEditStopNoteLabel"'));
        expect(source, contains('"userRoutesMoveStopUp"'));
        expect(source, contains('"userRoutesMoveStopDown"'));
        expect(source, contains('"userRoutesRebuildAndSave"'));
        expect(source, contains('"userRoutesEditPointsMinStops"'));
        expect(source, contains('"userRoutesRebuildFailed"'));
        expect(source, contains('"userRoutesStopsUpdateSuccess"'));
      }
    },
  );
}
