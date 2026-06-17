import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../core/network/chat_api.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/excursion_api.dart';
import '../../core/time/app_time.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/excursions/excursion_cover_url.dart';
import '../../features/excursions/excursion_localization.dart';
import '../../features/excursions/excursion_search.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../shared/widgets/app_map_card.dart';
import 'excursion_booking_screen.dart';
import 'widgets/excursion_review_management_sheet.dart';

class ExcursionDetailsScreen extends StatefulWidget {
  const ExcursionDetailsScreen({
    super.key,
    required this.excursionId,
    this.initialExcursion,
  });

  final String excursionId;
  final ExcursionVm? initialExcursion;

  @override
  State<ExcursionDetailsScreen> createState() => _ExcursionDetailsScreenState();
}

class _ExcursionDetailsScreenState extends State<ExcursionDetailsScreen> {
  final AttractionApi _attractionApi = AttractionApi();
  final ProfileApi _profileApi = ProfileApi();
  final ChatApi _chatApi = ChatApi();
  AttractionVm? _localizedLandmark;
  String? _localizedLandmarkId;
  String? _localizedLandmarkLocale;
  String? _loadingLocalizedLandmarkId;
  Map<String, UserProfileVm> _resolvedProfiles = const {};
  final Set<String> _resolvingGuideUserIds = <String>{};
  List<ExcursionOfferVm> _visibleOffers = const [];
  String? _visibleOffersExcursionId;
  String? _selectedOfferId;
  final Map<String, bool> _offerScheduleAvailability = <String, bool>{};
  final Set<String> _loadingOfferScheduleAvailability = <String>{};
  bool _isMessageGuideLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcursionProvider>().loadExcursionDetails(
        widget.excursionId,
        initialExcursion: widget.initialExcursion,
      );
      unawaited(
        context.read<ExcursionProvider>().loadExcursionReviews(
          productId: widget.excursionId,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant ExcursionDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.excursionId == widget.excursionId) return;

    _localizedLandmark = null;
    _localizedLandmarkId = null;
    _localizedLandmarkLocale = null;
    _loadingLocalizedLandmarkId = null;
    _resolvedProfiles = const {};
    _resolvingGuideUserIds.clear();
    _visibleOffers = const [];
    _visibleOffersExcursionId = null;
    _selectedOfferId = null;
    _offerScheduleAvailability.clear();
    _loadingOfferScheduleAvailability.clear();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/excursions');
  }

  Future<void> _retry({ExcursionVm? initialExcursion}) {
    return context.read<ExcursionProvider>().loadExcursionDetails(
      widget.excursionId,
      initialExcursion: initialExcursion ?? widget.initialExcursion,
    );
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3A2B1D),
        ),
      );
  }

  Future<void> _openGuideChat(String guideUserId) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedGuideUserId = guideUserId.trim();
    if (trimmedGuideUserId.isEmpty || _isMessageGuideLoading) {
      if (trimmedGuideUserId.isEmpty) {
        _showInfoSnack(l10n.profileNotAvailable);
      }
      return;
    }

    setState(() => _isMessageGuideLoading = true);

    try {
      final conversationId = await _chatApi.createDirectConversation(
        guideUserId,
      );
      if (!mounted) return;
      context.push('/chats/$conversationId');
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? DioErrorMapper.toMessage(e)
          : l10n.profileMessageOpenFailed;
      await showErrorDialog(context, title: l10n.error, message: message);
    } finally {
      if (mounted) {
        setState(() => _isMessageGuideLoading = false);
      }
    }
  }

  void _scheduleResolveGuideProfiles(
    Iterable<String> guideUserIds,
    UserProfileVm? currentProfile,
    bool canFetch,
  ) {
    final currentUserId = (currentProfile?.userId ?? '').trim();
    if (!canFetch) {
      return;
    }

    for (final rawGuideUserId in guideUserIds) {
      final guideUserId = rawGuideUserId.trim();
      if (guideUserId.isEmpty ||
          guideUserId == currentUserId ||
          _resolvedProfiles.containsKey(guideUserId) ||
          _resolvingGuideUserIds.contains(guideUserId)) {
        continue;
      }

      _resolvingGuideUserIds.add(guideUserId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveGuideProfile(guideUserId);
      });
    }
  }

  Future<void> _resolveGuideProfile(String guideUserId) async {
    try {
      final profile = await _profileApi.getUserById(guideUserId);
      if (!mounted) return;
      setState(() {
        _resolvedProfiles = {..._resolvedProfiles, guideUserId: profile};
        _resolvingGuideUserIds.remove(guideUserId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingGuideUserIds.remove(guideUserId));
    }
  }

  void _openGuideProfile(String guideUserId, {required bool isAuthor}) {
    final l10n = AppLocalizations.of(context)!;
    if (isAuthor) {
      context.push('/profile');
      return;
    }
    if (guideUserId.isEmpty) {
      unawaited(
        showErrorDialog(
          context,
          title: l10n.error,
          message: l10n.profileNotAvailable,
        ),
      );
      return;
    }
    context.push(
      '/users/$guideUserId/profile',
      extra: _resolvedProfiles[guideUserId],
    );
  }

  void _openBooking(ExcursionVm excursion, ExcursionOfferVm? selectedOffer) {
    final excursionId = excursion.id.trim();
    if (excursionId.isEmpty) return;
    final bookingExcursion = selectedOffer == null
        ? excursion
        : excursion.withPrimaryOffer(selectedOffer);

    context.push(
      '/excursions/${Uri.encodeComponent(excursion.id)}/booking',
      extra: ExcursionBookingRouteArgs(
        excursion: bookingExcursion,
        selectedOfferId: selectedOffer?.id,
      ),
    );
  }

  Future<void> _openEditOffer(
    ExcursionVm excursion,
    ExcursionOfferVm? selectedOffer,
  ) async {
    final legacyExcursionId = (selectedOffer?.legacyExcursionId ?? '').trim();
    if (legacyExcursionId.isEmpty) {
      _showInfoSnack(AppLocalizations.of(context)!.excursionDetailsLoadFailed);
      return;
    }
    final editableExcursion = selectedOffer == null
        ? excursion
        : excursion.withPrimaryOffer(selectedOffer);
    final updated = await context.push<ExcursionVm>(
      '/excursions/${Uri.encodeComponent(legacyExcursionId)}/edit',
      extra: editableExcursion,
    );
    if (!mounted) return;
    if (updated != null) {
      final updatedProductId = updated.id.trim();
      setState(() {
        _visibleOffersExcursionId = updatedProductId.isNotEmpty
            ? updatedProductId
            : null;
        _visibleOffers = updated.offers;
        _selectedOfferId = updated.offers.isNotEmpty
            ? updated.offers.first.id
            : null;
        _offerScheduleAvailability.clear();
        _loadingOfferScheduleAvailability.clear();
      });
      await _retry(initialExcursion: updated);
    }
  }

  Future<void> _openExcursionReviewActions(ExcursionReviewVm review) async {
    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    if (currentUserId.isEmpty || review.author.userId.trim() != currentUserId) {
      return;
    }
    final action = await showExcursionReviewActionsSheet(context);
    if (!mounted || action == null) return;

    switch (action) {
      case ExcursionReviewAction.edit:
        await _editExcursionReview(review);
      case ExcursionReviewAction.delete:
        await _deleteExcursionReview(review);
    }
  }

  Future<void> _editExcursionReview(ExcursionReviewVm review) async {
    final draft = await showExcursionReviewEditSheet(context, review: review);
    if (!mounted || draft == null) return;

    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final savedReview = await provider.saveExcursionReview(
      review.bookingId,
      draft.toRequest(),
    );
    if (!mounted) return;
    if (savedReview == null) {
      _showInfoSnack(
        provider.actionErrorMessage ?? l10n.myExcursionsReviewFailed,
      );
      return;
    }
    await _refreshReviewSources(savedReview);
    if (!mounted) return;
    _showInfoSnack(l10n.excursionReviewUpdated);
  }

  Future<void> _deleteExcursionReview(ExcursionReviewVm review) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ExcursionProvider>();
    final success = await provider.deleteExcursionReview(
      review.bookingId,
      review.id,
    );
    if (!mounted) return;
    if (!success) {
      _showInfoSnack(
        provider.actionErrorMessage ?? l10n.myExcursionsReviewDeleteFailed,
      );
      return;
    }
    await _refreshReviewSources(review);
    if (!mounted) return;
    _showInfoSnack(l10n.excursionReviewDeleted);
  }

  Future<void> _refreshReviewSources(ExcursionReviewVm review) async {
    final provider = context.read<ExcursionProvider>();
    final productId = review.productId.trim();
    if (productId.isNotEmpty) {
      await provider.loadExcursionReviews(productId: productId);
    }
    final landmarkId = review.landmarkId?.trim() ?? '';
    if (landmarkId.isNotEmpty) {
      await provider.loadExcursionReviews(landmarkId: landmarkId);
    }
  }

  void _selectOffer(ExcursionOfferVm offer) {
    setState(() => _selectedOfferId = offer.id);
  }

  String? _selectedOfferScheduleKey(
    ExcursionVm excursion,
    ExcursionOfferVm? selectedOffer,
  ) {
    final productId = excursion.id.trim();
    final offerId = selectedOffer?.id.trim() ?? '';
    if (productId.isEmpty || offerId.isEmpty) {
      return null;
    }
    return '$productId:$offerId';
  }

  void _scheduleLoadSelectedOfferAvailability(
    ExcursionVm excursion,
    ExcursionOfferVm? selectedOffer,
  ) {
    final selectedOfferScheduleKey = _selectedOfferScheduleKey(
      excursion,
      selectedOffer,
    );
    if (selectedOfferScheduleKey == null ||
        _offerScheduleAvailability.containsKey(selectedOfferScheduleKey) ||
        _loadingOfferScheduleAvailability.contains(selectedOfferScheduleKey)) {
      return;
    }

    _loadingOfferScheduleAvailability.add(selectedOfferScheduleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _loadSelectedOfferAvailability(
          productId: excursion.id,
          offerId: selectedOffer!.id,
          selectedOfferScheduleKey: selectedOfferScheduleKey,
        ),
      );
    });
  }

  Future<void> _loadSelectedOfferAvailability({
    required String productId,
    required String offerId,
    required String selectedOfferScheduleKey,
  }) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 90));

    try {
      final slots = await context
          .read<ExcursionProvider>()
          .loadBookableExcursionSchedule(
            productId: productId,
            offerId: offerId,
            from: from,
            to: to,
            seats: 1,
          );
      if (!mounted) return;
      setState(() {
        _offerScheduleAvailability[selectedOfferScheduleKey] = slots.any(
          (slot) => slot.isAvailableFor(1),
        );
        _loadingOfferScheduleAvailability.remove(selectedOfferScheduleKey);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offerScheduleAvailability[selectedOfferScheduleKey] = false;
        _loadingOfferScheduleAvailability.remove(selectedOfferScheduleKey);
      });
    }
  }

  List<ExcursionOfferVm> _offersFor(ExcursionVm excursion) {
    if (_visibleOffersExcursionId == excursion.id) {
      return _visibleOffers;
    }
    return excursion.offers;
  }

  void _scheduleLoadLocalizedLandmark(ExcursionVm excursion) {
    final landmarkId = excursion.landmarkId?.trim();
    if (landmarkId == null || landmarkId.isEmpty) {
      _localizedLandmark = null;
      _localizedLandmarkId = null;
      _localizedLandmarkLocale = null;
      _loadingLocalizedLandmarkId = null;
      return;
    }

    final lang = Localizations.localeOf(context).languageCode;
    if (_localizedLandmarkId == landmarkId &&
        _localizedLandmarkLocale == lang &&
        _localizedLandmark != null) {
      return;
    }
    if (_loadingLocalizedLandmarkId == '$landmarkId:$lang') return;

    _loadingLocalizedLandmarkId = '$landmarkId:$lang';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadLocalizedLandmark(landmarkId, lang));
    });
  }

  Future<void> _loadLocalizedLandmark(String landmarkId, String lang) async {
    try {
      final attraction = await _attractionApi.getAttraction(
        landmarkId,
        locale: lang,
      );
      if (!mounted || _loadingLocalizedLandmarkId != '$landmarkId:$lang') {
        return;
      }

      setState(() {
        _localizedLandmark = attraction;
        _localizedLandmarkId = landmarkId;
        _localizedLandmarkLocale = lang;
        _loadingLocalizedLandmarkId = null;
      });
    } catch (_) {
      if (!mounted || _loadingLocalizedLandmarkId != '$landmarkId:$lang') {
        return;
      }

      setState(() => _loadingLocalizedLandmarkId = null);
    }
  }

  void _replaceVisibleOffers(
    String excursionId,
    List<ExcursionOfferVm> offers,
  ) {
    setState(() {
      _visibleOffersExcursionId = excursionId;
      _visibleOffers = offers;
      _offerScheduleAvailability.clear();
      _loadingOfferScheduleAvailability.clear();
    });
  }

  ExcursionOfferVm? _selectedOfferFor(
    ExcursionVm excursion,
    List<ExcursionOfferVm> offers,
  ) {
    if (offers.isEmpty) {
      return null;
    }
    final selectedOfferId = _selectedOfferId?.trim();
    if (selectedOfferId != null && selectedOfferId.isNotEmpty) {
      for (final offer in offers) {
        if (offer.id == selectedOfferId) {
          return offer;
        }
      }
    }
    return offers.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1209),
      body: Consumer<ExcursionProvider>(
        builder: (context, provider, _) {
          final excursion = provider.excursionDetailsFor(widget.excursionId);
          final isInitialLoading =
              provider.isDetailLoadingFor(widget.excursionId) &&
              excursion == null;
          final isInitialError =
              provider.isDetailErrorFor(widget.excursionId) &&
              excursion == null;

          if (isInitialLoading) {
            return const _ExcursionDetailsLoading();
          }

          if (isInitialError) {
            return SafeArea(
              child: ErrorView(
                message:
                    provider.detailErrorMessageFor(widget.excursionId) ??
                    l10n.excursionDetailsLoadFailed,
                onRetry: _retry,
              ),
            );
          }

          if (excursion == null) {
            return const _ExcursionDetailsLoading();
          }

          _scheduleLoadLocalizedLandmark(excursion);
          final offers = _offersFor(excursion);
          final selectedOffer = _selectedOfferFor(excursion, offers);
          final displayExcursion = selectedOffer == null
              ? excursion
              : excursion.withPrimaryOffer(selectedOffer);
          final guideUserId =
              (selectedOffer?.guideUserId ?? excursion.guideUserId ?? '')
                  .trim();
          final hasBookableOffer = offers.isNotEmpty;
          final currentUserId = (session.profile?.userId ?? '').trim();
          final isCurrentUserGuide =
              session.profile?.roles.any(
                (role) => role.trim().toUpperCase() == 'GUIDE',
              ) ??
              false;
          final isAuthor =
              guideUserId.isNotEmpty && currentUserId == guideUserId;
          if (!isAuthor && hasBookableOffer) {
            _scheduleLoadSelectedOfferAvailability(excursion, selectedOffer);
          }
          final selectedOfferScheduleKey = _selectedOfferScheduleKey(
            excursion,
            selectedOffer,
          );
          final hasAvailableSchedule =
              selectedOfferScheduleKey != null &&
              (_offerScheduleAvailability[selectedOfferScheduleKey] ?? false);
          final hasScheduleAvailabilityResult =
              selectedOfferScheduleKey != null &&
              _offerScheduleAvailability.containsKey(selectedOfferScheduleKey);
          final isCheckingSchedule =
              selectedOfferScheduleKey != null &&
              _loadingOfferScheduleAvailability.contains(
                selectedOfferScheduleKey,
              );
          final bookingUnavailableMessage =
              !isAuthor && hasBookableOffer && !hasAvailableSchedule
              ? (isCheckingSchedule || !hasScheduleAvailabilityResult
                    ? l10n.excursionDetailsCheckingSchedule
                    : l10n.excursionDetailsNoAvailableSlots)
              : null;
          _scheduleResolveGuideProfiles(
            offers.map((offer) => offer.guideUserId),
            session.profile,
            session.isAuthenticated,
          );
          final offerProfiles = <String, UserProfileVm>{..._resolvedProfiles};
          if (session.profile != null && currentUserId.isNotEmpty) {
            offerProfiles[currentUserId] = session.profile!;
          }

          return ExcursionDetailsContent(
            excursion: displayExcursion,
            localizedLandmark: _localizedLandmark,
            offers: offers,
            excursionReviews: provider.excursionReviewsForProduct(excursion.id),
            selectedOffer: selectedOffer,
            currentUserId: currentUserId,
            isCurrentUserGuide: isCurrentUserGuide,
            enableRemoteOffers: true,
            offerProfiles: offerProfiles,
            showMessageGuide: !isAuthor && guideUserId.isNotEmpty,
            showBookingAction:
                !isAuthor && hasBookableOffer && hasAvailableSchedule,
            showCheckoutPrice:
                !isCurrentUserGuide && !isAuthor && hasBookableOffer,
            showEditOfferAction:
                isAuthor &&
                (selectedOffer?.legacyExcursionId ?? '').trim().isNotEmpty,
            isMessageGuideLoading: _isMessageGuideLoading,
            bookingUnavailableMessage: bookingUnavailableMessage,
            onBackTap: _goBack,
            onNotificationsTap: () => context.push('/notifications'),
            onOfferProfileTap: (offer) {
              final offerGuideUserId = offer.guideUserId.trim();
              if (offerGuideUserId.isEmpty) return;
              _openGuideProfile(
                offerGuideUserId,
                isAuthor: currentUserId == offerGuideUserId,
              );
            },
            onBookTap: () => _openBooking(excursion, selectedOffer),
            onEditOfferTap: () => _openEditOffer(excursion, selectedOffer),
            onMessageGuideTap: () => _openGuideChat(guideUserId),
            onOfferSelected: _selectOffer,
            onOffersChanged: (offers) =>
                _replaceVisibleOffers(excursion.id, offers),
            onReviewLongPress: _openExcursionReviewActions,
          );
        },
      ),
    );
  }
}

