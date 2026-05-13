import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../../core/network/chat_api.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/tour_api.dart';
import '../../core/ui/app_inline_sort_row.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui/filter_sheet_chrome.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/tours/models/tour_vm.dart';
import '../../features/tours/tour_cover_url.dart';
import '../../features/tours/tour_localization.dart';
import '../../features/tours/tour_search.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/tour_provider.dart';
import 'tour_booking_screen.dart';

class TourDetailsScreen extends StatefulWidget {
  const TourDetailsScreen({super.key, required this.tourId, this.initialTour});

  final String tourId;
  final TourVm? initialTour;

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  final AttractionApi _attractionApi = AttractionApi();
  final ProfileApi _profileApi = ProfileApi();
  final ChatApi _chatApi = ChatApi();
  AttractionVm? _localizedLandmark;
  String? _localizedLandmarkId;
  String? _localizedLandmarkLocale;
  String? _loadingLocalizedLandmarkId;
  Map<String, UserProfileVm> _resolvedProfiles = const {};
  final Set<String> _resolvingGuideUserIds = <String>{};
  List<TourOfferVm> _visibleOffers = const [];
  String? _visibleOffersTourId;
  String? _selectedOfferId;
  bool _isMessageGuideLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TourProvider>().loadTourDetails(
        widget.tourId,
        initialTour: widget.initialTour,
      );
    });
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/tours');
  }

  Future<void> _retry({TourVm? initialTour}) {
    return context.read<TourProvider>().loadTourDetails(
      widget.tourId,
      initialTour: initialTour ?? widget.initialTour,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileNotAvailable)));
      return;
    }
    context.push(
      '/users/$guideUserId/profile',
      extra: _resolvedProfiles[guideUserId],
    );
  }

  void _openBooking(TourVm tour, TourOfferVm? selectedOffer) {
    final tourId = tour.id.trim();
    if (tourId.isEmpty) return;
    final bookingTour = selectedOffer == null
        ? tour
        : tour.withPrimaryOffer(selectedOffer);

    context.push(
      '/tours/${Uri.encodeComponent(tour.id)}/booking',
      extra: TourBookingRouteArgs(
        tour: bookingTour,
        selectedOfferId: selectedOffer?.id,
      ),
    );
  }

  Future<void> _openEditOffer(TourVm tour, TourOfferVm? selectedOffer) async {
    final legacyTourId = (selectedOffer?.legacyTourId ?? '').trim();
    if (legacyTourId.isEmpty) {
      _showInfoSnack(AppLocalizations.of(context)!.tourDetailsLoadFailed);
      return;
    }
    final editableTour = selectedOffer == null
        ? tour
        : tour.withPrimaryOffer(selectedOffer);
    final updated = await context.push<TourVm>(
      '/tours/${Uri.encodeComponent(legacyTourId)}/edit',
      extra: editableTour,
    );
    if (!mounted) return;
    if (updated != null) {
      final updatedProductId = updated.id.trim();
      setState(() {
        _visibleOffersTourId = updatedProductId.isNotEmpty
            ? updatedProductId
            : null;
        _visibleOffers = updated.offers;
        _selectedOfferId = updated.offers.isNotEmpty
            ? updated.offers.first.id
            : null;
      });
      await _retry(initialTour: updated);
    }
  }

  void _selectOffer(TourOfferVm offer) {
    setState(() => _selectedOfferId = offer.id);
  }

  List<TourOfferVm> _offersFor(TourVm tour) {
    if (_visibleOffersTourId == tour.id) {
      return _visibleOffers;
    }
    return tour.offers;
  }

  void _scheduleLoadLocalizedLandmark(TourVm tour) {
    final landmarkId = tour.landmarkId?.trim();
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

  void _replaceVisibleOffers(String tourId, List<TourOfferVm> offers) {
    setState(() {
      _visibleOffersTourId = tourId;
      _visibleOffers = offers;
    });
  }

  TourOfferVm? _selectedOfferFor(TourVm tour, List<TourOfferVm> offers) {
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
      body: Consumer<TourProvider>(
        builder: (context, provider, _) {
          final tour = provider.selectedTour;
          final isInitialLoading =
              provider.detailState == TourDetailState.loading && tour == null;
          final isInitialError =
              provider.detailState == TourDetailState.error && tour == null;

          if (isInitialLoading) {
            return const _TourDetailsLoading();
          }

          if (isInitialError) {
            return SafeArea(
              child: ErrorView(
                message:
                    provider.detailErrorMessage ?? l10n.tourDetailsLoadFailed,
                onRetry: _retry,
              ),
            );
          }

          if (tour == null) {
            return const _TourDetailsLoading();
          }

          _scheduleLoadLocalizedLandmark(tour);
          final offers = _offersFor(tour);
          final selectedOffer = _selectedOfferFor(tour, offers);
          final displayTour = selectedOffer == null
              ? tour
              : tour.withPrimaryOffer(selectedOffer);
          final guideUserId =
              (selectedOffer?.guideUserId ?? tour.guideUserId ?? '').trim();
          final hasBookableOffer = offers.isNotEmpty;
          final currentUserId = (session.profile?.userId ?? '').trim();
          final isCurrentUserGuide =
              session.profile?.roles.any(
                (role) => role.trim().toUpperCase() == 'GUIDE',
              ) ??
              false;
          final isAuthor =
              guideUserId.isNotEmpty && currentUserId == guideUserId;
          _scheduleResolveGuideProfiles(
            offers.map((offer) => offer.guideUserId),
            session.profile,
            session.isAuthenticated,
          );
          final offerProfiles = <String, UserProfileVm>{..._resolvedProfiles};
          if (session.profile != null && currentUserId.isNotEmpty) {
            offerProfiles[currentUserId] = session.profile!;
          }

          return TourDetailsContent(
            tour: displayTour,
            localizedLandmark: _localizedLandmark,
            offers: offers,
            selectedOffer: selectedOffer,
            currentUserId: currentUserId,
            isCurrentUserGuide: isCurrentUserGuide,
            enableRemoteOffers: true,
            offerProfiles: offerProfiles,
            showMessageGuide: !isAuthor && guideUserId.isNotEmpty,
            showBookingAction: !isAuthor && hasBookableOffer,
            showCheckoutPrice:
                !isCurrentUserGuide && !isAuthor && hasBookableOffer,
            showEditOfferAction:
                isAuthor &&
                (selectedOffer?.legacyTourId ?? '').trim().isNotEmpty,
            isMessageGuideLoading: _isMessageGuideLoading,
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
            onBookTap: () => _openBooking(tour, selectedOffer),
            onEditOfferTap: () => _openEditOffer(tour, selectedOffer),
            onMessageGuideTap: () => _openGuideChat(guideUserId),
            onOfferSelected: _selectOffer,
            onOffersChanged: (offers) => _replaceVisibleOffers(tour.id, offers),
          );
        },
      ),
    );
  }
}

