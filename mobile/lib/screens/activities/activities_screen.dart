import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: Text(
          l10n.activitiesTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          if (provider.state == ActivitiesState.loading &&
              provider.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            );
          }

          if (provider.state == ActivitiesState.error &&
              provider.items.isEmpty) {
            return _ActivitiesErrorView(
              message: provider.errorMessage ?? l10n.activitiesLoadFailed,
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
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _ActivityCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityListItemVm item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateText = DateFormat('dd.MM.yyyy HH:mm').format(item.startAt.toLocal());

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        context.push('/activities/${item.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(label: _formatStatus(item.status, l10n)),
                _TagChip(label: _formatFormat(item.format, l10n)),
                _TagChip(
                  label: item.isFree
                      ? l10n.freeLabel
                      : '${l10n.fromLabel} ${item.priceLabel}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            if (item.shortLocation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place, size: 18, color: Color(0xFF00BCD4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.shortLocation,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.tags
                    .take(4)
                    .map((tag) => _TagChip(label: '#$tag'))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/activities/${item.id}');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.14)),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.detailsButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String value, AppLocalizations l10n) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return l10n.activityStatusDraft;
      case 'REVIEW_REQUIRED':
        return l10n.activityStatusReviewRequired;
      case 'PUBLISHED':
        return l10n.activityStatusPublished;
      case 'ENROLLMENT_OPEN':
        return l10n.activityStatusEnrollmentOpen;
      case 'FULL':
        return l10n.activityStatusFull;
      case 'STARTED':
        return l10n.activityStatusStarted;
      case 'COMPLETED':
        return l10n.activityStatusCompleted;
      case 'CANCELLED':
        return l10n.activityStatusCancelled;
      default:
        return value;
    }
  }

  String _formatFormat(String value, AppLocalizations l10n) {
    switch (value.toUpperCase()) {
      case 'OFFLINE':
        return l10n.activityFormatOffline;
      case 'ONLINE':
        return l10n.activityFormatOnline;
      case 'HYBRID':
        return l10n.activityFormatHybrid;
      default:
        return value;
    }
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7EE6F2),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivitiesEmptyView extends StatelessWidget {
  const _ActivitiesEmptyView({
    required this.title,
    required this.subtitle,
  });

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
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitiesErrorView extends StatelessWidget {
  const _ActivitiesErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}