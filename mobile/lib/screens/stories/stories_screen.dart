import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../common/app_side_drawer.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final _api = StoryApi();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<StoryVm> _stories = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPlace;
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
      _loadStories(showLoader: false);
    });
  }

  Future<void> _loadStories({bool showLoader = true}) async {
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
      final stories = await _api.listStories(
        search: _searchQuery,
        categories: _selectedCategory == null
            ? null
            : <String>[_selectedCategory!],
        place: _selectedPlace,
        sort: _sort,
        limit: 40,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _stories = stories;
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

    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          title: l10n.storyFilterCategory,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                _FilterOptionTile(
                  label: option == null
                      ? l10n.storyFilterAll
                      : formatStoryCategory(l10n, option),
                  selected: _selectedCategory == option,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == _selectedCategory) {
      return;
    }
    setState(() {
      _selectedCategory = selected;
    });
    await _loadStories(showLoader: false);
  }

  Future<void> _showPlaceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final places =
        _stories
            .map((story) => (story.placeName ?? '').trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterSheet(
          title: l10n.storyFilterCountry,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterOptionTile(
                label: l10n.storyFilterAll,
                selected: _selectedPlace == null,
                onTap: () => Navigator.of(context).pop(null),
              ),
              for (final place in places)
                _FilterOptionTile(
                  label: place,
                  selected: _selectedPlace == place,
                  onTap: () => Navigator.of(context).pop(place),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == _selectedPlace) {
      return;
    }
    setState(() {
      _selectedPlace = selected;
    });
    await _loadStories(showLoader: false);
  }

  Future<void> _refresh() => _loadStories(showLoader: false);

  Future<void> _openCreateStory() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/stories/create');
      return;
    }

    final result = await context.push<bool>('/stories/create');
    if (result == true && mounted) {
      await _loadStories(showLoader: false);
    }
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
        activeItem: AppDrawerActiveItem.home,
        onProfileTap: () =>
            _runDrawerAction(() async => context.push('/profile')),
        onLanguageTap: () => _runDrawerAction(_showLanguageSheet),
        onHomeTap: () => _runDrawerAction(() async => context.go('/')),
        onMyActivitiesTap: () =>
            _runDrawerAction(() async => context.push('/me/activities')),
        onActivitiesTap: () =>
            _runDrawerAction(() async => context.push('/activities')),
        onLoginTap: () =>
            _runDrawerAction(() async => context.push('/login?from=/stories')),
        onLogoutTap: () => _runDrawerAction(_confirmLogout),
      ),
      bottomNavigationBar: StoriesBottomNavBar(
        active: StoriesNavItem.stories,
        onItemTap: (item) {
          switch (item) {
            case StoriesNavItem.home:
              context.go('/');
            case StoriesNavItem.activities:
              context.push('/activities');
            case StoriesNavItem.stories:
              break;
            case StoriesNavItem.chats:
              context.push('/chats');
            case StoriesNavItem.profile:
              context.push('/profile');
          }
        },
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
                  title: l10n.storiesDiscoverTitle,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationsTap: () => context.push('/notifications'),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _refresh,
                  child: CustomScrollView(
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
                              placeLabel:
                                  _selectedPlace ?? l10n.storyFilterCountry,
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
                                _loadStories(showLoader: false);
                              },
                            ),
                            SizedBox(height: adaptive.scale(18)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _ShareYourStoryButton(
                                label: l10n.storyCreateCta,
                                onTap: _openCreateStory,
                              ),
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
                                actionLabel: l10n.storyCreateFirst,
                                onActionTap: _openCreateStory,
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
            color: StoryPalette.textMuted,
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
  });

  final String categoryLabel;
  final String placeLabel;
  final VoidCallback onCategoryTap;
  final VoidCallback onPlaceTap;

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
          active: false,
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

class _ShareYourStoryButton extends StatelessWidget {
  const _ShareYourStoryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: Size(adaptive.scale(180), adaptive.scale(54)),
        padding: EdgeInsets.symmetric(
          horizontal: adaptive.scale(20),
          vertical: adaptive.scale(14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(adaptive.radius(999)),
        ),
        elevation: 0,
      ),
      icon: Icon(Icons.add_rounded, size: adaptive.scale(18)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: adaptive.scale(15),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
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
  const _StoriesEmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionTap;

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
          SizedBox(height: adaptive.scale(18)),
          ElevatedButton(
            onPressed: onActionTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, adaptive.scale(54)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(adaptive.radius(999)),
              ),
            ),
            child: Text(actionLabel),
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

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: adaptive.scale(12),
          right: adaptive.scale(12),
          bottom: adaptive.scale(12),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF211207),
            borderRadius: BorderRadius.circular(adaptive.radius(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              adaptive.scale(18),
              adaptive.scale(18),
              adaptive.scale(18),
              adaptive.scale(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: adaptive.scale(46),
                    height: adaptive.scale(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(adaptive.radius(999)),
                    ),
                  ),
                ),
                SizedBox(height: adaptive.scale(18)),
                Text(
                  title,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: adaptive.scale(12)),
                child,
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
