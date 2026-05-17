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
import '../../core/utils/pagination.dart';
import '../../features/excursions/models/create_excursion_review_request.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';

class MyExcursionsScreen extends StatefulWidget {
  const MyExcursionsScreen({super.key});

  @override
  State<MyExcursionsScreen> createState() => _MyExcursionsScreenState();
}

class _MyExcursionsScreenState extends State<MyExcursionsScreen> {
  static const int _pageSize = 8;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  MyExcursionsTab _activeTab = MyExcursionsTab.booked;
  MyExcursionBookingSortMode _sortMode = MyExcursionBookingSortMode.date;
  bool _sortAscending = false;
  _MyExcursionsFilters _filters = const _MyExcursionsFilters();
  String _searchQuery = '';
  int _bookedPage = 1;
  int _visitedPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcursionProvider>().loadMyExcursionBookings();
    });
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

  int get _activeFilterCount => _filters.activeCount;

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
          initialFilters: _filters,
          previewCountBuilder: (filters) {
            final now = DateTime.now().toUtc();
            return filterMyExcursionBookings(
              sourceItems,
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
          onSubmit: (rating, comment) async {
            final review = await provider.createExcursionReview(
              booking.id,
              CreateExcursionReviewRequest(rating: rating, comment: comment),
            );
            if (review == null) return false;
            await provider.loadExcursionReviews(productId: booking.productId);
            final landmarkId = booking.landmarkId?.trim();
            if (landmarkId != null && landmarkId.isNotEmpty) {
              await provider.loadExcursionReviews(landmarkId: landmarkId);
            }
            return true;
          },
        );
      },
    );

    if (!mounted || success != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.myExcursionsReviewSuccess)));
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
              final now = DateTime.now().toUtc();
              final filtered = filterMyExcursionBookings(
                provider.myExcursionBookings,
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
                            message: provider.bookingListErrorMessage ??
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
                            message: _activeTab == MyExcursionsTab.booked
                                ? l10n.myExcursionsBookedEmptyHint
                                : l10n.myExcursionsVisitedEmptyHint,
                          ),
                        ] else ...[
                          for (var i = 0; i < page.items.length; i++) ...[
                            Builder(
                              builder: (context) {
                                final booking = page.items[i];
                                return _MyExcursionBookingCard(
                                  booking: booking,
                                  onTap: () => _openDetails(booking),
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
                            FlyfyPaginationBar(
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
    this.statuses = const <String>{},
    this.reviewed,
    this.startDate,
    this.endDate,
  });

  final Set<String> statuses;
  final bool? reviewed;
  final DateTime? startDate;
  final DateTime? endDate;

  int get activeCount =>
      statuses.length +
      (reviewed == null ? 0 : 1) +
      (startDate == null ? 0 : 1) +
      (endDate == null ? 0 : 1);
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
        minimumSize: const Size(0, 42),
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
    required this.onTap,
    required this.onReviewTap,
  });

  final ExcursionBookingVm booking;
  final VoidCallback onTap;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMd(
      localeName,
    ).add_Hm().format(booking.scheduledFor.toLocal());
    final guide = booking.guideDisplayName.trim().isEmpty
        ? l10n.myExcursionsGuideFallback
        : booking.guideDisplayName.trim();
    final price = NumberFormat.compactCurrency(
      locale: localeName,
      name: booking.currency,
      symbol: booking.currency,
    ).format(booking.totalPriceAmount);

    return Material(
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
                          booking.title.isEmpty
                              ? l10n.myExcursionsUntitled
                              : booking.title,
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
              if ((booking.landmarkName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  booking.landmarkName!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCCAB7),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (onReviewTap != null || booking.isReviewed) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (booking.isReviewed)
                      Expanded(
                        child: _ReviewedBadge(rating: booking.review!.rating),
                      )
                    else
                      const Spacer(),
                    if (onReviewTap != null) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: onReviewTap,
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(l10n.myExcursionsReviewButton),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
    required this.initialFilters,
    required this.previewCountBuilder,
  });

  final AppLocalizations l10n;
  final _MyExcursionsFilters initialFilters;
  final int Function(_MyExcursionsFilters filters) previewCountBuilder;

  @override
  State<_MyExcursionsFilterSheet> createState() =>
      _MyExcursionsFilterSheetState();
}

class _MyExcursionsFilterSheetState extends State<_MyExcursionsFilterSheet> {
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
        statuses: _statuses,
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

  void _clear() {
    setState(() {
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
                                  .l10n.activitiesFilterStartDatePlaceholder,
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
                                  .l10n.activitiesFilterEndDatePlaceholder,
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
                  label: widget.l10n.excursionsFiltersShowResults(
                    previewCount,
                  ),
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
              borderSide: const BorderSide(
                color: AppColors.accent,
                width: 1.5,
              ),
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

typedef _SubmitExcursionReview = Future<bool> Function(
    double rating, String comment);

class _ExcursionReviewSheet extends StatefulWidget {
  const _ExcursionReviewSheet({
    required this.l10n,
    required this.booking,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final ExcursionBookingVm booking;
  final _SubmitExcursionReview onSubmit;

  @override
  State<_ExcursionReviewSheet> createState() => _ExcursionReviewSheetState();
}

class _ExcursionReviewSheetState extends State<_ExcursionReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.length < 4) {
      setState(() => _errorText = widget.l10n.myExcursionsReviewCommentError);
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final success = await widget.onSubmit(_rating, comment);
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

  @override
  Widget build(BuildContext context) {
    return AppDismissibleModalSheet(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF211609),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(color: Color(0xFFCBB8A3), height: 1.35),
              ),
              const SizedBox(height: 20),
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: widget.l10n.myExcursionsReviewRating,
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _rating = value.toDouble()),
                    icon: Icon(
                      value <= _rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.accent,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                enabled: !_submitting,
                maxLines: 5,
                minLines: 3,
                maxLength: 600,
                cursorColor: AppColors.accent,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.l10n.myExcursionsReviewHint,
                  hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
                  filled: true,
                  fillColor: const Color(0xFF332416),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _errorText,
                ),
              ),
              const SizedBox(height: 16),
              AppFilterApplyButton(
                label: widget.l10n.myExcursionsReviewPublish,
                icon: Icons.send_rounded,
                isLoading: _submitting,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
