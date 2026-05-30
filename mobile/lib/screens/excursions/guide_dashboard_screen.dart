import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/attendance_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../core/ui/app_list_screen_header.dart';
import '../../core/ui/pagination_bar.dart';
import '../../core/utils/pagination.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/excursion_currency.dart';
import '../../features/excursions/guide_dashboard_formatters.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';

enum GuideDashboardSection { offers, bookings }

enum GuideOfferDashboardTab { active, draft, review, archive, rejected }

enum GuideBookingDashboardTab { active, cancelled, completed }

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  static const int _pageSize = 6;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<GuideOfferDashboardTab, int> _offerPages = {
    for (final tab in GuideOfferDashboardTab.values) tab: 1,
  };
  final Map<GuideBookingDashboardTab, int> _bookingPages = {
    for (final tab in GuideBookingDashboardTab.values) tab: 1,
  };

  GuideDashboardSection _activeSection = GuideDashboardSection.offers;
  GuideOfferDashboardTab _activeOfferTab = GuideOfferDashboardTab.active;
  GuideBookingDashboardTab _activeBookingTab = GuideBookingDashboardTab.active;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcursionProvider>().loadGuideDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _activePage {
    return switch (_activeSection) {
      GuideDashboardSection.offers => _offerPages[_activeOfferTab] ?? 1,
      GuideDashboardSection.bookings => _bookingPages[_activeBookingTab] ?? 1,
    };
  }

  Future<void> _setActivePage(int page) async {
    if (page == _activePage) return;
    setState(() {
      switch (_activeSection) {
        case GuideDashboardSection.offers:
          _offerPages[_activeOfferTab] = page;
        case GuideDashboardSection.bookings:
          _bookingPages[_activeBookingTab] = page;
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

  void _setActiveSection(GuideDashboardSection section) {
    if (_activeSection == section) return;
    setState(() {
      _activeSection = section;
    });
  }

  void _setActiveOfferTab(GuideOfferDashboardTab tab) {
    if (_activeOfferTab == tab) return;
    setState(() {
      _activeOfferTab = tab;
      _offerPages[tab] = 1;
    });
  }

  void _setActiveBookingTab(GuideBookingDashboardTab tab) {
    if (_activeBookingTab == tab) return;
    setState(() {
      _activeBookingTab = tab;
      _bookingPages[tab] = 1;
    });
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (_searchQuery == nextQuery) return;
    setState(() {
      _searchQuery = nextQuery;
      _resetPages();
    });
  }

  void _resetPages() {
    for (final tab in GuideOfferDashboardTab.values) {
      _offerPages[tab] = 1;
    }
    for (final tab in GuideBookingDashboardTab.values) {
      _bookingPages[tab] = 1;
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/profile');
  }

  void _openCreateOffer() {
    context.push('/excursions/create');
  }

  void _openGuideCalendar() {
    context.push('/profile/guide-dashboard/calendar');
  }

  void _openGuideReviews() {
    context.push('/profile/guide-dashboard/reviews');
  }

  void _openOfferEditor(ExcursionVm excursion) {
    final editId = _editableExcursionId(excursion);
    if (editId.isEmpty) return;
    context.push(
      '/excursions/${Uri.encodeComponent(editId)}/edit',
      extra: excursion,
    );
  }

  Future<void> _openBookingDetailsSheet(
    ExcursionBookingVm booking,
    List<ExcursionBookingVm> relatedBookings,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuideBookingDetailsSheet(
        booking: booking,
        relatedBookings: relatedBookings,
      ),
    );
  }

  Future<void> _cancelBookedExcursion(
    ExcursionBookingVm booking,
    List<ExcursionBookingVm> relatedBookings,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final slotId = (booking.scheduleSlotId ?? '').trim();
    if (slotId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.guideDashboardCancelNoSlot)));
      return;
    }

    final refundAmount = _totalRevenue(relatedBookings);
    final refundCurrency = _primaryCurrency(relatedBookings);
    final reason = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuideCancelExcursionSheet(
        refundAmount: refundAmount,
        refundCurrency: refundCurrency,
      ),
    );
    if (!mounted || reason == null) return;

    final cancelled = await context
        .read<ExcursionProvider>()
        .cancelGuideExcursionSlot(slotId, reason: reason);
    if (!mounted) return;

    if (cancelled) {
      setState(() {
        _activeSection = GuideDashboardSection.bookings;
        _activeBookingTab = GuideBookingDashboardTab.cancelled;
        _bookingPages[GuideBookingDashboardTab.cancelled] = 1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.guideDashboardCancelSuccess)));
      return;
    }

    final provider = context.read<ExcursionProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.actionErrorMessage ?? l10n.guideDashboardCancelFailed,
        ),
      ),
    );
  }

  Future<void> _archiveOffer(ExcursionVm excursion) async {
    final excursionId = _editableExcursionId(excursion);
    if (excursionId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final archived = await context
        .read<ExcursionProvider>()
        .archiveExcursionOffer(excursionId);
    if (!mounted) return;
    if (archived) {
      setState(() {
        _activeSection = GuideDashboardSection.offers;
        _activeOfferTab = GuideOfferDashboardTab.archive;
        _offerPages[GuideOfferDashboardTab.archive] = 1;
      });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.guideDashboardArchiveFailed)));
  }

  Future<void> _deleteDraftOffer(ExcursionVm excursion) async {
    final excursionId = _editableExcursionId(excursion);
    if (excursionId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF21170D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0x293A270F)),
        ),
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C2118),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.accent,
            size: 27,
          ),
        ),
        title: Text(l10n.guideDashboardDeleteDraftTitle),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFF7EC),
          fontSize: 23,
          height: 1.12,
          fontWeight: FontWeight.w900,
        ),
        content: Text(l10n.guideDashboardDeleteDraftMessage),
        contentTextStyle: TextStyle(
          color: const Color(0xFFE0D4C6).withValues(alpha: 0.88),
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2C2118),
              foregroundColor: const Color(0xFFD8C7B7),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3B260D)),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: Text(l10n.guideDashboardDeleteDraftConfirm),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final provider = context.read<ExcursionProvider>();
    final deleted = await provider.deleteDraftExcursionOffer(excursionId);
    if (!mounted) return;

    if (deleted) {
      setState(() {
        _activeSection = GuideDashboardSection.offers;
        _activeOfferTab = GuideOfferDashboardTab.draft;
        _offerPages[GuideOfferDashboardTab.draft] = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.guideDashboardDeleteDraftSuccess)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.actionErrorMessage ?? l10n.guideDashboardDeleteDraftFailed,
        ),
      ),
    );
  }

  Future<void> _publishOffer(ExcursionVm excursion) async {
    final excursionId = _editableExcursionId(excursion);
    if (excursionId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final published = await provider.publishExcursionOffer(excursionId);
    if (!mounted) return;
    if (published) {
      final updatedOffer = _dashboardOfferAfterMutation(
        provider.myGuideExcursions,
        excursion,
      );
      setState(() {
        _activeSection = GuideDashboardSection.offers;
        _activeOfferTab = _offerTabForStatus(
          updatedOffer,
          fallback: GuideOfferDashboardTab.active,
        );
        _offerPages[_activeOfferTab] = 1;
      });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.guideDashboardPublishFailed)));
  }

  Future<void> _submitOfferForReview(ExcursionVm excursion) async {
    final excursionId = _editableExcursionId(excursion);
    if (excursionId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final submitted = await provider.publishExcursionOffer(excursionId);
    if (!mounted) return;
    if (submitted) {
      final updatedOffer = _dashboardOfferAfterMutation(
        provider.myGuideExcursions,
        excursion,
      );
      setState(() {
        _activeSection = GuideDashboardSection.offers;
        _activeOfferTab = _offerTabForStatus(
          updatedOffer,
          fallback: GuideOfferDashboardTab.review,
        );
        _offerPages[_activeOfferTab] = 1;
      });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.guideDashboardSubmitFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final maxWidth = screenWidth >= 840
        ? 680.0
        : screenWidth >= 600
            ? 540.0
            : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF160D07),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF211609), Color(0xFF160D07)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<ExcursionProvider>(
            builder: (context, provider, _) {
              final now = DateTime.now().toUtc();
              final filteredExcursions = _filterOffersBySearch(
                provider.myGuideExcursions,
                _searchQuery,
              );
              final filteredBookings = _filterBookingsBySearch(
                provider.myGuideExcursionBookings,
                _searchQuery,
              );
              final activeOffers = _activeOffers(filteredExcursions);
              final draftOffers = _draftOffers(filteredExcursions);
              final archivedOffers = _archivedOffers(filteredExcursions);
              final reviewOffers = _reviewOffers(filteredExcursions);
              final rejectedOffers = _rejectedOffers(filteredExcursions);
              final upcomingBookings = _upcomingBookings(filteredBookings, now);
              final completedBookings = _completedBookings(
                filteredBookings,
                now,
              );
              final cancelledBookings = _cancelledBookings(filteredBookings);
              final activeItemsCount = _activeItemCount(
                activeOffers: activeOffers,
                draftOffers: draftOffers,
                archivedOffers: archivedOffers,
                reviewOffers: reviewOffers,
                rejectedOffers: rejectedOffers,
                upcomingBookings: upcomingBookings,
                completedBookings: completedBookings,
                cancelledBookings: cancelledBookings,
              );
              final page = paginateItems<int>(
                List<int>.generate(activeItemsCount, (index) => index),
                currentPage: _activePage,
                pageSize: _pageSize,
              );
              final isInitialLoading =
                  provider.guideDashboardState == ExcursionListState.loading &&
                      provider.myGuideExcursions.isEmpty &&
                      provider.myGuideExcursionBookings.isEmpty;
              final isInitialError =
                  provider.guideDashboardState == ExcursionListState.error &&
                      provider.myGuideExcursions.isEmpty &&
                      provider.myGuideExcursionBookings.isEmpty;

              return RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: const Color(0xFF2A1D13),
                onRefresh: provider.refreshGuideDashboardData,
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
                        28 + safeBottom,
                      ),
                      children: [
                        AppListScreenHeader(
                          title: l10n.guideDashboardTitle,
                          notificationsTooltip:
                              l10n.profileNotificationsRowTitle,
                          onBackTap: _goBack,
                          onNotificationsTap: () =>
                              context.push('/notifications'),
                          horizontalPadding: 0,
                        ),
                        const SizedBox(height: 14),
                        _GuideDashboardQuickActions(
                          calendarLabel: l10n.guideCalendarTitle,
                          reviewsLabel: l10n.guideDashboardReviewsTitle,
                          onCalendarTap: _openGuideCalendar,
                          onReviewsTap: _openGuideReviews,
                        ),
                        const SizedBox(height: 22),
                        _GuideDashboardStats(
                          offersCount: provider.myGuideExcursions.length,
                          bookingsCount: _upcomingBookings(
                            provider.myGuideExcursionBookings,
                            now,
                          ).length,
                          revenueAmount: _totalRevenue(
                            provider.myGuideExcursionBookings,
                          ),
                          revenueCurrency: _primaryCurrency(
                            provider.myGuideExcursionBookings,
                          ),
                          rating: provider.myGuideProfile?.ratingAvg ?? 0,
                        ),
                        const SizedBox(height: 22),
                        _GuideDashboardSearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: l10n.guideDashboardSearchHint,
                        ),
                        const SizedBox(height: 26),
                        _GuideDashboardSectionTabs(
                          activeSection: _activeSection,
                          offersCount: filteredExcursions.length,
                          bookingsCount: filteredBookings.length,
                          onChanged: _setActiveSection,
                        ),
                        const SizedBox(height: 18),
                        _GuideDashboardSubTabs(
                          activeSection: _activeSection,
                          activeOfferTab: _activeOfferTab,
                          activeBookingTab: _activeBookingTab,
                          offerCounts: {
                            GuideOfferDashboardTab.active: activeOffers.length,
                            GuideOfferDashboardTab.draft: draftOffers.length,
                            GuideOfferDashboardTab.archive:
                                archivedOffers.length,
                            GuideOfferDashboardTab.rejected:
                                rejectedOffers.length,
                            GuideOfferDashboardTab.review: reviewOffers.length,
                          },
                          bookingCounts: {
                            GuideBookingDashboardTab.active:
                                upcomingBookings.length,
                            GuideBookingDashboardTab.cancelled:
                                cancelledBookings.length,
                            GuideBookingDashboardTab.completed:
                                completedBookings.length,
                          },
                          onOfferChanged: _setActiveOfferTab,
                          onBookingChanged: _setActiveBookingTab,
                        ),
                        const SizedBox(height: 24),
                        if (isInitialLoading) ...[
                          const _GuideDashboardSkeletonCard(),
                          const SizedBox(height: 16),
                          const _GuideDashboardSkeletonCard(),
                        ] else if (isInitialError) ...[
                          _GuideDashboardInfoCard(
                            icon: Icons.wifi_off_rounded,
                            title: l10n.guideDashboardLoadFailed,
                            message: provider.guideDashboardErrorMessage ??
                                l10n.guideDashboardLoadFailed,
                            actionLabel: l10n.retryButton,
                            onActionTap: provider.refreshGuideDashboardData,
                          ),
                        ] else if (activeItemsCount == 0) ...[
                          _GuideDashboardInfoCard(
                            icon: _emptyIconFor(
                              section: _activeSection,
                              offerTab: _activeOfferTab,
                              bookingTab: _activeBookingTab,
                            ),
                            title: _emptyTitleFor(
                              l10n,
                              section: _activeSection,
                              offerTab: _activeOfferTab,
                              bookingTab: _activeBookingTab,
                            ),
                            message: _emptyMessageFor(
                              l10n,
                              section: _activeSection,
                              offerTab: _activeOfferTab,
                              bookingTab: _activeBookingTab,
                            ),
                            actionLabel: _activeSection ==
                                        GuideDashboardSection.offers &&
                                    _activeOfferTab ==
                                        GuideOfferDashboardTab.active
                                ? l10n.guideDashboardCreateOffer
                                : null,
                            onActionTap: _activeSection ==
                                        GuideDashboardSection.offers &&
                                    _activeOfferTab ==
                                        GuideOfferDashboardTab.active
                                ? _openCreateOffer
                                : null,
                          ),
                        ] else ...[
                          ..._activeCards(
                            l10n: l10n,
                            now: now,
                            pageIndexes: page.items,
                            activeOffers: activeOffers,
                            draftOffers: draftOffers,
                            archivedOffers: archivedOffers,
                            reviewOffers: reviewOffers,
                            rejectedOffers: rejectedOffers,
                            upcomingBookings: upcomingBookings,
                            completedBookings: completedBookings,
                            cancelledBookings: cancelledBookings,
                            guideBookings: provider.myGuideExcursionBookings,
                          ),
                          if (page.hasMultiplePages) ...[
                            const SizedBox(height: 22),
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

  int _activeItemCount({
    required List<ExcursionVm> activeOffers,
    required List<ExcursionVm> draftOffers,
    required List<ExcursionVm> archivedOffers,
    required List<ExcursionVm> reviewOffers,
    required List<ExcursionVm> rejectedOffers,
    required List<ExcursionBookingVm> upcomingBookings,
    required List<ExcursionBookingVm> completedBookings,
    required List<ExcursionBookingVm> cancelledBookings,
  }) {
    return switch (_activeSection) {
      GuideDashboardSection.offers => switch (_activeOfferTab) {
          GuideOfferDashboardTab.active => activeOffers.length,
          GuideOfferDashboardTab.draft => draftOffers.length,
          GuideOfferDashboardTab.archive => archivedOffers.length,
          GuideOfferDashboardTab.rejected => rejectedOffers.length,
          GuideOfferDashboardTab.review => reviewOffers.length,
        },
      GuideDashboardSection.bookings => switch (_activeBookingTab) {
          GuideBookingDashboardTab.active => upcomingBookings.length,
          GuideBookingDashboardTab.cancelled => cancelledBookings.length,
          GuideBookingDashboardTab.completed => completedBookings.length,
        },
    };
  }

  List<Widget> _activeCards({
    required AppLocalizations l10n,
    required DateTime now,
    required List<int> pageIndexes,
    required List<ExcursionVm> activeOffers,
    required List<ExcursionVm> draftOffers,
    required List<ExcursionVm> archivedOffers,
    required List<ExcursionVm> reviewOffers,
    required List<ExcursionVm> rejectedOffers,
    required List<ExcursionBookingVm> upcomingBookings,
    required List<ExcursionBookingVm> completedBookings,
    required List<ExcursionBookingVm> cancelledBookings,
    required List<ExcursionBookingVm> guideBookings,
  }) {
    final cards = <Widget>[];
    for (final index in pageIndexes) {
      final Widget card = switch (_activeSection) {
        GuideDashboardSection.offers => _offerCardForActiveTab(
            l10n: l10n,
            index: index,
            activeOffers: activeOffers,
            draftOffers: draftOffers,
            archivedOffers: archivedOffers,
            reviewOffers: reviewOffers,
            rejectedOffers: rejectedOffers,
            guideBookings: guideBookings,
          ),
        GuideDashboardSection.bookings => _bookingCardForActiveTab(
            l10n: l10n,
            now: now,
            index: index,
            upcomingBookings: upcomingBookings,
            completedBookings: completedBookings,
            cancelledBookings: cancelledBookings,
            guideBookings: guideBookings,
          ),
      };
      cards.add(card);
      if (index != pageIndexes.last) {
        cards.add(const SizedBox(height: 18));
      }
    }
    return cards;
  }

  Widget _offerCardForActiveTab({
    required AppLocalizations l10n,
    required int index,
    required List<ExcursionVm> activeOffers,
    required List<ExcursionVm> draftOffers,
    required List<ExcursionVm> archivedOffers,
    required List<ExcursionVm> reviewOffers,
    required List<ExcursionVm> rejectedOffers,
    required List<ExcursionBookingVm> guideBookings,
  }) {
    return switch (_activeOfferTab) {
      GuideOfferDashboardTab.active => _GuideOfferCard(
          excursion: activeOffers[index],
          bookingCount:
              _bookingCountForOffer(activeOffers[index], guideBookings),
          statusLabel: l10n.guideDashboardStatusActive,
          actionLabel: l10n.guideDashboardEditOffer,
          secondaryActionLabel: l10n.guideDashboardArchiveOffer,
          onSecondaryActionTap: () => _archiveOffer(activeOffers[index]),
          onTap: () => _openOfferEditor(activeOffers[index]),
        ),
      GuideOfferDashboardTab.draft => _GuideOfferCard(
          excursion: draftOffers[index],
          bookingCount:
              _bookingCountForOffer(draftOffers[index], guideBookings),
          statusLabel: l10n.guideDashboardStatusDraft,
          actionLabel: l10n.guideDashboardEditOffer,
          secondaryActionLabel: l10n.guideDashboardSubmitOffer,
          onSecondaryActionTap: () => _submitOfferForReview(draftOffers[index]),
          destructiveActionLabel: l10n.guideDashboardDeleteDraftOffer,
          onDestructiveActionTap: () => _deleteDraftOffer(draftOffers[index]),
          muted: true,
          onTap: () => _openOfferEditor(draftOffers[index]),
        ),
      GuideOfferDashboardTab.archive => _GuideOfferCard(
          excursion: archivedOffers[index],
          bookingCount: _bookingCountForOffer(
            archivedOffers[index],
            guideBookings,
          ),
          statusLabel: l10n.guideDashboardStatusArchived,
          actionLabel: l10n.guideDashboardEditOffer,
          secondaryActionLabel: l10n.guideDashboardPublishOffer,
          onSecondaryActionTap: () => _publishOffer(archivedOffers[index]),
          muted: true,
          onTap: () => _openOfferEditor(archivedOffers[index]),
        ),
      GuideOfferDashboardTab.rejected => _GuideOfferCard(
          excursion: rejectedOffers[index],
          bookingCount: _bookingCountForOffer(
            rejectedOffers[index],
            guideBookings,
          ),
          statusLabel: l10n.guideDashboardStatusRejected,
          actionLabel: l10n.guideDashboardViewDetails,
          secondaryActionLabel: l10n.guideDashboardSubmitOffer,
          onSecondaryActionTap: () =>
              _submitOfferForReview(rejectedOffers[index]),
          muted: true,
          onTap: () => _openOfferEditor(rejectedOffers[index]),
        ),
      GuideOfferDashboardTab.review => _GuideOfferCard(
          excursion: reviewOffers[index],
          bookingCount:
              _bookingCountForOffer(reviewOffers[index], guideBookings),
          statusLabel: l10n.guideDashboardStatusReview,
          actionLabel: l10n.guideDashboardViewDetails,
          muted: true,
          onTap: () => _openOfferEditor(reviewOffers[index]),
        ),
    };
  }

  Widget _bookingCardForActiveTab({
    required AppLocalizations l10n,
    required DateTime now,
    required int index,
    required List<ExcursionBookingVm> upcomingBookings,
    required List<ExcursionBookingVm> completedBookings,
    required List<ExcursionBookingVm> cancelledBookings,
    required List<ExcursionBookingVm> guideBookings,
  }) {
    switch (_activeBookingTab) {
      case GuideBookingDashboardTab.active:
        final booking = upcomingBookings[index];
        final relatedBookings = _relatedBookingsFor(booking, guideBookings);
        final canCancel = booking.canBeCancelledByGuide(now);
        return _GuideBookingCard(
          booking: booking,
          now: now,
          relatedBookings: relatedBookings,
          statusLabel: l10n.guideDashboardStatusBooked,
          actionLabel: l10n.guideDashboardViewBooking,
          secondaryActionLabel:
              canCancel ? l10n.guideDashboardCancelExcursion : null,
          onSecondaryActionTap: canCancel
              ? () => _cancelBookedExcursion(booking, relatedBookings)
              : null,
          onTap: () => _openBookingDetailsSheet(booking, relatedBookings),
        );
      case GuideBookingDashboardTab.cancelled:
        final booking = cancelledBookings[index];
        final relatedBookings = _relatedBookingsFor(booking, guideBookings);
        return _GuideBookingCard(
          booking: booking,
          now: now,
          relatedBookings: relatedBookings,
          statusLabel: l10n.guideDashboardStatusCancelled,
          actionLabel: l10n.guideDashboardViewDetails,
          muted: true,
          onTap: () => _openBookingDetailsSheet(booking, relatedBookings),
        );
      case GuideBookingDashboardTab.completed:
        final booking = completedBookings[index];
        final relatedBookings = _relatedBookingsFor(booking, guideBookings);
        return _GuideBookingCard(
          booking: booking,
          now: now,
          relatedBookings: relatedBookings,
          statusLabel: l10n.guideDashboardStatusCompleted,
          actionLabel: l10n.guideDashboardViewDetails,
          muted: true,
          onTap: () => _openBookingDetailsSheet(booking, relatedBookings),
        );
    }
  }
}

List<ExcursionVm> _activeOffers(List<ExcursionVm> items) {
  final result = items.where(_isPublishedPublicOffer).toList(growable: false);
  result.sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
  return result;
}

List<ExcursionVm> _archivedOffers(List<ExcursionVm> items) {
  final result = items.where(_isArchivedOffer).toList(growable: false);
  result.sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
  return result;
}

List<ExcursionVm> _draftOffers(List<ExcursionVm> items) {
  final result = items.where(_isDraftOffer).toList(growable: false);
  result.sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
  return result;
}

List<ExcursionVm> _reviewOffers(List<ExcursionVm> items) {
  final result = items.where(_isReviewOffer).toList(growable: false);
  result.sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
  return result;
}

List<ExcursionVm> _rejectedOffers(List<ExcursionVm> items) {
  final result = items.where(_isRejectedOffer).toList(growable: false);
  result.sort((a, b) => b.createdAtOrEpoch.compareTo(a.createdAtOrEpoch));
  return result;
}

List<ExcursionBookingVm> _upcomingBookings(
  List<ExcursionBookingVm> items,
  DateTime now,
) {
  final result = items.where((item) => item.isBooked(now)).toList();
  result.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  return result;
}

List<ExcursionBookingVm> _completedBookings(
  List<ExcursionBookingVm> items,
  DateTime now,
) {
  final result = items.where((item) => item.isVisited(now)).toList();
  result.sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
  return result;
}

List<ExcursionBookingVm> _cancelledBookings(List<ExcursionBookingVm> items) {
  final result = items.where((item) => item.isCancelled).toList();
  result.sort((a, b) {
    final left = b.updatedAt ?? b.createdAt ?? b.scheduledFor;
    final right = a.updatedAt ?? a.createdAt ?? a.scheduledFor;
    return left.compareTo(right);
  });
  return result;
}

List<ExcursionBookingVm> _relatedBookingsFor(
  ExcursionBookingVm booking,
  List<ExcursionBookingVm> bookings,
) {
  final slotId = (booking.scheduleSlotId ?? '').trim();
  final related = bookings.where((item) {
    if (slotId.isNotEmpty) {
      return (item.scheduleSlotId ?? '').trim() == slotId;
    }
    return item.productId == booking.productId &&
        item.offerId == booking.offerId &&
        item.scheduledFor.toUtc().isAtSameMomentAs(
              booking.scheduledFor.toUtc(),
            );
  }).toList(growable: false);

  if (related.isEmpty) return [booking];
  related.sort((a, b) {
    return _bookingCreatedAtOrEpoch(a).compareTo(_bookingCreatedAtOrEpoch(b));
  });
  return related;
}

bool _hasGuideBookingSlot(
  ExcursionBookingVm booking,
  List<ExcursionBookingVm> relatedBookings,
) {
  if ((booking.scheduleSlotId ?? '').trim().isNotEmpty) return true;
  return relatedBookings.any(
    (item) => (item.scheduleSlotId ?? '').trim().isNotEmpty,
  );
}

List<ExcursionBookingVm> _effectiveGuideBookingAuthors({
  required ExcursionBookingVm booking,
  required List<ExcursionBookingVm> relatedBookings,
  required List<ExcursionBookingVm> providerBookings,
}) {
  final fallbackBookings =
      relatedBookings.isEmpty ? [booking] : relatedBookings;
  final slotIds = fallbackBookings
      .map((item) => (item.scheduleSlotId ?? '').trim())
      .where((slotId) => slotId.isNotEmpty)
      .toSet();
  if (slotIds.isEmpty) return fallbackBookings;

  final refreshed = providerBookings.where((item) {
    return slotIds.contains((item.scheduleSlotId ?? '').trim());
  }).toList(growable: false);
  if (refreshed.isEmpty) return fallbackBookings;

  refreshed.sort((a, b) {
    return _bookingCreatedAtOrEpoch(a).compareTo(_bookingCreatedAtOrEpoch(b));
  });
  return refreshed;
}

DateTime _bookingCreatedAtOrEpoch(ExcursionBookingVm booking) {
  return booking.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

List<ExcursionVm> _filterOffersBySearch(List<ExcursionVm> items, String query) {
  if (query.trim().isEmpty) return items;
  return items.where((item) {
    return _matchesSmartQuery(query, [
      item.title,
      item.summary,
      item.description,
      item.landmarkName,
      item.cityName,
      item.countryCode,
      item.categorySlug,
      item.status,
      item.visibility,
      item.currency,
      item.priceAmount,
      item.maxGroupSize,
      item.meetingPoint,
      item.tags.join(' '),
      item.languageCodes.join(' '),
      item.primaryOffer?.id,
      item.primaryOffer?.legacyExcursionId,
      item.id,
    ]);
  }).toList(growable: false);
}

List<ExcursionBookingVm> _filterBookingsBySearch(
  List<ExcursionBookingVm> items,
  String query,
) {
  if (query.trim().isEmpty) return items;
  return items.where((item) {
    return _matchesSmartQuery(query, [
      item.title,
      item.summary,
      item.guideDisplayName,
      item.landmarkName,
      item.cityName,
      item.countryCode,
      item.categorySlug,
      item.status,
      item.currency,
      item.totalPriceAmount,
      item.totalSeats,
      item.scheduledFor.toIso8601String(),
      item.createdAt?.toIso8601String(),
      item.updatedAt?.toIso8601String(),
      item.id,
      item.productId,
      item.offerId,
      item.legacyExcursionId,
    ]);
  }).toList(growable: false);
}

bool _isPublishedPublicOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'PUBLISHED' &&
      excursion.visibility.trim().toUpperCase() == 'PUBLIC';
}

bool _isArchivedOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'ARCHIVED';
}

bool _isDraftOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase() == 'DRAFT';
}

bool _isReviewOffer(ExcursionVm excursion) {
  final status = excursion.status.trim().toUpperCase();
  if (status.isEmpty) return false;
  if (_isPublishedPublicOffer(excursion) ||
      _isDraftOffer(excursion) ||
      _isArchivedOffer(excursion) ||
      _isRejectedOffer(excursion) ||
      _isCancelledOffer(excursion)) {
    return false;
  }
  return status.contains('REVIEW') ||
      status.contains('MODERAT') ||
      status == 'PENDING';
}

bool _isRejectedOffer(ExcursionVm excursion) {
  final status = excursion.status.trim().toUpperCase();
  return status.contains('REJECT') || status.contains('DECLIN');
}

String _editableExcursionId(ExcursionVm excursion) {
  final legacyId = excursion.primaryOffer?.legacyExcursionId?.trim() ?? '';
  if (legacyId.isNotEmpty) return legacyId;
  return excursion.id.trim();
}

ExcursionVm _dashboardOfferAfterMutation(
  List<ExcursionVm> items,
  ExcursionVm fallback,
) {
  final fallbackId = _editableExcursionId(fallback);
  if (fallbackId.isEmpty) return fallback;
  for (final item in items) {
    if (_editableExcursionId(item) == fallbackId) {
      return item;
    }
  }
  return fallback;
}

GuideOfferDashboardTab _offerTabForStatus(
  ExcursionVm excursion, {
  required GuideOfferDashboardTab fallback,
}) {
  if (_isPublishedPublicOffer(excursion)) return GuideOfferDashboardTab.active;
  if (_isDraftOffer(excursion)) return GuideOfferDashboardTab.draft;
  if (_isArchivedOffer(excursion)) return GuideOfferDashboardTab.archive;
  if (_isRejectedOffer(excursion)) return GuideOfferDashboardTab.rejected;
  if (_isReviewOffer(excursion)) return GuideOfferDashboardTab.review;
  return fallback;
}

bool _isCancelledOffer(ExcursionVm excursion) {
  return excursion.status.trim().toUpperCase().contains('CANCEL');
}

int _bookingCountForOffer(
  ExcursionVm excursion,
  List<ExcursionBookingVm> bookings,
) {
  final identities = <String>{};
  void addIdentity(String? value) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      identities.add(normalized);
    }
  }

  addIdentity(excursion.id);
  addIdentity(excursion.primaryOffer?.id);
  addIdentity(excursion.primaryOffer?.legacyExcursionId);
  for (final offer in excursion.offers) {
    addIdentity(offer.id);
    addIdentity(offer.legacyExcursionId);
  }

  if (identities.isEmpty) return 0;

  return bookings.where((booking) {
    if (booking.isCancelled) return false;
    return identities.contains(booking.productId.trim()) ||
        identities.contains(booking.offerId.trim()) ||
        identities.contains(booking.legacyExcursionId?.trim());
  }).length;
}

