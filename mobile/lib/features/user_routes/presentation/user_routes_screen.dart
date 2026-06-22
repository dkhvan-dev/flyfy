import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_colors.dart';
import '../../../core/ui/error_view.dart';
import '../../../features/user_routes/models/user_route_models.dart';
import '../../../features/user_routes/user_route_feature_flags.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_routes_provider.dart';

enum _UserRoutesTab { publicRoutes, myRoutes, savedRoutes }

class UserRoutesScreen extends StatefulWidget {
  const UserRoutesScreen({super.key});

  @override
  State<UserRoutesScreen> createState() => _UserRoutesScreenState();
}

class _UserRoutesScreenState extends State<UserRoutesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<_UserRoutesTab> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _UserRoutesTab.values.length,
      vsync: this,
    )..addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCurrentTab(force: true);
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    _loadCurrentTab();
  }

  _UserRoutesTab get _currentTab => _UserRoutesTab.values[_tabController.index];

  bool get _isAuthenticated =>
      context.read<AuthProvider>().state == AuthState.authenticated;

  Future<void> _loadCurrentTab({bool force = false}) async {
    final tab = _currentTab;
    if (!force && _loadedTabs.contains(tab)) {
      return;
    }
    if (tab != _UserRoutesTab.publicRoutes && !_isAuthenticated) {
      return;
    }

    final provider = context.read<UserRoutesProvider>();
    switch (tab) {
      case _UserRoutesTab.publicRoutes:
        await provider.loadPublicRoutes();
      case _UserRoutesTab.myRoutes:
        await provider.loadMyRoutes();
      case _UserRoutesTab.savedRoutes:
        await provider.loadSavedRoutes();
    }
    _loadedTabs.add(tab);
  }

  List<UserRouteVm> _routesForTab(
    UserRoutesProvider provider,
    _UserRoutesTab tab,
  ) {
    return switch (tab) {
      _UserRoutesTab.publicRoutes => provider.publicRoutes,
      _UserRoutesTab.myRoutes => provider.myRoutes,
      _UserRoutesTab.savedRoutes => provider.savedRoutes,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.userRoutesTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (UserRouteFeatureFlags.customRoutesEnabled)
            IconButton(
              tooltip: l10n.mapRouteBuilderTitle,
              onPressed: () => context.push('/map?mode=route-builder'),
              icon: const Icon(Icons.add_location_alt_rounded),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.userRoutesPublicTab),
            Tab(text: l10n.userRoutesMineTab),
            Tab(text: l10n.userRoutesSavedTab),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<UserRoutesProvider, AuthProvider>(
          builder: (context, provider, authProvider, _) {
            final tab = _currentTab;
            final isAuthenticated =
                authProvider.state == AuthState.authenticated;
            if (tab != _UserRoutesTab.publicRoutes && !isAuthenticated) {
              return _UserRoutesAuthPrompt(
                onLogin: () => context.push('/login?from=/user-routes'),
              );
            }

            final routes = _routesForTab(provider, tab);
            final isInitialLoading =
                provider.state == UserRoutesState.loading && routes.isEmpty;
            final isInitialError =
                provider.state == UserRoutesState.error && routes.isEmpty;

            if (isInitialLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (isInitialError) {
              return ErrorView(
                message: provider.errorMessage ?? l10n.userRoutesSaveFailed,
                onRetry: () => _loadCurrentTab(force: true),
              );
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () => _loadCurrentTab(force: true),
              child: routes.isEmpty
                  ? _UserRoutesEmptyState(tab: tab)
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: routes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return _UserRouteCard(
                          route: route,
                          onTap: () => context.push(
                            '/user-routes/${Uri.encodeComponent(route.id)}',
                            extra: route,
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _UserRouteCard extends StatelessWidget {
  const _UserRouteCard({required this.route, required this.onTap});

  final UserRouteVm route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF21140C),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _VisibilityBadge(visibility: route.visibility),
                ],
              ),
              if ((route.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  route.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RouteMetaChip(
                    icon: Icons.place_outlined,
                    label: l10n.userRoutesStopsCount(route.points.length),
                  ),
                  _RouteMetaChip(
                    icon: Icons.schedule_rounded,
                    label: l10n.routeDurationMinutesShort(
                      (route.snapshot.durationSeconds / 60).round().clamp(
                        1,
                        1440,
                      ),
                    ),
                  ),
                  _RouteMetaChip(
                    icon: Icons.bookmark_rounded,
                    label: route.stats.savesCount.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRoutesEmptyState extends StatelessWidget {
  const _UserRoutesEmptyState({required this.tab});

  final _UserRoutesTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, subtitle) = switch (tab) {
      _UserRoutesTab.publicRoutes => (
        l10n.userRoutesPublicEmptyTitle,
        l10n.userRoutesPublicEmptySubtitle,
      ),
      _UserRoutesTab.myRoutes => (
        l10n.userRoutesMineEmptyTitle,
        l10n.userRoutesMineEmptySubtitle,
      ),
      _UserRoutesTab.savedRoutes => (
        l10n.userRoutesSavedEmptyTitle,
        l10n.userRoutesSavedEmptySubtitle,
      ),
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        Icon(
          Icons.route_outlined,
          size: 64,
          color: AppColors.accent.withValues(alpha: 0.82),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _UserRoutesAuthPrompt extends StatelessWidget {
  const _UserRoutesAuthPrompt({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: AppColors.accent,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.userRoutesLoginRequiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.userRoutesLoginRequiredSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF241100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.userRoutesLoginRequiredButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});

  final UserRouteVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (visibility) {
      UserRouteVisibility.private => l10n.userRoutesVisibilityPrivate,
      UserRouteVisibility.unlisted => l10n.userRoutesVisibilityUnlisted,
      UserRouteVisibility.public => l10n.userRoutesVisibilityPublic,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RouteMetaChip extends StatelessWidget {
  const _RouteMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.accent),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
