import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_session_events.dart';
import 'core/network/api_client.dart';
import 'firebase_options.dart';
import 'features/attendance/attendance_sync_manager.dart';
import 'features/notifications/data/firebase_messaging_push_token_provider.dart';
import 'features/notifications/data/notification_api.dart';
import 'features/notifications/data/push_registration_service.dart';
import 'features/notifications/presentation/push_notification_banner.dart';
import 'features/notifications/presentation/push_notification_coordinator.dart';
import 'providers/auth_provider.dart';
import 'providers/currency_rate_provider.dart';
import 'providers/home_location_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_badge_provider.dart';
import 'providers/routing_provider.dart';
import 'providers/user_routes_provider.dart';
import 'core/router/app_router.dart';
import 'core/ui/keyboard_dismiss_on_scroll.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/activity_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/sticker_catalog_provider.dart';
import 'providers/excursion_provider.dart';
import 'providers/excursion_schedule_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const SuperApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class SuperApp extends StatefulWidget {
  const SuperApp({super.key});

  @override
  State<SuperApp> createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  static const _deferredStartupDelay = Duration(milliseconds: 350);
  static const _deferredPushStartupDelay = Duration(seconds: 6);

  late final Completer<void> _firebaseReadyCompleter;
  late final Future<void> _firebaseReady;
  late final AuthSessionEvents _authSessionEvents;
  late final AuthProvider _authProvider;
  late final SessionProvider _sessionProvider;
  late final LocaleProvider _localeProvider;
  late final NotificationBadgeProvider _notificationBadgeProvider;
  late final PushRegistrationService _pushRegistrationService;
  late final PushNotificationBannerController _pushNotificationBannerController;
  late final PushNotificationCoordinator _pushNotificationCoordinator;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _firebaseReadyCompleter = Completer<void>();
    _firebaseReady = _firebaseReadyCompleter.future;
    _authSessionEvents = AuthSessionEvents.instance;
    _authProvider = AuthProvider(authSessionEvents: _authSessionEvents);
    _sessionProvider = SessionProvider(authSessionEvents: _authSessionEvents);
    _localeProvider = LocaleProvider();
    _notificationBadgeProvider = NotificationBadgeProvider();
    _pushRegistrationService = PushRegistrationService(
      client: NotificationApi(
        apiClient: ApiClient(authSessionEvents: _authSessionEvents),
      ),
      tokenProvider: FirebaseMessagingPushTokenProvider(
        firebaseReady: _firebaseReady,
      ),
    );
    _pushNotificationBannerController = PushNotificationBannerController();
    _router = AppRouter.router(_authProvider);
    _pushNotificationCoordinator = PushNotificationCoordinator(
      source: FirebasePushNotificationSource(firebaseReady: _firebaseReady),
      presenter: CompositePushNotificationPresenter([
        LocalPushNotificationPresenter(showForegroundNotification: false),
        InAppPushNotificationPresenter(
          controller: _pushNotificationBannerController,
        ),
      ]),
      routeHandler: _router.go,
      onNotificationReceived: (_) => _refreshNotificationBadgeAfterPush(),
    );

    _scheduleDeferredStartupWork();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _sessionProvider.dispose();
    _localeProvider.dispose();
    _notificationBadgeProvider.dispose();
    unawaited(_pushNotificationCoordinator.dispose());
    unawaited(_pushNotificationBannerController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<SessionProvider>.value(value: _sessionProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
        ChangeNotifierProvider(create: (_) => HomeLocationProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyRateProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ExcursionProvider()),
        ChangeNotifierProvider(create: (_) => ExcursionScheduleProvider()),
        ChangeNotifierProvider(create: (_) => RoutingProvider()),
        ChangeNotifierProvider(create: (_) => UserRoutesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider<NotificationBadgeProvider>.value(
          value: _notificationBadgeProvider,
        ),
        ChangeNotifierProvider(create: (_) => StickerCatalogProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          ApiClient.setAppLocale(localeProvider.locale.languageCode);

          return MaterialApp.router(
            title: 'Inflap',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            locale: localeProvider.locale,
            builder: (context, child) {
              return PushNotificationBannerHost(
                controller: _pushNotificationBannerController,
                child: _DismissKeyboardOnTap(
                  child: AppKeyboardDismissOnScroll(
                    child: _PushRegistrationBridge(
                      registrationService: _pushRegistrationService,
                      child: _PresenceHeartbeatBridge(
                        child: _AttendanceSyncBridge(
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0A0A0F),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00BCD4),
                brightness: Brightness.dark,
              ),
              fontFamily: 'Inter',
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }

  void _scheduleDeferredStartupWork() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runDeferredStartupWork());
    });
  }

  Future<void> _runDeferredStartupWork() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    await Future<void>.delayed(_deferredStartupDelay);
    if (!mounted) return;

    unawaited(_localeProvider.load());
    unawaited(_bootstrapAuth());
    unawaited(_runDeferredPushStartupWork());
  }

  Future<void> _runDeferredPushStartupWork() async {
    await Future<void>.delayed(_deferredPushStartupDelay);
    if (!mounted) return;

    await _initializeFirebaseMessaging();
    if (!mounted) return;
    await _startPushNotifications();
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseReadyCompleter.isCompleted) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!_firebaseReadyCompleter.isCompleted) {
        _firebaseReadyCompleter.complete();
      }
    } catch (error, stackTrace) {
      if (!_firebaseReadyCompleter.isCompleted) {
        _firebaseReadyCompleter.completeError(error, stackTrace);
      }
    }
  }

  Future<void> _startPushNotifications() async {
    try {
      await _pushNotificationCoordinator.start();
    } catch (_) {
      // Push setup is best effort and must not delay app startup.
    }
  }

  void _refreshNotificationBadgeAfterPush() {
    unawaited(_notificationBadgeProvider.refresh(forceRefresh: true));
    unawaited(_refreshNotificationBadgeAfterPropagationDelay());
  }

  Future<void> _refreshNotificationBadgeAfterPropagationDelay() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _notificationBadgeProvider.refresh(forceRefresh: true);
  }

  Future<void> _bootstrapAuth() async {
    await _authProvider.checkAuthStatus();
    if (_authProvider.state == AuthState.authenticated) {
      await _sessionProvider.restoreSession();
      await _authProvider.checkAuthStatus();
    }
  }
}

