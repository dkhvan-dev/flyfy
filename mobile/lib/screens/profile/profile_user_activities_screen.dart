import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/activity_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import 'profile_style.dart';
import 'widgets/profile_activity_card.dart';

enum _ProfileUserActivitiesTab { hosted, visited }

class ProfileUserActivitiesScreen extends StatefulWidget {
  const ProfileUserActivitiesScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ProfileUserActivitiesScreen> createState() =>
      _ProfileUserActivitiesScreenState();
}

class _ProfileUserActivitiesScreenState
    extends State<ProfileUserActivitiesScreen> {
  static const int _pageSize = 10;

  final ActivityApi _activityApi = ActivityApi();

  _ProfileActivitiesPageState _hostedState =
      const _ProfileActivitiesPageState.loading();
  _ProfileActivitiesPageState _visitedState =
      const _ProfileActivitiesPageState.loading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHosted(page: 1);
      _loadVisited(page: 1);
    });
  }

  Future<void> _loadHosted({required int page}) async {
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _hostedState = _hostedState.copyWith(
        isLoading: true,
        page: normalizedPage,
        hasError: false,
      );
    });

    try {
      final result = await _activityApi.getUserHostedActivitiesPage(
        widget.userId,
        limit: _pageSize,
        offset: (normalizedPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _hostedState = _ProfileActivitiesPageState.loaded(
          items: result.items,
          hasMore: result.hasMore,
          page: normalizedPage,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hostedState = _hostedState.copyWith(
          isLoading: false,
          hasError: true,
          items: const <ActivityListItemVm>[],
        );
      });
    }
  }

  Future<void> _loadVisited({required int page}) async {
    final normalizedPage = page < 1 ? 1 : page;
    setState(() {
      _visitedState = _visitedState.copyWith(
        isLoading: true,
        page: normalizedPage,
        hasError: false,
      );
    });

    try {
      final result = await _activityApi.getUserJoinedActivitiesPage(
        widget.userId,
        limit: _pageSize,
        offset: (normalizedPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _visitedState = _ProfileActivitiesPageState.loaded(
          items: result.items,
          hasMore: result.hasMore,
          page: normalizedPage,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _visitedState = _visitedState.copyWith(
          isLoading: false,
          hasError: true,
          items: const <ActivityListItemVm>[],
        );
      });
    }
  }

  Future<void> _changePage(
    _ProfileUserActivitiesTab tab,
    int page,
  ) async {
    switch (tab) {
      case _ProfileUserActivitiesTab.hosted:
        await _loadHosted(page: page);
      case _ProfileUserActivitiesTab.visited:
        await _loadVisited(page: page);
    }
  }

  void _openDetails(ActivityListItemVm item) {
    context.push('/activities/${item.id}', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final horizontalPadding = profileScaled(context, 20, min: 14, max: 20);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ProfileResponsiveScope(
          child: ProfileGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      profileScaled(context, 14, min: 10, max: 18),
                      horizontalPadding,
                      profileScaled(context, 12, min: 10, max: 14),
                    ),
                    child: _ProfileActivitiesHeader(
                      title: l10n.profileUserActivitiesTitle,
                      onBack: () => context.pop(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: _ProfileActivitiesTabs(
                      hostedLabel: l10n.profileUserActivitiesHostedTab,
                      visitedLabel: l10n.profileUserActivitiesVisitedTab,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ProfileActivitiesTabView(
                          state: _hostedState,
                          emptyTitle:
                              l10n.profileUserActivitiesHostedEmptyTitle,
                          emptySubtitle:
                              l10n.profileUserActivitiesHostedEmptySubtitle,
                          onRetry: () => _loadHosted(page: _hostedState.page),
                          onPageChanged: (page) => _changePage(
                            _ProfileUserActivitiesTab.hosted,
                            page,
                          ),
                          onOpenDetails: _openDetails,
                        ),
                        _ProfileActivitiesTabView(
                          state: _visitedState,
                          emptyTitle:
                              l10n.profileUserActivitiesVisitedEmptyTitle,
                          emptySubtitle:
                              l10n.profileUserActivitiesVisitedEmptySubtitle,
                          onRetry: () => _loadVisited(page: _visitedState.page),
                          onPageChanged: (page) => _changePage(
                            _ProfileUserActivitiesTab.visited,
                            page,
                          ),
                          onOpenDetails: _openDetails,
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

class _ProfileActivitiesPageState {
  const _ProfileActivitiesPageState({
    required this.items,
    required this.hasMore,
    required this.page,
    required this.isLoading,
    required this.hasError,
  });

  const _ProfileActivitiesPageState.loading()
      : items = const <ActivityListItemVm>[],
        hasMore = false,
        page = 1,
        isLoading = true,
        hasError = false;

  factory _ProfileActivitiesPageState.loaded({
    required List<ActivityListItemVm> items,
    required bool hasMore,
    required int page,
  }) {
    return _ProfileActivitiesPageState(
      items: items,
      hasMore: hasMore,
      page: page,
      isLoading: false,
      hasError: false,
    );
  }

  final List<ActivityListItemVm> items;
  final bool hasMore;
  final int page;
  final bool isLoading;
  final bool hasError;

  _ProfileActivitiesPageState copyWith({
    List<ActivityListItemVm>? items,
    bool? hasMore,
    int? page,
    bool? isLoading,
    bool? hasError,
  }) {
    return _ProfileActivitiesPageState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class _ProfileActivitiesHeader extends StatelessWidget {
  const _ProfileActivitiesHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
        ),
        SizedBox(width: profileScaled(context, 8, min: 6, max: 10)),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: profileScaled(context, 24, min: 21, max: 26),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActivitiesTabs extends StatelessWidget {
  const _ProfileActivitiesTabs({
    required this.hostedLabel,
    required this.visitedLabel,
  });

  final String hostedLabel;
  final String visitedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: profileSurfaceMuted.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(
          profileScaled(context, 18, min: 16, max: 18),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(
            profileScaled(context, 14, min: 12, max: 14),
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: profileTextMuted,
        labelStyle: TextStyle(
          fontSize: profileScaled(context, 13, min: 12, max: 14),
          fontWeight: FontWeight.w900,
        ),
        tabs: [
          Tab(text: hostedLabel),
          Tab(text: visitedLabel),
        ],
      ),
    );
  }
}

class _ProfileActivitiesTabView extends StatelessWidget {
  const _ProfileActivitiesTabView({
    required this.state,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRetry,
    required this.onPageChanged,
    required this.onOpenDetails,
  });

  final _ProfileActivitiesPageState state;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ActivityListItemVm> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = profileScaled(context, 20, min: 14, max: 20);

    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        key: ValueKey('profile-activities-loading-${state.page}'),
        padding: EdgeInsets.fromLTRB(
          padding,
          profileScaled(context, 18, min: 14, max: 20),
          padding,
          profileScaled(context, 28, min: 20, max: 34),
        ),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(
          height: profileScaled(context, 12, min: 10),
        ),
        itemBuilder: (context, index) => Container(
          height: profileScaled(context, 220, min: 190, max: 240),
          decoration: profileCardDecoration(context, highlighted: true),
        ),
      );
    }

    if (state.hasError) {
      return ListView(
        key: ValueKey('profile-activities-error-${state.page}'),
        padding: EdgeInsets.fromLTRB(
          padding,
          profileScaled(context, 18, min: 14, max: 20),
          padding,
          profileScaled(context, 28, min: 20, max: 34),
        ),
        children: [
          _ProfileActivitiesMessageCard(
            title: l10n.profileActivitiesLoadFailed,
            subtitle: l10n.profileActivitiesLoadFailedHint,
            actionLabel: l10n.retry,
            onAction: onRetry,
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        key: ValueKey('profile-activities-empty-${state.page}'),
        padding: EdgeInsets.fromLTRB(
          padding,
          profileScaled(context, 18, min: 14, max: 20),
          padding,
          profileScaled(context, 28, min: 20, max: 34),
        ),
        children: [
          _ProfileActivitiesMessageCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ],
      );
    }

    final totalPages = state.hasMore ? state.page + 1 : state.page;
    final listKey = state.items.map((item) => item.id).join('|');

    return ListView(
      key: ValueKey('profile-activities-${state.page}-$listKey'),
      padding: EdgeInsets.fromLTRB(
        padding,
        profileScaled(context, 18, min: 14, max: 20),
        padding,
        profileScaled(context, 28, min: 20, max: 34),
      ),
      children: [
        for (var i = 0; i < state.items.length; i++) ...[
          ProfileActivityCard(
            item: state.items[i],
            onTap: () => onOpenDetails(state.items[i]),
          ),
          if (i != state.items.length - 1)
            SizedBox(height: profileScaled(context, 12, min: 10)),
        ],
        if (totalPages > 1) ...[
          SizedBox(height: profileScaled(context, 20, min: 16, max: 24)),
          FlyfyPaginationBar(
            currentPage: state.page,
            totalPages: totalPages,
            onPageChanged: state.isLoading ? null : onPageChanged,
          ),
        ],
      ],
    );
  }
}

class _ProfileActivitiesMessageCard extends StatelessWidget {
  const _ProfileActivitiesMessageCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final callback = onAction;

    return Container(
      padding: EdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: profileCardDecoration(context, highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: profileScaled(context, 28, min: 24, max: 30),
            color: AppColors.accent,
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: profileScaled(context, 17, min: 15, max: 18),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Text(
            subtitle,
            style: TextStyle(
              color: profileTextSoft,
              fontSize: profileScaled(context, 13, min: 12, max: 14),
              height: 1.45,
            ),
          ),
          if (label != null && callback != null) ...[
            SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
            OutlinedButton.icon(
              onPressed: callback,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.34),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
