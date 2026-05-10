import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/attendance/attendance_sync_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/activity_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/sticker_catalog_provider.dart';
import 'providers/tour_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuperApp());
}

class SuperApp extends StatefulWidget {
  const SuperApp({super.key});

  @override
  State<SuperApp> createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  late final AuthProvider _authProvider;
  late final SessionProvider _sessionProvider;
  late final LocaleProvider _localeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();
    _sessionProvider = SessionProvider();
    _localeProvider = LocaleProvider()..load();
    _router = AppRouter.router(_authProvider);

    _bootstrapAuth();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _sessionProvider.dispose();
    _localeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<SessionProvider>.value(value: _sessionProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => TourProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StickerCatalogProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'FlyFy',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            locale: localeProvider.locale,
            builder: (context, child) {
              return _DismissKeyboardOnTap(
                child: _PresenceHeartbeatBridge(
                  child: _AttendanceSyncBridge(
                    child: child ?? const SizedBox.shrink(),
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

  Future<void> _bootstrapAuth() async {
    await _authProvider.checkAuthStatus();
    final hasStoredSession = await _authProvider.hasStoredSessionForUnlock();
    if (hasStoredSession) {
      await _sessionProvider.restoreSession();
      await _authProvider.checkAuthStatus();
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
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
