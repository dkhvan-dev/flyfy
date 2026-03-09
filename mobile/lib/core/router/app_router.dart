import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final authState = authProvider.state;
        final location = state.matchedLocation;
        final isLoggedIn = authState == AuthState.authenticated;
        final isInitial = authState == AuthState.initial;

        const publicRoutes = {
          '/',
          '/login',
          '/otp',
        };

        final isPublicRoute = publicRoutes.contains(location);

        if (isInitial) {
          return null;
        }

        if (!isLoggedIn && !isPublicRoute) {
          return '/login?from=${Uri.encodeComponent(location)}';
        }

        if (isLoggedIn && (location == '/login' || location == '/otp')) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return LoginScreen(from: from);
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phone = state.uri.queryParameters['phone'] ?? '';
            final from = state.uri.queryParameters['from'];
            return OtpScreen(phone: phone, from: from);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}