class ExcursionDetailsContent extends StatelessWidget {
  const ExcursionDetailsContent({
    super.key,
    required this.excursion,
    required this.selectedOffer,
    required this.offerProfiles,
    required this.onBookTap,
    required this.onEditOfferTap,
    required this.onMessageGuideTap,
    required this.onOfferSelected,
    this.offers,
    this.excursionReviews = const [],
    this.onOfferProfileTap,
    this.currentUserId = '',
    this.isCurrentUserGuide = false,
    this.enableRemoteOffers = false,
    this.showMessageGuide = true,
    this.showBookingAction = true,
    this.showCheckoutPrice = true,
    this.showEditOfferAction = false,
    this.isMessageGuideLoading = false,
    this.bookingUnavailableMessage,
    this.onBackTap,
    this.onNotificationsTap,
    this.onOffersChanged,
    this.onReviewLongPress,
    this.localizedLandmark,
  });

  final ExcursionVm excursion;
  final AttractionVm? localizedLandmark;
  final List<ExcursionOfferVm>? offers;
  final List<ExcursionReviewVm> excursionReviews;
  final ExcursionOfferVm? selectedOffer;
  final Map<String, UserProfileVm> offerProfiles;
  final VoidCallback onBookTap;
  final VoidCallback onEditOfferTap;
  final VoidCallback onMessageGuideTap;
  final ValueChanged<ExcursionOfferVm> onOfferSelected;
  final ValueChanged<ExcursionOfferVm>? onOfferProfileTap;
  final String currentUserId;
  final bool isCurrentUserGuide;
  final bool enableRemoteOffers;
  final bool showMessageGuide;
  final bool showBookingAction;
  final bool showCheckoutPrice;
  final bool showEditOfferAction;
  final bool isMessageGuideLoading;
  final String? bookingUnavailableMessage;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<List<ExcursionOfferVm>>? onOffersChanged;
  final ValueChanged<ExcursionReviewVm>? onReviewLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeSelectedOffer = selectedOffer;
    final visibleOffers = offers ?? excursion.offers;
    final showBottomBookingNotice =
        !showBookingAction &&
        !showEditOfferAction &&
        bookingUnavailableMessage != null;
    final bottomAction = showBookingAction || showEditOfferAction
        ? _ExcursionCheckoutBar(
            excursion: excursion,
            label: showEditOfferAction
                ? l10n.excursionDetailsEditOffer
                : l10n.excursionDetailsBook,
            icon: showEditOfferAction
                ? Icons.edit_rounded
                : Icons.arrow_forward_ios_rounded,
            helperText: showBookingAction
                ? l10n.excursionDetailsBookingSeatCheckNote
                : null,
            showPrice: showCheckoutPrice && showBookingAction,
            onTap: showEditOfferAction ? onEditOfferTap : onBookTap,
          )
        : showBottomBookingNotice
        ? _ExcursionBookingUnavailableNotice(
            message: bookingUnavailableMessage!,
          )
        : null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF20150B), Color(0xFF1A1209), Color(0xFF181006)],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _ExcursionDetailsTopBar(
              onBackTap: onBackTap,
              onNotificationsTap: onNotificationsTap,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ExcursionHero(
                    excursion: excursion,
                    localizedLandmark: localizedLandmark,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ExcursionStatsGrid(
                          excursion: excursion,
                          selectedOffer: activeSelectedOffer,
                        ),
                        const SizedBox(height: 40),
                        _ExcursionExperienceSection(
                          excursion: excursion,
                          localizedLandmark: localizedLandmark,
                        ),
                        const SizedBox(height: 44),
                        _ExcursionOffersSection(
                          excursion: excursion,
                          offers: visibleOffers,
                          selectedOffer: selectedOffer,
                          currentUserId: currentUserId,
                          isCurrentUserGuide: isCurrentUserGuide,
                          enableRemoteOffers: enableRemoteOffers,
                          offerProfiles: offerProfiles,
                          showMessageGuide: showMessageGuide,
                          isMessageGuideLoading: isMessageGuideLoading,
                          onOfferSelected: onOfferSelected,
                          onOfferProfileTap: onOfferProfileTap,
                          onMessageGuideTap: onMessageGuideTap,
                          onOffersChanged: onOffersChanged,
                        ),
                        if (activeSelectedOffer != null &&
                            activeSelectedOffer.includedItems.isNotEmpty) ...[
                          const SizedBox(height: 44),
                          _ExcursionSelectedOfferIncludedSection(
                            selectedOffer: activeSelectedOffer,
                          ),
                        ],
                        const SizedBox(height: 44),
                        _ExcursionMapPreview(excursion: excursion),
                        const SizedBox(height: 44),
                        _ExcursionItinerarySection(
                          excursion: excursion,
                          localizedLandmark: localizedLandmark,
                        ),
                        if (excursionReviews.isNotEmpty) ...[
                          const SizedBox(height: 44),
                          _ExcursionReviewsSection(
                            reviews: excursionReviews,
                            currentUserId: currentUserId,
                            onReviewLongPress: onReviewLongPress,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ?bottomAction,
        ],
      ),
    );
  }
}

