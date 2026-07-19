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
import 'core/storage/secure_storage.dart';
import 'firebase_options.dart';
import 'features/attendance/attendance_sync_manager.dart';
import 'features/notifications/data/firebase_messaging_push_token_provider.dart';
import 'features/notifications/data/initial_notification_permission_service.dart';
import 'features/notifications/data/notification_api.dart';
import 'features/notifications/data/push_registration_service.dart';
import 'features/notifications/presentation/push_notification_banner.dart';
import 'features/notifications/presentation/push_notification_coordinator.dart';
import 'features/saved/data/saved_api.dart';
import 'features/saved/data/saved_browse_api.dart';
import 'features/saved/data/saved_feature_repository.dart';
import 'features/saved/data/saved_repository.dart';
import 'features/saved/presentation/state/saved_screen_controller.dart';
import 'features/trust/providers/trust_access_provider.dart';
import 'core/ui/app_asset_licenses.dart';
import 'core/ui/app_design_system.dart';
import 'providers/auth_provider.dart';
import 'providers/currency_rate_provider.dart';
import 'providers/home_location_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_badge_provider.dart';
import 'providers/routing_provider.dart';
import 'providers/theme_mode_provider.dart';
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
  registerAppAssetLicenses();
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

class _SuperAppState extends State<SuperApp> with WidgetsBindingObserver {
  static const _deferredStartupDelay = Duration(milliseconds: 350);
  static const _deferredPushStartupDelay = Duration(seconds: 6);

  late final Completer<void> _firebaseReadyCompleter;
  late final Future<void> _firebaseReady;
  late final Completer<void> _initialPermissionsReadyCompleter;
  late final Future<void> _initialPermissionsReady;
  late final AuthSessionEvents _authSessionEvents;
  late final AuthProvider _authProvider;
  late final SessionProvider _sessionProvider;
  late final LocaleProvider _localeProvider;
  late final ThemeModeProvider _themeModeProvider;
  late final HomeLocationProvider _homeLocationProvider;
  late final NotificationBadgeProvider _notificationBadgeProvider;
  late final TrustAccessProvider _trustAccessProvider;
  late final SavedScreenController _savedScreenController;
  late final FirebaseMessagingPushTokenProvider _pushTokenProvider;
  late final InitialNotificationPermissionService _notificationPermissions;
  late final PushRegistrationService _pushRegistrationService;
  late final PushNotificationBannerController _pushNotificationBannerController;
  late final PushNotificationCoordinator _pushNotificationCoordinator;
  late final GoRouter _router;
  bool _initialPermissionsStartupReady = false;
  bool _initialPermissionsInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _firebaseReadyCompleter = Completer<void>();
    _firebaseReady = _firebaseReadyCompleter.future;
    _initialPermissionsReadyCompleter = Completer<void>();
    _initialPermissionsReady = _initialPermissionsReadyCompleter.future;
    _authSessionEvents = AuthSessionEvents.instance;
    _authProvider = AuthProvider(authSessionEvents: _authSessionEvents);
    _sessionProvider = SessionProvider(authSessionEvents: _authSessionEvents);
    _localeProvider = LocaleProvider();
    _themeModeProvider = ThemeModeProvider();
    _homeLocationProvider = HomeLocationProvider();
    _notificationBadgeProvider = NotificationBadgeProvider();
    _trustAccessProvider = TrustAccessProvider();
    final savedApiClient = ApiClient(authSessionEvents: _authSessionEvents);
    _savedScreenController = SavedScreenController(
      repository: SavedFeatureRepositoryImpl(
        browseApi: SavedBrowseApi(apiClient: savedApiClient),
        itemsRepository: SavedRepository(
          api: SavedApi(apiClient: savedApiClient),
        ),
      ),
    );
    _pushTokenProvider = FirebaseMessagingPushTokenProvider(
      firebaseReady: _firebaseReady,
    );
    _notificationPermissions = InitialNotificationPermissionService(
      requester: _pushTokenProvider,
    );
    _pushRegistrationService = PushRegistrationService(
      client: NotificationApi(
        apiClient: ApiClient(authSessionEvents: _authSessionEvents),
      ),
      tokenProvider: _pushTokenProvider,
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
      onNotificationReceived: _handlePushNotificationReceived,
    );

