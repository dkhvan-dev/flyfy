import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/reference_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../common/app_side_drawer.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, this.myOnly = false});

  final bool myOnly;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  static const int _pageSize = 8;

  final _api = StoryApi();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _searchDebounce;
  List<StoryVm> _stories = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalStories = 0;
  bool _hasNextPage = false;

  String _searchQuery = '';
  String? _selectedCategory;
  ReferenceCountry? _selectedPlace;
  String _sort = 'latest';

  @override
  void initState() {
    super.initState();
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
              place: _selectedPlace?.code,
              sort: _sort,
              limit: _pageSize,
              offset: (normalizedPage - 1) * _pageSize,
            )
          : await _api.listStoriesPage(
              search: _searchQuery,
              categories: _selectedCategory == null
                  ? null
                  : <String>[_selectedCategory!],
              place: _selectedPlace?.code,
              sort: _sort,
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

  Future<void> _showCategorySheet() async {
    final l10n = AppLocalizations.of(context)!;
    final options = <String?>[
      null,
      'JOURNAL',
      'GUIDE',
      'PHOTO_ESSAY',
      'CULINARY',
    ];

    final selected = await showModalBottomSheet<_StoryCategoryFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StoryCategoryFilterSheet(
          title: l10n.storyFilterCategory,
          options: options,
          initialCategory: _selectedCategory,
          previewCount: _totalStories,
          formatCategory: (option) => option == null
              ? l10n.storyFilterAll
              : formatStoryCategory(l10n, option),
          previewCountLoader: (category) => _loadStoriesPreviewCount(
            category: category,
            place: _selectedPlace,
          ),
        );
      },
    );

    if (!mounted ||
        selected == null ||
        selected.category == _selectedCategory) {
      return;
    }
    setState(() {
      _selectedCategory = selected.category;
    });
    await _loadStories(showLoader: false, page: 1);
  }

  Future<void> _showPlaceSheet() async {
    final l10n = AppLocalizations.of(context)!;

    final selected = await showModalBottomSheet<_StoryCountryFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CountrySearchSheet(
          title: l10n.storyFilterCountry,
          initialCountry: _selectedPlace,
          previewCount: _totalStories,
          previewCountLoader: (place) => _loadStoriesPreviewCount(
            category: _selectedCategory,
            place: place,
          ),
        );
      },
    );

    if (!mounted) return;
    if (selected == null) {
      return;
    }
    if (selected.country == null) {
      setState(() => _selectedPlace = null);
      await _loadStories(showLoader: false, page: 1);
      return;
    }
    if (selected.country!.code != (_selectedPlace?.code ?? '')) {
      setState(() => _selectedPlace = selected.country);
      await _loadStories(showLoader: false, page: 1);
    }
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
            place: place?.code,
            sort: _sort,
            limit: 1,
          )
        : await _api.listStoriesPage(
            search: _searchQuery,
            categories: categories,
            place: place?.code,
            sort: _sort,
            limit: 1,
          );
    return page.total;
  }

  Future<void> _refresh() => _loadStories(showLoader: false);

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
    if (_selectedPlace != null &&
        (story.placeCountryCode ?? '') != _selectedPlace!.code) {
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  adaptive.scale(18),
                  adaptive.scale(14),
                  adaptive.scale(18),
                  adaptive.scale(18),
                ),
                child: _StoriesTopBar(
                  title: widget.myOnly
                      ? l10n.myStoriesTitle
                      : l10n.storiesDiscoverTitle,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationsTap: () => context.push('/notifications'),
                ),
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
                          0,
                          adaptive.scale(18),
                          adaptive.scale(24),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            _StoriesSearchBar(
                              controller: _searchController,
                              hint: l10n.storySearchHint,
                            ),
                            SizedBox(height: adaptive.scale(16)),
                            _StoriesFilterRow(
                              categoryLabel: _selectedCategory == null
                                  ? l10n.storyFilterCategory
                                  : formatStoryCategory(
                                      l10n,
                                      _selectedCategory!,
                                    ),
                              placeLabel: _selectedPlace?.name ??
                                  l10n.storyFilterCountry,
                              placeActive: _selectedPlace != null,
                              onCategoryTap: _showCategorySheet,
                              onPlaceTap: _showPlaceSheet,
                            ),
                            SizedBox(height: adaptive.scale(18)),
                            _StoriesSortRow(
                              selectedSort: _sort,
                              onSortSelected: (value) {
                                if (_sort == value) {
                                  return;
                                }
                                setState(() {
                                  _sort = value;
                                });
                                _loadStories(showLoader: false, page: 1);
                              },
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

class _StoriesTopBar extends StatelessWidget {
  const _StoriesTopBar({
    required this.title,
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);

    return Row(
      children: [
        _StoriesCircleButton(
          icon: Icons.menu_rounded,
          onTap: onMenuTap,
          size: adaptive.scale(44),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(18),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _StoriesCircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotificationsTap,
          size: adaptive.scale(44),
        ),
      ],
    );
  }
}

class _StoriesSearchBar extends StatelessWidget {
  const _StoriesSearchBar({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

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
          if (controller.text.trim().isNotEmpty)
            IconButton(
              onPressed: controller.clear,
              icon: Icon(
                Icons.close_rounded,
                color: StoryPalette.textMuted,
                size: adaptive.scale(18),
              ),
            )
          else
            SizedBox(width: adaptive.scale(18)),
        ],
      ),
    );
  }
}

