import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_design_system.dart';
import '../../../core/ui/app_list_search_field.dart';
import '../../../core/ui/error_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/search_api.dart';
import '../data/search_client.dart';
import '../domain/search_domain.dart';
import '../domain/search_result.dart';
import 'search_route_config.dart';
import 'search_view_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.config = const SearchRouteConfig(),
    this.client,
  });

  final SearchRouteConfig config;
  final SearchClient? client;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  SearchViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) return;

    _searchController.text = widget.config.query;
    _viewModel = SearchViewModel(
      client: widget.client ?? SearchApi(),
      scope: widget.config.scope,
      domains: widget.config.domains,
      locale: Localizations.localeOf(context).languageCode,
    );
    _viewModel!.updateQuery(_searchController.text);
    _searchController.addListener(_handleQueryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_searchController.text.trim().isEmpty) {
        _searchFocusNode.requestFocus();
        return;
      }
      unawaited(_viewModel!.submitSearch());
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    _viewModel?.updateQuery(_searchController.text);
  }

  void _submitSearch([String? value]) {
    if (value != null && value != _searchController.text) {
      _searchController.text = value;
    }
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _viewModel?.reset();
      _searchFocusNode.requestFocus();
      return;
    }
    unawaited(_viewModel?.submitSearch() ?? Future<void>.value());
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel?.reset();
    _searchFocusNode.requestFocus();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  void _openResult(SearchResult result, int position) {
    _viewModel?.trackResultClick(result, position);
    final deepLink = result.deepLink.trim();
    if (deepLink.isNotEmpty) {
      context.push(deepLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final viewModel = _viewModel;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: _goBack,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surfaceRaised,
                          foregroundColor: colors.textPrimary,
                          minimumSize: const Size(44, 44),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppListSearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: l10n.homeSearchHint,
                          showFilterButton: false,
                          showClearButton: true,
                          onClear: _clearSearch,
                          onSubmitted: _submitSearch,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel == null
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: viewModel,
                          builder: (context, _) => _SearchBody(
                            viewModel: viewModel,
                            onRetry: () async => _submitSearch(),
                            onResultTap: _openResult,
                          ),
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

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.viewModel,
    required this.onRetry,
    required this.onResultTap,
  });

  final SearchViewModel viewModel;
  final Future<void> Function() onRetry;
  final void Function(SearchResult result, int position) onResultTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (viewModel.state) {
      SearchState.idle => _SearchMessage(
        icon: Icons.travel_explore_rounded,
        title: l10n.searchIdleTitle,
        message: l10n.searchIdleMessage,
      ),
      SearchState.loading => const _SearchLoadingState(),
      SearchState.error => ErrorView(
        message: l10n.searchLoadFailed,
        onRetry: onRetry,
      ),
      SearchState.loaded => _SearchResultsView(
        viewModel: viewModel,
        onResultTap: onResultTap,
      ),
    };
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Center(child: CircularProgressIndicator(color: colors.primary));
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.viewModel,
    required this.onResultTap,
  });

  final SearchViewModel viewModel;
  final void Function(SearchResult result, int position) onResultTap;

  @override
  Widget build(BuildContext context) {
    final page = viewModel.page;
    final groups = _resultGroups(context, viewModel.scope, page);
    final hasResults = groups.any((group) => group.results.isNotEmpty);
    if (!hasResults) {
      final l10n = AppLocalizations.of(context)!;
      return _SearchMessage(
        icon: Icons.search_off_rounded,
        title: l10n.searchNoResultsTitle,
        message: l10n.searchNoResultsMessage,
      );
    }

    return ListView.separated(
      padding: const AppEdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return _SearchResultGroupView(
          key: ValueKey('${page?.query ?? ''}:${group.title}'),
          group: group,
          isLoadingMore: group.isTopResults
              ? viewModel.isLoadingMoreTopResults
              : viewModel.isLoadingMore(group.domain!),
          onLoadMore: group.isTopResults
              ? viewModel.loadMoreTopResults
              : () => viewModel.loadMoreGroup(group.domain!),
          onResultTap: onResultTap,
        );
      },
      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.xl),
      itemCount: groups.length,
    );
  }
}

class _SearchResultGroupView extends StatelessWidget {
  const _SearchResultGroupView({
    super.key,
    required this.group,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onResultTap,
  });

