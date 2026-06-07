import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/app_list_search_field.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/pagination_bar.dart';
import '../../core/time/app_time.dart';
import '../../core/utils/pagination.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/excursions/excursion_currency.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../features/excursions/models/create_excursion_review_request.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/home_location_provider.dart';
import '../../shared/location/home_location_filter_defaults.dart';
import '../../shared/widgets/app_city_filter_section.dart';

class MyExcursionsScreen extends StatefulWidget {
  const MyExcursionsScreen({super.key});

  @override
  State<MyExcursionsScreen> createState() => _MyExcursionsScreenState();
}

class _MyExcursionsScreenState extends State<MyExcursionsScreen> {
  static const int _pageSize = 8;

  final AttractionApi _attractionApi = AttractionApi();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  Map<String, AttractionVm> _localizedLandmarks = const {};
  final Set<String> _loadingLocalizedLandmarkIds = <String>{};
  String? _localizedLandmarksLocale;
  MyExcursionsTab _activeTab = MyExcursionsTab.booked;
  MyExcursionBookingSortMode _sortMode = MyExcursionBookingSortMode.date;
  bool _sortAscending = false;
  _MyExcursionsFilters _filters = const _MyExcursionsFilters();
  String _searchQuery = '';
  int _bookedPage = 1;
  int _visitedPage = 1;
  bool _hasAppliedDefaultCityFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDefaultCityFilter());
      context.read<ExcursionProvider>().loadMyExcursionBookings();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final lang = Localizations.localeOf(context).languageCode;
    if (_localizedLandmarksLocale == lang) return;
    _localizedLandmarksLocale = lang;
    _localizedLandmarks = const {};
    _loadingLocalizedLandmarkIds.clear();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _activePage =>
      _activeTab == MyExcursionsTab.booked ? _bookedPage : _visitedPage;

  int get _activeFilterCount => _filters.activeCountFor(_activeTab);

  Future<void> _initializeDefaultCityFilter() async {
    final provider = context.read<HomeLocationProvider>();
    if (!provider.isLoaded && !provider.isLoading) {
      await provider.load(
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
    if (!mounted) return;
    _applyDefaultCityFilter(provider);
  }

  void _applyDefaultCityFilter(HomeLocationProvider provider) {
    if (_hasAppliedDefaultCityFilter) {
      return;
    }
    if (_filters.country != null || _filters.city != null) {
      _hasAppliedDefaultCityFilter = true;
      return;
    }

    final defaults = HomeLocationFilterDefaults.fromPreference(
      provider.effectiveLocation,
    );
    if (!defaults.hasValue) return;
    _hasAppliedDefaultCityFilter = true;

    setState(
      () => _filters = _filters.copyWith(
        country: defaults.country,
        city: defaults.city,
      ),
    );
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (_searchQuery == nextQuery) return;
    setState(() {
      _searchQuery = nextQuery;
      _resetActivePage();
    });
  }

  void _handleSortTap(MyExcursionBookingSortMode mode) {
    setState(() {
      if (_sortMode == mode) {
        _sortAscending = !_sortAscending;
      } else {
        _sortMode = mode;
        _sortAscending = mode == MyExcursionBookingSortMode.price;
      }
      _resetActivePage();
    });
  }

  void _resetActivePage() {
    if (_activeTab == MyExcursionsTab.booked) {
      _bookedPage = 1;
    } else {
      _visitedPage = 1;
    }
  }

  Future<void> _setActivePage(int page) async {
    if (page == _activePage) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (_activeTab == MyExcursionsTab.booked) {
        _bookedPage = page;
      } else {
        _visitedPage = page;
      }
    });
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  void _scheduleResolveLocalizedLandmarks(List<ExcursionBookingVm> bookings) {
    if (!mounted) return;

    final lang = Localizations.localeOf(context).languageCode;
    final ids = <String>{};
    for (final booking in bookings) {
      final landmarkId = booking.landmarkId?.trim();
      if (landmarkId == null ||
          landmarkId.isEmpty ||
          _localizedLandmarks.containsKey(landmarkId) ||
          _loadingLocalizedLandmarkIds.contains(landmarkId)) {
        continue;
      }
      ids.add(landmarkId);
    }
    if (ids.isEmpty) return;

    for (final landmarkId in ids.take(16)) {
      _loadingLocalizedLandmarkIds.add(landmarkId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadLocalizedLandmark(landmarkId, lang));
      });
    }
  }

  Future<void> _loadLocalizedLandmark(String landmarkId, String lang) async {
    try {
      final attraction = await _attractionApi.getAttraction(
        landmarkId,
        locale: lang,
      );
      if (!mounted || _localizedLandmarksLocale != lang) return;

      setState(() {
        _localizedLandmarks = {..._localizedLandmarks, landmarkId: attraction};
        _loadingLocalizedLandmarkIds.remove(landmarkId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocalizedLandmarkIds.remove(landmarkId));
    }
  }

  AttractionVm? _localizedLandmarkFor(ExcursionBookingVm booking) {
    final landmarkId = booking.landmarkId?.trim();
    if (landmarkId == null || landmarkId.isEmpty) return null;
    return _localizedLandmarks[landmarkId];
  }

  Future<void> _openFilters(
    AppLocalizations l10n,
    List<ExcursionBookingVm> sourceItems,
  ) async {
    final result = await showModalBottomSheet<_MyExcursionsFilters>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MyExcursionsFilterSheet(
          l10n: l10n,
          tab: _activeTab,
          initialFilters: _filters,
          previewCountBuilder: (filters) {
            final now = DateTime.now().toUtc();
            return filterMyExcursionBookings(
              _filterBookingsByLocation(sourceItems, filters),
              now: now,
              tab: _activeTab,
              query: _searchQuery,
              statuses: filters.statuses,
              reviewed: filters.reviewed,
              startDate: filters.startDate,
              endDate: filters.endDate,
            ).length;
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _filters = result;
      _resetActivePage();
    });
  }

  List<ExcursionBookingVm> _filterBookingsByLocation(
    List<ExcursionBookingVm> items,
    _MyExcursionsFilters filters,
  ) {
    if (filters.country == null && filters.city == null) return items;
    return items
        .where((booking) {
          final country = filters.country;
          if (country != null &&
              !country.matches(countryCode: booking.countryCode)) {
            return false;
          }

          final city = filters.city;
          if (city == null) return true;
          return city.matches(
            cityName: booking.cityName,
            countryCode: booking.countryCode,
          );
        })
        .toList(growable: false);
  }

  String _myExcursionsEmptyMessage(AppLocalizations l10n) {
    final base = _activeTab == MyExcursionsTab.booked
        ? l10n.myExcursionsBookedEmptyHint
        : l10n.myExcursionsVisitedEmptyHint;
    if (_filters.country == null && _filters.city == null) return base;
    return '$base\n\n${l10n.cityFilterEmptyHint}';
  }

  Future<void> _openReviewSheet(ExcursionBookingVm booking) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExcursionReviewSheet(
          l10n: l10n,
          booking: booking,
          onSubmit: (draft) async {
            final savedBooking = await provider.saveBookingReviews(
              booking.id,
              SaveBookingReviewsRequest(
                excursionReview: draft.excursion == null
                    ? null
                    : ReviewMutationRequest.fromDraft(draft.excursion!),
                guideReview: draft.guide == null
                    ? null
                    : ReviewMutationRequest.fromDraft(draft.guide!),
              ),
            );
            if (savedBooking == null) return false;
            await provider.loadExcursionReviews(productId: booking.productId);
            final landmarkId = booking.landmarkId?.trim();
            if (landmarkId != null && landmarkId.isNotEmpty) {
              await provider.loadExcursionReviews(landmarkId: landmarkId);
            }
            return true;
          },
          onDeleteExcursionReview: booking.review == null
              ? null
              : () => provider.deleteExcursionReview(
                  booking.id,
                  booking.review!.id,
                ),
          onDeleteGuideReview: booking.guideReview == null
              ? null
              : () => provider.deleteGuideReview(
                  booking.id,
                  booking.guideReview!.id,
                ),
        );
      },
    );

    if (!mounted || success != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.myExcursionsReviewSuccess)));
  }

  Future<void> _openEditGuestsSheet(ExcursionBookingVm booking) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditExcursionGuestsSheet(
          l10n: l10n,
          booking: booking,
          onQuote: (adults, children) {
            return provider.quoteExcursionBookingGuests(
              booking.id,
              adults: adults,
              children: children,
            );
          },
          onSubmit: (adults, children) {
            return provider.updateExcursionBookingGuests(
              booking.id,
              adults: adults,
              children: children,
            );
          },
        );
      },
    );

    if (!mounted || success != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.myExcursionsUpdateGuestsSuccess)),
      );
  }

  Future<void> _openCancelBookingSheet(ExcursionBookingVm booking) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final success = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CancelExcursionBookingSheet(
          l10n: l10n,
          booking: booking,
          onQuote: (reason) {
            return provider.quoteExcursionBookingCancellation(
              booking.id,
              reason: reason,
            );
          },
          onSubmit: (reason) {
            return provider.cancelExcursionBooking(booking.id, reason: reason);
          },
        );
      },
    );

    if (!mounted || success != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.myExcursionsCancelBookingSuccess)),
      );
  }

  void _openDetails(ExcursionBookingVm booking) {
    context.push('/excursions/${Uri.encodeComponent(booking.productId)}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final maxWidth = screenWidth >= 600 ? 480.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF160D07),
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.services,
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onMapTap: () => context.push('/map'),
        onServicesTap: () => context.push('/excursions'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C120A), Color(0xFF160D07)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<ExcursionProvider>(
            builder: (context, provider, _) {
              _scheduleResolveLocalizedLandmarks(provider.myExcursionBookings);
              final now = DateTime.now().toUtc();
              final locationFilteredBookings = _filterBookingsByLocation(
                provider.myExcursionBookings,
                _filters,
              );
              final filtered = filterMyExcursionBookings(
                locationFilteredBookings,
                now: now,
                tab: _activeTab,
                query: _searchQuery,
                statuses: _filters.statuses,
                reviewed: _filters.reviewed,
                startDate: _filters.startDate,
                endDate: _filters.endDate,
              );
              final sorted = sortMyExcursionBookings(
                filtered,
                now: now,
                tab: _activeTab,
                sortMode: _sortMode,
                ascending: _sortAscending,
              );
              final page = paginateItems(
                sorted,
                currentPage: _activePage,
                pageSize: _pageSize,
              );
              final isInitialLoading =
                  provider.bookingListState == ExcursionListState.loading &&
                  provider.myExcursionBookings.isEmpty;
              final isInitialError =
                  provider.bookingListState == ExcursionListState.error &&
                  provider.myExcursionBookings.isEmpty;

              return RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: const Color(0xFF2A1D13),
                onRefresh: provider.refreshMyExcursionBookings,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        104 + safeBottom,
                      ),
                      children: [
                        AppListScreenHeader(
                          title: l10n.myExcursionsTitle,
                          notificationsTooltip:
                              l10n.profileNotificationsRowTitle,
                          onBackTap: _goBack,
                          onNotificationsTap: () =>
                              context.push('/notifications'),
                          horizontalPadding: 0,
                        ),
                        const SizedBox(height: 14),
                        AppListSearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: l10n.myExcursionsSearchHint,
                          filterTooltip: l10n.myExcursionsFilterTitle,
                          activeFilterCount: _activeFilterCount,
                          showClearButton: true,
                          onFilterTap: () =>
                              _openFilters(l10n, provider.myExcursionBookings),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 14),
                        _MyExcursionsTabSwitcher(
                          activeTab: _activeTab,
                          onChanged: (tab) {
                            setState(() {
                              _activeTab = tab;
                              _resetActivePage();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        AppInlineSortRow<MyExcursionBookingSortMode>(
                          label: l10n.myExcursionsSortLabel,
                          options: [
                            AppInlineSortOption(
                              value: MyExcursionBookingSortMode.date,
                              label: l10n.myExcursionsSortDate,
                            ),
                            AppInlineSortOption(
                              value: MyExcursionBookingSortMode.price,
                              label: l10n.myExcursionsSortPrice,
                            ),
                          ],
                          selectedValue: _sortMode,
                          isAscending: _sortAscending,
                          onSelected: _handleSortTap,
                        ),
                        const SizedBox(height: 18),
                        if (isInitialLoading) ...[
                          const _MyExcursionSkeletonCard(),
                          const SizedBox(height: 14),
                          const _MyExcursionSkeletonCard(),
                        ] else if (isInitialError) ...[
                          _MyExcursionInfoCard(
                            icon: Icons.wifi_off_rounded,
                            title: l10n.myExcursionsLoadFailed,
                            message:
                                provider.bookingListErrorMessage ??
                                l10n.myExcursionsLoadFailed,
                            actionLabel: l10n.retryButton,
                            onActionTap: provider.refreshMyExcursionBookings,
                          ),
                        ] else if (sorted.isEmpty) ...[
                          _MyExcursionInfoCard(
                            icon: _activeTab == MyExcursionsTab.booked
                                ? Icons.confirmation_number_outlined
                                : Icons.rate_review_outlined,
                            title: _activeTab == MyExcursionsTab.booked
                                ? l10n.myExcursionsBookedEmpty
                                : l10n.myExcursionsVisitedEmpty,
                            message: _myExcursionsEmptyMessage(l10n),
                          ),
                        ] else ...[
                          for (var i = 0; i < page.items.length; i++) ...[
                            Builder(
                              builder: (context) {
                                final booking = page.items[i];
                                return _MyExcursionBookingCard(
                                  booking: booking,
                                  languageCode: Localizations.localeOf(
                                    context,
                                  ).languageCode,
                                  localizedLandmark: _localizedLandmarkFor(
                                    booking,
                                  ),
                                  onTap: () => _openDetails(booking),
                                  onEditGuestsTap: booking.isBooked(now)
                                      ? () => _openEditGuestsSheet(booking)
                                      : null,
                                  onCancelTap:
                                      booking.canBeCancelledByTourist(now)
                                      ? () => _openCancelBookingSheet(booking)
                                      : null,
                                  onReviewTap: booking.canReview(now)
                                      ? () => _openReviewSheet(booking)
                                      : null,
                                );
                              },
                            ),
                            if (i != page.items.length - 1)
                              const SizedBox(height: 14),
                          ],
                          if (page.hasMultiplePages) ...[
                            const SizedBox(height: 18),
                            InflapPaginationBar(
                              currentPage: page.currentPage,
                              totalPages: page.totalPages,
                              onPageChanged: _setActivePage,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MyExcursionsFilters {
  const _MyExcursionsFilters({
    this.country,
    this.city,
    this.statuses = const <String>{},
    this.reviewed,
    this.startDate,
    this.endDate,
  });

  final AppCountryFilterValue? country;
  final AppCityFilterValue? city;
  final Set<String> statuses;
  final bool? reviewed;
  final DateTime? startDate;
  final DateTime? endDate;

  int get activeCount =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      statuses.length +
      (reviewed == null ? 0 : 1) +
      (startDate == null ? 0 : 1) +
      (endDate == null ? 0 : 1);

  int activeCountFor(MyExcursionsTab tab) =>
      (country == null ? 0 : 1) +
      (city == null ? 0 : 1) +
      (tab == MyExcursionsTab.booked ? statuses.length : 0) +
      (reviewed == null ? 0 : 1) +
      (startDate == null ? 0 : 1) +
      (endDate == null ? 0 : 1);

  _MyExcursionsFilters copyWith({
    Object? country = _unset,
    Object? city = _unset,
    Set<String>? statuses,
    bool? reviewed,
    bool clearReviewed = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return _MyExcursionsFilters(
      country: identical(country, _unset)
          ? this.country
          : country as AppCountryFilterValue?,
      city: identical(city, _unset) ? this.city : city as AppCityFilterValue?,
      statuses: statuses ?? this.statuses,
      reviewed: clearReviewed ? null : reviewed ?? this.reviewed,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
    );
  }

  static const Object _unset = Object();
}

class _MyExcursionsTabSwitcher extends StatelessWidget {
  const _MyExcursionsTabSwitcher({
    required this.activeTab,
    required this.onChanged,
  });

  final MyExcursionsTab activeTab;
  final ValueChanged<MyExcursionsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.myExcursionsBookedTab,
              active: activeTab == MyExcursionsTab.booked,
              onTap: () => onChanged(MyExcursionsTab.booked),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: l10n.myExcursionsVisitedTab,
              active: activeTab == MyExcursionsTab.visited,
              onTap: () => onChanged(MyExcursionsTab.visited),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: active ? AppColors.accent : Colors.transparent,
        foregroundColor: active ? Colors.white : const Color(0xFFCBB8A3),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }
}

class _MyExcursionBookingCard extends StatelessWidget {
  const _MyExcursionBookingCard({
    required this.booking,
    required this.languageCode,
    required this.onTap,
    required this.onEditGuestsTap,
    required this.onCancelTap,
    required this.onReviewTap,
    this.localizedLandmark,
  });

  final ExcursionBookingVm booking;
  final String languageCode;
  final AttractionVm? localizedLandmark;
  final VoidCallback onTap;
  final VoidCallback? onEditGuestsTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final dateLabel = formatEventDateTime(
      booking.scheduledFor,
      timezoneId: booking.timezone,
      localeName: localeName,
    );
    final guide = booking.guideDisplayName.trim().isEmpty
        ? l10n.myExcursionsGuideFallback
        : booking.guideDisplayName.trim();
    final price = formatLocalizedExcursionMoney(
      amount: booking.totalPriceAmount,
      currency: booking.currency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );
    final displayTitle = localizedAttractionTitle(
      languageCode: languageCode,
      attraction: localizedLandmark,
      fallback: booking.title,
    ).trim();
    final landmarkName = localizedAttractionTitle(
      languageCode: languageCode,
      attraction: localizedLandmark,
      fallback: booking.landmarkName ?? '',
    ).trim();
    final showLandmarkName =
        landmarkName.isNotEmpty &&
        !_isSameMyExcursionLabel(landmarkName, displayTitle);
    final reviewBadgeRating = booking.reviewBadgeRating;
    final semanticLabel = [
      displayTitle.isEmpty ? l10n.myExcursionsUntitled : displayTitle,
      l10n.myExcursionsGuideLine(guide),
      dateLabel,
      l10n.myExcursionsGuests(booking.totalSeats),
      price,
      if (booking.isCancelled) l10n.myExcursionsCancelBookingSuccess,
    ].join(', ');

    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1D13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle.isEmpty
                                ? l10n.myExcursionsUntitled
                                : displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.myExcursionsGuideLine(guide),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFCBB8A3),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(icon: Icons.event_rounded, label: dateLabel),
                    _MetaChip(
                      icon: Icons.group_rounded,
                      label: l10n.myExcursionsGuests(booking.totalSeats),
                    ),
                    _MetaChip(icon: Icons.payments_outlined, label: price),
                  ],
                ),
                if (showLandmarkName) ...[
                  const SizedBox(height: 10),
                  Text(
                    landmarkName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDCCAB7),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (onEditGuestsTap != null ||
                    onCancelTap != null ||
                    onReviewTap != null ||
                    booking.isCancelled ||
                    reviewBadgeRating != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (reviewBadgeRating != null)
                        SizedBox(
                          width: double.infinity,
                          child: _ReviewedBadge(rating: reviewBadgeRating),
                        ),
                      if (booking.isCancelled)
                        SizedBox(
                          width: double.infinity,
                          child: _CancelledBookingBadge(booking: booking),
                        ),
                      if (onEditGuestsTap != null)
                        OutlinedButton.icon(
                          onPressed: onEditGuestsTap,
                          icon: const Icon(Icons.group_add_rounded, size: 18),
                          label: Text(l10n.myExcursionsEditGuestsButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.45),
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      if (onCancelTap != null)
                        OutlinedButton.icon(
                          onPressed: onCancelTap,
                          icon: const Icon(Icons.event_busy_rounded, size: 18),
                          label: Text(l10n.myExcursionsCancelBookingButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: BorderSide(
                              color: AppColors.destructive.withValues(
                                alpha: 0.42,
                              ),
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      if (onReviewTap != null)
                        FilledButton.icon(
                          onPressed: onReviewTap,
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: Text(l10n.myExcursionsReviewButton),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isSameMyExcursionLabel(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDCCAB7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewedBadge extends StatelessWidget {
  const _ReviewedBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF58C47B),
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${AppLocalizations.of(context)!.myExcursionsReviewed} ${rating.toStringAsFixed(1)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFBDEBCB),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelledBookingBadge extends StatelessWidget {
  const _CancelledBookingBadge({required this.booking});

  final ExcursionBookingVm booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final refundAmount = booking.refundAmount;
    final refundCurrency = (booking.refundCurrency ?? booking.currency).trim();
    final refundLabel = formatLocalizedExcursionMoney(
      amount: refundAmount,
      currency: refundCurrency.isEmpty ? booking.currency : refundCurrency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );
    final text = refundAmount > 0
        ? l10n.myExcursionsCancelledWithRefund(
            refundLabel,
            booking.refundPercent,
          )
        : l10n.myExcursionsCancelledWithoutRefund;

    return Row(
      children: [
        const Icon(
          Icons.event_busy_rounded,
          color: AppColors.destructive,
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFD0C1),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelExcursionBookingSheet extends StatefulWidget {
  const _CancelExcursionBookingSheet({
    required this.l10n,
    required this.booking,
    required this.onQuote,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final ExcursionBookingVm booking;
  final Future<ExcursionBookingCancellationQuote> Function(String reason)
  onQuote;
  final Future<bool> Function(String reason) onSubmit;

  @override
  State<_CancelExcursionBookingSheet> createState() =>
      _CancelExcursionBookingSheetState();
}

class _CancelExcursionBookingSheetState
    extends State<_CancelExcursionBookingSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocusNode = FocusNode();
  ExcursionBookingCancellationQuote? _quote;
  bool _isQuoteLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    if (_isQuoteLoading) return;
    setState(() {
      _isQuoteLoading = true;
      _errorMessage = null;
    });
    try {
      final quote = await widget.onQuote(_reasonController.text);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _isQuoteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _isQuoteLoading = false;
        _errorMessage = widget.l10n.myExcursionsCancelQuoteFailed;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isQuoteLoading || _quote == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onSubmit(_reasonController.text);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = widget.l10n.myExcursionsCancelBookingFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final quote = _quote;
    final refund = quote == null
        ? null
        : formatLocalizedExcursionMoney(
            amount: quote.amount,
            currency: quote.currency,
            localeName: localeName,
            useExcursionListCurrencyFormat: true,
          );
    final canSubmit = !_isSubmitting && !_isQuoteLoading && quote != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          math.max(12, mediaQuery.viewInsets.bottom + 12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF21150D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.l10n.myExcursionsCancelBookingTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFDCCAB7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.l10n.myExcursionsCancelBookingHint,
                    style: const TextStyle(
                      color: Color(0xFFCBB8A3),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isQuoteLoading)
                    _QuoteStatusPanel(
                      icon: Icons.receipt_long_rounded,
                      title: widget.l10n.myExcursionsCancelQuoteLoading,
                      showProgress: true,
                    )
                  else if (quote == null || refund == null)
                    _QuoteStatusPanel(
                      icon: Icons.error_outline_rounded,
                      title: widget.l10n.myExcursionsCancelQuoteFailed,
                      actionLabel: widget.l10n.retryButton,
                      onActionTap: _loadQuote,
                    )
                  else
                    _CancelRefundPanel(
                      amount: refund,
                      percent: quote.percent,
                      hasRefund: quote.hasRefund,
                    ),
                  const SizedBox(height: 14),
                  _CancelPolicyPanel(l10n: widget.l10n),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _reasonController,
                    focusNode: _reasonFocusNode,
                    enabled: !_isSubmitting,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          widget.l10n.myExcursionsCancelBookingReasonLabel,
                      hintText: widget
                          .l10n
                          .myExcursionsCancelBookingReasonPlaceholder,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFFC1A8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Icon(Icons.event_busy_rounded),
                    label: Text(widget.l10n.myExcursionsCancelBookingConfirm),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD85B3E),
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

class _QuoteStatusPanel extends StatelessWidget {
  const _QuoteStatusPanel({
    required this.icon,
    required this.title,
    this.showProgress = false,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFDCCAB7);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showProgress)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            )
          else
            Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelRefundPanel extends StatelessWidget {
  const _CancelRefundPanel({
    required this.amount,
    required this.percent,
    required this.hasRefund,
  });

  final String amount;
  final int percent;
  final bool hasRefund;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = hasRefund ? const Color(0xFF7ED7B5) : AppColors.destructive;
    final title = hasRefund
        ? l10n.myExcursionsCancelBookingRefund(amount, percent)
        : l10n.myExcursionsCancelBookingNoRefund;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasRefund ? Icons.savings_rounded : Icons.info_outline_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.myExcursionsCancelBookingRefundHint,
                  style: const TextStyle(
                    color: Color(0xFFCBB8A3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelPolicyPanel extends StatelessWidget {
  const _CancelPolicyPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myExcursionsCancelPolicyTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _CancelPolicyRow(text: l10n.myExcursionsCancelPolicyFull),
          _CancelPolicyRow(text: l10n.myExcursionsCancelPolicySeventyFive),
          _CancelPolicyRow(text: l10n.myExcursionsCancelPolicyHalf),
          _CancelPolicyRow(text: l10n.myExcursionsCancelPolicyQuarter),
          _CancelPolicyRow(text: l10n.myExcursionsCancelPolicyZero),
        ],
      ),
    );
  }
}

class _CancelPolicyRow extends StatelessWidget {
  const _CancelPolicyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '-',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFDCCAB7),
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExcursionGuestsSheet extends StatefulWidget {
  const _EditExcursionGuestsSheet({
    required this.l10n,
    required this.booking,
    required this.onQuote,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final ExcursionBookingVm booking;
  final Future<ExcursionBookingGuestsQuote> Function(int adults, int children)
  onQuote;
  final Future<bool> Function(int adults, int children) onSubmit;

  @override
  State<_EditExcursionGuestsSheet> createState() =>
      _EditExcursionGuestsSheetState();
}

class _EditExcursionGuestsSheetState extends State<_EditExcursionGuestsSheet> {
  late int _adults;
  late int _children;
  ExcursionBookingGuestsQuote? _quote;
  bool _isQuoteLoading = false;
  int _quoteRequestSerial = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  int get _totalGuests => _adults + _children;

  int get _maxGuests {
    final maxGroupSize = widget.booking.maxGroupSize ?? 0;
    if (maxGroupSize > 0) {
      return math.max(maxGroupSize, widget.booking.totalSeats);
    }
    return math.max(widget.booking.totalSeats, 20);
  }

  @override
  void initState() {
    super.initState();
    _adults = math.max(1, widget.booking.adults);
    _children = math.max(0, widget.booking.children);
    _loadQuote();
  }

  void _incrementAdults() {
    if (_totalGuests >= _maxGuests || _isSubmitting) return;
    setState(() => _adults++);
    _loadQuote();
  }

  void _decrementAdults() {
    if (_adults <= 1 || _isSubmitting) return;
    setState(() => _adults--);
    _loadQuote();
  }

  void _incrementChildren() {
    if (_totalGuests >= _maxGuests || _isSubmitting) return;
    setState(() => _children++);
    _loadQuote();
  }

  void _decrementChildren() {
    if (_children <= 0 || _isSubmitting) return;
    setState(() => _children--);
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final serial = ++_quoteRequestSerial;
    setState(() {
      _isQuoteLoading = true;
      _errorMessage = null;
    });
    try {
      final quote = await widget.onQuote(_adults, _children);
      if (!mounted || serial != _quoteRequestSerial) return;
      setState(() {
        _quote = quote;
        _isQuoteLoading = false;
      });
    } catch (_) {
      if (!mounted || serial != _quoteRequestSerial) return;
      setState(() {
        _quote = null;
        _isQuoteLoading = false;
        _errorMessage = widget.l10n.myExcursionsGuestsQuoteFailed;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isQuoteLoading || _quote == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final success = await widget.onSubmit(_adults, _children);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = widget.l10n.myExcursionsUpdateGuestsFailed;
    });
  }

  String _formatSettlementAmount(double amount, String currency) {
    return formatLocalizedExcursionMoney(
      amount: amount.abs(),
      currency: currency,
      localeName: widget.l10n.localeName,
      useExcursionListCurrencyFormat: true,
    );
  }

  String _submitLabel() {
    final delta = _quote?.deltaAmount ?? 0;
    if (delta > 0) {
      return widget.l10n.myExcursionsPayAndSaveGuests;
    }
    if (delta < 0) {
      return widget.l10n.myExcursionsRefundAndSaveGuests;
    }
    return widget.l10n.createExcursionSaveChanges;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight = math.max(180.0, screenHeight - bottom - 24);
    final maxSheetHeight = math.min(screenHeight * 0.86, availableHeight);
    final quote = _quote;
    final canSubmit = !_isSubmitting && !_isQuoteLoading && quote != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, math.max(12, bottom + 12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF21150D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.l10n.myExcursionsEditGuestsTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFDCCAB7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.l10n.myExcursionsEditGuestsHint,
                    style: const TextStyle(
                      color: Color(0xFFCBB8A3),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EditGuestsCounterRow(
                    title: widget.l10n.excursionBookingAdults,
                    value: _adults,
                    canIncrement: _totalGuests < _maxGuests && !_isSubmitting,
                    canDecrement: _adults > 1 && !_isSubmitting,
                    incrementLabel: '${widget.l10n.excursionBookingAdults}: +1',
                    decrementLabel: '${widget.l10n.excursionBookingAdults}: -1',
                    onIncrement: _incrementAdults,
                    onDecrement: _decrementAdults,
                  ),
                  const SizedBox(height: 10),
                  _EditGuestsCounterRow(
                    title: widget.l10n.excursionBookingChildren,
                    value: _children,
                    canIncrement: _totalGuests < _maxGuests && !_isSubmitting,
                    canDecrement: _children > 0 && !_isSubmitting,
                    incrementLabel:
                        '${widget.l10n.excursionBookingChildren}: +1',
                    decrementLabel:
                        '${widget.l10n.excursionBookingChildren}: -1',
                    onIncrement: _incrementChildren,
                    onDecrement: _decrementChildren,
                  ),
                  const SizedBox(height: 12),
                  if (_isQuoteLoading)
                    _QuoteStatusPanel(
                      icon: Icons.receipt_long_rounded,
                      title: widget.l10n.myExcursionsGuestsQuoteLoading,
                      showProgress: true,
                    )
                  else if (quote == null)
                    _QuoteStatusPanel(
                      icon: Icons.error_outline_rounded,
                      title: widget.l10n.myExcursionsGuestsQuoteFailed,
                      actionLabel: widget.l10n.retryButton,
                      onActionTap: _loadQuote,
                    )
                  else
                    _EditGuestsSettlementPanel(
                      l10n: widget.l10n,
                      quote: quote,
                      formattedAmount: _formatSettlementAmount(
                        quote.deltaAmount,
                        quote.currency,
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFFC1A8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Text(_submitLabel()),
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

class _EditGuestsSettlementPanel extends StatelessWidget {
  const _EditGuestsSettlementPanel({
    required this.l10n,
    required this.quote,
    required this.formattedAmount,
  });

  final AppLocalizations l10n;
  final ExcursionBookingGuestsQuote quote;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final deltaAmount = quote.deltaAmount;
    final isCharge = deltaAmount > 0;
    final isRefund = deltaAmount < 0;
    final accentColor = isCharge
        ? AppColors.accent
        : isRefund
        ? const Color(0xFF7ED7B5)
        : const Color(0xFFDCCAB7);
    final title = isCharge
        ? l10n.myExcursionsGuestsAdditionalCharge(formattedAmount)
        : isRefund
        ? l10n.myExcursionsGuestsRefundDue(formattedAmount)
        : l10n.myExcursionsGuestsNoPaymentChange;
    final icon = isCharge
        ? Icons.payments_rounded
        : isRefund
        ? Icons.savings_rounded
        : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.myExcursionsGuestsPaymentQuoteHint,
                  style: const TextStyle(
                    color: Color(0xFFCBB8A3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditGuestsCounterRow extends StatelessWidget {
  const _EditGuestsCounterRow({
    required this.title,
    required this.value,
    required this.canIncrement,
    required this.canDecrement,
    required this.incrementLabel,
    required this.decrementLabel,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String title;
  final int value;
  final bool canIncrement;
  final bool canDecrement;
  final String incrementLabel;
  final String decrementLabel;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _EditGuestsCounterButton(
            icon: Icons.remove_rounded,
            semanticLabel: decrementLabel,
            enabled: canDecrement,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _EditGuestsCounterButton(
            icon: Icons.add_rounded,
            semanticLabel: incrementLabel,
            enabled: canIncrement,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _EditGuestsCounterButton extends StatelessWidget {
  const _EditGuestsCounterButton({
    required this.icon,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final buttonSize = _myExcursionsCounterButtonSize(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 24,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.accent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: enabled ? 0.58 : 0.16),
            ),
          ),
          child: Icon(
            icon,
            color: enabled
                ? AppColors.accent
                : const Color(0xFFDCCAB7).withValues(alpha: 0.38),
            size: 20,
          ),
        ),
      ),
    );
  }
}

double _myExcursionsCounterButtonSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.095).clamp(34.0, 42.0).toDouble();
}

class _MyExcursionInfoCard extends StatelessWidget {
  const _MyExcursionInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBB8A3), height: 1.4),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _MyExcursionSkeletonCard extends StatelessWidget {
  const _MyExcursionSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _MyExcursionsFilterSheet extends StatefulWidget {
  const _MyExcursionsFilterSheet({
    required this.l10n,
    required this.tab,
    required this.initialFilters,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final MyExcursionsTab tab;
  final _MyExcursionsFilters initialFilters;
  final int Function(_MyExcursionsFilters filters) previewCountBuilder;

  @override
  State<_MyExcursionsFilterSheet> createState() =>
      _MyExcursionsFilterSheetState();
}

class _MyExcursionsFilterSheetState extends State<_MyExcursionsFilterSheet> {
  late AppCountryFilterValue? _country = widget.initialFilters.country;
  late AppCityFilterValue? _city = widget.initialFilters.city;
  late Set<String> _statuses = {...widget.initialFilters.statuses};
  late bool? _reviewed = widget.initialFilters.reviewed;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final FocusNode _startDateFocusNode;
  late final FocusNode _endDateFocusNode;
  late DateTime? _startDate;
  late DateTime? _endDate;
  String? _startDateError;
  String? _endDateError;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilters.startDate;
    _endDate = widget.initialFilters.endDate;
    _startDateController = TextEditingController(
      text: _startDate == null ? '' : _formatDate(_startDate!),
    );
    _endDateController = TextEditingController(
      text: _endDate == null ? '' : _formatDate(_endDate!),
    );
    _startDateFocusNode = FocusNode()..addListener(_handleFocusChange);
    _endDateFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _startDateFocusNode.removeListener(_handleFocusChange);
    _endDateFocusNode.removeListener(_handleFocusChange);
    _startDateController.dispose();
    _endDateController.dispose();
    _startDateFocusNode.dispose();
    _endDateFocusNode.dispose();
    super.dispose();
  }

  _MyExcursionsFilters _draftFilters() => _MyExcursionsFilters(
    country: _country,
    city: _city,
    statuses: widget.tab == MyExcursionsTab.booked
        ? _statuses
        : const <String>{},
    reviewed: _reviewed,
    startDate: _startDate,
    endDate: _endDate,
  );

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  void _handleFocusChange() {
    if (_startDateFocusNode.hasFocus || _endDateFocusNode.hasFocus) {
      return;
    }
    _validateDateInputs(showIncompleteErrors: true);
  }

  DateTime? _parseDateInput(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length != 10) {
      return null;
    }

    final parts = normalized.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  String? _dateErrorFor(
    String value,
    DateTime? parsed, {
    required bool showIncompleteErrors,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length < 10) {
      return showIncompleteErrors
          ? widget.l10n.myActivitiesFilterInvalidDate
          : null;
    }
    if (parsed == null) {
      return widget.l10n.myActivitiesFilterInvalidDate;
    }
    return null;
  }

  bool _validateDateInputs({required bool showIncompleteErrors}) {
    final startParsed = _parseDateInput(_startDateController.text);
    final endParsed = _parseDateInput(_endDateController.text);

    var startError = _dateErrorFor(
      _startDateController.text,
      startParsed,
      showIncompleteErrors: showIncompleteErrors,
    );
    var endError = _dateErrorFor(
      _endDateController.text,
      endParsed,
      showIncompleteErrors: showIncompleteErrors,
    );

    if (startError == null &&
        endError == null &&
        startParsed != null &&
        endParsed != null &&
        endParsed.isBefore(startParsed)) {
      endError = widget.l10n.myActivitiesFilterInvalidRange;
    }

    setState(() {
      _startDate = startParsed;
      _endDate = endParsed;
      _startDateError = startError;
      _endDateError = endError;
    });

    return startError == null && endError == null;
  }

  void _handleDateChanged() {
    _validateDateInputs(showIncompleteErrors: false);
  }

  void _clearDate({required bool start}) {
    if (start) {
      _startDateController.clear();
    } else {
      _endDateController.clear();
    }
    _handleDateChanged();
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    if (!_validateDateInputs(showIncompleteErrors: true)) {
      return;
    }
    Navigator.of(context).pop(_draftFilters());
  }

  void _setCountry(AppCountryFilterValue? country) {
    setState(() {
      _country = country;
      _city = null;
    });
  }

  void _clear() {
    setState(() {
      _country = null;
      _city = null;
      _statuses = {};
      _reviewed = null;
      _startDateController.clear();
      _endDateController.clear();
      _startDate = null;
      _endDate = null;
      _startDateError = null;
      _endDateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final baseMaxHeight = size.height * 0.82;
    final availableSheetHeight = math.max(
      0.0,
      size.height - keyboardInset - MediaQuery.paddingOf(context).top - 16,
    );
    final maxHeight = math.min(baseMaxHeight, availableSheetHeight);
    final previewCount = widget.previewCountBuilder(_draftFilters());
    final showStatusFilter = widget.tab == MyExcursionsTab.booked;

    return AppDismissibleModalSheet(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF211609),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: widget.l10n.myExcursionsFilterTitle,
                clearLabel: widget.l10n.myActivitiesFilterClear,
                onClear: _clear,
              ),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCountryFilterSection(
                        title: widget.l10n.attractionFilterCountrySection,
                        allCountriesLabel:
                            widget.l10n.attractionFilterCountryAll,
                        searchHint:
                            widget.l10n.attractionFilterCountrySearchHint,
                        noResultsText:
                            widget.l10n.attractionFilterCountryNoResults,
                        selectedCountry: _country,
                        onChanged: _setCountry,
                      ),
                      if (_country != null) ...[
                        const SizedBox(height: 20),
                        AppCityFilterSection(
                          title: widget.l10n.locationFilterCitySection,
                          allCitiesLabel: widget.l10n.locationFilterAllCities,
                          searchHint: widget.l10n.locationFilterCitySearchHint,
                          noResultsText:
                              widget.l10n.locationFilterCityNoResults,
                          selectedCity: _city,
                          onChanged: (city) {
                            setState(() => _city = city);
                          },
                          countryCode: _country?.countryCode,
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (showStatusFilter) ...[
                        _FilterSectionTitle(
                          widget.l10n.myExcursionsFilterStatus,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoicePill(
                              label: widget.l10n.myExcursionsStatusRequested,
                              selected: _statuses.contains('REQUESTED'),
                              onTap: () => _toggleStatus('REQUESTED'),
                            ),
                            _ChoicePill(
                              label: widget.l10n.activityStatusCancelled,
                              selected: _statuses.contains('CANCELLED'),
                              onTap: () => _toggleStatus('CANCELLED'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      _FilterSectionTitle(widget.l10n.myExcursionsFilterReview),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChoicePill(
                            label: widget.l10n.myExcursionsFilterReviewAll,
                            selected: _reviewed == null,
                            onTap: () => setState(() => _reviewed = null),
                          ),
                          _ChoicePill(
                            label: widget.l10n.myExcursionsFilterUnreviewed,
                            selected: _reviewed == false,
                            onTap: () => setState(() => _reviewed = false),
                          ),
                          _ChoicePill(
                            label: widget.l10n.myExcursionsFilterReviewed,
                            selected: _reviewed == true,
                            onTap: () => setState(() => _reviewed = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _FilterSectionTitle(
                        widget.l10n.myActivitiesFilterDateRange,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useColumn = constraints.maxWidth < 390;
                          final fields = [
                            _FilterDateField(
                              label: widget.l10n.myActivitiesFilterStartDate,
                              controller: _startDateController,
                              focusNode: _startDateFocusNode,
                              hintText: widget
                                  .l10n
                                  .activitiesFilterStartDatePlaceholder,
                              errorText: _startDateError,
                              onChanged: (_) => _handleDateChanged(),
                              onSubmitted: (_) =>
                                  _endDateFocusNode.requestFocus(),
                              onClear: _startDateController.text.isEmpty
                                  ? null
                                  : () => _clearDate(start: true),
                              textInputAction: TextInputAction.next,
                            ),
                            _FilterDateField(
                              label: widget.l10n.myActivitiesFilterEndDate,
                              controller: _endDateController,
                              focusNode: _endDateFocusNode,
                              hintText: widget
                                  .l10n
                                  .activitiesFilterEndDatePlaceholder,
                              errorText: _endDateError,
                              onChanged: (_) => _handleDateChanged(),
                              onSubmitted: (_) => _applyFilters(),
                              onClear: _endDateController.text.isEmpty
                                  ? null
                                  : () => _clearDate(start: false),
                              textInputAction: TextInputAction.done,
                            ),
                          ];

                          if (useColumn) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 10),
                                fields[1],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 10),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + safeBottomInset),
                child: AppFilterApplyButton(
                  label: widget.l10n.excursionsFiltersShowResults(previewCount),
                  onTap: _applyFilters,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_statuses.contains(status)) {
        _statuses.remove(status);
      } else {
        _statuses.add(status);
      }
    });
  }
}

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent,
      backgroundColor: const Color(0xFF332416),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFFDCCAB7),
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    );
  }
}

class _FilterDateField extends StatelessWidget {
  const _FilterDateField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
    this.onClear,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String? errorText;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final hasValue = controller.text.isNotEmpty;
    final borderColor = errorText == null
        ? AppColors.accent.withValues(alpha: 0.28)
        : const Color(0xFFE28A7E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          inputFormatters: const [_DateTextInputFormatter()],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB8B0AA),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            errorText: errorText,
            errorMaxLines: 2,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.02),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            suffixIcon: hasValue
                ? IconButton(
                    onPressed: onClear,
                    splashRadius: 20,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFB8B0AA),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFFE28A7E),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFFE28A7E),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clampedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < clampedDigits.length; i++) {
      buffer.write(clampedDigits[i]);
      if ((i == 1 || i == 3) && i != clampedDigits.length - 1) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    final digitsBeforeSelection = newValue.selection.end <= 0
        ? 0
        : newValue.text
              .substring(0, newValue.selection.end)
              .replaceAll(RegExp(r'[^0-9]'), '')
              .length;

    var selectionOffset = 0;
    var seenDigits = 0;
    while (selectionOffset < formatted.length &&
        seenDigits < digitsBeforeSelection) {
      if (RegExp(r'[0-9]').hasMatch(formatted[selectionOffset])) {
        seenDigits++;
      }
      selectionOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

typedef _SubmitCombinedReview =
    Future<bool> Function(_CombinedReviewDraft draft);

class _ExcursionReviewSheet extends StatefulWidget {
  const _ExcursionReviewSheet({
    required this.l10n,
    required this.booking,
    required this.onSubmit,
    required this.onDeleteExcursionReview,
    required this.onDeleteGuideReview,
  });

  final AppLocalizations l10n;
  final ExcursionBookingVm booking;
  final _SubmitCombinedReview onSubmit;
  final Future<bool> Function()? onDeleteExcursionReview;
  final Future<bool> Function()? onDeleteGuideReview;

  @override
  State<_ExcursionReviewSheet> createState() => _ExcursionReviewSheetState();
}

class _ExcursionReviewSheetState extends State<_ExcursionReviewSheet> {
  late final TextEditingController _excursionCommentController;
  late final TextEditingController _guideCommentController;
  late double _excursionRating;
  late double _guideRating;
  late bool _includeExcursionReview;
  late bool _includeGuideReview;
  bool _submitting = false;
  bool _deletingExcursionReview = false;
  bool _deletingGuideReview = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _excursionRating = widget.booking.review?.rating ?? 5;
    _guideRating = widget.booking.guideReview?.rating ?? 5;
    _includeExcursionReview =
        widget.booking.review != null || widget.booking.guideReview == null;
    _includeGuideReview = widget.booking.guideReview != null;
    _excursionCommentController = TextEditingController(
      text: widget.booking.review?.comment ?? '',
    );
    _guideCommentController = TextEditingController(
      text: widget.booking.guideReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _excursionCommentController.dispose();
    _guideCommentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_includeExcursionReview && !_includeGuideReview) {
      setState(() {
        _errorText = widget.l10n.myExcursionsReviewSelectOneError;
      });
      return;
    }
    final excursionComment = _excursionCommentController.text.trim();
    final guideComment = _guideCommentController.text.trim();
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final success = await widget.onSubmit(
      _CombinedReviewDraft(
        excursion: _includeExcursionReview
            ? ReviewDraftRequest(
                rating: _excursionRating,
                comment: excursionComment,
              )
            : null,
        guide: _includeGuideReview
            ? ReviewDraftRequest(rating: _guideRating, comment: guideComment)
            : null,
      ),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _errorText = widget.l10n.myExcursionsReviewFailed;
    });
  }

  Future<void> _deleteExcursionReview() async {
    final delete = widget.onDeleteExcursionReview;
    if (delete == null) return;
    setState(() {
      _deletingExcursionReview = true;
      _errorText = null;
    });
    final success = await delete();
    if (!mounted) return;
    if (!success) {
      setState(() {
        _deletingExcursionReview = false;
        _errorText = widget.l10n.myExcursionsReviewDeleteFailed;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteGuideReview() async {
    final delete = widget.onDeleteGuideReview;
    if (delete == null) return;
    setState(() {
      _deletingGuideReview = true;
      _errorText = null;
    });
    final success = await delete();
    if (!mounted) return;
    if (!success) {
      setState(() {
        _deletingGuideReview = false;
        _errorText = widget.l10n.myExcursionsReviewDeleteFailed;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppDismissibleModalSheet(
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF211609),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              children: [
                Text(
                  widget.l10n.myExcursionsReviewTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.booking.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBB8A3),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _ReviewSectionCard(
                  title: widget.l10n.myExcursionsExcursionReviewSectionTitle,
                  subtitle:
                      widget.l10n.myExcursionsExcursionReviewSectionSubtitle,
                  rating: _excursionRating,
                  ratingTooltip: widget.l10n.myExcursionsReviewRating,
                  commentController: _excursionCommentController,
                  commentHint: widget.l10n.myExcursionsReviewHint,
                  enabled:
                      !_submitting &&
                      !_deletingExcursionReview &&
                      _includeExcursionReview,
                  optional: true,
                  included: _includeExcursionReview,
                  includeLabel: widget.l10n.myExcursionsExcursionReviewOptional,
                  onIncludedChanged: (value) {
                    setState(() {
                      _includeExcursionReview = value;
                      _errorText = null;
                    });
                  },
                  onRatingChanged: (value) {
                    setState(() => _excursionRating = value);
                  },
                  deleteLabel: widget.booking.review == null
                      ? null
                      : widget.l10n.myExcursionsReviewDeleteExcursion,
                  isDeleting: _deletingExcursionReview,
                  onDelete: widget.booking.review == null
                      ? null
                      : _deleteExcursionReview,
                ),
                const SizedBox(height: 14),
                _ReviewSectionCard(
                  title: widget.l10n.myExcursionsGuideReviewSectionTitle,
                  subtitle: widget.l10n.myExcursionsGuideReviewSectionSubtitle,
                  rating: _guideRating,
                  ratingTooltip: widget.l10n.myExcursionsGuideReviewRating,
                  commentController: _guideCommentController,
                  commentHint: widget.l10n.myExcursionsGuideReviewHint,
                  enabled:
                      !_submitting &&
                      !_deletingGuideReview &&
                      _includeGuideReview,
                  optional: true,
                  included: _includeGuideReview,
                  includeLabel: widget.l10n.myExcursionsGuideReviewOptional,
                  onIncludedChanged: (value) {
                    setState(() {
                      _includeGuideReview = value;
                      _errorText = null;
                    });
                  },
                  onRatingChanged: (value) {
                    setState(() => _guideRating = value);
                  },
                  deleteLabel: widget.booking.guideReview == null
                      ? null
                      : widget.l10n.myExcursionsReviewDeleteGuide,
                  isDeleting: _deletingGuideReview,
                  onDelete: widget.booking.guideReview == null
                      ? null
                      : _deleteGuideReview,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppFilterApplyButton(
                  label: widget.l10n.myExcursionsReviewPublish,
                  icon: Icons.send_rounded,
                  isLoading: _submitting,
                  onTap: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CombinedReviewDraft {
  const _CombinedReviewDraft({required this.excursion, required this.guide});

  final ReviewDraftRequest? excursion;
  final ReviewDraftRequest? guide;
}

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.ratingTooltip,
    required this.commentController,
    required this.commentHint,
    required this.enabled,
    required this.onRatingChanged,
    this.optional = false,
    this.included = true,
    this.includeLabel,
    this.onIncludedChanged,
    this.deleteLabel,
    this.isDeleting = false,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final double rating;
  final String ratingTooltip;
  final TextEditingController commentController;
  final String commentHint;
  final bool enabled;
  final ValueChanged<double> onRatingChanged;
  final bool optional;
  final bool included;
  final String? includeLabel;
  final ValueChanged<bool>? onIncludedChanged;
  final String? deleteLabel;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final active = !optional || included;
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFCBB8A3),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (optional)
                Switch.adaptive(
                  value: included,
                  activeThumbColor: AppColors.accent,
                  activeTrackColor: AppColors.accent.withValues(alpha: 0.28),
                  onChanged: onIncludedChanged,
                ),
            ],
          ),
          if (optional && includeLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              includeLabel!,
              style: const TextStyle(
                color: Color(0xFF9F8B7D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 2,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: ratingTooltip,
                onPressed: !enabled || !active
                    ? null
                    : () => onRatingChanged(value.toDouble()),
                icon: Icon(
                  value <= rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: active ? AppColors.accent : const Color(0xFF7D6D60),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: commentController,
            enabled: enabled && active,
            maxLines: 5,
            minLines: 3,
            maxLength: 600,
            cursorColor: AppColors.accent,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: commentHint,
              hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
              filled: true,
              fillColor: const Color(0xFF332416),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (deleteLabel != null && onDelete != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: !enabled || isDeleting ? null : onDelete,
              icon: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(deleteLabel!),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
