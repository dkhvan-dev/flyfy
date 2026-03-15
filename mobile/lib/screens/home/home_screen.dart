import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Map<String, Map<String, String>> _localizedCountryNames = {
    'KZ': {'en': 'Kazakhstan', 'ru': 'Казахстан', 'kk': 'Қазақстан'},
  };

  static const Map<String, Map<String, String>> _localizedCityNames = {
    'Almaty': {'en': 'Almaty', 'ru': 'Алматы', 'kk': 'Алматы'},
    'Astana': {'en': 'Astana', 'ru': 'Астана', 'kk': 'Астана'},
  };

  static const _destinations = [
    _DestinationCardData(
      title: 'Charyn Canyon',
      icon: Icons.landscape_rounded,
      gradient: [Color(0xFF7B341E), Color(0xFFF6AD55)],
    ),
    _DestinationCardData(
      title: 'Big Almaty Lake',
      icon: Icons.water_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF93C5FD)],
    ),
    _DestinationCardData(
      title: 'Shymbulak',
      icon: Icons.downhill_skiing_rounded,
      gradient: [Color(0xFF0F172A), Color(0xFF64748B)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivityProvider>();
      if (provider.state == ActivitiesState.initial && provider.items.isEmpty) {
        provider.loadActivities();
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

  Future<void> _openCreateActivity() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    context.push('/activities/create');
  }

  void _openProfile() {
    context.push('/profile');
  }

  void _openActivities() {
    context.push('/activities');
  }

  void _openActivityDetails(String activityId) {
    context.push('/activities/$activityId');
  }

  Future<void> _refreshActivities() {
    return context.read<ActivityProvider>().refreshActivities();
  }

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final profile = session.profile;
    final location = _resolveLocation(profile, Localizations.localeOf(context));

    final quickActions = [
      _QuickActionData(
        title: l10n.activitiesEntryTitle,
        icon: Icons.explore_rounded,
        onTap: _openActivities,
      ),
      _QuickActionData(
        title: l10n.myActivitiesTitle,
        icon: Icons.event_note_rounded,
        onTap: _openMyActivities,
      ),
      _QuickActionData(
        title: l10n.createActivityFab,
        icon: Icons.add_circle_outline_rounded,
        onTap: _openCreateActivity,
      ),
      _QuickActionData(
        title: l10n.profileTitle,
        icon: Icons.person_outline_rounded,
        onTap: _openProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _HomeBottomNav(
        l10n: l10n,
        onHomeTap: () => context.go('/'),
        onActivitiesTap: _openActivities,
        onCreateTap: _openCreateActivity,
        onMyTap: _openMyActivities,
        onProfileTap: _openProfile,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1E0D), AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HomeHeader(
                l10n: l10n,
                location: location,
                isLoggedIn: isLoggedIn,
                initials: profile?.initials ?? 'F',
                onLoginTap: () => context.push('/login'),
                onLogoutTap: _confirmLogout,
                onProfileTap: _openProfile,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _refreshActivities,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _SearchBar(
                              hint: l10n.homeSearchHint,
                              onTap: _openActivities,
                            ),
                            const SizedBox(height: 28),
                            _SectionHeader(title: l10n.homeExploreServices),
                            const SizedBox(height: 16),
                            _QuickActionsGrid(actions: quickActions),
                            const SizedBox(height: 36),
                            _SectionHeader(
                              title: l10n.homeTopDestinations,
                              actionLabel: l10n.homeSeeAll,
                              onActionTap: _openActivities,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 240,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _destinations.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final destination = _destinations[index];
                                  return _DestinationCard(
                                    data: destination,
                                    onTap: _openActivities,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 36),
                            _StoryCard(
                              badge: l10n.homeEditorialBadge,
                              title: l10n.homeStoryTitle,
                              description: l10n.homeStoryDescription,
                              buttonLabel: l10n.homeReadStory,
                              onTap: _openActivities,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _TravelEntryCard(
                                    title: l10n.homeFeaturedStays,
                                    icon: Icons.hotel_rounded,
                                    gradient: const [
                                      Color(0xFF334155),
                                      Color(0xFF0F172A),
                                    ],
                                    onTap: _showComingSoon,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _TravelEntryCard(
                                    title: l10n.homeCarRentals,
                                    icon: Icons.directions_car_rounded,
                                    gradient: const [
                                      Color(0xFF111827),
                                      Color(0xFF475569),
                                    ],
                                    onTap: _showComingSoon,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            _SectionHeader(
                              title: l10n.homeRecommendedActivities,
                              actionLabel: l10n.homeFilterButton,
                              onActionTap: _openActivities,
                            ),
                            const SizedBox(height: 16),
                            Consumer<ActivityProvider>(
                              builder: (context, provider, _) {
                                return _RecommendedActivitiesSection(
                                  provider: provider,
                                  l10n: l10n,
                                  onRetry: provider.loadActivities,
                                  onEmptyTap: _openActivities,
                                  onActivityTap: _openActivityDetails,
                                );
                              },
                            ),
                          ]),
                        ),
                      ),
                    ],
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.l10n,
    required this.location,
    required this.isLoggedIn,
    required this.initials,
    required this.onLoginTap,
    required this.onLogoutTap,
    required this.onProfileTap,
  });

  final AppLocalizations l10n;
  final String location;
  final bool isLoggedIn;
  final String initials;
  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        border: Border(
          bottom: BorderSide(color: AppColors.accent.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeCurrentLocationLabel,
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.90),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoggedIn) ...[
            _HeaderActionButton(icon: Icons.logout_rounded, onTap: onLogoutTap),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ] else
            TextButton(
              onPressed: onLoginTap,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(l10n.loginButton),
            ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textCaption,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textCaption,
                    fontSize: 15,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
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
    return GridView.builder(
      shrinkWrap: true,
      itemCount: actions.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Ink(
                  width: double.infinity,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(action.icon, color: AppColors.accent, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.data, required this.onTap});

  final _DestinationCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 188,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: data.gradient,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -24,
                  right: -12,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 52,
                  left: -18,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Icon(
                    data.icon,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 26,
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
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
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.badge,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF7C2D12), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 22,
                        left: 22,
                        right: 22,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 64,
                        left: 28,
                        right: 28,
                        bottom: 0,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
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
        ],
      ),
    );
  }
}

