import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/excursion_api.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';

class GuideReviewsScreen extends StatefulWidget {
  const GuideReviewsScreen({super.key});

  @override
  State<GuideReviewsScreen> createState() => _GuideReviewsScreenState();
}

class _GuideReviewsScreenState extends State<GuideReviewsScreen> {
  final ExcursionApi _excursionApi = ExcursionApi();

  Future<ExcursionReviewsPage>? _excursionReviewsFuture;
  Future<GuideReviewsPage>? _directGuideReviewsFuture;
  String _loadedGuideUserId = '';

  Future<ExcursionReviewsPage> _loadExcursionReviews(String guideUserId) {
    return _excursionApi.getGuideExcursionReviews(
      guideUserId: guideUserId,
      limit: 20,
      sort: 'latest',
    );
  }

  Future<GuideReviewsPage> _loadDirectGuideReviews(String guideUserId) {
    return _excursionApi.getGuideReviews(
      guideUserId: guideUserId,
      limit: 20,
      sort: 'latest',
    );
  }

  Future<void> _refresh(String guideUserId) async {
    final excursionFuture = _loadExcursionReviews(guideUserId);
    final directGuideFuture = _loadDirectGuideReviews(guideUserId);
    setState(() {
      _loadedGuideUserId = guideUserId;
      _excursionReviewsFuture = excursionFuture;
      _directGuideReviewsFuture = directGuideFuture;
    });
    await Future.wait([excursionFuture, directGuideFuture]);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/profile/guide-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final session = context.watch<SessionProvider>();
    final profile = session.profile;
    final guideUserId = profile?.userId.trim() ?? '';
    final canLoadReviews = guideUserId.isNotEmpty && profile?.isGuide == true;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final maxWidth = screenWidth >= 840
        ? 680.0
        : screenWidth >= 600
        ? 540.0
        : double.infinity;

    if (canLoadReviews && _loadedGuideUserId != guideUserId) {
      _loadedGuideUserId = guideUserId;
      _excursionReviewsFuture = _loadExcursionReviews(guideUserId);
      _directGuideReviewsFuture = _loadDirectGuideReviews(guideUserId);
    }

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: colors.background,
          body: DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.screenGradientColors,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      Padding(
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          0,
                        ),
                        child: AppListScreenHeader(
                          title: l10n.guideDashboardReviewsTitle,
                          notificationsTooltip:
                              l10n.profileNotificationsRowTitle,
                          onBackTap: _goBack,
                          onNotificationsTap: () =>
                              context.push('/notifications'),
                          horizontalPadding: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: AppEdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: DecoratedBox(
                          decoration: AppBoxDecoration(
                            color: colors.surface,
                            borderRadius: AppBorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: AppBoxDecoration(
                              color: colors.primary,
                              borderRadius: AppBorderRadius.circular(8),
                            ),
                            labelColor: colors.textPrimary,
                            unselectedLabelColor: colors.textMuted,
                            tabs: [
                              Tab(text: l10n.guideDashboardExcursionReviewsTab),
                              Tab(
                                text: l10n.guideDashboardDirectGuideReviewsTab,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            RefreshIndicator(
                              color: colors.primary,
                              backgroundColor: colors.surface,
                              onRefresh: !canLoadReviews
                                  ? () async {}
                                  : () => _refresh(guideUserId),
                              child: _GuideExcursionReviewsTab(
                                sessionIsLoading: session.isLoading,
                                canLoadReviews: canLoadReviews,
                                reviewsFuture: _excursionReviewsFuture,
                                horizontalPadding: horizontalPadding,
                                safeBottom: safeBottom,
                              ),
                            ),
                            RefreshIndicator(
                              color: colors.primary,
                              backgroundColor: colors.surface,
                              onRefresh: !canLoadReviews
                                  ? () async {}
                                  : () => _refresh(guideUserId),
                              child: _DirectGuideReviewsTab(
                                sessionIsLoading: session.isLoading,
                                canLoadReviews: canLoadReviews,
                                reviewsFuture: _directGuideReviewsFuture,
                                horizontalPadding: horizontalPadding,
                                safeBottom: safeBottom,
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
        ),
      ),
    );
  }
}

class _GuideExcursionReviewsTab extends StatelessWidget {
  const _GuideExcursionReviewsTab({
    required this.sessionIsLoading,
    required this.canLoadReviews,
    required this.reviewsFuture,
    required this.horizontalPadding,
    required this.safeBottom,
  });

  final bool sessionIsLoading;
  final bool canLoadReviews;
  final Future<ExcursionReviewsPage>? reviewsFuture;
  final double horizontalPadding;
  final double safeBottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        28 + safeBottom,
      ),
      children: [
        if (sessionIsLoading)
          const _GuideReviewsSkeletonList()
        else if (!canLoadReviews)
          _GuideReviewsInfoCard(
            icon: Icons.person_off_rounded,
            title: l10n.profileNotAvailable,
            message: l10n.profileGuideReviewsLoadFailedHint,
          )
        else
          FutureBuilder<ExcursionReviewsPage>(
            future: reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _GuideReviewsSkeletonList();
              }
              if (snapshot.hasError) {
                return _GuideReviewsInfoCard(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.profileGuideReviewsLoadFailed,
                  message: l10n.profileGuideReviewsLoadFailedHint,
                );
              }
              final reviews =
                  snapshot.data?.items ?? const <ExcursionReviewVm>[];
              if (reviews.isEmpty) {
                return _GuideReviewsInfoCard(
                  icon: Icons.rate_review_outlined,
                  title: l10n.profileGuideReviewsEmptyTitle,
                  message: l10n.profileGuideReviewsEmpty,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < reviews.length; i++) ...[
                    _GuideReviewCard(review: reviews[i]),
                    if (i != reviews.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _DirectGuideReviewsTab extends StatelessWidget {
  const _DirectGuideReviewsTab({
    required this.sessionIsLoading,
    required this.canLoadReviews,
    required this.reviewsFuture,
    required this.horizontalPadding,
    required this.safeBottom,
  });

  final bool sessionIsLoading;
  final bool canLoadReviews;
  final Future<GuideReviewsPage>? reviewsFuture;
  final double horizontalPadding;
  final double safeBottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        28 + safeBottom,
      ),
      children: [
        if (sessionIsLoading)
          const _GuideReviewsSkeletonList()
        else if (!canLoadReviews)
          _GuideReviewsInfoCard(
            icon: Icons.person_off_rounded,
            title: l10n.profileNotAvailable,
            message: l10n.profileGuideReviewsLoadFailedHint,
          )
        else
          FutureBuilder<GuideReviewsPage>(
            future: reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _GuideReviewsSkeletonList();
              }
              if (snapshot.hasError) {
                return _GuideReviewsInfoCard(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.profileGuideReviewsLoadFailed,
                  message: l10n.profileGuideReviewsLoadFailedHint,
                );
              }
              final reviews = snapshot.data?.items ?? const <GuideReviewVm>[];
              if (reviews.isEmpty) {
                return _GuideReviewsInfoCard(
                  icon: Icons.rate_review_outlined,
                  title: l10n.profileGuideReviewsEmptyTitle,
                  message: l10n.guideDashboardDirectGuideReviewsEmpty,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < reviews.length; i++) ...[
                    _DirectGuideReviewCard(review: reviews[i]),
                    if (i != reviews.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _GuideReviewCard extends StatelessWidget {
  const _GuideReviewCard({required this.review});

  final ExcursionReviewVm review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : review.author.resolvedDisplayName;
    final avatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final excursionTitle = review.landmarkName?.trim().isNotEmpty == true
        ? review.landmarkName!.trim()
        : review.sourceLabel.trim();
    final dateText = DateFormat.yMMMd(
      locale,
    ).format(review.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: const AppEdgeInsets.all(16),
      decoration: _guideReviewsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.secondaryContainer,
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: AppTextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      excursionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _GuideReviewRating(value: review.rating),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _GuideReviewDateChip(label: dateText),
        ],
      ),
    );
  }
}

class _DirectGuideReviewCard extends StatelessWidget {
  const _DirectGuideReviewCard({required this.review});

  final GuideReviewVm review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
        : review.author.resolvedDisplayName;
    final avatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final dateText = DateFormat.yMMMd(
      locale,
    ).format(review.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: const AppEdgeInsets.all(16),
      decoration: _guideReviewsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.secondaryContainer,
                backgroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: AppTextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _GuideReviewRating(value: review.rating),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _GuideReviewDateChip(label: dateText),
        ],
      ),
    );
  }
}

class _GuideReviewDateChip extends StatelessWidget {
  const _GuideReviewDateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: Color.alphaBlend(
          colors.secondaryContainer.withValues(alpha: isLight ? 0.44 : 0.22),
          colors.surface,
        ),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: AppTextStyle(
            color: colors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GuideReviewRating extends StatelessWidget {
  const _GuideReviewRating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: colors.primary, size: 15),
            const SizedBox(width: 3),
            Text(
              value.toStringAsFixed(1),
              style: AppTextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideReviewsInfoCard extends StatelessWidget {
  const _GuideReviewsInfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      width: double.infinity,
      padding: const AppEdgeInsets.all(18),
      decoration: _guideReviewsCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.secondary, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideReviewsSkeletonList extends StatelessWidget {
  const _GuideReviewsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _GuideReviewsSkeletonCard(),
        SizedBox(height: 14),
        _GuideReviewsSkeletonCard(),
        SizedBox(height: 14),
        _GuideReviewsSkeletonCard(),
      ],
    );
  }
}

class _GuideReviewsSkeletonCard extends StatelessWidget {
  const _GuideReviewsSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: _guideReviewsSkeletonMinHeight(context),
      ),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.surfaceHigh.withValues(alpha: 0.72),
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
      ),
    );
  }
}

BoxDecoration _guideReviewsCardDecoration(BuildContext context) {
  final colors = AppDesignSystem.colorsFor(context);
  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: AppBorderRadius.circular(8),
    border: Border.all(color: colors.border),
  );
}

double _guideReviewsSkeletonMinHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.32).clamp(108.0, 144.0).toDouble();
}

String _reviewInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
