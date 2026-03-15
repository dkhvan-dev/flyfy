import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadActivities();
    });
  }

  Future<void> _onCreateTap(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/activities/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled) return;
    if (!context.mounted) return;

    context.push('/activities/create');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthProvider>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: authState == AuthState.authenticated
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(l10n.createActivityFab),
              onPressed: () => _onCreateTap(context),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header: title + notification icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/'),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.accent,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.appTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.textCaption,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.activitiesSearchHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textCaption,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            _FilterChips(l10n: l10n),
            const SizedBox(height: 8),

            // Activity list
            Expanded(
              child: Consumer<ActivityProvider>(
                builder: (context, provider, _) {
                  if (provider.state == ActivitiesState.loading &&
                      provider.items.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  if (provider.state == ActivitiesState.error &&
                      provider.items.isEmpty) {
                    return ErrorView(
                      message:
                          provider.errorMessage ?? l10n.activitiesLoadFailed,
                      onRetry: provider.loadActivities,
                    );
                  }

                  if (provider.items.isEmpty) {
                    return _ActivitiesEmptyView(
                      title: l10n.noActivitiesYet,
                      subtitle: l10n.activitiesWillAppearHere,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.refreshActivities,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return _ActivityCard(item: item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chips ────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (Icons.category_outlined, l10n.activitiesFilterCategory),
      (Icons.calendar_today_outlined, l10n.activitiesFilterDate),
      (Icons.payments_outlined, l10n.activitiesFilterPricing),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (icon, label) = filters[index];
          return GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.accent : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: index == 0
                    ? null
                    : Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: index == 0
                        ? AppColors.background
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: index == 0
                          ? AppColors.background
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: index == 0
                        ? AppColors.background
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Activity Card ───────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityListItemVm item;

  String _ctaLabel(AppLocalizations l10n) {
    switch (item.format.toUpperCase()) {
      case 'ONLINE':
        return l10n.activityGetLink;
      default:
        return l10n.activityViewDetails;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateText = DateFormat.yMMMd(locale).add_Hm().format(item.startAt);

    return GestureDetector(
      onTap: () => context.push('/activities/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image placeholder with price badge
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        AppColors.surfaceLight,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppColors.textCaption,
                    ),
                  ),
                ),
                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.isFree ? l10n.freeLabel : item.priceLabel,
                      style: TextStyle(
                        color: item.isFree
                            ? AppColors.success
                            : AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Host row: avatar + category + name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.2,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categorySlug.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            l10n.activityHostSection,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Location + format row
                  Row(
                    children: [
                      if (item.shortLocation.isNotEmpty) ...[
                        const Icon(
                          Icons.place,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.shortLocation,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Icon(_formatIcon(), size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        formatActivityFormat(item.format, l10n),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date row
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push('/activities/${item.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _ctaLabel(l10n),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
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
    );
  }

  IconData _formatIcon() {
    switch (item.format.toUpperCase()) {
      case 'ONLINE':
        return Icons.videocam;
      case 'HYBRID':
        return Icons.devices;
      default:
        return Icons.location_on;
    }
  }
}

// ── Empty View ──────────────────────────────────────────────

class _ActivitiesEmptyView extends StatelessWidget {
  const _ActivitiesEmptyView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.explore_outlined,
              size: 72,
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