class _StoriesFilterRow extends StatelessWidget {
  const _StoriesFilterRow({
    required this.categoryLabel,
    required this.placeLabel,
    required this.onCategoryTap,
    required this.onPlaceTap,
    this.placeActive = false,
  });

  final String categoryLabel;
  final String placeLabel;
  final VoidCallback onCategoryTap;
  final VoidCallback onPlaceTap;
  final bool placeActive;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);

    return Wrap(
      spacing: adaptive.scale(12),
      runSpacing: adaptive.scale(12),
      children: [
        _StoriesFilterChip(
          label: categoryLabel,
          icon: Icons.category_outlined,
          active: true,
          onTap: onCategoryTap,
        ),
        _StoriesFilterChip(
          label: placeLabel,
          icon: Icons.public_rounded,
          active: placeActive,
          onTap: onPlaceTap,
        ),
      ],
    );
  }
}

class _StoriesSortRow extends StatelessWidget {
  const _StoriesSortRow({
    required this.selectedSort,
    required this.onSortSelected,
  });

  final String selectedSort;
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
              child: Text(
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

class _StoriesCircleButton extends StatelessWidget {
  const _StoriesCircleButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.10),
          ),
          child: Icon(icon, color: AppColors.accent, size: size * 0.48),
        ),
      ),
    );
  }
}

