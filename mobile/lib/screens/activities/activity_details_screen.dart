import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
  });

  final String activityId;

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadActivityDetails(widget.activityId);
    });
  }

  @override
  void dispose() {
    context.read<ActivityProvider>().clearSelectedActivity();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push(
        Uri(
          path: '/login',
          queryParameters: {'from': '/activities/${widget.activityId}'},
        ).toString(),
      );
      return;
    }

    final provider = context.read<ActivityProvider>();
    final success = await provider.joinActivity(widget.activityId);

    if (!mounted) return;

    if (!success) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.activityJoinFailed,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.activityJoinSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.activityDetailsTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          if (provider.state == ActivitiesState.loading &&
              provider.selectedActivity == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            );
          }

          if (provider.state == ActivitiesState.error &&
              provider.selectedActivity == null) {
            return _ActivityDetailsErrorView(
              message: provider.errorMessage ?? l10n.activityDetailsLoadFailed,
              onRetry: () => provider.loadActivityDetails(widget.activityId),
            );
          }

          final activity = provider.selectedActivity;
          if (activity == null) {
            return _ActivityDetailsErrorView(
              message: l10n.activityNotFound,
              onRetry: () => provider.loadActivityDetails(widget.activityId),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadActivityDetails(widget.activityId),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(activity: activity),
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: l10n.activityAboutSection,
                        child: Text(
                          activity.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: l10n.activityInfoSection,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.schedule,
                              label: l10n.activityDateAndTime,
                              value: _formatDateRange(activity),
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.category_outlined,
                              label: l10n.activityCategory,
                              value: activity.categorySlug,
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.language,
                              label: l10n.activityLanguage,
                              value: activity.languageCode.toUpperCase(),
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.people_outline,
                              label: l10n.activityCapacity,
                              value: _formatCapacity(activity, l10n),
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.payments_outlined,
                              label: l10n.activityPrice,
                              value: activity.isFree
                                  ? l10n.freeLabel
                                  : activity.priceLabel,
                            ),
                            if (activity.shortLocation.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _InfoRow(
                                icon: Icons.place_outlined,
                                label: l10n.activityLocation,
                                value: activity.shortLocation,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (activity.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoCard(
                          title: l10n.activityTagsSection,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: activity.tags
                                .map((tag) => _TagChip(label: '#$tag'))
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: l10n.activityAccessSection,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.activitySensitiveDetailsProtected,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.activitySensitiveDetailsHint,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Consumer<ActivityProvider>(
                      builder: (context, provider, _) {
                        final isLoading =
                            provider.actionState == ActivityActionState.loading;

                        return ElevatedButton(
                          onPressed: isLoading ? null : _handleJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.activityJoinButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateRange(ActivityListItemVm activity) {
    final start = activity.startAt.toLocal();
    final end = activity.endAt.toLocal();

    final startDate = DateFormat('dd.MM.yyyy HH:mm').format(start);
    final endDate = DateFormat('dd.MM.yyyy HH:mm').format(end);

    return '$startDate — $endDate';
  }

  String _formatCapacity(
    ActivityListItemVm activity,
    AppLocalizations l10n,
  ) {
    if (activity.capacityType.toUpperCase() == 'UNLIMITED') {
      return l10n.activityUnlimitedCapacity;
    }
    return l10n.activityLimitedCapacity;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.activity});

  final ActivityListItemVm activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: _formatStatus(activity.status, l10n)),
              _TagChip(label: _formatFormat(activity.format, l10n)),
              _TagChip(
                label: activity.isFree
                    ? l10n.freeLabel
                    : '${l10n.fromLabel} ${activity.priceLabel}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (activity.shortLocation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: Color(0xFF00BCD4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.shortLocation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00BCD4)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

class _ActivityDetailsErrorView extends StatelessWidget {
  const _ActivityDetailsErrorView({
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