bool _matchesSmartQuery(String query, Iterable<Object?> values) {
  final tokens = _normalizeGuideDashboardSearchText(
    query,
  ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
  if (tokens.isEmpty) return true;

  final haystack = values
      .whereType<Object>()
      .map((value) => _normalizeGuideDashboardSearchText('$value'))
      .where((value) => value.isNotEmpty)
      .join(' ');
  return tokens.every(haystack.contains);
}

String _normalizeGuideDashboardSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-/.,:;]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

double _totalRevenue(List<ExcursionBookingVm> bookings) {
  return bookings
      .where((booking) => !booking.isCancelled)
      .fold<double>(0, (sum, booking) => sum + booking.totalPriceAmount);
}

String _primaryCurrency(List<ExcursionBookingVm> bookings) {
  for (final booking in bookings) {
    final currency = booking.currency.trim();
    if (currency.isNotEmpty) return currency;
  }
  return 'KZT';
}

IconData _emptyIconFor({
  required GuideDashboardSection section,
  required GuideOfferDashboardTab offerTab,
  required GuideBookingDashboardTab bookingTab,
}) {
  return switch (section) {
    GuideDashboardSection.offers => switch (offerTab) {
        GuideOfferDashboardTab.active => Icons.explore_outlined,
        GuideOfferDashboardTab.draft => Icons.edit_note_rounded,
        GuideOfferDashboardTab.archive => Icons.inventory_2_outlined,
        GuideOfferDashboardTab.rejected => Icons.block_rounded,
        GuideOfferDashboardTab.review => Icons.manage_search_rounded,
      },
    GuideDashboardSection.bookings => switch (bookingTab) {
        GuideBookingDashboardTab.active => Icons.confirmation_number_outlined,
        GuideBookingDashboardTab.cancelled => Icons.event_busy_rounded,
        GuideBookingDashboardTab.completed => Icons.task_alt_rounded,
      },
  };
}

