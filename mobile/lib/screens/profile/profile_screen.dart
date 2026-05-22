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
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/guide_profile_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/models/story_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_style.dart';
import 'widgets/profile_activity_card.dart';
import 'widgets/profile_story_card.dart';

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
  final StoryApi _storyApi = StoryApi();

  Future<UserProfileVm>? _foreignProfileFuture;
  Future<_ProfileExtras>? _extrasFuture;
  Future<int>? _activityCountFuture;
  Future<List<ActivityListItemVm>>? _foreignRecentActivitiesFuture;
  Future<List<StoryVm>>? _foreignPopularStoriesFuture;
  Future<int>? _publishedStoriesCountFuture;
  Future<ExcursionReviewsPage>? _guideReviewsFuture;
  Future<GuideReviewsPage>? _directGuideReviewsFuture;
  String _extrasKey = '';
  String _activityCountKey = '';
  String _foreignRecentActivitiesKey = '';
  String _foreignPopularStoriesKey = '';
  String _publishedStoriesCountKey = '';
  String _guideReviewsKey = '';
  String _directGuideReviewsKey = '';
  String _followOverrideUserId = '';
  int? _followersCountOverride;
  bool? _isFollowedByMeOverride;
  bool _isFollowActionLoading = false;
  bool _isMessageActionLoading = false;

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

  void _configureForeignProfileFuture() {
    _followOverrideUserId = '';
    _followersCountOverride = null;
    _isFollowedByMeOverride = null;
    _isFollowActionLoading = false;
    _isMessageActionLoading = false;
    _publishedStoriesCountFuture = null;
    _publishedStoriesCountKey = '';
    _foreignRecentActivitiesFuture = null;
    _foreignRecentActivitiesKey = '';
    _foreignPopularStoriesFuture = null;
    _foreignPopularStoriesKey = '';
    _guideReviewsFuture = null;
    _guideReviewsKey = '';
    _directGuideReviewsFuture = null;
    _directGuideReviewsKey = '';

    final userId = widget.userId?.trim() ?? '';
    if (userId.isEmpty) {
      _foreignProfileFuture = null;
      return;
    }

    // Always fetch fresh data from API to get up-to-date followers/reputation.
    _foreignProfileFuture = _profileApi.getUserById(userId);
  }

  UserProfileVm _profileWithFollowOverrides(UserProfileVm profile) {
    if (_followOverrideUserId != profile.userId.trim()) {
      return profile;
    }

    return profile.copyWith(
      followersCount: _followersCountOverride,
      isFollowedByMe: _isFollowedByMeOverride,
    );
  }

  Future<void> _toggleFollow(UserProfileVm profile) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = profile.userId.trim();
    if (userId.isEmpty || _isFollowActionLoading) {
      return;
    }

    final currentProfile = _profileWithFollowOverrides(profile);
    final willFollow = !currentProfile.isFollowedByMe;
    final nextFollowersCount =
        currentProfile.followersCount + (willFollow ? 1 : -1);

    setState(() {
      _followOverrideUserId = userId;
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
        _followOverrideUserId = userId;
        _isFollowedByMeOverride = currentProfile.isFollowedByMe;
        _followersCountOverride = currentProfile.followersCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileFollowUpdateFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _isFollowActionLoading = false;
        });
      }
    }
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

  Future<_ProfileExtras> _loadExtras(UserProfileVm profile) async {
    Future<GuideProfileVm?> loadGuide() async {
      try {
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

  Future<_ProfileExtras> _extrasFutureFor(UserProfileVm profile) {
    final key =
        '${profile.userId.trim()}|${(profile.avatarFileId ?? '').trim()}|${profile.roles.join(",")}';
    if (_extrasFuture == null || _extrasKey != key) {
      _extrasKey = key;
      _extrasFuture = _loadExtras(profile);
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

  Future<List<StoryVm>> _popularStoriesFutureFor(UserProfileVm profile) {
    final key =
        '${profile.userId.trim()}|$_foreignProfilePopularStoriesPreviewLimit';
    if (_foreignPopularStoriesFuture == null ||
        _foreignPopularStoriesKey != key) {
      _foreignPopularStoriesKey = key;
      _foreignPopularStoriesFuture = _storyApi.getUserPopularStories(
        profile.userId.trim(),
        limit: _foreignProfilePopularStoriesPreviewLimit,
      );
    }
    return _foreignPopularStoriesFuture!;
  }

  Future<int> _publishedStoriesCountFutureFor(UserProfileVm profile) {
    final key = profile.userId.trim();
    if (_publishedStoriesCountFuture == null ||
        _publishedStoriesCountKey != key) {
      _publishedStoriesCountKey = key;
      _publishedStoriesCountFuture = _storyApi.countPublishedStoriesForUser(
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

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AndroidBackSwipeScope(child: EditProfileScreen()),
      ),
    );

    if (updated == true && mounted) {
      _extrasKey = '';
      _extrasFuture = null;
      _activityCountKey = '';
      _activityCountFuture = null;
      _publishedStoriesCountKey = '';
      _publishedStoriesCountFuture = null;
      await context.read<SessionProvider>().reloadProfile();
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
      backgroundColor: Colors.transparent,
      body: ProfileResponsiveScope(
        child: ProfileGlassBackground(
          child: SafeArea(
            child: isOwnProfile
                ? _buildResolvedProfile(
                    context,
                    session.profile,
                    isOwnProfile: true,
                  )
                : FutureBuilder<UserProfileVm>(
                    future: _foreignProfileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || snapshot.data == null) {
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
                        snapshot.data,
                        isOwnProfile: false,
                      );
                    },
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

    final effectiveProfile = _profileWithFollowOverrides(profile);

    return FutureBuilder<_ProfileExtras>(
      future: _extrasFutureFor(effectiveProfile),
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
          recentActivitiesFuture: isOwnProfile
              ? null
              : _recentActivitiesFutureFor(effectiveProfile),
          popularStoriesFuture: isOwnProfile
              ? null
              : _popularStoriesFutureFor(effectiveProfile),
          activityCountFuture: _activityCountFutureFor(effectiveProfile),
          publishedStoriesCountFuture: _publishedStoriesCountFutureFor(
            effectiveProfile,
          ),
          isOwnProfile: isOwnProfile,
          isFollowActionLoading: _isFollowActionLoading,
          isMessageActionLoading: _isMessageActionLoading,
          onToggleFollow: isOwnProfile
              ? null
              : () => _toggleFollow(effectiveProfile),
          onMessageTap: isOwnProfile
              ? null
              : () => _openDirectChat(effectiveProfile),
          onSettingsTap: isOwnProfile ? _openSettings : null,
          onEditProfile: isOwnProfile ? _openEditProfile : null,
          onCopyProfileLink: () => _copyProfileLink(effectiveProfile),
          onFollowersTap: () => _openFollowers(effectiveProfile),
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
    required this.recentActivitiesFuture,
    required this.popularStoriesFuture,
    required this.activityCountFuture,
    required this.publishedStoriesCountFuture,
    required this.isOwnProfile,
    required this.isFollowActionLoading,
    required this.isMessageActionLoading,
    required this.onToggleFollow,
    required this.onMessageTap,
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
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;
  final Future<List<StoryVm>>? popularStoriesFuture;
  final Future<int> activityCountFuture;
  final Future<int> publishedStoriesCountFuture;
  final bool isOwnProfile;
  final bool isFollowActionLoading;
  final bool isMessageActionLoading;
  final Future<void> Function()? onToggleFollow;
  final Future<void> Function()? onMessageTap;
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
        _ProfileTopBar(
          isOwnProfile: isOwnProfile,
          title: isOwnProfile ? l10n.myProfileTitle : profile.preferredName,
          onLeadingTap: isOwnProfile ? onSettingsTap : () => context.pop(),
          onShareTap: onCopyProfileLink,
        ),
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
        if (!isOwnProfile) ...[
          SizedBox(height: profileScaled(context, 22, min: 18, max: 24)),
          _ForeignProfileActions(
            isFollowedByMe: profile.isFollowedByMe,
            isBusy: isFollowActionLoading,
            isMessageBusy: isMessageActionLoading,
            onToggleFollow: onToggleFollow,
            onMessageTap: onMessageTap,
          ),
        ],
        SizedBox(height: profileScaled(context, 32, min: 24, max: 36)),
        if (isOwnProfile) ...[
          _OwnProfileSections(isGuideProfile: isGuideProfile),
        ] else ...[
          _ForeignProfileSections(
            userId: profile.userId,
            isGuideProfile: isGuideProfile,
            guideReviewsFuture: guideReviewsFuture,
            directGuideReviewsFuture: directGuideReviewsFuture,
            recentActivitiesFuture: recentActivitiesFuture,
            popularStoriesFuture: popularStoriesFuture,
          ),
        ],
      ],
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.isOwnProfile,
    required this.title,
    required this.onLeadingTap,
    required this.onShareTap,
  });

  final bool isOwnProfile;
  final String title;
  final VoidCallback? onLeadingTap;
  final VoidCallback onShareTap;

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
        ProfileTopIconButton(icon: Icons.ios_share_outlined, onTap: onShareTap),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.guide,
    required this.avatarUrl,
    required this.isOwnProfile,
    required this.isGuideProfile,
  });

  final UserProfileVm profile;
  final GuideProfileVm? guide;
  final String? avatarUrl;
  final bool isOwnProfile;
  final bool isGuideProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bio = _resolveAboutText(l10n);
    final badges = _topBadges(l10n);

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

    if (values.isEmpty) {
      final country = (profile.countryCode ?? '').trim();
      final currency = (profile.currency ?? '').trim();
      if (country.isNotEmpty) {
        values.add(country);
      }
      if (currency.isNotEmpty) {
        values.add(currency);
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
                        errorBuilder: (_, __, ___) => Center(
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

    final title = isPending
        ? l10n.guideVerificationPendingTitle
        : isRejected
        ? l10n.guideVerificationRejectedTitle
        : l10n.profileBecomeGuideTitle;
    final subtitle = isPending
        ? l10n.guideVerificationPendingSubtitle
        : isRejected
        ? l10n.guideVerificationRejectedSubtitle
        : isDraft
        ? l10n.guideVerificationDraftSubtitle
        : l10n.profileBecomeGuideSubtitle;
    final buttonLabel = isPending
        ? l10n.guideVerificationViewApplicationButton
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
              onPressed: onTap,
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
        final activityCount = snapshot.data ?? 0;
        return FutureBuilder<int>(
          future: publishedStoriesCountFuture,
          builder: (context, storiesSnapshot) {
            final publishedStoriesCount = storiesSnapshot.data ?? 0;
            final cards = <_StatConfig>[
              _StatConfig(
                label: l10n.profileActivitiesStat,
                value: '$activityCount',
                highlighted: true,
              ),
              _StatConfig(
                label: l10n.profileBlogsStat,
                value: '$publishedStoriesCount',
                highlighted: true,
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
    this.onTap,
  });

  final String label;
  final String value;
  final bool highlighted;
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

class _ForeignProfileActions extends StatelessWidget {
  const _ForeignProfileActions({
    required this.isFollowedByMe,
    required this.isBusy,
    required this.isMessageBusy,
    required this.onToggleFollow,
    required this.onMessageTap,
  });

  final bool isFollowedByMe;
  final bool isBusy;
  final bool isMessageBusy;
  final Future<void> Function()? onToggleFollow;
  final Future<void> Function()? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: isFollowedByMe
              ? OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await onToggleFollow?.call();
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                    foregroundColor: AppColors.accent,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                    minimumSize: Size(
                      double.infinity,
                      profileScaled(context, 52, min: 48, max: 54),
                    ),
                    disabledForegroundColor: AppColors.accent.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  child: Text(
                    isBusy
                        ? l10n.profileFollowingAction
                        : l10n.profileFollowingAction,
                  ),
                )
              : FilledButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await onToggleFollow?.call();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: Size(
                      double.infinity,
                      profileScaled(context, 52, min: 48, max: 54),
                    ),
                    disabledBackgroundColor: profileSurfaceMuted,
                    disabledForegroundColor: profileTextSoft,
                  ),
                  child: Text(
                    isBusy
                        ? l10n.profileFollowingAction
                        : l10n.profileFollowAction,
                  ),
                ),
        ),
        SizedBox(width: profileScaled(context, 14, min: 10, max: 16)),
        Expanded(
          child: OutlinedButton(
            onPressed: isMessageBusy
                ? null
                : () async {
                    await onMessageTap?.call();
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              foregroundColor: profileTextSoft,
              backgroundColor: profileSurfaceMuted.withValues(alpha: 0.62),
              minimumSize: Size(
                double.infinity,
                profileScaled(context, 52, min: 48, max: 54),
              ),
              disabledForegroundColor: profileTextSoft,
            ),
            child: isMessageBusy
                ? SizedBox(
                    width: profileScaled(context, 18, min: 16, max: 18),
                    height: profileScaled(context, 18, min: 16, max: 18),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accent,
                    ),
                  )
                : Text(l10n.profileMessageAction),
          ),
        ),
      ],
    );
  }
}

class _OwnProfileSections extends StatelessWidget {
  const _OwnProfileSections({required this.isGuideProfile});

  final bool isGuideProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(title: l10n.profileJourneyTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        _ProfileMenuTile(
          icon: Icons.bookmark_border_rounded,
          title: l10n.profileSavedItemsTitle,
          subtitle: l10n.profileSavedItemsSubtitle,
          disabled: true,
        ),
        if (isGuideProfile)
          _ProfileMenuTile(
            icon: Icons.dashboard_customize_outlined,
            title: l10n.profileGuideDashboardTitle,
            subtitle: l10n.profileGuideDashboardSubtitle,
            onTap: () => context.push('/profile/guide-dashboard'),
          ),
        SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
        ProfileSectionHeading(title: l10n.profilePreferencesTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        _ProfileMenuTile(
          icon: Icons.notifications_none_rounded,
          title: l10n.profileNotificationsRowTitle,
          subtitle: l10n.profileNotificationsRowSubtitle,
          onTap: () => context.push('/profile/notifications'),
        ),
        _ProfileMenuTile(
          icon: Icons.lock_outline_rounded,
          title: l10n.profileSecurityRowTitle,
          subtitle: l10n.profileSecurityRowSubtitle,
          onTap: () => context.push('/profile/security'),
        ),
      ],
    );
  }
}

class _ForeignProfileSections extends StatelessWidget {
  const _ForeignProfileSections({
    required this.userId,
    required this.isGuideProfile,
    required this.guideReviewsFuture,
    required this.directGuideReviewsFuture,
    required this.recentActivitiesFuture,
    required this.popularStoriesFuture,
  });

  final String userId;
  final bool isGuideProfile;
  final Future<ExcursionReviewsPage>? guideReviewsFuture;
  final Future<GuideReviewsPage>? directGuideReviewsFuture;
  final Future<List<ActivityListItemVm>>? recentActivitiesFuture;
  final Future<List<StoryVm>>? popularStoriesFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isGuideProfile && guideReviewsFuture != null) ...[
          if (directGuideReviewsFuture != null) ...[
            _DirectGuideReviewsSection(
              reviewsFuture: directGuideReviewsFuture!,
            ),
            SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
          ],
          _GuideExcursionReviewsSection(reviewsFuture: guideReviewsFuture!),
          SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
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
  final Future<List<StoryVm>>? popularStoriesFuture;

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
                        '/users/${Uri.encodeComponent(userId)}/stories',
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
          FutureBuilder<List<StoryVm>>(
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

              final stories = snapshot.data ?? const <StoryVm>[];
              if (stories.isEmpty) {
                return _PlaceholderShowcaseCard(
                  title: l10n.profileStoriesEmptyTitle,
                  subtitle: l10n.profileStoriesEmptySubtitle,
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < stories.length; i++) ...[
                    ProfileStoryCard(
                      story: stories[i],
                      onTap: () => context.push(
                        '/stories/${Uri.encodeComponent(stories[i].slug)}',
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

class _DirectGuideReviewsSection extends StatelessWidget {
  const _DirectGuideReviewsSection({required this.reviewsFuture});

  final Future<GuideReviewsPage> reviewsFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(title: l10n.profileDirectGuideReviewsTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        FutureBuilder<GuideReviewsPage>(
          future: reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GuideReviewSkeletonList();
            }
            if (snapshot.hasError) {
              return _PlaceholderShowcaseCard(
                title: l10n.profileGuideReviewsLoadFailed,
                subtitle: l10n.profileGuideReviewsLoadFailedHint,
              );
            }

            final reviews = snapshot.data?.items ?? const <GuideReviewVm>[];
            if (reviews.isEmpty) {
              return _PlaceholderShowcaseCard(
                title: l10n.profileGuideReviewsEmptyTitle,
                subtitle: l10n.profileDirectGuideReviewsEmpty,
              );
            }

            return Column(
              children: [
                for (var i = 0; i < reviews.length; i++) ...[
                  _ProfileDirectGuideReviewCard(review: reviews[i]),
                  if (i != reviews.length - 1)
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

class _GuideExcursionReviewsSection extends StatelessWidget {
  const _GuideExcursionReviewsSection({required this.reviewsFuture});

  final Future<ExcursionReviewsPage> reviewsFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(title: l10n.profileGuideReviewsTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        FutureBuilder<ExcursionReviewsPage>(
          future: reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GuideReviewSkeletonList();
            }
            if (snapshot.hasError) {
              return _PlaceholderShowcaseCard(
                title: l10n.profileGuideReviewsLoadFailed,
                subtitle: l10n.profileGuideReviewsLoadFailedHint,
              );
            }

            final reviews = snapshot.data?.items ?? const <ExcursionReviewVm>[];
            if (reviews.isEmpty) {
              return _PlaceholderShowcaseCard(
                title: l10n.profileGuideReviewsEmptyTitle,
                subtitle: l10n.profileGuideReviewsEmpty,
              );
            }

            return Column(
              children: [
                for (var i = 0; i < reviews.length; i++) ...[
                  _ProfileGuideReviewCard(review: reviews[i]),
                  if (i != reviews.length - 1)
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

class _ProfileGuideReviewCard extends StatelessWidget {
  const _ProfileGuideReviewCard({required this.review});

  final ExcursionReviewVm review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.attractionTravelerFallback
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
        ? l10n.attractionTravelerFallback
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
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
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
    final attraction = (landmarkName ?? '').trim();
    if (attraction.isNotEmpty) {
      return attraction;
    }
    return guideDisplayName.trim().isEmpty ? sourceLabel : guideDisplayName;
  }
}
