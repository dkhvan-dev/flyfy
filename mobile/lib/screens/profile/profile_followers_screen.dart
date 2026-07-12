import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../features/chat/utils/chat_presence_status.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/profile_follower_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import 'profile_style.dart';

class ProfileFollowersScreen extends StatefulWidget {
  const ProfileFollowersScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ProfileFollowersScreen> createState() => _ProfileFollowersScreenState();
}

class _ProfileFollowersScreenState extends State<ProfileFollowersScreen> {
  static const _pageSize = 20;

  final ProfileApi _profileApi = ProfileApi();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<ProfileFollowerVm> _followers = const [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorText;
  int? _nextOffset;
  int _requestEpoch = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _searchController.addListener(_handleSearchChanged);
    unawaited(_reloadFollowers());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      unawaited(_loadMoreFollowers());
    }
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 280),
      () => unawaited(_reloadFollowers()),
    );
  }

  Future<void> _reloadFollowers() async {
    final requestEpoch = ++_requestEpoch;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _errorText = null;
      _nextOffset = null;
      _followers = const [];
    });

    try {
      final page = await _profileApi.getFollowers(
        widget.userId,
        limit: _pageSize,
        offset: 0,
        query: _searchController.text,
      );
      if (!mounted || requestEpoch != _requestEpoch) return;

      setState(() {
        _followers = page.items;
        _nextOffset = page.nextOffset;
      });
    } catch (e) {
      if (!mounted || requestEpoch != _requestEpoch) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorText = e is DioException
            ? DioErrorMapper.toMessage(e)
            : l10n.profileFollowersLoadFailed;
      });
    } finally {
      if (mounted && requestEpoch == _requestEpoch) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMoreFollowers() async {
    final offset = _nextOffset;
    if (offset == null) return;

    final requestEpoch = _requestEpoch;
    setState(() => _loadingMore = true);

    try {
      final page = await _profileApi.getFollowers(
        widget.userId,
        limit: _pageSize,
        offset: offset,
        query: _searchController.text,
      );
      if (!mounted || requestEpoch != _requestEpoch) return;

      final merged = <String, ProfileFollowerVm>{
        for (final item in _followers) item.userId: item,
      };
      for (final item in page.items) {
        merged[item.userId] = item;
      }

      setState(() {
        _followers = merged.values.toList(growable: false);
        _nextOffset = page.nextOffset;
      });
    } catch (_) {
      if (!mounted || requestEpoch != _requestEpoch) return;
    } finally {
      if (mounted && requestEpoch == _requestEpoch) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _openFollowerProfile(ProfileFollowerVm follower) {
    final userId = follower.userId.trim();
    if (userId.isEmpty) return;

    final currentUserId = context
        .read<SessionProvider>()
        .profile
        ?.userId
        .trim();
    if (currentUserId != null && currentUserId == userId) {
      context.push('/profile');
      return;
    }

    context.push('/users/${Uri.encodeComponent(userId)}/profile');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: ProfileResponsiveScope(
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.screenGradientColors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = profileScaled(
                    context,
                    constraints.maxWidth < 360 ? 16 : 20,
                    min: 16,
                    max: 24,
                  );

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: RefreshIndicator(
                        color: colors.primary,
                        backgroundColor: colors.surface,
                        onRefresh: _reloadFollowers,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: AppEdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  profileScaled(context, 10, min: 8, max: 14),
                                  horizontalPadding,
                                  0,
                                ),
                                child: _FollowersHeader(
                                  title: l10n.profileFollowersTitle,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: AppEdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  profileScaled(context, 20, min: 16, max: 24),
                                  horizontalPadding,
                                  profileScaled(context, 16, min: 12, max: 18),
                                ),
                                child: _FollowersSearchField(
                                  controller: _searchController,
                                  hintText: l10n.profileFollowersSearchHint,
                                ),
                              ),
                            ),
                            if (_loading)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _FollowersLoadingState(),
                              )
                            else if (_errorText != null && _followers.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _FollowersErrorState(
                                  title: l10n.profileFollowersLoadFailed,
                                  subtitle: _errorText!,
                                  retryLabel: l10n.retryButton,
                                  onRetry: () => unawaited(_reloadFollowers()),
                                ),
                              )
                            else if (_followers.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _FollowersEmptyState(
                                  title: _searchController.text.trim().isEmpty
                                      ? l10n.profileFollowersEmptyTitle
                                      : l10n.profileFollowersSearchEmptyTitle,
                                  subtitle:
                                      _searchController.text.trim().isEmpty
                                      ? l10n.profileFollowersEmptySubtitle
                                      : l10n.profileFollowersSearchEmptySubtitle,
                                ),
                              )
                            else
                              SliverPadding(
                                padding: AppEdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0,
                                  horizontalPadding,
                                  profileScaled(context, 28, min: 22, max: 32),
                                ),
                                sliver: SliverList.separated(
                                  itemCount:
                                      _followers.length +
                                      (_loadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= _followers.length) {
                                      return Padding(
                                        padding: const AppEdgeInsets.only(
                                          top: 8,
                                          bottom: 12,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return _FollowerRow(
                                      follower: _followers[index],
                                      onTap: () => _openFollowerProfile(
                                        _followers[index],
                                      ),
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height: profileScaled(
                                          context,
                                          12,
                                          min: 10,
                                          max: 14,
                                        ),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowersHeader extends StatelessWidget {
  const _FollowersHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      children: [
        _FollowersBackButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.pop(),
        ),
        SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: profileScaled(context, 24, min: 20, max: 28),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowersBackButton extends StatelessWidget {
  const _FollowersBackButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final size = profileScaled(context, 38, min: 34, max: 40);
    final iconSize = profileScaled(context, 20, min: 18, max: 20);

    return Material(
      color: colors.surfaceRaised,
      shape: CircleBorder(side: BorderSide(color: colors.borderSoft)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: iconSize, color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _FollowersSearchField extends StatelessWidget {
  const _FollowersSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        decoration: _followersCardDecoration(
          context,
          colors,
          radius: profileScaled(context, 18, min: 16, max: 20),
        ),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: profileScaled(context, 15, min: 14, max: 16),
            fontWeight: FontWeight.w600,
          ),
          decoration: AppInputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.primary,
              size: profileScaled(context, 22, min: 20, max: 24),
            ),
            suffixIcon: controller.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: controller.clear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.primary,
                      size: profileScaled(context, 20, min: 18, max: 22),
                    ),
                  ),
            hintText: hintText,
            hintStyle: AppTextStyle(
              color: colors.textSecondary,
              fontSize: profileScaled(context, 15, min: 14, max: 16),
              fontWeight: FontWeight.w500,
            ),
            contentPadding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 18, min: 16, max: 20),
              vertical: profileScaled(context, 16, min: 14, max: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowerRow extends StatelessWidget {
  const _FollowerRow({required this.follower, required this.onTap});

  final ProfileFollowerVm follower;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final status = chatPresenceStatusLabelForValues(
      l10n,
      isOnline: follower.isOnline,
      lastSeenAt: follower.lastSeenAt,
    );
    final nickname = follower.nicknameOrFallback(l10n.chatUserFallbackName);

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 22, min: 18, max: 24),
        ),
        child: Ink(
          padding: AppEdgeInsets.all(
            profileScaled(context, 14, min: 12, max: 16),
          ),
          decoration: _followersCardDecoration(
            context,
            colors,
            radius: profileScaled(context, 22, min: 18, max: 24),
          ),
          child: Row(
            children: [
              _FollowerAvatar(follower: follower),
              SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: profileScaled(context, 18, min: 16, max: 20),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                    Row(
                      children: [
                        if (follower.isOnline) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: AppBoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle(
                              color: follower.isOnline
                                  ? colors.primary
                                  : colors.textSecondary,
                              fontSize: profileScaled(
                                context,
                                13,
                                min: 12,
                                max: 14,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: profileScaled(context, 8, min: 6, max: 10)),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: profileScaled(context, 24, min: 22, max: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowerAvatar extends StatelessWidget {
  const _FollowerAvatar({required this.follower});

  final ProfileFollowerVm follower;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final size = profileScaled(context, 58, min: 52, max: 62);
    final imageUrl = resolvePublicFileContentUrl(follower.avatarFileId ?? '');

    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderPrimary),
      ),
      child: ClipOval(
        child: Container(
          color: colors.surfaceRaised,
          child: imageUrl == null
              ? _FollowerAvatarFallback(initials: follower.initials)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _FollowerAvatarFallback(initials: follower.initials),
                ),
        ),
      ),
    );
  }
}

class _FollowerAvatarFallback extends StatelessWidget {
  const _FollowerAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceWarm, colors.surfaceRaised],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyle(
            fontSize: profileScaled(context, 20, min: 18, max: 22),
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FollowersLoadingState extends StatelessWidget {
  const _FollowersLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _FollowersEmptyState extends StatelessWidget {
  const _FollowersEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Padding(
      padding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 24, min: 20, max: 28),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              color: colors.textSecondary,
              size: profileScaled(context, 42, min: 36, max: 46),
            ),
            SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: profileScaled(context, 20, min: 18, max: 22),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowersErrorState extends StatelessWidget {
  const _FollowersErrorState({
    required this.title,
    required this.subtitle,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Padding(
      padding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 24, min: 20, max: 28),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: colors.textSecondary,
              size: profileScaled(context, 42, min: 36, max: 46),
            ),
            SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: profileScaled(context, 20, min: 18, max: 22),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: profileScaled(context, 14, min: 13, max: 15),
                height: 1.45,
              ),
            ),
            SizedBox(height: profileScaled(context, 18, min: 14, max: 20)),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _followersCardDecoration(
  BuildContext context,
  AppColors colors, {
  double? radius,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: AppBorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 24),
    ),
    border: Border.all(color: isDark ? colors.borderPrimary : colors.border),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: 0.22),
              blurRadius: profileScaled(context, 18, min: 14, max: 22),
              offset: Offset(0, profileScaled(context, 8, min: 5, max: 10)),
            ),
          ]
        : const [],
  );
}