String _emptyTitleFor(
  AppLocalizations l10n, {
  required GuideDashboardSection section,
  required GuideOfferDashboardTab offerTab,
  required GuideBookingDashboardTab bookingTab,
}) {
  return switch (section) {
    GuideDashboardSection.offers => switch (offerTab) {
        GuideOfferDashboardTab.active => l10n.guideDashboardOffersEmpty,
        GuideOfferDashboardTab.draft => l10n.guideDashboardDraftEmpty,
        GuideOfferDashboardTab.archive => l10n.guideDashboardArchiveEmpty,
        GuideOfferDashboardTab.rejected => l10n.guideDashboardRejectedEmpty,
        GuideOfferDashboardTab.review => l10n.guideDashboardReviewEmpty,
      },
    GuideDashboardSection.bookings => switch (bookingTab) {
        GuideBookingDashboardTab.active => l10n.guideDashboardBookingsEmpty,
        GuideBookingDashboardTab.cancelled => l10n.guideDashboardCancelledEmpty,
        GuideBookingDashboardTab.completed => l10n.guideDashboardCompletedEmpty,
      },
  };
}

String _emptyMessageFor(
  AppLocalizations l10n, {
  required GuideDashboardSection section,
  required GuideOfferDashboardTab offerTab,
  required GuideBookingDashboardTab bookingTab,
}) {
  return switch (section) {
    GuideDashboardSection.offers => switch (offerTab) {
        GuideOfferDashboardTab.active => l10n.guideDashboardOffersEmptyHint,
        GuideOfferDashboardTab.draft => l10n.guideDashboardDraftEmptyHint,
        GuideOfferDashboardTab.archive => l10n.guideDashboardArchiveEmptyHint,
        GuideOfferDashboardTab.rejected => l10n.guideDashboardRejectedEmptyHint,
        GuideOfferDashboardTab.review => l10n.guideDashboardReviewEmptyHint,
      },
    GuideDashboardSection.bookings => switch (bookingTab) {
        GuideBookingDashboardTab.active => l10n.guideDashboardBookingsEmptyHint,
        GuideBookingDashboardTab.cancelled =>
          l10n.guideDashboardCancelledEmptyHint,
        GuideBookingDashboardTab.completed =>
          l10n.guideDashboardCompletedEmptyHint,
      },
  };
}

