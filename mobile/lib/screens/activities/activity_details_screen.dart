import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/tag_chip.dart';
import '../../features/activities/activity_formatters.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';

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

  Future<void> _handlePublish() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ActivityProvider>();
    final success = await provider.publishActivity(widget.activityId);

    if (!mounted) return;

    if (success) {
      provider.loadActivities();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activityPublishSuccess)),
      );
    } else {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: provider.actionErrorMessage ?? l10n.activityPublishFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionProvider = context.watch<SessionProvider>();
    final currentUserId = sessionProvider.profile?.userId;

    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        final activity = provider.selectedActivity;
        final isOwner = currentUserId != null &&
            activity != null &&
            currentUserId == activity.hostUserId;
        final status = activity?.status.toUpperCase() ?? '';
        final isDraft = status == 'DRAFT';
        final isEditable = isDraft ||
            status == 'REVIEW_REQUIRED' ||
            status == 'ENROLLMENT_OPEN' ||
            status == 'FULL';
        final canEdit = isOwner && isEditable;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: _buildBody(
              context, provider, activity, l10n, isOwner, isDraft, canEdit),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ActivityProvider provider,
    ActivityListItemVm? activity,
    AppLocalizations l10n,
    bool isOwner,
    bool isDraft,
    bool canEdit,
  ) {
    if (provider.state == ActivitiesState.loading &&
        provider.selectedActivity == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (provider.state == ActivitiesState.error &&
        provider.selectedActivity == null) {
      return ErrorView(
        message: provider.errorMessage ?? l10n.activityDetailsLoadFailed,
        onRetry: () => provider.loadActivityDetails(widget.activityId),
      );
    }

    if (activity == null) {
      return ErrorView(
        message: l10n.activityNotFound,
        onRetry: () => provider.loadActivityDetails(widget.activityId),
      );
    }

    final showBottomBar = (isOwner && isDraft) || !isOwner;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadActivityDetails(widget.activityId),
            child: CustomScrollView(
              slivers: [
                // Hero image with transparent app bar
                _HeroSliverAppBar(
                  activity: activity,
                  canEdit: canEdit,
                  l10n: l10n,
                  activityId: widget.activityId,
                ),
                // Content
                SliverToBoxAdapter(
                  child: _ContentSection(
                    activity: activity,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showBottomBar)
          _BottomBar(
            activity: activity,
            isOwner: isOwner,
            isDraft: isDraft,
            provider: provider,
            l10n: l10n,
            onJoin: _handleJoin,
            onPublish: _handlePublish,
          ),
      ],
    );
  }
}

// ── Hero Sliver App Bar ─────────────────────────────────────

class _HeroSliverAppBar extends StatelessWidget {
  const _HeroSliverAppBar({
    required this.activity,
    required this.canEdit,
    required this.l10n,
    required this.activityId,
  });

  final ActivityListItemVm activity;
  final bool canEdit;
  final AppLocalizations l10n;
  final String activityId;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        children: [
          Text(
            l10n.activityDetailsTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          Text(
            formatActivityStatus(activity.status, l10n).toUpperCase(),
            style: TextStyle(
              color: _statusColor(activity.status),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editActivityButton,
            onPressed: () {
              context.push(
                '/activities/$activityId/edit',
                extra: activity,
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    AppColors.background,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.white24,
                ),
              ),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            // Category + spots chips at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  TagChip(label: activity.categorySlug.toUpperCase()),
                  const SizedBox(width: 8),
                  if (activity.capacityType.toUpperCase() == 'LIMITED' &&
                      activity.maxParticipants != null)
                    TagChip(
                      label: l10n.activitySpotsLeft(activity.maxParticipants!),
                    )
                  else
                    TagChip(label: l10n.activityUnlimitedSpots),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
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
}

// ── Content Section ─────────────────────────────────────────

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.activity,
    required this.l10n,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            activity.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            activity.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Host profile section
          _HostSection(activity: activity, l10n: l10n),
          const SizedBox(height: 24),

          // Info grid 2x2
          _InfoGrid(activity: activity, l10n: l10n),
          const SizedBox(height: 24),

          // Meeting point
          if (activity.addressText != null &&
              activity.addressText!.trim().isNotEmpty)
            _MeetingPointSection(activity: activity, l10n: l10n),

          // Tags
          if (activity.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  activity.tags.map((tag) => TagChip(label: '#$tag')).toList(),
            ),
          ],

          // Access and safety
          const SizedBox(height: 24),
          Text(
            l10n.activityAccessSection,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.activitySensitiveDetailsProtected,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.activitySensitiveDetailsHint,
            style: const TextStyle(
              color: AppColors.textCaption,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Host Section ────────────────────────────────────────────

class _HostSection extends StatelessWidget {
  const _HostSection({required this.activity, required this.l10n});

  final ActivityListItemVm activity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Name and role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activityHostSection,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.categorySlug,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Profile button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent, width: 1),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.profileTitle,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Grid (2x2) ─────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.activity, required this.l10n});

  final ActivityListItemVm activity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final start = activity.startAt.toLocal();
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).add_Hm().format(start);

    final priceStr = activity.isFree
        ? l10n.freeLabel
        : '${activity.priceLabel} ${l10n.activityPerPerson}';

    final formatStr = formatActivityFormat(activity.format, l10n);
    final formatDetail = activity.format.toUpperCase() == 'OFFLINE'
        ? '(${activity.categorySlug})'
        : '';

    final capacityStr = activity.capacityType.toUpperCase() == 'LIMITED' &&
            activity.maxParticipants != null
        ? l10n.activityPeopleMax(activity.maxParticipants!)
        : l10n.activityUnlimitedSpots;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoGridCell(
                icon: Icons.calendar_today_outlined,
                label: l10n.activityDateAndTime.toUpperCase(),
                value: dateStr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoGridCell(
                icon: Icons.payments_outlined,
                label: l10n.activityPricing.toUpperCase(),
                value: priceStr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoGridCell(
                icon: Icons.language,
                label: l10n.activityCategory.toUpperCase(),
                value: '$formatStr $formatDetail'.trim(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoGridCell(
                icon: Icons.people_outline,
                label: l10n.activityTotalCapacity.toUpperCase(),
                value: capacityStr,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoGridCell extends StatelessWidget {
  const _InfoGridCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textCaption,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meeting Point Section ───────────────────────────────────

class _MeetingPointSection extends StatelessWidget {
  const _MeetingPointSection({
    required this.activity,
    required this.l10n,
  });

  final ActivityListItemVm activity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.activityMeetingPoint,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.activityGetDirections,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Map placeholder
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Center(
            child: Icon(
              Icons.map_outlined,
              size: 40,
              color: Colors.white24,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.place, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                activity.addressText ?? activity.shortLocation,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bottom Bar ──────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.activity,
    required this.isOwner,
    required this.isDraft,
    required this.provider,
    required this.l10n,
    required this.onJoin,
    required this.onPublish,
  });

  final ActivityListItemVm activity;
  final bool isOwner;
  final bool isDraft;
  final ActivityProvider provider;
  final AppLocalizations l10n;
  final VoidCallback onJoin;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final isLoading = provider.actionState == ActivityActionState.loading;

    String buttonLabel;
    Color buttonColor;
    VoidCallback? onPressed;

    if (isOwner && isDraft) {
      buttonLabel = l10n.activityPublishButton;
      buttonColor = AppColors.success;
      onPressed = isLoading ? null : onPublish;
    } else {
      buttonLabel = l10n.activityJoinActivity;
      buttonColor = AppColors.accent;
      onPressed = isLoading ? null : onJoin;
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            // Price column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL',
                  style: const TextStyle(
                    color: AppColors.textCaption,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.isFree ? l10n.freeLabel : activity.priceLabel,
                  style: TextStyle(
                    color: activity.isFree
                        ? AppColors.success
                        : AppColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // CTA button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