class _ExcursionDetailsTopBar extends StatelessWidget {
  const _ExcursionDetailsTopBar({
    required this.onBackTap,
    required this.onNotificationsTap,
  });

  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1F150B).withValues(alpha: 0.96),
      ),
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: onBackTap,
              ),
              Expanded(
                child: Text(
                  l10n.excursionDetailsTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _CircleIconButton(
                icon: Icons.notifications_outlined,
                tooltip: l10n.attractionNotificationsTooltip,
                color: AppColors.accent,
                background: AppColors.accent.withValues(alpha: 0.12),
                onTap: onNotificationsTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color = AppColors.textPrimary,
    this.background = Colors.transparent,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _ExcursionHero extends StatelessWidget {
  const _ExcursionHero({
    required this.excursion,
    required this.localizedLandmark,
  });

  final ExcursionVm excursion;
  final AttractionVm? localizedLandmark;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveExcursionCoverUrl(excursion)?.trim() ?? '';
    final label = _categoryLabel(context, excursion.categorySlug);
    final title = localizedExcursionTitle(
      languageCode: Localizations.localeOf(context).languageCode,
      excursion: excursion,
      attraction: localizedLandmark,
      fallback: label,
    );

    return SizedBox(
      height: 236,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ExcursionHeroFallback(),
            )
          else
            const _ExcursionHeroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.12),
                  const Color(0xFF1A1209),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _HeroMetaPill(
                      icon: Icons.schedule_rounded,
                      label: _formatDuration(
                        context,
                        excursion.durationMinutes,
                      ).toUpperCase(),
                    ),
                    const _HeroMetaPill(
                      icon: Icons.star_rounded,
                      label: '4.9',
                      accentIcon: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({
    required this.icon,
    required this.label,
    this.accentIcon = false,
  });

  final IconData icon;
  final String label;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: accentIcon ? AppColors.accent : const Color(0xFFB9A99A),
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(
          label.isEmpty ? '-' : label,
          style: const TextStyle(
            color: Color(0xFFB9A99A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ExcursionHeroFallback extends StatelessWidget {
  const _ExcursionHeroFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ExcursionHeroPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ExcursionHeroPainter extends CustomPainter {
  const _ExcursionHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF16313A), Color(0xFF432A13)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final dark = Paint()
      ..color = const Color(0xFF08232A).withValues(alpha: 0.98);
    final green = Paint()
      ..color = const Color(0xFF124953).withValues(alpha: 0.98);
    final amber = Paint()
      ..color = const Color(0xFF724720).withValues(alpha: 0.88);
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.76);

    Path ridge(double start, double peak, double end) {
      return Path()
        ..moveTo(size.width * start, size.height)
        ..lineTo(size.width * peak, size.height * 0.36)
        ..lineTo(size.width * end, size.height)
        ..close();
    }

    canvas
      ..drawPath(ridge(-0.15, 0.28, 0.7), dark)
      ..drawPath(ridge(0.18, 0.58, 1.15), green)
      ..drawPath(ridge(0.42, 0.78, 1.25), amber);

    final snowCap = Path()
      ..moveTo(size.width * 0.58, size.height * 0.36)
      ..lineTo(size.width * 0.49, size.height * 0.5)
      ..lineTo(size.width * 0.65, size.height * 0.45)
      ..close();
    canvas.drawPath(snowCap, snow);

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.22),
              AppColors.accent.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, -size.height * 0.12),
              radius: math.min(size.width, size.height),
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExcursionStatsGrid extends StatelessWidget {
  const _ExcursionStatsGrid({required this.excursion, this.selectedOffer});

  final ExcursionVm excursion;
  final ExcursionOfferVm? selectedOffer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedOfferLanguages = selectedOffer?.languageCodes ?? const [];
    final languageCodes = selectedOfferLanguages.isNotEmpty
        ? selectedOfferLanguages
        : excursion.languageCodes;
    final language = _formatLanguageLabels(l10n, languageCodes);
    final cards = <_ExcursionStatData>[
      _ExcursionStatData(
        label: l10n.excursionDetailsPrice,
        value: _formatPrice(context, excursion),
        suffix: l10n.excursionDetailsPerPerson,
        accent: true,
      ),
      _ExcursionStatData(
        label: l10n.excursionDetailsIntensity,
        value: l10n.excursionDetailsIntensityModerate,
      ),
      if (excursion.routeKind == 'COMBINED_ROUTE' && excursion.stopCount > 1)
        _ExcursionStatData(
          label: l10n.excursionDetailsRouteStopsCount(excursion.stopCount),
          value: excursion.stopCount.toString(),
        ),
      _ExcursionStatData(
        label: l10n.excursionDetailsGroupSize,
        value: excursion.maxGroupSize > 0
            ? l10n.excursionDetailsGroupSizeUpTo(excursion.maxGroupSize)
            : '-',
      ),
      _ExcursionStatData(
        label: l10n.excursionDetailsLanguage,
        value: language,
        allowMultiline: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 12.0 : 16.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: _ExcursionStatCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _ExcursionStatData {
  const _ExcursionStatData({
    required this.label,
    required this.value,
    this.suffix,
    this.accent = false,
    this.allowMultiline = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool accent;
  final bool allowMultiline;
}

class _ExcursionStatCard extends StatelessWidget {
  const _ExcursionStatCard({required this.data});

  final _ExcursionStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF312316),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCAB9A5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          RichText(
            maxLines: data.allowMultiline ? null : 2,
            overflow: data.allowMultiline
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            text: TextSpan(
              text: data.value,
              style: TextStyle(
                color: data.accent ? AppColors.accent : AppColors.textPrimary,
                fontSize: data.accent
                    ? 24
                    : data.allowMultiline
                    ? 18
                    : 20,
                fontWeight: FontWeight.w800,
                height: data.allowMultiline ? 1.16 : 1.08,
              ),
              children: [
                if (data.suffix != null)
                  TextSpan(
                    text: ' ${data.suffix}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _ExcursionExperienceSection extends StatelessWidget {
  const _ExcursionExperienceSection({
    required this.excursion,
    required this.localizedLandmark,
  });

  final ExcursionVm excursion;
  final AttractionVm? localizedLandmark;

  void _openLandmarkDetails(BuildContext context) {
    final landmarkId = (excursion.landmarkId ?? '').trim();
    if (landmarkId.isEmpty) return;

    context.push(
      '/attractions/${Uri.encodeComponent(landmarkId)}',
      extra: localizedLandmark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLandmarkId = (excursion.landmarkId ?? '').trim().isNotEmpty;
    final description = localizedExcursionDescription(
      languageCode: Localizations.localeOf(context).languageCode,
      excursion: excursion,
      attraction: localizedLandmark,
      fallback: l10n.excursionDetailsNoDescription,
    );

    return _ExcursionSection(
      title: l10n.excursionDetailsExperience,
      actionLabel: hasLandmarkId ? l10n.detailsButton : null,
      onActionTap: hasLandmarkId ? () => _openLandmarkDetails(context) : null,
      child: Text(
        description,
        style: const TextStyle(
          color: Color(0xFFC6B6A7),
          fontSize: 16,
          height: 1.58,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ExcursionSelectedOfferIncludedSection extends StatelessWidget {
  const _ExcursionSelectedOfferIncludedSection({required this.selectedOffer});

  final ExcursionOfferVm selectedOffer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final features = _resolveExcursionIncludedFeatures(
      selectedOffer.localizedIncludedItems(languageCode),
      languageCode,
    );

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ExcursionSection(
      title: l10n.excursionDetailsSelectedOfferIncluded,
      child: Column(
        children: [
          for (var index = 0; index < features.length; index++) ...[
            _ExcursionFeatureCard(feature: features[index]),
            if (index != features.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ExcursionFeatureCard extends StatelessWidget {
  const _ExcursionFeatureCard({required this.feature});

  final _ExcursionIncludedFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2B1D),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _includedFeatureIcon(feature),
              color: AppColors.accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              feature.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExcursionIncludedFeatureType {
  transport,
  food,
  tickets,
  equipment,
  guide,
  photo,
  other,
}

class _ExcursionIncludedFeature {
  const _ExcursionIncludedFeature({required this.type, required this.label});

  final _ExcursionIncludedFeatureType type;
  final String label;
}

List<_ExcursionIncludedFeature> _resolveExcursionIncludedFeatures(
  List<String> source,
  String languageCode,
) {
  return source
      .map((item) => _parseExcursionIncludedFeature(item, languageCode))
      .where((feature) => feature.label.isNotEmpty)
      .toList(growable: false);
}

_ExcursionIncludedFeature _parseExcursionIncludedFeature(
  String rawValue,
  String languageCode,
) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return const _ExcursionIncludedFeature(
      type: _ExcursionIncludedFeatureType.other,
      label: '',
    );
  }

  final directType = _includedFeatureTypeFromPrefix(value.toLowerCase());
  if (directType != null) {
    return _ExcursionIncludedFeature(
      type: directType,
      label: _includedFeatureTypeLabel(directType, languageCode),
    );
  }

  final separatorIndex = value.indexOf(':');
  if (separatorIndex > 0) {
    final prefix = value.substring(0, separatorIndex).trim().toLowerCase();
    final label = value.substring(separatorIndex + 1).trim();
    final type = _includedFeatureTypeFromPrefix(prefix);
    if (type != null && label.isNotEmpty) {
      return _ExcursionIncludedFeature(
        type: type,
        label: _isTextCompatibleWithLocale(label, languageCode)
            ? label
            : _includedFeatureTypeLabel(type, languageCode),
      );
    }
  }

  if (!_isTextCompatibleWithLocale(value, languageCode)) {
    final type = _guessIncludedFeatureType(value);
    return _ExcursionIncludedFeature(
      type: type,
      label: _includedFeatureTypeLabel(type, languageCode),
    );
  }

  return _ExcursionIncludedFeature(
    type: _guessIncludedFeatureType(value),
    label: value,
  );
}

_ExcursionIncludedFeatureType? _includedFeatureTypeFromPrefix(String prefix) {
  return switch (prefix) {
    'transport' ||
    'транспорт' ||
    'көлік' => _ExcursionIncludedFeatureType.transport,
    'food' ||
    'meal' ||
    'meals' ||
    'питание' ||
    'еда' ||
    'тамақ' => _ExcursionIncludedFeatureType.food,
    'tickets' ||
    'ticket' ||
    'билеты' ||
    'билет' ||
    'билеттер' => _ExcursionIncludedFeatureType.tickets,
    'equipment' ||
    'gear' ||
    'снаряжение' ||
    'жабдық' => _ExcursionIncludedFeatureType.equipment,
    'guide' || 'гид' => _ExcursionIncludedFeatureType.guide,
    'photo' || 'photos' || 'фото' => _ExcursionIncludedFeatureType.photo,
    'other' || 'другое' || 'басқа' => _ExcursionIncludedFeatureType.other,
    _ => null,
  };
}

String _includedFeatureTypeLabel(
  _ExcursionIncludedFeatureType type,
  String languageCode,
) {
  final normalized = _normalizeLanguageCode(languageCode);
  final labels = switch (type) {
    _ExcursionIncludedFeatureType.transport => const {
      'en': 'Transport',
      'ru': 'Транспорт',
      'kk': 'Көлік',
    },
    _ExcursionIncludedFeatureType.food => const {
      'en': 'Food',
      'ru': 'Питание',
      'kk': 'Тамақ',
    },
    _ExcursionIncludedFeatureType.tickets => const {
      'en': 'Tickets',
      'ru': 'Билеты',
      'kk': 'Билеттер',
    },
    _ExcursionIncludedFeatureType.equipment => const {
      'en': 'Equipment',
      'ru': 'Снаряжение',
      'kk': 'Жабдық',
    },
    _ExcursionIncludedFeatureType.guide => const {
      'en': 'Guide',
      'ru': 'Гид',
      'kk': 'Гид',
    },
    _ExcursionIncludedFeatureType.photo => const {
      'en': 'Photo',
      'ru': 'Фото',
      'kk': 'Фото',
    },
    _ExcursionIncludedFeatureType.other => const {
      'en': 'Included',
      'ru': 'Включено',
      'kk': 'Кіреді',
    },
  };
  return labels[normalized] ??
      labels[normalized.split('-').first] ??
      labels['en']!;
}

String _normalizeLanguageCode(String value) {
  return value.trim().toLowerCase().replaceAll('_', '-');
}

bool _isTextCompatibleWithLocale(String text, String languageCode) {
  final value = text.trim();
  if (value.isEmpty) return true;

  final normalized = _normalizeLanguageCode(languageCode).split('-').first;
  final hasLatin = RegExp(r'[A-Za-z]').hasMatch(value);
  final hasCyrillic = RegExp(r'[А-Яа-яЁёӘәҒғҚқҢңӨөҰұҮүҺһІі]').hasMatch(value);

  return switch (normalized) {
    'en' => !hasCyrillic,
    'ru' => !hasLatin,
    'kk' => !hasLatin && !_looksLikeRussianOnlyText(value),
    _ => true,
  };
}

bool _looksLikeRussianOnlyText(String value) {
  final normalized = value.toLowerCase();
  if (RegExp(r'[ӘәҒғҚқҢңӨөҰұҮүҺһІі]').hasMatch(normalized)) {
    return false;
  }

  const russianOnlySignals = [
    'имеется',
    'возможно',
    'стоит',
    'изменить',
    'встреча',
    'гидом',
    'начало',
    'маршрут',
    'отель',
    'выезд',
    'питание',
    'раза',
  ];
  return russianOnlySignals.any(normalized.contains);
}

_ExcursionIncludedFeatureType _guessIncludedFeatureType(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('car') ||
      normalized.contains('suv') ||
      normalized.contains('transfer') ||
      normalized.contains('transport') ||
      normalized.contains('авто') ||
      normalized.contains('трансфер') ||
      normalized.contains('көлік')) {
    return _ExcursionIncludedFeatureType.transport;
  }
  if (normalized.contains('food') ||
      normalized.contains('meal') ||
      normalized.contains('lunch') ||
      normalized.contains('picnic') ||
      normalized.contains('еда') ||
      normalized.contains('обед') ||
      normalized.contains('тамақ')) {
    return _ExcursionIncludedFeatureType.food;
  }
  if (normalized.contains('ticket') ||
      normalized.contains('entry') ||
      normalized.contains('билет') ||
      normalized.contains('кіру')) {
    return _ExcursionIncludedFeatureType.tickets;
  }
  if (normalized.contains('gear') ||
      normalized.contains('equipment') ||
      normalized.contains('снаряж') ||
      normalized.contains('жабдық')) {
    return _ExcursionIncludedFeatureType.equipment;
  }
  if (normalized.contains('photo') ||
      normalized.contains('фото') ||
      normalized.contains('сурет')) {
    return _ExcursionIncludedFeatureType.photo;
  }
  if (normalized.contains('guide') ||
      normalized.contains('гид') ||
      normalized.contains('нұсқаушы')) {
    return _ExcursionIncludedFeatureType.guide;
  }
  return _ExcursionIncludedFeatureType.other;
}

IconData _includedFeatureIcon(_ExcursionIncludedFeature feature) {
  return switch (feature.type) {
    _ExcursionIncludedFeatureType.transport =>
      Icons.directions_car_filled_rounded,
    _ExcursionIncludedFeatureType.food => Icons.restaurant_rounded,
    _ExcursionIncludedFeatureType.tickets => Icons.confirmation_number_rounded,
    _ExcursionIncludedFeatureType.equipment => Icons.backpack_rounded,
    _ExcursionIncludedFeatureType.guide => Icons.person_pin_circle_rounded,
    _ExcursionIncludedFeatureType.photo => Icons.photo_camera_rounded,
    _ExcursionIncludedFeatureType.other => Icons.check_circle_rounded,
  };
}

enum _ExcursionOfferSortMode { rating, experience, price }

extension _ExcursionOfferSortModeX on _ExcursionOfferSortMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _ExcursionOfferSortMode.rating => l10n.excursionDetailsOffersSortRating,
      _ExcursionOfferSortMode.experience =>
        l10n.excursionDetailsOffersSortExperience,
      _ExcursionOfferSortMode.price => l10n.excursionDetailsOffersSortPrice,
    };
  }

  String get apiValue {
    return switch (this) {
      _ExcursionOfferSortMode.rating => 'rating',
      _ExcursionOfferSortMode.experience => 'experience',
      _ExcursionOfferSortMode.price => 'price',
    };
  }

  _ExcursionOfferSortDirection get defaultDirection {
    return switch (this) {
      _ExcursionOfferSortMode.price => _ExcursionOfferSortDirection.asc,
      _ => _ExcursionOfferSortDirection.desc,
    };
  }
}

enum _ExcursionOfferSortDirection { asc, desc }

extension _ExcursionOfferSortDirectionX on _ExcursionOfferSortDirection {
  String get apiValue {
    return switch (this) {
      _ExcursionOfferSortDirection.asc => 'asc',
      _ExcursionOfferSortDirection.desc => 'desc',
    };
  }

  _ExcursionOfferSortDirection get toggled {
    return switch (this) {
      _ExcursionOfferSortDirection.asc => _ExcursionOfferSortDirection.desc,
      _ExcursionOfferSortDirection.desc => _ExcursionOfferSortDirection.asc,
    };
  }

  bool get isAscending => this == _ExcursionOfferSortDirection.asc;
}

class _ExcursionOfferFilters {
  const _ExcursionOfferFilters({
    this.languageCode,
    this.priceMax,
    this.maxGroupSizeMin,
    this.availableDate,
  });

  final String? languageCode;
  final double? priceMax;
  final int? maxGroupSizeMin;
  final DateTime? availableDate;

  int get activeCount =>
      ((languageCode ?? '').trim().isEmpty ? 0 : 1) +
      (priceMax == null ? 0 : 1) +
      (maxGroupSizeMin == null ? 0 : 1) +
      (availableDate == null ? 0 : 1);
}

class _ExcursionOffersSection extends StatefulWidget {
  const _ExcursionOffersSection({
    required this.excursion,
    required this.offers,
    required this.selectedOffer,
    required this.currentUserId,
    required this.isCurrentUserGuide,
    required this.enableRemoteOffers,
    required this.offerProfiles,
    required this.showMessageGuide,
    required this.isMessageGuideLoading,
    required this.onOfferSelected,
    required this.onMessageGuideTap,
    this.onOffersChanged,
    this.onOfferProfileTap,
  });

  final ExcursionVm excursion;
  final List<ExcursionOfferVm> offers;
  final ExcursionOfferVm? selectedOffer;
  final String currentUserId;
  final bool isCurrentUserGuide;
  final bool enableRemoteOffers;
  final Map<String, UserProfileVm> offerProfiles;
  final bool showMessageGuide;
  final bool isMessageGuideLoading;
  final ValueChanged<ExcursionOfferVm> onOfferSelected;
  final VoidCallback onMessageGuideTap;
  final ValueChanged<List<ExcursionOfferVm>>? onOffersChanged;
  final ValueChanged<ExcursionOfferVm>? onOfferProfileTap;

  @override
  State<_ExcursionOffersSection> createState() =>
      _ExcursionOffersSectionState();
}

class _ExcursionOffersSectionState extends State<_ExcursionOffersSection> {
  static const _pageSize = 20;

  final ExcursionApi _excursionApi = ExcursionApi();
  final TextEditingController _offerSearchController = TextEditingController();
  Timer? _offerSearchDebounce;
  List<ExcursionOfferVm> _offers = const [];
  _ExcursionOfferFilters _filters = const _ExcursionOfferFilters();
  _ExcursionOfferSortMode _sortMode = _ExcursionOfferSortMode.rating;
  _ExcursionOfferSortDirection _sortDirection =
      _ExcursionOfferSortDirection.desc;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorText;
  String _offerSearchQuery = '';
  int _requestSerial = 0;
  final Map<String, bool> _offerDateAvailability = <String, bool>{};
  final Set<String> _loadingOfferDateAvailability = <String>{};

  @override
  void initState() {
    super.initState();
    _offers = _prioritizeCurrentGuideOffer(widget.offers);
    _hasMore = widget.excursion.publishedOffersCount > _offers.length;
    if (widget.enableRemoteOffers) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOffers());
    }
  }

  @override
  void didUpdateWidget(covariant _ExcursionOffersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRefreshOffers = _shouldRefreshOffersAfterWidgetUpdate(
      oldWidget,
    );
    if (oldWidget.excursion.id != widget.excursion.id ||
        oldWidget.offers != widget.offers ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.isCurrentUserGuide != widget.isCurrentUserGuide) {
      setState(() {
        _offers = _prioritizeCurrentGuideOffer(widget.offers);
        _hasMore = widget.excursion.publishedOffersCount > _offers.length;
      });
    }
    if (shouldRefreshOffers) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOffers());
    }
  }

  @override
  void dispose() {
    _offerSearchDebounce?.cancel();
    _offerSearchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOffers() => _loadOffers(reset: true);

  Future<void> _loadMoreOffers() => _loadOffers(reset: false);

  bool _shouldRefreshOffersAfterWidgetUpdate(
    _ExcursionOffersSection oldWidget,
  ) {
    if (!widget.enableRemoteOffers) return false;
    if (oldWidget.excursion.id != widget.excursion.id) return true;

    final staleEmptyOffersBecameVisible =
        widget.offers.isEmpty &&
        widget.excursion.publishedOffersCount > 0 &&
        (oldWidget.offers != widget.offers ||
            oldWidget.excursion.publishedOffersCount !=
                widget.excursion.publishedOffersCount ||
            oldWidget.enableRemoteOffers != widget.enableRemoteOffers);
    return staleEmptyOffersBecameVisible;
  }

  Future<void> _loadOffers({required bool reset}) async {
    if (!widget.enableRemoteOffers || _isLoading || _isLoadingMore) {
      return;
    }
    final requestSerial = ++_requestSerial;
    setState(() {
      if (reset) {
        _isLoading = true;
        _errorText = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final page = await _excursionApi.getExcursionOffers(
        widget.excursion.id,
        limit: _pageSize,
        offset: reset ? 0 : _offers.length,
        query: _offerSearchController.text,
        sort: _sortMode.apiValue,
        sortDirection: _sortDirection.apiValue,
        languageCode: _filters.languageCode,
        priceMax: _filters.priceMax,
        maxGroupSizeMin: _filters.maxGroupSizeMin,
        preferredGuideUserId: _preferredGuideUserId,
      );
      if (!mounted || requestSerial != _requestSerial) return;
      final merged = reset ? page.items : _mergeOffers(_offers, page.items);
      final prioritized = _prioritizeCurrentGuideOffer(merged);
      setState(() {
        _offers = prioritized;
        _hasMore = page.hasMore;
        _errorText = null;
      });
      widget.onOffersChanged?.call(prioritized);
    } catch (_) {
      if (!mounted || requestSerial != _requestSerial) return;
      setState(
        () => _errorText = AppLocalizations.of(
          context,
        )!.excursionDetailsOffersLoadFailed,
      );
    } finally {
      if (mounted && requestSerial == _requestSerial) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  String? get _preferredGuideUserId {
    final currentUserId = widget.currentUserId.trim();
    if (!widget.isCurrentUserGuide || currentUserId.isEmpty) return null;
    return currentUserId;
  }

  void _onSearchChanged() {
    final nextQuery = _offerSearchController.text.trim();
    if (nextQuery != _offerSearchQuery) {
      setState(() => _offerSearchQuery = nextQuery);
    }

    _offerSearchDebounce?.cancel();
    if (!widget.enableRemoteOffers) return;
    if (nextQuery.isNotEmpty && _queryMatchesResolvedGuideProfile(nextQuery)) {
      return;
    }

    _offerSearchDebounce = Timer(
      const Duration(milliseconds: 360),
      _refreshOffers,
    );
  }

  void _onSortChanged(_ExcursionOfferSortMode value) {
    setState(() {
      if (_sortMode == value) {
        _toggleSortDirection();
      } else {
        _sortMode = value;
        _sortDirection = value.defaultDirection;
      }
    });
    _refreshOffers();
  }

  void _toggleSortDirection() {
    _sortDirection = _sortDirection.toggled;
  }

  Future<void> _showFilters() async {
    final next = await showModalBottomSheet<_ExcursionOfferFilters>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExcursionOffersFilterSheet(filters: _filters),
    );
    if (!mounted || next == null) return;
    setState(() {
      if (_dateKey(_filters.availableDate) != _dateKey(next.availableDate)) {
        _offerDateAvailability.clear();
        _loadingOfferDateAvailability.clear();
      }
      _filters = next;
    });
    _refreshOffers();
  }

  List<ExcursionOfferVm> _mergeOffers(
    List<ExcursionOfferVm> current,
    List<ExcursionOfferVm> incoming,
  ) {
    final byId = <String, ExcursionOfferVm>{
      for (final offer in current)
        if (offer.id.trim().isNotEmpty) offer.id: offer,
    };
    final merged = <ExcursionOfferVm>[
      for (final offer in current)
        if (offer.id.trim().isEmpty) offer,
    ];
    for (final offer in incoming) {
      final id = offer.id.trim();
      if (id.isEmpty) {
        merged.add(offer);
        continue;
      }
      byId[id] = offer;
    }
    return [...byId.values, ...merged];
  }

  List<ExcursionOfferVm> _prioritizeCurrentGuideOffer(
    List<ExcursionOfferVm> offers,
  ) {
    final currentUserId = widget.currentUserId.trim();
    if (!widget.isCurrentUserGuide || currentUserId.isEmpty) {
      return offers;
    }
    final own = <ExcursionOfferVm>[];
    final rest = <ExcursionOfferVm>[];
    for (final offer in offers) {
      if (offer.guideUserId.trim() == currentUserId) {
        own.add(offer);
      } else {
        rest.add(offer);
      }
    }
    return [...own, ...rest];
  }

  bool _isCurrentUserOffer(ExcursionOfferVm offer) {
    return widget.isCurrentUserGuide &&
        widget.currentUserId.trim().isNotEmpty &&
        widget.currentUserId.trim() == offer.guideUserId.trim();
  }

  List<ExcursionOfferVm> _visibleOffers(AppLocalizations l10n) {
    final offers = _prioritizeCurrentGuideOffer(_offers);
    final searchGroups = excursionSearchNeedleGroups(_offerSearchQuery);
    final searchedOffers = searchGroups.isEmpty
        ? offers
        : offers
              .where((offer) {
                final haystack = _offerSearchHaystack(l10n, offer);
                return searchGroups.every(
                  (variants) => variants.any(haystack.contains),
                );
              })
              .toList(growable: false);

    final availableDate = _filters.availableDate;
    if (availableDate == null) return searchedOffers;

    _scheduleLoadOfferDateAvailability(searchedOffers, availableDate);
    return searchedOffers
        .where((offer) => _offerHasBookableSlotOnDate(offer, availableDate))
        .toList(growable: false);
  }

  bool _offerHasBookableSlotOnDate(
    ExcursionOfferVm offer,
    DateTime availableDate,
  ) {
    return _offerDateAvailability[_offerDateAvailabilityKey(
          offer.id,
          availableDate,
        )] ??
        false;
  }

  void _scheduleLoadOfferDateAvailability(
    List<ExcursionOfferVm> offers,
    DateTime availableDate,
  ) {
    for (final offer in offers) {
      final offerId = offer.id.trim();
      if (offerId.isEmpty) continue;
      final key = _offerDateAvailabilityKey(offerId, availableDate);
      if (_offerDateAvailability.containsKey(key) ||
          _loadingOfferDateAvailability.contains(key)) {
        continue;
      }
      _loadingOfferDateAvailability.add(key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          _loadOfferDateAvailability(
            offerId: offerId,
            availableDate: availableDate,
            cacheKey: key,
          ),
        );
      });
    }
  }

  Future<void> _loadOfferDateAvailability({
    required String offerId,
    required DateTime availableDate,
    required String cacheKey,
  }) async {
    final from = DateTime(
      availableDate.year,
      availableDate.month,
      availableDate.day,
    );
    final to = from.add(const Duration(days: 1));
    try {
      final slots = await context
          .read<ExcursionProvider>()
          .loadBookableExcursionSchedule(
            productId: widget.excursion.id,
            offerId: offerId,
            from: from,
            to: to,
            seats: 1,
          );
      if (!mounted) return;
      setState(() {
        _offerDateAvailability[cacheKey] = slots.any(
          (slot) =>
              slot.isAvailableFor(1) &&
              _dateKey(eventDateOnly(slot.startAt, slot.timezone)) ==
                  _dateKey(availableDate),
        );
        _loadingOfferDateAvailability.remove(cacheKey);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offerDateAvailability[cacheKey] = false;
        _loadingOfferDateAvailability.remove(cacheKey);
      });
    }
  }

  String _offerSearchHaystack(AppLocalizations l10n, ExcursionOfferVm offer) {
    final profile = widget.offerProfiles[offer.guideUserId];
    final firstName = (profile?.firstName ?? '').trim();
    final lastName = (profile?.lastName ?? '').trim();
    final nickname = (profile?.nickname ?? '').trim();
    final values = <String>[
      offer.id,
      offer.guideProfileId,
      offer.guideUserId,
      offer.guideDisplayName,
      if (offer.guideDisplayName.startsWith('@'))
        offer.guideDisplayName.substring(1),
      offer.title,
      offer.summary,
      offer.description,
      offer.meetingPoint,
      offer.currency,
      offer.priceAmount.toString(),
      offer.maxGroupSize.toString(),
      offer.durationMinutes.toString(),
      for (final code in offer.languageCodes) ...[
        code,
        localizedExcursionLanguageLabel(l10n, code),
      ],
      if (profile != null) ...[
        profile.userId,
        profile.preferredName,
        profile.initials,
        nickname,
        firstName,
        lastName,
        [firstName, lastName].where((value) => value.isNotEmpty).join(' '),
        [lastName, firstName].where((value) => value.isNotEmpty).join(' '),
        if (firstName.isNotEmpty && lastName.isNotEmpty)
          '$lastName ${firstName.substring(0, 1)}',
        if (nickname.startsWith('@')) nickname.substring(1),
        profile.primaryPhone ?? '',
        profile.primaryEmail ?? '',
        profile.bio ?? '',
        profile.countryCode ?? '',
        profile.locale,
      ],
    ];

    return _normalizeOfferSearchText(values.join(' '));
  }

  bool _queryMatchesResolvedGuideProfile(String query) {
    final searchGroups = excursionSearchNeedleGroups(query);
    if (searchGroups.isEmpty) return false;

    return widget.offerProfiles.values.any((profile) {
      final firstName = (profile.firstName ?? '').trim();
      final lastName = (profile.lastName ?? '').trim();
      final nickname = (profile.nickname ?? '').trim();
      final profileHaystack = _normalizeOfferSearchText(
        [
          profile.userId,
          profile.preferredName,
          profile.initials,
          nickname,
          if (nickname.startsWith('@')) nickname.substring(1),
          firstName,
          lastName,
          [firstName, lastName].where((value) => value.isNotEmpty).join(' '),
          [lastName, firstName].where((value) => value.isNotEmpty).join(' '),
          profile.primaryPhone ?? '',
          profile.primaryEmail ?? '',
        ].join(' '),
      );
      return searchGroups.every(
        (variants) => variants.any(profileHaystack.contains),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offers = _visibleOffers(l10n);
    final isDateFilterLoading =
        _filters.availableDate != null &&
        _loadingOfferDateAvailability.isNotEmpty;

    return _ExcursionSection(
      title: l10n.excursionDetailsOffersTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExcursionOffersSearchField(
            controller: _offerSearchController,
            hintText: l10n.excursionDetailsOffersSearchHint,
            activeFilterCount: _filters.activeCount,
            onChanged: _onSearchChanged,
            onFilterTap: _showFilters,
          ),
          const SizedBox(height: 14),
          _ExcursionOffersSortBar(
            selected: _sortMode,
            direction: _sortDirection,
            onChanged: _onSortChanged,
          ),
          const SizedBox(height: 18),
          if ((_isLoading || isDateFilterLoading) && offers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (offers.isEmpty)
            _ExcursionOffersEmpty(
              message: _errorText ?? l10n.excursionDetailsOffersEmpty,
            )
          else
            Column(
              children: [
                for (var index = 0; index < offers.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final offer = offers[index];
                      final isSelected = offer.id == widget.selectedOffer?.id;
                      final isCurrentUserOffer = _isCurrentUserOffer(offer);

                      return _ExcursionOfferCard(
                        offer: offer,
                        isSelected: isSelected,
                        isCurrentUserOffer: isCurrentUserOffer,
                        profile: widget.offerProfiles[offer.guideUserId],
                        showMessageAction:
                            isSelected && widget.showMessageGuide,
                        isMessageActionLoading:
                            isSelected && widget.isMessageGuideLoading,
                        onTap: () => widget.onOfferSelected(offer),
                        onProfileTap: isCurrentUserOffer
                            ? null
                            : widget.onOfferProfileTap == null
                            ? null
                            : () => widget.onOfferProfileTap!(offer),
                        onMessageTap: isSelected
                            ? widget.onMessageGuideTap
                            : null,
                      );
                    },
                  ),
                  if (index != offers.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          if (_errorText != null && offers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExcursionOffersEmpty(message: _errorText!),
          ],
          if (_hasMore) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoadingMore ? null : _loadMoreOffers,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text(
                      l10n.excursionDetailsOffersLoadMore,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExcursionOffersSearchField extends StatelessWidget {
  const _ExcursionOffersSearchField({
    required this.controller,
    required this.hintText,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final String hintText;
  final int activeFilterCount;
  final VoidCallback onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 8, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1F14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.accent, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onFilterTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.accent,
                    minimumSize: const Size(42, 42),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 23),
                ),
                if (activeFilterCount > 0)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _ExcursionOffersSortBar extends StatelessWidget {
  const _ExcursionOffersSortBar({
    required this.selected,
    required this.direction,
    required this.onChanged,
  });

  final _ExcursionOfferSortMode selected;
  final _ExcursionOfferSortDirection direction;
  final ValueChanged<_ExcursionOfferSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppInlineSortRow<_ExcursionOfferSortMode>(
      label: l10n.excursionsSortLabel,
      options: [
        for (final mode in _ExcursionOfferSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction.isAscending,
      onSelected: onChanged,
      optionGap: 18,
    );
  }
}

class _ExcursionOffersFilterSheet extends StatefulWidget {
  const _ExcursionOffersFilterSheet({required this.filters});

  final _ExcursionOfferFilters filters;

  @override
  State<_ExcursionOffersFilterSheet> createState() =>
      _ExcursionOffersFilterSheetState();
}

class _ExcursionOffersFilterSheetState
    extends State<_ExcursionOffersFilterSheet> {
  late final TextEditingController _languageSearchController;
  late final TextEditingController _priceMaxController;
  late final TextEditingController _groupSizeController;
  late final TextEditingController _availableDateController;
  String? _languageCode;
  String _languageSearchQuery = '';
  String? _availableDateError;

  static const _languageCodes = [
    'en',
    'ru',
    'kk',
    'fr',
    'ja',
    'de',
    'es',
    'tr',
  ];

  @override
  void initState() {
    super.initState();
    _languageCode = widget.filters.languageCode;
    _languageSearchController = TextEditingController()
      ..addListener(_handleLanguageSearchChanged);
    _priceMaxController = TextEditingController(
      text: widget.filters.priceMax == null
          ? ''
          : _formatNumericInput(widget.filters.priceMax!),
    );
    _groupSizeController = TextEditingController(
      text: widget.filters.maxGroupSizeMin?.toString() ?? '',
    );
    _availableDateController = TextEditingController(
      text: _formatDateInput(widget.filters.availableDate),
    );
  }

  @override
  void dispose() {
    _languageSearchController
      ..removeListener(_handleLanguageSearchChanged)
      ..dispose();
    _priceMaxController.dispose();
    _groupSizeController.dispose();
    _availableDateController.dispose();
    super.dispose();
  }

  void _clear() {
    _languageSearchController.clear();
    setState(() => _languageCode = null);
    _priceMaxController.clear();
    _groupSizeController.clear();
    _availableDateController.clear();
    _availableDateError = null;
  }

  void _handleLanguageSearchChanged() {
    final nextQuery = _languageSearchController.text.trim();
    if (nextQuery == _languageSearchQuery) return;

    setState(() => _languageSearchQuery = nextQuery);
  }

  void _selectLanguage(String code) {
    final selectedCode = _languageCode == code ? null : code;
    _languageSearchController.clear();
    setState(() {
      _languageCode = selectedCode;
      _languageSearchQuery = '';
    });
  }

  String? _selectedLanguage(AppLocalizations l10n) {
    final code = (_languageCode ?? '').trim();
    if (code.isEmpty) return null;
    return localizedExcursionLanguageLabel(l10n, code);
  }

  List<String> _visibleLanguages(AppLocalizations l10n) {
    final query = _normalizeOfferSearchText(_languageSearchQuery);
    if (query.isEmpty) return const [];
    final tokens = query
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return const [];

    return _languageCodes
        .where((code) {
          final haystack = _languageSearchHaystack(l10n, code);
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);
  }

  String _languageSearchHaystack(AppLocalizations l10n, String code) {
    final aliases = switch (code.trim().toLowerCase()) {
      'en' => 'english английский ағылшын',
      'ru' => 'russian русский орыс',
      'kk' || 'kz' => 'kazakh казахский қазақ',
      'fr' => 'french французский француз',
      'ja' || 'jp' => 'japanese японский жапон',
      'de' => 'german немецкий неміс',
      'es' => 'spanish испанский испан',
      'tr' => 'turkish турецкий түрік',
      _ => '',
    };
    return _normalizeOfferSearchText(
      '$code ${localizedExcursionLanguageLabel(l10n, code)} $aliases',
    );
  }

  void _apply() {
    final priceMax = double.tryParse(
      _priceMaxController.text.trim().replaceAll(',', '.'),
    );
    final groupSize = int.tryParse(_groupSizeController.text.trim());
    final availableDateInput = _availableDateController.text.trim();
    final availableDate = _parseDateInput(availableDateInput);
    if (availableDateInput.isNotEmpty && availableDate == null) {
      setState(
        () => _availableDateError = AppLocalizations.of(
          context,
        )!.excursionDetailsOffersAvailableDateInvalid,
      );
      return;
    }
    Navigator.of(context).pop(
      _ExcursionOfferFilters(
        languageCode: (_languageCode ?? '').trim().isEmpty
            ? null
            : _languageCode,
        priceMax: priceMax != null && priceMax > 0 ? priceMax : null,
        maxGroupSizeMin: groupSize != null && groupSize > 0 ? groupSize : null,
        availableDate: availableDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final selectedLanguage = _selectedLanguage(l10n);
    final visibleLanguages = _visibleLanguages(l10n);

    return AppDismissibleModalSheet(
      safeAreaBottom: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.86),
        child: Material(
          color: const Color(0xFF21160D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppFilterSheetHeader(
                title: l10n.excursionDetailsOffersFiltersTitle,
                clearLabel: l10n.excursionsFiltersClear,
                onClear: _clear,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExcursionOffersFilterTitle(
                        icon: Icons.translate_rounded,
                        label: l10n.excursionsFilterLanguage,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2118),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.translate_rounded,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedLanguage ??
                                          l10n.excursionDetailsOffersLanguageAny,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (_languageCode != null)
                                    IconButton(
                                      tooltip: l10n.excursionsFiltersClear,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          setState(() => _languageCode = null),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFFBDAA98),
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _languageSearchController,
                            cursorColor: AppColors.accent,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  l10n.excursionDetailsOffersLanguageSearchHint,
                              hintStyle: const TextStyle(
                                color: Color(0xFF9D8877),
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.accent,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF171009),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          if (_languageSearchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            if (visibleLanguages.isEmpty)
                              Text(
                                l10n.excursionDetailsOffersLanguageNoResults,
                                style: const TextStyle(
                                  color: Color(0xFFBDAA98),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (final code in visibleLanguages) ...[
                                    _ExcursionOffersLanguageRow(
                                      label: localizedExcursionLanguageLabel(
                                        l10n,
                                        code,
                                      ),
                                      code: code.toUpperCase(),
                                      selected: _languageCode == code,
                                      onTap: () => _selectLanguage(code),
                                    ),
                                    if (code != visibleLanguages.last)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ExcursionOffersFilterTitle(
                        icon: Icons.event_available_rounded,
                        label: l10n.excursionDetailsOffersAvailableDate,
                      ),
                      const SizedBox(height: 10),
                      _ExcursionOffersDateField(
                        controller: _availableDateController,
                        hintText: l10n.excursionDetailsOffersAvailableDateHint,
                        errorText: _availableDateError,
                        onChanged: (_) =>
                            setState(() => _availableDateError = null),
                      ),
                      const SizedBox(height: 24),
                      _ExcursionOffersFilterTitle(
                        icon: Icons.payments_rounded,
                        label: l10n.excursionDetailsOffersMaxPrice,
                      ),
                      const SizedBox(height: 10),
                      _ExcursionOffersNumberField(
                        controller: _priceMaxController,
                        hintText: l10n.excursionDetailsOffersMaxPriceHint,
                      ),
                      const SizedBox(height: 24),
                      _ExcursionOffersFilterTitle(
                        icon: Icons.group_rounded,
                        label: l10n.excursionDetailsOffersMinGroup,
                      ),
                      const SizedBox(height: 10),
                      _ExcursionOffersNumberField(
                        controller: _groupSizeController,
                        hintText: l10n.excursionDetailsOffersMinGroupHint,
                        decimal: false,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  math.max(18, MediaQuery.paddingOf(context).bottom),
                ),
                child: AppFilterApplyButton(
                  label: l10n.excursionDetailsOffersApplyFilters,
                  onTap: _apply,
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionOffersFilterTitle extends StatelessWidget {
  const _ExcursionOffersFilterTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
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
      ],
    );
  }
}

class _ExcursionOffersLanguageRow extends StatelessWidget {
  const _ExcursionOffersLanguageRow({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : const Color(0xFF2C2118),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                code,
                style: const TextStyle(
                  color: Color(0xFFBDAA98),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionOffersDateField extends StatelessWidget {
  const _ExcursionOffersDateField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2B1F14),
        hintText: hintText,
        errorText: errorText,
        prefixIcon: const Icon(
          Icons.calendar_month_rounded,
          color: AppColors.accent,
        ),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: AppLocalizations.of(context)!.excursionsFiltersClear,
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, color: Color(0xFFBDAA98)),
              ),
        hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
        errorStyle: const TextStyle(
          color: Color(0xFFFF6B6B),
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
    );
  }
}

class _ExcursionOffersNumberField extends StatelessWidget {
  const _ExcursionOffersNumberField({
    required this.controller,
    required this.hintText,
    this.decimal = true,
  });

  final TextEditingController controller;
  final String hintText;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2B1F14),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9F8B7D)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

String _formatNumericInput(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toString();
}

String _formatDateInput(DateTime? value) {
  if (value == null) return '';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString().padLeft(4, '0');
  return '$day.$month.$year';
}

DateTime? _parseDateInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split(RegExp(r'[.\-/]'));
  if (parts.length != 3) return null;

  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  final third = int.tryParse(parts[2]);
  if (first == null || second == null || third == null) return null;

  final year = parts[0].length == 4 ? first : third;
  final month = second;
  final day = parts[0].length == 4 ? third : first;
  if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

String? _dateKey(DateTime? value) {
  if (value == null) return null;
  final normalized = DateTime(value.year, value.month, value.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

String _offerDateAvailabilityKey(String offerId, DateTime availableDate) {
  return '${offerId.trim()}:${_dateKey(availableDate)}';
}

class _ExcursionOffersEmpty extends StatelessWidget {
  const _ExcursionOffersEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF312316),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: AppColors.accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFCAB9A5),
                fontSize: 14,
                height: 1.28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExcursionOfferCard extends StatelessWidget {
  const _ExcursionOfferCard({
    required this.offer,
    required this.isSelected,
    required this.isCurrentUserOffer,
    required this.showMessageAction,
    required this.isMessageActionLoading,
    required this.onTap,
    this.profile,
    this.onProfileTap,
    this.onMessageTap,
  });

  final ExcursionOfferVm offer;
  final bool isSelected;
  final bool isCurrentUserOffer;
  final bool showMessageAction;
  final bool isMessageActionLoading;
  final VoidCallback onTap;
  final UserProfileVm? profile;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guideName = _offerGuideName(l10n);
    final language = _formatLanguageLabels(l10n, offer.languageCodes);
    final groupSize = offer.maxGroupSize > 0
        ? l10n.excursionDetailsGroupSizeUpTo(offer.maxGroupSize)
        : '';
    final semanticLabel = [
      guideName,
      _formatOfferPrice(context, offer),
      if (groupSize.isNotEmpty) groupSize,
      if (language.isNotEmpty) language,
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isCurrentUserOffer
                  ? AppColors.success.withValues(alpha: 0.11)
                  : isSelected
                  ? AppColors.accent.withValues(alpha: 0.13)
                  : const Color(0xFF312316),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrentUserOffer
                    ? AppColors.success.withValues(alpha: 0.68)
                    : isSelected
                    ? AppColors.accent.withValues(alpha: 0.76)
                    : Colors.white.withValues(alpha: 0.055),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideAvatar(
                  imageUrl: _resolveExcursionGuideAvatarUrl(profile),
                  fallbackText: _displayInitials(guideName, fallback: 'G'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              guideName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                          ),
                          if (isCurrentUserOffer || isSelected) ...[
                            const SizedBox(width: 8),
                            _SelectedOfferBadge(
                              label: isCurrentUserOffer
                                  ? l10n.excursionDetailsOfferCurrentUser
                                  : l10n.excursionDetailsOfferSelected,
                              color: isCurrentUserOffer
                                  ? AppColors.success
                                  : AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 10,
                        runSpacing: 7,
                        children: [
                          _OfferMetaChip(
                            icon: Icons.payments_rounded,
                            label: _formatOfferPrice(context, offer),
                            accent: true,
                          ),
                          if (groupSize.isNotEmpty)
                            _OfferMetaChip(
                              icon: Icons.group_rounded,
                              label: groupSize,
                            ),
                          if (language.isNotEmpty)
                            _OfferMetaChip(
                              icon: Icons.translate_rounded,
                              label: language,
                              allowMultiline: true,
                            ),
                        ],
                      ),
                      if (isSelected &&
                          (onProfileTap != null || showMessageAction)) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (onProfileTap != null)
                              OutlinedButton.icon(
                                onPressed: onProfileTap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  l10n.profileTitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (showMessageAction)
                              OutlinedButton(
                                onPressed: isMessageActionLoading
                                    ? null
                                    : onMessageTap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: isMessageActionLoading
                                      ? const SizedBox(
                                          key: ValueKey(
                                            'offer-message-guide-progress',
                                          ),
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.accent,
                                          ),
                                        )
                                      : Text(
                                          l10n.excursionDetailsMessageGuide,
                                          key: const ValueKey(
                                            'offer-message-guide-label',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _offerGuideName(AppLocalizations l10n) {
    final profileName = profile == null
        ? ''
        : _formatGuideFullName(profile!).trim();
    if (profileName.isNotEmpty) {
      return profileName;
    }
    return l10n.excursionDetailsGuideName;
  }
}

class _SelectedOfferBadge extends StatelessWidget {
  const _SelectedOfferBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1,
          ).copyWith(color: color),
        ),
      ),
    );
  }
}

class _OfferMetaChip extends StatelessWidget {
  const _OfferMetaChip({
    required this.icon,
    required this.label,
    this.accent = false,
    this.allowMultiline = false,
  });

  final IconData icon;
  final String label;
  final bool accent;
  final bool allowMultiline;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: allowMultiline ? 1 : 0),
              child: Icon(
                icon,
                color: accent ? AppColors.accent : const Color(0xFFB9A99A),
                size: 14,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: allowMultiline ? null : 1,
                overflow: allowMultiline
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent ? AppColors.accent : const Color(0xFFE8DDD2),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: allowMultiline ? 1.18 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideAvatar extends StatelessWidget {
  const _GuideAvatar({required this.fallbackText, this.imageUrl});

  final String? imageUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
          width: 2,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2423), Color(0xFF52311E), Color(0xFF100C08)],
        ),
      ),
      child: ClipOval(
        child: (imageUrl ?? '').trim().isEmpty
            ? Center(
                child: Text(
                  fallbackText,
                  style: const TextStyle(
                    color: Color(0xFFFFE3B8),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    fallbackText,
                    style: const TextStyle(
                      color: Color(0xFFFFE3B8),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ExcursionMapPreview extends StatelessWidget {
  const _ExcursionMapPreview({required this.excursion});

  final ExcursionVm excursion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final point = LatLng(
      excursion.latitude ?? 43.238949,
      excursion.longitude ?? 76.889709,
    );
    final label = excursion.meetingPoint.trim().isNotEmpty
        ? excursion.meetingPoint.trim()
        : excursion.cityName?.trim().isNotEmpty == true
        ? excursion.cityName!.trim()
        : l10n.excursionDetailsMapPreview;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          children: [
            AppMapCard(
              target: point,
              hasMarker: true,
              height: 190,
              initialZoom: 14.8,
              borderRadius: 24,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A1209).withValues(alpha: 0.10),
                        Colors.transparent,
                        const Color(0xFF1A1209).withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF160F0A).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8DDD2),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcursionItinerarySection extends StatelessWidget {
  const _ExcursionItinerarySection({
    required this.excursion,
    required this.localizedLandmark,
  });

  final ExcursionVm excursion;
  final AttractionVm? localizedLandmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final summary = localizedExcursionSummary(
      languageCode: languageCode,
      excursion: excursion,
      attraction: localizedLandmark,
    );
    final steps = excursion.itinerary.isNotEmpty
        ? excursion.itinerary
        : [
            ExcursionItineraryItemVm(
              id: 'meeting',
              sortOrder: 0,
              startOffsetMinutes: 0,
              title: l10n.excursionDetailsMeetingPoint,
              description: excursion.meetingPoint.trim().isNotEmpty
                  ? excursion.meetingPoint.trim()
                  : summary,
            ),
          ];

    return _ExcursionSection(
      title: l10n.excursionDetailsItinerary,
      child: Stack(
        children: [
          Positioned(
            left: 13,
            top: 15,
            bottom: 10,
            child: Container(
              width: 1,
              color: AppColors.accent.withValues(alpha: 0.42),
            ),
          ),
          Column(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                _ExcursionItineraryStep(
                  step: steps[index],
                  index: index,
                  totalSteps: steps.length,
                  isFirst: index == 0,
                  languageCode: languageCode,
                ),
                if (index != steps.length - 1) const SizedBox(height: 30),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExcursionItineraryStep extends StatelessWidget {
  const _ExcursionItineraryStep({
    required this.step,
    required this.index,
    required this.totalSteps,
    required this.isFirst,
    required this.languageCode,
  });

  final ExcursionItineraryItemVm step;
  final int index;
  final int totalSteps;
  final bool isFirst;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _localizedItineraryTitle(
      context,
      step,
      languageCode,
      index,
      totalSteps,
    );
    final description = _localizedItineraryDescription(step, languageCode);
    final attractionName = step.attractionName?.trim() ?? '';
    final travelFromPreviousMinutes = step.travelFromPreviousMinutes;
    final metaChips = <Widget>[
      if (attractionName.isNotEmpty)
        _RouteStopMetaChip(icon: Icons.place_rounded, label: attractionName),
      if (travelFromPreviousMinutes != null && travelFromPreviousMinutes > 0)
        _RouteStopMetaChip(
          icon: Icons.route_rounded,
          label: l10n.excursionDetailsTravelFromPrevious(
            travelFromPreviousMinutes,
          ),
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: isFirst
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.65)),
          ),
          alignment: Alignment.center,
          child: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFBAAB9D),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              if (metaChips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: metaChips),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteStopMetaChip extends StatelessWidget {
  const _RouteStopMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedItineraryTitle(
  BuildContext context,
  ExcursionItineraryItemVm step,
  String languageCode,
  int index,
  int totalSteps,
) {
  final translated = _itineraryTranslationFor(step, languageCode)?.title ?? '';
  if (translated.trim().isNotEmpty) return translated.trim();

  final title = step.title.trim();
  if (title.isNotEmpty) return title;

  return AppLocalizations.of(context)!.createStepCounter(index + 1, totalSteps);
}

String _localizedItineraryDescription(
  ExcursionItineraryItemVm step,
  String languageCode,
) {
  final translated =
      _itineraryTranslationFor(step, languageCode)?.description ?? '';
  if (translated.trim().isNotEmpty) return translated.trim();

  final description = step.description.trim();
  if (description.isNotEmpty) return description;

  return '';
}

ExcursionItineraryLocalizedCopyVm? _itineraryTranslationFor(
  ExcursionItineraryItemVm step,
  String languageCode,
) {
  final normalized = _normalizeLanguageCode(languageCode);
  if (normalized.isEmpty || step.translations.isEmpty) return null;
  return step.translations[normalized] ??
      step.translations[normalized.split('-').first];
}

class _ExcursionReviewsSection extends StatelessWidget {
  const _ExcursionReviewsSection({
    required this.reviews,
    required this.currentUserId,
    this.onReviewLongPress,
  });

  final List<ExcursionReviewVm> reviews;
  final String currentUserId;
  final ValueChanged<ExcursionReviewVm>? onReviewLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (reviews.isEmpty) {
      return _ExcursionSection(
        title: l10n.excursionReviewsTitle,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Text(
            l10n.excursionReviewsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textCaption,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return _ExcursionSection(
      title: l10n.excursionReviewsTitle,
      child: Column(
        children: [
          for (var i = 0; i < reviews.length; i++) ...[
            _ExcursionReviewCard(
              review: reviews[i],
              currentUserId: currentUserId,
              onLongPress: onReviewLongPress,
            ),
            if (i < reviews.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ExcursionReviewCard extends StatelessWidget {
  const _ExcursionReviewCard({
    required this.review,
    required this.currentUserId,
    this.onLongPress,
  });

  final ExcursionReviewVm review;
  final String currentUserId;
  final ValueChanged<ExcursionReviewVm>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guideName = review.guideDisplayName.trim().isEmpty
        ? l10n.myExcursionsGuideFallback
        : review.guideDisplayName.trim();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.attractionTravelerFallback
        : review.author.resolvedDisplayName;
    final authorAvatarUrl = review.author.resolvedAvatarFileId.isEmpty
        ? null
        : resolvePublicFileContentUrl(review.author.resolvedAvatarFileId);
    final canManage =
        currentUserId.isNotEmpty &&
        review.author.userId.trim() == currentUserId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: canManage && onLongPress != null
          ? () => onLongPress!(review)
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF245163),
                  backgroundImage: authorAvatarUrl != null
                      ? NetworkImage(authorAvatarUrl)
                      : null,
                  child: authorAvatarUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.excursionReviewViaGuide(guideName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD8C2AD),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 18,
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD7BFAA),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExcursionSection extends StatelessWidget {
  const _ExcursionSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _ExcursionBookingUnavailableNotice extends StatelessWidget {
  const _ExcursionBookingUnavailableNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E140B).withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 13, 14, math.max(13, safeBottom)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.34),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
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

class _ExcursionCheckoutBar extends StatelessWidget {
  const _ExcursionCheckoutBar({
    required this.excursion,
    required this.label,
    required this.icon,
    required this.showPrice,
    required this.onTap,
    this.helperText,
  });

  final ExcursionVm excursion;
  final String label;
  final IconData icon;
  final bool showPrice;
  final VoidCallback onTap;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E140B).withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 13, 14, math.max(13, safeBottom)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (showPrice) ...[
                    SizedBox(
                      width: 96,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.excursionDetailsTotal.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFB8A898),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPrice(context, excursion),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(icon, size: 16),
                      label: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if ((helperText ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    helperText!,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Color(0xFFB8A898),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionDetailsLoading extends StatelessWidget {
  const _ExcursionDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF1A1209),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

String _formatDuration(BuildContext context, int minutes) {
  if (minutes <= 0) return '';

  final l10n = AppLocalizations.of(context)!;
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;

  if (hours > 0 && remainder > 0) {
    return '$hours ${l10n.excursionsDurationHourShort} '
        '$remainder ${l10n.excursionsDurationMinuteShort}';
  }
  if (hours > 0) {
    return '$hours ${l10n.excursionsDurationHourShort}';
  }
  return '$minutes ${l10n.excursionsDurationMinuteShort}';
}

String _formatPrice(BuildContext context, ExcursionVm excursion) {
  final l10n = AppLocalizations.of(context)!;
  if (excursion.priceAmount <= 0) return l10n.excursionsFreePrice;

  final decimalDigits =
      excursion.priceAmount == excursion.priceAmount.truncateToDouble() ? 0 : 2;

  try {
    return NumberFormat.simpleCurrency(
      name: excursion.currency,
      decimalDigits: decimalDigits,
    ).format(excursion.priceAmount);
  } catch (_) {
    return '${excursion.priceAmount.toStringAsFixed(decimalDigits)} ${excursion.currency}';
  }
}

String _formatOfferPrice(BuildContext context, ExcursionOfferVm offer) {
  final l10n = AppLocalizations.of(context)!;
  if (offer.priceAmount <= 0) return l10n.excursionsFreePrice;

  final decimalDigits =
      offer.priceAmount == offer.priceAmount.truncateToDouble() ? 0 : 2;

  try {
    return NumberFormat.simpleCurrency(
      name: offer.currency,
      decimalDigits: decimalDigits,
    ).format(offer.priceAmount);
  } catch (_) {
    return '${offer.priceAmount.toStringAsFixed(decimalDigits)} ${offer.currency}';
  }
}

String _formatLanguageLabels(
  AppLocalizations l10n,
  List<String> languageCodes,
) {
  return formatLocalizedExcursionLanguages(l10n, languageCodes);
}

String _formatGuideFullName(UserProfileVm profile) {
  final lastName = (profile.lastName ?? '').trim();
  final firstName = (profile.firstName ?? '').trim();

  if (lastName.isNotEmpty && firstName.isNotEmpty) {
    return '$lastName ${firstName[0]}.';
  }
  if (lastName.isNotEmpty) {
    return lastName;
  }
  if (firstName.isNotEmpty) {
    return firstName;
  }
  return profile.preferredName;
}

String _normalizeOfferSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[@_.,;:\/\\|()\[\]{}<>+\-=]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _resolveExcursionGuideAvatarUrl(UserProfileVm? profile) {
  final avatarFileId = (profile?.avatarFileId ?? '').trim();
  return resolvePublicFileContentUrl(avatarFileId);
}

String _displayInitials(String value, {String fallback = 'FG'}) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return fallback;
  }
  if (parts.length >= 2) {
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
  final normalized = parts.first.replaceAll(
    RegExp(r'[^A-Za-zА-Яа-яӘәҒғҚқҢңӨөҰұҮүҺһІі0-9]'),
    '',
  );
  if (normalized.length >= 2) {
    return normalized.substring(0, 2).toUpperCase();
  }
  if (normalized.isNotEmpty) {
    return normalized[0].toUpperCase();
  }
  return fallback;
}

String _categoryLabel(BuildContext context, String? categorySlug) {
  final l10n = AppLocalizations.of(context)!;
  return localizedExcursionCategoryLabel(l10n, categorySlug);
}