extension on ExcursionVm {
  DateTime get createdAtOrEpoch =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class _GuideDashboardStats extends StatelessWidget {
  const _GuideDashboardStats({
    required this.offersCount,
    required this.bookingsCount,
    required this.revenueAmount,
    required this.revenueCurrency,
    required this.rating,
  });

  final int offersCount;
  final int bookingsCount;
  final double revenueAmount;
  final String revenueCurrency;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final revenue = formatGuideDashboardRevenue(
      amount: revenueAmount,
      currency: revenueCurrency,
      localeName: localeName,
    );
    final ratingLabel = rating <= 0 ? '0.0' : rating.toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 340;
        final spacing = useSingleColumn ? 10.0 : 14.0;
        final itemWidth = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _GuideStatCard(
                label: l10n.guideDashboardOffersStat,
                value: '$offersCount',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _GuideStatCard(
                label: l10n.guideDashboardBookingsStat,
                value: '$bookingsCount',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _GuideStatCard(
                label: l10n.guideDashboardRevenueStat,
                value: revenue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _GuideStatCard(
                label: l10n.guideDashboardRatingStat,
                value: ratingLabel,
                suffix: Icons.star_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuideStatCard extends StatelessWidget {
  const _GuideStatCard({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final IconData? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD3BFA9),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Icon(suffix, color: AppColors.accent, size: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideDashboardSearchField extends StatelessWidget {
  const _GuideDashboardSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFD3BFA9),
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.trim().isEmpty) {
                return const SizedBox(width: 12);
              }
              return IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFFD3BFA9),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _GuideDashboardQuickActions extends StatelessWidget {
  const _GuideDashboardQuickActions({
    required this.calendarLabel,
    required this.reviewsLabel,
    required this.onCalendarTap,
    required this.onReviewsTap,
  });

  final String calendarLabel;
  final String reviewsLabel;
  final VoidCallback onCalendarTap;
  final VoidCallback onReviewsTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions = constraints.maxWidth < 380;
        final tiles = [
          _GuideDashboardActionTile(
            icon: Icons.calendar_month_rounded,
            label: calendarLabel,
            onTap: onCalendarTap,
          ),
          _GuideDashboardActionTile(
            icon: Icons.reviews_rounded,
            label: reviewsLabel,
            onTap: onReviewsTap,
          ),
        ];

        if (stackActions) {
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        );
      },
    );
  }
}

class _GuideDashboardActionTile extends StatelessWidget {
  const _GuideDashboardActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1D13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD3BFA9),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideDashboardSectionTabs extends StatelessWidget {
  const _GuideDashboardSectionTabs({
    required this.activeSection,
    required this.offersCount,
    required this.bookingsCount,
    required this.onChanged,
  });

  final GuideDashboardSection activeSection;
  final int offersCount;
  final int bookingsCount;
  final ValueChanged<GuideDashboardSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (GuideDashboardSection.offers, l10n.guideDashboardOffersTab, offersCount),
      (
        GuideDashboardSection.bookings,
        l10n.guideDashboardBookingsTab,
        bookingsCount,
      ),
    ];

    return _GuideHorizontalTabs(
      children: [
        for (final tab in tabs)
          _GuideTabButton(
            label: tab.$2,
            count: tab.$3,
            active: activeSection == tab.$1,
            onTap: () => onChanged(tab.$1),
          ),
      ],
    );
  }
}

class _GuideDashboardSubTabs extends StatelessWidget {
  const _GuideDashboardSubTabs({
    required this.activeSection,
    required this.activeOfferTab,
    required this.activeBookingTab,
    required this.offerCounts,
    required this.bookingCounts,
    required this.onOfferChanged,
    required this.onBookingChanged,
  });

  final GuideDashboardSection activeSection;
  final GuideOfferDashboardTab activeOfferTab;
  final GuideBookingDashboardTab activeBookingTab;
  final Map<GuideOfferDashboardTab, int> offerCounts;
  final Map<GuideBookingDashboardTab, int> bookingCounts;
  final ValueChanged<GuideOfferDashboardTab> onOfferChanged;
  final ValueChanged<GuideBookingDashboardTab> onBookingChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offerTabs = [
      (GuideOfferDashboardTab.active, l10n.guideDashboardActiveTab),
      (GuideOfferDashboardTab.draft, l10n.guideDashboardDraftTab),
      (GuideOfferDashboardTab.review, l10n.guideDashboardReviewTab),
      (GuideOfferDashboardTab.archive, l10n.guideDashboardArchiveTab),
      (GuideOfferDashboardTab.rejected, l10n.guideDashboardRejectedTab),
    ];
    final bookingTabs = [
      (GuideBookingDashboardTab.active, l10n.guideDashboardActiveTab),
      (GuideBookingDashboardTab.cancelled, l10n.guideDashboardCancelledTab),
      (GuideBookingDashboardTab.completed, l10n.guideDashboardCompletedTab),
    ];

    return _GuideHorizontalTabs(
      children: switch (activeSection) {
        GuideDashboardSection.offers => [
            for (final tab in offerTabs)
              _GuideTabButton(
                label: tab.$2,
                count: offerCounts[tab.$1] ?? 0,
                active: activeOfferTab == tab.$1,
                onTap: () => onOfferChanged(tab.$1),
              ),
          ],
        GuideDashboardSection.bookings => [
            for (final tab in bookingTabs)
              _GuideTabButton(
                label: tab.$2,
                count: bookingCounts[tab.$1] ?? 0,
                active: activeBookingTab == tab.$1,
                onTap: () => onBookingChanged(tab.$1),
              ),
          ],
      },
    );
  }
}

class _GuideHorizontalTabs extends StatelessWidget {
  const _GuideHorizontalTabs({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final child in children) ...[child, const SizedBox(width: 24)],
          ],
        ),
      ),
    );
  }
}

