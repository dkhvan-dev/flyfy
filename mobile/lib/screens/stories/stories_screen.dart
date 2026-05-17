import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/reference_api.dart';
import '../../core/network/story_api.dart';
import '../../core/reference/country_filter_utils.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../common/app_side_drawer.dart';

enum _StorySortDirection { asc, desc }

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

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, this.myOnly = false});

  final bool myOnly;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  static const int _pageSize = 8;

  final _api = StoryApi();
  final _referenceApi = ReferenceApi();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _searchDebounce;
  List<StoryVm> _stories = const [];
  List<ReferenceCountry> _countries = const [];
  Map<String, Set<String>> _countrySearchAliases = const {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isCountriesLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalStories = 0;
  bool _hasNextPage = false;
  Future<void>? _countriesLoadFuture;

  String _searchQuery = '';
  String? _selectedCategory;
  ReferenceCountry? _selectedPlace;
  String _sort = 'latest';
  _StorySortDirection _sortDirection = _StorySortDirection.desc;

  String get _sortQueryParam => '${_sort}_${_sortDirection.querySuffix}';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    unawaited(_loadCountries());
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

  String? get _selectedPlaceCode {
    return normalizeReferenceCountryCode(_selectedPlace?.code);
  }

  Future<void> _loadCountries() {
    if (_countries.isNotEmpty) return Future.value();
    final inFlight = _countriesLoadFuture;
    if (inFlight != null) return inFlight;

    final future = _loadCountriesInner();
    _countriesLoadFuture = future;
    return future.whenComplete(() => _countriesLoadFuture = null);
  }

  Future<void> _loadCountriesInner() async {
    if (!mounted) return;

    setState(() => _isCountriesLoading = true);
    final lang = Localizations.localeOf(context).languageCode;

    try {
      final countries = await _referenceApi.listCountries(lang: lang);
      final countrySearchAliases = await _loadCountrySearchAliases(
        countries,
        lang,
      );
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _countrySearchAliases = countrySearchAliases;
        _isCountriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _countries = const [];
        _countrySearchAliases = const {};
        _isCountriesLoading = false;
      });
    }
  }

  Future<Map<String, Set<String>>> _loadCountrySearchAliases(
    List<ReferenceCountry> countries,
    String currentLang,
  ) async {
    final languages = {'en', 'ru', 'kk'}..remove(currentLang);
    final localizedLists = await Future.wait(
      languages.map((lang) async {
        try {
          return await _referenceApi.listCountries(lang: lang);
        } catch (_) {
          return const <ReferenceCountry>[];
        }
      }),
    );

    return countrySearchAliasMap([
      ...countries,
      for (final localizedCountries in localizedLists) ...localizedCountries,
    ]);
  }

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
          ? await _api.listMyStoriesPage(
              search: _searchQuery,
              categories: _selectedCategory == null
                  ? null
                  : <String>[_selectedCategory!],
              place: _selectedPlaceCode,
              sort: _sortQueryParam,
              limit: _pageSize,
              offset: (normalizedPage - 1) * _pageSize,
            )
          : await _api.listStoriesPage(
              search: _searchQuery,
              categories: _selectedCategory == null
                  ? null
                  : <String>[_selectedCategory!],
              place: _selectedPlaceCode,
              sort: _sortQueryParam,
              limit: _pageSize,
              offset: (normalizedPage - 1) * _pageSize,
            );

      if (!mounted) {
        return;
      }
      setState(() {
        _stories = storiesPage.items;
        _totalStories = storiesPage.total;
        _currentPage = storiesPage.items.isEmpty && normalizedPage > 1
            ? 1
            : normalizedPage;
        _hasNextPage = storiesPage.hasMore;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = DioErrorMapper.toMessage(e);
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.storyLoadFailed;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    await _loadCountries();
    if (!mounted) return;

    final selected = await showModalBottomSheet<_StoryFiltersResult>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _StoryFiltersSheet(
          initialCategory: _selectedCategory,
          initialPlace: _selectedPlace,
          previewCount: _totalStories,
          countries: _countries,
          countrySearchAliases: _countrySearchAliases,
          isCountriesLoading: _isCountriesLoading,
          previewCountLoader: ({required category, required place}) =>
              _loadStoriesPreviewCount(
            category: category,
            place: place,
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    final categoryChanged = selected.category != _selectedCategory;
    final placeChanged = normalizeReferenceCountryCode(selected.place?.code) !=
        normalizeReferenceCountryCode(_selectedPlace?.code);
    if (!categoryChanged && !placeChanged) {
      return;
    }
    setState(() {
      _selectedCategory = selected.category;
      _selectedPlace = selected.place;
    });
    await _loadStories(showLoader: false, page: 1);
  }

  Future<int> _loadStoriesPreviewCount({
    required String? category,
    required ReferenceCountry? place,
  }) async {
    final trimmedCategory = category?.trim() ?? '';
    final categories =
        trimmedCategory.isEmpty ? null : <String>[trimmedCategory];
    final page = widget.myOnly
        ? await _api.listMyStoriesPage(
            search: _searchQuery,
            categories: categories,
            place: normalizeReferenceCountryCode(place?.code),
            sort: _sortQueryParam,
            limit: 1,
          )
        : await _api.listStoriesPage(
            search: _searchQuery,
            categories: categories,
            place: normalizeReferenceCountryCode(place?.code),
            sort: _sortQueryParam,
            limit: 1,
          );
    return page.total;
  }

  Future<void> _refresh() => _loadStories(showLoader: false);

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
    final authProvider = context.read<AuthProvider>();
    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/stories/create');
      return;
    }

    final result = await context.push<StoryVm>('/stories/create');
    if (result != null && mounted) {
      _upsertStory(result);
      unawaited(_loadStories(showLoader: false, page: 1));
    }
  }

  void _upsertStory(StoryVm story) {
    if (!story.isPublished || !_matchesActiveFilters(story)) {
      return;
    }
    setState(() {
      final next =
          _stories.where((item) => item.id != story.id).toList(growable: true);
      next.insert(0, story);
      next.sort((a, b) => b.sortDate.compareTo(a.sortDate));
      _stories = next;
    });
  }

  bool _matchesActiveFilters(StoryVm story) {
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
    final selectedCountryCode = normalizeReferenceCountryCode(
      _selectedPlace?.code,
    );
    if (selectedCountryCode != null &&
        normalizeReferenceCountryCode(story.placeCountryCode) !=
            selectedCountryCode) {
      return false;
    }
    return true;
  }

  Future<void> _openStory(StoryVm story) async {
    final refreshed = await context.push<bool>(
      '/stories/${Uri.encodeComponent(story.slug)}',
      extra: story,
    );
    if (refreshed == true && mounted) {
      await _loadStories(showLoader: false);
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1E11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            l10n.logoutDialogTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.logoutDialogMessage,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
              ),
              child: Text(l10n.logoutConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await authProvider.logout();
    await sessionProvider.clearSession();
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _closeDrawerIfNeeded() async {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null || !scaffoldState.isDrawerOpen) {
      return;
    }
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }

  Future<void> _runDrawerAction(Future<void> Function() action) async {
    await _closeDrawerIfNeeded();
    if (!mounted) {
      return;
    }
    await action();
  }

  Future<void> _showLanguageSheet() => showAppLanguageSheet(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionProvider>();
    final profile = session.profile;
    final location = resolveDrawerLocation(
      profile,
      Localizations.localeOf(context),
    );
    final isLoggedIn = auth.state == AuthState.authenticated;
    final totalPages = _hasNextPage ? _currentPage + 1 : _currentPage;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: StoryPalette.backgroundDeep,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 28,
      drawerScrimColor: Colors.black.withValues(alpha: 0.42),
      drawer: AppSideDrawer(
        l10n: l10n,
        isLoggedIn: isLoggedIn,
        showGuideBadge: profile?.isGuide ?? false,
        profile: profile,
        location: location,
        languageLabel: resolveDrawerLanguageLabel(
          Localizations.localeOf(context).languageCode,
        ),
        activeItem: AppDrawerActiveItem.none,
        onProfileTap: () =>
            _runDrawerAction(() async => context.push('/profile')),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() async => context.go('/')),
        onMyActivitiesTap: () =>
            _runDrawerAction(() async => context.push('/me/activities')),
        onMyStoriesTap: () =>
            _runDrawerAction(() async => context.push('/me/stories')),
        onActivitiesTap: () =>
            _runDrawerAction(() async => context.push('/activities')),
        onLoginTap: () =>
            _runDrawerAction(() async => context.push('/login?from=/stories')),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: CreateActionBottomNavigationBar(
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onCreateTap: _openCreateStory,
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: storyScreenBackground(),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppListScreenHeader(
                title: widget.myOnly
                    ? l10n.myStoriesTitle
                    : l10n.storiesDiscoverTitle,
                notificationsTooltip: l10n.profileNotificationsRowTitle,
                onBackTap: _goBack,
                onNotificationsTap: () => context.push('/notifications'),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          adaptive.scale(18),
                          adaptive.scale(18),
                          adaptive.scale(18),
                          adaptive.scale(24),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            _StoriesSearchBar(
                              controller: _searchController,
                              hint: l10n.storySearchHint,
                              filterTooltip: l10n.storyFiltersTitle,
                              hasActiveFilters: _selectedCategory != null ||
                                  _selectedPlace != null,
                              onFilterTap: _openFilters,
                            ),
                            SizedBox(height: adaptive.scale(18)),
                            _StoriesSortRow(
                              selectedSort: _sort,
                              sortDirection: _sortDirection,
                              onSortSelected: _handleSortSelected,
                            ),
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
                                title: l10n.storyEmptyTitle,
                                subtitle: l10n.storyEmptySubtitle,
                              )
                            else ...[
                              if (_isRefreshing)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: adaptive.scale(12),
                                  ),
                                  child: const LinearProgressIndicator(
                                    minHeight: 2,
                                    color: AppColors.accent,
                                    backgroundColor: Colors.transparent,
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
                                FlyfyPaginationBar(
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
}

class _StoriesSearchBar extends StatelessWidget {
  const _StoriesSearchBar({
    required this.controller,
    required this.hint,
    required this.filterTooltip,
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final String hint;
  final String filterTooltip;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final height = adaptive.scale(52);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2A180D),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: adaptive.scale(18)),
          Icon(
            Icons.search_rounded,
            color: AppColors.accent,
            size: adaptive.scale(20),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: StoryPalette.textSoft,
                fontSize: adaptive.scale(15),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: StoryPalette.textMuted,
                  fontSize: adaptive.scale(15),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.trim().isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: controller.clear,
                icon: Icon(
                  Icons.close_rounded,
                  color: StoryPalette.textMuted,
                  size: adaptive.scale(18),
                ),
              );
            },
          ),
          IconButton(
            tooltip: filterTooltip,
            onPressed: onFilterTap,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              foregroundColor: AppColors.accent,
              minimumSize: Size(
                adaptive.scale(40, minFactor: 0.9, maxFactor: 1.0),
                adaptive.scale(40, minFactor: 0.9, maxFactor: 1.0),
              ),
              shape: const CircleBorder(),
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: adaptive.scale(21),
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: adaptive.scale(7, minFactor: 0.9),
                      height: adaptive.scale(7, minFactor: 0.9),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2A180D),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: adaptive.scale(6)),
        ],
      ),
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
            style: TextStyle(
              color: StoryPalette.textMuted,
              fontSize: adaptive.scale(12),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(width: adaptive.scale(18)),
          for (final item in items) ...[
            GestureDetector(
              onTap: () => onSortSelected(item.$1),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: selectedSort == item.$1
                          ? AppColors.accent
                          : const Color(0xFFA98D74),
                      fontSize: adaptive.scale(12),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (selectedSort == item.$1) ...[
                    SizedBox(width: adaptive.scale(5, minFactor: 0.72)),
                    Icon(
                      directionIcon,
                      color: AppColors.accent,
                      size: adaptive.scale(14, minFactor: 0.82),
                    ),
                  ],
                ],
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

  final StoryVm story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final imageHeight = adaptive.isVeryNarrow
        ? adaptive.scale(214, maxFactor: 1.0)
        : adaptive.scale(236, maxFactor: 1.04);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(adaptive.radius(42)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: adaptive.scale(30),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StoryCoverImage(url: story.coverUrl),
                Positioned(
                  left: adaptive.scale(14),
                  top: adaptive.scale(14),
                  child: _LocationTag(
                    label: (story.placeName ?? '').trim().isEmpty
                        ? formatStoryCategory(
                            AppLocalizations.of(context)!,
                            story.category,
                          )
                        : story.placeName!.trim(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: adaptive.scale(18)),
          Text(
            story.title,
            maxLines: adaptive.isNarrow ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFFFFAF5),
              fontSize: adaptive.scale(adaptive.isNarrow ? 23 : 26),
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
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
                        style: TextStyle(
                          color: const Color(0xFFD7C5B2),
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
                    color: StoryPalette.textMuted,
                    size: adaptive.scale(16),
                  ),
                  SizedBox(width: adaptive.scale(6)),
                  Text(
                    '${formatStoryCountCompact(story.stats.views)} ${AppLocalizations.of(context)!.storyViewsSuffix}',
                    style: TextStyle(
                      color: StoryPalette.textMuted,
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
    );
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: adaptive.scale(14),
        vertical: adaptive.scale(9),
      ),
      decoration: BoxDecoration(
        color: const Color(0xC428211B),
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place_outlined,
            color: Colors.white,
            size: adaptive.scale(13),
          ),
          SizedBox(width: adaptive.scale(7)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
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
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: adaptive.scale(26)),
          child: Container(
            height: adaptive.scale(320),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(adaptive.radius(28)),
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
    return Container(
      padding: EdgeInsets.all(adaptive.scale(22)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(26)),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: AppColors.accent,
            size: adaptive.scale(36),
          ),
          SizedBox(height: adaptive.scale(14)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StoryPalette.textSoft,
              fontSize: adaptive.scale(15),
              height: 1.45,
            ),
          ),
          SizedBox(height: adaptive.scale(18)),
          ElevatedButton(
            onPressed: () => onRetry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: adaptive.scale(20),
                vertical: adaptive.scale(14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(adaptive.radius(999)),
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
  const _StoriesEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      padding: EdgeInsets.all(adaptive.scale(24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.03),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: AppColors.accent,
            size: adaptive.scale(40),
          ),
          SizedBox(height: adaptive.scale(16)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: adaptive.scale(10)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StoryPalette.textSoft,
              fontSize: adaptive.scale(15),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryFiltersResult {
  const _StoryFiltersResult({required this.category, required this.place});

  final String? category;
  final ReferenceCountry? place;
}

typedef _StoryFiltersPreviewCountLoader = Future<int> Function({
  required String? category,
  required ReferenceCountry? place,
});

class _StoryFiltersSheet extends StatefulWidget {
  const _StoryFiltersSheet({
    required this.initialCategory,
    required this.initialPlace,
    required this.previewCount,
    required this.countries,
    required this.countrySearchAliases,
    required this.isCountriesLoading,
    required this.previewCountLoader,
  });

  final String? initialCategory;
  final ReferenceCountry? initialPlace;
  final int previewCount;
  final List<ReferenceCountry> countries;
  final Map<String, Set<String>> countrySearchAliases;
  final bool isCountriesLoading;
  final _StoryFiltersPreviewCountLoader previewCountLoader;

  @override
  State<_StoryFiltersSheet> createState() => _StoryFiltersSheetState();
}

class _StoryFiltersSheetState extends State<_StoryFiltersSheet> {
  static const _categoryOptions = <String?>[
    null,
    'JOURNAL',
    'GUIDE',
    'PHOTO_ESSAY',
    'CULINARY',
  ];

  final _countrySearchController = TextEditingController();
  String _countrySearchQuery = '';
  String? _selectedCategory;
  ReferenceCountry? _selectedPlace;
  late int _previewCount;
  bool _isPreviewLoading = false;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedPlace = widget.initialPlace;
    _previewCount = widget.previewCount;
    _countrySearchController.addListener(_onCountrySearchChanged);
    _loadPreviewCount();
  }

  @override
  void dispose() {
    _countrySearchController
      ..removeListener(_onCountrySearchChanged)
      ..dispose();
    super.dispose();
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) {
      return;
    }
    setState(() => _selectedCategory = category);
    _loadPreviewCount();
  }

  void _selectPlace(ReferenceCountry? place) {
    if (normalizeReferenceCountryCode(_selectedPlace?.code) ==
        normalizeReferenceCountryCode(place?.code)) {
      return;
    }
    setState(() {
      _selectedPlace = place;
      _countrySearchController.clear();
      _countrySearchQuery = '';
    });
    _loadPreviewCount();
  }

  void _clearAll() {
    _countrySearchController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedPlace = null;
      _countrySearchQuery = '';
    });
    _loadPreviewCount();
  }

  Future<void> _loadPreviewCount() async {
    final requestId = ++_previewRequestId;
    setState(() => _isPreviewLoading = true);
    try {
      final count = await widget.previewCountLoader(
        category: _selectedCategory,
        place: _selectedPlace,
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

  void _onCountrySearchChanged() {
    final nextQuery = _countrySearchController.text.trim();
    if (nextQuery == _countrySearchQuery) return;

    setState(() => _countrySearchQuery = nextQuery);
  }

  ReferenceCountry? _selectedCountry() {
    final countryCode = normalizeReferenceCountryCode(_selectedPlace?.code);
    if (countryCode == null) return null;

    for (final country in widget.countries) {
      if (normalizeReferenceCountryCode(country.code) == countryCode) {
        return country;
      }
    }
    return _selectedPlace;
  }

  String _countryLabel(ReferenceCountry country) {
    final name = country.name.trim();
    if (name.isNotEmpty) return name;
    return normalizeReferenceCountryCode(country.code) ?? country.code.trim();
  }

  List<ReferenceCountry> _visibleCountries() {
    final query = normalizeCountrySearchText(_countrySearchQuery);
    if (query.isEmpty) return const [];

    final tokens = query
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);

    return widget.countries
        .where((country) {
          final haystack = countryFilterSearchHaystack(
            country,
            widget.countrySearchAliases,
          );
          return tokens.every(haystack.contains);
        })
        .take(24)
        .toList(growable: false);
  }

  Widget _buildCountrySection(AppLocalizations l10n, StoryAdaptive adaptive) {
    final selectedCountry = _selectedCountry();
    final visibleCountries = _visibleCountries();
    final countryCode = normalizeReferenceCountryCode(_selectedPlace?.code);
    final hasCountryQuery = _countrySearchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterSectionTitle(label: l10n.storyFilterCountry),
        SizedBox(height: adaptive.scale(12)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2118),
            borderRadius: BorderRadius.circular(adaptive.radius(18)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: adaptive.scale(14),
              vertical: adaptive.scale(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  color: AppColors.accent,
                  size: adaptive.scale(21),
                ),
                SizedBox(width: adaptive.scale(10)),
                Expanded(
                  child: Text(
                    selectedCountry == null
                        ? l10n.storyFilterCountryAll
                        : _countryLabel(selectedCountry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: adaptive.scale(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (countryCode != null)
                  IconButton(
                    tooltip: l10n.myActivitiesFilterClear,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _selectPlace(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: const Color(0xFFBDAA98),
                      size: adaptive.scale(20),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: adaptive.scale(12)),
        _FilterSearchField(
          controller: _countrySearchController,
          hintText: l10n.storyFilterCountrySearchHint,
          enabled: widget.countries.isNotEmpty,
        ),
        if (widget.isCountriesLoading && widget.countries.isEmpty) ...[
          SizedBox(height: adaptive.scale(12)),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            ),
          ),
        ] else if (hasCountryQuery) ...[
          SizedBox(height: adaptive.scale(12)),
          if (visibleCountries.isEmpty)
            Text(
              l10n.storyFilterCountryNoResults,
              style: TextStyle(
                color: const Color(0xFFBDAA98),
                fontSize: adaptive.scale(13),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.28,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: visibleCountries.length,
                separatorBuilder: (_, _) => SizedBox(height: adaptive.scale(8)),
                itemBuilder: (context, index) {
                  final country = visibleCountries[index];
                  final normalizedCode =
                      normalizeReferenceCountryCode(country.code) ??
                          country.code.trim().toUpperCase();
                  final selected = countryCode == normalizedCode;

                  return _StoryCountryResultTile(
                    label: _countryLabel(country),
                    code: normalizedCode,
                    selected: selected,
                    onTap: () => _selectPlace(country),
                  );
                },
              ),
            ),
        ],
      ],
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
            category: _selectedCategory,
            place: _selectedPlace,
          ),
        );
      },
      isApplyLoading: _isPreviewLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterSectionTitle(label: l10n.storyFilterCategory),
          SizedBox(height: adaptive.scale(8)),
          for (final option in _categoryOptions)
            _FilterOptionTile(
              label: option == null
                  ? l10n.storyFilterAll
                  : formatStoryCategory(l10n, option),
              selected: _selectedCategory == option,
              onTap: () => _selectCategory(option),
            ),
          SizedBox(height: adaptive.scale(18)),
          _buildCountrySection(l10n, adaptive),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final horizontalPadding = adaptive.scale(18);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B1808), Color(0xFF201208)],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(adaptive.radius(28)),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: SafeArea(
            top: false,
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
                    padding: EdgeInsets.fromLTRB(
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
                  margin: EdgeInsets.only(top: adaptive.scale(10)),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    adaptive.scale(10),
                    horizontalPadding,
                    adaptive.scale(14) + safeBottomInset,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.09),
                      ),
                    ),
                    color: Colors.black.withValues(alpha: 0.06),
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

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(18)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: adaptive.scale(14),
            horizontal: adaptive.scale(2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.accent : StoryPalette.textSoft,
                    fontSize: adaptive.scale(15),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.24),
                size: adaptive.scale(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCountryResultTile extends StatelessWidget {
  const _StoryCountryResultTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(14)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : const Color(0xFF2C2118),
            borderRadius: BorderRadius.circular(adaptive.radius(14)),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: adaptive.scale(13),
              vertical: adaptive.scale(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: adaptive.scale(14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: adaptive.scale(10)),
                Text(
                  code,
                  style: TextStyle(
                    color: const Color(0xFFBDAA98),
                    fontSize: adaptive.scale(12),
                    fontWeight: FontWeight.w800,
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

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: StoryPalette.textMuted,
        fontSize: adaptive.scale(12),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FilterSearchField extends StatelessWidget {
  const _FilterSearchField({
    required this.controller,
    required this.hintText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: adaptive.scale(44)),
      decoration: BoxDecoration(
        color: const Color(0xFF2A180D),
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
      ),
      child: Row(
        children: [
          SizedBox(width: adaptive.scale(14)),
          Icon(
            Icons.search_rounded,
            color: AppColors.accent,
            size: adaptive.scale(18),
          ),
          SizedBox(width: adaptive.scale(8)),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              cursorColor: AppColors.accent,
              style: TextStyle(
                color: StoryPalette.textSoft,
                fontSize: adaptive.scale(14),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: StoryPalette.textMuted,
                  fontSize: adaptive.scale(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: adaptive.scale(14)),
        ],
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

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          adaptive.scale(10),
          adaptive.scale(12),
          adaptive.scale(10),
          adaptive.scale(10),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF228190D), Color(0xF822150C)],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
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
    final color = active ? AppColors.accent : const Color(0xFFC7B19B);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: adaptive.scale(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: adaptive.scale(22)),
                SizedBox(height: adaptive.scale(5)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
    );
  }
}
