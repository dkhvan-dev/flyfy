import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  String _selectedFilter = 'ALL';
  final List<String> publishedStatuses = ['PUBLISHED', 'ENROLLMENT_OPEN'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadMyActivities();
    });
  }

  List<ActivityListItemVm> _filterItems(List<ActivityListItemVm> items) {
    if (_selectedFilter == 'ALL') return items;

    if (_selectedFilter == 'PUBLISHED') {
      return items.where((item) {
        final status = item.status.toUpperCase();
        return publishedStatuses.contains(status);
      }).toList();
    }

    return items
        .where((i) => i.status.toUpperCase() == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.myActivitiesTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () async {
          final provider = context.read<ActivityProvider>();
          await context.push('/activities/create');
          if (mounted) {
            provider.loadMyActivities();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _FilterTabs(
            selected: _selectedFilter,
            onChanged: (v) => setState(() => _selectedFilter = v),
          ),
          Expanded(
            child: Consumer<ActivityProvider>(
              builder: (context, provider, _) {
                if (provider.myState == ActivitiesState.loading &&
                    provider.myItems.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (provider.myState == ActivitiesState.error &&
                    provider.myItems.isEmpty) {
                  return ErrorView(
                    message:
                        provider.myErrorMessage ?? l10n.myActivitiesLoadFailed,
                    onRetry: provider.loadMyActivities,
                  );
                }

                final filtered = _filterItems(provider.myItems);

                if (filtered.isEmpty) {
                  return _EmptyView(
                    title: l10n.myActivitiesEmpty,
                    subtitle: l10n.myActivitiesEmptyHint,
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.refreshMyActivities,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _MyActivityCard(item: filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Tabs ──────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filters = <String, String>{
      'ALL': l10n.myActivitiesFilterAll,
      'DRAFT': l10n.activityStatusDraft,
      'PUBLISHED': l10n.activityStatusPublished,
      'REVIEW_REQUIRED': l10n.activityStatusReviewRequired,
      'COMPLETED': l10n.activityStatusCompleted,
      'CANCELLED': l10n.activityStatusCancelled,
    };

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = filters.entries.elementAt(index);
          final isSelected = entry.key == selected;

          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Activity Card ────────────────────────────────────────────

class _MyActivityCard extends StatelessWidget {
  const _MyActivityCard({required this.item});

  final ActivityListItemVm item;

  bool get _isDraft => item.status.toUpperCase() == 'DRAFT';

  Color _statusColor() {
    switch (item.status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'PUBLISHED':
      case 'ENROLLMENT_OPEN':
        return AppColors.success;
      case 'REVIEW_REQUIRED':
        return Colors.orange;
      case 'COMPLETED':
        return AppColors.accent;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'FULL':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final updatedText = DateFormat('dd MMM yyyy', locale).format(item.startAt);

    return GestureDetector(
      onTap: () => context.push('/activities/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image placeholder with gradient
            Stack(
              children: [
                Container(
                  height: 160,
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
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatActivityStatus(item.status, l10n),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Format badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_formatIcon(), size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          formatActivityFormat(item.format, l10n),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.isFree ? l10n.freeLabel : item.priceLabel,
                        style: TextStyle(
                          color: item.isFree
                              ? AppColors.success
                              : AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Last updated
                  Text(
                    updatedText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info chips row
                  Row(
                    children: [
                      if (item.shortLocation.isNotEmpty) ...[
                        const Icon(
                          Icons.place,
                          size: 14,
                          color: AppColors.textCaption,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.shortLocation,
                            style: const TextStyle(
                              color: AppColors.textCaption,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (item.capacityType.toUpperCase() == 'LIMITED' &&
                          item.maxParticipants != null) ...[
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textCaption,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.maxParticipants}',
                          style: const TextStyle(
                            color: AppColors.textCaption,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: _isDraft
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              await context.push(
                                '/activities/${item.id}/edit',
                                extra: item,
                              );
                              if (context.mounted) {
                                context
                                    .read<ActivityProvider>()
                                    .loadMyActivities();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: Text(l10n.editActivityButton),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.accent,
                                width: 1,
                              ),
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              context.push('/activities/${item.id}');
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(l10n.myActivitiesContinueButton),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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

// ── Empty View ───────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.subtitle});

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
              Icons.event_note_outlined,
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