class _GuideTabButton extends StatelessWidget {
  const _GuideTabButton({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : const Color(0xFFD3BFA9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color.withValues(alpha: active ? 0.92 : 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: active ? 64 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideOfferCard extends StatelessWidget {
  const _GuideOfferCard({
    required this.excursion,
    required this.bookingCount,
    required this.statusLabel,
    required this.actionLabel,
    required this.onTap,
    this.secondaryActionLabel,
    this.onSecondaryActionTap,
    this.destructiveActionLabel,
    this.onDestructiveActionTap,
    this.muted = false,
  });

  final ExcursionVm excursion;
  final int bookingCount;
  final String statusLabel;
  final String actionLabel;
  final VoidCallback onTap;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryActionTap;
  final String? destructiveActionLabel;
  final VoidCallback? onDestructiveActionTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final price = formatLocalizedExcursionMoney(
      amount: excursion.priceAmount,
      currency: excursion.currency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );
    final maxGroupLabel = excursion.maxGroupSize > 0
        ? l10n.guideDashboardMaxGuests(excursion.maxGroupSize)
        : l10n.guideDashboardFlexibleGroup;

    return _GuideJourneyCard(
      title: excursion.title.trim().isEmpty
          ? l10n.myExcursionsUntitled
          : excursion.title.trim(),
      statusLabel: statusLabel,
      actionLabel: actionLabel,
      muted: muted,
      imageUrl: resolveOwnedExcursionCoverUrl(excursion),
      categorySlug: excursion.categorySlug,
      seed: excursion.id.hashCode,
      onTap: onTap,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryActionTap: onSecondaryActionTap,
      destructiveActionLabel: destructiveActionLabel,
      onDestructiveActionTap: onDestructiveActionTap,
      meta: [
        _GuideMetaData(
          icon: Icons.confirmation_number_outlined,
          label: l10n.guideDashboardBookingCount(bookingCount),
        ),
        _GuideMetaData(icon: Icons.group_rounded, label: maxGroupLabel),
        _GuideMetaData(icon: Icons.payments_outlined, label: price),
      ],
    );
  }
}

class _GuideBookingCard extends StatelessWidget {
  const _GuideBookingCard({
    required this.booking,
    required this.now,
    required this.relatedBookings,
    required this.statusLabel,
    required this.actionLabel,
    required this.onTap,
    this.secondaryActionLabel,
    this.onSecondaryActionTap,
    this.muted = false,
  });

  final ExcursionBookingVm booking;
  final DateTime now;
  final List<ExcursionBookingVm> relatedBookings;
  final String statusLabel;
  final String actionLabel;
  final VoidCallback onTap;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryActionTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = DateFormat.yMMMd(
      localeName,
    ).add_Hm().format(booking.scheduledFor.toLocal());
    final price = formatLocalizedExcursionMoney(
      amount: booking.totalPriceAmount,
      currency: booking.currency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );
    final scheduleSlotId = (booking.scheduleSlotId ?? '').trim();
    final showAttendanceQr = booking.canShowAttendanceQr(now);

    return _GuideJourneyCard(
      title: booking.title.trim().isEmpty
          ? l10n.myExcursionsUntitled
          : booking.title.trim(),
      statusLabel: booking.isCancelled
          ? l10n.guideDashboardStatusCancelled
          : statusLabel,
      actionLabel: actionLabel,
      muted: muted || booking.isCancelled,
      imageUrl: resolveExcursionBookingCoverUrl(booking),
      categorySlug: booking.categorySlug,
      seed: booking.productId.hashCode,
      onTap: onTap,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryActionTap: onSecondaryActionTap,
      actionFooter: showAttendanceQr
          ? _ExcursionAttendanceQrAction(
              scheduleSlotId: scheduleSlotId,
              relatedBookings: relatedBookings,
            )
          : null,
      stackSecondaryAction: true,
      meta: [
        _GuideMetaData(icon: Icons.event_rounded, label: dateLabel),
        _GuideMetaData(
          icon: Icons.group_rounded,
          label: l10n.myExcursionsGuests(booking.totalSeats),
        ),
        _GuideMetaData(icon: Icons.payments_outlined, label: price),
      ],
      subtitle: (booking.landmarkName ?? '').trim(),
    );
  }
}

class _ExcursionAttendanceQrAction extends StatelessWidget {
  const _ExcursionAttendanceQrAction({
    required this.scheduleSlotId,
    required this.relatedBookings,
  });

  final String scheduleSlotId;
  final List<ExcursionBookingVm> relatedBookings;

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExcursionAttendanceQrSheet(
        scheduleSlotId: scheduleSlotId,
        relatedBookings: relatedBookings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(
          l10n.guideDashboardShowAttendanceQr.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFD6A3),
          side: BorderSide(
            color: const Color(0xFFFFD6A3).withValues(alpha: 0.38),
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ExcursionAttendanceQrSheet extends StatefulWidget {
  const _ExcursionAttendanceQrSheet({
    required this.scheduleSlotId,
    required this.relatedBookings,
  });

  final String scheduleSlotId;
  final List<ExcursionBookingVm> relatedBookings;

  @override
  State<_ExcursionAttendanceQrSheet> createState() =>
      _ExcursionAttendanceQrSheetState();
}

class _ExcursionAttendanceQrSheetState
    extends State<_ExcursionAttendanceQrSheet> {
  final AttendanceApi _attendanceApi = AttendanceApi();

  Timer? _refreshTimer;
  Timer? _countdownTimer;
  Timer? _participantRefreshTimer;
  bool _isLoading = false;
  bool _isRefreshingParticipants = false;
  String? _token;
  String? _error;
  DateTime? _refreshAt;

  @override
  void initState() {
    super.initState();
    _loadQr();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshParticipants());
    });
    _participantRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshParticipants()),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _participantRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ExcursionAttendanceQrSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scheduleSlotId == widget.scheduleSlotId) {
      return;
    }
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _isLoading = false;
    _token = null;
    _error = null;
    _refreshAt = null;
    unawaited(_loadQr());
  }

  Future<void> _refreshParticipants() async {
    if (!mounted || _isRefreshingParticipants) return;
    _isRefreshingParticipants = true;
    try {
      await context.read<ExcursionProvider>().refreshGuideDashboardData();
    } finally {
      _isRefreshingParticipants = false;
    }
  }

  Future<void> _loadQr() async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final qr = await _attendanceApi.getExcursionAttendanceQr(
        widget.scheduleSlotId,
      );
      if (!mounted) return;
      setState(() {
        _token = qr.token;
        _refreshAt = qr.refreshAt;
        _isLoading = false;
      });
      _scheduleRefresh(qr.refreshAt);
      _restartCountdownTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'failed';
        _isLoading = false;
      });
    }
  }

  void _scheduleRefresh(DateTime refreshAt) {
    _refreshTimer?.cancel();
    final delay = refreshAt.difference(DateTime.now().toUtc());
    _refreshTimer = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      _loadQr,
    );
  }

  void _restartCountdownTicker() {
    _countdownTimer?.cancel();
    if (_refreshAt == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  String _countdownLabel(AppLocalizations l10n) {
    final refreshAt = _refreshAt;
    if (refreshAt == null) return '';
    final remaining = refreshAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      return l10n.activityAttendanceQrRefreshing;
    }
    return l10n.activityAttendanceQrExpiresIn(
      remaining.inSeconds.clamp(0, 999).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 390;
    final bottomLift = mediaQuery.padding.bottom + 18;

    return AppDismissibleModalSheet(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: mediaQuery.viewInsets.bottom + bottomLift,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: mediaQuery.size.height * 0.82,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF92A190D), Color(0xFA180E08)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 36,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                14,
                compact ? 16 : 20,
                22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.guideDashboardShowAttendanceQr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: compact ? 21 : 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFD3BFA9),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildQrBody(l10n),
                  const SizedBox(height: 18),
                  _GuideAttendanceParticipantStatusList(
                    scheduleSlotId: widget.scheduleSlotId,
                    fallbackBookings: widget.relatedBookings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_error != null || (_token ?? '').isEmpty) {
      return Column(
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.accent,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.activityAttendanceQrLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadQr, child: Text(l10n.retryButton)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final qrSize = (constraints.maxWidth - 40).clamp(160.0, 220.0);
        return Column(
          children: [
            Container(
              width: qrSize,
              height: qrSize,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: _token!,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  color: Colors.black,
                  dataModuleShape: QrDataModuleShape.square,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _countdownLabel(l10n),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD3BFA9),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuideAttendanceParticipantStatusList extends StatelessWidget {
  const _GuideAttendanceParticipantStatusList({
    required this.scheduleSlotId,
    required this.fallbackBookings,
  });

  final String scheduleSlotId;
  final List<ExcursionBookingVm> fallbackBookings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();

    return Consumer<ExcursionProvider>(
      builder: (context, provider, _) {
        final participants = provider.myGuideExcursionBookings.where((booking) {
          return !booking.isCancelled &&
              (booking.scheduleSlotId ?? '').trim() == scheduleSlotId;
        }).toList(growable: false);
        final effectiveParticipants = participants.isEmpty
            ? fallbackBookings
                .where((booking) => !booking.isCancelled)
                .toList(growable: false)
            : participants;
        if (effectiveParticipants.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.guideDashboardAttendanceParticipants,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final booking in effectiveParticipants) ...[
                _GuideAttendanceParticipantRow(
                  booking: booking,
                  localeName: localeName,
                ),
                if (booking != effectiveParticipants.last)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GuideAttendanceParticipantRow extends StatelessWidget {
  const _GuideAttendanceParticipantRow({
    required this.booking,
    required this.localeName,
  });

  final ExcursionBookingVm booking;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checkedIn = booking.isCheckedIn;
    final statusColor =
        checkedIn ? const Color(0xFF77D88B) : const Color(0xFFFFD6A3);
    final statusLabel = checkedIn
        ? l10n.guideDashboardAttendanceCheckedIn
        : l10n.guideDashboardAttendanceWaiting;
    final checkedInAt = booking.checkedInAt;
    final timeLabel = checkedInAt == null
        ? null
        : DateFormat.Hm(localeName).format(checkedInAt.toLocal());

    return Row(
      children: [
        Icon(
          checkedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _guideAttendanceParticipantName(booking),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.myExcursionsGuests(booking.totalSeats),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD3BFA9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusColor.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              timeLabel == null ? statusLabel : '$statusLabel · $timeLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _guideAttendanceParticipantName(ExcursionBookingVm booking) {
  final displayName = booking.author.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }
  final userId = booking.touristUserId.trim();
  if (userId.isNotEmpty) {
    return userId;
  }
  return booking.id;
}

class _GuideBookingDetailsSheet extends StatefulWidget {
  const _GuideBookingDetailsSheet({
    required this.booking,
    required this.relatedBookings,
  });

  final ExcursionBookingVm booking;
  final List<ExcursionBookingVm> relatedBookings;

  @override
  State<_GuideBookingDetailsSheet> createState() =>
      _GuideBookingDetailsSheetState();
}

class _GuideBookingDetailsSheetState extends State<_GuideBookingDetailsSheet> {
  Timer? _authorRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshGuideDashboardAuthors());
    });
    _authorRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshGuideDashboardAuthors()),
    );
  }

  @override
  void dispose() {
    _authorRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshGuideDashboardAuthors() async {
    if (!mounted ||
        !_hasGuideBookingSlot(widget.booking, widget.relatedBookings)) {
      return;
    }
    await context.read<ExcursionProvider>().refreshGuideDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 390;
    final providerBookings =
        context.watch<ExcursionProvider>().myGuideExcursionBookings;
    final bookings = _effectiveGuideBookingAuthors(
      booking: widget.booking,
      relatedBookings: widget.relatedBookings,
      providerBookings: providerBookings,
    );
    final primaryBooking = bookings.firstWhere(
      (item) => item.id == widget.booking.id,
      orElse: () => widget.booking,
    );
    final adults = bookings.fold<int>(0, (sum, item) => sum + item.adults);
    final children = bookings.fold<int>(0, (sum, item) => sum + item.children);
    final totalSeats = bookings.fold<int>(
      0,
      (sum, item) => sum + item.totalSeats,
    );
    final totalAmount = bookings.fold<double>(
      0,
      (sum, item) => sum + item.totalPriceAmount,
    );
    final dateLabel = DateFormat.yMMMd(
      localeName,
    ).add_Hm().format(primaryBooking.scheduledFor.toLocal());
    final totalPrice = formatLocalizedExcursionMoney(
      amount: totalAmount,
      currency: _primaryCurrency(bookings),
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );

    return AppDismissibleModalSheet(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: mediaQuery.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: mediaQuery.size.height * 0.86,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF92A190D), Color(0xFA180E08)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 36,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                14,
                compact ? 16 : 20,
                22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.guideDashboardBookingSheetTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 21 : 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    primaryBooking.title.trim().isEmpty
                        ? l10n.myExcursionsUntitled
                        : primaryBooking.title.trim(),
                    style: const TextStyle(
                      color: Color(0xFFD3BFA9),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _GuideBookingInfoPill(
                        icon: Icons.event_rounded,
                        label: dateLabel,
                      ),
                      _GuideBookingInfoPill(
                        icon: Icons.group_rounded,
                        label: l10n.myExcursionsGuests(totalSeats),
                      ),
                      _GuideBookingInfoPill(
                        icon: Icons.payments_outlined,
                        label: totalPrice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (primaryBooking.isCancelled) ...[
                    _GuideBookingCancellationPanel(booking: primaryBooking),
                    const SizedBox(height: 22),
                  ],
                  _GuideBookingGuestBreakdown(
                    adults: adults,
                    children: children,
                    totalSeats: totalSeats,
                  ),
                  const SizedBox(height: 22),
                  _GuideBookingAuthorsList(
                    bookings: bookings,
                    localeName: localeName,
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

class _GuideBookingGuestBreakdown extends StatelessWidget {
  const _GuideBookingGuestBreakdown({
    required this.adults,
    required this.children,
    required this.totalSeats,
  });

  final int adults;
  final int children;
  final int totalSeats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _GuideBookingBreakdownRow(
            label: l10n.guideDashboardAdults,
            value: '$adults',
          ),
          const SizedBox(height: 10),
          _GuideBookingBreakdownRow(
            label: l10n.guideDashboardChildren,
            value: '$children',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0x33FFFFFF)),
          ),
          _GuideBookingBreakdownRow(
            label: l10n.guideDashboardTotalGuests,
            value: '$totalSeats',
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _GuideBookingAuthorsList extends StatelessWidget {
  const _GuideBookingAuthorsList({
    required this.bookings,
    required this.localeName,
  });

  final List<ExcursionBookingVm> bookings;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ExcursionProvider>(
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.guideDashboardBookingAuthorsTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in bookings) ...[
              _GuideBookingAuthorRow(booking: item, localeName: localeName),
              if (item != bookings.last) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _GuideBookingCancellationPanel extends StatelessWidget {
  const _GuideBookingCancellationPanel({required this.booking});

  final ExcursionBookingVm booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final refundCurrency = (booking.refundCurrency ?? booking.currency).trim();
    final refund = formatLocalizedExcursionMoney(
      amount: booking.refundAmount,
      currency: refundCurrency.isEmpty ? booking.currency : refundCurrency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );
    final cancelledBy = (booking.cancelledBy ?? '').trim().toUpperCase();
    final title = switch (cancelledBy) {
      'TOURIST' => l10n.guideDashboardCancelledByTourist,
      'GUIDE' => l10n.guideDashboardCancelledByGuide,
      _ => l10n.guideDashboardStatusCancelled,
    };
    final reason = (booking.cancelReason ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB49A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB49A).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_busy_rounded,
                color: Color(0xFFFFB49A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.refundAmount > 0
                ? l10n.myExcursionsCancelledWithRefund(
                    refund,
                    booking.refundPercent,
                  )
                : l10n.myExcursionsCancelledWithoutRefund,
            style: const TextStyle(
              color: Color(0xFFFFD0C1),
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.guideDashboardCancellationReason(reason),
              style: const TextStyle(
                color: Color(0xFFD3BFA9),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideCancelExcursionSheet extends StatefulWidget {
  const _GuideCancelExcursionSheet({
    required this.refundAmount,
    required this.refundCurrency,
  });

  final double refundAmount;
  final String refundCurrency;

  @override
  State<_GuideCancelExcursionSheet> createState() =>
      _GuideCancelExcursionSheetState();
}

class _GuideCancelExcursionSheetState
    extends State<_GuideCancelExcursionSheet> {
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = AppLocalizations.of(
          context,
        )!
            .guideDashboardCancelReasonRequired;
      });
      _reasonFocusNode.requestFocus();
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final compact = mediaQuery.size.width < 390;
    final refund = formatLocalizedExcursionMoney(
      amount: widget.refundAmount,
      currency: widget.refundCurrency,
      localeName: localeName,
      useExcursionListCurrencyFormat: true,
    );

    return AppDismissibleModalSheet(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: mediaQuery.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: mediaQuery.size.height * 0.88,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF92A190D), Color(0xFA180E08)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 36,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                14,
                compact ? 16 : 20,
                22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.guideDashboardCancelTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 21 : 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.guideDashboardCancelDescription,
                    style: const TextStyle(
                      color: Color(0xFFD3BFA9),
                      fontSize: 14,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      l10n.guideDashboardRefundAmount(refund),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.guideDashboardCancelReasonLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _errorText == null
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0x88FF8A65),
                      ),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      focusNode: _reasonFocusNode,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 160,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.guideDashboardCancelReasonPlaceholder,
                        hintStyle: TextStyle(
                          color: const Color(
                            0xFFD3BFA9,
                          ).withValues(alpha: 0.72),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        counterStyle: const TextStyle(
                          color: Color(0xFFD3BFA9),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          14,
                          12,
                          14,
                          8,
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorText != null &&
                            _reasonController.text.trim().isNotEmpty) {
                          setState(() => _errorText = null);
                        }
                      },
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFFF8A65),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 360;
                      final keep = OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          minimumSize: const Size(0, 50),
                        ),
                        child: Text(l10n.cancelButton),
                      );
                      final confirm = FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.event_busy_rounded),
                        label: Text(l10n.guideDashboardCancelConfirm),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                        ),
                      );

                      if (stack) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [keep, const SizedBox(height: 10), confirm],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: keep),
                          const SizedBox(width: 12),
                          Expanded(child: confirm),
                        ],
                      );
                    },
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

class _GuideBookingAuthorRow extends StatelessWidget {
  const _GuideBookingAuthorRow({
    required this.booking,
    required this.localeName,
  });

  final ExcursionBookingVm booking;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final displayName = booking.author.resolvedDisplayName.isNotEmpty
        ? booking.author.resolvedDisplayName
        : booking.touristUserId;
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.accent.withValues(alpha: 0.16),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                _GuideBookingAuthorGuestsText(booking: booking),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _GuideBookingAttendanceStatusPill(
            booking: booking,
            localeName: localeName,
          ),
        ],
      ),
    );
  }
}

class _GuideBookingAuthorGuestsText extends StatelessWidget {
  const _GuideBookingAuthorGuestsText({required this.booking});

  final ExcursionBookingVm booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.guideDashboardGuestBreakdown(
        booking.adults,
        booking.children,
        booking.totalSeats,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFD3BFA9),
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GuideBookingAttendanceStatusPill extends StatelessWidget {
  const _GuideBookingAttendanceStatusPill({
    required this.booking,
    required this.localeName,
  });

  final ExcursionBookingVm booking;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checkedIn = booking.isCheckedIn;
    final statusColor =
        checkedIn ? const Color(0xFF77D88B) : const Color(0xFFFFD6A3);
    final statusLabel = checkedIn
        ? l10n.guideDashboardAttendanceCheckedIn
        : l10n.guideDashboardAttendanceWaiting;
    final checkedInAt = booking.checkedInAt;
    final timeLabel = checkedInAt == null
        ? null
        : DateFormat.Hm(localeName).format(checkedInAt.toLocal());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 178),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: statusColor.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                checkedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  timeLabel == null ? statusLabel : '$statusLabel · $timeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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

class _GuideBookingInfoPill extends StatelessWidget {
  const _GuideBookingInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBookingBreakdownRow extends StatelessWidget {
  const _GuideBookingBreakdownRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  emphasized ? AppColors.textPrimary : const Color(0xFFD3BFA9),
              fontSize: emphasized ? 15 : 14,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: emphasized ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GuideJourneyCard extends StatelessWidget {
  const _GuideJourneyCard({
    required this.title,
    required this.statusLabel,
    required this.actionLabel,
    required this.meta,
    required this.seed,
    required this.onTap,
    this.imageUrl,
    this.categorySlug,
    this.secondaryActionLabel,
    this.onSecondaryActionTap,
    this.actionFooter,
    this.destructiveActionLabel,
    this.onDestructiveActionTap,
    this.subtitle = '',
    this.muted = false,
    this.stackSecondaryAction = false,
  });

  final String title;
  final String statusLabel;
  final String actionLabel;
  final List<_GuideMetaData> meta;
  final int seed;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? categorySlug;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryActionTap;
  final Widget? actionFooter;
  final String? destructiveActionLabel;
  final VoidCallback? onDestructiveActionTap;
  final String subtitle;
  final bool muted;
  final bool stackSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: muted
                ? const Color(0xFF2A1D13).withValues(alpha: 0.72)
                : const Color(0xFF2A1D13),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: muted
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.05),
              style: muted ? BorderStyle.solid : BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: AspectRatio(
                  aspectRatio: 2.04,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _GuideCoverArt(
                        seed: seed,
                        categorySlug: categorySlug,
                        imageUrl: imageUrl,
                        muted: muted,
                      ),
                      Positioned(
                        top: 12,
                        left: 14,
                        child: _GuideStatusBadge(
                          label: statusLabel,
                          muted: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 23,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD3BFA9),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final item in meta)
                          _GuideMetaChip(icon: item.icon, label: item.label),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final secondary = secondaryActionLabel?.trim() ?? '';
                        final hasSecondary = secondary.isNotEmpty &&
                            onSecondaryActionTap != null;
                        final destructive =
                            destructiveActionLabel?.trim() ?? '';
                        final hasDestructive = destructive.isNotEmpty &&
                            onDestructiveActionTap != null;
                        final stackActions = constraints.maxWidth < 360;
                        final primaryButton = FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            actionLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        );
                        if (!hasSecondary && !hasDestructive) {
                          return SizedBox(
                            width: double.infinity,
                            child: primaryButton,
                          );
                        }

                        final secondaryButton = OutlinedButton(
                          onPressed: onSecondaryActionTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD6A3),
                            side: BorderSide(
                              color: const Color(
                                0xFFFFD6A3,
                              ).withValues(alpha: 0.38),
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            secondary.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        );

                        final destructiveButton = OutlinedButton.icon(
                          onPressed: onDestructiveActionTap,
                          icon: const Icon(Icons.delete_outline_rounded),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB4AB),
                            side: BorderSide(
                              color: const Color(
                                0xFFFFB4AB,
                              ).withValues(alpha: 0.46),
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          label: Text(
                            destructive.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        );

                        if (stackActions || stackSecondaryAction) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              primaryButton,
                              if (hasSecondary) ...[
                                const SizedBox(height: 10),
                                secondaryButton,
                              ],
                              if (hasDestructive) ...[
                                const SizedBox(height: 10),
                                destructiveButton,
                              ],
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: primaryButton),
                                if (hasSecondary) ...[
                                  const SizedBox(width: 10),
                                  Expanded(child: secondaryButton),
                                ],
                              ],
                            ),
                            if (hasDestructive) ...[
                              const SizedBox(height: 10),
                              destructiveButton,
                            ],
                          ],
                        );
                      },
                    ),
                    if (actionFooter != null) ...[
                      const SizedBox(height: 14),
                      actionFooter!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStatusBadge extends StatelessWidget {
  const _GuideStatusBadge({required this.label, required this.muted});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF160D07).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: muted ? const Color(0xFFD3BFA9) : AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _GuideMetaChip extends StatelessWidget {
  const _GuideMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD3BFA9), size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD3BFA9),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GuideMetaData {
  const _GuideMetaData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _GuideCoverArt extends StatelessWidget {
  const _GuideCoverArt({
    required this.seed,
    required this.categorySlug,
    required this.imageUrl,
    required this.muted,
  });

  final int seed;
  final String? categorySlug;
  final String? imageUrl;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = _GuideCoverPalette.forCategory(categorySlug, seed);
    final resolvedImageUrl = imageUrl?.trim() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (resolvedImageUrl.isNotEmpty)
          Image.network(
            resolvedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _GeneratedGuideCover(palette: palette, seed: seed),
          )
        else
          _GeneratedGuideCover(palette: palette, seed: seed),
        if (muted)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              backgroundBlendMode: BlendMode.saturation,
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF2A1D13).withValues(alpha: 0.76),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneratedGuideCover extends StatelessWidget {
  const _GeneratedGuideCover({required this.palette, required this.seed});

  final _GuideCoverPalette palette;
  final int seed;

  @override
  Widget build(BuildContext context) {
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
        CustomPaint(painter: _GuideCoverPainter(palette, seed)),
      ],
    );
  }
}

