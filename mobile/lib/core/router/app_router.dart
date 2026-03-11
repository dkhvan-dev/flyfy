import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/activities/activities_screen.dart';
import '../../screens/activities/activity_details_screen.dart';
import '../../screens/activities/create_activity_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final authState = authProvider.state;
        final location = state.uri.path;
        final isLoggedIn = authState == AuthState.authenticated;
        final isInitial = authState == AuthState.initial;

        final isPublicRoute = _isPublicRoute(location);

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
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivitiesScreen(),
        ),
        GoRoute(
          path: '/activities/create',
          builder: (context, state) => const CreateActivityScreen(),
        ),
        GoRoute(
          path: '/activities/:activityId',
          builder: (context, state) {
            final activityId = state.pathParameters['activityId'] ?? '';
            return ActivityDetailsScreen(activityId: activityId);
          },
        ),
      ],
    );
  }

  static bool _isPublicRoute(String location) {
    if (location == '/' || location == '/login' || location == '/otp') {
      return true;
    }

    if (location == '/activities') {
      return true;
    }

    if (location.startsWith('/activities/') &&
        location != '/activities/create') {
      return true;
    }

    return false;
  }
}