class _TravelEntryCard extends StatelessWidget {
  const _TravelEntryCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 136,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -14,
                right: -10,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.white, size: 30),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
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

class _RecommendedActivitiesSection extends StatelessWidget {
  const _RecommendedActivitiesSection({
    required this.provider,
    required this.l10n,
    required this.onRetry,
    required this.onEmptyTap,
    required this.onActivityTap,
  });

  final ActivityProvider provider;
  final AppLocalizations l10n;
  final VoidCallback onRetry;
  final VoidCallback onEmptyTap;
  final ValueChanged<String> onActivityTap;

  @override
  Widget build(BuildContext context) {
    if ((provider.state == ActivitiesState.loading ||
            provider.state == ActivitiesState.initial) &&
        provider.items.isEmpty) {
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

    if (provider.state == ActivitiesState.error && provider.items.isEmpty) {
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
              provider.errorMessage ?? l10n.activitiesLoadFailed,
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

    if (provider.items.isEmpty) {
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

    final items = provider.items.take(3).toList(growable: false);
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _RecommendedActivityCard(
            item: items[index],
            onTap: () => onActivityTap(items[index].id),
          ),
          if (index != items.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RecommendedActivityCard extends StatelessWidget {
  const _RecommendedActivityCard({required this.item, required this.onTap});

  final ActivityListItemVm item;
  final VoidCallback onTap;

  String _ctaLabel(AppLocalizations l10n) {
    if (item.format.toUpperCase() == 'ONLINE') {
      return l10n.activityGetLink;
    }
    return l10n.activityViewDetails;
  }

  String _priceLabel(AppLocalizations l10n) {
    if (item.isFree) return l10n.createPriceFree;
    return item.priceLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final location = item.shortLocation.isNotEmpty
        ? item.shortLocation
        : formatActivityStatus(item.status, l10n);
    final meta = [
      if (location.isNotEmpty) location,
      formatActivityFormat(item.format, l10n),
      DateFormat.MMMd(locale).format(item.startAt),
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              _ActivityThumb(item: item),
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
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            formatActivityFormat(item.format, l10n),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _priceLabel(l10n),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _ctaLabel(l10n),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

class _ActivityThumb extends StatelessWidget {
  const _ActivityThumb({required this.item});

  final ActivityListItemVm item;

  List<Color> _gradient() {
    switch (item.format.toUpperCase()) {
      case 'ONLINE':
        return const [Color(0xFF1D4ED8), Color(0xFF60A5FA)];
      case 'HYBRID':
        return const [Color(0xFF7C3AED), Color(0xFFA78BFA)];
      default:
        return const [Color(0xFF166534), Color(0xFF4ADE80)];
    }
  }

  IconData _icon() {
    switch (item.format.toUpperCase()) {
      case 'ONLINE':
        return Icons.videocam_rounded;
      case 'HYBRID':
        return Icons.hub_rounded;
      default:
        return Icons.terrain_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradient(),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -6,
            right: -2,
            child: Icon(
              _icon(),
              size: 48,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
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

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.l10n,
    required this.onHomeTap,
    required this.onActivitiesTap,
    required this.onCreateTap,
    required this.onMyTap,
    required this.onProfileTap,
  });

  final AppLocalizations l10n;
  final VoidCallback onHomeTap;
  final VoidCallback onActivitiesTap;
  final VoidCallback onCreateTap;
  final VoidCallback onMyTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              label: l10n.homeNavHome,
              icon: Icons.home_rounded,
              isActive: true,
              onTap: onHomeTap,
            ),
            _NavItem(
              label: l10n.activitiesEntryTitle,
              icon: Icons.explore_rounded,
              onTap: onActivitiesTap,
            ),
            _NavItem(
              label: l10n.createActivityFab,
              icon: Icons.add_circle_rounded,
              onTap: onCreateTap,
            ),
            _NavItem(
              label: l10n.homeNavMy,
              icon: Icons.event_note_rounded,
              onTap: onMyTap,
            ),
            _NavItem(
              label: l10n.profileTitle,
              icon: Icons.person_rounded,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textCaption;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
    required this.icon,
    required this.gradient,
  });

  final String title;
  final IconData icon;
  final List<Color> gradient;
}