class _GuideCoverPainter extends CustomPainter {
  const _GuideCoverPainter(this.palette, this.seed);

  final _GuideCoverPalette palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final ridge = Paint()..color = palette.ridge;
    final ridgeDark = Paint()..color = palette.ridgeDark;
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.32);
    final offset = (seed.abs() % 5) * size.width * 0.04;

    final back = Path()
      ..moveTo(-size.width * 0.08, size.height)
      ..lineTo(size.width * 0.26 + offset, size.height * 0.38)
      ..lineTo(size.width * 0.64 + offset, size.height)
      ..close();
    final front = Path()
      ..moveTo(size.width * 0.10 - offset, size.height)
      ..lineTo(size.width * 0.68 - offset, size.height * 0.28)
      ..lineTo(size.width * 1.10, size.height)
      ..close();
    final cap = Path()
      ..moveTo(size.width * 0.68 - offset, size.height * 0.28)
      ..lineTo(size.width * 0.58 - offset, size.height * 0.44)
      ..lineTo(size.width * 0.76 - offset, size.height * 0.40)
      ..close();

    canvas
      ..drawPath(back, ridgeDark)
      ..drawPath(front, ridge)
      ..drawPath(cap, highlight);
  }

  @override
  bool shouldRepaint(covariant _GuideCoverPainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.seed != seed;
  }
}