class _PushRegistrationBridge extends StatefulWidget {
  const _PushRegistrationBridge({
    required this.registrationService,
    required this.child,
  });

  final PushRegistrationService registrationService;
  final Widget child;

  @override
  State<_PushRegistrationBridge> createState() =>
      _PushRegistrationBridgeState();
}

class _PushRegistrationBridgeState extends State<_PushRegistrationBridge>
    with WidgetsBindingObserver {
  StreamSubscription<PushTokenSnapshot>? _tokenRefreshSubscription;
  String? _activeUserId;
  bool _registrationInFlight = false;
  bool _unregistrationInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleTokenRefreshSubscription();
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleTokenRefreshSubscription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tokenRefreshSubscription != null) return;
      _tokenRefreshSubscription = widget.registrationService.tokenRefreshes
          .listen((_) => _scheduleRegistration(force: true), onError: (_) {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final userId = session.profile?.userId ?? '';

    if (session.isAuthenticated && userId.isNotEmpty) {
      if (_activeUserId != userId) {
        _activeUserId = userId;
        _scheduleRegistration(force: true);
      }
    } else if (_activeUserId != null) {
      _activeUserId = null;
      _scheduleUnregistration();
    }

    return widget.child;
  }

  void _scheduleRegistration({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_registerCurrentDevice(force: force));
    });
  }

  Future<void> _registerCurrentDevice({required bool force}) async {
    final session = context.read<SessionProvider>();
    final userId = session.profile?.userId ?? '';
    if (!session.isAuthenticated || userId.isEmpty) return;
    if (_registrationInFlight) return;

    _registrationInFlight = true;
    try {
      await widget.registrationService.registerCurrentDevice(
        userId: userId,
        force: force,
      );
    } catch (_) {
      // Push registration should never block sign-in or navigation.
    } finally {
      _registrationInFlight = false;
    }
  }

  void _scheduleUnregistration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_unregisterCurrentDevice());
    });
  }

  Future<void> _unregisterCurrentDevice() async {
    if (_unregistrationInFlight) return;

    _unregistrationInFlight = true;
    try {
      await widget.registrationService.unregisterCurrentDevice();
    } catch (_) {
      // Best-effort cleanup: expired sessions may no longer have a valid token.
    } finally {
      _unregistrationInFlight = false;
    }
  }
}

