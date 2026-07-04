import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/network/checklist_api.dart';
import 'package:inflap/core/network/reference_api.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/features/checklists/data/checklist_offline_cache.dart';
import 'package:inflap/features/checklists/models/trip_checklist_vm.dart';
import 'package:inflap/features/checklists/models/travel_checklist_route_args.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/checklists/travel_checklist_screen.dart';

void main() {
  test(
    'travel checklist optimizes day route through routing provider',
    () async {
      final source = await File(
        'lib/screens/checklists/travel_checklist_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../features/routing/models/routing_models.dart';"),
      );
      expect(
        source,
        contains("import '../../providers/routing_provider.dart';"),
      );
      expect(
        source,
        contains('ItineraryOptimizationResponseVm? _optimizedItinerary;'),
      );
      expect(source, contains('Future<void> _optimizeDayRoute('));
      expect(source, contains('context.read<RoutingProvider>()'));
      expect(source, contains('routingProvider.optimizeItinerary('));
      expect(source, contains('ItineraryOptimizationRequestVm('));
      expect(source, contains('_OptimizedItineraryCard('));
      expect(source, contains('travelChecklistOptimizeRouteTitle'));
    },
  );

  test(
    'travel checklist request uses profile citizenship from session',
    () async {
      final source = await File(
        'lib/screens/checklists/travel_checklist_screen.dart',
      ).readAsString();

      expect(
        source,
        contains("import '../../providers/session_provider.dart';"),
      );
      expect(source, contains('context.read<SessionProvider>()'));
      expect(source, contains('session.profile?.countryCode'));
      expect(source, contains('citizenshipCountryCode:'));
    },
  );

  test('saved checklist chips use visible V2 borders in light theme', () async {
    final source = await File(
      'lib/screens/checklists/travel_checklist_screen.dart',
    ).readAsString();
    final chipStart = source.indexOf('class _ChipLabel');
    final panelStart = source.indexOf('class _SurfacePanel');

    expect(chipStart, isNonNegative);
    expect(panelStart, greaterThan(chipStart));

    final chipSource = source.substring(chipStart, panelStart);

    expect(
      chipSource,
      contains(
        'final isLight = Theme.of(context).brightness == Brightness.light;',
      ),
    );
    expect(chipSource, contains('alpha: isLight ? 0.48 : 0.30'));
    expect(chipSource, contains('width: isLight ? 1.2 : 1'));
  });

  test(
    'missing context action buttons use visible V2 borders in light theme',
    () async {
      final source = await File(
        'lib/screens/checklists/travel_checklist_screen.dart',
      ).readAsString();
      final actionsStart = source.indexOf(
        'class _MissingContextAlternativeActions',
      );
      final contextPanelStart = source.indexOf('class _TripContextPanel');

      expect(actionsStart, isNonNegative);
      expect(contextPanelStart, greaterThan(actionsStart));

      final actionsSource = source.substring(actionsStart, contextPanelStart);

      expect(
        actionsSource,
        contains('final palette = _ChecklistAmber.of(context);'),
      );
      expect(
        actionsSource,
        contains(
          'final isLight = Theme.of(context).brightness == Brightness.light;',
        ),
      );
      expect(actionsSource, contains('final actionBackground ='));
      expect(actionsSource, contains('final actionBorder ='));
      expect(actionsSource, contains('backgroundColor: actionBackground'));
      expect(actionsSource, contains('foregroundColor: palette.textPrimary'));
      expect(
        actionsSource,
        contains(
          'side: BorderSide(color: actionBorder, width: isLight ? 1.2 : 1)',
        ),
      );
    },
  );

  test('saved checklist cards use visible V2 borders in light theme', () async {
    final source = await File(
      'lib/screens/checklists/travel_checklist_screen.dart',
    ).readAsString();
    final tileStart = source.indexOf('class _RecentChecklistTile');
    final autocompleteStart = source.indexOf(
      'class _QuickPrepAutocompleteField',
    );

    expect(tileStart, isNonNegative);
    expect(autocompleteStart, greaterThan(tileStart));

    final tileSource = source.substring(tileStart, autocompleteStart);

    expect(
      tileSource,
      contains(
        'final isLight = Theme.of(context).brightness == Brightness.light;',
      ),
    );
    expect(tileSource, contains('side: BorderSide('));
    expect(tileSource, contains('alpha: isLight ? 0.74 : 0.42'));
    expect(tileSource, contains('width: isLight ? 1.2 : 1'));
  });

  testWidgets(
    'shows setup state instead of sample checklist when route args are missing',
    (tester) async {
      final checklistApi = _FakeChecklistApi();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(checklistApi.getOrCreateCalls, 0);
      expect(find.text('Сначала выберите поездку'), findsOneWidget);
      expect(find.text('Защита от жары и дождя'), findsNothing);
    },
  );

  testWidgets('does not show saved checklists on setup screen', (tester) async {
    final checklistApi = _FakeChecklistApi();
    final cachedRouteArgs = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:istanbul:2026-07-10',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Istanbul',
        cityId: 'istanbul',
      ),
      startAt: DateTime.utc(2026, 7, 10, 9),
      endAt: DateTime.utc(2026, 7, 17, 18),
      transportModes: const ['flight'],
      activitySlugs: const ['culture'],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(
            entries: [
              CachedTravelChecklistEntry(
                routeArgs: cachedRouteArgs,
                savedAt: DateTime.utc(2026, 6, 20, 12),
                readinessScore: 72,
                readinessStatus: 'on_track',
                itemCount: 3,
              ),
            ],
          ),
          referenceApi: _FakeReferenceApi(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Быстрая подготовка'), findsOneWidget);
    expect(find.text('Мои чек-листы'), findsNothing);
    expect(find.text('Стамбул, TR'), findsNothing);
    expect(checklistApi.getOrCreateCalls, 0);
  });

  testWidgets('shows saved checklists on dedicated list screen and opens one', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi();
    final cachedRouteArgs = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:istanbul:2026-07-10',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Istanbul',
        cityId: 'istanbul',
      ),
      startAt: DateTime.utc(2026, 7, 10, 9),
      endAt: DateTime.utc(2026, 7, 17, 18),
      transportModes: const ['flight'],
      activitySlugs: const ['culture'],
    );
    final checklistCache = _FakeChecklistOfflineCache(
      entries: [
        CachedTravelChecklistEntry(
          routeArgs: cachedRouteArgs,
          savedAt: DateTime.utc(2026, 6, 20, 12),
          readinessScore: 72,
          readinessStatus: 'on_track',
          itemCount: 3,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/me/checklists',
      routes: [
        GoRoute(
          path: '/me/checklists',
          builder: (context, state) => TravelChecklistListScreen(
            checklistApi: checklistApi,
            checklistCache: checklistCache,
          ),
        ),
        GoRoute(
          path: '/travel-checklist',
          builder: (context, state) {
            final routeArgs = state.extra is TravelChecklistRouteArgs
                ? state.extra! as TravelChecklistRouteArgs
                : null;
            return TravelChecklistScreen(
              checklistApi: checklistApi,
              checklistCache: checklistCache,
              referenceApi: _FakeReferenceApi(),
              routeArgs: routeArgs,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Мои чек-листы'), findsWidgets);
    expect(find.text('Стамбул, Турция'), findsOneWidget);
    expect(find.text('Istanbul, Турция'), findsNothing);
    expect(
      find.byKey(const ValueKey('travel-checklist-list-create')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        ValueKey('travel-checklist-recent-${cachedRouteArgs.normalizedTripId}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 1);
    expect(checklistApi.lastRequest?.tripId, cachedRouteArgs.normalizedTripId);
    expect(checklistApi.lastRequest?.destination.cityName, 'Istanbul');
  });

  testWidgets('refreshes saved checklist list after returning from details', (
    tester,
  ) async {
    final initialRouteArgs = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:istanbul:2026-07-10',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Istanbul',
        cityId: 'istanbul',
      ),
      destinationCountryName: 'Турция',
      startAt: DateTime.utc(2026, 7, 10, 9),
      endAt: DateTime.utc(2026, 7, 17, 18),
      transportModes: const ['flight'],
      activitySlugs: const ['culture'],
    );
    final refreshedRouteArgs = TravelChecklistRouteArgs(
      tripId: 'quick-prep:tr:antalya:2026-08-01',
      destination: const TripChecklistDestinationRequest(
        countryCode: 'TR',
        cityName: 'Antalya',
        cityId: 'antalya',
      ),
      destinationCountryName: 'Турция',
      startAt: DateTime.utc(2026, 8, 1, 9),
      endAt: DateTime.utc(2026, 8, 8, 18),
      transportModes: const ['flight'],
      activitySlugs: const ['beach'],
    );
    final checklistCache = _FakeChecklistOfflineCache(
      entries: [
        CachedTravelChecklistEntry(
          routeArgs: initialRouteArgs,
          savedAt: DateTime.utc(2026, 6, 20, 12),
          readinessScore: 72,
          readinessStatus: 'on_track',
          itemCount: 3,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/me/checklists',
      routes: [
        GoRoute(
          path: '/me/checklists',
          builder: (context, state) => TravelChecklistListScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: checklistCache,
          ),
        ),
        GoRoute(
          path: '/travel-checklist',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('return-from-checklist-details'),
                onPressed: () {
                  checklistCache.entries = [
                    CachedTravelChecklistEntry(
                      routeArgs: refreshedRouteArgs,
                      savedAt: DateTime.utc(2026, 6, 21, 12),
                      readinessScore: 40,
                      readinessStatus: 'not_ready',
                      itemCount: 5,
                    ),
                  ];
                  context.pop();
                },
                child: const Text('Back'),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Стамбул, Турция'), findsOneWidget);
    expect(checklistCache.listCalls, 1);

    await tester.tap(
      find.byKey(
        ValueKey(
          'travel-checklist-recent-${initialRouteArgs.normalizedTripId}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('return-from-checklist-details')),
    );
    await tester.pumpAndSettle();

    expect(checklistCache.listCalls, greaterThanOrEqualTo(2));
    expect(find.text('Анталья, Турция'), findsOneWidget);
    expect(find.text('Стамбул, Турция'), findsNothing);
  });

  testWidgets('loads my checklist list from server when local index is empty', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi(
      serverSummaries: [
        TripChecklistSummaryVm.fromJson({
          'instanceId': 'instance-1',
          'userId': 'user-42',
          'tripId': 'quick-prep:tr:istanbul:2026-07-10',
          'destination': {
            'countryCode': 'TR',
            'countryName': 'Турция',
            'cityName': 'Istanbul',
            'cityId': 'istanbul',
          },
          'startAt': '2026-07-10T09:00:00Z',
          'endAt': '2026-07-17T18:00:00Z',
          'transportModes': ['flight'],
          'activitySlugs': ['culture'],
          'hasChildren': false,
          'readiness': {'score': 72, 'status': 'on_track'},
          'itemCount': 3,
          'updatedAt': '2026-06-20T12:00:00Z',
        }),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistListScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.listTripChecklistCalls, 1);
    expect(find.text('Стамбул, Турция'), findsOneWidget);
    expect(find.text('Istanbul, Турция'), findsNothing);
  });

  testWidgets(
    'shows fallback country name for saved checklists without stored country name',
    (tester) async {
      final checklistApi = _FakeChecklistApi();
      final cachedRouteArgs = TravelChecklistRouteArgs(
        tripId: 'quick-prep:gr:athens:2026-07-21',
        destination: const TripChecklistDestinationRequest(
          countryCode: 'GR',
          cityName: 'Афины',
          cityId: 'athens',
        ),
        startAt: DateTime.utc(2026, 7, 21, 9),
        endAt: DateTime.utc(2026, 7, 28, 18),
        transportModes: const ['flight'],
        activitySlugs: const ['culture'],
      );
      final checklistCache = _FakeChecklistOfflineCache(
        entries: [
          CachedTravelChecklistEntry(
            routeArgs: cachedRouteArgs,
            savedAt: DateTime.utc(2026, 6, 20, 12),
            readinessScore: 19,
            readinessStatus: 'not_ready',
            itemCount: 3,
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/me/checklists',
        routes: [
          GoRoute(
            path: '/me/checklists',
            builder: (context, state) => TravelChecklistListScreen(
              checklistApi: _FakeChecklistApi(),
              checklistCache: checklistCache,
            ),
          ),
          GoRoute(
            path: '/travel-checklist',
            builder: (context, state) {
              final routeArgs = state.extra is TravelChecklistRouteArgs
                  ? state.extra! as TravelChecklistRouteArgs
                  : null;
              return TravelChecklistScreen(
                checklistApi: checklistApi,
                checklistCache: checklistCache,
                referenceApi: _FakeReferenceApi(),
                routeArgs: routeArgs,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Афины, Греция'), findsOneWidget);
      expect(find.text('Афины'), findsNothing);

      await tester.tap(
        find.byKey(
          ValueKey(
            'travel-checklist-recent-${cachedRouteArgs.normalizedTripId}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Афины, Греция'), findsOneWidget);
      expect(checklistApi.lastRequest?.destination.countryCode, 'GR');
    },
  );

  testWidgets('groups saved checklists by urgency and filters by source', (
    tester,
  ) async {
    final checklistCache = _FakeChecklistOfflineCache(
      entries: [
        CachedTravelChecklistEntry(
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'quick-prep:it:rome:2099-09-01',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'IT',
              cityName: 'Рим',
              cityId: 'rome',
            ),
            startAt: DateTime.utc(2099, 9, 1, 9),
            endAt: DateTime.utc(2099, 9, 7, 18),
          ),
          savedAt: DateTime.utc(2026, 6, 20, 12),
          readinessScore: 41,
          readinessStatus: 'at_risk',
          itemCount: 8,
        ),
        CachedTravelChecklistEntry(
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'activity:almaty-hike',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'KZ',
              cityName: 'Алматы',
              cityId: 'almaty',
            ),
            startAt: DateTime.utc(2099, 7, 1, 9),
            endAt: DateTime.utc(2099, 7, 1, 18),
          ),
          savedAt: DateTime.utc(2026, 6, 21, 12),
          readinessScore: 72,
          readinessStatus: 'on_track',
          itemCount: 5,
        ),
        CachedTravelChecklistEntry(
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'excursion_booking:bosphorus',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'TR',
              cityName: 'Istanbul',
              cityId: 'istanbul',
            ),
            startAt: DateTime.utc(2099, 6, 25, 9),
            endAt: DateTime.utc(2099, 6, 25, 13),
          ),
          savedAt: DateTime.utc(2026, 6, 21, 13),
          readinessScore: 88,
          readinessStatus: 'almost_ready',
          itemCount: 4,
        ),
        CachedTravelChecklistEntry(
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'activity:past-walk',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'FR',
              cityName: 'Париж',
              cityId: 'paris',
            ),
            startAt: DateTime.utc(2000, 1, 10, 9),
            endAt: DateTime.utc(2000, 1, 10, 13),
          ),
          savedAt: DateTime.utc(2026, 6, 19, 12),
          readinessScore: 100,
          readinessStatus: 'ready',
          itemCount: 2,
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: '/me/checklists',
      routes: [
        GoRoute(
          path: '/me/checklists',
          builder: (context, state) => TravelChecklistListScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: checklistCache,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ближайшие подготовки'), findsOneWidget);
    expect(find.text('Мои планы'), findsOneWidget);
    expect(find.text('Прошедшие'), findsOneWidget);
    expect(find.text('Экскурсия'), findsOneWidget);
    expect(find.text('Активность'), findsWidgets);
    expect(find.text('Мой чек-лист'), findsOneWidget);

    final istanbulTop = tester.getTopLeft(find.text('Стамбул, Турция')).dy;
    final almatyTop = tester.getTopLeft(find.text('Алматы, Казахстан')).dy;
    final romeTop = tester.getTopLeft(find.text('Рим, Италия')).dy;
    final parisTop = tester.getTopLeft(find.text('Париж, Франция')).dy;
    expect(istanbulTop, lessThan(almatyTop));
    expect(almatyTop, lessThan(romeTop));
    expect(romeTop, lessThan(parisTop));

    await tester.tap(find.text('Мои'));
    await tester.pumpAndSettle();

    expect(find.text('Рим, Италия'), findsOneWidget);
    expect(find.text('Стамбул, Турция'), findsNothing);
    expect(find.text('Алматы, Казахстан'), findsNothing);
  });

  testWidgets('list screen plus button opens quick preparation setup', (
    tester,
  ) async {
    final checklistCache = _FakeChecklistOfflineCache();
    final router = GoRouter(
      initialLocation: '/me/checklists',
      routes: [
        GoRoute(
          path: '/me/checklists',
          builder: (context, state) => TravelChecklistListScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: checklistCache,
          ),
        ),
        GoRoute(
          path: '/travel-checklist',
          builder: (context, state) => TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: checklistCache,
            referenceApi: _FakeReferenceApi(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('travel-checklist-list-create')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Быстрая подготовка'), findsOneWidget);
  });

  testWidgets('creates quick preparation context from checklist menu entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          referenceApi: _FakeReferenceApi(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 0);
    expect(find.text('Быстрая подготовка'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('quick-prep-country-code-field')),
      'тур',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Турция').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('quick-prep-city-field')),
      'ста',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Стамбул').last);
    await tester.pumpAndSettle();

    final transportFinder = find.byKey(
      const ValueKey('quick-prep-transport-train'),
    );
    await tester.ensureVisible(transportFinder);
    await tester.pumpAndSettle();
    await tester.tap(transportFinder);

    final activityFinder = find.byKey(
      const ValueKey('quick-prep-activity-culture'),
    );
    await tester.ensureVisible(activityFinder);
    await tester.pumpAndSettle();
    await tester.tap(activityFinder);

    final childrenFinder = find.byKey(
      const ValueKey('quick-prep-has-children'),
    );
    await tester.ensureVisible(childrenFinder);
    await tester.pumpAndSettle();
    await tester.tap(childrenFinder);
    await tester.ensureVisible(find.byKey(const ValueKey('quick-prep-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-prep-submit')));
    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 1);
    expect(checklistApi.lastRequest?.tripId, startsWith('quick-prep:'));
    expect(checklistApi.lastRequest?.destination.countryCode, 'TR');
    expect(checklistApi.lastRequest?.destination.cityName, 'Стамбул');
    expect(checklistApi.lastRequest?.destination.cityId, 'istanbul');
    expect(checklistApi.lastRequest?.transportModes, ['train']);
    expect(checklistApi.lastRequest?.activitySlugs, ['culture']);
    expect(checklistApi.lastRequest?.hasChildren, isTrue);
    expect(checklistApi.lastRequest?.preferredLanguage, 'ru');
    expect(find.text('Для какой поездки'), findsOneWidget);
    expect(find.text('Стамбул, Турция'), findsOneWidget);
    expect(find.text('Культура'), findsOneWidget);
    expect(find.text('Поезд'), findsOneWidget);
    expect(find.text('С детьми'), findsOneWidget);
  });

  testWidgets(
    'opens existing manual checklist instead of duplicating quick preparation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final today = DateTime.now().toUtc();
      final startDate = DateTime.utc(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 30));
      final endDate = startDate.add(const Duration(days: 7));
      final existingRouteArgs = TravelChecklistRouteArgs(
        tripId: 'quick-prep:existing-istanbul',
        destination: const TripChecklistDestinationRequest(
          countryCode: 'TR',
          cityName: 'Стамбул',
          cityId: 'istanbul',
        ),
        destinationCountryName: 'Турция',
        startAt: DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day,
          9,
        ),
        endAt: DateTime.utc(endDate.year, endDate.month, endDate.day, 18),
        transportModes: const ['flight'],
      );
      final checklistApi = _FakeChecklistApi();
      final checklistCache = _FakeChecklistOfflineCache(
        entries: [
          CachedTravelChecklistEntry(
            routeArgs: existingRouteArgs,
            savedAt: DateTime.utc(2026, 6, 20, 12),
            readinessScore: 64,
            readinessStatus: 'at_risk',
            itemCount: 5,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: checklistCache,
            referenceApi: _FakeReferenceApi(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-country-code-field')),
        'тур',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Турция').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-city-field')),
        'ста',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Стамбул').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('quick-prep-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-prep-submit')));
      await tester.pumpAndSettle();

      expect(checklistApi.getOrCreateCalls, 1);
      expect(checklistApi.lastRequest?.tripId, 'quick-prep:existing-istanbul');
      expect(
        find.text('У вас уже есть подготовка для этой поездки.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps same-day activity checklists separate and distinguishes their time',
    (tester) async {
      final morningStart = DateTime.utc(2099, 7, 10, 9);
      final morningEnd = DateTime.utc(2099, 7, 10, 11);
      final eveningStart = DateTime.utc(2099, 7, 10, 18);
      final eveningEnd = DateTime.utc(2099, 7, 10, 20);
      final checklistCache = _FakeChecklistOfflineCache(
        entries: [
          CachedTravelChecklistEntry(
            routeArgs: TravelChecklistRouteArgs(
              tripId: 'activity:istanbul-morning-walk',
              destination: const TripChecklistDestinationRequest(
                countryCode: 'TR',
                cityName: 'Стамбул',
                cityId: 'istanbul',
              ),
              startAt: morningStart,
              endAt: morningEnd,
            ),
            savedAt: DateTime.utc(2026, 6, 21, 12),
            readinessScore: 40,
            readinessStatus: 'at_risk',
            itemCount: 6,
          ),
          CachedTravelChecklistEntry(
            routeArgs: TravelChecklistRouteArgs(
              tripId: 'activity:istanbul-evening-food',
              destination: const TripChecklistDestinationRequest(
                countryCode: 'TR',
                cityName: 'Стамбул',
                cityId: 'istanbul',
              ),
              startAt: eveningStart,
              endAt: eveningEnd,
            ),
            savedAt: DateTime.utc(2026, 6, 21, 13),
            readinessScore: 80,
            readinessStatus: 'on_track',
            itemCount: 4,
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/me/checklists',
        routes: [
          GoRoute(
            path: '/me/checklists',
            builder: (context, state) => TravelChecklistListScreen(
              checklistApi: _FakeChecklistApi(),
              checklistCache: checklistCache,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Стамбул, Турция'), findsNWidgets(2));
      expect(find.text('Активность'), findsNWidgets(2));
      expect(
        find.textContaining(
          _expectedSameDayDateTimeLabel(morningStart, morningEnd),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          _expectedSameDayDateTimeLabel(eveningStart, eveningEnd),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'travel-checklist-recent-activity:istanbul-morning-walk',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'travel-checklist-recent-activity:istanbul-evening-food',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'uses localized destination dropdowns and selected Amber control text color',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final checklistApi = _FakeChecklistApi();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
            referenceApi: _FakeReferenceApi(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Например: Турция'), findsOneWidget);
      expect(find.text('Например: Стамбул'), findsOneWidget);
      expect(find.text('Например: TR'), findsNothing);

      final selectedFlightLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('quick-prep-transport-flight')),
          matching: find.text('Самолет'),
        ),
      );
      expect(
        selectedFlightLabel.style?.color,
        AppColorSchemes.light.textPrimary,
      );

      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-country-code-field')),
        'тур',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Турция').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-city-field')),
        'ста',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Стамбул').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('quick-prep-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-prep-submit')));
      await tester.pumpAndSettle();

      expect(checklistApi.getOrCreateCalls, 1);
      expect(checklistApi.lastRequest?.destination.countryCode, 'TR');
      expect(checklistApi.lastRequest?.destination.cityName, 'Стамбул');
      expect(checklistApi.lastRequest?.destination.cityId, 'istanbul');
    },
  );

  testWidgets('searches quick preparation destination in reference catalog', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          referenceApi: _FakeReferenceApi(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('quick-prep-country-code-field')),
      'бра',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бразилия').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('quick-prep-city-field')),
      'рио',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рио-де-Жанейро').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('quick-prep-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-prep-submit')));
    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 1);
    expect(checklistApi.lastRequest?.destination.countryCode, 'BR');
    expect(checklistApi.lastRequest?.destination.cityName, 'Рио-де-Жанейро');
    expect(checklistApi.lastRequest?.destination.cityId, 'rio-de-janeiro');
  });

  testWidgets(
    'does not force uppercase for quick preparation destination input',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: _FakeChecklistOfflineCache(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.length, greaterThanOrEqualTo(2));
      expect(fields.elementAt(0).textCapitalization, TextCapitalization.words);
      expect(fields.elementAt(1).textCapitalization, TextCapitalization.words);
    },
  );

  testWidgets(
    'clears partial destination input when dropdown option was not selected',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final checklistApi = _FakeChecklistApi();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
            referenceApi: _FakeReferenceApi(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-country-code-field')),
        'тур',
      );
      await tester.enterText(
        find.byKey(const ValueKey('quick-prep-city-field')),
        'ста',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('quick-prep-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-prep-submit')));
      await tester.pumpAndSettle();

      expect(find.text('тур'), findsNothing);
      expect(find.text('ста'), findsNothing);
      expect(checklistApi.getOrCreateCalls, 0);
      expect(find.text('Выберите страну.'), findsOneWidget);
      expect(find.text('Укажите город.'), findsOneWidget);
    },
  );

  testWidgets(
    'transport chips are content-sized without shifting when selected',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: _FakeChecklistOfflineCache(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final trainFinder = find.byKey(
        const ValueKey('quick-prep-transport-train'),
      );
      final carFinder = find.byKey(const ValueKey('quick-prep-transport-car'));
      final busFinder = find.byKey(const ValueKey('quick-prep-transport-bus'));
      final motorcycleFinder = find.byKey(
        const ValueKey('quick-prep-transport-motorcycle'),
      );
      final ferryFinder = find.byKey(
        const ValueKey('quick-prep-transport-ferry'),
      );
      final otherFinder = find.byKey(
        const ValueKey('quick-prep-transport-other'),
      );
      await tester.ensureVisible(trainFinder);
      await tester.pumpAndSettle();

      final unselectedBusChip = tester.widget<FilterChip>(
        find.descendant(of: busFinder, matching: find.byType(FilterChip)),
      );
      expect(unselectedBusChip.avatar, isNull);
      expect(find.text('Мотоцикл'), findsOneWidget);
      expect(find.text('Паром'), findsOneWidget);
      expect(find.text('Другое'), findsOneWidget);
      expect(motorcycleFinder, findsOneWidget);
      expect(ferryFinder, findsOneWidget);
      expect(otherFinder, findsOneWidget);

      final carChipFinder = find.descendant(
        of: carFinder,
        matching: find.byType(FilterChip),
      );
      final carRectBeforeSelection = tester.getRect(carChipFinder);

      await tester.tap(trainFinder);
      await tester.pumpAndSettle();

      final carRectAfterSelection = tester.getRect(carChipFinder);
      expect(carRectAfterSelection.topLeft, carRectBeforeSelection.topLeft);

      final selectedTrainChip = tester.widget<FilterChip>(
        find.descendant(of: trainFinder, matching: find.byType(FilterChip)),
      );
      expect(selectedTrainChip.avatar, isNull);
      expect(
        find.descendant(
          of: trainFinder,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('opens quick preparation date picker with Amber theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: _FakeChecklistApi(),
          checklistCache: _FakeChecklistOfflineCache(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('quick-prep-start-date')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-prep-start-date')));
    await tester.pumpAndSettle();

    final theme = tester.widget<Theme>(
      find.byKey(const ValueKey('quick-prep-date-picker-amber-theme')),
    );
    final datePickerTheme = theme.data.datePickerTheme;
    expect(datePickerTheme.backgroundColor, AppColorSchemes.light.surface);
    expect(
      datePickerTheme.headerBackgroundColor,
      AppColorSchemes.light.primary,
    );
    expect(
      datePickerTheme.headerForegroundColor,
      AppColorSchemes.light.textPrimary,
    );
    expect(
      datePickerTheme.dayForegroundColor?.resolve({WidgetState.selected}),
      AppColorSchemes.light.textPrimary,
    );
  });

  testWidgets('renders readiness, seasonal profile, and carry item search', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 1);
    expect(find.text('Подготовка к поездке'), findsOneWidget);
    expect(find.textContaining('Inflap собирает no-paid'), findsNothing);
    expect(find.text('Для какой поездки'), findsOneWidget);
    expect(find.text('Токио, Япония'), findsOneWidget);
    expect(find.text('Самолет'), findsOneWidget);
    expect(find.text('Хайкинг'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.text('Не готово'), findsOneWidget);
    expect(find.text('not_ready'), findsNothing);
    expect(find.text('Нужна проверка'), findsOneWidget);
    expect(checklistApi.reminderListCalls, 0);
    expect(find.text('Напоминания'), findsNothing);
    expect(find.text('За 30 дн. до поездки'), findsNothing);
    expect(find.text('Дата: 2026-06-11'), findsNothing);
    expect(find.text('Жарко'), findsOneWidget);
    expect(find.text('Дождливо'), findsOneWidget);
    expect(find.text('Переменная облачность'), findsOneWidget);
    expect(find.text('Влажно'), findsOneWidget);
    expect(find.text('Защита от жары и дождя'), findsOneWidget);
    expect(find.text('Легкая одежда'), findsOneWidget);
    expect(find.text('Важное'), findsWidgets);
    expect(find.text('important'), findsNothing);
    expect(find.text('hot'), findsNothing);
    expect(find.text('rainy'), findsNothing);
    expect(find.text('mixed'), findsNothing);
    expect(find.text('humid'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('carry-search-field')),
    );
    await tester.pumpAndSettle();
    final carrySearchField = tester.widget<TextField>(
      find.byKey(const ValueKey('carry-search-field')),
    );
    expect(carrySearchField.controller?.text, isEmpty);
    expect(
      carrySearchField.decoration?.hintText,
      'Повербанк, жидкости, ножницы',
    );
    final carrySearchButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('carry-search-submit')),
    );
    expect(
      carrySearchButton.style?.foregroundColor?.resolve({}),
      AppColorSchemes.light.textPrimary,
    );
    await tester.enterText(
      find.byKey(const ValueKey('carry-search-field')),
      'power bank',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('carry-search-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('carry-search-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Повербанк'), findsOneWidget);
    expect(find.text('power_bank'), findsNothing);
    expect(find.textContaining('Запрещено'), findsOneWidget);
  });

  testWidgets('renders excursion checklist preview as read-only details', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi();
    final checklistCache = _FakeChecklistOfflineCache();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: checklistCache,
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'excursion_preview:product-1:offer-1',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'TR',
              cityName: 'Istanbul',
              cityId: 'istanbul',
            ),
            startAt: DateTime.utc(2026, 11, 9, 9),
            endAt: DateTime.utc(2026, 11, 9, 12),
            transportModes: const ['flight', 'walking'],
            activitySlugs: const ['culture', 'walking'],
            isPreview: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.previewCalls, 1);
    expect(checklistApi.getOrCreateCalls, 0);
    expect(checklistCache.savedTripIds, isEmpty);
    expect(find.text('Предпросмотр'), findsWidgets);
    expect(find.text('Выбирается при бронировании'), findsOneWidget);
    expect(find.text('Защита от жары и дождя'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('travel-checklist-add-custom-item')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey(
          'checklist-item-feedback-helpful-weather.tokyo_july_rain_heat',
        ),
      ),
      findsNothing,
    );

    final previewToggleFinder = find.byKey(
      const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
    );
    await tester.ensureVisible(previewToggleFinder);
    await tester.pumpAndSettle();
    await tester.tap(previewToggleFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(checklistApi.updatedTripId, isNull);
    expect(checklistApi.assignedTripId, isNull);
  });

  testWidgets('shows separate personal progress in readiness block', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi(hasCustomItem: true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Системная готовность'), findsOneWidget);
    expect(find.text('Личные пункты: 0 из 1'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('adds custom checklist item from bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = find.byKey(
      const ValueKey('travel-checklist-add-custom-item'),
    );
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-checklist-item-title-field')),
      'Зарядка для камеры',
    );
    await tester.tap(
      find.byKey(const ValueKey('custom-checklist-item-additional-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-checklist-item-note-field')),
      'USB-C',
    );
    await tester.tap(
      find.byKey(const ValueKey('custom-checklist-item-reuse-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('custom-checklist-item-save')));
    await tester.pumpAndSettle();

    expect(checklistApi.createdCustomTitle, 'Зарядка для камеры');
    expect(checklistApi.createdCustomNote, 'USB-C');
    expect(checklistApi.createdCustomReuseInFuture, isTrue);
    expect(find.text('Зарядка для камеры'), findsOneWidget);
    expect(find.text('Мое'), findsOneWidget);
    expect(find.text('Личные пункты: 0 из 1'), findsOneWidget);
  });

  testWidgets('custom item sheet stays readable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(1.35),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: TravelChecklistScreen(
          checklistApi: _FakeChecklistApi(),
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = find.byKey(
      const ValueKey('travel-checklist-add-custom-item'),
    );
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('custom-checklist-item-title-field')),
      'Зарядка',
    );
    await tester.tap(
      find.byKey(const ValueKey('custom-checklist-item-additional-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-checklist-item-note-field')),
      'USB-C',
    );
    await tester.pumpAndSettle();

    final noteField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('custom-checklist-item-note-field')),
        matching: find.byType(TextField),
      ),
    );
    final noteDecoration = noteField.decoration;
    expect(noteDecoration?.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(
      noteDecoration?.contentPadding,
      const EdgeInsets.fromLTRB(14, 24, 14, 18),
    );
    FlutterError.onError = previousOnError;
    expect(find.text('Важное'), findsWidgets);
    expect(find.text('Рекомендуем'), findsOneWidget);
    expect(find.text('Опционально'), findsOneWidget);
    expect(
      flutterErrors.where(
        (error) =>
            error.exceptionAsString().contains('overflowed') ||
            error.exceptionAsString().contains('RenderFlex'),
      ),
      isEmpty,
    );
  });

  testWidgets('filters system and custom checklist items by search query', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi(hasCustomItem: true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final searchField = find.byKey(
      const ValueKey('travel-checklist-items-search-field'),
    );
    await tester.ensureVisible(searchField);
    await tester.enterText(searchField, 'камера');
    await tester.pumpAndSettle();

    expect(
      find.text('Зарядка для камеры', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Защита от жары и дождя', skipOffstage: false),
      findsNothing,
    );

    await tester.enterText(searchField, 'дождь');
    await tester.pumpAndSettle();

    expect(find.text('Зарядка для камеры', skipOffstage: false), findsNothing);
    expect(
      find.text('Защита от жары и дождя', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('shows country name instead of country code in trip context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: _FakeChecklistApi(),
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'quick-prep:tr:istanbul:2026-07-10',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'TR',
              cityName: 'Istanbul',
              cityId: 'istanbul',
            ),
            destinationCountryName: 'Турция',
            startAt: DateTime.utc(2026, 7, 10, 9),
            endAt: DateTime.utc(2026, 7, 17, 18),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Стамбул, Турция'), findsWidgets);
    expect(find.text('Istanbul, Турция'), findsNothing);
    expect(find.text('Стамбул, TR'), findsNothing);
  });

  testWidgets(
    'localizes activity context chips from activity checklist slugs',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: _FakeChecklistOfflineCache(),
            routeArgs: TravelChecklistRouteArgs(
              tripId: 'activity:almaty-culture',
              destination: const TripChecklistDestinationRequest(
                countryCode: 'KZ',
                cityName: 'Алматы',
                cityId: 'almaty',
              ),
              startAt: DateTime.utc(2026, 6, 22, 14),
              endAt: DateTime.utc(2026, 6, 22, 16),
              transportModes: const ['flight'],
              activitySlugs: const [
                'culture-art',
                'museum-gallery',
                'OFFLINE',
                'activity-flow',
                'qa',
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Культура'), findsOneWidget);
      expect(find.text('Музеи'), findsOneWidget);
      expect(find.text('Офлайн'), findsOneWidget);
      expect(find.text('Culture-art'), findsNothing);
      expect(find.text('Museum-gallery'), findsNothing);
      expect(find.text('Activity-flow'), findsNothing);
      expect(find.text('Qa'), findsNothing);
    },
  );

  testWidgets('toggles custom checklist item without resetting scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi(hasCustomItem: true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final customToggle = find.byKey(
      const ValueKey('custom-checklist-item-toggle-custom-1'),
    );
    await tester.ensureVisible(customToggle);
    await tester.pumpAndSettle();
    final beforeTapY = tester.getTopLeft(customToggle).dy;

    await tester.tap(customToggle);
    await tester.pumpAndSettle();

    expect(checklistApi.updatedCustomItemId, 'custom-1');
    expect(checklistApi.updatedCustomStatus, 'done');
    expect(tester.getTopLeft(customToggle).dy, closeTo(beforeTapY, 1));
    expect(find.text('Личные пункты: 1 из 1'), findsOneWidget);
  });

  testWidgets('adapts full checklist across representative mobile widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    for (final scenario in const [
      _LayoutScenario(size: Size(320, 860), textScale: 1.45),
      _LayoutScenario(size: Size(390, 844), textScale: 1.35),
      _LayoutScenario(size: Size(430, 932), textScale: 1.25),
    ]) {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scenario.textScale),
              ),
              child: child!,
            );
          },
          home: TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(useLongContent: true),
            checklistCache: _FakeChecklistOfflineCache(),
            routeArgs: _compactStressRouteArgs(),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }
    FlutterError.onError = previousOnError;

    final overflowErrors = flutterErrors.where(
      (details) => details.exceptionAsString().contains('overflowed'),
    );
    expect(overflowErrors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'adapts checklist setup state on compact mobile width with increased text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final flutterErrors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = flutterErrors.add;
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.45),
              ),
              child: child!,
            );
          },
          home: TravelChecklistScreen(
            checklistApi: _FakeChecklistApi(),
            checklistCache: _FakeChecklistOfflineCache(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      FlutterError.onError = previousOnError;

      final overflowErrors = flutterErrors.where(
        (details) => details.exceptionAsString().contains('overflowed'),
      );
      expect(overflowErrors, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toggles checklist item status through persisted API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final toggleFinder = find.byKey(
      const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
    );
    expect(
      find.byKey(
        const ValueKey(
          'checklist-item-assignment-weather.tokyo_july_rain_heat',
        ),
      ),
      findsNothing,
    );
    final initialCheckbox = tester.widget<Checkbox>(toggleFinder);
    expect(initialCheckbox.checkColor, AppColorSchemes.light.textPrimary);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(checklistApi.updatedTripId, 'sample-tokyo-july');
    expect(checklistApi.updatedItemId, 'weather.tokyo_july_rain_heat');
    expect(checklistApi.updatedStatus, 'done');
    expect(checklistApi.assignedTripId, 'sample-tokyo-july');
    expect(checklistApi.assignedItemId, 'weather.tokyo_july_rain_heat');
    expect(checklistApi.assignedToMe, isTrue);
    final checkbox = tester.widget<Checkbox>(
      find.byKey(
        const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
      ),
    );
    expect(checkbox.value, isTrue);
  });

  testWidgets('submits checklist item feedback from item tile', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final feedbackFinder = find.byKey(
      const ValueKey(
        'checklist-item-feedback-helpful-weather.tokyo_july_rain_heat',
      ),
    );
    await tester.ensureVisible(feedbackFinder);
    await tester.pumpAndSettle();
    await tester.tap(feedbackFinder);
    await tester.pumpAndSettle();

    expect(checklistApi.submittedFeedbackTripId, 'sample-tokyo-july');
    expect(
      checklistApi.submittedFeedbackItemId,
      'weather.tokyo_july_rain_heat',
    );
    expect(
      checklistApi.submittedFeedbackType,
      ChecklistItemFeedbackType.helpful,
    );
    expect(
      find.text('Отзыв учтен: будем чаще показывать такие пункты.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'marks checklist item feedback as selected and ignores repeated taps',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final checklistApi = _FakeChecklistApi();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
            routeArgs: _sampleRouteArgs(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final helpfulFinder = find.byKey(
        const ValueKey(
          'checklist-item-feedback-helpful-weather.tokyo_july_rain_heat',
        ),
      );
      final notHelpfulFinder = find.byKey(
        const ValueKey(
          'checklist-item-feedback-not-helpful-weather.tokyo_july_rain_heat',
        ),
      );
      await tester.ensureVisible(helpfulFinder);
      await tester.pumpAndSettle();

      await tester.tap(helpfulFinder);
      await tester.pumpAndSettle();

      expect(checklistApi.submittedFeedbackCalls, 1);
      expect(
        find.descendant(
          of: helpfulFinder,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(helpfulFinder);
      await tester.pumpAndSettle();

      expect(checklistApi.submittedFeedbackCalls, 1);

      await tester.tap(notHelpfulFinder);
      await tester.pumpAndSettle();

      expect(checklistApi.submittedFeedbackCalls, 2);
      expect(
        find.descendant(
          of: notHelpfulFinder,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: helpfulFinder,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsNothing,
      );
      expect(
        checklistApi.submittedFeedbackType,
        ChecklistItemFeedbackType.notHelpful,
      );
    },
  );

  testWidgets('hides assignment button on personal checklist items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'checklist-item-assignment-weather.tokyo_july_rain_heat',
        ),
      ),
      findsNothing,
    );
    expect(find.text('Возьму'), findsNothing);
    expect(checklistApi.assignedTripId, isNull);
  });

  testWidgets('keeps checklist scroll position after item actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final assignmentFinder = find.byKey(
      const ValueKey('checklist-item-assignment-weather.tokyo_july_rain_heat'),
    );
    expect(assignmentFinder, findsNothing);
    final toggleFinder = find.byKey(
      const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
    );
    await tester.ensureVisible(toggleFinder);
    await tester.pumpAndSettle();
    final beforeTapY = tester.getTopLeft(toggleFinder).dy;

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(checklistApi.assignedToMe, isTrue);
    expect(tester.getTopLeft(toggleFinder).dy, closeTo(beforeTapY, 1));
  });

  testWidgets(
    'keeps checklist checkbox mounted while status update is pending',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final statusUpdateCompleter = Completer<void>();
      final checklistApi = _FakeChecklistApi(
        statusUpdateCompleter: statusUpdateCompleter,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
            routeArgs: _sampleRouteArgs(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(
        const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
      );
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      final beforeTapY = tester.getTopLeft(checkboxFinder).dy;

      await tester.tap(checkboxFinder);
      await tester.pump();

      expect(checkboxFinder, findsOneWidget);
      expect(tester.getTopLeft(checkboxFinder).dy, closeTo(beforeTapY, 1));

      statusUpdateCompleter.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('uses Amber floating snackbar style for checklist messages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: _FakeChecklistApi(),
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: _sampleRouteArgs(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final feedbackFinder = find.byKey(
      const ValueKey(
        'checklist-item-feedback-helpful-weather.tokyo_july_rain_heat',
      ),
    );
    await tester.ensureVisible(feedbackFinder);
    await tester.pumpAndSettle();
    await tester.tap(feedbackFinder);
    await tester.pumpAndSettle();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, AppColorSchemes.light.surfaceRaised);
    expect(snackBar.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets(
    'keeps checklist content mounted when auto assignment response returns',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final assignmentCompleter = Completer<void>();
      final checklistApi = _FakeChecklistApi(
        assignmentCompleter: assignmentCompleter,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelChecklistScreen(
            checklistApi: checklistApi,
            checklistCache: _FakeChecklistOfflineCache(),
            routeArgs: _sampleRouteArgs(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(
        const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
      );
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      final beforeResponseY = tester.getTopLeft(checkboxFinder).dy;

      await tester.tap(checkboxFinder);
      await tester.pump();
      assignmentCompleter.complete();
      await tester.pump();

      expect(checkboxFinder, findsOneWidget);
      expect(tester.getTopLeft(checkboxFinder).dy, closeTo(beforeResponseY, 1));
    },
  );

  testWidgets('uses route args for persisted load and item updates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checklistApi = _FakeChecklistApi();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: _FakeChecklistOfflineCache(),
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'activity:act-42',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'TR',
              cityName: 'Istanbul',
              cityId: 'istanbul',
            ),
            startAt: DateTime.utc(2026, 11, 9, 9),
            endAt: DateTime.utc(2026, 11, 9, 12),
            transportModes: const ['flight'],
            activitySlugs: const ['culture', 'walking'],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.lastRequest?.tripId, 'activity:act-42');
    expect(checklistApi.lastRequest?.destination.countryCode, 'TR');
    expect(checklistApi.lastRequest?.destination.cityName, 'Istanbul');
    expect(checklistApi.lastRequest?.destination.cityId, 'istanbul');
    expect(checklistApi.lastRequest?.startAt, DateTime.utc(2026, 11, 9, 9));
    expect(checklistApi.lastRequest?.endAt, DateTime.utc(2026, 11, 9, 12));
    expect(checklistApi.lastRequest?.transportModes, ['flight']);
    expect(checklistApi.lastRequest?.activitySlugs, ['culture', 'walking']);
    expect(checklistApi.lastRequest?.preferredLanguage, 'en');

    await tester.tap(
      find.byKey(
        const ValueKey('checklist-item-toggle-weather.tokyo_july_rain_heat'),
      ),
    );
    await tester.pumpAndSettle();

    expect(checklistApi.updatedTripId, 'activity:act-42');
  });

  testWidgets('renders cached checklist when persisted load fails', (
    tester,
  ) async {
    final checklistApi = _FakeChecklistApi(shouldFailLoad: true);
    final checklistCache = _FakeChecklistOfflineCache(
      cached: _cachedChecklist(),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelChecklistScreen(
          checklistApi: checklistApi,
          checklistCache: checklistCache,
          routeArgs: TravelChecklistRouteArgs(
            tripId: 'activity:act-42',
            destination: const TripChecklistDestinationRequest(
              countryCode: 'TR',
              cityName: 'Istanbul',
            ),
            startAt: DateTime.utc(2026, 11, 9, 9),
            endAt: DateTime.utc(2026, 11, 9, 12),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(checklistApi.getOrCreateCalls, 1);
    expect(checklistCache.readTripIds, ['activity:act-42']);
    expect(find.text('Offline copy'), findsWidgets);
    expect(find.text('Cached passport'), findsOneWidget);
    expect(find.textContaining('64%'), findsOneWidget);
  });
}

TravelChecklistRouteArgs _sampleRouteArgs() {
  return TravelChecklistRouteArgs.sample(now: DateTime.utc(2026));
}

TravelChecklistRouteArgs _compactStressRouteArgs() {
  return TravelChecklistRouteArgs(
    tripId: 'compact-stress-trip',
    destination: const TripChecklistDestinationRequest(
      countryCode: 'KZ',
      cityName: 'Алматы',
      cityId: 'almaty',
    ),
    startAt: DateTime.utc(2026, 12, 24, 9),
    endAt: DateTime.utc(2026, 12, 31, 21),
    transportModes: const ['flight', 'train'],
    activitySlugs: const ['walking', 'hiking', 'culture', 'museum'],
    hasChildren: true,
  );
}

String _expectedSameDayDateTimeLabel(DateTime startAt, DateTime endAt) {
  final start = startAt.toLocal();
  final end = endAt.toLocal();
  final year = start.year.toString().padLeft(4, '0');
  final month = start.month.toString().padLeft(2, '0');
  final day = start.day.toString().padLeft(2, '0');
  final startHour = start.hour.toString().padLeft(2, '0');
  final startMinute = start.minute.toString().padLeft(2, '0');
  final endHour = end.hour.toString().padLeft(2, '0');
  final endMinute = end.minute.toString().padLeft(2, '0');
  return '$year-$month-$day, $startHour:$startMinute - $endHour:$endMinute';
}

class _LayoutScenario {
  const _LayoutScenario({required this.size, required this.textScale});

  final Size size;
  final double textScale;
}

class _FakeChecklistApi extends ChecklistApi {
  _FakeChecklistApi({
    this.shouldFailLoad = false,
    this.useLongContent = false,
    this.hasCustomItem = false,
    this.serverSummaries = const [],
    this.assignmentCompleter,
    this.statusUpdateCompleter,
  });

  final bool shouldFailLoad;
  final bool useLongContent;
  bool hasCustomItem;
  final List<TripChecklistSummaryVm> serverSummaries;
  final Completer<void>? assignmentCompleter;
  final Completer<void>? statusUpdateCompleter;
  int previewCalls = 0;
  int getOrCreateCalls = 0;
  int listTripChecklistCalls = 0;
  bool _isDone = false;
  bool _assignedToMe = false;
  TripChecklistPreviewRequest? lastRequest;
  String? updatedTripId;
  String? updatedItemId;
  String? updatedStatus;
  String? submittedFeedbackTripId;
  String? submittedFeedbackItemId;
  int submittedFeedbackCalls = 0;
  ChecklistItemFeedbackType? submittedFeedbackType;
  String? assignedTripId;
  String? assignedItemId;
  bool? assignedToMe;
  int reminderListCalls = 0;
  String? createdCustomTitle;
  String? createdCustomNote;
  bool? createdCustomReuseInFuture;
  String? updatedCustomItemId;
  String? updatedCustomStatus;
  bool _customItemDone = false;

  @override
  Future<TripChecklistVm> previewTripChecklist(
    TripChecklistPreviewRequest request,
  ) async {
    previewCalls += 1;
    lastRequest = request;
    return _checklist();
  }

  @override
  Future<TripChecklistVm> getOrCreateTripChecklist(
    TripChecklistPreviewRequest request,
  ) async {
    getOrCreateCalls += 1;
    lastRequest = request;
    if (shouldFailLoad) {
      throw StateError('network unavailable');
    }
    return _checklist();
  }

  @override
  Future<List<TripChecklistSummaryVm>> listTripChecklists({
    String locale = 'ru',
    int limit = 50,
  }) async {
    listTripChecklistCalls += 1;
    return serverSummaries.take(limit).toList(growable: false);
  }

  @override
  Future<TripChecklistVm> updateChecklistItemStatus({
    required String tripId,
    required String itemId,
    required String status,
    String locale = 'ru',
  }) async {
    await statusUpdateCompleter?.future;
    updatedTripId = tripId;
    updatedItemId = itemId;
    updatedStatus = status;
    _isDone = status == 'done';
    return _checklist();
  }

  @override
  Future<TripChecklistVm> setChecklistItemAssignment({
    required String tripId,
    required String itemId,
    required bool assignToMe,
    String locale = 'ru',
  }) async {
    await assignmentCompleter?.future;
    assignedTripId = tripId;
    assignedItemId = itemId;
    assignedToMe = assignToMe;
    _assignedToMe = assignToMe;
    return _checklist();
  }

  @override
  Future<TripChecklistVm> createCustomChecklistItem({
    required String tripId,
    required CustomChecklistItemRequest request,
    String locale = 'ru',
  }) async {
    createdCustomTitle = request.title.trim();
    createdCustomNote = request.note.trim();
    createdCustomReuseInFuture = request.reuseInFuture;
    hasCustomItem = true;
    _customItemDone = false;
    return _checklist();
  }

  @override
  Future<TripChecklistVm> updateCustomChecklistItemStatus({
    required String tripId,
    required String itemId,
    required String status,
    String locale = 'ru',
  }) async {
    updatedCustomItemId = itemId;
    updatedCustomStatus = status;
    _customItemDone = status == 'done';
    hasCustomItem = true;
    return _checklist();
  }

  @override
  Future<ChecklistReminderListVm> listTripChecklistReminders({
    required String tripId,
    String locale = 'ru',
  }) async {
    reminderListCalls += 1;
    return ChecklistReminderListVm.fromJson(const {
      'items': [
        {
          'id': 'trip-30-days-before',
          'offsetDays': 30,
          'dueAt': '2026-06-11T10:00:00Z',
          'status': 'scheduled',
          'title': 'Проверка документов',
          'message': 'Проверьте паспорт и брони',
        },
      ],
    });
  }

  TripChecklistVm _checklist() {
    final title = useLongContent
        ? 'Проверка документов, лекарств, теплой одежды и вещей для ребенка'
        : 'Защита от жары и дождя';
    final reason = useLongContent
        ? 'Этот пункт добавлен из-за перелета, зимней поездки, прогулок, хайкинга и путешествия с детьми. Проверьте все заранее, чтобы не искать важные вещи перед выездом.'
        : 'В июле в Токио обычно жарко и дождливо.';
    final packingImplications = useLongContent
        ? [
            'Теплые слои одежды для вечерних прогулок',
            'Компактная аптечка и документы ребенка',
            'Защита от дождя и сменная обувь',
          ]
        : ['Легкая одежда'];

    return TripChecklistVm.fromJson({
      'instanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': 'sample-tokyo-july',
      'readiness': {
        'score': _isDone ? 76 : 50,
        'status': _isDone ? 'on_track' : 'not_ready',
        'blockers': const [],
      },
      'trustNotice': const {
        'code': 'official_source_required',
        'title': 'Нужна проверка',
        'message': 'Проверьте официальные источники',
      },
      'items': [
        {
          'id': 'weather.tokyo_july_rain_heat',
          'category': 'weather',
          'priority': 'important',
          'status': _isDone ? 'done' : 'open',
          if (_assignedToMe) 'assignedUserId': 'user-42',
          'title': title,
          'reason': reason,
          'trustLevel': 'verified_curated',
          'requiresUserConfirmation': false,
          'source': const {'confidence': 'medium'},
        },
      ],
      'customItems': [
        if (hasCustomItem)
          {
            'id': 'custom-1',
            'title': createdCustomTitle ?? 'Зарядка для камеры',
            'note': createdCustomNote ?? 'USB-C',
            'category': 'custom',
            'priority': 'recommended',
            'status': _customItemDone ? 'done' : 'open',
            'reuseInFuture': createdCustomReuseInFuture ?? true,
            'createdAt': '2026-06-21T10:00:00Z',
            'updatedAt': '2026-06-21T10:05:00Z',
          },
      ],
      'personalProgress': {
        'total': hasCustomItem ? 1 : 0,
        'done': hasCustomItem && _customItemDone ? 1 : 0,
        'percent': hasCustomItem && _customItemDone ? 100 : 0,
      },
      'seasonalProfile': {
        'month': 7,
        'temperatureBand': 'hot',
        'precipitationBand': 'rainy',
        'skyBand': 'mixed',
        'riskTags': const ['humid'],
        'packingImplications': packingImplications,
        'source': const {'confidence': 'medium'},
      },
      'generatedAt': '2026-06-20T00:00:00Z',
    });
  }

  @override
  Future<CarryItemPolicyListVm> searchCarryItems({
    required String query,
    String transportMode = 'flight',
    String locale = 'ru',
  }) async {
    return CarryItemPolicyListVm.fromJson(const {
      'items': [
        {
          'itemSlug': 'power_bank',
          'carryOn': 'allowed_with_conditions',
          'checkedBaggage': 'prohibited',
          'requiresAirlineCheck': true,
          'conditionSummary': 'Только ручная кладь',
          'source': {'confidence': 'high'},
        },
      ],
    });
  }

  @override
  Future<ChecklistItemFeedbackVm> submitChecklistItemFeedback({
    required String tripId,
    required String itemId,
    required ChecklistItemFeedbackType type,
    String comment = '',
    String locale = 'ru',
  }) async {
    submittedFeedbackCalls += 1;
    submittedFeedbackTripId = tripId;
    submittedFeedbackItemId = itemId;
    submittedFeedbackType = type;
    return ChecklistItemFeedbackVm.fromJson({
      'id': 'feedback-1',
      'checklistInstanceId': 'instance-1',
      'userId': 'user-42',
      'tripId': tripId,
      'itemId': itemId,
      'type': checklistItemFeedbackTypeValue(type),
      'comment': comment,
      'createdAt': '2026-06-20T00:06:00Z',
    });
  }
}

class _FakeChecklistOfflineCache extends ChecklistOfflineCache {
  _FakeChecklistOfflineCache({this.cached, this.entries = const []});

  final TripChecklistVm? cached;
  List<CachedTravelChecklistEntry> entries;
  final List<String> readTripIds = [];
  final List<String> savedTripIds = [];
  int listCalls = 0;

  @override
  Future<TripChecklistVm?> readTripChecklist(String tripId) async {
    readTripIds.add(tripId);
    return cached;
  }

  @override
  Future<void> saveTripChecklist(
    String tripId,
    TripChecklistVm checklist, {
    TravelChecklistRouteArgs? routeArgs,
  }) async {
    savedTripIds.add(tripId);
  }

  @override
  Future<List<CachedTravelChecklistEntry>> listTripChecklistEntries() async {
    listCalls += 1;
    return entries;
  }

  @override
  Future<void> replaceTripChecklistEntries(
    Iterable<CachedTravelChecklistEntry> entries,
  ) async {
    this.entries = entries.toList(growable: false);
  }
}

class _FakeReferenceApi extends ReferenceApi {
  static const _countries = [
    ReferenceCountry(code: 'TR', name: 'Турция'),
    ReferenceCountry(code: 'BR', name: 'Бразилия'),
  ];

  static const _cities = [
    ReferenceCity(id: 'istanbul', countryCode: 'TR', name: 'Стамбул'),
    ReferenceCity(
      id: 'rio-de-janeiro',
      countryCode: 'BR',
      name: 'Рио-де-Жанейро',
    ),
  ];

  @override
  Future<List<ReferenceCountry>> listCountries({String lang = 'en'}) async {
    return _countries;
  }

  @override
  Future<List<ReferenceCountry>> searchCountries(
    String query, {
    String lang = 'en',
    int limit = 10,
  }) async {
    final normalized = query.toLowerCase();
    return _countries
        .where((country) => country.name.toLowerCase().contains(normalized))
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<List<ReferenceCity>> citiesByCountry(
    String countryCode, {
    String lang = 'en',
  }) async {
    return _cities
        .where((city) => city.countryCode == countryCode.toUpperCase())
        .toList(growable: false);
  }

  @override
  Future<List<ReferenceCity>> searchCities(
    String query, {
    String? countryCode,
    String lang = 'en',
    int limit = 10,
  }) async {
    final normalized = query.toLowerCase();
    return _cities
        .where(
          (city) =>
              (countryCode == null ||
                  city.countryCode == countryCode.toUpperCase()) &&
              city.name.toLowerCase().contains(normalized),
        )
        .take(limit)
        .toList(growable: false);
  }
}

TripChecklistVm _cachedChecklist() {
  return TripChecklistVm.fromJson({
    'instanceId': 'cached-instance',
    'userId': 'user-42',
    'tripId': 'activity:act-42',
    'readiness': {'score': 64, 'status': 'at_risk', 'blockers': const []},
    'trustNotice': const {
      'code': 'verified_curated',
      'title': 'Cached trust notice',
      'message': 'Offline copy',
    },
    'items': const [
      {
        'id': 'documents.cached_passport',
        'category': 'documents',
        'priority': 'critical',
        'status': 'open',
        'title': 'Cached passport',
        'reason': 'Offline item',
        'trustLevel': 'official_link_required',
        'requiresUserConfirmation': true,
        'source': {'confidence': 'high'},
      },
    ],
    'generatedAt': '2026-06-20T00:00:00Z',
  });
}
