import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/error_view.dart';
import '../../features/profile/profile_completion_gate.dart';
import '../../features/profile/profile_guard_result.dart';
import '../../features/tours/models/tour_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/tour_provider.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

enum _ToursSortMode { popular, newest, affordable }

class _ToursScreenState extends State<ToursScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _ToursSortMode _sortMode = _ToursSortMode.popular;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourProvider>().loadTours();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) return;

    setState(() {
      _searchQuery = nextQuery;
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Future<void> _handleRefresh() {
    return context.read<TourProvider>().refreshTours(query: _searchQuery);
  }

  Future<void> _onCreateTourTap() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.state != AuthState.authenticated) {
      context.push('/login?from=/tours/create');
      return;
    }

    final result = await ProfileCompletionGate.ensureCompleted(context);
    if (result == ProfileGuardResult.cancelled || !mounted) return;

    context.push('/tours/create');
  }

  void _openTourDetails(TourVm tour) {
    if (tour.id.trim().isEmpty) return;

    context.push('/tours/${Uri.encodeComponent(tour.id)}', extra: tour);
  }

  void _onSortTap(_ToursSortMode mode) {
    if (_sortMode == mode) return;

    setState(() {
      _sortMode = mode;
    });
  }

  Future<void> _showFilters() async {
    final selectedMode = await showModalBottomSheet<_ToursSortMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ToursFilterSheet(selected: _sortMode),
    );

    if (selectedMode == null || !mounted) return;
    _onSortTap(selectedMode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<SessionProvider>().profile;
    final canCreateTour = profile?.isGuide == true;

    return Scaffold(
      backgroundColor: const Color(0xFF21170D),
      bottomNavigationBar: ToursBottomNavigation(
        canCreateTour: canCreateTour,
        onCreateTourTap: _onCreateTourTap,
        onMapTap: () => context.push('/map'),
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppListScreenHeader(
              title: l10n.toursDiscoverTitle,
              notificationsTooltip: l10n.attractionNotificationsTooltip,
              onBackTap: _goBack,
              onNotificationsTap: () => context.push('/notifications'),
            ),
            Expanded(
              child: Consumer<TourProvider>(
                builder: (context, provider, _) {
                  final visibleTours = _visibleTours(provider.tours);
                  final isInitialLoading =
                      provider.listState == TourListState.loading &&
                          provider.tours.isEmpty;
                  final hasInitialError =
                      provider.listState == TourListState.error &&
                          provider.tours.isEmpty;

                  if (hasInitialError) {
                    return ErrorView(
                      message:
                          provider.listErrorMessage ?? l10n.toursLoadFailed,
                      onRetry: () => context
                          .read<TourProvider>()
                          .loadTours(query: _searchQuery),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: const Color(0xFF2B1F14),
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPadding(context),
                            14,
                            _horizontalPadding(context),
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ToursSearchField(
                                  controller: _searchController,
                                  hintText: l10n.toursSearchHint,
                                  onFilterTap: _showFilters,
                                ),
                                const SizedBox(height: 26),
                                const Divider(
                                  height: 1,
                                  color: Color(0x1AFFFFFF),
                                ),
                                const SizedBox(height: 9),
                                _ToursSortTabs(
                                  selected: _sortMode,
                                  onChanged: _onSortTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isInitialLoading)
                          _ToursLoadingGrid(
                              horizontalPadding: _horizontalPadding(context))
                        else if (visibleTours.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ToursEmptyState(
                              title: l10n.toursEmptyTitle,
                              subtitle: _searchQuery.isEmpty
                                  ? l10n.toursEmptySubtitle
                                  : l10n.toursEmptySearchSubtitle,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              _horizontalPadding(context),
                              26,
                              _horizontalPadding(context),
                              28,
                            ),
                            sliver: SliverGrid.builder(
                              itemCount: visibleTours.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 18,
                                crossAxisSpacing: 18,
                                childAspectRatio: _gridAspectRatio(context),
                              ),
                              itemBuilder: (context, index) {
                                return TourListCard(
                                  tour: visibleTours[index],
                                  seed: index,
                                  onTap: () =>
                                      _openTourDetails(visibleTours[index]),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TourVm> _visibleTours(List<TourVm> tours) {
    final query = _searchQuery.toLowerCase();
    final filtered = tours.where((tour) {
      if (query.isEmpty) return true;

      final haystack = [
        tour.title,
        tour.summary,
        tour.cityName,
        tour.landmarkName,
        tour.categorySlug,
        ...tour.tags,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList(growable: false);

    final sorted = [...filtered];
    switch (_sortMode) {
      case _ToursSortMode.affordable:
        sorted.sort((a, b) => a.priceAmount.compareTo(b.priceAmount));
      case _ToursSortMode.newest:
        sorted.sort((a, b) => b.id.compareTo(a.id));
      case _ToursSortMode.popular:
        sorted.sort((a, b) => a.title.compareTo(b.title));
    }

    return sorted;
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 18;
    if (width >= 600) return 28;
    return 24;
  }

  double _gridAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 360) return 0.63;
    if (width >= 600) return 0.72;
    return 0.68;
  }
}

class ToursBottomNavigation extends StatelessWidget {
  const ToursBottomNavigation({
    super.key,
    required this.canCreateTour,
    required this.onCreateTourTap,
    required this.onMapTap,
    required this.onHomeTap,
    required this.onQrTap,
    required this.onServicesTap,
    required this.onChatsTap,
  });

  final bool canCreateTour;
  final VoidCallback onCreateTourTap;
  final VoidCallback onMapTap;
  final VoidCallback onHomeTap;
  final VoidCallback onQrTap;
  final VoidCallback onServicesTap;
  final VoidCallback onChatsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (canCreateTour) {
      return CreateActionBottomNavigationBar(
        createSemanticsLabel: l10n.toursCreateFab,
        onHomeTap: onHomeTap,
        onQrTap: onQrTap,
        onCreateTap: onCreateTourTap,
        onServicesTap: onServicesTap,
        onChatsTap: onChatsTap,
        backgroundStyle: AppBottomNavCreateBackgroundStyle.flat,
      );
    }

    return CommonBottomNavigationBar(
      onHomeTap: onHomeTap,
      onQrTap: onQrTap,
      onMapTap: onMapTap,
      onServicesTap: onServicesTap,
      onChatsTap: onChatsTap,
    );
  }
}

class _ToursSearchField extends StatelessWidget {
  const _ToursSearchField({
    required this.controller,
    required this.hintText,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1F14),
        borderRadius: BorderRadius.circular(21),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFFA99586),
            size: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
              ),
            ),
          ),
          Tooltip(
            message: AppLocalizations.of(context)!.myActivitiesFilterButton,
            child: IconButton(
              onPressed: onFilterTap,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                foregroundColor: AppColors.accent,
                minimumSize: const Size(43, 43),
              ),
              icon: const Icon(Icons.tune_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToursFilterSheet extends StatelessWidget {
  const _ToursFilterSheet({required this.selected});

  final _ToursSortMode selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (mode: _ToursSortMode.popular, label: l10n.toursSortPopular),
      (mode: _ToursSortMode.newest, label: l10n.toursSortNewest),
      (mode: _ToursSortMode.affordable, label: l10n.toursSortAffordable),
    ];

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            maxWidth: 520,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF21170D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0x293A270F)),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.myActivitiesFilterTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final option in options) ...[
                    _ToursFilterOption(
                      label: option.label,
                      selected: option.mode == selected,
                      onTap: () => Navigator.of(context).pop(option.mode),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToursFilterOption extends StatelessWidget {
  const _ToursFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : const Color(0xFF2B1F14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.44)
                    : Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color:
                        selected ? AppColors.accent : const Color(0xFFA99586),
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

class _ToursSortTabs extends StatelessWidget {
  const _ToursSortTabs({
    required this.selected,
    required this.onChanged,
  });

  final _ToursSortMode selected;
  final ValueChanged<_ToursSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (mode: _ToursSortMode.popular, label: l10n.toursSortPopular),
      (mode: _ToursSortMode.newest, label: l10n.toursSortNewest),
      (mode: _ToursSortMode.affordable, label: l10n.toursSortAffordable),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = item.mode == selected;

          return _ToursSortTab(
            label: item.label,
            active: active,
            onTap: () => onChanged(item.mode),
          );
        },
      ),
    );
  }
}

class _ToursSortTab extends StatelessWidget {
  const _ToursSortTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : const Color(0xFFC8B8A9);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(top: 9, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.9,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: active ? 34 : 0,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TourListCard extends StatelessWidget {
  const TourListCard({
    super.key,
    required this.tour,
    required this.seed,
    this.onTap,
  });

  final TourVm tour;
  final int seed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = _primaryLocation(tour);
    final duration = _formatDuration(context, tour.durationMinutes);
    final price = _formatPrice(context, tour);
    final category = _categoryLabel(l10n, tour.categorySlug);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF251A10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _TourCoverArt(
                      seed: seed, categorySlug: tour.categorySlug),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            tour.title.isEmpty ? category : tour.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFEADCD0),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1.16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                duration.isEmpty ? category : duration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB5A394),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _primaryLocation(TourVm tour) {
    final city = tour.cityName?.trim();
    if (city != null && city.isNotEmpty) return city;

    final landmark = tour.landmarkName?.trim();
    if (landmark != null && landmark.isNotEmpty) return landmark;

    return tour.categorySlug?.trim().isNotEmpty == true
        ? tour.categorySlug!.trim()
        : 'FlyFy';
  }

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes <= 0) return '';

    final l10n = AppLocalizations.of(context)!;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours > 0 && remainder > 0) {
      return '$hours ${l10n.toursDurationHourShort} '
          '$remainder ${l10n.toursDurationMinuteShort}';
    }
    if (hours > 0) {
      return '$hours ${l10n.toursDurationHourShort}';
    }
    return '$minutes ${l10n.toursDurationMinuteShort}';
  }

  String _formatPrice(BuildContext context, TourVm tour) {
    final l10n = AppLocalizations.of(context)!;
    if (tour.priceAmount <= 0) return l10n.toursFreePrice;

    final decimalDigits =
        tour.priceAmount == tour.priceAmount.truncateToDouble() ? 0 : 2;

    try {
      return NumberFormat.simpleCurrency(
        name: tour.currency,
        decimalDigits: decimalDigits,
      ).format(tour.priceAmount);
    } catch (_) {
      return '${tour.priceAmount.toStringAsFixed(decimalDigits)} ${tour.currency}';
    }
  }

  String _categoryLabel(AppLocalizations l10n, String? categorySlug) {
    switch (categorySlug?.toLowerCase()) {
      case 'adventure':
        return l10n.createTourCategoryAdventure;
      case 'cultural':
        return l10n.createTourCategoryCultural;
      case 'culinary':
        return l10n.createTourCategoryCulinary;
      case 'wellness':
        return l10n.createTourCategoryWellness;
      default:
        return l10n.serviceTours;
    }
  }
}

class _TourCoverArt extends StatelessWidget {
  const _TourCoverArt({
    required this.seed,
    required this.categorySlug,
  });

  final int seed;
  final String? categorySlug;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(categorySlug, seed);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.sky, palette.haze, palette.ground],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _TourCoverPainter(palette, seed)),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 3),
                  Text(
                    '4.9',
                    style: TextStyle(
                      color: Color(0xFFF4EEE8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  _TourCoverPalette _paletteFor(String? categorySlug, int seed) {
    switch (categorySlug?.toLowerCase()) {
      case 'cultural':
        return const _TourCoverPalette(
          sky: Color(0xFF52B8D9),
          haze: Color(0xFFE1C071),
          ground: Color(0xFF8A5A2B),
          ridge: Color(0xFFB67A33),
          ridgeDark: Color(0xFF5A3419),
        );
      case 'culinary':
        return const _TourCoverPalette(
          sky: Color(0xFFFFB13B),
          haze: Color(0xFF8C4022),
          ground: Color(0xFF30160C),
          ridge: Color(0xFFE07A22),
          ridgeDark: Color(0xFF6D2812),
        );
      case 'wellness':
        return const _TourCoverPalette(
          sky: Color(0xFF7DD2C7),
          haze: Color(0xFF4F8E65),
          ground: Color(0xFF143B29),
          ridge: Color(0xFF2E7D4C),
          ridgeDark: Color(0xFF10291E),
        );
      default:
        final variants = [
          const _TourCoverPalette(
            sky: Color(0xFF43A9DF),
            haze: Color(0xFFBFE6F3),
            ground: Color(0xFF143E23),
            ridge: Color(0xFF2D8437),
            ridgeDark: Color(0xFF102E19),
          ),
          const _TourCoverPalette(
            sky: Color(0xFFF7A541),
            haze: Color(0xFFD17618),
            ground: Color(0xFF7D3508),
            ridge: Color(0xFF9B4C08),
            ridgeDark: Color(0xFF4C2206),
          ),
        ];
        return variants[seed % variants.length];
    }
  }
}

class _TourCoverPainter extends CustomPainter {
  const _TourCoverPainter(this.palette, this.seed);

  final _TourCoverPalette palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final ridgePaint = Paint()..color = palette.ridge;
    final ridgeDarkPaint = Paint()..color = palette.ridgeDark;
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.86);

    final offset = (seed % 4) * size.width * 0.05;
    final firstRidge = Path()
      ..moveTo(-size.width * 0.1, size.height)
      ..lineTo(size.width * 0.32 + offset, size.height * 0.42)
      ..lineTo(size.width * 0.78 + offset, size.height)
      ..close();

    final secondRidge = Path()
      ..moveTo(size.width * 0.22 - offset, size.height)
      ..lineTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 1.12, size.height)
      ..close();

    final snowCap = Path()
      ..moveTo(size.width * 0.72 - offset, size.height * 0.34)
      ..lineTo(size.width * 0.63 - offset, size.height * 0.48)
      ..lineTo(size.width * 0.78 - offset, size.height * 0.44)
      ..close();

    canvas
      ..drawPath(firstRidge, ridgeDarkPaint)
      ..drawPath(secondRidge, ridgePaint)
      ..drawPath(snowCap, snowPaint);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.54, size.height * 0.28),
          radius: math.min(size.width, size.height) * 0.2,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.28),
      math.min(size.width, size.height) * 0.2,
      sunPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TourCoverPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.seed != seed;
  }
}

class _TourCoverPalette {
  const _TourCoverPalette({
    required this.sky,
    required this.haze,
    required this.ground,
    required this.ridge,
    required this.ridgeDark,
  });

  final Color sky;
  final Color haze;
  final Color ground;
  final Color ridge;
  final Color ridgeDark;
}

class _ToursLoadingGrid extends StatelessWidget {
  const _ToursLoadingGrid({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 26, horizontalPadding, 28),
      sliver: SliverGrid.builder(
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio:
              MediaQuery.sizeOf(context).width <= 360 ? 0.63 : 0.68,
        ),
        itemBuilder: (context, index) {
          return const _ToursSkeletonCard();
        },
      ),
    );
  }
}

class _ToursSkeletonCard extends StatelessWidget {
  const _ToursSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF251A10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SkeletonBlock()),
            SizedBox(height: 14),
            _SkeletonLine(width: 84, height: 10),
            SizedBox(height: 10),
            _SkeletonLine(width: double.infinity, height: 18),
            SizedBox(height: 8),
            _SkeletonLine(width: 92, height: 16),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ToursEmptyState extends StatelessWidget {
  const _ToursEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA99586),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
