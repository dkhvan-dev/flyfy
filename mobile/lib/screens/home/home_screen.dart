import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../features/activities/activity_cover_url.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/data/guide_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GuideApi _guideApi = GuideApi();
  String? _requestedHostedActivitiesForUserId;
  String? _requestedJoinedActivitiesForUserId;
  String? _guideBadgeUserId;
  bool _showGuideBadge = false;

  static const Map<String, Map<String, String>> _localizedCountryNames = {
    'KZ': {'en': 'Kazakhstan', 'ru': 'Казахстан', 'kk': 'Қазақстан'},
  };

  static const Map<String, Map<String, String>> _localizedCityNames = {
    'Almaty': {'en': 'Almaty', 'ru': 'Алматы', 'kk': 'Алматы'},
    'Astana': {'en': 'Astana', 'ru': 'Астана', 'kk': 'Астана'},
  };

  static const _destinationCharynImageUrl =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80';
  static const _destinationLakeImageUrl =
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80';
  static const _destinationKolsaiImageUrl =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80';

  static const _storyImageUrl =
      'https://images.unsplash.com/photo-1511818966892-d7d671e672a2?auto=format&fit=crop&w=900&q=80';

  static const _featuredStaysImageUrl =
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1000&q=80';
  static const _carRentalsImageUrl =
      'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?auto=format&fit=crop&w=1000&q=80';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      if (provider.state == ActivitiesState.initial && provider.items.isEmpty) {
        provider.loadActivities();
      }
      final currentUserId =
          (context.read<SessionProvider>().profile?.userId ?? '').trim();
      if (currentUserId.isNotEmpty &&
          provider.joinedState == ActivitiesState.initial &&
          provider.joinedItems.isEmpty) {
        provider.loadJoinedActivities();
      }
    });
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.logoutDialogTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutDialogMessage,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.logoutConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await authProvider.logout();
    await sessionProvider.clearSession();

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _openMyActivities() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/me/activities');
      return;
    }

    context.push('/me/activities');
  }

  void _openProfile() {
    context.push('/profile');
  }

  void _openActivities() {
    context.push('/activities');
  }

  void _openStories() {
    context.push('/stories');
  }

  void _openNotifications() {
    context.push('/notifications');
  }

  void _openStubRoute(String path) {
    context.push(path);
  }

  void _openAttractions() {
    context.push('/attractions');
  }

  void _openActivityDetails(String activityId) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/$activityId');
      return;
    }

    context.push('/activities/$activityId');
  }

  Future<void> _refreshActivities() async {
    final provider = context.read<ActivityProvider>();
    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    await provider.refreshActivities();
    if (currentUserId.isNotEmpty) {
      await Future.wait<void>([
        provider.refreshMyActivities(),
        provider.refreshJoinedActivities(),
      ]);
    }
  }

  List<_DestinationCardData> _buildDestinations(AppLocalizations l10n) {
    return [
      _DestinationCardData(
        title: l10n.homeDestinationCharynTitle,
        subtitle: l10n.homeDestinationCharynSubtitle,
        imageUrl: _destinationCharynImageUrl,
      ),
      _DestinationCardData(
        title: l10n.homeDestinationLakeTitle,
        subtitle: l10n.homeDestinationLakeSubtitle,
        imageUrl: _destinationLakeImageUrl,
        compact: true,
      ),
      _DestinationCardData(
        title: l10n.homeDestinationKolsaiTitle,
        subtitle: l10n.homeDestinationKolsaiSubtitle,
        imageUrl: _destinationKolsaiImageUrl,
        compact: true,
      ),
    ];
  }

  List<_FeatureEntryData> _buildFeatureEntries(AppLocalizations l10n) {
    return [
      _FeatureEntryData(
        title: l10n.homeFeaturedStays,
        imageUrl: _featuredStaysImageUrl,
        route: '/featured-stays',
      ),
      _FeatureEntryData(
        title: l10n.homeCarRentals,
        imageUrl: _carRentalsImageUrl,
        route: '/car-rentals',
      ),
    ];
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _closeDrawerIfNeeded() async {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null || !scaffoldState.isDrawerOpen) return;

    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  Future<void> _runDrawerAction(FutureOr<void> Function() action) async {
    await _closeDrawerIfNeeded();
    if (!mounted) return;
    await action();
  }

  Future<void> _showLanguageSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        final screenWidth = MediaQuery.sizeOf(sheetContext).width;
        final isCompact = screenWidth < 375;
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final horizontalPadding = isCompact ? 22.0 : 26.0;
        final sheetRadius = isCompact ? 30.0 : 34.0;
        final iconWrapSize = isCompact ? 136.0 : 148.0;
        final glowSize = isCompact ? 156.0 : 170.0;
        final iconSize = isCompact ? 56.0 : 60.0;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(sheetRadius),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF211207), Color(0xFF170D06)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(sheetRadius),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 40,
                        offset: const Offset(0, -12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.02),
                                  Colors.transparent,
                                ],
                                stops: const [0, 0.16],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -24,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, 0.7),
                                radius: 0.95,
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 24 : 28,
                          horizontalPadding,
                          isCompact ? 24 : 30,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 76,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.45,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 26 : 34),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: glowSize,
                                  height: glowSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.accent.withValues(
                                          alpha: 0.26,
                                        ),
                                        AppColors.accent.withValues(
                                          alpha: 0.12,
                                        ),
                                        AppColors.accent.withValues(
                                          alpha: 0.04,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0, 0.3, 0.52, 0.78],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: iconWrapSize,
                                  height: iconWrapSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: const Alignment(0, -0.25),
                                      colors: [
                                        AppColors.accent.withValues(
                                          alpha: 0.05,
                                        ),
                                        AppColors.accent.withValues(
                                          alpha: 0.01,
                                        ),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.36,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 28,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.language_rounded,
                                    size: iconSize,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 22 : 26),
                            Text(
                              l10n.appLanguageTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: isCompact ? 14 : 18,
                                height: 0.98,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.1,
                              ),
                            ),
                            SizedBox(height: isCompact ? 28 : 34),
                            for (final option in _languageOptions) ...[
                              _LanguageOptionTile(
                                label: option.label,
                                code: option.code.toUpperCase(),
                                isSelected: currentCode == option.code,
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(option.code),
                              ),
                              if (option != _languageOptions.last)
                                SizedBox(height: isCompact ? 14 : 16),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedCode == null || !mounted) return;
    await localeProvider.setLocale(selectedCode);
  }

  void _ensureGuideBadgeState(String? currentUserId) {
    final normalizedUserId = (currentUserId ?? '').trim();
    if (normalizedUserId.isEmpty) {
      _guideBadgeUserId = null;
      _showGuideBadge = false;
      return;
    }

    if (_guideBadgeUserId == normalizedUserId) {
      return;
    }

    _guideBadgeUserId = normalizedUserId;
    _showGuideBadge = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final guide = await _guideApi.getMyGuideProfileOrNull();
        if (!mounted || _guideBadgeUserId != normalizedUserId) {
          return;
        }
        setState(() {
          _showGuideBadge = guide?.isVerified == true;
        });
      } catch (_) {
        if (!mounted || _guideBadgeUserId != normalizedUserId) {
          return;
        }
        setState(() {
          _showGuideBadge = false;
        });
      }
    });
  }

  String _resolveLocation(UserProfileVm? profile, Locale locale) {
    final languageCode = locale.languageCode;
    final timezone = (profile?.timezone ?? '').trim();
    final city = _resolveLocalizedCity(timezone, languageCode);
    final country = _resolveLocalizedCountry(
      (profile?.countryCode ?? '').trim(),
      languageCode,
    );

    if (country.isNotEmpty && city.isNotEmpty) {
      return '$country, $city';
    }
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;

    return _localizedCityNames['Almaty']?[languageCode] ?? 'Almaty';
  }

  String _resolveLocalizedCountry(String countryCode, String languageCode) {
    if (countryCode.isEmpty) return '';

    final normalizedCode = countryCode.toUpperCase();
    return _localizedCountryNames[normalizedCode]?[languageCode] ??
        normalizedCode;
  }

  String _resolveLocalizedCity(String timezone, String languageCode) {
    if (timezone.isEmpty) return '';

    final timezoneParts = timezone.split('/');
    if (timezoneParts.length > 1 && timezoneParts.last.trim().isNotEmpty) {
      final cityKey = timezoneParts.last.trim().replaceAll('_', ' ');
      return _localizedCityNames[cityKey]?[languageCode] ?? cityKey;
    }

    return '';
  }

  String _resolveLanguageLabel(String code) {
    return code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final activityProvider = context.watch<ActivityProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final profile = session.profile;
    final currentUserId = (profile?.userId ?? '').trim();
    final location = _resolveLocation(profile, Localizations.localeOf(context));
    final languageCode = Localizations.localeOf(context).languageCode;
    final locationCity = _resolveLocalizedCity(
      (profile?.timezone ?? '').trim(),
      languageCode,
    );
    final destinations = _buildDestinations(l10n);
    final featureEntries = _buildFeatureEntries(l10n);
    final locationTitle = locationCity.isNotEmpty
        ? locationCity
        : location.split(',').last.trim();

    if (currentUserId.isEmpty) {
      _requestedHostedActivitiesForUserId = null;
      _requestedJoinedActivitiesForUserId = null;
    } else if (_requestedHostedActivitiesForUserId != currentUserId &&
        activityProvider.myState != ActivitiesState.loading) {
      _requestedHostedActivitiesForUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ActivityProvider>().loadMyActivities();
      });
    }

    if (currentUserId.isNotEmpty &&
        _requestedJoinedActivitiesForUserId != currentUserId &&
        activityProvider.joinedState != ActivitiesState.loading) {
      _requestedJoinedActivitiesForUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ActivityProvider>().loadJoinedActivities();
      });
    }

    _ensureGuideBadgeState(currentUserId);

    final quickActions = [
      _QuickActionData(
        title: 'Yandex Go',
        icon: Icons.local_taxi_rounded,
        onTap: () => _openStubRoute('/yandex-go'),
      ),
      _QuickActionData(
        title: 'Glovo',
        icon: Icons.restaurant_rounded,
        onTap: () => _openStubRoute('/glovo'),
      ),
      _QuickActionData(
        title: 'Wolt',
        icon: Icons.shopping_bag_rounded,
        onTap: () => _openStubRoute('/wolt'),
      ),
      _QuickActionData(
        title: l10n.homeMoreButton,
        icon: Icons.more_horiz_rounded,
        onTap: () => _openStubRoute('/more-services'),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF160D07),
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      drawer: _HomeSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        showGuideBadge: _showGuideBadge,
        profile: profile,
        location: location,
        languageLabel: _resolveLanguageLabel(
          context.watch<LocaleProvider>().locale.languageCode,
        ),
        onProfileTap: () => _runDrawerAction(_openProfile),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() => context.go('/')),
        onMyActivitiesTap: () => _runDrawerAction(_openMyActivities),
        onMyStoriesTap: () =>
            _runDrawerAction(() => context.push('/me/stories')),
        onActivitiesTap: () => _runDrawerAction(_openActivities),
        onLoginTap: () => _runDrawerAction(() => context.push('/login')),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.home,
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onMapTap: () => context.push('/map'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF191008)),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF20140C), Color(0xFF191008)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -120,
              left: -48,
              right: -48,
              child: IgnorePointer(
                child: Container(
                  height: 310,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.55),
                      radius: 1.0,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.13),
                        AppColors.accent.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.36, 1],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _HomeHeader(
                    location: locationTitle,
                    currentLocationLabel: l10n.homeCurrentLocationLabel,
                    onMenuTap: _openDrawer,
                    onNotificationsTap: _openNotifications,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: _refreshActivities,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 375;
                          final horizontalPadding = isCompact ? 14.0 : 15.0;

                          return CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  14,
                                  horizontalPadding,
                                  28,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SearchBar(
                                        hint: l10n.homeSearchHint,
                                        onTap: _openActivities,
                                      ),
                                      const SizedBox(height: 26),
                                      _SectionHeader(
                                        title: l10n.homeExploreServices,
                                      ),
                                      const SizedBox(height: 14),
                                      _QuickActionsGrid(actions: quickActions),
                                      const SizedBox(height: 26),
                                      _SectionHeader(
                                        title: l10n.homeTopDestinations,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openAttractions,
                                      ),
                                      const SizedBox(height: 14),
                                      _TopDestinationsRow(
                                        destinations: destinations,
                                        onTap: _openAttractions,
                                      ),
                                      const SizedBox(height: 26),
                                      _SectionHeader(
                                        title: l10n.homeRecommendedBlogs,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openStories,
                                      ),
                                      const SizedBox(height: 14),
                                      _StoryCard(
                                        badge: l10n.homeEditorialBadge,
                                        title: l10n.homeStoryTitle,
                                        description: l10n.homeStoryDescription,
                                        buttonLabel: l10n.homeReadStory,
                                        imageUrl: _storyImageUrl,
                                        onTap: _openStories,
                                      ),
                                      const SizedBox(height: 14),
                                      _FeatureEntriesGrid(
                                        entries: featureEntries,
                                        onEntryTap: (entry) =>
                                            _openStubRoute(entry.route),
                                      ),
                                      const SizedBox(height: 26),
                                      _SectionHeader(
                                        title: l10n.homeRecommendedActivities,
                                        actionLabel: l10n.homeSeeAll,
                                        onActionTap: _openActivities,
                                      ),
                                      const SizedBox(height: 16),
                                      _RecommendedActivitiesSection(
                                        provider: activityProvider,
                                        l10n: l10n,
                                        currentUserId: currentUserId,
                                        onRetry: () {
                                          _refreshActivities();
                                        },
                                        onEmptyTap: _openActivities,
                                        onActivityTap: _openActivityDetails,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.location,
    required this.currentLocationLabel,
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  final String location;
  final String currentLocationLabel;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 375;
    final buttonSize = isCompact ? 38.0 : 40.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isCompact ? 13 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.08)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          _HeaderActionButton(
            icon: Icons.menu_rounded,
            size: buttonSize,
            onTap: onMenuTap,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isCompact ? 34 : 38,
                  height: isCompact ? 34 : 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
                    size: isCompact ? 18 : 20,
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLocationLabel,
                        style: TextStyle(
                          color: const Color(0xFFFFB347),
                          fontSize: isCompact ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFFFF7EF),
                                fontSize: isCompact ? 16 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white.withValues(alpha: 0.72),
                            size: isCompact ? 14 : 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _HeaderActionButton(
            icon: Icons.notifications_none_rounded,
            size: buttonSize,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AppColors.accent, size: size < 46 ? 20 : 22),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF382110), Color(0xFF311C0D)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.02),
                blurRadius: 0,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF927C67),
                    fontSize: isCompact ? 15 : 16,
                    fontWeight: FontWeight.w500,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Color(0xFFF5EFE8),
              fontSize: isCompact ? 19 : 20,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final gap = isCompact ? 10.0 : 12.0;
        final tileWidth = (constraints.maxWidth - gap * 3) / 4;
        final boxHeight = tileWidth.clamp(62.0, 74.0);

        return GridView.builder(
          shrinkWrap: true,
          itemCount: actions.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: tileWidth / (boxHeight + 28),
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Ink(
                      width: double.infinity,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF38220F), Color(0xFF2A180B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        action.icon,
                        color: AppColors.accent,
                        size: isCompact ? 24 : 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF2E5D7),
                        fontSize: isCompact ? 12 : 13,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.data,
    required this.onTap,
    this.width,
    this.height,
  });

  final _DestinationCardData data;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.86, 1.06);
    final resolvedWidth =
        width ?? (data.compact ? 168.0 * scale : 238.0 * scale);
    final resolvedHeight = height ?? 318.0 * scale;
    final isCompact = screenWidth < 375;

    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF2F1B0D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkCardImage(imageUrl: data.imageUrl),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 16 : 17,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFB648),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopDestinationsRow extends StatelessWidget {
  const _TopDestinationsRow({required this.destinations, required this.onTap});

  final List<_DestinationCardData> destinations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.86, 1.06);
    final regularWidth = 238.0 * scale;
    final compactWidth = 168.0 * scale;
    final cardHeight = 318.0 * scale;

    return SizedBox(
      height: cardHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++) ...[
              _DestinationCard(
                data: destinations[index],
                onTap: onTap,
                width: destinations[index].compact
                    ? compactWidth
                    : regularWidth,
                height: cardHeight,
              ),
              if (index != destinations.length - 1) const SizedBox(width: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.badge,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.imageUrl,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String description;
  final String buttonLabel;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 390;
    final isVeryCompact = screenWidth < 360;
    final minCardHeight = isVeryCompact ? 238.0 : (isCompact ? 224.0 : 210.0);
    final contentPadding = EdgeInsets.fromLTRB(
      isCompact ? 18 : 18,
      isCompact ? 18 : 18,
      isCompact ? 16 : 18,
      isCompact ? 16 : 16,
    );

    return IntrinsicHeight(
      child: Container(
        constraints: BoxConstraints(minHeight: minCardHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B190D), Color(0xFF22140B)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 23,
              child: Padding(
                padding: contentPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: isCompact ? 28 : 30,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: Color(0xFFFFF7EC),
                                fontSize: isCompact ? 10 : 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 14 : 16),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF5EFE8),
                            fontSize: isCompact ? 17 : 18,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: isCompact ? 10 : 12),
                        Text(
                          description,
                          maxLines: isVeryCompact ? 4 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFD2BCAA),
                            fontSize: isCompact ? 14 : 15,
                            height: isCompact ? 1.38 : 1.45,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 14 : 18),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: const Color(0xFFFFF6EB),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 18 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonLabel,
                          style: TextStyle(
                            fontSize: isCompact ? 15 : 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 17,
              child: ClipPath(
                clipper: _StoryImageClipper(),
                child: _NetworkCardImage(
                  imageUrl: imageUrl,
                  overlay: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureEntriesGrid extends StatelessWidget {
  const _FeatureEntriesGrid({required this.entries, required this.onEntryTap});

  final List<_FeatureEntryData> entries;
  final ValueChanged<_FeatureEntryData> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 375;
        final gap = isCompact ? 10.0 : 12.0;

        return Row(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              Expanded(
                child: _TravelEntryCard(
                  data: entries[index],
                  onTap: () => onEntryTap(entries[index]),
                ),
              ),
              if (index != entries.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _TravelEntryCard extends StatelessWidget {
  const _TravelEntryCard({required this.data, required this.onTap});

  final _FeatureEntryData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: isCompact ? 108 : 112,
          decoration: BoxDecoration(
            color: const Color(0xFF2C190D),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkCardImage(
                  imageUrl: data.imageUrl,
                  overlay: Colors.black.withValues(alpha: 0.12),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.38),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedActivitiesSection extends StatelessWidget {
  const _RecommendedActivitiesSection({
    required this.provider,
    required this.l10n,
    required this.currentUserId,
    required this.onRetry,
    required this.onEmptyTap,
    required this.onActivityTap,
  });

  final ActivityProvider provider;
  final AppLocalizations l10n;
  final String currentUserId;
  final VoidCallback onRetry;
  final VoidCallback onEmptyTap;
  final ValueChanged<String> onActivityTap;

  @override
  Widget build(BuildContext context) {
    final recommendedItems = _mergeHomeRecommendedItems(
      publicItems: provider.items,
      hostedItems: provider.myItems,
      currentUserId: currentUserId,
    );
    final isLoadingPublic =
        provider.state == ActivitiesState.loading ||
        provider.state == ActivitiesState.initial;
    final isLoadingHosted =
        currentUserId.isNotEmpty &&
        (provider.myState == ActivitiesState.loading ||
            provider.myState == ActivitiesState.initial);
    final hasLoadError =
        provider.state == ActivitiesState.error ||
        (currentUserId.isNotEmpty && provider.myState == ActivitiesState.error);

    if (recommendedItems.isEmpty && (isLoadingPublic || isLoadingHosted)) {
      return Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _RecommendedLoadingCard(),
          ),
        ),
      );
    }

    if (recommendedItems.isEmpty && hasLoadError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.errorMessage ??
                  provider.myErrorMessage ??
                  l10n.activitiesLoadFailed,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.30),
                ),
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    if (recommendedItems.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEmptyTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noActivitiesYet,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.activitiesWillAppearHere,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textCaption,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = recommendedItems.take(3).toList(growable: false);
    final joinedIds = currentUserId.isEmpty
        ? const <String>{}
        : provider.joinedItems.map((item) => item.id).toSet();
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _RecommendedActivityCard(
            item: items[index],
            isJoined: joinedIds.contains(items[index].id),
            onTap: () => onActivityTap(items[index].id),
          ),
          if (index != items.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RecommendedActivityCard extends StatelessWidget {
  const _RecommendedActivityCard({
    required this.item,
    required this.isJoined,
    required this.onTap,
  });

  final ActivityListItemVm item;
  final bool isJoined;
  final VoidCallback onTap;

  String _durationLabel(AppLocalizations l10n) {
    final totalHours = item.endAt.difference(item.startAt).inMinutes / 60;
    final roundedHours = totalHours <= 1 ? 1 : totalHours.round();
    return l10n.homeDurationHours(roundedHours);
  }

  String _categoryLabel() {
    return ActivityCategoryVm.humanizeSlug(item.categorySlug);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ActivityThumb(
                item: item,
                imageUrl: resolveActivityCoverUrl(item),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFFFF7EF),
                              fontSize: isCompact ? 15 : 16,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_categoryLabel()} • ${_durationLabel(l10n)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFB8A48F),
                              fontSize: isCompact ? 13 : 14,
                            ),
                          ),
                        ),
                        if (isJoined) ...[
                          const SizedBox(width: 8),
                          _HomeActivityStatusPill(
                            label: l10n.activityDetailsJoinedBadge,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          item.isFree ? l10n.freeLabel : item.priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFFF9F1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.createPricePerPersonHint,
                          style: const TextStyle(
                            color: Color(0xFFD6C4AF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityThumb extends StatelessWidget {
  const _ActivityThumb({required this.item, this.imageUrl});

  final ActivityListItemVm item;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim() ?? '';
    final art = _homeCardArtForItem(item);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 88,
        height: 88,
        child: normalizedImageUrl.isNotEmpty
            ? _NetworkCardImage(imageUrl: normalizedImageUrl)
            : _HomeDecorativeActivityThumb(spec: art),
      ),
    );
  }
}

class _HomeDecorativeActivityThumb extends StatelessWidget {
  const _HomeDecorativeActivityThumb({required this.spec});

  final _HomeCardArtSpec spec;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: spec.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -22,
            top: -18,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -28,
            bottom: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Icon(
                spec.icon,
                size: 34,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActivityStatusPill extends StatelessWidget {
  const _HomeActivityStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NetworkCardImage extends StatelessWidget {
  const _NetworkCardImage({required this.imageUrl, this.overlay});

  final String imageUrl;
  final Color? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5A3519), Color(0xFF2D1A0D)],
                ),
              ),
            );
          },
        ),
        if (overlay != null)
          DecoratedBox(decoration: BoxDecoration(color: overlay)),
      ],
    );
  }
}

class _HomeCardArtSpec {
  const _HomeCardArtSpec({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;
}

_HomeCardArtSpec _homeCategoryVisual(String slug) {
  if (slug.contains('wellness') || slug.contains('health')) {
    return const _HomeCardArtSpec(
      icon: Icons.spa_rounded,
      colors: [Color(0xFF295E54), Color(0xFF74D2AE)],
    );
  }
  if (slug.contains('nature') ||
      slug.contains('outdoor') ||
      slug.contains('hiking')) {
    return const _HomeCardArtSpec(
      icon: Icons.forest_rounded,
      colors: [Color(0xFF2A4B2B), Color(0xFF78C36A)],
    );
  }
  if (slug.contains('food')) {
    return const _HomeCardArtSpec(
      icon: Icons.restaurant_rounded,
      colors: [Color(0xFF66371A), Color(0xFFFFA657)],
    );
  }
  if (slug.contains('culture') ||
      slug.contains('art') ||
      slug.contains('history')) {
    return const _HomeCardArtSpec(
      icon: Icons.palette_outlined,
      colors: [Color(0xFF5A3055), Color(0xFFCB84BA)],
    );
  }
  if (slug.contains('sport') || slug.contains('adventure')) {
    return const _HomeCardArtSpec(
      icon: Icons.kayaking_rounded,
      colors: [Color(0xFF5F3D1F), Color(0xFFE69B4B)],
    );
  }
  if (slug.contains('workshop') ||
      slug.contains('learning') ||
      slug.contains('education')) {
    return const _HomeCardArtSpec(
      icon: Icons.auto_stories_rounded,
      colors: [Color(0xFF443A73), Color(0xFF9A89E2)],
    );
  }
  if (slug.contains('night') || slug.contains('social')) {
    return const _HomeCardArtSpec(
      icon: Icons.celebration_rounded,
      colors: [Color(0xFF5A2348), Color(0xFFE07AB8)],
    );
  }

  return const _HomeCardArtSpec(
    icon: Icons.travel_explore_rounded,
    colors: [Color(0xFF52301B), Color(0xFFCB8B50)],
  );
}

_HomeCardArtSpec _homeCardArtForItem(ActivityListItemVm item) {
  final fromCategory = _homeCategoryVisual(
    item.categorySlug.trim().toLowerCase(),
  );
  if (item.format.toUpperCase() == 'ONLINE') {
    return const _HomeCardArtSpec(
      icon: Icons.videocam_rounded,
      colors: [Color(0xFF1F4D8A), Color(0xFF67A8F5)],
    );
  }
  if (item.format.toUpperCase() == 'HYBRID') {
    return const _HomeCardArtSpec(
      icon: Icons.devices_rounded,
      colors: [Color(0xFF5E3E86), Color(0xFFB08CF6)],
    );
  }
  return fromCategory;
}

class _StoryImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.28, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RecommendedLoadingCard extends StatelessWidget {
  const _RecommendedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _SkeletonLine(width: double.infinity),
                const SizedBox(height: 10),
                _SkeletonLine(width: 180),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: _SkeletonLine(width: 80)),
                    SizedBox(width: 16),
                    _SkeletonChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _HomeSideDrawer extends StatelessWidget {
  const _HomeSideDrawer({
    required this.l10n,
    required this.isLoggedIn,
    required this.showGuideBadge,
    required this.profile,
    required this.location,
    required this.languageLabel,
    required this.onProfileTap,
    required this.onLanguageTap,
    required this.onHomeTap,
    required this.onMyActivitiesTap,
    required this.onMyStoriesTap,
    required this.onActivitiesTap,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  final AppLocalizations l10n;
  final bool isLoggedIn;
  final bool showGuideBadge;
  final UserProfileVm? profile;
  final String location;
  final String languageLabel;
  final VoidCallback onProfileTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onMyActivitiesTap;
  final VoidCallback onMyStoriesTap;
  final VoidCallback onActivitiesTap;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final layout = _HomeDrawerLayout.of(context);
    final profileTitle = isLoggedIn
        ? profile?.preferredName ?? 'FlyFy'
        : 'FlyFy';
    final profileSubtitle = isLoggedIn ? location : l10n.homeSubtitle;
    final avatarText = profile?.initials ?? 'F';
    final avatarUrl = resolvePublicFileContentUrl(
      (profile?.avatarFileId ?? '').trim(),
    );
    return Drawer(
      width: layout.drawerWidth,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(layout.panelRadius),
          bottomRight: Radius.circular(layout.panelRadius),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B120B), Color(0xFF0F0906)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 40,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.13),
                          Colors.transparent,
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -80,
                left: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        layout.topPadding,
                        layout.horizontalPadding,
                        layout.sectionGap,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoggedIn ? onProfileTap : onLoginTap,
                                borderRadius: BorderRadius.circular(
                                  layout.cardRadius,
                                ),
                                child: Ink(
                                  padding: EdgeInsets.all(layout.cardPadding),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      layout.cardRadius,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.05),
                                        AppColors.accent.withValues(
                                          alpha: 0.10,
                                        ),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: layout.avatarSize,
                                            height: layout.avatarSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xFFFDF9F4),
                                                  Color(0xFFF2E7DA),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: AppColors.accent,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.18),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: ClipOval(
                                                child: SizedBox.expand(
                                                  child: avatarUrl == null
                                                      ? Center(
                                                          child: Text(
                                                            avatarText,
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .background,
                                                              fontSize: layout
                                                                  .avatarTextSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        )
                                                      : Image.network(
                                                          avatarUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Center(
                                                            child: Text(
                                                              avatarText,
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .background,
                                                                fontSize: layout
                                                                    .avatarTextSize,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (showGuideBadge)
                                            Positioned(
                                              right: -2,
                                              bottom: 8,
                                              child: Container(
                                                width: layout.avatarBadgeSize,
                                                height: layout.avatarBadgeSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      const LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Color(0xFFFFB347),
                                                          Color(0xFFF98C06),
                                                        ],
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF2B170C,
                                                    ),
                                                    width: 3,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.verified_rounded,
                                                  size: layout
                                                      .avatarBadgeIconSize,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: layout.profileGap),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.18),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                isLoggedIn
                                                    ? l10n.profileTitle
                                                    : l10n.loginButton,
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize:
                                                      layout.metaLabelSize,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: layout.profileTextGap,
                                            ),
                                            Text(
                                              profileTitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize:
                                                    layout.profileTitleSize,
                                                height: 1.05,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(
                                              height: layout.profileTextGap,
                                            ),
                                            Text(
                                              profileSubtitle,
                                              maxLines: isLoggedIn ? 1 : 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.74,
                                                ),
                                                fontSize:
                                                    layout.profileSubtitleSize,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: layout.trailingGap),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                        size: layout.trailingIconSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: layout.sectionGap),
                            _DrawerMenuItem(
                              layout: layout,
                              icon: Icons.language_rounded,
                              iconWidget: Center(
                                child: Text(
                                  languageLabel,
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: layout.iconBoxSize * 0.36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              label: l10n.appLanguageTitle,
                              labelFontSize: layout.menuLabelSize - 3,
                              usePreferencePalette: true,
                              onTap: onLanguageTap,
                            ),
                            SizedBox(height: layout.sectionGap),
                            _DrawerSectionTitle(
                              title: l10n.homeExploreServices,
                              layout: layout,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.homeNavHome,
                              icon: Icons.home_rounded,
                              isActive: true,
                              onTap: onHomeTap,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myActivitiesTitle,
                              icon: Icons.event_note_rounded,
                              usePreferencePalette: true,
                              onTap: onMyActivitiesTap,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.myStoriesTitle,
                              icon: Icons.auto_stories_rounded,
                              usePreferencePalette: true,
                              onTap: onMyStoriesTap,
                            ),
                            SizedBox(height: layout.menuGap),
                            _DrawerMenuItem(
                              layout: layout,
                              label: l10n.activitiesEntryTitle,
                              icon: Icons.explore_rounded,
                              usePreferencePalette: true,
                              onTap: onActivitiesTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          layout.horizontalPadding,
                          0,
                          layout.horizontalPadding,
                          layout.bottomPadding,
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.only(
                                top: layout.footerTopPadding,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.homeTitle,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: layout.brandTitleSize,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.homeSubtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.50,
                                            ),
                                            fontSize: layout.brandSubtitleSize,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: layout.footerGap),
                                  _DrawerFooterAction(
                                    layout: layout,
                                    icon: isLoggedIn
                                        ? Icons.logout_rounded
                                        : Icons.login_rounded,
                                    isAccent: !isLoggedIn,
                                    onTap: isLoggedIn
                                        ? onLogoutTap
                                        : onLoginTap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDrawerLayout {
  const _HomeDrawerLayout({
    required this.drawerWidth,
    required this.panelRadius,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
    required this.avatarTextSize,
    required this.avatarBadgeSize,
    required this.avatarBadgeIconSize,
    required this.profileGap,
    required this.profileTextGap,
    required this.profileTitleSize,
    required this.profileSubtitleSize,
    required this.metaLabelSize,
    required this.trailingGap,
    required this.trailingIconSize,
    required this.sectionGap,
    required this.menuGap,
    required this.menuMinHeight,
    required this.iconBoxSize,
    required this.menuLabelSize,
    required this.footerTopPadding,
    required this.footerGap,
    required this.footerButtonSize,
    required this.brandTitleSize,
    required this.brandSubtitleSize,
    required this.sectionTitleSize,
  });

  final double drawerWidth;
  final double panelRadius;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double cardRadius;
  final double cardPadding;
  final double avatarSize;
  final double avatarTextSize;
  final double avatarBadgeSize;
  final double avatarBadgeIconSize;
  final double profileGap;
  final double profileTextGap;
  final double profileTitleSize;
  final double profileSubtitleSize;
  final double metaLabelSize;
  final double trailingGap;
  final double trailingIconSize;
  final double sectionGap;
  final double menuGap;
  final double menuMinHeight;
  final double iconBoxSize;
  final double menuLabelSize;
  final double footerTopPadding;
  final double footerGap;
  final double footerButtonSize;
  final double brandTitleSize;
  final double brandSubtitleSize;
  final double sectionTitleSize;

  static _HomeDrawerLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isCompact = width < 375;
    final isShort = height < 740;

    return _HomeDrawerLayout(
      drawerWidth: (width * 0.88).clamp(292.0, 388.0).toDouble(),
      panelRadius: width < 420 ? 28 : 32,
      horizontalPadding: isCompact ? 18 : 24,
      topPadding: isShort ? 10 : 14,
      bottomPadding: isShort ? 18 : 22,
      cardRadius: isCompact ? 22 : 26,
      cardPadding: isCompact ? 16 : 20,
      avatarSize: isCompact ? 84 : 100,
      avatarTextSize: isCompact ? 28 : 32,
      avatarBadgeSize: isCompact ? 28 : 32,
      avatarBadgeIconSize: isCompact ? 13 : 14,
      profileGap: isCompact ? 14 : 16,
      profileTextGap: isCompact ? 8 : 10,
      profileTitleSize: isCompact ? 22 : 24,
      profileSubtitleSize: isCompact ? 13 : 14,
      metaLabelSize: isCompact ? 11 : 12,
      trailingGap: isCompact ? 10 : 12,
      trailingIconSize: isCompact ? 20 : 22,
      sectionGap: isShort ? 24 : 30,
      menuGap: isCompact ? 12 : 14,
      menuMinHeight: isCompact ? 78 : 90,
      iconBoxSize: isCompact ? 48 : 54,
      menuLabelSize: isCompact ? 16 : 18,
      footerTopPadding: isCompact ? 16 : 18,
      footerGap: isCompact ? 12 : 16,
      footerButtonSize: isCompact ? 56 : 64,
      brandTitleSize: isCompact ? 22 : 24,
      brandSubtitleSize: isCompact ? 10.5 : 11,
      sectionTitleSize: isCompact ? 11 : 12,
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle({required this.title, required this.layout});

  final String title;
  final _HomeDrawerLayout layout;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: layout.sectionTitleSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.layout,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconWidget,
    this.labelFontSize,
    this.isActive = false,
    this.usePreferencePalette = false,
  });

  final _HomeDrawerLayout layout;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? iconWidget;
  final double? labelFontSize;
  final bool isActive;
  final bool usePreferencePalette;

  @override
  Widget build(BuildContext context) {
    final matchesPreferencePalette = !isActive && usePreferencePalette;
    final foregroundColor = isActive
        ? const Color(0xFFFFB347)
        : Colors.white.withValues(alpha: 0.90);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: layout.menuMinHeight),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: layout.cardPadding,
              vertical: layout.cardPadding - 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(layout.cardRadius),
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.24),
                        AppColors.accent.withValues(alpha: 0.10),
                      ],
                    )
                  : matchesPreferencePalette
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.03),
                        AppColors.accent.withValues(alpha: 0.07),
                      ],
                    )
                  : null,
              color: isActive
                  ? null
                  : matchesPreferencePalette
                  ? null
                  : Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.20)
                    : matchesPreferencePalette
                    ? AppColors.accent.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: layout.iconBoxSize,
                  height: layout.iconBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFB02E), Color(0xFFF98C06)],
                          )
                        : null,
                    color: isActive
                        ? null
                        : matchesPreferencePalette
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: iconWidget ?? Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : matchesPreferencePalette
                        ? AppColors.accent
                        : foregroundColor,
                    size: layout.iconBoxSize * 0.48,
                  ),
                ),
                SizedBox(width: layout.profileGap),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: labelFontSize ?? layout.menuLabelSize,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : matchesPreferencePalette
                          ? FontWeight.w600
                          : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooterAction extends StatelessWidget {
  const _DrawerFooterAction({
    required this.layout,
    required this.icon,
    required this.onTap,
    this.isAccent = false,
  });

  final _HomeDrawerLayout layout;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: layout.footerButtonSize,
          height: layout.footerButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isAccent
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB347), Color(0xFFF98C06)],
                  )
                : null,
            color: isAccent ? null : Colors.white.withValues(alpha: 0.04),
          ),
          child: Icon(
            icon,
            color: isAccent ? AppColors.background : Colors.white70,
            size: layout.footerButtonSize * 0.38,
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFA726), Color(0xFFF98C06)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.accent.withValues(alpha: 0.42),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.96),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.86)
                            : AppColors.accent.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: isSelected ? Colors.white : AppColors.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureEntryData {
  const _FeatureEntryData({
    required this.title,
    required this.imageUrl,
    required this.route,
  });

  final String title;
  final String imageUrl;
  final String route;
}

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _DestinationCardData {
  const _DestinationCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final bool compact;
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(code: 'ru', label: 'Русский'),
  _LanguageOption(code: 'en', label: 'English'),
  _LanguageOption(code: 'kk', label: 'Қазақша'),
];

List<ActivityListItemVm> _mergeHomeRecommendedItems({
  required List<ActivityListItemVm> publicItems,
  required List<ActivityListItemVm> hostedItems,
  required String? currentUserId,
}) {
  final itemsById = <String, ActivityListItemVm>{};

  for (final item in publicItems) {
    if (_isHomePublishedActivity(item.status)) {
      itemsById[item.id] = item;
    }
  }

  final normalizedUserId = (currentUserId ?? '').trim();
  if (normalizedUserId.isNotEmpty) {
    for (final item in hostedItems) {
      if (item.hostUserId != normalizedUserId) {
        continue;
      }
      if (!_isHomePublishedActivity(item.status)) {
        continue;
      }
      itemsById[item.id] = item;
    }
  }

  final merged = itemsById.values.toList(growable: false)
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  return merged;
}

bool _isHomePublishedActivity(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
    case 'ENROLLMENT_OPEN':
    case 'FULL':
    case 'STARTED':
      return true;
    default:
      return false;
  }
}