class TourDetailsContent extends StatelessWidget {
  const TourDetailsContent({
    super.key,
    required this.tour,
    required this.selectedOffer,
    required this.offerProfiles,
    required this.onBookTap,
    required this.onEditOfferTap,
    required this.onMessageGuideTap,
    required this.onOfferSelected,
    this.offers,
    this.onOfferProfileTap,
    this.currentUserId = '',
    this.isCurrentUserGuide = false,
    this.enableRemoteOffers = false,
    this.showMessageGuide = true,
    this.showBookingAction = true,
    this.showCheckoutPrice = true,
    this.showEditOfferAction = false,
    this.isMessageGuideLoading = false,
    this.onBackTap,
    this.onNotificationsTap,
    this.onOffersChanged,
    this.localizedLandmark,
  });

  final TourVm tour;
  final AttractionVm? localizedLandmark;
  final List<TourOfferVm>? offers;
  final TourOfferVm? selectedOffer;
  final Map<String, UserProfileVm> offerProfiles;
  final VoidCallback onBookTap;
  final VoidCallback onEditOfferTap;
  final VoidCallback onMessageGuideTap;
  final ValueChanged<TourOfferVm> onOfferSelected;
  final ValueChanged<TourOfferVm>? onOfferProfileTap;
  final String currentUserId;
  final bool isCurrentUserGuide;
  final bool enableRemoteOffers;
  final bool showMessageGuide;
  final bool showBookingAction;
  final bool showCheckoutPrice;
  final bool showEditOfferAction;
  final bool isMessageGuideLoading;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<List<TourOfferVm>>? onOffersChanged;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final activeSelectedOffer = selectedOffer;
    final visibleOffers = offers ?? tour.offers;
    final scrollBottomPadding =
        (showBookingAction || showEditOfferAction ? 116.0 : 24.0) +
        bottomPadding;

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
            child: _TourDetailsTopBar(
              onBackTap: onBackTap,
              onNotificationsTap: onNotificationsTap,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: scrollBottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TourHero(
                          tour: tour,
                          localizedLandmark: localizedLandmark,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TourStatsGrid(tour: tour),
                              const SizedBox(height: 40),
                              _TourExperienceSection(
                                tour: tour,
                                localizedLandmark: localizedLandmark,
                              ),
                              const SizedBox(height: 44),
                              _TourOffersSection(
                                tour: tour,
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
                                  activeSelectedOffer
                                      .includedItems
                                      .isNotEmpty) ...[
                                const SizedBox(height: 44),
                                _TourSelectedOfferIncludedSection(
                                  selectedOffer: activeSelectedOffer,
                                ),
                              ],
                              const SizedBox(height: 44),
                              _TourMapPreview(tour: tour),
                              const SizedBox(height: 44),
                              _TourItinerarySection(
                                tour: tour,
                                localizedLandmark: localizedLandmark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showBookingAction || showEditOfferAction)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _TourCheckoutBar(
                      tour: tour,
                      label: showEditOfferAction
                          ? AppLocalizations.of(context)!.tourDetailsEditOffer
                          : AppLocalizations.of(context)!.tourDetailsBook,
                      icon: showEditOfferAction
                          ? Icons.edit_rounded
                          : Icons.arrow_forward_ios_rounded,
                      showPrice: showCheckoutPrice && showBookingAction,
                      onTap: showEditOfferAction ? onEditOfferTap : onBookTap,
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

class _TourDetailsTopBar extends StatelessWidget {
  const _TourDetailsTopBar({
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
                  l10n.tourDetailsTitle,
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
            width: 40,
            height: 40,
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

class _TourHero extends StatelessWidget {
  const _TourHero({required this.tour, required this.localizedLandmark});

  final TourVm tour;
  final AttractionVm? localizedLandmark;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveTourCoverUrl(tour)?.trim() ?? '';
    final label = _categoryLabel(context, tour.categorySlug);
    final title = localizedTourTitle(
      languageCode: Localizations.localeOf(context).languageCode,
      tour: tour,
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
              errorBuilder: (_, _, _) => const _TourHeroFallback(),
            )
          else
            const _TourHeroFallback(),
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
                        tour.durationMinutes,
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

class _TourHeroFallback extends StatelessWidget {
  const _TourHeroFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _TourHeroPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TourHeroPainter extends CustomPainter {
  const _TourHeroPainter();

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

class _TourStatsGrid extends StatelessWidget {
  const _TourStatsGrid({required this.tour});

  final TourVm tour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = _formatLanguageLabels(l10n, tour.languageCodes);
    final cards = [
      _TourStatData(
        label: l10n.tourDetailsPrice,
        value: _formatPrice(context, tour),
        suffix: l10n.tourDetailsPerPerson,
        accent: true,
      ),
      _TourStatData(
        label: l10n.tourDetailsIntensity,
        value: l10n.tourDetailsIntensityModerate,
      ),
      _TourStatData(
        label: l10n.tourDetailsGroupSize,
        value: tour.maxGroupSize > 0
            ? l10n.tourDetailsGroupSizeUpTo(tour.maxGroupSize)
            : '-',
      ),
      _TourStatData(label: l10n.tourDetailsLanguage, value: language),
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
                child: _TourStatCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _TourStatData {
  const _TourStatData({
    required this.label,
    required this.value,
    this.suffix,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool accent;
}

class _TourStatCard extends StatelessWidget {
  const _TourStatCard({required this.data});

  final _TourStatData data;

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: data.value,
              style: TextStyle(
                color: data.accent ? AppColors.accent : AppColors.textPrimary,
                fontSize: data.accent ? 24 : 20,
                fontWeight: FontWeight.w800,
                height: 1.08,
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

class _TourExperienceSection extends StatelessWidget {
  const _TourExperienceSection({
    required this.tour,
    required this.localizedLandmark,
  });

  final TourVm tour;
  final AttractionVm? localizedLandmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = localizedTourDescription(
      languageCode: Localizations.localeOf(context).languageCode,
      tour: tour,
      attraction: localizedLandmark,
      fallback: l10n.tourDetailsNoDescription,
    );

    return _TourSection(
      title: l10n.tourDetailsExperience,
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

class _TourSelectedOfferIncludedSection extends StatelessWidget {
  const _TourSelectedOfferIncludedSection({required this.selectedOffer});

  final TourOfferVm selectedOffer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final features = _resolveTourIncludedFeatures(
      selectedOffer.localizedIncludedItems(languageCode),
      languageCode,
    );

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return _TourSection(
      title: l10n.tourDetailsSelectedOfferIncluded,
      child: Column(
        children: [
          for (var index = 0; index < features.length; index++) ...[
            _TourFeatureCard(feature: features[index]),
            if (index != features.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _TourFeatureCard extends StatelessWidget {
  const _TourFeatureCard({required this.feature});

  final _TourIncludedFeature feature;

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

enum _TourIncludedFeatureType {
  transport,
  food,
  tickets,
  equipment,
  guide,
  photo,
  other,
}

class _TourIncludedFeature {
  const _TourIncludedFeature({required this.type, required this.label});

  final _TourIncludedFeatureType type;
  final String label;
}

List<_TourIncludedFeature> _resolveTourIncludedFeatures(
  List<String> source,
  String languageCode,
) {
  return source
      .map((item) => _parseTourIncludedFeature(item, languageCode))
      .where((feature) => feature.label.isNotEmpty)
      .toList(growable: false);
}

_TourIncludedFeature _parseTourIncludedFeature(
  String rawValue,
  String languageCode,
) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return const _TourIncludedFeature(
      type: _TourIncludedFeatureType.other,
      label: '',
    );
  }

  final directType = _includedFeatureTypeFromPrefix(value.toLowerCase());
  if (directType != null) {
    return _TourIncludedFeature(
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
      return _TourIncludedFeature(
        type: type,
        label: _isTextCompatibleWithLocale(label, languageCode)
            ? label
            : _includedFeatureTypeLabel(type, languageCode),
      );
    }
  }

  if (!_isTextCompatibleWithLocale(value, languageCode)) {
    final type = _guessIncludedFeatureType(value);
    return _TourIncludedFeature(
      type: type,
      label: _includedFeatureTypeLabel(type, languageCode),
    );
  }

  return _TourIncludedFeature(
    type: _guessIncludedFeatureType(value),
    label: value,
  );
}

_TourIncludedFeatureType? _includedFeatureTypeFromPrefix(String prefix) {
  return switch (prefix) {
    'transport' || 'транспорт' || 'көлік' => _TourIncludedFeatureType.transport,
    'food' ||
    'meal' ||
    'meals' ||
    'питание' ||
    'еда' ||
    'тамақ' => _TourIncludedFeatureType.food,
    'tickets' ||
    'ticket' ||
    'билеты' ||
    'билет' ||
    'билеттер' => _TourIncludedFeatureType.tickets,
    'equipment' ||
    'gear' ||
    'снаряжение' ||
    'жабдық' => _TourIncludedFeatureType.equipment,
    'guide' || 'гид' => _TourIncludedFeatureType.guide,
    'photo' || 'photos' || 'фото' => _TourIncludedFeatureType.photo,
    'other' || 'другое' || 'басқа' => _TourIncludedFeatureType.other,
    _ => null,
  };
}

String _includedFeatureTypeLabel(
  _TourIncludedFeatureType type,
  String languageCode,
) {
  final normalized = _normalizeLanguageCode(languageCode);
  final labels = switch (type) {
    _TourIncludedFeatureType.transport => const {
      'en': 'Transport',
      'ru': 'Транспорт',
      'kk': 'Көлік',
    },
    _TourIncludedFeatureType.food => const {
      'en': 'Food',
      'ru': 'Питание',
      'kk': 'Тамақ',
    },
    _TourIncludedFeatureType.tickets => const {
      'en': 'Tickets',
      'ru': 'Билеты',
      'kk': 'Билеттер',
    },
    _TourIncludedFeatureType.equipment => const {
      'en': 'Equipment',
      'ru': 'Снаряжение',
      'kk': 'Жабдық',
    },
    _TourIncludedFeatureType.guide => const {
      'en': 'Guide',
      'ru': 'Гид',
      'kk': 'Гид',
    },
    _TourIncludedFeatureType.photo => const {
      'en': 'Photo',
      'ru': 'Фото',
      'kk': 'Фото',
    },
    _TourIncludedFeatureType.other => const {
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

_TourIncludedFeatureType _guessIncludedFeatureType(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('car') ||
      normalized.contains('suv') ||
      normalized.contains('transfer') ||
      normalized.contains('transport') ||
      normalized.contains('авто') ||
      normalized.contains('трансфер') ||
      normalized.contains('көлік')) {
    return _TourIncludedFeatureType.transport;
  }
  if (normalized.contains('food') ||
      normalized.contains('meal') ||
      normalized.contains('lunch') ||
      normalized.contains('picnic') ||
      normalized.contains('еда') ||
      normalized.contains('обед') ||
      normalized.contains('тамақ')) {
    return _TourIncludedFeatureType.food;
  }
  if (normalized.contains('ticket') ||
      normalized.contains('entry') ||
      normalized.contains('билет') ||
      normalized.contains('кіру')) {
    return _TourIncludedFeatureType.tickets;
  }
  if (normalized.contains('gear') ||
      normalized.contains('equipment') ||
      normalized.contains('снаряж') ||
      normalized.contains('жабдық')) {
    return _TourIncludedFeatureType.equipment;
  }
  if (normalized.contains('photo') ||
      normalized.contains('фото') ||
      normalized.contains('сурет')) {
    return _TourIncludedFeatureType.photo;
  }
  if (normalized.contains('guide') ||
      normalized.contains('гид') ||
      normalized.contains('нұсқаушы')) {
    return _TourIncludedFeatureType.guide;
  }
  return _TourIncludedFeatureType.other;
}

IconData _includedFeatureIcon(_TourIncludedFeature feature) {
  return switch (feature.type) {
    _TourIncludedFeatureType.transport => Icons.directions_car_filled_rounded,
    _TourIncludedFeatureType.food => Icons.restaurant_rounded,
    _TourIncludedFeatureType.tickets => Icons.confirmation_number_rounded,
    _TourIncludedFeatureType.equipment => Icons.backpack_rounded,
    _TourIncludedFeatureType.guide => Icons.person_pin_circle_rounded,
    _TourIncludedFeatureType.photo => Icons.photo_camera_rounded,
    _TourIncludedFeatureType.other => Icons.check_circle_rounded,
  };
}

enum _TourOfferSortMode { rating, experience, price }

extension _TourOfferSortModeX on _TourOfferSortMode {
  String label(AppLocalizations l10n) {
    return switch (this) {
      _TourOfferSortMode.rating => l10n.tourDetailsOffersSortRating,
      _TourOfferSortMode.experience => l10n.tourDetailsOffersSortExperience,
      _TourOfferSortMode.price => l10n.tourDetailsOffersSortPrice,
    };
  }

  String get apiValue {
    return switch (this) {
      _TourOfferSortMode.rating => 'rating',
      _TourOfferSortMode.experience => 'experience',
      _TourOfferSortMode.price => 'price',
    };
  }

  _TourOfferSortDirection get defaultDirection {
    return switch (this) {
      _TourOfferSortMode.price => _TourOfferSortDirection.asc,
      _ => _TourOfferSortDirection.desc,
    };
  }
}

enum _TourOfferSortDirection { asc, desc }

extension _TourOfferSortDirectionX on _TourOfferSortDirection {
  String get apiValue {
    return switch (this) {
      _TourOfferSortDirection.asc => 'asc',
      _TourOfferSortDirection.desc => 'desc',
    };
  }

  _TourOfferSortDirection get toggled {
    return switch (this) {
      _TourOfferSortDirection.asc => _TourOfferSortDirection.desc,
      _TourOfferSortDirection.desc => _TourOfferSortDirection.asc,
    };
  }

  bool get isAscending => this == _TourOfferSortDirection.asc;
}

class _TourOfferFilters {
  const _TourOfferFilters({
    this.languageCode,
    this.priceMax,
    this.maxGroupSizeMin,
  });

  final String? languageCode;
  final double? priceMax;
  final int? maxGroupSizeMin;

  int get activeCount =>
      ((languageCode ?? '').trim().isEmpty ? 0 : 1) +
      (priceMax == null ? 0 : 1) +
      (maxGroupSizeMin == null ? 0 : 1);
}

class _TourOffersSection extends StatefulWidget {
  const _TourOffersSection({
    required this.tour,
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

  final TourVm tour;
  final List<TourOfferVm> offers;
  final TourOfferVm? selectedOffer;
  final String currentUserId;
  final bool isCurrentUserGuide;
  final bool enableRemoteOffers;
  final Map<String, UserProfileVm> offerProfiles;
  final bool showMessageGuide;
  final bool isMessageGuideLoading;
  final ValueChanged<TourOfferVm> onOfferSelected;
  final VoidCallback onMessageGuideTap;
  final ValueChanged<List<TourOfferVm>>? onOffersChanged;
  final ValueChanged<TourOfferVm>? onOfferProfileTap;

  @override
  State<_TourOffersSection> createState() => _TourOffersSectionState();
}

class _TourOffersSectionState extends State<_TourOffersSection> {
  static const _pageSize = 20;

  final TourApi _tourApi = TourApi();
  final TextEditingController _offerSearchController = TextEditingController();
  Timer? _offerSearchDebounce;
  List<TourOfferVm> _offers = const [];
  _TourOfferFilters _filters = const _TourOfferFilters();
  _TourOfferSortMode _sortMode = _TourOfferSortMode.rating;
  _TourOfferSortDirection _sortDirection = _TourOfferSortDirection.desc;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorText;
  String _offerSearchQuery = '';
  int _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _offers = _prioritizeCurrentGuideOffer(widget.offers);
    _hasMore = widget.tour.publishedOffersCount > _offers.length;
    if (widget.enableRemoteOffers) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOffers());
    }
  }

  @override
  void didUpdateWidget(covariant _TourOffersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRefreshOffers = _shouldRefreshOffersAfterWidgetUpdate(
      oldWidget,
    );
    if (oldWidget.tour.id != widget.tour.id ||
        oldWidget.offers != widget.offers ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.isCurrentUserGuide != widget.isCurrentUserGuide) {
      setState(() {
        _offers = _prioritizeCurrentGuideOffer(widget.offers);
        _hasMore = widget.tour.publishedOffersCount > _offers.length;
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

  bool _shouldRefreshOffersAfterWidgetUpdate(_TourOffersSection oldWidget) {
    if (!widget.enableRemoteOffers) return false;
    if (oldWidget.tour.id != widget.tour.id) return true;

    final staleEmptyOffersBecameVisible =
        widget.offers.isEmpty &&
        widget.tour.publishedOffersCount > 0 &&
        (oldWidget.offers != widget.offers ||
            oldWidget.tour.publishedOffersCount !=
                widget.tour.publishedOffersCount ||
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
      final page = await _tourApi.getTourOffers(
        widget.tour.id,
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
        )!.tourDetailsOffersLoadFailed,
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

  void _onSortChanged(_TourOfferSortMode value) {
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
    final next = await showModalBottomSheet<_TourOfferFilters>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TourOffersFilterSheet(filters: _filters),
    );
    if (!mounted || next == null) return;
    setState(() => _filters = next);
    _refreshOffers();
  }

  List<TourOfferVm> _mergeOffers(
    List<TourOfferVm> current,
    List<TourOfferVm> incoming,
  ) {
    final byId = <String, TourOfferVm>{
      for (final offer in current)
        if (offer.id.trim().isNotEmpty) offer.id: offer,
    };
    final merged = <TourOfferVm>[
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

  List<TourOfferVm> _prioritizeCurrentGuideOffer(List<TourOfferVm> offers) {
    final currentUserId = widget.currentUserId.trim();
    if (!widget.isCurrentUserGuide || currentUserId.isEmpty) {
      return offers;
    }
    final own = <TourOfferVm>[];
    final rest = <TourOfferVm>[];
    for (final offer in offers) {
      if (offer.guideUserId.trim() == currentUserId) {
        own.add(offer);
      } else {
        rest.add(offer);
      }
    }
    return [...own, ...rest];
  }

  bool _isCurrentUserOffer(TourOfferVm offer) {
    return widget.isCurrentUserGuide &&
        widget.currentUserId.trim().isNotEmpty &&
        widget.currentUserId.trim() == offer.guideUserId.trim();
  }

  List<TourOfferVm> _visibleOffers(AppLocalizations l10n) {
    final offers = _prioritizeCurrentGuideOffer(_offers);
    final searchGroups = tourSearchNeedleGroups(_offerSearchQuery);
    if (searchGroups.isEmpty) return offers;

    return offers
        .where((offer) {
          final haystack = _offerSearchHaystack(l10n, offer);
          return searchGroups.every(
            (variants) => variants.any(haystack.contains),
          );
        })
        .toList(growable: false);
  }

  String _offerSearchHaystack(AppLocalizations l10n, TourOfferVm offer) {
    final profile = widget.offerProfiles[offer.guideUserId];
    final firstName = (profile?.firstName ?? '').trim();
    final lastName = (profile?.lastName ?? '').trim();
    final displayName = (profile?.displayName ?? '').trim();
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
        localizedTourLanguageLabel(l10n, code),
      ],
      if (profile != null) ...[
        profile.userId,
        profile.preferredName,
        profile.initials,
        displayName,
        firstName,
        lastName,
        [firstName, lastName].where((value) => value.isNotEmpty).join(' '),
        [lastName, firstName].where((value) => value.isNotEmpty).join(' '),
        if (firstName.isNotEmpty && lastName.isNotEmpty)
          '$lastName ${firstName.substring(0, 1)}',
        if (displayName.startsWith('@')) displayName.substring(1),
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
    final searchGroups = tourSearchNeedleGroups(query);
    if (searchGroups.isEmpty) return false;

    return widget.offerProfiles.values.any((profile) {
      final firstName = (profile.firstName ?? '').trim();
      final lastName = (profile.lastName ?? '').trim();
      final displayName = (profile.displayName ?? '').trim();
      final profileHaystack = _normalizeOfferSearchText(
        [
          profile.userId,
          profile.preferredName,
          profile.initials,
          displayName,
          if (displayName.startsWith('@')) displayName.substring(1),
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

    return _TourSection(
      title: l10n.tourDetailsOffersTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TourOffersSearchField(
            controller: _offerSearchController,
            hintText: l10n.tourDetailsOffersSearchHint,
            activeFilterCount: _filters.activeCount,
            onChanged: _onSearchChanged,
            onFilterTap: _showFilters,
          ),
          const SizedBox(height: 14),
          _TourOffersSortBar(
            selected: _sortMode,
            direction: _sortDirection,
            onChanged: _onSortChanged,
          ),
          const SizedBox(height: 18),
          if (_isLoading && offers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (offers.isEmpty)
            _TourOffersEmpty(message: _errorText ?? l10n.tourDetailsOffersEmpty)
          else
            Column(
              children: [
                for (var index = 0; index < offers.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final offer = offers[index];
                      final isSelected = offer.id == widget.selectedOffer?.id;
                      final isCurrentUserOffer = _isCurrentUserOffer(offer);

                      return _TourOfferCard(
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
            _TourOffersEmpty(message: _errorText!),
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
                      l10n.tourDetailsOffersLoadMore,
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

class _TourOffersSearchField extends StatelessWidget {
  const _TourOffersSearchField({
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

class _TourOffersSortBar extends StatelessWidget {
  const _TourOffersSortBar({
    required this.selected,
    required this.direction,
    required this.onChanged,
  });

  final _TourOfferSortMode selected;
  final _TourOfferSortDirection direction;
  final ValueChanged<_TourOfferSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppInlineSortRow<_TourOfferSortMode>(
      label: l10n.toursSortLabel,
      options: [
        for (final mode in _TourOfferSortMode.values)
          AppInlineSortOption(value: mode, label: mode.label(l10n)),
      ],
      selectedValue: selected,
      isAscending: direction.isAscending,
      onSelected: onChanged,
      optionGap: 18,
    );
  }
}

class _TourOffersFilterSheet extends StatefulWidget {
  const _TourOffersFilterSheet({required this.filters});

  final _TourOfferFilters filters;

  @override
  State<_TourOffersFilterSheet> createState() => _TourOffersFilterSheetState();
}

class _TourOffersFilterSheetState extends State<_TourOffersFilterSheet> {
  late final TextEditingController _languageSearchController;
  late final TextEditingController _priceMaxController;
  late final TextEditingController _groupSizeController;
  String? _languageCode;
  String _languageSearchQuery = '';

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
  }

  @override
  void dispose() {
    _languageSearchController
      ..removeListener(_handleLanguageSearchChanged)
      ..dispose();
    _priceMaxController.dispose();
    _groupSizeController.dispose();
    super.dispose();
  }

  void _clear() {
    _languageSearchController.clear();
    setState(() => _languageCode = null);
    _priceMaxController.clear();
    _groupSizeController.clear();
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
    return localizedTourLanguageLabel(l10n, code);
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
      '$code ${localizedTourLanguageLabel(l10n, code)} $aliases',
    );
  }

  void _apply() {
    final priceMax = double.tryParse(
      _priceMaxController.text.trim().replaceAll(',', '.'),
    );
    final groupSize = int.tryParse(_groupSizeController.text.trim());
    Navigator.of(context).pop(
      _TourOfferFilters(
        languageCode: (_languageCode ?? '').trim().isEmpty
            ? null
            : _languageCode,
        priceMax: priceMax != null && priceMax > 0 ? priceMax : null,
        maxGroupSizeMin: groupSize != null && groupSize > 0 ? groupSize : null,
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
                title: l10n.tourDetailsOffersFiltersTitle,
                clearLabel: l10n.toursFiltersClear,
                onClear: _clear,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TourOffersFilterTitle(
                        icon: Icons.translate_rounded,
                        label: l10n.toursFilterLanguage,
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
                                          l10n.tourDetailsOffersLanguageAny,
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
                                      tooltip: l10n.toursFiltersClear,
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
                                  l10n.tourDetailsOffersLanguageSearchHint,
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
                                l10n.tourDetailsOffersLanguageNoResults,
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
                                    _TourOffersLanguageRow(
                                      label: localizedTourLanguageLabel(
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
                      _TourOffersFilterTitle(
                        icon: Icons.payments_rounded,
                        label: l10n.tourDetailsOffersMaxPrice,
                      ),
                      const SizedBox(height: 10),
                      _TourOffersNumberField(
                        controller: _priceMaxController,
                        hintText: l10n.tourDetailsOffersMaxPriceHint,
                      ),
                      const SizedBox(height: 24),
                      _TourOffersFilterTitle(
                        icon: Icons.group_rounded,
                        label: l10n.tourDetailsOffersMinGroup,
                      ),
                      const SizedBox(height: 10),
                      _TourOffersNumberField(
                        controller: _groupSizeController,
                        hintText: l10n.tourDetailsOffersMinGroupHint,
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
                  label: l10n.tourDetailsOffersApplyFilters,
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

class _TourOffersFilterTitle extends StatelessWidget {
  const _TourOffersFilterTitle({required this.icon, required this.label});

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

class _TourOffersLanguageRow extends StatelessWidget {
  const _TourOffersLanguageRow({
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

class _TourOffersNumberField extends StatelessWidget {
  const _TourOffersNumberField({
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

class _TourOffersEmpty extends StatelessWidget {
  const _TourOffersEmpty({required this.message});

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

class _TourOfferCard extends StatelessWidget {
  const _TourOfferCard({
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

  final TourOfferVm offer;
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
        ? l10n.tourDetailsGroupSizeUpTo(offer.maxGroupSize)
        : '';

    return Material(
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
                imageUrl: _resolveTourGuideAvatarUrl(profile),
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
                                ? l10n.tourDetailsOfferCurrentUser
                                : l10n.tourDetailsOfferSelected,
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
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              icon: const Icon(Icons.person_rounded, size: 16),
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
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                        l10n.tourDetailsMessageGuide,
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
    );
  }

  String _offerGuideName(AppLocalizations l10n) {
    final profileName = profile == null
        ? ''
        : _formatGuideSurnameInitials(profile!).trim();
    if (profileName.isNotEmpty) {
      return profileName;
    }
    return l10n.tourDetailsGuideName;
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
  });

  final IconData icon;
  final String label;
  final bool accent;

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
          children: [
            Icon(
              icon,
              color: accent ? AppColors.accent : const Color(0xFFB9A99A),
              size: 14,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent ? AppColors.accent : const Color(0xFFE8DDD2),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
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
                errorBuilder: (_, __, ___) => Center(
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

class _TourMapPreview extends StatelessWidget {
  const _TourMapPreview({required this.tour});

  final TourVm tour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final point = LatLng(
      tour.latitude ?? 43.238949,
      tour.longitude ?? 76.889709,
    );
    final label = tour.meetingPoint.trim().isNotEmpty
        ? tour.meetingPoint.trim()
        : tour.cityName?.trim().isNotEmpty == true
        ? tour.cityName!.trim()
        : l10n.tourDetailsMapPreview;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 14.8,
                minZoom: 3,
                maxZoom: 18,
                backgroundColor: const Color(0xFFB3A28D),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.dkhvan.flyfy.superapp',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 58,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: const _TourMeetingPointMarker(),
                    ),
                  ],
                ),
              ],
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

class _TourMeetingPointMarker extends StatelessWidget {
  const _TourMeetingPointMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 22,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 23),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.accent,
            border: Border.all(color: Colors.white, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _TourItinerarySection extends StatelessWidget {
  const _TourItinerarySection({
    required this.tour,
    required this.localizedLandmark,
  });

  final TourVm tour;
  final AttractionVm? localizedLandmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final summary = localizedTourSummary(
      languageCode: languageCode,
      tour: tour,
      attraction: localizedLandmark,
    );
    final steps = tour.itinerary.isNotEmpty
        ? tour.itinerary
        : [
            TourItineraryItemVm(
              id: 'meeting',
              sortOrder: 0,
              startOffsetMinutes: 0,
              title: l10n.tourDetailsMeetingPoint,
              description: tour.meetingPoint.trim().isNotEmpty
                  ? tour.meetingPoint.trim()
                  : summary,
            ),
          ];

    return _TourSection(
      title: l10n.tourDetailsItinerary,
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
                _TourItineraryStep(
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

class _TourItineraryStep extends StatelessWidget {
  const _TourItineraryStep({
    required this.step,
    required this.index,
    required this.totalSteps,
    required this.isFirst,
    required this.languageCode,
  });

  final TourItineraryItemVm step;
  final int index;
  final int totalSteps;
  final bool isFirst;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final title = _localizedItineraryTitle(
      context,
      step,
      languageCode,
      index,
      totalSteps,
    );
    final description = _localizedItineraryDescription(step, languageCode);

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
            ],
          ),
        ),
      ],
    );
  }
}

String _localizedItineraryTitle(
  BuildContext context,
  TourItineraryItemVm step,
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
  TourItineraryItemVm step,
  String languageCode,
) {
  final translated =
      _itineraryTranslationFor(step, languageCode)?.description ?? '';
  if (translated.trim().isNotEmpty) return translated.trim();

  final description = step.description.trim();
  if (description.isNotEmpty) return description;

  return '';
}

TourItineraryLocalizedCopyVm? _itineraryTranslationFor(
  TourItineraryItemVm step,
  String languageCode,
) {
  final normalized = _normalizeLanguageCode(languageCode);
  if (normalized.isEmpty || step.translations.isEmpty) return null;
  return step.translations[normalized] ??
      step.translations[normalized.split('-').first];
}

class _TourSection extends StatelessWidget {
  const _TourSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _TourCheckoutBar extends StatelessWidget {
  const _TourCheckoutBar({
    required this.tour,
    required this.label,
    required this.icon,
    required this.showPrice,
    required this.onTap,
  });

  final TourVm tour;
  final String label;
  final IconData icon;
  final bool showPrice;
  final VoidCallback onTap;

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
          child: Row(
            children: [
              if (showPrice) ...[
                SizedBox(
                  width: 96,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tourDetailsTotal.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFB8A898),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPrice(context, tour),
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
        ),
      ),
    );
  }
}

class _TourDetailsLoading extends StatelessWidget {
  const _TourDetailsLoading();

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

  final decimalDigits = tour.priceAmount == tour.priceAmount.truncateToDouble()
      ? 0
      : 2;

  try {
    return NumberFormat.simpleCurrency(
      name: tour.currency,
      decimalDigits: decimalDigits,
    ).format(tour.priceAmount);
  } catch (_) {
    return '${tour.priceAmount.toStringAsFixed(decimalDigits)} ${tour.currency}';
  }
}

String _formatOfferPrice(BuildContext context, TourOfferVm offer) {
  final l10n = AppLocalizations.of(context)!;
  if (offer.priceAmount <= 0) return l10n.toursFreePrice;

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
  return formatLocalizedTourLanguages(l10n, languageCodes);
}

String _formatGuideSurnameInitials(UserProfileVm profile) {
  final lastName = (profile.lastName ?? '').trim();
  final firstName = (profile.firstName ?? '').trim();

  if (lastName.isNotEmpty && firstName.isNotEmpty) {
    return '$lastName ${firstName.substring(0, 1).toUpperCase()}.';
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

String? _resolveTourGuideAvatarUrl(UserProfileVm? profile) {
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
  return localizedTourCategoryLabel(l10n, categorySlug);
}