  final _SearchResultGroup group;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(SearchResult result, int position) onResultTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    if (group.results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            group.title,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < group.results.length; index++) ...[
          _SearchResultTile(
            result: group.results[index],
            position: index,
            showDomainLabel: group.showDomainLabel,
            onTap: onResultTap,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (group.hasMore)
          Padding(
            padding: const AppEdgeInsets.only(top: AppSpacing.xs),
            child: OutlinedButton.icon(
              onPressed: isLoadingMore ? null : onLoadMore,
              icon: isLoadingMore
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(l10n.searchLoadMore),
            ),
          ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.position,
    required this.showDomainLabel,
    required this.onTap,
  });

  final SearchResult result;
  final int position;
  final bool showDomainLabel;
  final void Function(SearchResult result, int position) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final domainLabel = showDomainLabel
        ? _domainLabel(l10n, result.domain)
        : null;
    final subtitle = result.subtitle?.trim();
    final deepLink = result.deepLink.trim();

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: deepLink.isEmpty ? null : () => onTap(result, position),
        borderRadius: AppBorderRadius.circular(8),
        child: Ink(
          padding: const AppEdgeInsets.all(AppSpacing.md),
          decoration: AppBoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(8),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppBoxDecoration(
                  color: colors.primary.withValues(alpha: 0.13),
                  borderRadius: AppBorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _domainIcon(result.domain),
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (domainLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        domainLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
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
    return Center(
      child: Padding(
        padding: const AppEdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.primary, size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_SearchResultGroup> _resultGroups(
  BuildContext context,
  SearchScope scope,
  SearchPage? page,
) {
  if (page == null) return const [];
  final l10n = AppLocalizations.of(context)!;
  final groups = <_SearchResultGroup>[];

  if (page.topResults.isNotEmpty) {
    groups.add(
      _SearchResultGroup(
        isTopResults: true,
        domain: null,
        title: scope == SearchScope.global
            ? l10n.searchTopResultsTitle
            : _scopeTitle(l10n, scope),
        page: SearchGroupPage(
          items: page.topResults,
          nextPageToken: page.nextPageToken,
          hasMore: page.nextPageToken != null,
        ),
      ),
    );
  }

  if (scope != SearchScope.global) {
    final scopedPage = _resultsForScope(page.groups, scope);
    if (page.topResults.isEmpty && scopedPage.items.isNotEmpty) {
      groups.add(
        _SearchResultGroup(
          isTopResults: false,
          domain: scope.matchingDomain,
          title: _scopeTitle(l10n, scope),
          page: scopedPage,
        ),
      );
    }
    return groups;
  }

  groups.addAll([
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.place,
      title: l10n.searchPlacesTitle,
      page: page.groups.places,
    ),
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.activity,
      title: l10n.searchActivitiesTitle,
      page: page.groups.activities,
    ),
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.excursion,
      title: l10n.searchExcursionsTitle,
      page: page.groups.excursions,
    ),
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.guide,
      title: l10n.searchGuidesTitle,
      page: page.groups.guides,
    ),
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.community,
      title: l10n.searchCommunitiesTitle,
      page: page.groups.communities,
    ),
    _SearchResultGroup(
      isTopResults: false,
      domain: SearchDomain.user,
      title: l10n.searchUsersTitle,
      page: page.groups.users,
    ),
  ]);

  return groups
      .where((group) => group.results.isNotEmpty)
      .toList(growable: false);
}

SearchGroupPage _resultsForScope(SearchGroups groups, SearchScope scope) {
  return switch (scope) {
    SearchScope.global => const SearchGroupPage(),
    SearchScope.activity => groups.activities,
    SearchScope.excursion => groups.excursions,
    SearchScope.place => groups.places,
    SearchScope.guide => groups.guides,
    SearchScope.community => groups.communities,
    SearchScope.user => groups.users,
  };
}

String _scopeTitle(AppLocalizations l10n, SearchScope scope) {
  return switch (scope) {
    SearchScope.global => l10n.searchTopResultsTitle,
    SearchScope.activity => l10n.searchActivitiesTitle,
    SearchScope.excursion => l10n.searchExcursionsTitle,
    SearchScope.place => l10n.searchPlacesTitle,
    SearchScope.guide => l10n.searchGuidesTitle,
    SearchScope.community => l10n.searchCommunitiesTitle,
    SearchScope.user => l10n.searchUsersTitle,
  };
}

String _domainLabel(AppLocalizations l10n, SearchDomain domain) {
  return switch (domain) {
    SearchDomain.activity => l10n.searchDomainActivity,
    SearchDomain.excursion => l10n.searchDomainExcursion,
    SearchDomain.place => l10n.searchDomainPlace,
    SearchDomain.guide => l10n.searchDomainGuide,
    SearchDomain.community => l10n.searchDomainCommunity,
    SearchDomain.user => l10n.searchDomainUser,
  };
}

IconData _domainIcon(SearchDomain domain) {
  return switch (domain) {
    SearchDomain.activity => Icons.local_activity_rounded,
    SearchDomain.excursion => Icons.tour_rounded,
    SearchDomain.place => Icons.place_rounded,
    SearchDomain.guide => Icons.badge_rounded,
    SearchDomain.community => Icons.groups_rounded,
    SearchDomain.user => Icons.person_rounded,
  };
}

class _SearchResultGroup {
  const _SearchResultGroup({
    required this.isTopResults,
    required this.domain,
    required this.title,
    required this.page,
  });

  final bool isTopResults;
  final SearchDomain? domain;
  final String title;
  final SearchGroupPage page;

  List<SearchResult> get results => page.items;
  bool get hasMore => page.hasMore;
  bool get showDomainLabel => isTopResults;
}
