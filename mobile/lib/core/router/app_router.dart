import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/android_back_swipe_scope.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/models/story_vm.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/stories/create_story_screen.dart';
import '../../screens/stories/story_details_screen.dart';
import '../../screens/stories/stories_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/profile_notifications_screen.dart';
import '../../screens/profile/profile_security_screen.dart';
import '../../screens/profile/profile_settings_screen.dart';
import '../../screens/profile/guide_verification_screen.dart';
import '../../screens/activities/activities_screen.dart';
import '../../screens/activities/activity_details_screen.dart';
import '../../screens/activities/activity_attendance_qr_screen.dart';
import '../../screens/activities/activity_payment_screen.dart';
import '../../screens/activities/create_activity_screen.dart';
import '../../screens/activities/my_activities_screen.dart';
import '../../screens/attendance/attendance_scanner_screen.dart';
import '../../screens/chat/conversations_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/common/feature_stub_screen.dart';
import '../../screens/map/map_screen.dart';

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
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return _withAndroidBackSwipe(LoginScreen(from: from));
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phone = state.uri.queryParameters['phone'] ?? '';
            final from = state.uri.queryParameters['from'];
            return _withAndroidBackSwipe(OtpScreen(phone: phone, from: from));
          },
        ),
        GoRoute(
          path: '/stories',
          builder: (context, state) =>
              _withAndroidBackSwipe(const StoriesScreen()),
        ),
        GoRoute(
          path: '/stories/create',
          builder: (context, state) {
            final initialStory = state.extra is StoryVm
                ? state.extra! as StoryVm
                : null;
            return _withAndroidBackSwipe(
              CreateStoryScreen(initialStory: initialStory),
            );
          },
        ),
        GoRoute(
          path: '/stories/:storyId/edit',
          builder: (context, state) {
            final storyId = state.pathParameters['storyId'] ?? '';
            final initialStory = state.extra is StoryVm
                ? state.extra! as StoryVm
                : null;
            return _withAndroidBackSwipe(
              CreateStoryScreen(storyId: storyId, initialStory: initialStory),
            );
          },
        ),
        GoRoute(
          path: '/stories/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            final initialStory = state.extra is StoryVm
                ? state.extra! as StoryVm
                : null;
            return _withAndroidBackSwipe(
              StoryDetailsScreen(slug: slug, initialStory: initialStory),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ProfileScreen()),
        ),
        GoRoute(
          path: '/profile/settings',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ProfileSettingsScreen()),
        ),
        GoRoute(
          path: '/profile/notifications',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ProfileNotificationsScreen()),
        ),
        GoRoute(
          path: '/profile/security',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ProfileSecurityScreen()),
        ),
        GoRoute(
          path: '/profile/guide-verification',
          builder: (context, state) =>
              _withAndroidBackSwipe(const GuideVerificationScreen()),
        ),
        GoRoute(
          path: '/users/:userId/profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            final initialProfile = state.extra is UserProfileVm
                ? state.extra! as UserProfileVm
                : null;
            return _withAndroidBackSwipe(
              ProfileScreen(userId: userId, initialProfile: initialProfile),
            );
          },
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ActivitiesScreen()),
        ),
        GoRoute(
          path: '/me/activities',
          builder: (context, state) =>
              _withAndroidBackSwipe(const MyActivitiesScreen()),
        ),
        GoRoute(
          path: '/activities/create',
          pageBuilder: (context, state) {
            final activity = state.extra is ActivityListItemVm
                ? state.extra! as ActivityListItemVm
                : null;
            return _buildActivityEditorPage(
              state: state,
              child: CreateActivityScreen(
                activity: activity,
                repeatFromActivity: activity != null,
              ),
            );
          },
        ),
        GoRoute(
          path: '/activities/:activityId/edit',
          pageBuilder: (context, state) {
            final activity = state.extra as ActivityListItemVm?;
            return _buildActivityEditorPage(
              state: state,
              child: CreateActivityScreen(activity: activity),
            );
          },
        ),
        GoRoute(
          path: '/activities/:activityId/payment',
          builder: (context, state) {
            final activityId = state.pathParameters['activityId'] ?? '';
            final args = state.extra as ActivityPaymentRouteArgs?;
            return _withAndroidBackSwipe(
              ActivityPaymentScreen(
                activityId: activityId,
                initialActivity: args?.activity,
                initialHostName: args?.hostName,
              ),
            );
          },
        ),
        GoRoute(
          path: '/activities/:activityId',
          builder: (context, state) {
            final activityId = state.pathParameters['activityId'] ?? '';
            return ActivityDetailsScreen(activityId: activityId);
          },
        ),
        GoRoute(
          path: '/activities/:activityId/attendance-qr',
          builder: (context, state) {
            final activityId = state.pathParameters['activityId'] ?? '';
            return _withAndroidBackSwipe(
              ActivityAttendanceQrScreen(activityId: activityId),
            );
          },
        ),
        GoRoute(
          path: '/activities/:activityId/chat',
          builder: (context, state) {
            final activityId = state.pathParameters['activityId'] ?? '';
            return _withAndroidBackSwipe(
              ChatScreen(conversationId: activityId),
            );
          },
        ),
        GoRoute(
          path: '/qr',
          builder: (context, state) =>
              _withAndroidBackSwipe(const AttendanceScannerScreen()),
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) =>
              _withAndroidBackSwipe(const FeatureStubScreen(title: 'Menu')),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => _withAndroidBackSwipe(const MapScreen()),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => _withAndroidBackSwipe(
            const FeatureStubScreen(title: 'Notifications'),
          ),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) =>
              _withAndroidBackSwipe(const FeatureStubScreen(title: 'Services')),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ConversationsScreen()),
        ),
        GoRoute(
          path: '/chats/:conversationId',
          builder: (context, state) {
            final conversationId =
                state.pathParameters['conversationId'] ?? '';
            return _withAndroidBackSwipe(
              ChatScreen(conversationId: conversationId),
            );
          },
        ),
        GoRoute(
          path: '/yandex-go',
          builder: (context, state) => _withAndroidBackSwipe(
            const FeatureStubScreen(title: 'Yandex Go'),
          ),
        ),
        GoRoute(
          path: '/glovo',
          builder: (context, state) =>
              _withAndroidBackSwipe(const FeatureStubScreen(title: 'Glovo')),
        ),
        GoRoute(
          path: '/wolt',
          builder: (context, state) =>
              _withAndroidBackSwipe(const FeatureStubScreen(title: 'Wolt')),
        ),
        GoRoute(
          path: '/more-services',
          builder: (context, state) => _withAndroidBackSwipe(
            const FeatureStubScreen(title: 'More Services'),
          ),
        ),
        GoRoute(
          path: '/featured-stays',
          builder: (context, state) => _withAndroidBackSwipe(
            const FeatureStubScreen(title: 'Featured Stays'),
          ),
        ),
        GoRoute(
          path: '/car-rentals',
          builder: (context, state) => _withAndroidBackSwipe(
            const FeatureStubScreen(title: 'Car Rentals'),
          ),
        ),
        GoRoute(
          path: '/editorial',
          builder: (context, state) =>
              _withAndroidBackSwipe(const StoriesScreen()),
        ),
      ],
    );
  }

  static bool _isPublicRoute(String location) {
    if (location == '/' || location == '/login' || location == '/otp') {
      return true;
    }

    if (location == '/activities' ||
        location == '/stories' ||
        location == '/menu' ||
        location == '/map' ||
        location == '/notifications' ||
        location == '/services' ||
        location == '/chats' ||
        location == '/yandex-go' ||
        location == '/glovo' ||
        location == '/wolt' ||
        location == '/more-services' ||
        location == '/featured-stays' ||
        location == '/car-rentals' ||
        location == '/editorial') {
      return true;
    }

    if (location.startsWith('/stories/')) {
      return true;
    }

    return false;
  }
}

Widget _withAndroidBackSwipe(Widget child) {
  return AndroidBackSwipeScope(child: child);
}

CustomTransitionPage<void> _buildActivityEditorPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: pageChild,
        ),
      );
    },
  );
}
