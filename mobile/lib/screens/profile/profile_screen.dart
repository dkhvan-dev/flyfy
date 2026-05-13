import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../core/network/activity_api.dart';
import '../../core/network/chat_api.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/guide_profile_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.initialProfile});

  final String? userId;
  final UserProfileVm? initialProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApi _profileApi = ProfileApi();
  final GuideApi _guideApi = GuideApi();
  final FileApi _fileApi = FileApi();
  final ActivityApi _activityApi = ActivityApi();
  final ChatApi _chatApi = ChatApi();

  Future<UserProfileVm>? _foreignProfileFuture;
  Future<_ProfileExtras>? _extrasFuture;
  Future<ActivityCompletionStatsVm>? _activityStatsFuture;
  String _extrasKey = '';
  String _activityStatsKey = '';
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

  Future<ActivityCompletionStatsVm> _activityStatsFutureFor(
    UserProfileVm profile, {
    required bool isOwnProfile,
  }) {
    final key = '${profile.userId.trim()}|$isOwnProfile';
    if (_activityStatsFuture == null || _activityStatsKey != key) {
      _activityStatsKey = key;
      if (isOwnProfile) {
        _activityStatsFuture = _activityApi.getMyCompletionStats(
          actorUserId: profile.userId.trim(),
        );
      } else {
        _activityStatsFuture = _activityApi
            .countCompletedActivitiesForUser(profile.userId.trim())
            .then(
              (count) => ActivityCompletionStatsVm(
                hostedCompleted: count,
                joinedCompleted: 0,
              ),
            );
      }
    }
    return _activityStatsFuture!;
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
      _activityStatsKey = '';
      _activityStatsFuture = null;
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
          activityStatsFuture: _activityStatsFutureFor(
            effectiveProfile,
            isOwnProfile: isOwnProfile,
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
    required this.activityStatsFuture,
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
  final Future<ActivityCompletionStatsVm> activityStatsFuture;
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
          activityStatsFuture: activityStatsFuture,
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
          const _OwnProfileSections(),
        ] else ...[
          _ForeignProfileSections(isGuideProfile: isGuideProfile),
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
        if (!profile.isPublic) ...[
          SizedBox(height: profileScaled(context, 10, min: 8, max: 10)),
          _ProfilePill(
            text: l10n.profilePrivate,
            icon: Icons.lock_outline_rounded,
            highlighted: false,
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
      values.add(profile.isPublic ? l10n.profilePublic : l10n.profilePrivate);
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
  const _ProfilePill({required this.text, this.icon, this.highlighted = true});

  final String text;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: profileScaled(context, 14, min: 12, max: 16),
        vertical: profileScaled(context, 8, min: 7, max: 10),
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: profileScaled(context, 14, min: 12, max: 14),
              color: highlighted ? AppColors.accent : profileTextSoft,
            ),
            SizedBox(width: profileScaled(context, 8, min: 6, max: 8)),
          ],
          Text(
            text,
            style: TextStyle(
              color: highlighted ? AppColors.accent : profileTextSoft,
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
    required this.activityStatsFuture,
    this.onFollowersTap,
  });

  final UserProfileVm profile;
  final Future<ActivityCompletionStatsVm> activityStatsFuture;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<ActivityCompletionStatsVm>(
      future: activityStatsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final totalCompleted =
            (stats?.hostedCompleted ?? 0) + (stats?.joinedCompleted ?? 0);
        final cards = <_StatConfig>[
          _StatConfig(
            label: l10n.profileActivitiesStat,
            value: '$totalCompleted',
            highlighted: true,
          ),
          _StatConfig(
            label: l10n.profileBlogsStat,
            value: '0',
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
  const _OwnProfileSections();

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
        _ProfileMenuTile(
          icon: Icons.calendar_month_outlined,
          title: l10n.profileBookingsTitle,
          subtitle: l10n.profileBookingsSubtitle,
          disabled: true,
        ),
        _ProfileMenuTile(
          icon: Icons.event_note_outlined,
          title: l10n.myActivitiesTitle,
          subtitle: l10n.profileMyActivitiesSubtitle,
          onTap: () => context.push('/me/activities'),
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
  const _ForeignProfileSections({required this.isGuideProfile});

  final bool isGuideProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeading(
          title: l10n.profileHostedActivitiesTitle,
          kicker: isGuideProfile ? l10n.profileGuideTitle : null,
        ),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        _PlaceholderShowcaseCard(
          title: l10n.profileUnavailableTitle,
          subtitle: l10n.profileHostedActivitiesUnavailable,
        ),
        SizedBox(height: profileScaled(context, 28, min: 24, max: 32)),
        ProfileSectionHeading(title: l10n.profileBlogsTitle),
        SizedBox(height: profileScaled(context, 16, min: 12, max: 18)),
        _PlaceholderShowcaseCard(
          title: l10n.profileUnavailableTitle,
          subtitle: l10n.profileBlogsUnavailable,
        ),
      ],
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
