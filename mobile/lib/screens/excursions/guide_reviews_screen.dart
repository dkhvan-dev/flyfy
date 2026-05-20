import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/excursion_api.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF160D07),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF211609), Color(0xFF160D07)],
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
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        0,
                      ),
                      child: AppListScreenHeader(
                        title: l10n.guideDashboardReviewsTitle,
                        notificationsTooltip: l10n.profileNotificationsRowTitle,
                        onBackTap: _goBack,
                        onNotificationsTap: () =>
                            context.push('/notifications'),
                        horizontalPadding: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1D13),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFFCBB8A3),
                          tabs: [
                            Tab(
                              text: l10n.guideDashboardExcursionReviewsTab,
                            ),
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
                            color: AppColors.accent,
                            backgroundColor: const Color(0xFF2A1D13),
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
                            color: AppColors.accent,
                            backgroundColor: const Color(0xFF2A1D13),
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
      padding: EdgeInsets.fromLTRB(
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
      padding: EdgeInsets.fromLTRB(
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.attractionTravelerFallback
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                backgroundImage:
                    avatarUrl == null ? null : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: const TextStyle(
                          color: AppColors.accent,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      excursionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD3BFA9),
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            dateText,
            style: const TextStyle(
              color: Color(0xFF9F8E7B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.attractionTravelerFallback
        : review.author.resolvedDisplayName;
    final avatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final dateText = DateFormat.yMMMd(
      locale,
    ).format(review.createdAt.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                backgroundImage:
                    avatarUrl == null ? null : NetworkImage(avatarUrl),
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(authorName),
                        style: const TextStyle(
                          color: AppColors.accent,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            dateText,
            style: const TextStyle(
              color: Color(0xFF9F8E7B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideReviewRating extends StatelessWidget {
  const _GuideReviewRating({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
            const SizedBox(width: 3),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.accent,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFD3BFA9),
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
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
    );
  }
}

String _reviewInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