    _scheduleDeferredStartupWork();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_initialPermissionsReadyCompleter.isCompleted) {
      _initialPermissionsReadyCompleter.complete();
    }
    _authProvider.dispose();
    _sessionProvider.dispose();
    _localeProvider.dispose();
    _themeModeProvider.dispose();
    _homeLocationProvider.dispose();
    _notificationBadgeProvider.dispose();
    _trustAccessProvider.dispose();
    _savedScreenController.dispose();
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
        ChangeNotifierProvider<ThemeModeProvider>.value(
          value: _themeModeProvider,
        ),
        ChangeNotifierProvider<HomeLocationProvider>.value(
          value: _homeLocationProvider,
        ),
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
        ChangeNotifierProvider<TrustAccessProvider>.value(
          value: _trustAccessProvider,
        ),
        ChangeNotifierProvider<SavedScreenController>.value(
          value: _savedScreenController,
        ),
        ChangeNotifierProvider(create: (_) => StickerCatalogProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeModeProvider>(
        builder: (context, localeProvider, themeModeProvider, _) {
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
                    child: _SavedSessionBridge(
                      controller: _savedScreenController,
                      child: _TrustAccessSessionBridge(
                        provider: _trustAccessProvider,
                        child: _PushRegistrationBridge(
                          registrationService: _pushRegistrationService,
                          initialPermissionsReady: _initialPermissionsReady,
                          child: _PresenceHeartbeatBridge(
                            child: _AttendanceSyncBridge(
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            theme: AppDesignSystem.lightTheme(),
            darkTheme: AppDesignSystem.darkTheme(),
            themeMode: themeModeProvider.themeMode,
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

    final localeReady = _localeProvider.load();
    unawaited(_themeModeProvider.load());
    unawaited(_bootstrapAuth());
    unawaited(_runDeferredPushStartupWork(localeReady: localeReady));
  }

  Future<void> _runDeferredPushStartupWork({
    required Future<void> localeReady,
  }) async {
    await Future<void>.delayed(_deferredPushStartupDelay);
    if (!mounted) return;

    await _initializeFirebaseMessaging();
    if (!mounted) return;

    try {
      await localeReady;
    } catch (_) {
      // Permission prompts can safely use the system locale as a fallback.
    }
    if (!mounted) return;

    _initialPermissionsStartupReady = true;
    await _requestInitialPermissions();
    if (!mounted) return;
    await _startPushNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialPermissionsStartupReady) {
      unawaited(_requestInitialPermissions());
    }
  }

  Future<void> _requestInitialPermissions() async {
    if (!_initialPermissionsStartupReady ||
        _initialPermissionsReadyCompleter.isCompleted ||
        _initialPermissionsInFlight ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    _initialPermissionsInFlight = true;
    try {
      try {
        await _notificationPermissions.requestPermissionOnce();
        // Warm up the FCM token independently from authentication. The token
        // is sent to the backend only by _PushRegistrationBridge after login.
        await _pushTokenProvider.getCurrentToken();
      } catch (_) {
        // Notification access is optional and retried on the next app launch.
      }
      if (!_canContinueInitialPermissionFlow) return;

      try {
        await _homeLocationProvider.requestInitialLocationPermission(
          languageCode: _localeProvider.locale.languageCode,
        );
      } catch (_) {
        // Location access is optional and must not block app startup.
      }
      if (!_canContinueInitialPermissionFlow) return;

      _initialPermissionsReadyCompleter.complete();
    } finally {
      _initialPermissionsInFlight = false;
    }
  }

  bool get _canContinueInitialPermissionFlow {
    return mounted &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
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

  void _handlePushNotificationReceived(PushNotificationEnvelope envelope) {
    unawaited(_notificationBadgeProvider.refresh(forceRefresh: true));
    unawaited(_refreshNotificationBadgeAfterPropagationDelay());
    if (_sessionProvider.isAuthenticated) {
      unawaited(_trustAccessProvider.handlePushData(envelope.data));
    }
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

class _SavedSessionBridge extends StatefulWidget {
  const _SavedSessionBridge({required this.controller, required this.child});

  final SavedScreenController controller;
  final Widget child;

  @override
  State<_SavedSessionBridge> createState() => _SavedSessionBridgeState();
}

class _SavedSessionBridgeState extends State<_SavedSessionBridge> {
  final SecureStorage _secureStorage = SecureStorage();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _activeBinding;
  bool _probeScheduled = false;
  bool _probeInFlight = false;
  bool _probeAgain = false;
  bool _clearScheduled = false;
  int _bindingEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChanged,
        onError: (_) {},
      );
      unawaited(_checkInitialConnectivity());
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;
    final session = context.watch<SessionProvider>();
    final userId = session.profile?.userId.trim() ?? '';
    final authenticated =
        authState == AuthState.authenticated &&
        session.isAuthenticated &&
        userId.isNotEmpty;

    if (authenticated) {
      _scheduleProbe(userId);
    } else if (_activeBinding != null || widget.controller.initialized) {
      _activeBinding = null;
      _bindingEpoch++;
      _scheduleClear();
    }
    return widget.child;
  }

  void _scheduleProbe(String userId) {
    if (_probeInFlight) {
      _probeAgain = true;
      return;
    }
    if (_probeScheduled) return;
    _probeScheduled = true;
    final epoch = _bindingEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeScheduled = false;
      if (!mounted || epoch != _bindingEpoch) return;
      unawaited(_probeBinding(userId, epoch));
    });
  }

  Future<void> _probeBinding(String userId, int epoch) async {
    _probeInFlight = true;
    try {
      final sessionId = (await _secureStorage.getSessionId())?.trim() ?? '';
      if (!mounted || epoch != _bindingEpoch) return;
      final session = context.read<SessionProvider>();
      final currentUserId = session.profile?.userId.trim() ?? '';
      if (!session.isAuthenticated || currentUserId != userId) return;
      if (sessionId.isEmpty) {
        _activeBinding = '$userId:<missing-session-id>';
        widget.controller.clearForLogout();
        return;
      }
      final nextBinding = '$userId:$sessionId';
      if (_activeBinding != null && _activeBinding != nextBinding) {
        widget.controller.clearForLogout();
      }
      _activeBinding = nextBinding;
      if (widget.controller.isOnline) {
        await widget.controller.ensureCapabilities();
      }
    } on Object {
      if (mounted && epoch == _bindingEpoch) {
        _activeBinding = '$userId:<unavailable-session-id>';
        widget.controller.clearForLogout();
      }
    } finally {
      _probeInFlight = false;
      if (_probeAgain && mounted) {
        _probeAgain = false;
        final session = context.read<SessionProvider>();
        final currentUserId = session.profile?.userId.trim() ?? '';
        if (session.isAuthenticated && currentUserId.isNotEmpty) {
          _scheduleProbe(currentUserId);
        }
      }
    }
  }

  void _scheduleClear() {
    if (_clearScheduled) return;
    _clearScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearScheduled = false;
      if (!mounted || _activeBinding != null) return;
      widget.controller.clearForLogout();
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      _handleConnectivityChanged(await _connectivity.checkConnectivity());
    } on Object {
      // Connectivity is advisory; request errors remain the source of truth.
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (_hasUsableConnectivity(results)) {
      unawaited(widget.controller.handleConnectivityRestored());
    } else {
      widget.controller.handleConnectivityLost();
    }
  }

  bool _hasUsableConnectivity(List<ConnectivityResult> results) {
    return results.any((result) {
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
          return false;
      }
    });
  }
}

class _TrustAccessSessionBridge extends StatefulWidget {
  const _TrustAccessSessionBridge({
    required this.provider,
    required this.child,
  });

  final TrustAccessProvider provider;
  final Widget child;

  @override
  State<_TrustAccessSessionBridge> createState() =>
      _TrustAccessSessionBridgeState();
}

class _TrustAccessSessionBridgeState extends State<_TrustAccessSessionBridge>
    with WidgetsBindingObserver {
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeUserId != null) {
      unawaited(widget.provider.refresh(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final userId = session.profile?.userId.trim() ?? '';
    if (session.isAuthenticated && userId.isNotEmpty) {
      if (_activeUserId != userId) {
        _activeUserId = userId;
        _scheduleRefresh();
      }
    } else if (_activeUserId != null) {
      _activeUserId = null;
      _scheduleClear();
    }
    return widget.child;
  }

  void _scheduleRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeUserId == null) return;
      unawaited(widget.provider.refresh(force: true));
    });
  }

  void _scheduleClear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeUserId != null) return;
      widget.provider.clear();
    });
  }
}

class _PushRegistrationBridge extends StatefulWidget {
  const _PushRegistrationBridge({
    required this.registrationService,
    required this.initialPermissionsReady,
    required this.child,
  });

  final PushRegistrationService registrationService;
  final Future<void> initialPermissionsReady;
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
      await widget.initialPermissionsReady;
      if (!mounted) return;

      final currentSession = context.read<SessionProvider>();
      final currentUserId = currentSession.profile?.userId ?? '';
      if (!currentSession.isAuthenticated || currentUserId.isEmpty) return;

      await widget.registrationService.registerCurrentDevice(
        userId: currentUserId,
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
