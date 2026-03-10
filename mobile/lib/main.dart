import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/activity_provider.dart';

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

    _authProvider = AuthProvider()..checkAuthStatus();
    _sessionProvider = SessionProvider()..restoreSession();
    _localeProvider = LocaleProvider()..load();
    _router = AppRouter.router(_authProvider);
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
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'FlyFy',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            locale: localeProvider.locale,
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
}