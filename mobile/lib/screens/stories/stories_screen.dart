import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/post_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/stories/models/post_vm.dart';
import '../../features/stories/editor/presentation/post_create_preflight.dart';
import '../../features/stories/story_ui.dart';
import '../../features/trust/providers/trust_access_provider.dart';
import '../../features/trust/widgets/trust_restriction_notice.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_city_filter_section.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum _StorySortDirection { asc, desc }

enum _MyStoryStatusTab { drafts, pendingReview, published, archived }

extension _StorySortDirectionX on _StorySortDirection {
  String get querySuffix {
    switch (this) {
      case _StorySortDirection.asc:
        return 'asc';
      case _StorySortDirection.desc:
        return 'desc';
    }
  }
}

extension _MyStoryStatusTabX on _MyStoryStatusTab {
  String get postStatus {
    switch (this) {
      case _MyStoryStatusTab.drafts:
        return 'DRAFT';
      case _MyStoryStatusTab.pendingReview:
        return 'PUBLISHED';
      case _MyStoryStatusTab.published:
        return 'PUBLISHED';
      case _MyStoryStatusTab.archived:
        return 'ARCHIVED';
    }
  }

  List<String>? get moderationStatuses {
    switch (this) {
      case _MyStoryStatusTab.pendingReview:
        return const ['PENDING'];
      case _MyStoryStatusTab.published:
        return const ['NOT_REQUIRED', 'APPROVED'];
      case _MyStoryStatusTab.drafts:
      case _MyStoryStatusTab.archived:
        return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case _MyStoryStatusTab.drafts:
        return l10n.myStoriesDraftsTab;
      case _MyStoryStatusTab.pendingReview:
        return l10n.myStoriesPendingReviewTab;
      case _MyStoryStatusTab.published:
        return l10n.myStoriesPublishedTab;
      case _MyStoryStatusTab.archived:
        return l10n.myStoriesArchivedTab;
    }
  }
}

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({
    super.key,
    this.myOnly = false,
    this.authorId,
    this.postApi,
  });

  final bool myOnly;
  final String? authorId;
  final PostApi? postApi;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  static const int _pageSize = 8;

  late final PostApi _api;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _searchDebounce;
  List<PostVm> _stories = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalStories = 0;
  int _pageLimit = _pageSize;
  bool _hasNextPage = false;
  int _loadRequestId = 0;

  String _searchQuery = '';
  String? _selectedFormat;
  String? _selectedCategory;
  AppCountryFilterValue? _selectedCountry;
  AppCityFilterValue? _selectedCity;
  String _sort = 'latest';
  _StorySortDirection _sortDirection = _StorySortDirection.desc;
  _MyStoryStatusTab _selectedMyStatus = _MyStoryStatusTab.published;

  String get _sortQueryParam => '${_sort}_${_sortDirection.querySuffix}';
  String? get _myStatusFilter =>
      widget.myOnly ? _selectedMyStatus.postStatus : null;
  List<String>? get _myModerationStatusFilter =>
      widget.myOnly ? _selectedMyStatus.moderationStatuses : null;
  String? get _authorIdFilter {
    final value = (widget.authorId ?? '').trim();
    return value.isEmpty ? null : value;
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      (_selectedFormat ?? '').trim().isNotEmpty ||
      (_selectedCategory ?? '').trim().isNotEmpty ||
      _selectedCountry != null ||
      _selectedCity != null;

  int get _totalPages {
    final limit = _pageLimit <= 0 ? _pageSize : _pageLimit;
    if (_totalStories > 0) {
      final pages = (_totalStories / limit).ceil();
      return pages < 1 ? 1 : pages;
    }
    return _hasNextPage ? _currentPage + 1 : _currentPage;
  }

  @override
  void initState() {
    super.initState();
    _api = widget.postApi ?? PostApi();
    _searchController.addListener(_handleSearchChanged);
    _loadStories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      final next = _searchController.text.trim();
      if (_searchQuery == next) {
        return;
      }
      setState(() {
        _searchQuery = next;
      });
      _loadStories(showLoader: false, page: 1);
    });
  }

  String? get _selectedCountryCode => _selectedCountry?.countryCode;

  String? get _selectedCityId => _selectedCity?.cityId;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Future<void> _loadStories({bool showLoader = true, int? page}) async {
    final requestedPage = page ?? _currentPage;
    final normalizedPage = requestedPage < 1 ? 1 : requestedPage;
    final requestId = ++_loadRequestId;
    final requestSignature = _storyListSignature(normalizedPage);

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final storiesPage = widget.myOnly
          ? await _api.listMyPostsPage(
              search: _searchQuery,
              formats: _selectedFormat == null
                  ? null
                  : <String>[_selectedFormat!],
              categories: _selectedCategory == null
                  ? null
                  : <String>[_selectedCategory!],
              moderationStatuses: _myModerationStatusFilter,
              countryCode: _selectedCountryCode,
              cityId: _selectedCityId,
              sort: _sortQueryParam,
              status: _myStatusFilter,
              limit: _pageSize,
              offset: (normalizedPage - 1) * _pageSize,
            )
          : await _api.listPostsPage(
              search: _searchQuery,
              formats: _selectedFormat == null
                  ? null
                  : <String>[_selectedFormat!],
              categories: _selectedCategory == null
                  ? null
                  : <String>[_selectedCategory!],
              countryCode: _selectedCountryCode,
              cityId: _selectedCityId,
              sort: _sortQueryParam,
              limit: _pageSize,
              offset: (normalizedPage - 1) * _pageSize,
              authorId: widget.authorId,
            );

      if (!_isCurrentStoriesRequest(
        requestId,
        requestSignature,
        normalizedPage,
      )) {
        return;
      }
      setState(() {
        _stories = storiesPage.items;
        _totalStories = storiesPage.total;
        _pageLimit = storiesPage.limit <= 0 ? _pageSize : storiesPage.limit;
        _currentPage = storiesPage.items.isEmpty && normalizedPage > 1
            ? 1
            : normalizedPage;
        _hasNextPage = storiesPage.hasMore;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on DioException catch (e) {
      if (!_isCurrentStoriesRequest(
        requestId,
        requestSignature,
        normalizedPage,
      )) {
        return;
      }
      setState(() {
        _errorMessage = DioErrorMapper.toMessage(e);
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!_isCurrentStoriesRequest(
        requestId,
        requestSignature,
        normalizedPage,
      )) {
        return;
      }
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.storyLoadFailed;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String _storyListSignature(int page) {
    final format = _selectedFormat?.trim().toUpperCase() ?? '';
    final category = _selectedCategory?.trim().toUpperCase() ?? '';
    final countryCode = _selectedCountryCode?.trim().toUpperCase() ?? '';
    final cityId = _selectedCityId?.trim() ?? '';
    return [
      widget.myOnly ? 'mine' : 'public',
      _authorIdFilter ?? '',
      _myStatusFilter ?? '',
      _myModerationStatusFilter?.join(',') ?? '',
      _searchQuery.trim(),
      format,
      category,
      countryCode,
      cityId,
      _sortQueryParam,
      page.toString(),
    ].join('\u001F');
  }

  bool _isCurrentStoriesRequest(int requestId, String signature, int page) {
    if (!mounted || requestId != _loadRequestId) {
      return false;
    }
    return signature == _storyListSignature(page);
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    if (!mounted) return;

    final selected = await showAppModalBottomSheet<_StoryFiltersResult>(
      context: context,
      isDismissible: true,
      backgroundColor: AppDesignSystem.colorsFor(context).transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _StoryFiltersSheet(
          initialFormat: _selectedFormat,
          initialCategory: _selectedCategory,
          initialCountry: _selectedCountry,
          initialCity: _selectedCity,
          previewCount: _totalStories,
          previewCountLoader:
              ({
                required format,
                required category,
                required country,
                required city,
              }) => _loadStoriesPreviewCount(
                format: format,
                category: category,
                country: country,
                city: city,
              ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    final formatChanged = selected.format != _selectedFormat;
    final categoryChanged = selected.category != _selectedCategory;
    final countryChanged = !_sameCountryFilter(
      selected.country,
      _selectedCountry,
    );
    final cityChanged = !_sameCityFilter(selected.city, _selectedCity);
    if (!formatChanged && !categoryChanged && !countryChanged && !cityChanged) {
      return;
    }
    setState(() {
      _selectedFormat = selected.format;
      _selectedCategory = selected.category;
      _selectedCountry = selected.country;
      _selectedCity = selected.city;
    });
    await _loadStories(showLoader: false, page: 1);
  }

  Future<int> _loadStoriesPreviewCount({
    required String? format,
    required String? category,
    required AppCountryFilterValue? country,
    required AppCityFilterValue? city,
  }) async {
    final trimmedFormat = format?.trim() ?? '';
    final formats = trimmedFormat.isEmpty ? null : <String>[trimmedFormat];
    final trimmedCategory = category?.trim() ?? '';
    final categories = trimmedCategory.isEmpty
        ? null
        : <String>[trimmedCategory];
    final page = widget.myOnly
        ? await _api.listMyPostsPage(
            search: _searchQuery,
            formats: formats,
            categories: categories,
            moderationStatuses: _myModerationStatusFilter,
            countryCode: country?.countryCode,
            cityId: city?.cityId,
            sort: _sortQueryParam,
            status: _myStatusFilter,
            limit: 1,
          )
        : await _api.listPostsPage(
            search: _searchQuery,
            formats: formats,
            categories: categories,
            countryCode: country?.countryCode,
            cityId: city?.cityId,
            sort: _sortQueryParam,
            limit: 1,
            authorId: widget.authorId,
          );
    return page.total;
  }

  bool _sameCountryFilter(
    AppCountryFilterValue? left,
    AppCountryFilterValue? right,
  ) {
    return (left?.countryCode ?? '') == (right?.countryCode ?? '');
  }

  bool _sameCityFilter(AppCityFilterValue? left, AppCityFilterValue? right) {
    return (left?.cityId ?? '') == (right?.cityId ?? '') &&
        (left?.cityName ?? '') == (right?.cityName ?? '') &&
        (left?.countryCode ?? '') == (right?.countryCode ?? '');
  }

  Future<void> _refresh() => _loadStories(showLoader: false);

  Future<void> _resetFilters() async {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedFormat = null;
      _selectedCategory = null;
      _selectedCountry = null;
      _selectedCity = null;
    });
    await _loadStories(showLoader: false, page: 1);
  }

  void _handleMyStatusSelected(_MyStoryStatusTab status) {
    if (!widget.myOnly || _selectedMyStatus == status) {
      return;
    }
    setState(() {
      _selectedMyStatus = status;
    });
    _loadStories(showLoader: false, page: 1);
  }

  void _handleSortSelected(String value) {
    if (_sort == value) {
      setState(() {
        _sortDirection = _sortDirection == _StorySortDirection.asc
            ? _StorySortDirection.desc
            : _StorySortDirection.asc;
      });
    } else {
      setState(() {
        _sort = value;
        _sortDirection = _StorySortDirection.desc;
      });
    }
    _loadStories(showLoader: false, page: 1);
  }

  Future<void> _handlePageChanged(int page) async {
    if (page == _currentPage || _isLoading || _isRefreshing) {
      return;
    }

    FocusScope.of(context).unfocus();
    await _loadStories(showLoader: false, page: page);
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openCreateStory() async {
    const path = '/posts/create';
    final allowed = await ensurePostCreateAllowed(
      context,
      postApi: _api,
      loginFrom: path,
    );
    if (!allowed || !mounted) {
      return;
    }

    final result = await context.push<PostVm>(path);
    if (result != null && mounted) {
      if (widget.myOnly) {
        final nextStatus = _statusTabForPost(result);
        if (_selectedMyStatus != nextStatus) {
          setState(() {
            _selectedMyStatus = nextStatus;
          });
        }
      }
      _upsertStory(result);
      unawaited(_loadStories(showLoader: false, page: 1));
    }
  }

  _MyStoryStatusTab _statusTabForPost(PostVm story) {
    final status = story.status.trim().toUpperCase();
    if (status == 'DRAFT') {
      return _MyStoryStatusTab.drafts;
    }
    if (status == 'ARCHIVED') {
      return _MyStoryStatusTab.archived;
    }
    if (_isPendingModerationStatus(story.moderationStatus)) {
      return _MyStoryStatusTab.pendingReview;
    }
    return _MyStoryStatusTab.published;
  }

  void _upsertStory(PostVm story) {
    if (!_matchesActiveStatus(story) || !_matchesActiveFilters(story)) {
      return;
    }
    setState(() {
      final existed = _stories.any((item) => item.id == story.id);
      final next = _stories
          .where((item) => item.id != story.id)
          .toList(growable: true);
      next.insert(0, story);
      next.sort((a, b) => b.sortDate.compareTo(a.sortDate));
      _stories = next.take(_pageSize).toList(growable: false);
      if (!existed) {
        _totalStories += 1;
      }
      final limit = _pageLimit <= 0 ? _pageSize : _pageLimit;
      _hasNextPage = _totalStories > _currentPage * limit;
    });
  }

  bool _matchesActiveStatus(PostVm story) {
    final status = story.status.trim().toUpperCase();
    if (widget.myOnly) {
      if (status != _selectedMyStatus.postStatus) {
        return false;
      }
      final moderationStatuses = _selectedMyStatus.moderationStatuses;
      if (moderationStatuses == null || moderationStatuses.isEmpty) {
        return true;
      }
      final moderationStatus = story.moderationStatus.trim().toUpperCase();
      return moderationStatuses.contains(moderationStatus);
    }
    return status == 'PUBLISHED';
  }

  bool _isPendingModerationStatus(String value) {
    final status = value.trim().toUpperCase();
    return status == 'PENDING' ||
        status == 'PENDING_REVIEW' ||
        status == 'IN_REVIEW';
  }

  bool _matchesActiveFilters(PostVm story) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final haystack =
          '${story.title} ${story.excerpt} ${story.author.preferredName} ${story.placeName ?? ''}'
              .toLowerCase();
      if (!haystack.contains(query)) {
        return false;
      }
    }
    if ((_selectedCategory ?? '').trim().isNotEmpty &&
        story.category.trim().toUpperCase() !=
            _selectedCategory!.trim().toUpperCase()) {
      return false;
    }
    if ((_selectedFormat ?? '').trim().isNotEmpty &&
        story.format.trim().toUpperCase() !=
            _selectedFormat!.trim().toUpperCase()) {
      return false;
    }
    final selectedCountry = _selectedCountry;
    if (selectedCountry != null &&
        !selectedCountry.matches(countryCode: story.placeCountryCode)) {
      return false;
    }
    final selectedCity = _selectedCity;
    if (selectedCity != null &&
        !selectedCity.matches(
          cityId: story.placeCityId,
          cityName: _storyCityName(story.placeName),
          countryCode: story.placeCountryCode,
        )) {
      return false;
    }
    return true;
  }

  String? _storyCityName(String? placeName) {
    final value = (placeName ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return value.contains(',') ? value.split(',').first.trim() : value;
  }

  Future<void> _openStory(PostVm story) async {
    final refreshed = await context.push<bool>(
      '/posts/${Uri.encodeComponent(story.slug)}',
      extra: story,
    );
    if (refreshed == true && mounted) {
      await _loadStories(showLoader: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.state == AuthState.authenticated;
    final postCreationRestricted =
        isLoggedIn &&
        context.watch<TrustAccessProvider>().isRestricted(
          TrustCapability.createPost,
        );
    final totalPages = _totalPages;

    return Scaffold(
      backgroundColor: colors.backgroundDeep,
      bottomNavigationBar: CreateActionBottomNavigationBar(
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onCreateTap: postCreationRestricted ? null : _openCreateStory,
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: storyScreenBackground(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppListScreenHeader(
                title: widget.myOnly
                    ? l10n.myStoriesTitle
                    : _authorIdFilter == null
                    ? l10n.storiesDiscoverTitle
                    : l10n.profileUserStoriesTitle,
                notificationsTooltip: l10n.profileNotificationsRowTitle,
                onBackTap: _goBack,
                onNotificationsTap: () => context.push('/notifications'),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: colors.primary,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: AppEdgeInsets.fromLTRB(
                          adaptive.scale(18),
                          adaptive.scale(18),
                          adaptive.scale(18),
                          adaptive.scale(24),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            if (postCreationRestricted) ...[
                              const TrustRestrictionNotice(creation: true),
                              SizedBox(height: adaptive.scale(18)),
                            ],
                            _StoriesSearchBar(
                              controller: _searchController,
                              hint: l10n.storySearchHint,
                              compactHint: l10n.storySearchCompactHint,
                              filterTooltip: l10n.storyFiltersTitle,
                              activeFilterCount:
                                  (_selectedFormat == null ? 0 : 1) +
                                  (_selectedCategory == null ? 0 : 1) +
                                  (_selectedCountry == null ? 0 : 1) +
                                  (_selectedCity == null ? 0 : 1),
                              onFilterTap: _openFilters,
                            ),
                            SizedBox(height: adaptive.scale(18)),
                            _StoriesSortRow(
                              selectedSort: _sort,
                              sortDirection: _sortDirection,
                              onSortSelected: _handleSortSelected,
                            ),
                            if (widget.myOnly) ...[
                              SizedBox(height: adaptive.scale(18)),
                              _MyStoriesStatusTabs(
                                selected: _selectedMyStatus,
                                onSelected: _handleMyStatusSelected,
                              ),
                            ],
                            SizedBox(height: adaptive.scale(18)),
                            if (_isLoading)
                              const _StoriesLoadingState()
                            else if (_errorMessage != null)
                              _StoriesErrorState(
                                message: _errorMessage!,
                                retryLabel: l10n.retry,
                                onRetry: _loadStories,
                              )
                            else if (_stories.isEmpty)
                              _StoriesEmptyState(
                                title: _emptyTitle(l10n, isLoggedIn),
                                subtitle: _emptySubtitle(l10n, isLoggedIn),
                                actionLabel: _emptyActionLabel(
                                  l10n,
                                  isLoggedIn,
                                ),
                                onAction: _emptyAction(isLoggedIn),
                              )
                            else ...[
                              if (_isRefreshing)
                                Padding(
                                  padding: AppEdgeInsets.only(
                                    bottom: adaptive.scale(12),
                                  ),
                                  child: LinearProgressIndicator(
                                    minHeight: 2,
                                    color: colors.primary,
                                    backgroundColor: colors.transparent,
                                  ),
                                ),
                              for (final story in _stories) ...[
                                _StoryListCard(
                                  story: story,
                                  onTap: () => _openStory(story),
                                ),
                                SizedBox(height: adaptive.scale(30)),
                              ],
                              if (totalPages > 1) ...[
                                SizedBox(height: adaptive.scale(4)),
                                InflapPaginationBar(
                                  currentPage: _currentPage,
                                  totalPages: totalPages,
                                  onPageChanged: _handlePageChanged,
                                ),
                                SizedBox(height: adaptive.scale(18)),
                              ],
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyTitle(AppLocalizations l10n, bool isLoggedIn) {
    if (_hasActiveFilters) {
      return l10n.storyFilteredEmptyTitle;
    }
    if (widget.myOnly) {
      switch (_selectedMyStatus) {
        case _MyStoryStatusTab.drafts:
          return l10n.myStoriesDraftEmptyTitle;
        case _MyStoryStatusTab.pendingReview:
          return l10n.myStoriesPendingReviewEmptyTitle;
        case _MyStoryStatusTab.published:
          return l10n.myStoriesPublishedEmptyTitle;
        case _MyStoryStatusTab.archived:
          return l10n.myStoriesArchivedEmptyTitle;
      }
    }
    return l10n.storyEmptyTitle;
  }

  String _emptySubtitle(AppLocalizations l10n, bool isLoggedIn) {
    if (_hasActiveFilters) {
      return l10n.storyFilteredEmptySubtitle;
    }
    if (widget.myOnly) {
      switch (_selectedMyStatus) {
        case _MyStoryStatusTab.drafts:
          return l10n.myStoriesDraftEmptySubtitle;
        case _MyStoryStatusTab.pendingReview:
          return l10n.myStoriesPendingReviewEmptySubtitle;
        case _MyStoryStatusTab.published:
          return l10n.myStoriesPublishedEmptySubtitle;
        case _MyStoryStatusTab.archived:
          return l10n.myStoriesArchivedEmptySubtitle;
      }
    }
    return isLoggedIn
        ? l10n.storyEmptyAuthenticatedSubtitle
        : l10n.storyEmptySubtitle;
  }

  String? _emptyActionLabel(AppLocalizations l10n, bool isLoggedIn) {
    if (_hasActiveFilters) {
      return l10n.storyResetFiltersAction;
    }
    if (!widget.myOnly && isLoggedIn && _authorIdFilter == null) {
      return l10n.storyCreateFirst;
    }
    return null;
  }

  VoidCallback? _emptyAction(bool isLoggedIn) {
    if (_hasActiveFilters) {
      return () => unawaited(_resetFilters());
    }
    if (!widget.myOnly && isLoggedIn && _authorIdFilter == null) {
      return () => unawaited(_openCreateStory());
    }
    return null;
  }
}

class _MyStoriesStatusTabs extends StatelessWidget {
  const _MyStoriesStatusTabs({
    required this.selected,
    required this.onSelected,
  });

  final _MyStoryStatusTab selected;
  final ValueChanged<_MyStoryStatusTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final tab in _MyStoryStatusTab.values) ...[
            ChoiceChip(
              label: Text(tab.label(l10n)),
              selected: selected == tab,
              onSelected: (_) => onSelected(tab),
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceRaised,
              showCheckmark: false,
              side: BorderSide(
                color: selected == tab ? colors.primary : colors.transparent,
              ),
              labelStyle: AppTextStyle(
                color: selected == tab
                    ? colors.onPrimary
                    : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
              ),
            ),
            if (tab != _MyStoryStatusTab.values.last)
              SizedBox(width: adaptive.scale(8)),
          ],
        ],
      ),
    );
  }
}

class _StoriesSearchBar extends StatelessWidget {
  const _StoriesSearchBar({
    required this.controller,
    required this.hint,
    required this.compactHint,
    required this.filterTooltip,
    required this.activeFilterCount,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final String hint;
  final String compactHint;
  final String filterTooltip;
  final int activeFilterCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveHint = constraints.maxWidth < 390 ? compactHint : hint;
        return AppListSearchField(
          controller: controller,
          hintText: effectiveHint,
          filterTooltip: filterTooltip,
          activeFilterCount: activeFilterCount,
          showClearButton: true,
          onFilterTap: onFilterTap,
        );
      },
    );
  }
}

class _StoriesSortRow extends StatelessWidget {
  const _StoriesSortRow({
    required this.selectedSort,
    required this.sortDirection,
    required this.onSortSelected,
  });

  final String selectedSort;
  final _StorySortDirection sortDirection;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final items = <(String value, String label)>[
      ('latest', l10n.storySortDate),
      ('popular', l10n.storySortViews),
      ('discussed', l10n.storySortComments),
    ];
    final directionIcon = sortDirection == _StorySortDirection.asc
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Text(
            '${l10n.storySortLabel}:',
            style: AppTextStyle(
              color: colors.textMuted,
              fontSize: adaptive.scale(12),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(width: adaptive.scale(18)),
          for (final item in items) ...[
            Semantics(
              button: true,
              selected: selectedSort == item.$1,
              label: item.$2,
              onTap: () => onSortSelected(item.$1),
              child: Material(
                color: colors.transparent,
                child: InkWell(
                  onTap: () => onSortSelected(item.$1),
                  borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: adaptive.scale(40)),
                    child: Padding(
                      padding: AppEdgeInsets.symmetric(
                        horizontal: adaptive.scale(2),
                        vertical: adaptive.scale(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.$2,
                            style: AppTextStyle(
                              color: selectedSort == item.$1
                                  ? colors.primary
                                  : colors.textSecondary,
                              fontSize: adaptive.scale(12),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          if (selectedSort == item.$1) ...[
                            SizedBox(width: adaptive.scale(5, minFactor: 0.72)),
                            Icon(
                              directionIcon,
                              color: colors.primary,
                              size: adaptive.scale(14, minFactor: 0.82),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: adaptive.scale(22)),
          ],
        ],
      ),
    );
  }
}

class _StoryListCard extends StatelessWidget {
  const _StoryListCard({required this.story, required this.onTap});

  final PostVm story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final state = resolvePostEntryState(story);
    final publishedLabel = formatStoryDate(
      context,
      story.publishedAt ?? story.createdAt,
    );
    final imageHeight = adaptive.isVeryNarrow
        ? adaptive.scale(214, maxFactor: 1.0)
        : adaptive.scale(236, maxFactor: 1.04);
    final cardRadius = AppBorderRadius.circular(adaptive.radius(18));
    final imageRadius = AppBorderRadius.circular(adaptive.radius(34));

    return Semantics(
      button: true,
      container: true,
      enabled: !state.disablesEntry,
      label: story.title,
      onTap: state.disablesEntry ? null : onTap,
      child: Material(
        color: colors.transparent,
        borderRadius: cardRadius,
        child: InkWell(
          borderRadius: cardRadius,
          onTap: state.disablesEntry ? null : onTap,
          child: Ink(
            decoration: AppBoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: cardRadius,
              border: Border.all(color: colors.border),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: colors.black.withValues(alpha: 0.18),
                        blurRadius: adaptive.scale(18),
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Padding(
              padding: AppEdgeInsets.all(adaptive.scale(10, minFactor: 0.82)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: AppBoxDecoration(borderRadius: imageRadius),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        StoryCoverImage(url: story.coverUrl),
                        if (state.disablesEntry)
                          Positioned.fill(
                            child: ColoredBox(
                              color: colors.black.withValues(alpha: 0.38),
                            ),
                          ),
                        Positioned(
                          left: adaptive.scale(14),
                          top: adaptive.scale(14),
                          child: _LocationTag(
                            label: (story.placeName ?? '').trim().isEmpty
                                ? formatStoryCategory(l10n, story.category)
                                : story.placeName!.trim(),
                          ),
                        ),
                        Positioned(
                          right: adaptive.scale(14),
                          top: adaptive.scale(14),
                          child: _FormatTag(
                            label: formatStoryFormat(l10n, story.format),
                          ),
                        ),
                        Positioned(
                          left: adaptive.scale(14),
                          bottom: adaptive.scale(14),
                          child: StoryStateAffordance.fromPost(story),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: adaptive.scale(18)),
                  Text(
                    story.title,
                    maxLines: adaptive.isNarrow ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: adaptive.scale(adaptive.isNarrow ? 23 : 26),
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: adaptive.scale(10)),
                  Wrap(
                    spacing: adaptive.scale(8),
                    runSpacing: adaptive.scale(8),
                    children: [
                      _StoryMetaChip(
                        icon: Icons.auto_stories_outlined,
                        label: formatStoryFormat(l10n, story.format),
                      ),
                      _StoryMetaChip(
                        icon: Icons.category_outlined,
                        label: formatStoryCategory(l10n, story.category),
                      ),
                      if (publishedLabel.trim().isNotEmpty)
                        _StoryMetaChip(
                          icon: Icons.calendar_month_outlined,
                          label: publishedLabel,
                        ),
                    ],
                  ),
                  SizedBox(height: adaptive.scale(16)),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            StoryAvatar(
                              label: story.author.initials,
                              imageUrl: story.author.avatarUrl,
                              size: adaptive.scale(36),
                            ),
                            SizedBox(width: adaptive.scale(12)),
                            Expanded(
                              child: Text(
                                story.author.preferredName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.textSecondary,
                                  fontSize: adaptive.scale(15),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: adaptive.scale(14)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            color: colors.textMuted,
                            size: adaptive.scale(16),
                          ),
                          SizedBox(width: adaptive.scale(6)),
                          Text(
                            '${formatStoryCountCompact(story.stats.views)} ${l10n.storyViewsSuffix}',
                            style: AppTextStyle(
                              color: colors.textMuted,
                              fontSize: adaptive.scale(15),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _StoryMetaChip extends StatelessWidget {
  const _StoryMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      constraints: BoxConstraints(maxWidth: adaptive.scale(210)),
      padding: AppEdgeInsets.symmetric(
        horizontal: adaptive.scale(10),
        vertical: adaptive.scale(7),
      ),
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh.withValues(alpha: 0.72),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.secondary, size: adaptive.scale(14)),
          SizedBox(width: adaptive.scale(6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textMuted,
                fontSize: adaptive.scale(13),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatTag extends StatelessWidget {
  const _FormatTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      constraints: BoxConstraints(maxWidth: adaptive.scale(150)),
      padding: AppEdgeInsets.symmetric(
        horizontal: adaptive.scale(12),
        vertical: adaptive.scale(8),
      ),
      decoration: AppBoxDecoration(
        color: colors.secondary.withValues(alpha: 0.92),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle(
          color: colors.textPrimary,
          fontSize: adaptive.scale(11),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      padding: AppEdgeInsets.symmetric(
        horizontal: adaptive.scale(14),
        vertical: adaptive.scale(9),
      ),
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh.withValues(alpha: 0.78),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place_outlined,
            color: colors.secondary,
            size: adaptive.scale(13),
          ),
          SizedBox(width: adaptive.scale(7)),
          Text(
            label,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: adaptive.scale(12),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesLoadingState extends StatelessWidget {
  const _StoriesLoadingState();

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: AppEdgeInsets.only(bottom: adaptive.scale(26)),
          child: Container(
            height: adaptive.scale(320),
            decoration: AppBoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: AppBorderRadius.circular(adaptive.radius(28)),
              border: Border.all(color: colors.borderSoft),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoriesErrorState extends StatelessWidget {
  const _StoriesErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function({bool showLoader}) onRetry;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      padding: AppEdgeInsets.all(adaptive.scale(22)),
      decoration: AppBoxDecoration(
        borderRadius: AppBorderRadius.circular(adaptive.radius(26)),
        color: colors.surfaceRaised,
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: colors.primary,
            size: adaptive.scale(36),
          ),
          SizedBox(height: adaptive.scale(14)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: adaptive.scale(15),
              height: 1.45,
            ),
          ),
          SizedBox(height: adaptive.scale(18)),
          ElevatedButton(
            onPressed: () => onRetry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: AppEdgeInsets.symmetric(
                horizontal: adaptive.scale(20),
                vertical: adaptive.scale(14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
              ),
            ),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _StoriesEmptyState extends StatelessWidget {
  const _StoriesEmptyState({
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
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      padding: AppEdgeInsets.all(adaptive.scale(24)),
      decoration: AppBoxDecoration(
        borderRadius: AppBorderRadius.circular(adaptive.radius(28)),
        color: colors.surfaceRaised,
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: colors.primary,
            size: adaptive.scale(40),
          ),
          SizedBox(height: adaptive.scale(16)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: colors.textPrimary,
              fontSize: adaptive.scale(20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: adaptive.scale(10)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle(
              color: colors.textSecondary,
              fontSize: adaptive.scale(15),
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: adaptive.scale(18)),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: AppEdgeInsets.symmetric(
                  horizontal: adaptive.scale(20),
                  vertical: adaptive.scale(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryFiltersResult {
  const _StoryFiltersResult({
    required this.format,
    required this.category,
    required this.country,
    required this.city,
  });

  final String? format;
  final String? category;
  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
}

typedef _StoryFiltersPreviewCountLoader =
    Future<int> Function({
      required String? format,
      required String? category,
      required AppCountryFilterValue? country,
      required AppCityFilterValue? city,
    });

class _StoryFiltersSheet extends StatefulWidget {
  const _StoryFiltersSheet({
    required this.initialFormat,
    required this.initialCategory,
    required this.initialCountry,
    required this.initialCity,
    required this.previewCount,
    required this.previewCountLoader,
  });

  final String? initialFormat;
  final String? initialCategory;
  final AppCountryFilterValue? initialCountry;
  final AppCityFilterValue? initialCity;
  final int previewCount;
  final _StoryFiltersPreviewCountLoader previewCountLoader;

  @override
  State<_StoryFiltersSheet> createState() => _StoryFiltersSheetState();
}

class _StoryFiltersSheetState extends State<_StoryFiltersSheet> {
  static const _formatOptions = <String?>[
    null,
    'GUIDE',
    'PHOTO_ESSAY',
    'ARTICLE',
    'CULINARY',
  ];
  static const _categoryOptions = <String?>[
    null,
    'JOURNAL',
    'GUIDE',
    'PHOTO_ESSAY',
    'CULINARY',
  ];

  String? _selectedFormat;
  String? _selectedCategory;
  AppCountryFilterValue? _selectedCountry;
  AppCityFilterValue? _selectedCity;
  late int _previewCount;
  bool _isPreviewLoading = false;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _selectedCategory = widget.initialCategory;
    _selectedCountry = widget.initialCountry;
    _selectedCity = widget.initialCity;
    _previewCount = widget.previewCount;
    _loadPreviewCount();
  }

  void _selectFormat(String? format) {
    if (_selectedFormat == format) {
      return;
    }
    setState(() => _selectedFormat = format);
    _loadPreviewCount();
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) {
      return;
    }
    setState(() => _selectedCategory = category);
    _loadPreviewCount();
  }

  void _setCountry(AppCountryFilterValue? country) {
    if ((_selectedCountry?.countryCode ?? '') == (country?.countryCode ?? '')) {
      return;
    }
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
    });
    _loadPreviewCount();
  }

  void _setCity(AppCityFilterValue? city) {
    if ((_selectedCity?.cityId ?? '') == (city?.cityId ?? '') &&
        (_selectedCity?.cityName ?? '') == (city?.cityName ?? '') &&
        (_selectedCity?.countryCode ?? '') == (city?.countryCode ?? '')) {
      return;
    }
    setState(() => _selectedCity = city);
    _loadPreviewCount();
  }

  void _clearAll() {
    setState(() {
      _selectedFormat = null;
      _selectedCategory = null;
      _selectedCountry = null;
      _selectedCity = null;
    });
    _loadPreviewCount();
  }

  Future<void> _loadPreviewCount() async {
    final requestId = ++_previewRequestId;
    setState(() => _isPreviewLoading = true);
    try {
      final count = await widget.previewCountLoader(
        format: _selectedFormat,
        category: _selectedCategory,
        country: _selectedCountry,
        city: _selectedCity,
      );
      if (!mounted || requestId != _previewRequestId) {
        return;
      }
      setState(() {
        _previewCount = count;
        _isPreviewLoading = false;
      });
    } catch (_) {
      if (mounted && requestId == _previewRequestId) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  Widget _buildCountrySection(AppLocalizations l10n, StoryAdaptive adaptive) {
    return AppCountryFilterSection(
      title: l10n.storyFilterCountry,
      allCountriesLabel: l10n.storyFilterCountryAll,
      searchHint: l10n.storyFilterCountrySearchHint,
      noResultsText: l10n.storyFilterCountryNoResults,
      selectedCountry: _selectedCountry,
      onChanged: _setCountry,
      maxResultsHeight: MediaQuery.sizeOf(context).height * 0.28,
    );
  }

  Widget _buildCitySection(AppLocalizations l10n, StoryAdaptive adaptive) {
    return AppCityFilterSection(
      title: l10n.locationFilterCitySection,
      allCitiesLabel: l10n.locationFilterAllCities,
      searchHint: l10n.locationFilterCitySearchHint,
      noResultsText: l10n.locationFilterCityNoResults,
      selectedCity: _selectedCity,
      onChanged: _setCity,
      countryCode: _selectedCountry?.countryCode,
      maxResultsHeight: MediaQuery.sizeOf(context).height * 0.28,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _FilterSheet(
      title: l10n.storyFiltersTitle,
      clearLabel: l10n.myActivitiesFilterClear,
      applyLabel: l10n.storiesShowResults(_previewCount),
      onClear: _clearAll,
      onApply: () {
        Navigator.of(context).pop(
          _StoryFiltersResult(
            format: _selectedFormat,
            category: _selectedCategory,
            country: _selectedCountry,
            city: _selectedCity,
          ),
        );
      },
      isApplyLoading: _isPreviewLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActiveFiltersSummary(
            title: l10n.storyFiltersActiveSummary,
            formatLabel: _selectedFormat == null
                ? l10n.storyFilterAll
                : formatStoryFormat(l10n, _selectedFormat!),
            categoryLabel: _selectedCategory == null
                ? l10n.storyFilterAll
                : formatStoryCategory(l10n, _selectedCategory!),
            countryLabel: (_selectedCountry?.fallbackLabel ?? '').trim().isEmpty
                ? l10n.storyFilterCountryAll
                : _selectedCountry!.fallbackLabel,
            cityLabel: (_selectedCity?.fallbackLabel ?? '').trim().isEmpty
                ? l10n.locationFilterAllCities
                : _selectedCity!.fallbackLabel,
          ),
          SizedBox(height: adaptive.scale(18)),
          _buildCountrySection(l10n, adaptive),
          SizedBox(height: adaptive.scale(18)),
          _buildCitySection(l10n, adaptive),
          SizedBox(height: adaptive.scale(18)),
          _FilterSectionTitle(label: l10n.storyFilterFormat),
          SizedBox(height: adaptive.scale(10)),
          _FilterFormatGrid(
            options: _formatOptions,
            selectedFormat: _selectedFormat,
            labelFor: (option) => option == null
                ? l10n.storyFilterAll
                : formatStoryFormat(l10n, option),
            onSelected: _selectFormat,
          ),
          SizedBox(height: adaptive.scale(18)),
          _FilterSectionTitle(label: l10n.storyFilterCategory),
          SizedBox(height: adaptive.scale(10)),
          _FilterCategoryGrid(
            options: _categoryOptions,
            selectedCategory: _selectedCategory,
            labelFor: (option) => option == null
                ? l10n.storyFilterAll
                : formatStoryCategory(l10n, option),
            onSelected: _selectCategory,
          ),
        ],
      ),
    );
  }
}

class _ActiveFiltersSummary extends StatelessWidget {
  const _ActiveFiltersSummary({
    required this.title,
    required this.formatLabel,
    required this.categoryLabel,
    required this.countryLabel,
    required this.cityLabel,
  });

  final String title;
  final String formatLabel;
  final String categoryLabel;
  final String countryLabel;
  final String cityLabel;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: AppBorderRadius.circular(adaptive.radius(20)),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: AppEdgeInsets.all(adaptive.scale(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: colors.primary,
                  size: adaptive.scale(18),
                ),
                SizedBox(width: adaptive.scale(8)),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      fontSize: adaptive.scale(13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: adaptive.scale(10)),
            Wrap(
              spacing: adaptive.scale(8),
              runSpacing: adaptive.scale(8),
              children: [
                _ActiveFilterChip(
                  icon: Icons.auto_stories_outlined,
                  label: formatLabel,
                ),
                _ActiveFilterChip(
                  icon: Icons.category_outlined,
                  label: categoryLabel,
                ),
                _ActiveFilterChip(
                  icon: Icons.public_rounded,
                  label: countryLabel,
                ),
                _ActiveFilterChip(
                  icon: Icons.location_city_outlined,
                  label: cityLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      constraints: BoxConstraints(maxWidth: adaptive.scale(230)),
      padding: AppEdgeInsets.symmetric(
        horizontal: adaptive.scale(10),
        vertical: adaptive.scale(7),
      ),
      decoration: AppBoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: adaptive.scale(14), color: colors.secondary),
          SizedBox(width: adaptive.scale(6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: adaptive.scale(12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.clearLabel,
    required this.applyLabel,
    required this.onClear,
    required this.onApply,
    required this.child,
    this.isApplyLoading = false,
  });

  final String title;
  final String clearLabel;
  final String applyLabel;
  final VoidCallback onClear;
  final VoidCallback onApply;
  final Widget child;
  final bool isApplyLoading;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final horizontalPadding = adaptive.scale(18);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: colors.surface,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(adaptive.radius(28)),
            ),
            border: Border.all(color: colors.borderSoft),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterSheetHeader(
                  title: title,
                  clearLabel: clearLabel,
                  onClear: onClear,
                  height: adaptive.scale(46),
                  horizontalPadding: horizontalPadding,
                  titleFontSize: adaptive.scale(16),
                  clearFontSize: adaptive.scale(12),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppEdgeInsets.fromLTRB(
                      horizontalPadding,
                      adaptive.scale(14),
                      horizontalPadding,
                      0,
                    ),
                    child: child,
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: AppEdgeInsets.only(top: adaptive.scale(10)),
                  padding: AppEdgeInsets.fromLTRB(
                    horizontalPadding,
                    adaptive.scale(10),
                    horizontalPadding,
                    adaptive.scale(14) + safeBottomInset,
                  ),
                  decoration: AppBoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSoft)),
                    color: colors.surfaceRaised,
                  ),
                  child: AppFilterApplyButton(
                    label: applyLabel,
                    onTap: onApply,
                    minHeight: adaptive.scale(52),
                    fontSize: adaptive.scale(15),
                    isLoading: isApplyLoading,
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

class _FilterFormatGrid extends StatelessWidget {
  const _FilterFormatGrid({
    required this.options,
    required this.selectedFormat,
    required this.labelFor,
    required this.onSelected,
  });

  final List<String?> options;
  final String? selectedFormat;
  final String Function(String? option) labelFor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = adaptive.scale(8);
        final fullWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final useTwoColumns = fullWidth >= adaptive.scale(330);
        final itemWidth = useTwoColumns ? (fullWidth - spacing) / 2 : fullWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final option in options)
              SizedBox(
                width: itemWidth,
                child: _FilterOptionCard(
                  label: labelFor(option),
                  icon: _formatFilterIcon(option),
                  selected: selectedFormat == option,
                  onTap: () => onSelected(option),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterCategoryGrid extends StatelessWidget {
  const _FilterCategoryGrid({
    required this.options,
    required this.selectedCategory,
    required this.labelFor,
    required this.onSelected,
  });

  final List<String?> options;
  final String? selectedCategory;
  final String Function(String? option) labelFor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = adaptive.scale(8);
        final fullWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final useTwoColumns = fullWidth >= adaptive.scale(330);
        final itemWidth = useTwoColumns ? (fullWidth - spacing) / 2 : fullWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final option in options)
              SizedBox(
                width: itemWidth,
                child: _FilterOptionCard(
                  label: labelFor(option),
                  icon: _categoryFilterIcon(option),
                  selected: selectedCategory == option,
                  onTap: () => onSelected(option),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterOptionCard extends StatelessWidget {
  const _FilterOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(adaptive.radius(18)),
        child: Ink(
          padding: AppEdgeInsets.all(adaptive.scale(12)),
          decoration: AppBoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.14)
                : colors.surfaceRaised,
            borderRadius: AppBorderRadius.circular(adaptive.radius(18)),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.40)
                  : colors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: adaptive.scale(34),
                height: adaptive.scale(34),
                decoration: AppBoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.18)
                      : colors.surfaceHigh,
                  borderRadius: AppBorderRadius.circular(adaptive.radius(12)),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.primary : colors.textSecondary,
                  size: adaptive.scale(18),
                ),
              ),
              SizedBox(width: adaptive.scale(10)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontSize: adaptive.scale(14),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline,
                color: selected
                    ? colors.primary
                    : colors.textMuted.withValues(alpha: 0.78),
                size: adaptive.scale(19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryFilterIcon(String? category) {
  return switch ((category ?? '').trim()) {
    'GUIDE' => Icons.map_outlined,
    'PHOTO_ESSAY' => Icons.photo_library_outlined,
    'CULINARY' => Icons.restaurant_menu_rounded,
    'JOURNAL' || '' => Icons.auto_stories_outlined,
    _ => Icons.category_outlined,
  };
}

IconData _formatFilterIcon(String? format) {
  return switch ((format ?? '').trim()) {
    'GUIDE' => Icons.map_outlined,
    'PHOTO_ESSAY' => Icons.photo_library_outlined,
    'ARTICLE' => Icons.article_outlined,
    'CULINARY' => Icons.restaurant_menu_rounded,
    'STORY' || '' => Icons.auto_stories_outlined,
    _ => Icons.dashboard_customize_outlined,
  };
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyle(
        color: colors.textMuted,
        fontSize: adaptive.scale(12),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

enum StoriesNavItem { home, activities, stories, chats, profile }

class StoriesBottomNavBar extends StatelessWidget {
  const StoriesBottomNavBar({
    super.key,
    required this.active,
    required this.onItemTap,
  });

  final StoriesNavItem active;
  final ValueChanged<StoriesNavItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: AppEdgeInsets.fromLTRB(
          adaptive.scale(10),
          adaptive.scale(12),
          adaptive.scale(10),
          adaptive.scale(10),
        ),
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceRaised, colors.surface],
          ),
          border: Border(top: BorderSide(color: colors.borderSoft)),
        ),
        child: Row(
          children: [
            _StoriesNavButton(
              label: l10n.homeNavHome,
              icon: Icons.home_rounded,
              active: active == StoriesNavItem.home,
              onTap: () => onItemTap(StoriesNavItem.home),
            ),
            _StoriesNavButton(
              label: l10n.storiesActivitiesNavLabel,
              icon: Icons.explore_outlined,
              active: active == StoriesNavItem.activities,
              onTap: () => onItemTap(StoriesNavItem.activities),
            ),
            _StoriesNavButton(
              label: l10n.storiesNavLabel,
              icon: Icons.auto_stories_rounded,
              active: active == StoriesNavItem.stories,
              onTap: () => onItemTap(StoriesNavItem.stories),
            ),
            _StoriesNavButton(
              label: l10n.homeNavChats,
              icon: Icons.chat_bubble_outline_rounded,
              active: active == StoriesNavItem.chats,
              onTap: () => onItemTap(StoriesNavItem.chats),
            ),
            _StoriesNavButton(
              label: l10n.profileTitle,
              icon: Icons.person_outline_rounded,
              active: active == StoriesNavItem.profile,
              onTap: () => onItemTap(StoriesNavItem.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesNavButton extends StatelessWidget {
  const _StoriesNavButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final color = active ? colors.primary : colors.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        onTap: onTap,
        child: Material(
          color: colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: AppEdgeInsets.symmetric(vertical: adaptive.scale(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: adaptive.scale(22)),
                  SizedBox(height: adaptive.scale(5)),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      color: color,
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w600,
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