class _GuideCoverPalette {
  const _GuideCoverPalette({
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

  static _GuideCoverPalette forCategory(String? categorySlug, int seed) {
    switch (categorySlug?.toLowerCase()) {
      case 'culinary':
        return const _GuideCoverPalette(
          sky: Color(0xFFFFB13B),
          haze: Color(0xFF8C4022),
          ground: Color(0xFF30160C),
          ridge: Color(0xFFE07A22),
          ridgeDark: Color(0xFF6D2812),
        );
      case 'wellness':
        return const _GuideCoverPalette(
          sky: Color(0xFF7DD2C7),
          haze: Color(0xFF4F8E65),
          ground: Color(0xFF143B29),
          ridge: Color(0xFF2E7D4C),
          ridgeDark: Color(0xFF10291E),
        );
      default:
        final variants = [
          const _GuideCoverPalette(
            sky: Color(0xFFE7C38A),
            haze: Color(0xFFB76821),
            ground: Color(0xFF442512),
            ridge: Color(0xFFD56D11),
            ridgeDark: Color(0xFF74411A),
          ),
          const _GuideCoverPalette(
            sky: Color(0xFF8BD1E3),
            haze: Color(0xFF346B73),
            ground: Color(0xFF0F2B2B),
            ridge: Color(0xFF1F6B5B),
            ridgeDark: Color(0xFF12352F),
          ),
        ];
        return variants[seed.abs() % variants.length];
    }
  }
}

class _GuideDashboardInfoCard extends StatelessWidget {
  const _GuideDashboardInfoCard({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD3BFA9), height: 1.4),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onActionTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideDashboardSkeletonCard extends StatelessWidget {
  const _GuideDashboardSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D13),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