class _PresenceHeartbeatBridge extends StatefulWidget {
  const _PresenceHeartbeatBridge({required this.child});

  final Widget child;

  @override
  State<_PresenceHeartbeatBridge> createState() =>
      _PresenceHeartbeatBridgeState();
}

class _PresenceHeartbeatBridgeState extends State<_PresenceHeartbeatBridge>
    with WidgetsBindingObserver {
  static const _heartbeatInterval = Duration(seconds: 45);
  static const _minHeartbeatGap = Duration(seconds: 20);

  Timer? _heartbeatTimer;
  String? _activeUserId;
  DateTime? _lastHeartbeatAt;
  bool _heartbeatInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      unawaited(_sendHeartbeat(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final userId = session.profile?.userId ?? '';

    if (session.isAuthenticated && userId.isNotEmpty) {
      if (_activeUserId != userId) {
        _activeUserId = userId;
        _restartTimer();
        _scheduleHeartbeat(force: true);
      }
    } else if (_activeUserId != null) {
      _activeUserId = null;
      _lastHeartbeatAt = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }

    return widget.child;
  }

  void _restartTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _scheduleHeartbeat(),
    );
  }

  void _scheduleHeartbeat({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_sendHeartbeat(force: force));
    });
  }

  Future<void> _sendHeartbeat({required bool force}) async {
    final session = context.read<SessionProvider>();
    final userId = session.profile?.userId ?? '';
    if (!session.isAuthenticated || userId.isEmpty) return;
    if (_heartbeatInFlight) return;

    final now = DateTime.now();
    if (!force &&
        _lastHeartbeatAt != null &&
        now.difference(_lastHeartbeatAt!) < _minHeartbeatGap) {
      return;
    }

    _heartbeatInFlight = true;
    try {
      await session.updatePresenceSilently();
      _lastHeartbeatAt = DateTime.now();
    } finally {
      _heartbeatInFlight = false;
    }
  }
}

class _AttendanceSyncBridge extends StatefulWidget {
  const _AttendanceSyncBridge({required this.child});

  final Widget child;

  @override
  State<_AttendanceSyncBridge> createState() => _AttendanceSyncBridgeState();
}

class _AttendanceSyncBridgeState extends State<_AttendanceSyncBridge>
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();

  String? _lastSyncedUserId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleConnectivitySubscription();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleConnectivitySubscription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _connectivitySubscription != null) return;
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChanged,
        onError: (_) {},
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final userId = session.profile?.userId ?? '';
    if (session.isAuthenticated &&
        userId.isNotEmpty &&
        _lastSyncedUserId != userId) {
      _lastSyncedUserId = userId;
      _scheduleSync();
    }
    if (!session.isAuthenticated) {
      _lastSyncedUserId = null;
    }
    return widget.child;
  }

  Future<void> _handleConnectivityChanged(
    List<ConnectivityResult> results,
  ) async {
    if (!_hasUsableConnectivity(results)) {
      return;
    }

    _scheduleSync(force: true);
  }

  bool _hasUsableConnectivity(List<ConnectivityResult> results) {
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.mobile:
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.satellite:
        case ConnectivityResult.other:
          return true;
        case ConnectivityResult.none:
          continue;
      }
    }
    return false;
  }

  void _scheduleSync({bool force = false}) {
    final session = context.read<SessionProvider>();
    final userId = session.profile?.userId ?? '';
    if (!session.isAuthenticated || userId.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AttendanceSyncManager.instance.syncPendingForUser(userId, force: force);
    });
  }
}

class _DismissKeyboardOnTap extends StatelessWidget {
  const _DismissKeyboardOnTap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
