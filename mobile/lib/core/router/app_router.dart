import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../network/debug_network_inspector.dart';
import '../navigation/android_back_swipe_scope.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/checklists/models/travel_checklist_route_args.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/editor/presentation/story_editor_trust_context.dart';
import '../../features/stories/models/post_vm.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/password_reset_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/stories/create_story_screen.dart';
import '../../screens/stories/my_story_archive_screen.dart';
import '../../screens/stories/story_capture_screen.dart';
import '../../screens/stories/story_details_screen.dart';
import '../../screens/stories/story_tray_viewer_screen.dart';
import '../../screens/stories/stories_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/profile_user_activities_screen.dart';
import '../../screens/profile/profile_notifications_screen.dart';
import '../../screens/profile/profile_security_screen.dart';
import '../../screens/profile/profile_settings_screen.dart';
import '../../screens/profile/guide_verification_screen.dart';
import '../../screens/profile/profile_connections_screen.dart';
import '../../screens/profile/profile_followers_screen.dart';
import '../../screens/activities/activities_screen.dart';
import '../../screens/activities/activity_details_screen.dart';
import '../../screens/activities/activity_attendance_qr_screen.dart';
import '../../screens/activities/activity_payment_screen.dart';
import '../../screens/activities/create_activity_screen.dart';
import '../../screens/activities/my_activities_screen.dart';
import '../../screens/excursions/create_excursion_screen.dart';
import '../../screens/excursions/excursion_booking_screen.dart';
import '../../screens/excursions/excursion_select_location_screen.dart';
import '../../screens/excursions/excursion_details_screen.dart';
import '../../screens/excursions/excursions_screen.dart';
import '../../screens/excursions/guide_calendar_screen.dart';
import '../../screens/excursions/guide_dashboard_screen.dart';
import '../../screens/excursions/guide_reviews_screen.dart';
import '../../screens/excursions/my_excursions_screen.dart';
import '../../screens/guides/guides_screen.dart';
import '../../screens/attendance/attendance_scanner_screen.dart';
import '../../screens/chat/conversations_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/places/places_screen.dart';
import '../../screens/places/place_details_screen.dart';
import '../../features/places/models/place_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/feed/presentation/community_members_screen.dart';
import '../../features/feed/presentation/community_moderation_screen.dart';
import '../../features/feed/presentation/community_discovery_screen.dart';
import '../../features/feed/presentation/community_profile_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/feed/models/feed_block_vm.dart';
import '../../features/help_center/models/help_center_models.dart';
import '../../features/help_center/presentation/help_center_screen.dart';
import '../../features/help_center/presentation/support_tickets_screen.dart';
import '../../features/notifications/data/notification_api.dart';
import '../../features/search/presentation/search_route_config.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/app_settings_screen.dart';
import '../../features/user_routes/user_route_feature_flags.dart';
import '../../features/user_routes/presentation/user_route_details_screen.dart';
import '../../features/user_routes/presentation/user_routes_screen.dart';
import '../../features/user_routes/models/user_route_models.dart';
import '../../shared/map/app_map_links.dart';
import '../../screens/common/feature_stub_screen.dart';
import '../../screens/checklists/travel_checklist_screen.dart';
import '../../screens/currency/currency_converter_screen.dart';
import '../../screens/map/map_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/services/services_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: DebugNetworkInspector.navigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      observers: [KeyboardDismissRouteObserver()],
      redirect: (context, state) {
        final authState = authProvider.state;
        final location = state.uri.path;
        final isLoggedIn = authState == AuthState.authenticated;
        final isInitial = authState == AuthState.initial;
        final isAuthenticationRoute =
            location == '/login' ||
            location == '/otp' ||
            location == '/password-reset';

        final isPublicRoute = _isPublicRoute(location);

        if (isInitial) {
          return null;
        }

        if (authState == AuthState.sessionExpired && !isAuthenticationRoute) {
          return Uri(
            path: '/login',
            queryParameters: {
              'from': state.uri.toString(),
              'reason': 'session-expired',
            },
          ).toString();
        }

        if (!isLoggedIn && !isPublicRoute) {
          return '/login?from=${Uri.encodeComponent(location)}';
        }

        if (isLoggedIn && isAuthenticationRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            final config = SearchRouteConfig.fromQueryParameters(
              state.uri.queryParameters,
            );
            return _withAndroidBackSwipe(SearchScreen(config: config));
          },
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) =>
              _withAndroidBackSwipe(const FeedScreen()),
        ),
        GoRoute(
          path: '/communities',
          builder: (context, state) =>
              _withAndroidBackSwipe(const CommunityDiscoveryScreen()),
        ),
        GoRoute(
          path: '/communities/:communityId',
          builder: (context, state) {
            final communityId = state.pathParameters['communityId'] ?? '';
            final initialCommunity = state.extra is FeedCommunityVm
                ? state.extra! as FeedCommunityVm
                : null;
            final initialPostId = state.uri.queryParameters['postId'];
            return _withAndroidBackSwipe(
              CommunityProfileScreen(
                communityId: communityId,
                initialCommunity: initialCommunity,
                initialPostId: initialPostId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/communities/:communityId/moderation',
          builder: (context, state) {
            final communityId = state.pathParameters['communityId'] ?? '';
            final communityTitle = state.uri.queryParameters['title'];
            return _withAndroidBackSwipe(
              CommunityModerationScreen(
                communityId: communityId,
                communityTitle: communityTitle,
              ),
            );
          },
        ),
        GoRoute(
          path: '/communities/:communityId/members',
          builder: (context, state) {
            final communityId = state.pathParameters['communityId'] ?? '';
            final communityTitle = state.uri.queryParameters['title'];
            return _withAndroidBackSwipe(
              CommunityMembersScreen(
                communityId: communityId,
                communityTitle: communityTitle,
              ),
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            final initialRegister =
                state.uri.queryParameters['mode'] == 'register';
            return _withAndroidBackSwipe(
              LoginScreen(from: from, initialRegister: initialRegister),
            );
          },
        ),
        GoRoute(
          path: '/app-settings',
          builder: (context, state) =>
              _withAndroidBackSwipe(const AppSettingsScreen()),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phone = state.uri.queryParameters['phone'] ?? '';
            final email = state.uri.queryParameters['email'] ?? '';
            final mode = state.uri.queryParameters['mode'] ?? 'phone';
            final from = state.uri.queryParameters['from'];
            return _withAndroidBackSwipe(
              OtpScreen(phone: phone, email: email, mode: mode, from: from),
            );
          },
        ),
        GoRoute(
          path: '/password-reset',
          builder: (context, state) =>
              _withAndroidBackSwipe(const PasswordResetScreen()),
        ),
        GoRoute(
          path: '/posts',
          builder: (context, state) =>
              _withAndroidBackSwipe(const StoriesScreen()),
        ),
        GoRoute(
          path: '/me/posts',
          builder: (context, state) =>
              _withAndroidBackSwipe(const StoriesScreen(myOnly: true)),
        ),
        GoRoute(
          path: '/me/stories',
          builder: (context, state) =>
              _withAndroidBackSwipe(const MyStoryArchiveScreen()),
        ),
        GoRoute(
          path: '/posts/create',
          builder: (context, state) {
            final extra = state.extra;
            final initialStory = extra is PostVm ? extra : null;
            final communityTrustContext = extra is StoryEditorTrustContext
                ? extra
                : null;
            final communityId = state.uri.queryParameters['communityId'];
            final postProfileKey = state.uri.queryParameters['postProfileKey'];
            final availablePostProfileKeys = _splitCsvQueryValue(
              state.uri.queryParameters['postProfileKeys'],
            );
            final communityCountryCode =
                state.uri.queryParameters['communityCountryCode'];
            final communityCityId =
                state.uri.queryParameters['communityCityId'];
            final communityCityName =
                state.uri.queryParameters['communityCityName'];
            return _withAndroidBackSwipe(
              CreateStoryScreen(
                initialStory: initialStory,
                communityId: communityId,
                postProfileKey: postProfileKey,
                availablePostProfileKeys: availablePostProfileKeys,
                communityCountryCode: communityCountryCode,
                communityCityId: communityCityId,
                communityCityName: communityCityName,
                communityTrustContext: communityTrustContext,
              ),
            );
          },
        ),
        GoRoute(
          path: '/stories/capture',
          builder: (context, state) =>
              _withAndroidBackSwipe(const StoryCaptureScreen()),
        ),
        GoRoute(
          path: '/posts/:postId/edit',
          builder: (context, state) {
            final storyId = state.pathParameters['postId'] ?? '';
            final initialStory = state.extra is PostVm
                ? state.extra! as PostVm
                : null;
            return _withAndroidBackSwipe(
              CreateStoryScreen(
                storyId: storyId,
                initialStory: initialStory,
                returnOnSave: state.uri.queryParameters['returnOnSave'] == '1',
              ),
            );
          },
        ),
        GoRoute(
          path: '/stories/viewer',
          builder: (context, state) {
            final data = state.extra is StoryTrayViewerRouteData
                ? state.extra! as StoryTrayViewerRouteData
                : const StoryTrayViewerRouteData(stories: []);
            return _withAndroidBackSwipe(StoryTrayViewerScreen(data: data));
          },
        ),
        GoRoute(
          path: '/posts/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            final initialCommentId = state.uri.queryParameters['comment'];
            final initialStory = state.extra is PostVm
                ? state.extra! as PostVm
                : null;
            return _withAndroidBackSwipe(
              StoryDetailsScreen(
                slug: slug,
                initialStory: initialStory,
                initialCommentId: initialCommentId,
              ),
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
          path: '/profile/guide-dashboard',
          builder: (context, state) =>
              _withAndroidBackSwipe(const GuideDashboardScreen()),
        ),
        GoRoute(
          path: '/profile/guide-dashboard/calendar',
          builder: (context, state) =>
              _withAndroidBackSwipe(const GuideCalendarScreen()),
        ),
        GoRoute(
          path: '/profile/guide-dashboard/reviews',
          builder: (context, state) =>
              _withAndroidBackSwipe(const GuideReviewsScreen()),
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
          path: '/users/:userId/followers',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return _withAndroidBackSwipe(
              ProfileFollowersScreen(userId: userId),
            );
          },
        ),
        GoRoute(
          path: '/profile/connections',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ProfileConnectionsScreen()),
        ),
        GoRoute(
          path: '/users/:userId/activities',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return _withAndroidBackSwipe(
              ProfileUserActivitiesScreen(userId: userId),
            );
          },
        ),
        GoRoute(
          path: '/users/:userId/posts',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return _withAndroidBackSwipe(StoriesScreen(authorId: userId));
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
            final activityId = state.pathParameters['activityId'] ?? '';
            final activity = state.extra as ActivityListItemVm?;
            if (activity == null) {
              return _buildActivityEditorPage(
                state: state,
                child: ActivityDetailsScreen(
                  activityId: activityId,
                  initialActivity: activity,
                ),
              );
            }
            return _buildActivityEditorPage(
              state: state,
              child: CreateActivityScreen(
                activity: activity,
                repeatFromActivity: false,
              ),
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
            final initialActivity = state.extra is ActivityListItemVm
                ? state.extra! as ActivityListItemVm
                : null;
            return _withAndroidBackSwipe(
              ActivityDetailsScreen(
                activityId: activityId,
                initialActivity: initialActivity,
              ),
            );
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
            final initialMessageId = state.uri.queryParameters['message'];
            return _withAndroidBackSwipe(
              ChatScreen(
                activityId: activityId,
                initialMessageId: initialMessageId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/excursions',
          builder: (context, state) {
            final args = state.extra is ExcursionsRouteArgs
                ? state.extra! as ExcursionsRouteArgs
                : null;
            return _withAndroidBackSwipe(ExcursionsScreen(routeArgs: args));
          },
        ),
        GoRoute(
          path: '/guides',
          builder: (context, state) =>
              _withAndroidBackSwipe(const GuidesScreen()),
        ),
        GoRoute(
          path: '/guides/:guideUserId/calendar',
          builder: (context, state) {
            final guideUserId = state.pathParameters['guideUserId'] ?? '';
            return _withAndroidBackSwipe(
              GuideCalendarScreen(guideUserId: guideUserId, readOnly: true),
            );
          },
        ),
        GoRoute(
          path: '/excursions/create',
          pageBuilder: (context, state) {
            return _buildActivityEditorPage(
              state: state,
              child: const CreateExcursionScreen(),
            );
          },
        ),
        GoRoute(
          path: '/excursions/create/location',
          pageBuilder: (context, state) {
            final args = state.extra is ExcursionLocationPickerArgs
                ? state.extra! as ExcursionLocationPickerArgs
                : null;
            final initialSelection =
                args?.initialSelection ??
                (state.extra is ExcursionLocationSelection
                    ? state.extra! as ExcursionLocationSelection
                    : null);
            final countryCode =
                args?.countryCode ?? initialSelection?.countryCode ?? 'KZ';
            return _buildActivityEditorPage(
              state: state,
              child: ExcursionSelectLocationScreen(
                countryCode: countryCode,
                initialSelection: initialSelection,
              ),
            );
          },
        ),
        GoRoute(
          path: '/excursions/:excursionId/edit',
          pageBuilder: (context, state) {
            final excursionId = state.pathParameters['excursionId'] ?? '';
            final initialExcursion = state.extra is ExcursionVm
                ? state.extra! as ExcursionVm
                : null;
            return _buildActivityEditorPage(
              state: state,
              child: CreateExcursionScreen(
                excursionId: excursionId,
                initialExcursion: initialExcursion,
              ),
            );
          },
        ),
        GoRoute(
          path: '/excursions/:excursionId/booking',
          builder: (context, state) {
            final excursionId = state.pathParameters['excursionId'] ?? '';
            final args = state.extra is ExcursionBookingRouteArgs
                ? state.extra! as ExcursionBookingRouteArgs
                : null;
            final initialExcursion =
                args?.excursion ??
                (state.extra is ExcursionVm
                    ? state.extra! as ExcursionVm
                    : null);
            return _withAndroidBackSwipe(
              ExcursionBookingScreen(
                excursionId: excursionId,
                initialExcursion: initialExcursion,
                selectedOfferId: args?.selectedOfferId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/me/excursions',
          builder: (context, state) =>
              _withAndroidBackSwipe(const MyExcursionsScreen()),
        ),
        GoRoute(
          path: '/excursions/:excursionId',
          builder: (context, state) {
            final excursionId = state.pathParameters['excursionId'] ?? '';
            final initialExcursion = state.extra is ExcursionVm
                ? state.extra! as ExcursionVm
                : null;
            return _withAndroidBackSwipe(
              ExcursionDetailsScreen(
                excursionId: excursionId,
                initialExcursion: initialExcursion,
              ),
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
          path: '/places',
          builder: (context, state) =>
              _withAndroidBackSwipe(const PlacesScreen()),
        ),
        GoRoute(
          path: '/places/:placeId',
          builder: (context, state) {
            final placeId = state.pathParameters['placeId'] ?? '';
            final initialPlace = state.extra is PlaceVm
                ? state.extra! as PlaceVm
                : null;
            return _withAndroidBackSwipe(
              PlaceDetailsScreen(placeId: placeId, initialPlace: initialPlace),
            );
          },
        ),
        GoRoute(
          path: '/places',
          builder: (context, state) =>
              _withAndroidBackSwipe(const PlacesScreen()),
        ),
        GoRoute(
          path: '/places/:placeId',
          builder: (context, state) {
            final placeId = state.pathParameters['placeId'] ?? '';
            final initialPlace = state.extra is PlaceVm
                ? state.extra! as PlaceVm
                : null;
            return _withAndroidBackSwipe(
              PlaceDetailsScreen(placeId: placeId, initialPlace: initialPlace),
            );
          },
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            final meetingPointPickerEnabled = mode == 'meeting-point-picker';
            final routeBuilderEnabled =
                UserRouteFeatureFlags.customRoutesEnabled &&
                mode == 'route-builder';
            final routePreview = state.extra is MapRoutePreview
                ? state.extra! as MapRoutePreview
                : null;
            final initialTarget = state.extra is MapTarget
                ? state.extra! as MapTarget
                : routePreview?.destination ?? _mapTargetFromQuery(state);
            final activityCollection = state.extra is MapActivityCollection
                ? state.extra! as MapActivityCollection
                : null;
            return _withAndroidBackSwipe(
              MapScreen(
                initialTarget: initialTarget,
                activityCollection: activityCollection,
                routePreview: routePreview,
                routeBuilderEnabled: routeBuilderEnabled,
                meetingPointPickerEnabled: meetingPointPickerEnabled,
              ),
            );
          },
        ),
        GoRoute(
          path: '/user-routes',
          redirect: (context, state) =>
              UserRouteFeatureFlags.customRoutesEnabled ? null : '/',
          builder: (context, state) =>
              _withAndroidBackSwipe(const UserRoutesScreen()),
        ),
        GoRoute(
          path: '/user-routes/:routeId',
          redirect: (context, state) =>
              UserRouteFeatureFlags.customRoutesEnabled ? null : '/',
          builder: (context, state) {
            final routeId = state.pathParameters['routeId'] ?? '';
            final initialRoute = state.extra is UserRouteVm
                ? state.extra! as UserRouteVm
                : null;
            return _withAndroidBackSwipe(
              UserRouteDetailsScreen(
                routeId: routeId,
                initialRoute: initialRoute,
              ),
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              _withAndroidBackSwipe(const NotificationsOverviewScreen()),
        ),
        GoRoute(
          path: '/notifications/:category',
          builder: (context, state) {
            final category = Uri.decodeComponent(
              state.pathParameters['category'] ?? 'general',
            );
            final initialSummary = state.extra is NotificationCategorySummary
                ? state.extra! as NotificationCategorySummary
                : null;
            return _withAndroidBackSwipe(
              NotificationCategoryScreen(
                category: category,
                initialSummary: initialSummary,
              ),
            );
          },
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ServicesScreen()),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) =>
              _withAndroidBackSwipe(const HelpCenterScreen()),
        ),
        GoRoute(
          path: '/help/support',
          builder: (context, state) {
            final extra = state.extra;
            return _withAndroidBackSwipe(
              SupportTicketDetailScreen(
                initialIntent: extra is SupportChatOpenIntent ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: '/help/support/:ticketId',
          builder: (context, state) => _withAndroidBackSwipe(
            SupportTicketDetailScreen(
              ticketId: state.pathParameters['ticketId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/currency-converter',
          builder: (context, state) =>
              _withAndroidBackSwipe(const CurrencyConverterScreen()),
        ),
        GoRoute(
          path: '/travel-checklist',
          builder: (context, state) {
            final checklistArgs = state.extra is TravelChecklistRouteArgs
                ? state.extra! as TravelChecklistRouteArgs
                : _travelChecklistArgsFromQuery(state.uri.queryParameters);
            return _withAndroidBackSwipe(
              TravelChecklistScreen(routeArgs: checklistArgs),
            );
          },
        ),
        GoRoute(
          path: '/me/checklists',
          builder: (context, state) =>
              _withAndroidBackSwipe(const TravelChecklistListScreen()),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) =>
              _withAndroidBackSwipe(const ConversationsScreen()),
        ),
        GoRoute(
          path: '/chats/:conversationId',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId'] ?? '';
            final initialMessageId = state.uri.queryParameters['message'];
            return _withAndroidBackSwipe(
              ChatScreen(
                conversationId: conversationId,
                initialMessageId: initialMessageId,
              ),
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

  static TravelChecklistRouteArgs? _travelChecklistArgsFromQuery(
    Map<String, String> queryParameters,
  ) {
    const requiredKeys = [
      'tripId',
      'countryCode',
      'cityName',
      'startAt',
      'endAt',
    ];
    for (final key in requiredKeys) {
      if ((queryParameters[key] ?? '').trim().isEmpty) {
        return null;
      }
    }
    return TravelChecklistRouteArgs.fromQueryParameters(queryParameters);
  }

  static bool _isPublicRoute(String location) {
    if (location == '/' ||
        location == '/search' ||
        location == '/app-settings' ||
        location == '/login' ||
        location == '/otp' ||
        location == '/password-reset') {
      return true;
    }

    if (location == '/activities' ||
        location == '/excursions' ||
        location == '/feed' ||
        location == '/communities' ||
        location == '/guides' ||
        location == '/posts' ||
        location == '/stories/viewer' ||
        location == '/menu' ||
        location == '/map' ||
        location == '/services' ||
        location == '/help' ||
        location == '/currency-converter' ||
        location == '/yandex-go' ||
        location == '/glovo' ||
        location == '/wolt' ||
        location == '/more-services' ||
        location == '/featured-stays' ||
        location == '/car-rentals' ||
        location == '/editorial') {
      return true;
    }

    if (location.startsWith('/communities/')) {
      final isProtectedCommunitySubroute =
          location.contains('/moderation') || location.contains('/members');
      return !isProtectedCommunitySubroute;
    }

    if (location.startsWith('/posts/create')) {
      return false;
    }

    if (location.startsWith('/stories/capture')) {
      return false;
    }

    if (location.startsWith('/posts/') && location.endsWith('/edit')) {
      return false;
    }

    if (location.startsWith('/posts/')) {
      return true;
    }

    if (location.startsWith('/user-routes')) {
      return true;
    }

    if (location.startsWith('/guides/')) {
      return true;
    }

    if (location.startsWith('/users/') && location.endsWith('/profile')) {
      return true;
    }

    if (location.startsWith('/excursions/create')) {
      return false;
    }

    if (location.startsWith('/excursions/') && location.endsWith('/edit')) {
      return false;
    }

    if (location.startsWith('/excursions/') && location.endsWith('/booking')) {
      return false;
    }

    if (location.startsWith('/excursions/')) {
      return true;
    }

    if (location == '/places' ||
        location.startsWith('/places/') ||
        location == '/places' ||
        location.startsWith('/places/')) {
      return true;
    }

    return false;
  }
}

class KeyboardDismissRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismissKeyboard();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

Widget _withAndroidBackSwipe(Widget child) {
  return AndroidBackSwipeScope(child: child);
}

List<String>? _splitCsvQueryValue(String? value) {
  final parts = (value ?? '')
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  return parts.isEmpty ? null : parts;
}

MapTarget? _mapTargetFromQuery(GoRouterState state) {
  final latitude = double.tryParse(state.uri.queryParameters['lat'] ?? '');
  final longitude = double.tryParse(state.uri.queryParameters['lon'] ?? '');
  if (latitude == null ||
      longitude == null ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }

  final title = state.uri.queryParameters['title']?.trim();
  final subtitle = state.uri.queryParameters['subtitle']?.trim();
  final fallbackTitle = title?.isNotEmpty == true ? title! : 'Map';
  return MapTarget(
    title: fallbackTitle,
    subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
    latitude: latitude,
    longitude: longitude,
    sourceUrl: AppMapLinks.buildUrl(
      latitude: latitude,
      longitude: longitude,
      title: fallbackTitle,
      subtitle: subtitle,
    ),
  );
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