class _StoriesFilterChip extends StatelessWidget {
  const _StoriesFilterChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: adaptive.scale(18),
            vertical: adaptive.scale(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(adaptive.radius(999)),
            border: Border.all(
              color: active
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.25),
            ),
            color: active ? AppColors.accent : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : const Color(0xFFF4E8DA),
                size: adaptive.scale(15),
              ),
              SizedBox(width: adaptive.scale(8)),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFFF4E8DA),
                  fontSize: adaptive.scale(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: adaptive.scale(8)),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: active ? Colors.white : const Color(0xFFF4E8DA),
                size: adaptive.scale(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCategoryFilterResult {
  const _StoryCategoryFilterResult(this.category);

  final String? category;
}

class _StoryCountryFilterResult {
  const _StoryCountryFilterResult(this.country);

  final ReferenceCountry? country;
}

class _StoryCategoryFilterSheet extends StatefulWidget {
  const _StoryCategoryFilterSheet({
    required this.title,
    required this.options,
    required this.initialCategory,
    required this.previewCount,
    required this.formatCategory,
    required this.previewCountLoader,
  });

  final String title;
  final List<String?> options;
  final String? initialCategory;
  final int previewCount;
  final String Function(String? category) formatCategory;
  final Future<int> Function(String? category) previewCountLoader;

  @override
  State<_StoryCategoryFilterSheet> createState() =>
      _StoryCategoryFilterSheetState();
}

class _StoryCategoryFilterSheetState extends State<_StoryCategoryFilterSheet> {
  String? _selectedCategory;
  late int _previewCount;
  bool _isPreviewLoading = false;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _previewCount = widget.previewCount;
    _loadPreviewCount();
  }

  void _selectCategory(String? category) {
    if (_selectedCategory == category) {
      return;
    }
    setState(() => _selectedCategory = category);
    _loadPreviewCount();
  }

  Future<void> _loadPreviewCount() async {
    final requestId = ++_previewRequestId;
    setState(() => _isPreviewLoading = true);
    try {
      final count = await widget.previewCountLoader(_selectedCategory);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _FilterSheet(
      title: widget.title,
      clearLabel: l10n.myActivitiesFilterClear,
      applyLabel: l10n.storiesShowResults(_previewCount),
      onClear: () => _selectCategory(null),
      onApply: () {
        Navigator.of(
          context,
        ).pop(_StoryCategoryFilterResult(_selectedCategory));
      },
      isApplyLoading: _isPreviewLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in widget.options)
            _FilterOptionTile(
              label: widget.formatCategory(option),
              selected: _selectedCategory == option,
              onTap: () => _selectCategory(option),
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

class _CountrySearchSheet extends StatefulWidget {
  const _CountrySearchSheet({
    required this.title,
    required this.initialCountry,
    required this.previewCount,
    required this.previewCountLoader,
  });

  final String title;
  final ReferenceCountry? initialCountry;
  final int previewCount;
  final Future<int> Function(ReferenceCountry? country) previewCountLoader;

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final _searchController = TextEditingController();
  final _api = ReferenceApi();
  Timer? _debounce;
  List<ReferenceCountry> _results = const [];
  ReferenceCountry? _selectedCountry;
  late int _previewCount;
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  int _previewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _previewCount = widget.previewCount;
    _searchController.addListener(_onSearchChanged);
    _loadInitial();
    _loadPreviewCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await _api.listCountries(lang: lang);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _search(_searchController.text.trim());
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      await _loadInitial();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final results = await _api.searchCountries(query, lang: lang, limit: 30);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectCountry(ReferenceCountry? country) {
    if (_selectedCountry?.code == country?.code) {
      return;
    }
    setState(() => _selectedCountry = country);
    _loadPreviewCount();
  }

  Future<void> _loadPreviewCount() async {
    final requestId = ++_previewRequestId;
    setState(() => _isPreviewLoading = true);
    try {
      final count = await widget.previewCountLoader(_selectedCountry);
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

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _FilterSheet(
      title: widget.title,
      clearLabel: l10n.myActivitiesFilterClear,
      applyLabel: l10n.storiesShowResults(_previewCount),
      onClear: () => _selectCountry(null),
      onApply: () {
        Navigator.of(context).pop(_StoryCountryFilterResult(_selectedCountry));
      },
      isApplyLoading: _isPreviewLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: adaptive.scale(44),
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
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: StoryPalette.textSoft,
                      fontSize: adaptive.scale(14),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.storyCountryHint,
                      hintStyle: TextStyle(
                        color: StoryPalette.textMuted,
                        fontSize: adaptive.scale(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: adaptive.scale(14)),
              ],
            ),
          ),
          SizedBox(height: adaptive.scale(8)),
          _FilterOptionTile(
            label: l10n.storyFilterAll,
            selected: _selectedCountry == null,
            onTap: () => _selectCountry(null),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: adaptive.scale(18)),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final country = _results[index];
                  return _FilterOptionTile(
                    label: country.name,
                    selected: country.code == _selectedCountry?.code,
                    onTap: () => _selectCountry(country),
                  );
                },
              ),
            ),
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
