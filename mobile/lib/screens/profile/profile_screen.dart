import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../core/network/activity_api.dart';
import '../../core/network/chat_api.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/excursion_api.dart';
import '../../core/network/post_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/activities/models/activity_review_vm.dart';
import '../../features/chat/models/user_block_status_vm.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/guide_profile_vm.dart';
import '../../features/profile/models/profile_follower_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/models/post_vm.dart';
import '../../features/user_routes/user_route_feature_flags.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_style.dart';
import 'widgets/profile_activity_card.dart';
import 'widgets/profile_post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.initialProfile});

  final String? userId;
  final UserProfileVm? initialProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _foreignProfileRecentActivitiesPreviewLimit = 3;
  static const int _foreignProfilePopularStoriesPreviewLimit = 3;

  final ProfileApi _profileApi = ProfileApi();
  final GuideApi _guideApi = GuideApi();
  final FileApi _fileApi = FileApi();
  final ActivityApi _activityApi = ActivityApi();
  final ChatApi _chatApi = ChatApi();
  final ExcursionApi _excursionApi = ExcursionApi();
  final PostApi _postApi = PostApi();

  Future<UserProfileVm>? _foreignProfileFuture;
  UserProfileVm? _initialForeignProfile;
  Future<_ProfileExtras>? _extrasFuture;
  Future<int>? _activityCountFuture;
  Future<List<ActivityListItemVm>>? _foreignRecentActivitiesFuture;
  Future<List<PostVm>>? _foreignPopularStoriesFuture;
  Future<ProfileFollowersPageVm>? _incomingFriendRequestsFuture;
  Future<int>? _publishedStoriesCountFuture;
  Future<ExcursionReviewsPage>? _guideReviewsFuture;
  Future<GuideReviewsPage>? _directGuideReviewsFuture;
  Future<ActivityReviewsPage>? _activityReviewsFuture;
  Future<ActivityOrganizerReviewsPage>? _activityOrganizerReviewsFuture;
  Future<UserBlockStatusVm>? _blockStatusFuture;
  String _extrasKey = '';
  String _activityCountKey = '';
  String _foreignRecentActivitiesKey = '';
  String _foreignPopularStoriesKey = '';
  String _incomingFriendRequestsKey = '';
  String _publishedStoriesCountKey = '';
  String _guideReviewsKey = '';
  String _directGuideReviewsKey = '';
  String _activityReviewsKey = '';
  String _activityOrganizerReviewsKey = '';
  String _blockStatusKey = '';
  String _relationshipOverrideUserId = '';
  String _blockStatusOverrideUserId = '';
  int? _followersCountOverride;
  bool? _isFollowedByMeOverride;
  bool? _isBlockedByMeOverride;
  UserFriendshipStatus? _friendshipStatusOverride;
  bool _isFollowActionLoading = false;
  bool _isFriendshipActionLoading = false;
  bool _isMessageActionLoading = false;
  bool _isBlockActionLoading = false;

  @override
  void initState() {
    super.initState();
    _configureForeignProfileFuture();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.initialProfile?.userId != widget.initialProfile?.userId) {
      _configureForeignProfileFuture();
    }
  }

  void _clearProfileDataFutures() {
    _extrasFuture = null;
    _extrasKey = '';
    _activityCountFuture = null;
    _activityCountKey = '';
    _publishedStoriesCountFuture = null;
    _publishedStoriesCountKey = '';
    _foreignRecentActivitiesFuture = null;
    _foreignRecentActivitiesKey = '';
    _foreignPopularStoriesFuture = null;
    _foreignPopularStoriesKey = '';
    _incomingFriendRequestsFuture = null;
    _incomingFriendRequestsKey = '';
    _guideReviewsFuture = null;
    _guideReviewsKey = '';
    _directGuideReviewsFuture = null;
    _directGuideReviewsKey = '';
    _activityReviewsFuture = null;
    _activityReviewsKey = '';
    _activityOrganizerReviewsFuture = null;
    _activityOrganizerReviewsKey = '';
    _blockStatusFuture = null;
    _blockStatusKey = '';
  }

  void _configureForeignProfileFuture() {
    _relationshipOverrideUserId = '';
    _blockStatusOverrideUserId = '';
    _followersCountOverride = null;
    _isFollowedByMeOverride = null;
    _isBlockedByMeOverride = null;
    _friendshipStatusOverride = null;
    _isFollowActionLoading = false;
    _isFriendshipActionLoading = false;
    _isMessageActionLoading = false;
    _isBlockActionLoading = false;
    _clearProfileDataFutures();

    final userId = widget.userId?.trim() ?? '';
    if (userId.isEmpty) {
      _foreignProfileFuture = null;
      _initialForeignProfile = null;
      return;
    }

    final initialProfile = widget.initialProfile;
    _initialForeignProfile =
        initialProfile != null && initialProfile.userId.trim() == userId
        ? initialProfile
        : null;

    final isAuthenticated = context.read<SessionProvider>().isAuthenticated;
    _foreignProfileFuture = isAuthenticated
        ? _profileApi.getUserById(userId)
        : _profileApi.getPublicUserById(userId);
  }

  UserProfileVm? _initialForeignProfileForBuilder(String requestedUserId) {
    final initialProfile = _initialForeignProfile;
    if (initialProfile == null ||
        initialProfile.userId.trim() != requestedUserId.trim()) {
      return null;
    }
    return _profileWithRelationshipOverrides(initialProfile);
  }

  UserProfileVm _profileWithRelationshipOverrides(UserProfileVm profile) {
    if (_relationshipOverrideUserId != profile.userId.trim()) {
      return profile;
    }

    return profile.copyWith(
      followersCount: _followersCountOverride,
      isFollowedByMe: _isFollowedByMeOverride,
      friendshipStatus: _friendshipStatusOverride,
    );
  }

  Future<void> _refreshProfile() async {
    final requestedUserId = widget.userId?.trim() ?? '';
    final session = context.read<SessionProvider>();
    final currentUserId = session.profile?.userId.trim() ?? '';
    final isOwnProfile =
        requestedUserId.isEmpty || requestedUserId == currentUserId;

    if (isOwnProfile) {
      await session.reloadProfile();
      if (!mounted) return;
      setState(_clearProfileDataFutures);
      return;
    }

    Future<UserProfileVm>? refreshedProfile;
    setState(() {
      _configureForeignProfileFuture();
      refreshedProfile = _foreignProfileFuture;
    });

    try {
      await refreshedProfile;
    } catch (_) {
      // FutureBuilder renders the failed refresh state; keep pull-to-refresh calm.
    }
  }

  Future<void> _toggleFollow(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isFollowActionLoading) {
      return;
    }

    final currentProfile = _profileWithRelationshipOverrides(profile);
    final willFollow = !currentProfile.isFollowedByMe;
    if (!willFollow) {
      final confirmed = await _confirmUnfollowUser();
      if (!confirmed || !mounted) {
        return;
      }
    }

    final nextFollowersCount =
        currentProfile.followersCount + (willFollow ? 1 : -1);

    setState(() {
      _relationshipOverrideUserId = userId;
      _isFollowedByMeOverride = willFollow;
      _followersCountOverride = nextFollowersCount < 0 ? 0 : nextFollowersCount;
      _isFollowActionLoading = true;
    });

    try {
      if (willFollow) {
        await _profileApi.followUser(userId);
      } else {
        await _profileApi.unfollowUser(userId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _relationshipOverrideUserId = userId;
        _isFollowedByMeOverride = currentProfile.isFollowedByMe;
        _followersCountOverride = currentProfile.followersCount;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileFollowUpdateFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowActionLoading = false;
        });
      }
    }
  }

  Future<void> _handleFriendshipAction(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isFriendshipActionLoading) {
      return;
    }

    final currentProfile = _profileWithRelationshipOverrides(profile);
    final currentStatus = currentProfile.friendshipStatus;
    if (currentStatus == UserFriendshipStatus.friends) {
      final confirmed = await _confirmRemoveFriend();
      if (!confirmed || !mounted) {
        return;
      }
    }

    final optimisticStatus = _optimisticFriendshipStatus(currentStatus);

    setState(() {
      _relationshipOverrideUserId = userId;
      _friendshipStatusOverride = optimisticStatus;
      _isFriendshipActionLoading = true;
    });

    try {
      final resolvedStatus = switch (currentStatus) {
        UserFriendshipStatus.none => await _profileApi.sendFriendRequest(
          userId,
        ),
        UserFriendshipStatus.outgoingRequest =>
          await _profileApi.cancelFriendRequest(userId),
        UserFriendshipStatus.incomingRequest =>
          await _profileApi.acceptFriendRequest(userId),
        UserFriendshipStatus.friends => await _profileApi.removeFriend(userId),
      };

      if (!mounted) return;
      setState(() {
        _relationshipOverrideUserId = userId;
        _friendshipStatusOverride = resolvedStatus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _relationshipOverrideUserId = userId;
        _friendshipStatusOverride = currentStatus;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileFriendshipUpdateFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFriendshipActionLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeclineFriendRequest(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isFriendshipActionLoading) {
      return;
    }

    final currentProfile = _profileWithRelationshipOverrides(profile);
    if (currentProfile.friendshipStatus !=
        UserFriendshipStatus.incomingRequest) {
      return;
    }

    setState(() {
      _relationshipOverrideUserId = userId;
      _friendshipStatusOverride = UserFriendshipStatus.none;
      _isFriendshipActionLoading = true;
    });

    try {
      final resolvedStatus = await _profileApi.declineFriendRequest(userId);
      if (!mounted) return;
      setState(() {
        _relationshipOverrideUserId = userId;
        _friendshipStatusOverride = resolvedStatus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _relationshipOverrideUserId = userId;
        _friendshipStatusOverride = currentProfile.friendshipStatus;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.profileFriendshipUpdateFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFriendshipActionLoading = false;
        });
      }
    }
  }

  UserFriendshipStatus _optimisticFriendshipStatus(
    UserFriendshipStatus status,
  ) {
    return switch (status) {
      UserFriendshipStatus.none => UserFriendshipStatus.outgoingRequest,
      UserFriendshipStatus.outgoingRequest => UserFriendshipStatus.none,
      UserFriendshipStatus.incomingRequest => UserFriendshipStatus.friends,
      UserFriendshipStatus.friends => UserFriendshipStatus.none,
    };
  }

  Future<bool> _confirmRemoveFriend() async {
    final l10n = AppLocalizations.of(context)!;
    return _showRelationshipConfirmDialog(
      title: l10n.profileRemoveFriendTitle,
      description: l10n.profileRemoveFriendDescription,
      confirmLabel: l10n.profileRemoveFriendConfirm,
      icon: Icons.person_remove_alt_1_rounded,
    );
  }

  Future<bool> _confirmUnfollowUser() async {
    final l10n = AppLocalizations.of(context)!;
    return _showRelationshipConfirmDialog(
      title: l10n.profileUnfollowTitle,
      description: l10n.profileUnfollowDescription,
      confirmLabel: l10n.profileUnfollowConfirm,
      icon: Icons.visibility_off_rounded,
    );
  }

  Future<bool> _showRelationshipConfirmDialog({
    required String title,
    required String description,
    required String confirmLabel,
    required IconData icon,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _ProfileRelationshipConfirmDialog(
          title: title,
          description: description,
          cancelLabel: l10n.cancel,
          confirmLabel: confirmLabel,
          icon: icon,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );
    return result == true;
  }

  Future<void> _openDirectChat(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isMessageActionLoading) {
      return;
    }

    setState(() => _isMessageActionLoading = true);

    try {
      final conversationId = await _chatApi.createDirectConversation(userId);
      if (!mounted) return;
      context.push('/chats/$conversationId');
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileMessageOpenFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) {
        setState(() => _isMessageActionLoading = false);
      }
    }
  }

  Future<void> _openLoginForProtectedAction() async {
    context.push('/login');
  }

  Future<void> _toggleBlockUser(
    UserProfileVm profile,
    bool isBlockedByMe,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isBlockActionLoading) {
      return;
    }

    setState(() {
      _blockStatusOverrideUserId = userId;
      _isBlockedByMeOverride = !isBlockedByMe;
      _isBlockActionLoading = true;
    });

    try {
      final status = isBlockedByMe
          ? await _chatApi.unblockUser(userId)
          : await _chatApi.blockUser(userId);
      if (!mounted) return;
      setState(() {
        _blockStatusOverrideUserId = userId;
        _isBlockedByMeOverride = status.isBlockedByMe;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _blockStatusOverrideUserId = userId;
        _isBlockedByMeOverride = isBlockedByMe;
      });
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.chatUserBlockUpdateFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isBlockActionLoading = false);
      }
    }
  }

  Future<_ProfileExtras> _loadExtras(
    UserProfileVm profile, {
    required bool publicRead,
  }) async {
    Future<GuideProfileVm?> loadGuide() async {
      try {
        if (publicRead) {
          return await _guideApi.getPublicGuideProfileByUserIdOrNull(
            profile.userId,
          );
        }
        return await _guideApi.getGuideProfileByUserIdOrNull(profile.userId);
      } catch (_) {
        return null;
      }
    }

    Future<String?> loadAvatar() async {
      final avatarFileId = (profile.avatarFileId ?? '').trim();
      if (avatarFileId.isEmpty) {
        return null;
      }
      return _fileApi.publicContentUrl(avatarFileId);
    }

    final results = await Future.wait<Object?>([loadGuide(), loadAvatar()]);

    return _ProfileExtras(
      guide: results[0] as GuideProfileVm?,
      avatarUrl: results[1] as String?,
    );
  }

  Future<UserBlockStatusVm> _blockStatusFutureFor(UserProfileVm profile) {
    final key = profile.userId.trim();
    if (_blockStatusFuture == null || _blockStatusKey != key) {
      _blockStatusKey = key;
      _blockStatusFuture = _chatApi.getUserBlockStatus(key);
    }
    return _blockStatusFuture!;
  }

  Future<_ProfileExtras> _extrasFutureFor(
    UserProfileVm profile, {
    required bool publicRead,
  }) {
    final key =
        '${profile.userId.trim()}|${(profile.avatarFileId ?? '').trim()}|${profile.roles.join(",")}|$publicRead';
    if (_extrasFuture == null || _extrasKey != key) {
      _extrasKey = key;
      _extrasFuture = _loadExtras(profile, publicRead: publicRead);
    }
    return _extrasFuture!;
  }

  Future<int> _activityCountFutureFor(UserProfileVm profile) {
    final key = profile.userId.trim();
    if (_activityCountFuture == null || _activityCountKey != key) {
      _activityCountKey = key;
      _activityCountFuture = _activityApi.countCompletedActivitiesForUser(
        profile.userId.trim(),
      );
    }
    return _activityCountFuture!;
  }

  Future<List<ActivityListItemVm>> _recentActivitiesFutureFor(
    UserProfileVm profile,
  ) {
    final key =
        '${profile.userId.trim()}|$_foreignProfileRecentActivitiesPreviewLimit';
    if (_foreignRecentActivitiesFuture == null ||
        _foreignRecentActivitiesKey != key) {
      _foreignRecentActivitiesKey = key;
      _foreignRecentActivitiesFuture = _activityApi.getUserRecentActivities(
        profile.userId.trim(),
        limit: _foreignProfileRecentActivitiesPreviewLimit,
      );
    }
    return _foreignRecentActivitiesFuture!;
  }

  Future<List<PostVm>> _popularStoriesFutureFor(UserProfileVm profile) {
    final key =
        '${profile.userId.trim()}|$_foreignProfilePopularStoriesPreviewLimit';
    if (_foreignPopularStoriesFuture == null ||
        _foreignPopularStoriesKey != key) {
      _foreignPopularStoriesKey = key;
      _foreignPopularStoriesFuture = _postApi.getUserPopularPosts(
        profile.userId.trim(),
        limit: _foreignProfilePopularStoriesPreviewLimit,
      );
    }
    return _foreignPopularStoriesFuture!;
  }

  Future<ProfileFollowersPageVm> _incomingFriendRequestsFutureFor() {
    const key = 'me|incoming-friend-requests|1';
    if (_incomingFriendRequestsFuture == null ||
        _incomingFriendRequestsKey != key) {
      _incomingFriendRequestsKey = key;
      _incomingFriendRequestsFuture = _profileApi.getMyIncomingFriendRequests(
        limit: 1,
      );
    }
    return _incomingFriendRequestsFuture!;
  }

  Future<int> _publishedStoriesCountFutureFor(UserProfileVm profile) {
    final key = profile.userId.trim();
    if (_publishedStoriesCountFuture == null ||
        _publishedStoriesCountKey != key) {
      _publishedStoriesCountKey = key;
      _publishedStoriesCountFuture = _postApi.countPublishedPostsForUser(
        profile.userId.trim(),
      );
    }
    return _publishedStoriesCountFuture!;
  }

  Future<ExcursionReviewsPage> _guideReviewsFutureFor(UserProfileVm profile) {
    final key = '${profile.userId.trim()}|rating_desc|10';
    if (_guideReviewsFuture == null || _guideReviewsKey != key) {
      _guideReviewsKey = key;
      _guideReviewsFuture = _excursionApi.getGuideExcursionReviews(
        guideUserId: profile.userId.trim(),
        limit: 10,
        sort: 'rating_desc',
      );
    }
    return _guideReviewsFuture!;
  }

  Future<GuideReviewsPage> _directGuideReviewsFutureFor(UserProfileVm profile) {
    final key = '${profile.userId.trim()}|rating_desc|10|direct';
    if (_directGuideReviewsFuture == null || _directGuideReviewsKey != key) {
      _directGuideReviewsKey = key;
      _directGuideReviewsFuture = _excursionApi.getGuideReviews(
        guideUserId: profile.userId.trim(),
        limit: 10,
        sort: 'rating_desc',
      );
    }
    return _directGuideReviewsFuture!;
  }

  Future<ActivityReviewsPage> _activityReviewsFutureFor(UserProfileVm profile) {
    final key = '${profile.userId.trim()}|rating_desc|10|activity';
    if (_activityReviewsFuture == null || _activityReviewsKey != key) {
      _activityReviewsKey = key;
      _activityReviewsFuture = _activityApi.getActivityReviews(
        hostUserId: profile.userId.trim(),
        limit: 10,
        sort: 'rating_desc',
      );
    }
    return _activityReviewsFuture!;
  }

  Future<ActivityOrganizerReviewsPage> _activityOrganizerReviewsFutureFor(
    UserProfileVm profile,
  ) {
    final key = '${profile.userId.trim()}|rating_desc|10|activity_organizer';
    if (_activityOrganizerReviewsFuture == null ||
        _activityOrganizerReviewsKey != key) {
      _activityOrganizerReviewsKey = key;
      _activityOrganizerReviewsFuture = _activityApi
          .getActivityOrganizerReviews(
            hostUserId: profile.userId.trim(),
            limit: 10,
            sort: 'rating_desc',
          );
    }
    return _activityOrganizerReviewsFuture!;
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AndroidBackSwipeScope(child: EditProfileScreen()),
      ),
    );

    if (updated == true && mounted) {
      await context.read<SessionProvider>().reloadProfile();
      if (!mounted) return;
      setState(_clearProfileDataFutures);
    }
  }

  void _openSettings() {
    context.push('/profile/settings');
  }

  Future<void> _copyProfileLink(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final path = '/users/${profile.userId}/profile';
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileLinkCopied)));
  }

  void _openFollowers(UserProfileVm profile) {
    final userId = profile.userId.trim();
    if (userId.isEmpty) return;
    context.push('/users/${Uri.encodeComponent(userId)}/followers');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.watch<SessionProvider>();
    final requestedUserId = widget.userId?.trim() ?? '';
    final currentUserId = session.profile?.userId.trim() ?? '';
    final isOwnProfile =
        requestedUserId.isEmpty || requestedUserId == currentUserId;

    return Scaffold(
      key: ValueKey(
        'profile-screen-${requestedUserId.isEmpty ? 'me' : requestedUserId}',
      ),
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              child: isOwnProfile
                  ? _buildResolvedProfile(
                      context,
                      session.profile,
                      isOwnProfile: true,
                      isAuthenticated: session.isAuthenticated,
                    )
                  : FutureBuilder<UserProfileVm>(
                      future: _foreignProfileFuture,
                      initialData: _initialForeignProfileForBuilder(
                        requestedUserId,
                      ),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            profile == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError && profile == null) {
                          return Center(
                            child: Text(
                              l10n.profileNotAvailable,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }

                        if (profile == null) {
                          return Center(
                            child: Text(
                              l10n.profileNotAvailable,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }

                        return _buildResolvedProfile(
                          context,
                          profile,
                          isOwnProfile: false,
                          isAuthenticated: session.isAuthenticated,
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResolvedProfile(
    BuildContext context,
    UserProfileVm? profile, {
    required bool isOwnProfile,
    required bool isAuthenticated,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (profile == null) {
      return Center(
        child: Text(
          l10n.profileNotAvailable,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    final effectiveProfile = _profileWithRelationshipOverrides(profile);
    final publicRead = !isOwnProfile;
    final canUseProtectedActions = isAuthenticated;
    final Future<void> Function()? onToggleFollow = isOwnProfile
        ? null
        : canUseProtectedActions
        ? () => _toggleFollow(effectiveProfile)
        : _openLoginForProtectedAction;
    final Future<void> Function()? onFriendshipAction = isOwnProfile
        ? null
        : canUseProtectedActions
        ? () => _handleFriendshipAction(effectiveProfile)
        : _openLoginForProtectedAction;
    final Future<void> Function()? onDeclineFriendship = isOwnProfile
        ? null
        : canUseProtectedActions
        ? () => _handleDeclineFriendRequest(effectiveProfile)
        : _openLoginForProtectedAction;
    final Future<void> Function()? onMessageTap = isOwnProfile
        ? null
        : canUseProtectedActions
        ? () => _openDirectChat(effectiveProfile)
        : _openLoginForProtectedAction;
    final Future<void> Function(bool isBlockedByMe)? onToggleBlock =
        isOwnProfile
        ? null
        : canUseProtectedActions
        ? (isBlockedByMe) => _toggleBlockUser(effectiveProfile, isBlockedByMe)
        : (_) => _openLoginForProtectedAction();
    final VoidCallback onFollowersTap = isOwnProfile || canUseProtectedActions
        ? () => _openFollowers(effectiveProfile)
        : _openLoginForProtectedAction;

    return FutureBuilder<_ProfileExtras>(
      future: _extrasFutureFor(effectiveProfile, publicRead: publicRead),
      builder: (context, snapshot) {
        final extras = snapshot.data ?? const _ProfileExtras();
        return _ProfileBody(
          profile: effectiveProfile,
          guide: extras.guide,
          avatarUrl: extras.avatarUrl,
          guideReviewsFuture: !isOwnProfile && extras.guide?.isVerified == true
              ? _guideReviewsFutureFor(effectiveProfile)
              : null,
          directGuideReviewsFuture:
              !isOwnProfile && extras.guide?.isVerified == true
              ? _directGuideReviewsFutureFor(effectiveProfile)
              : null,
          activityReviewsFuture: !isOwnProfile
              ? _activityReviewsFutureFor(effectiveProfile)
              : null,
          activityOrganizerReviewsFuture: !isOwnProfile
              ? _activityOrganizerReviewsFutureFor(effectiveProfile)
              : null,
          blockStatusFuture: isOwnProfile
              ? null
              : !canUseProtectedActions
              ? null
              : _blockStatusFutureFor(effectiveProfile),
          recentActivitiesFuture: _recentActivitiesFutureFor(effectiveProfile),
          popularStoriesFuture: _popularStoriesFutureFor(effectiveProfile),
          incomingFriendRequestsFuture: isOwnProfile
              ? _incomingFriendRequestsFutureFor()
              : null,
          activityCountFuture: _activityCountFutureFor(effectiveProfile),
          publishedStoriesCountFuture: _publishedStoriesCountFutureFor(
            effectiveProfile,
          ),
          isOwnProfile: isOwnProfile,
          isFollowActionLoading: _isFollowActionLoading,
          isFriendshipActionLoading: _isFriendshipActionLoading,
          isMessageActionLoading: _isMessageActionLoading,
          isBlockActionLoading: _isBlockActionLoading,
          isBlockedByMeOverride:
              _blockStatusOverrideUserId == effectiveProfile.userId.trim()
              ? _isBlockedByMeOverride
              : null,
          onToggleFollow: onToggleFollow,
          onFriendshipAction: onFriendshipAction,
          onDeclineFriendship: onDeclineFriendship,
          onMessageTap: onMessageTap,
          onToggleBlock: onToggleBlock,
          onSettingsTap: isOwnProfile ? _openSettings : null,
          onEditProfile: isOwnProfile ? _openEditProfile : null,
          onCopyProfileLink: () => _copyProfileLink(effectiveProfile),
          onFollowersTap: onFollowersTap,
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.guide,
    required this.avatarUrl,
    required this.guideReviewsFuture,
    required this.directGuideReviewsFuture,
    required this.activityReviewsFuture,
    required this.activityOrganizerReviewsFuture,
    required this.blockStatusFuture,
    required this.recentActivitiesFuture,
    required this.popularStoriesFuture,
    required this.incomingFriendRequestsFuture,
    required this.activityCountFuture,
    required this.publishedStoriesCountFuture,
    required this.isOwnProfile,
    required this.isFollowActionLoading,
    required this.isFriendshipActionLoading,
    required this.isMessageActionLoading,
    required this.isBlockActionLoading,
    required this.isBlockedByMeOverride,
    required this.onToggleFollow,
    required this.onFriendshipAction,
    required this.onDeclineFriendship,
    required this.onMessageTap,
    required this.onToggleBlock,
    required this.onSettingsTap,
    required this.onCopyProfileLink,
    required this.onEditProfile,
    required this.onFollowersTap,
  });

  final UserProfileVm profile;
  final GuideProfileVm? guide;
  final String? avatarUrl;
  final Future<ExcursionReviewsPage>? guideReviewsFuture;
  final Future<GuideReviewsPage>? directGuideReviewsFuture;
  final Future<ActivityReviewsPage>? activityReviewsFuture;
  final Future<ActivityOrganizerReviewsPage>? activityOrganizerReviewsFuture;
  final Future<UserBlockStatusVm>? blockStatusFuture;
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;
  final Future<List<PostVm>>? popularStoriesFuture;
  final Future<ProfileFollowersPageVm>? incomingFriendRequestsFuture;
  final Future<int> activityCountFuture;
  final Future<int> publishedStoriesCountFuture;
  final bool isOwnProfile;
  final bool isFollowActionLoading;
  final bool isFriendshipActionLoading;
  final bool isMessageActionLoading;
  final bool isBlockActionLoading;
  final bool? isBlockedByMeOverride;
  final Future<void> Function()? onToggleFollow;
  final Future<void> Function()? onFriendshipAction;
  final Future<void> Function()? onDeclineFriendship;
  final Future<void> Function()? onMessageTap;
  final Future<void> Function(bool isBlockedByMe)? onToggleBlock;
  final VoidCallback? onSettingsTap;
  final VoidCallback onCopyProfileLink;
  final Future<void> Function()? onEditProfile;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final isGuideProfile = guide?.isVerified == true;
    final l10n = AppLocalizations.of(context)!;
    final padding = profileScaled(context, 20, min: 14, max: 20);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        padding,
        profileScaled(context, 14, min: 10, max: 18),
        padding,
        profileScaled(context, 28, min: 20, max: 34),
      ),
      children: [
        _buildProfileTopBar(context, l10n),
        SizedBox(height: profileScaled(context, 26, min: 18, max: 30)),
        if (isOwnProfile && !profile.isProfileCompleted)
          Padding(
            padding: EdgeInsets.only(
              bottom: profileScaled(context, 18, min: 14, max: 18),
            ),
            child: _ProfileBanner(
              title: l10n.profileIncompleteTitle,
              subtitle: l10n.profileIncompleteDescription,
              onTap: onEditProfile,
            ),
          ),
        _ProfileHero(
          profile: profile,
          guide: guide,
          avatarUrl: avatarUrl,
          isOwnProfile: isOwnProfile,
          isGuideProfile: isGuideProfile,
          actions: !isOwnProfile
              ? _ProfileHeroActions(
                  isGuideProfile: isGuideProfile,
                  isFollowedByMe: profile.isFollowedByMe,
                  friendshipStatus: profile.friendshipStatus,
                  isFollowActionLoading: isFollowActionLoading,
                  isFriendshipActionLoading: isFriendshipActionLoading,
                  isMessageActionLoading: isMessageActionLoading,
                  onToggleFollow: onToggleFollow,
                  onFriendshipAction: onFriendshipAction,
                  onDeclineFriendship: onDeclineFriendship,
                  onMessageTap: onMessageTap,
                  onGuideCalendarTap: isGuideProfile
                      ? () => context.push('/guides/${profile.userId}/calendar')
                      : null,
                )
              : null,
        ),
        SizedBox(height: profileScaled(context, 20, min: 16, max: 24)),
        if (!isGuideProfile && isOwnProfile)
          _BecomeGuideCard(
            guide: guide,
            onTap: () => context.push('/profile/guide-verification'),
          ),
        if (!isGuideProfile && isOwnProfile)
          SizedBox(height: profileScaled(context, 22, min: 16, max: 24)),
        _ProfileStatsGrid(
          profile: profile,
          activityCountFuture: activityCountFuture,
          publishedStoriesCountFuture: publishedStoriesCountFuture,
          onFollowersTap: onFollowersTap,
        ),
        SizedBox(height: profileScaled(context, 32, min: 24, max: 36)),
        if (isOwnProfile) ...[
          _OwnProfileSections(
            userId: profile.userId,
            isGuideProfile: isGuideProfile,
            incomingFriendRequestsFuture: incomingFriendRequestsFuture,
            recentActivitiesFuture: recentActivitiesFuture,
            popularStoriesFuture: popularStoriesFuture,
          ),
        ] else ...[
          _ForeignProfileSections(
            userId: profile.userId,
            isGuideProfile: isGuideProfile,
            guideReviewsFuture: guideReviewsFuture,
            directGuideReviewsFuture: directGuideReviewsFuture,
            activityReviewsFuture: activityReviewsFuture,
            activityOrganizerReviewsFuture: activityOrganizerReviewsFuture,
            recentActivitiesFuture: recentActivitiesFuture,
            popularStoriesFuture: popularStoriesFuture,
          ),
        ],
      ],
    );
  }

  Widget _buildProfileTopBar(BuildContext context, AppLocalizations l10n) {
    final title = isOwnProfile ? l10n.myProfileTitle : profile.preferredName;
    final leadingTap = isOwnProfile ? onSettingsTap : () => context.pop();

    if (isOwnProfile || blockStatusFuture == null) {
      return _ProfileTopBar(
        isOwnProfile: isOwnProfile,
        title: title,
        onLeadingTap: leadingTap,
        onShareTap: onCopyProfileLink,
      );
    }

    return FutureBuilder<UserBlockStatusVm>(
      future: blockStatusFuture,
      builder: (context, snapshot) {
        final isBlockedByMe =
            isBlockedByMeOverride ?? snapshot.data?.isBlockedByMe ?? false;
        return _ProfileTopBar(
          isOwnProfile: isOwnProfile,
          title: title,
          onLeadingTap: leadingTap,
          onShareTap: onCopyProfileLink,
          isBlockedByMe: isBlockedByMe,
          isBlockActionLoading: isBlockActionLoading,
          onToggleBlock: onToggleBlock == null
              ? null
              : () => onToggleBlock!(isBlockedByMe),
        );
      },
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.isOwnProfile,
    required this.title,
    required this.onLeadingTap,
    required this.onShareTap,
    this.isBlockedByMe = false,
    this.isBlockActionLoading = false,
    this.onToggleBlock,
  });

  final bool isOwnProfile;
  final String title;
  final VoidCallback? onLeadingTap;
  final VoidCallback onShareTap;
  final bool isBlockedByMe;
  final bool isBlockActionLoading;
  final VoidCallback? onToggleBlock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileTopIconButton(
          icon: isOwnProfile ? Icons.settings_outlined : Icons.arrow_back,
          onTap: onLeadingTap,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileTopIconButton(
              icon: Icons.ios_share_outlined,
              onTap: onShareTap,
            ),
            if (!isOwnProfile && onToggleBlock != null) ...[
              SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
              PopupMenuButton<_ProfileTopMenuAction>(
                enabled: !isBlockActionLoading,
                color: profileSurface,
                elevation: 10,
                onSelected: (_) => onToggleBlock?.call(),
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return [
                    PopupMenuItem(
                      value: _ProfileTopMenuAction.toggleBlock,
                      child: Row(
                        children: [
                          Icon(
                            isBlockedByMe
                                ? Icons.lock_open_rounded
                                : Icons.block_rounded,
                            color: isBlockedByMe
                                ? AppColors.accent
                                : AppColors.destruct,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isBlockedByMe
                                ? l10n.chatUnblockUserAction
                                : l10n.chatBlockUserAction,
                            style: TextStyle(
                              color: isBlockedByMe
                                  ? AppColors.textPrimary
                                  : AppColors.destruct,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                child: ProfileTopIconButton(
                  icon: Icons.more_vert_rounded,
                  onTap: null,
                  disabled: isBlockActionLoading,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

enum _ProfileTopMenuAction { toggleBlock }

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.guide,
    required this.avatarUrl,
    required this.isOwnProfile,
    required this.isGuideProfile,
    required this.actions,
  });

  final UserProfileVm profile;
  final GuideProfileVm? guide;
  final String? avatarUrl;
  final bool isOwnProfile;
  final bool isGuideProfile;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bio = _resolveAboutText(l10n);
    final badges = _topBadges(l10n);
    final fullName = profile.fullName;

    return Column(
      children: [
        _ProfileAvatar(
          initials: profile.initials,
          avatarUrl: avatarUrl,
          verified: guide?.isVerified == true,
        ),
        SizedBox(height: profileScaled(context, 22, min: 16, max: 24)),
        Text(
          profile.preferredName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: profileScaled(context, 30, min: 24, max: 34),
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.04,
          ),
        ),
        if (fullName.isNotEmpty && fullName != profile.preferredName) ...[
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Text(
            fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: profileTextSoft,
              fontSize: profileScaled(context, 15, min: 13, max: 16),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              height: 1.25,
            ),
          ),
        ],
        if (isGuideProfile) ...[
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Text(
            guide?.isVerified == true
                ? l10n.profileVerifiedExplorer
                : l10n.profileGuideTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: profileScaled(context, 13, min: 12, max: 13),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          if (guide?.isVerified == true) ...[
            SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
            _GuideRatingBadge(guide: guide!),
          ],
        ],
        if (badges.isNotEmpty) ...[
          SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: profileScaled(context, 10, min: 8, max: 10),
            runSpacing: profileScaled(context, 10, min: 8, max: 10),
            children: badges
                .take(6)
                .map((item) => _ProfilePill(text: item))
                .toList(growable: false),
          ),
        ],
        if (actions != null) ...[
          SizedBox(height: profileScaled(context, 20, min: 16, max: 22)),
          actions!,
        ],
        SizedBox(height: profileScaled(context, 22, min: 18, max: 24)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
          decoration: profileCardDecoration(
            context,
            highlighted: isGuideProfile,
            radius: profileScaled(context, 26, min: 22, max: 28),
          ),
          child: Text(
            bio,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: profileScaled(context, 15, min: 14, max: 16),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  String _resolveAboutText(AppLocalizations l10n) {
    final guideAbout = (guide?.about ?? '').trim();
    if (guideAbout.isNotEmpty) {
      return guideAbout;
    }

    final guideHeadline = (guide?.headline ?? '').trim();
    if (guideHeadline.isNotEmpty) {
      return guideHeadline;
    }

    final bio = (profile.bio ?? '').trim();
    if (bio.isNotEmpty) {
      return bio;
    }

    return l10n.profileEmptyBioPlaceholder;
  }

  List<String> _topBadges(AppLocalizations l10n) {
    final values = <String>[];

    if (guide != null) {
      for (final item in guide!.serviceBadges) {
        final normalized = _humanizeToken(item);
        if (normalized.isNotEmpty) {
          values.add(normalized);
        }
      }
    }

    return values.toSet().toList(growable: false);
  }

  String _humanizeToken(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ');
    final words = normalized.split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}

class _GuideRatingBadge extends StatelessWidget {
  const _GuideRatingBadge({required this.guide});

  final GuideProfileVm guide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rating = guide.ratingAvg <= 0
        ? '0.0'
        : guide.ratingAvg.toStringAsFixed(1);
    final maxWidth =
        MediaQuery.sizeOf(context).width -
        profileScaled(context, 56, min: 36, max: 56);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: profileScaled(context, 12, min: 10, max: 12),
            vertical: profileScaled(context, 7, min: 6, max: 7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.profileGuideRatingLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 12, min: 11, max: 12),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(width: profileScaled(context, 6, min: 5, max: 6)),
              Icon(
                Icons.star_rounded,
                size: profileScaled(context, 17, min: 15, max: 17),
                color: AppColors.accent,
              ),
              SizedBox(width: profileScaled(context, 6, min: 5, max: 6)),
              Flexible(
                child: Text(
                  rating,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: profileScaled(context, 13, min: 12, max: 13),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.initials,
    required this.avatarUrl,
    required this.verified,
  });

  final String initials;
  final String? avatarUrl;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final size = profileScaled(context, 150, min: 120, max: 160);
    final badgeSize = profileScaled(context, 34, min: 28, max: 36);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(profileScaled(context, 5, min: 4, max: 6)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE5C48D), Color(0xFF8B5506)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: profileScaled(context, 22, min: 16, max: 24),
                  offset: Offset(
                    0,
                    profileScaled(context, 10, min: 6, max: 10),
                  ),
                ),
              ],
            ),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEEF3F6), Color(0xFFB9CAD5)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.92),
                    width: profileScaled(context, 4, min: 3, max: 4),
                  ),
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: const Color(0xFF516572),
                            fontSize: profileScaled(
                              context,
                              44,
                              min: 34,
                              max: 48,
                            ),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      )
                    : Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: const Color(0xFF516572),
                              fontSize: profileScaled(
                                context,
                                44,
                                min: 34,
                                max: 48,
                              ),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (verified)
            Positioned(
              right: profileScaled(context, -2, min: -2, max: 2),
              bottom: profileScaled(context, 14, min: 10, max: 16),
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: profileBgTop,
                    width: profileScaled(context, 3, min: 2, max: 3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: profileScaled(context, 14, min: 10, max: 16),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: profileScaled(context, 16, min: 14, max: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 14, min: 12, max: 16),
        vertical: profileScaled(context, 8, min: 7, max: 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: profileScaled(context, 12, min: 11, max: 12),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accent,
            size: profileScaled(context, 24, min: 20, max: 24),
          ),
          SizedBox(width: profileScaled(context, 12, min: 10, max: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: profileScaled(context, 16, min: 14, max: 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 13, min: 12, max: 13),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                AppLocalizations.of(context)!.editProfileButton,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _BecomeGuideCard extends StatelessWidget {
  const _BecomeGuideCard({required this.guide, required this.onTap});

  final GuideProfileVm? guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = guide?.isPendingReview == true;
    final isRejected = guide?.isRejected == true;
    final isDraft = guide?.isDraft == true;
    final isRevoked = guide?.isRevoked == true;

    final title = isPending
        ? l10n.guideVerificationPendingTitle
        : isRevoked
        ? l10n.guideVerificationRevokedTitle
        : isRejected
        ? l10n.guideVerificationRejectedTitle
        : l10n.profileBecomeGuideTitle;
    final subtitle = isPending
        ? l10n.guideVerificationPendingSubtitle
        : isRevoked
        ? _revokedGuideSubtitle(l10n, guide)
        : isRejected
        ? l10n.guideVerificationRejectedSubtitle
        : isDraft
        ? l10n.guideVerificationDraftSubtitle
        : l10n.profileBecomeGuideSubtitle;
    final buttonLabel = isPending
        ? l10n.guideVerificationViewApplicationButton
        : isRevoked
        ? l10n.guideVerificationRevokedButton
        : isRejected || isDraft
        ? l10n.guideVerificationContinueButton
        : l10n.becomeGuideButton;

    return Container(
      padding: EdgeInsets.all(profileScaled(context, 18, min: 16, max: 20)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 30, min: 24, max: 34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: profileScaled(context, 44, min: 40, max: 48),
                height: profileScaled(context, 44, min: 40, max: 48),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending
                      ? Icons.hourglass_bottom_rounded
                      : isRevoked
                      ? Icons.block_rounded
                      : Icons.explore_outlined,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 15, min: 14, max: 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 4, min: 4, max: 6)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: profileTextMuted,
                        fontSize: profileScaled(context, 12, min: 11, max: 13),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isRevoked ? null : onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  String _revokedGuideSubtitle(AppLocalizations l10n, GuideProfileVm? guide) {
    final reason = guide?.statusReason?.trim() ?? '';
    if (reason.isEmpty) {
      return l10n.guideVerificationRevokedSubtitle;
    }
    return l10n.guideVerificationRevokedSubtitleWithReason(reason);
  }
}

class _ProfileStatsGrid extends StatelessWidget {
  const _ProfileStatsGrid({
    required this.profile,
    required this.activityCountFuture,
    required this.publishedStoriesCountFuture,
    this.onFollowersTap,
  });

  final UserProfileVm profile;
  final Future<int> activityCountFuture;
  final Future<int> publishedStoriesCountFuture;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<int>(
      future: activityCountFuture,
      builder: (context, snapshot) {
        final activityCount = snapshot.data;
        final activityCountLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            activityCount == null;
        return FutureBuilder<int>(
          future: publishedStoriesCountFuture,
          builder: (context, storiesSnapshot) {
            final publishedStoriesCount = storiesSnapshot.data;
            final publishedStoriesCountLoading =
                storiesSnapshot.connectionState == ConnectionState.waiting &&
                publishedStoriesCount == null;
            final cards = <_StatConfig>[
              _StatConfig(
                label: l10n.profileActivitiesStat,
                value: activityCount == null ? '—' : '$activityCount',
                highlighted: true,
                isLoading: activityCountLoading,
              ),
              _StatConfig(
                label: l10n.profileStoriesStat,
                value: publishedStoriesCount == null
                    ? '—'
                    : '$publishedStoriesCount',
                highlighted: true,
                isLoading: publishedStoriesCountLoading,
              ),
              _StatConfig(
                label: l10n.profileFollowersStat,
                value: '${profile.followersCount}',
                highlighted: true,
                onTap: onFollowersTap,
              ),
            ];

            return _StatsGridLayout(cards: cards);
          },
        );
      },
    );
  }
}

class _StatsGridLayout extends StatelessWidget {
  const _StatsGridLayout({required this.cards});

  final List<_StatConfig> cards;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = cards.length >= 4 ? 2 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: profileScaled(context, 14, min: 10, max: 14),
        crossAxisSpacing: profileScaled(context, 14, min: 10, max: 14),
        mainAxisExtent: profileScaled(context, 122, min: 104, max: 132),
      ),
      itemBuilder: (context, index) => _ProfileStatCard(config: cards[index]),
    );
  }
}

class _StatConfig {
  const _StatConfig({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool isLoading;
  final VoidCallback? onTap;
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({required this.config});

  final _StatConfig config;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 8, min: 6, max: 10),
        vertical: profileScaled(context, 14, min: 10, max: 16),
      ),
      decoration: profileCardDecoration(
        context,
        highlighted: config.highlighted,
        radius: profileScaled(context, 20, min: 18, max: 22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (config.isLoading)
            SizedBox(
              width: profileScaled(context, 24, min: 20, max: 24),
              height: profileScaled(context, 24, min: 20, max: 24),
              child: const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            )
          else
            Text(
              config.value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: profileScaled(context, 24, min: 20, max: 28),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
          Text(
            config.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: profileTextSoft,
              fontSize: profileScaled(context, 11, min: 10, max: 11),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );

    if (config.onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: config.onTap,
        borderRadius: BorderRadius.circular(
          profileScaled(context, 20, min: 18, max: 22),
        ),
        child: child,
      ),
    );
  }
}

class _ProfileRelationshipConfirmDialog extends StatelessWidget {
  const _ProfileRelationshipConfirmDialog({
    required this.title,
    required this.description,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.icon,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String description;
  final String cancelLabel;
  final String confirmLabel;
  final IconData icon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 375;
    final maxDialogHeight =
        (mediaQuery.size.height - mediaQuery.viewPadding.vertical - 48)
            .clamp(300.0, mediaQuery.size.height)
            .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 386, maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            profileScaled(context, 28, min: 24, max: 28),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2B1808).withValues(alpha: 0.99),
                  const Color(0xFF201208),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 22 : 26,
                  isCompact ? 22 : 26,
                  isCompact ? 22 : 26,
                  isCompact ? 20 : 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: profileScaled(context, 56, min: 52, max: 58),
                      height: profileScaled(context, 56, min: 52, max: 58),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.95),
                            const Color(0xFFFFC46A),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF1D1711),
                        size: profileScaled(context, 27, min: 25, max: 28),
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 20, min: 18, max: 20),
                    ),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 23, min: 21, max: 23),
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 10, min: 8, max: 10),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: profileTextSoft.withValues(alpha: 0.9),
                        fontSize: profileScaled(context, 15, min: 14, max: 15),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 26, min: 22, max: 26),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale = MediaQuery.of(
                          context,
                        ).textScaler.scale(1);
                        final shouldStack =
                            constraints.maxWidth < 318 || textScale > 1.25;
                        final actionWidth = shouldStack
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            SizedBox(
                              width: actionWidth,
                              child: _ActivitiesStyleConfirmAction(
                                label: cancelLabel,
                                onTap: onCancel,
                                isPrimary: false,
                              ),
                            ),
                            SizedBox(
                              width: actionWidth,
                              child: _ActivitiesStyleConfirmAction(
                                label: confirmLabel,
                                onTap: onConfirm,
                                isPrimary: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivitiesStyleConfirmAction extends StatelessWidget {
  const _ActivitiesStyleConfirmAction({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary
        ? const Color(0xFF1D1711)
        : AppColors.textPrimary.withValues(alpha: 0.92);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB347), Color(0xFFFFD083)],
                    )
                  : null,
              color: isPrimary ? null : Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : AppColors.accent.withValues(alpha: 0.20),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: profileScaled(context, 15, min: 14, max: 15),
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroActions extends StatelessWidget {
  const _ProfileHeroActions({
    required this.isGuideProfile,
    required this.isFollowedByMe,
    required this.friendshipStatus,
    required this.isFollowActionLoading,
    required this.isFriendshipActionLoading,
    required this.isMessageActionLoading,
    required this.onToggleFollow,
    required this.onFriendshipAction,
    required this.onDeclineFriendship,
    required this.onMessageTap,
    required this.onGuideCalendarTap,
  });

  final bool isGuideProfile;
  final bool isFollowedByMe;
  final UserFriendshipStatus friendshipStatus;
  final bool isFollowActionLoading;
  final bool isFriendshipActionLoading;
  final bool isMessageActionLoading;
  final Future<void> Function()? onToggleFollow;
  final Future<void> Function()? onFriendshipAction;
  final Future<void> Function()? onDeclineFriendship;
  final Future<void> Function()? onMessageTap;
  final VoidCallback? onGuideCalendarTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gap = profileScaled(context, 12, min: 10, max: 14);
    final actions = <Widget>[
      _ProfileHeroActionButton(
        icon: Icons.chat_bubble_outline_rounded,
        label: l10n.profileMessageAction,
        isBusy: isMessageActionLoading,
        selected: true,
        onTap: isMessageActionLoading ? null : () async => onMessageTap?.call(),
      ),
      _ProfileHeroActionButton(
        icon: isFollowedByMe
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        label: isFollowedByMe
            ? l10n.profileFollowingAction
            : l10n.profileFollowAction,
        isBusy: isFollowActionLoading,
        selected: isFollowedByMe,
        onTap: isFollowActionLoading
            ? null
            : () async => onToggleFollow?.call(),
      ),
      ..._friendshipActions(l10n),
      if (isGuideProfile && onGuideCalendarTap != null)
        _ProfileHeroActionButton(
          icon: Icons.calendar_month_rounded,
          label: l10n.guideCalendarTitle,
          selected: true,
          onTap: onGuideCalendarTap,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 2, min: 0, max: 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            actions[i],
            if (i != actions.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }

  List<Widget> _friendshipActions(AppLocalizations l10n) {
    return switch (friendshipStatus) {
      UserFriendshipStatus.none => [
        _ProfileHeroActionButton(
          icon: Icons.person_add_alt_1_rounded,
          label: l10n.profileAddFriendAction,
          isBusy: isFriendshipActionLoading,
          selected: true,
          onTap: isFriendshipActionLoading
              ? null
              : () async => onFriendshipAction?.call(),
        ),
      ],
      UserFriendshipStatus.outgoingRequest => [
        _ProfileHeroActionButton(
          icon: Icons.schedule_rounded,
          label: l10n.profileFriendRequestSentAction,
          isBusy: isFriendshipActionLoading,
          selected: true,
          onTap: isFriendshipActionLoading
              ? null
              : () async => onFriendshipAction?.call(),
        ),
      ],
      UserFriendshipStatus.incomingRequest => [
        _ProfileHeroActionButton(
          icon: Icons.check_rounded,
          label: l10n.profileAcceptFriendAction,
          isBusy: isFriendshipActionLoading,
          selected: true,
          onTap: isFriendshipActionLoading
              ? null
              : () async => onFriendshipAction?.call(),
        ),
        _ProfileHeroActionButton(
          icon: Icons.close_rounded,
          label: l10n.profileDeclineFriendAction,
          isBusy: isFriendshipActionLoading,
          destructive: true,
          onTap: isFriendshipActionLoading
              ? null
              : () async => onDeclineFriendship?.call(),
        ),
      ],
      UserFriendshipStatus.friends => [
        _ProfileHeroActionButton(
          icon: Icons.person_remove_alt_1_rounded,
          label: l10n.profileRemoveFriendAction,
          isBusy: isFriendshipActionLoading,
          destructive: true,
          onTap: isFriendshipActionLoading
              ? null
              : () async => onFriendshipAction?.call(),
        ),
      ],
    };
  }
}

class _ProfileHeroActionButton extends StatelessWidget {
  const _ProfileHeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isBusy = false,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isBusy;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isBusy;
    final circleSize = profileScaled(context, 50, min: 46, max: 54);
    final width = profileScaled(context, 78, min: 70, max: 86);
    final color = destructive
        ? AppColors.destruct
        : selected
        ? AppColors.accent
        : profileTextSoft;
    final disabledColor = destructive
        ? AppColors.destruct.withValues(alpha: 0.52)
        : profileDisabled;
    final effectiveColor = enabled ? color : disabledColor;
    final backgroundColor = destructive
        ? AppColors.destruct.withValues(alpha: selected ? 0.16 : 0.10)
        : selected
        ? AppColors.accent.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.055);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: enabled ? onTap : null,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveColor.withValues(
                        alpha: enabled ? 0.46 : 0.22,
                      ),
                    ),
                  ),
                  child: Center(
                    child: isBusy
                        ? SizedBox(
                            width: profileScaled(context, 18, min: 16, max: 18),
                            height: profileScaled(
                              context,
                              18,
                              min: 16,
                              max: 18,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: effectiveColor,
                            ),
                          )
                        : Icon(
                            icon,
                            color: effectiveColor,
                            size: profileScaled(context, 22, min: 20, max: 24),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: profileScaled(context, 7, min: 6, max: 8)),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? profileTextSoft : profileDisabled,
                fontSize: profileScaled(context, 11, min: 10, max: 12),
                fontWeight: FontWeight.w800,
                height: 1.08,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnProfileSections extends StatelessWidget {
  const _OwnProfileSections({
    required this.userId,
    required this.isGuideProfile,
    required this.incomingFriendRequestsFuture,
    required this.recentActivitiesFuture,
    required this.popularStoriesFuture,
  });

  final String userId;
  final bool isGuideProfile;
  final Future<ProfileFollowersPageVm>? incomingFriendRequestsFuture;
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;
  final Future<List<PostVm>>? popularStoriesFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(title: l10n.profileJourneyTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        if (UserRouteFeatureFlags.customRoutesEnabled)
          _ProfileMenuTile(
            icon: Icons.route_outlined,
            title: l10n.profileUserRoutesTitle,
            subtitle: l10n.profileUserRoutesSubtitle,
            onTap: () => context.push('/user-routes'),
          ),
        _ProfileMenuTile(
          icon: Icons.bookmark_border_rounded,
          title: l10n.profileSavedItemsTitle,
          subtitle: l10n.profileSavedItemsSubtitle,
          disabled: true,
        ),
        _ProfileMenuTile(
          icon: Icons.people_alt_outlined,
          title: l10n.profileConnectionsTitle,
          subtitle: l10n.profileConnectionsSubtitle,
          onTap: () => context.push('/profile/connections'),
          trailing: incomingFriendRequestsFuture == null
              ? null
              : _IncomingFriendRequestsBadge(
                  requestsFuture: incomingFriendRequestsFuture!,
                ),
        ),
        if (isGuideProfile)
          _ProfileMenuTile(
            icon: Icons.dashboard_customize_outlined,
            title: l10n.profileGuideDashboardTitle,
            subtitle: l10n.profileGuideDashboardSubtitle,
            onTap: () => context.push('/profile/guide-dashboard'),
          ),
        SizedBox(height: profileScaled(context, 14, min: 10, max: 16)),
        _ForeignRecentActivitiesSection(
          userId: userId,
          recentActivitiesFuture: recentActivitiesFuture,
        ),
        SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
        _ForeignPopularStoriesSection(
          userId: userId,
          popularStoriesFuture: popularStoriesFuture,
        ),
      ],
    );
  }
}

class _IncomingFriendRequestsBadge extends StatelessWidget {
  const _IncomingFriendRequestsBadge({required this.requestsFuture});

  final Future<ProfileFollowersPageVm> requestsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileFollowersPageVm>(
      future: requestsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final label = data.nextOffset == null ? '1' : '1+';
        return Container(
          constraints: BoxConstraints(
            minWidth: profileScaled(context, 26, min: 24, max: 28),
            minHeight: profileScaled(context, 24, min: 22, max: 26),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: profileScaled(context, 8, min: 7, max: 9),
            vertical: profileScaled(context, 3, min: 2, max: 4),
          ),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(
              profileScaled(context, 999, min: 999, max: 999),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: profileScaled(context, 11, min: 10, max: 12),
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class _ForeignProfileSections extends StatelessWidget {
  const _ForeignProfileSections({
    required this.userId,
    required this.isGuideProfile,
    required this.guideReviewsFuture,
    required this.directGuideReviewsFuture,
    required this.activityReviewsFuture,
    required this.activityOrganizerReviewsFuture,
    required this.recentActivitiesFuture,
    required this.popularStoriesFuture,
  });

  final String userId;
  final bool isGuideProfile;
  final Future<ExcursionReviewsPage>? guideReviewsFuture;
  final Future<GuideReviewsPage>? directGuideReviewsFuture;
  final Future<ActivityReviewsPage>? activityReviewsFuture;
  final Future<ActivityOrganizerReviewsPage>? activityOrganizerReviewsFuture;
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;
  final Future<List<PostVm>>? popularStoriesFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGuideProfile && guideReviewsFuture != null) ...[
          if (directGuideReviewsFuture != null) ...[
            _DirectGuideReviewsSection(
              reviewsFuture: directGuideReviewsFuture!,
              bottomSpacing: profileScaled(context, 28, min: 24, max: 32),
            ),
          ],
          _GuideExcursionReviewsSection(
            reviewsFuture: guideReviewsFuture!,
            bottomSpacing: profileScaled(context, 28, min: 24, max: 32),
          ),
        ],
        if (activityOrganizerReviewsFuture != null) ...[
          _ProfileActivityOrganizerReviewsSection(
            reviewsFuture: activityOrganizerReviewsFuture!,
            bottomSpacing: profileScaled(context, 28, min: 24, max: 32),
          ),
        ],
        if (activityReviewsFuture != null) ...[
          _ProfileActivityReviewsSection(
            reviewsFuture: activityReviewsFuture!,
            bottomSpacing: profileScaled(context, 28, min: 24, max: 32),
          ),
        ],
        _ForeignRecentActivitiesSection(
          userId: userId,
          recentActivitiesFuture: recentActivitiesFuture,
        ),
        SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
        _ForeignPopularStoriesSection(
          userId: userId,
          popularStoriesFuture: popularStoriesFuture,
        ),
      ],
    );
  }
}

class _ForeignRecentActivitiesSection extends StatelessWidget {
  const _ForeignRecentActivitiesSection({
    required this.userId,
    required this.recentActivitiesFuture,
  });

  final String userId;
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfileSectionHeading(
                title: l10n.profileRecentActivitiesTitle,
              ),
            ),
            SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
            TextButton.icon(
              onPressed: userId.trim().isEmpty
                  ? null
                  : () {
                      context.push(
                        '/users/${Uri.encodeComponent(userId)}/activities',
                      );
                    },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.profileViewAllActivities),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.symmetric(
                  horizontal: profileScaled(context, 10, min: 8, max: 12),
                  vertical: profileScaled(context, 8, min: 6, max: 8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        if (recentActivitiesFuture == null)
          _PlaceholderShowcaseCard(
            title: l10n.profileActivitiesEmptyTitle,
            subtitle: l10n.profileActivitiesEmptySubtitle,
          )
        else
          FutureBuilder<List<ActivityListItemVm>>(
            future: recentActivitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ForeignRecentActivitiesSkeleton();
              }
              if (snapshot.hasError) {
                return _PlaceholderShowcaseCard(
                  title: l10n.profileActivitiesLoadFailed,
                  subtitle: l10n.profileActivitiesLoadFailedHint,
                );
              }

              final items = snapshot.data ?? const <ActivityListItemVm>[];
              if (items.isEmpty) {
                return _PlaceholderShowcaseCard(
                  title: l10n.profileActivitiesEmptyTitle,
                  subtitle: l10n.profileActivitiesEmptySubtitle,
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    ProfileCompactActivityCard(
                      item: items[i],
                      onTap: () => context.push(
                        '/activities/${items[i].id}',
                        extra: items[i],
                      ),
                    ),
                    if (i != items.length - 1)
                      SizedBox(height: profileScaled(context, 12, min: 10)),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ForeignRecentActivitiesSkeleton extends StatelessWidget {
  const _ForeignRecentActivitiesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(
            height: profileScaled(context, 220, min: 190, max: 240),
            decoration: profileCardDecoration(context, highlighted: true),
          ),
          if (i != 1) SizedBox(height: profileScaled(context, 12, min: 10)),
        ],
      ],
    );
  }
}

class _ForeignPopularStoriesSection extends StatelessWidget {
  const _ForeignPopularStoriesSection({
    required this.userId,
    required this.popularStoriesFuture,
  });

  final String userId;
  final Future<List<PostVm>>? popularStoriesFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProfileSectionHeading(
                title: l10n.profilePopularStoriesTitle,
              ),
            ),
            SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
            TextButton.icon(
              onPressed: userId.trim().isEmpty
                  ? null
                  : () {
                      context.push(
                        '/users/${Uri.encodeComponent(userId)}/posts',
                      );
                    },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.profileViewAllStories),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.symmetric(
                  horizontal: profileScaled(context, 10, min: 8, max: 12),
                  vertical: profileScaled(context, 8, min: 6, max: 8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        if (popularStoriesFuture == null)
          _PlaceholderShowcaseCard(
            title: l10n.profileStoriesEmptyTitle,
            subtitle: l10n.profileStoriesEmptySubtitle,
          )
        else
          FutureBuilder<List<PostVm>>(
            future: popularStoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ForeignPopularStoriesSkeleton();
              }
              if (snapshot.hasError) {
                return _PlaceholderShowcaseCard(
                  title: l10n.profileStoriesLoadFailed,
                  subtitle: l10n.profileStoriesLoadFailedHint,
                );
              }

              final stories = snapshot.data ?? const <PostVm>[];
              if (stories.isEmpty) {
                return _PlaceholderShowcaseCard(
                  title: l10n.profileStoriesEmptyTitle,
                  subtitle: l10n.profileStoriesEmptySubtitle,
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < stories.length; i++) ...[
                    ProfilePostCard(
                      post: stories[i],
                      onTap: () => context.push(
                        '/posts/${Uri.encodeComponent(stories[i].slug)}',
                        extra: stories[i],
                      ),
                    ),
                    if (i != stories.length - 1)
                      SizedBox(height: profileScaled(context, 12, min: 10)),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ForeignPopularStoriesSkeleton extends StatelessWidget {
  const _ForeignPopularStoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: profileScaled(context, 120, min: 108, max: 132),
            decoration: profileCardDecoration(context, highlighted: true),
          ),
          if (i != 2) SizedBox(height: profileScaled(context, 12, min: 10)),
        ],
      ],
    );
  }
}

class _ProfileReviewSectionShell extends StatelessWidget {
  const _ProfileReviewSectionShell({
    required this.title,
    required this.child,
    required this.bottomSpacing,
  });

  final String title;
  final Widget child;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(title: title),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}

class _ProfileActivityOrganizerReviewsSection extends StatelessWidget {
  const _ProfileActivityOrganizerReviewsSection({
    required this.reviewsFuture,
    required this.bottomSpacing,
  });

  final Future<ActivityOrganizerReviewsPage> reviewsFuture;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ActivityOrganizerReviewsPage>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ProfileReviewSectionShell(
            title: l10n.profileActivityOrganizerReviewsTitle,
            bottomSpacing: bottomSpacing,
            child: const _GuideReviewSkeletonList(),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews =
            snapshot.data?.items ?? const <ActivityOrganizerReviewVm>[];
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ProfileReviewSectionShell(
          title: l10n.profileActivityOrganizerReviewsTitle,
          bottomSpacing: bottomSpacing,
          child: Column(
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                _ProfileActivityReviewCard(
                  author: reviews[i].author,
                  rating: reviews[i].rating,
                  comment: reviews[i].comment,
                  createdAt: reviews[i].createdAt,
                  subtitle: l10n.activityReviewOrganizerLabel,
                ),
                if (i != reviews.length - 1)
                  SizedBox(height: profileScaled(context, 12, min: 10)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActivityReviewsSection extends StatelessWidget {
  const _ProfileActivityReviewsSection({
    required this.reviewsFuture,
    required this.bottomSpacing,
  });

  final Future<ActivityReviewsPage> reviewsFuture;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ActivityReviewsPage>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ProfileReviewSectionShell(
            title: l10n.profileActivityReviewsTitle,
            bottomSpacing: bottomSpacing,
            child: const _GuideReviewSkeletonList(),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data?.items ?? const <ActivityReviewVm>[];
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ProfileReviewSectionShell(
          title: l10n.profileActivityReviewsTitle,
          bottomSpacing: bottomSpacing,
          child: Column(
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                _ProfileActivityReviewCard(
                  author: reviews[i].author,
                  rating: reviews[i].rating,
                  comment: reviews[i].comment,
                  createdAt: reviews[i].createdAt,
                  subtitle: l10n.activityReviewActivityLabel,
                ),
                if (i != reviews.length - 1)
                  SizedBox(height: profileScaled(context, 12, min: 10)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DirectGuideReviewsSection extends StatelessWidget {
  const _DirectGuideReviewsSection({
    required this.reviewsFuture,
    required this.bottomSpacing,
  });

  final Future<GuideReviewsPage> reviewsFuture;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<GuideReviewsPage>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ProfileReviewSectionShell(
            title: l10n.profileDirectGuideReviewsTitle,
            bottomSpacing: bottomSpacing,
            child: const _GuideReviewSkeletonList(),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data?.items ?? const <GuideReviewVm>[];
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ProfileReviewSectionShell(
          title: l10n.profileDirectGuideReviewsTitle,
          bottomSpacing: bottomSpacing,
          child: Column(
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                _ProfileDirectGuideReviewCard(review: reviews[i]),
                if (i != reviews.length - 1)
                  SizedBox(height: profileScaled(context, 12, min: 10)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GuideExcursionReviewsSection extends StatelessWidget {
  const _GuideExcursionReviewsSection({
    required this.reviewsFuture,
    required this.bottomSpacing,
  });

  final Future<ExcursionReviewsPage> reviewsFuture;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ExcursionReviewsPage>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _ProfileReviewSectionShell(
            title: l10n.profileGuideReviewsTitle,
            bottomSpacing: bottomSpacing,
            child: const _GuideReviewSkeletonList(),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data?.items ?? const <ExcursionReviewVm>[];
        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return _ProfileReviewSectionShell(
          title: l10n.profileGuideReviewsTitle,
          bottomSpacing: bottomSpacing,
          child: Column(
            children: [
              for (var i = 0; i < reviews.length; i++) ...[
                _ProfileGuideReviewCard(review: reviews[i]),
                if (i != reviews.length - 1)
                  SizedBox(height: profileScaled(context, 12, min: 10)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileActivityReviewCard extends StatelessWidget {
  const _ProfileActivityReviewCard({
    required this.author,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.subtitle,
  });

  final ActivityReviewAuthorVm author;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : author.resolvedDisplayName;
    final avatarUrl = author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(author.resolvedAvatarFileId);
    final dateText = DateFormat.yMMMd(locale).format(createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: profileScaled(context, 18, min: 16, max: 20),
                backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 14, min: 13, max: 15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 3, min: 2, max: 4)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: profileTextMuted,
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
              _ProfileReviewRating(value: rating),
            ],
          ),
          if (comment.trim().isNotEmpty) ...[
            SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
            Text(
              comment.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                height: 1.42,
              ),
            ),
          ],
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
          Text(
            dateText,
            style: TextStyle(
              color: profileDisabled,
              fontSize: profileScaled(context, 11, min: 10, max: 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGuideReviewCard extends StatelessWidget {
  const _ProfileGuideReviewCard({required this.review});

  final ExcursionReviewVm review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : review.author.resolvedDisplayName;
    final avatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final title = review.titleForProfileCard;
    final dateText = DateFormat.yMMMd(
      locale,
    ).format(review.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: profileScaled(context, 18, min: 16, max: 20),
                backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: profileScaled(context, 14, min: 13, max: 15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 3, min: 2, max: 4)),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: profileTextMuted,
                        fontSize: profileScaled(context, 12, min: 11, max: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
              _ProfileReviewRating(value: review.rating),
            ],
          ),
          SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
          Text(
            review.comment,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: profileScaled(context, 14, min: 13, max: 15),
              height: 1.42,
            ),
          ),
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
          Text(
            dateText,
            style: TextStyle(
              color: profileDisabled,
              fontSize: profileScaled(context, 11, min: 10, max: 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDirectGuideReviewCard extends StatelessWidget {
  const _ProfileDirectGuideReviewCard({required this.review});

  final GuideReviewVm review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : review.author.resolvedDisplayName;
    final avatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final dateText = DateFormat.yMMMd(
      locale,
    ).format(review.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 16, min: 14, max: 18)),
      decoration: profileCardDecoration(
        context,
        highlighted: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: profileScaled(context, 18, min: 16, max: 20),
                backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: profileScaled(context, 12, min: 10, max: 12)),
              Expanded(
                child: Text(
                  authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: profileScaled(context, 14, min: 13, max: 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
              _ProfileReviewRating(value: review.rating),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
            Text(
              review.comment,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                height: 1.42,
              ),
            ),
          ],
          SizedBox(height: profileScaled(context, 10, min: 8, max: 12)),
          Text(
            dateText,
            style: TextStyle(
              color: profileDisabled,
              fontSize: profileScaled(context, 11, min: 10, max: 11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileReviewRating extends StatelessWidget {
  const _ProfileReviewRating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: profileScaled(context, 10, min: 8, max: 10),
          vertical: profileScaled(context, 6, min: 5, max: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: AppColors.accent,
              size: profileScaled(context, 15, min: 14, max: 16),
            ),
            SizedBox(width: profileScaled(context, 3, min: 2, max: 4)),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.accent,
                fontSize: profileScaled(context, 12, min: 11, max: 12),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideReviewSkeletonList extends StatelessWidget {
  const _GuideReviewSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _GuideReviewSkeletonCard(),
        SizedBox(height: 12),
        _GuideReviewSkeletonCard(),
      ],
    );
  }
}

class _GuideReviewSkeletonCard extends StatelessWidget {
  const _GuideReviewSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: profileScaled(context, 116, min: 104, max: 126),
      decoration: profileCardDecoration(
        context,
        disabled: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = disabled || onTap == null;
    return Opacity(
      opacity: effectiveDisabled ? 0.68 : 1,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: profileScaled(context, 14, min: 10, max: 14),
        ),
        child: InkWell(
          onTap: effectiveDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(
            profileScaled(context, 22, min: 18, max: 22),
          ),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: profileScaled(context, 8, min: 4, max: 8),
              vertical: profileScaled(context, 4, min: 2, max: 4),
            ),
            child: Row(
              children: [
                Container(
                  width: profileScaled(context, 44, min: 40, max: 48),
                  height: profileScaled(context, 44, min: 40, max: 48),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(
                      alpha: effectiveDisabled ? 0.06 : 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: effectiveDisabled
                        ? profileDisabled
                        : AppColors.accent,
                  ),
                ),
                SizedBox(width: profileScaled(context, 14, min: 12, max: 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: effectiveDisabled
                              ? profileDisabled
                              : AppColors.textPrimary,
                          fontSize: profileScaled(
                            context,
                            17,
                            min: 15,
                            max: 18,
                          ),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(
                        height: profileScaled(context, 4, min: 3, max: 4),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: effectiveDisabled
                              ? profileDisabled
                              : profileTextMuted,
                          fontSize: profileScaled(
                            context,
                            13,
                            min: 12,
                            max: 13,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: profileScaled(context, 10, min: 8, max: 10)),
                  trailing!,
                ],
                SizedBox(width: profileScaled(context, 6, min: 4, max: 6)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: effectiveDisabled ? profileDisabled : profileTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderShowcaseCard extends StatelessWidget {
  const _PlaceholderShowcaseCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: profileCardDecoration(
        context,
        disabled: true,
        radius: profileScaled(context, 22, min: 18, max: 22),
      ),
      child: Row(
        children: [
          Container(
            width: profileScaled(context, 46, min: 40, max: 48),
            height: profileScaled(context, 46, min: 40, max: 48),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(
                profileScaled(context, 14, min: 12, max: 14),
              ),
            ),
            child: Icon(
              Icons.hourglass_disabled_outlined,
              color: profileDisabled,
              size: profileScaled(context, 22, min: 18, max: 22),
            ),
          ),
          SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: profileTextSoft,
                    fontSize: profileScaled(context, 16, min: 14, max: 16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: profileScaled(context, 6, min: 4, max: 6)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: profileDisabled,
                    fontSize: profileScaled(context, 13, min: 12, max: 13),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileExtras {
  const _ProfileExtras({this.guide, this.avatarUrl});

  final GuideProfileVm? guide;
  final String? avatarUrl;
}

String _reviewInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

extension _ProfileExcursionReviewTitle on ExcursionReviewVm {
  String get titleForProfileCard {
    final place = (landmarkName ?? '').trim();
    if (place.isNotEmpty) {
      return place;
    }
    return guideDisplayName.trim().isEmpty ? sourceLabel : guideDisplayName;
  }
}
