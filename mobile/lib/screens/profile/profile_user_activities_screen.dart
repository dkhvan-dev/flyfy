import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

import '../../core/network/activity_api.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/activities/activity_taxonomy_resolver.dart';
import '../../features/activities/models/activity_category_vm.dart';
import '../../features/activities/models/activity_list_item_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import 'profile_style.dart';
import 'widgets/profile_activity_card.dart';

enum _ProfileUserActivitiesTab { hosted, visited }

enum _ProfileActivitySortField { date, price }

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _searchDebounce;

  _ProfileActivitiesPageState _hostedState =
      const _ProfileActivitiesPageState.loading();
  _ProfileActivitiesPageState _visitedState =
      const _ProfileActivitiesPageState.loading();
  List<ActivityCategoryVm> _categories = const <ActivityCategoryVm>[];
  _ProfileActivityFilters _filters = const _ProfileActivityFilters();
  String _searchQuery = '';
  _ProfileActivitySortField _sortField = _ProfileActivitySortField.date;
  bool _sortAscending = false;
  int _hostedRequestId = 0;
  int _visitedRequestId = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
      _loadHosted(page: 1);
      _loadVisited(page: 1);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  int get _activeFilterCount => _filters.activeCount;

  String get _sortQueryParam {
    switch (_sortField) {
      case _ProfileActivitySortField.date:
        return _sortAscending ? 'date_asc' : 'date_desc';
      case _ProfileActivitySortField.price:
        return _sortAscending ? 'price_asc' : 'price_desc';
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _activityApi.getActivityCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (_) {
      // The list still works without taxonomy labels; filters fall back to slugs.
    }
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted || _searchQuery == nextQuery) {
        return;
      }
      setState(() {
        _searchQuery = nextQuery;
      });
      _reloadFirstPages();
    });
  }

  void _handleSortTap(_ProfileActivitySortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = field == _ProfileActivitySortField.price;
      }
    });
    _reloadFirstPages();
  }

  void _reloadFirstPages() {
    _loadHosted(page: 1);
    _loadVisited(page: 1);
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final colors = AppDesignSystem.colorsFor(context);

    final result = await showAppModalBottomSheet<_ProfileActivityFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: colors.transparent,
      builder: (sheetContext) {
        return AppModalSheetFrame(
          onTapOutside: () => Navigator.of(context).maybePop(),
          safeAreaBottom: false,
          child: _ProfileActivityFiltersSheet(
            l10n: AppLocalizations.of(sheetContext)!,
            initialFilters: _filters,
            categoryOptions: _buildCategoryOptions(sheetContext),
            previewCountBuilder: _previewCountForFilters,
          ),
        );
      },
    );

    if (!mounted || result == null || result == _filters) {
      return;
    }

    setState(() {
      _filters = result;
    });
    _reloadFirstPages();
  }

  List<_ProfileActivityCategoryOption> _buildCategoryOptions(
    BuildContext context,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = _categories;
    if (categories.isNotEmpty) {
      return [
        for (final category in categories)
          if (category.slug.trim().isNotEmpty)
            _ProfileActivityCategoryOption(
              slug: category.slug.trim(),
              label: category.localizedName(languageCode),
            ),
      ]..sort((a, b) => a.label.compareTo(b.label));
    }

    final slugs = <String>{
      for (final item in [..._hostedState.items, ..._visitedState.items])
        normalizeActivityTaxonomySlug(item.categorySlug),
    }..remove('');

    return [
      for (final slug in slugs)
        _ProfileActivityCategoryOption(
          slug: slug,
          label: localizedActivityCategoryLabel(
            categories: const <ActivityCategoryVm>[],
            slug: slug,
            languageCode: languageCode,
          ),
        ),
    ]..sort((a, b) => a.label.compareTo(b.label));
  }

  int _previewCountForFilters(_ProfileActivityFilters filters) {
    final itemsById = <String, ActivityListItemVm>{};
    for (final item in [..._hostedState.items, ..._visitedState.items]) {
      itemsById[item.id] = item;
    }

    return itemsById.values
        .where((item) => _matchesProfileActivityFilters(item, filters))
        .length;
  }

  bool _matchesProfileActivityFilters(
    ActivityListItemVm item,
    _ProfileActivityFilters filters,
  ) {
    final categorySlug = normalizeActivityTaxonomySlug(item.categorySlug);
    final selectedCategory = normalizeActivityTaxonomySlug(
      filters.categorySlug,
    );
    if (selectedCategory.isNotEmpty && categorySlug != selectedCategory) {
      return false;
    }

    final selectedFormat = (filters.format ?? '').trim().toUpperCase();
    if (selectedFormat.isNotEmpty &&
        item.format.trim().toUpperCase() != selectedFormat) {
      return false;
    }

    final selectedPriceType = (filters.priceType ?? '').trim().toUpperCase();
    if (selectedPriceType.isNotEmpty &&
        item.priceType.trim().toUpperCase() != selectedPriceType) {
      return false;
    }

    return true;
  }

  Future<void> _loadHosted({required int page}) async {
    final normalizedPage = page < 1 ? 1 : page;
    final requestId = ++_hostedRequestId;
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
        query: _searchQuery,
        categorySlug: _filters.categorySlug,
        format: _filters.format,
        priceType: _filters.priceType,
        sort: _sortQueryParam,
      );
      if (!mounted || requestId != _hostedRequestId) return;
      setState(() {
        _hostedState = _ProfileActivitiesPageState.loaded(
          items: result.items,
          hasMore: result.hasMore,
          page: normalizedPage,
        );
      });
    } catch (_) {
      if (!mounted || requestId != _hostedRequestId) return;
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
    final requestId = ++_visitedRequestId;
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
        query: _searchQuery,
        categorySlug: _filters.categorySlug,
        format: _filters.format,
        priceType: _filters.priceType,
        sort: _sortQueryParam,
      );
      if (!mounted || requestId != _visitedRequestId) return;
      setState(() {
        _visitedState = _ProfileActivitiesPageState.loaded(
          items: result.items,
          hasMore: result.hasMore,
          page: normalizedPage,
        );
      });
    } catch (_) {
      if (!mounted || requestId != _visitedRequestId) return;
      setState(() {
        _visitedState = _visitedState.copyWith(
          isLoading: false,
          hasError: true,
          items: const <ActivityListItemVm>[],
        );
      });
    }
  }

  Future<void> _changePage(_ProfileUserActivitiesTab tab, int page) async {
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
    final colors = AppDesignSystem.colorsFor(context);
    final horizontalPadding = profileScaled(context, 20, min: 14, max: 20);
    final hasActiveQuery = _searchQuery.isNotEmpty || _filters.hasAnyValue;

    return DefaultTabController(
      length: 2,
      child: Theme(
        data: AppDesignSystem.themeFor(context),
        child: Scaffold(
          backgroundColor: colors.background,
          body: ProfileResponsiveScope(
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.screenGradientColors,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: AppEdgeInsets.fromLTRB(
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
                      padding: AppEdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: AppListSearchField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: l10n.activitiesSearchHint,
                        filterTooltip: l10n.activitiesFiltersTitle,
                        activeFilterCount: _activeFilterCount,
                        showClearButton: true,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        onFilterTap: _openFilters,
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 10, min: 8, max: 12),
                    ),
                    Padding(
                      padding: AppEdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppInlineSortRow<_ProfileActivitySortField>(
                            label: l10n.activitiesSortLabel,
                            options: [
                              AppInlineSortOption(
                                value: _ProfileActivitySortField.date,
                                label: l10n.activitiesSortDate,
                              ),
                              AppInlineSortOption(
                                value: _ProfileActivitySortField.price,
                                label: l10n.activitiesSortPrice,
                              ),
                            ],
                            selectedValue: _sortField,
                            isAscending: _sortAscending,
                            onSelected: _handleSortTap,
                            fontSize: profileScaled(
                              context,
                              12,
                              min: 11,
                              max: 12,
                            ),
                            iconSize: profileScaled(
                              context,
                              14,
                              min: 12,
                              max: 14,
                            ),
                            labelToOptionsGap: profileScaled(
                              context,
                              18,
                              min: 12,
                              max: 18,
                            ),
                            optionGap: profileScaled(
                              context,
                              22,
                              min: 16,
                              max: 22,
                            ),
                            iconGap: profileScaled(context, 5, min: 4, max: 5),
                            verticalPadding: profileScaled(
                              context,
                              8,
                              min: 6,
                              max: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: profileScaled(context, 8, min: 6, max: 10),
                    ),
                    Padding(
                      padding: AppEdgeInsets.symmetric(
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
                            emptyTitle: hasActiveQuery
                                ? l10n.activitiesFilteredEmptyTitle
                                : l10n.profileUserActivitiesHostedEmptyTitle,
                            emptySubtitle: hasActiveQuery
                                ? l10n.activitiesFilteredEmptySubtitle
                                : l10n.profileUserActivitiesHostedEmptySubtitle,
                            onRetry: () => _loadHosted(page: _hostedState.page),
                            onPageChanged: (page) => _changePage(
                              _ProfileUserActivitiesTab.hosted,
                              page,
                            ),
                            onOpenDetails: _openDetails,
                          ),
                          _ProfileActivitiesTabView(
                            state: _visitedState,
                            emptyTitle: hasActiveQuery
                                ? l10n.activitiesFilteredEmptyTitle
                                : l10n.profileUserActivitiesVisitedEmptyTitle,
                            emptySubtitle: hasActiveQuery
                                ? l10n.activitiesFilteredEmptySubtitle
                                : l10n.profileUserActivitiesVisitedEmptySubtitle,
                            onRetry: () =>
                                _loadVisited(page: _visitedState.page),
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

class _ProfileActivityFilters {
  const _ProfileActivityFilters({
    this.categorySlug,
    this.format,
    this.priceType,
  });

  final String? categorySlug;
  final String? format;
  final String? priceType;

  bool get hasAnyValue =>
      (categorySlug ?? '').trim().isNotEmpty ||
      (format ?? '').trim().isNotEmpty ||
      (priceType ?? '').trim().isNotEmpty;

  int get activeCount =>
      ((categorySlug ?? '').trim().isNotEmpty ? 1 : 0) +
      ((format ?? '').trim().isNotEmpty ? 1 : 0) +
      ((priceType ?? '').trim().isNotEmpty ? 1 : 0);

  _ProfileActivityFilters copyWith({
    Object? categorySlug = _unset,
    Object? format = _unset,
    Object? priceType = _unset,
  }) {
    return _ProfileActivityFilters(
      categorySlug: identical(categorySlug, _unset)
          ? this.categorySlug
          : categorySlug as String?,
      format: identical(format, _unset) ? this.format : format as String?,
      priceType: identical(priceType, _unset)
          ? this.priceType
          : priceType as String?,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) {
    return other is _ProfileActivityFilters &&
        other.categorySlug == categorySlug &&
        other.format == format &&
        other.priceType == priceType;
  }

  @override
  int get hashCode => Object.hash(categorySlug, format, priceType);
}

class _ProfileActivityCategoryOption {
  const _ProfileActivityCategoryOption({
    required this.slug,
    required this.label,
  });

  final String slug;
  final String label;
}

class _ProfileActivityFiltersSheet extends StatefulWidget {
  const _ProfileActivityFiltersSheet({
    required this.l10n,
    required this.initialFilters,
    required this.categoryOptions,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final _ProfileActivityFilters initialFilters;
  final List<_ProfileActivityCategoryOption> categoryOptions;
  final int Function(_ProfileActivityFilters filters) previewCountBuilder;

  @override
  State<_ProfileActivityFiltersSheet> createState() =>
      _ProfileActivityFiltersSheetState();
}

class _ProfileActivityFiltersSheetState
    extends State<_ProfileActivityFiltersSheet> {
  late _ProfileActivityFilters _draftFilters;

  @override
  void initState() {
    super.initState();
    _draftFilters = widget.initialFilters;
  }

  void _clearAll() {
    setState(() {
      _draftFilters = const _ProfileActivityFilters();
    });
  }

  void _apply() {
    Navigator.of(context).pop(_draftFilters);
  }

  void _toggleCategory(String slug) {
    setState(() {
      _draftFilters = _draftFilters.copyWith(
        categorySlug: _draftFilters.categorySlug == slug ? null : slug,
      );
    });
  }

  void _toggleFormat(String format) {
    setState(() {
      _draftFilters = _draftFilters.copyWith(
        format: _draftFilters.format == format ? null : format,
      );
    });
  }

  void _togglePriceType(String priceType) {
    setState(() {
      _draftFilters = _draftFilters.copyWith(
        priceType: _draftFilters.priceType == priceType ? null : priceType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final l10n = widget.l10n;
    final colors = AppDesignSystem.colorsFor(context);
    final previewCount = widget.previewCountBuilder(_draftFilters);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: AppBoxDecoration(
          color: colors.surface,
          borderRadius: const AppBorderRadius.vertical(
            top: AppRadiusValue.circular(28),
          ),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFilterSheetHeader(
              title: l10n.activitiesFiltersTitle,
              clearLabel: l10n.myActivitiesFilterClear,
              onClear: _clearAll,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: AppEdgeInsets.fromLTRB(
                  profileScaled(context, 18, min: 14, max: 20),
                  profileScaled(context, 18, min: 14, max: 20),
                  profileScaled(context, 18, min: 14, max: 20),
                  profileScaled(context, 18, min: 14, max: 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileFilterSection(
                      title: l10n.activitiesFilterCategory,
                      icon: Icons.dashboard_customize_outlined,
                      child: widget.categoryOptions.isEmpty
                          ? Text(
                              l10n.activitiesAllCategories,
                              style: AppTextStyle(
                                color: colors.textSecondary,
                                fontSize: profileScaled(
                                  context,
                                  14,
                                  min: 13,
                                  max: 15,
                                ),
                              ),
                            )
                          : _ProfileFilterChoiceWrap(
                              children: [
                                for (final option in widget.categoryOptions)
                                  _ProfileFilterChip(
                                    label: option.label,
                                    selected:
                                        _draftFilters.categorySlug ==
                                        option.slug,
                                    onTap: () => _toggleCategory(option.slug),
                                  ),
                              ],
                            ),
                    ),
                    const _ProfileFilterDivider(),
                    _ProfileFilterSection(
                      title: l10n.activityFormatLabel,
                      icon: Icons.hub_outlined,
                      child: _ProfileFilterChoiceWrap(
                        children: [
                          _ProfileFilterChip(
                            label: l10n.activityFormatOffline,
                            selected: _draftFilters.format == 'OFFLINE',
                            onTap: () => _toggleFormat('OFFLINE'),
                          ),
                          _ProfileFilterChip(
                            label: l10n.activityFormatOnline,
                            selected: _draftFilters.format == 'ONLINE',
                            onTap: () => _toggleFormat('ONLINE'),
                          ),
                          _ProfileFilterChip(
                            label: l10n.activityFormatHybrid,
                            selected: _draftFilters.format == 'HYBRID',
                            onTap: () => _toggleFormat('HYBRID'),
                          ),
                        ],
                      ),
                    ),
                    const _ProfileFilterDivider(),
                    _ProfileFilterSection(
                      title: l10n.activitiesFilterPricing,
                      icon: Icons.payments_outlined,
                      child: _ProfileFilterChoiceWrap(
                        children: [
                          _ProfileFilterChip(
                            label: l10n.createPriceFree,
                            selected: _draftFilters.priceType == 'FREE',
                            onTap: () => _togglePriceType('FREE'),
                          ),
                          _ProfileFilterChip(
                            label: l10n.createPricePaid,
                            selected: _draftFilters.priceType == 'PAID',
                            onTap: () => _togglePriceType('PAID'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppEdgeInsets.fromLTRB(
                profileScaled(context, 18, min: 14, max: 20),
                profileScaled(context, 10, min: 8, max: 12),
                profileScaled(context, 18, min: 14, max: 20),
                profileScaled(context, 18, min: 14, max: 20) + safeBottomInset,
              ),
              child: AppFilterApplyButton(
                label: l10n.activitiesShowResults(previewCount),
                onTap: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFilterSection extends StatelessWidget {
  const _ProfileFilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colors.primary,
              size: profileScaled(context, 18, min: 16, max: 20),
            ),
            SizedBox(width: profileScaled(context, 8, min: 6, max: 10)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: profileScaled(context, 15, min: 14, max: 16),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: profileScaled(context, 12, min: 10, max: 14)),
        child,
      ],
    );
  }
}

class _ProfileFilterChoiceWrap extends StatelessWidget {
  const _ProfileFilterChoiceWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: profileScaled(context, 8, min: 6, max: 10),
      runSpacing: profileScaled(context, 8, min: 6, max: 10),
      children: children,
    );
  }
}

class _ProfileFilterChip extends StatelessWidget {
  const _ProfileFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final maxWidth =
        (MediaQuery.sizeOf(context).width -
                profileScaled(context, 64, min: 48, max: 72))
            .clamp(160.0, 420.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ChoiceChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: colors.primarySoft,
        backgroundColor: colors.surfaceRaised,
        side: BorderSide(
          color: selected ? colors.borderPrimary : colors.borderSoft,
        ),
        labelStyle: AppTextStyle(
          color: selected ? colors.textPrimary : colors.textSecondary,
          fontSize: profileScaled(context, 13, min: 12, max: 14),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileFilterDivider extends StatelessWidget {
  const _ProfileFilterDivider();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Padding(
      padding: AppEdgeInsets.symmetric(
        vertical: profileScaled(context, 18, min: 14, max: 20),
      ),
      child: Divider(color: colors.borderSoft, height: 1),
    );
  }
}

class _ProfileActivitiesHeader extends StatelessWidget {
  const _ProfileActivitiesHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: colors.textPrimary,
        ),
        SizedBox(width: profileScaled(context, 8, min: 6, max: 10)),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: colors.textPrimary,
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
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: const AppEdgeInsets.all(4),
      decoration: AppBoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 18, min: 16, max: 18),
        ),
        border: Border.all(color: colors.borderSoft),
      ),
      child: TabBar(
        dividerColor: colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: AppBoxDecoration(
          color: colors.primary,
          borderRadius: AppBorderRadius.circular(
            profileScaled(context, 14, min: 12, max: 14),
          ),
          border: Border.all(color: colors.borderPrimary),
        ),
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: AppTextStyle(
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
    final colors = AppDesignSystem.colorsFor(context);
    final padding = profileScaled(context, 20, min: 14, max: 20);

    if (state.isLoading && state.items.isEmpty) {
      return ListView.separated(
        key: ValueKey('profile-activities-loading-${state.page}'),
        padding: AppEdgeInsets.fromLTRB(
          padding,
          profileScaled(context, 18, min: 14, max: 20),
          padding,
          profileScaled(context, 28, min: 20, max: 34),
        ),
        itemCount: 3,
        separatorBuilder: (_, _) =>
            SizedBox(height: profileScaled(context, 12, min: 10)),
        itemBuilder: (context, index) => Container(
          height: profileScaled(context, 220, min: 190, max: 240),
          decoration: _profileActivitiesCardDecoration(
            context,
            colors,
            highlighted: true,
          ),
        ),
      );
    }

    if (state.hasError) {
      return ListView(
        key: ValueKey('profile-activities-error-${state.page}'),
        padding: AppEdgeInsets.fromLTRB(
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
        padding: AppEdgeInsets.fromLTRB(
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
      padding: AppEdgeInsets.fromLTRB(
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
          InflapPaginationBar(
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
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 18, min: 14, max: 20)),
      decoration: _profileActivitiesCardDecoration(
        context,
        colors,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: profileScaled(context, 28, min: 24, max: 30),
            color: colors.primary,
          ),
          SizedBox(height: profileScaled(context, 14, min: 12, max: 16)),
          Text(
            title,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: profileScaled(context, 17, min: 15, max: 18),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
          Text(
            subtitle,
            style: AppTextStyle(
              color: colors.textSecondary,
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
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.borderPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _profileActivitiesCardDecoration(
  BuildContext context,
  AppColors colors, {
  bool highlighted = false,
  bool danger = false,
  double? radius,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = danger
      ? colors.danger
      : highlighted
      ? colors.borderPrimary
      : colors.border;

  return AppBoxDecoration(
    color: highlighted ? colors.surfaceRaised : colors.surface,
    borderRadius: AppBorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 24),
    ),
    border: Border.all(color: borderColor),
    boxShadow: isDark
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: highlighted ? 0.24 : 0.16),
              blurRadius: profileScaled(context, 18, min: 14, max: 22),
              offset: Offset(0, profileScaled(context, 8, min: 5, max: 10)),
            ),
          ]
        : const [],
  );
}
