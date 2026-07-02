import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/device/device_context_service.dart';
import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/ui/app_inline_field_error.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/places/place_ui.dart';
import '../../features/places/data/place_api.dart';
import '../../features/places/models/place_review_vm.dart';
import '../../features/places/models/place_vm.dart';
import '../../features/routing/models/routing_models.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../features/excursions/models/excursion_vm.dart';
import '../../features/help_center/data/help_center_api.dart';
import '../../features/help_center/widgets/contextual_help_section.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_rate_provider.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/routing_provider.dart';
import '../../providers/session_provider.dart';
import '../../shared/map/app_map_links.dart';
import '../excursions/excursions_screen.dart';
import '../excursions/widgets/excursion_review_management_sheet.dart';
import '../map/map_screen.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

final class _PlaceDetailsColors {
  const _PlaceDetailsColors._(this.colors);

  final AppColors colors;

  static _PlaceDetailsColors of(BuildContext context) {
    return _PlaceDetailsColors._(AppDesignSystem.colorsFor(context));
  }

  Color get primary => colors.primary;
  Color get primaryPressed => colors.primaryPressed;
  Color get primarySoft => colors.primarySoft;
  Color get primaryContainer => colors.primaryContainer;
  Color get secondary => colors.secondary;
  Color get secondarySoft => colors.secondarySoft;
  Color get secondaryContainer => colors.secondaryContainer;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.danger;
  Color get background => colors.background;
  Color get backgroundDeep => colors.backgroundDeep;
  Color get backgroundWarm => colors.backgroundWarm;
  Color get surface => colors.surface;
  Color get surfaceRaised => colors.surfaceRaised;
  Color get surfaceHigh => colors.surfaceHigh;
  Color get surfaceWarm => colors.surfaceWarm;
  Color get surfaceTeal => colors.surfaceTeal;
  Color get detailCardSurface => colors.surfaceRaised;
  Color get detailCardBorder => colors.border;
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get textMuted => colors.textMuted;
  Color get textDisabled => colors.textDisabled;
  Color get border => colors.border;
  Color get borderSoft => colors.borderSoft;
  Color get transparent => colors.transparent;
  Color get black => colors.black;
  Color get white => colors.white;
  Color get scrim => colors.scrim;
}

extension _PlaceDetailsColorContext on BuildContext {
  _PlaceDetailsColors get placeColors => _PlaceDetailsColors.of(this);
}

LinearGradient? _placeHeroOverlayGradient(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.light) {
    return null;
  }

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      context.placeColors.transparent,
      context.placeColors.background.withValues(alpha: 0.96),
    ],
    stops: const [0.42, 1.0],
  );
}

Color _placeHeroTitleColor(BuildContext context, {required bool hasMedia}) {
  if (!hasMedia && Theme.of(context).brightness == Brightness.light) {
    return context.placeColors.textPrimary;
  }
  return context.placeColors.white;
}

class PlaceDetailsScreen extends StatefulWidget {
  const PlaceDetailsScreen({
    super.key,
    required this.placeId,
    this.initialPlace,
  });

  final String placeId;
  final PlaceVm? initialPlace;

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final PlaceApi _api = PlaceApi();
  final DeviceContextService _deviceContextService =
      const DeviceContextService();
  final FileApi _fileApi = FileApi();
  final ReferenceApi _referenceApi = ReferenceApi();
  final ScrollController _scrollController = ScrollController();
  final PageController _heroImageController = PageController();

  PlaceVm? _place;
  List<PlaceReviewVm> _reviews = [];
  PlaceReviewVm? _currentUserReview;
  int _reviewTotal = 0;
  bool _loading = true;
  bool _submittingReview = false;
  bool _checkingCurrentUserReview = false;
  bool _isOpeningExcursions = false;
  bool _isBuildingRoute = false;
  String? _error;
  String? _locationLabel;
  int _currentImageIndex = 0;
  bool _didResolveInitialPlace = false;
  bool _didScheduleInitialLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didResolveInitialPlace) {
      final locale = Localizations.localeOf(context);
      if (canDisplayInitialPlaceForLocale(widget.initialPlace, locale)) {
        _place = widget.initialPlace;
      }
      _didResolveInitialPlace = true;
    }
    if (!_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  @override
  void dispose() {
    _heroImageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    setState(() {
      _loading = _place == null;
      _checkingCurrentUserReview = currentUserId.isNotEmpty;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final excursionProvider = context.read<ExcursionProvider>();
      final results = await Future.wait([
        _api.getPlace(widget.placeId, locale: locale),
        _api.getReviews(widget.placeId, limit: 5),
        _loadCurrentUserReview(currentUserId),
        excursionProvider.loadExcursionReviews(landmarkId: widget.placeId),
      ]);

      if (!mounted) return;
      final place = results[0] as PlaceVm;
      final reviewResult =
          results[1] as ({List<PlaceReviewVm> items, int total});
      final currentUserReview =
          (results[2] as PlaceReviewVm?) ??
          _findReviewByAuthor(reviewResult.items, currentUserId);
      final locationLabel = await _resolveLocationLabel(place, locale);
      final mediaCount = place.media.length;
      final imageIndex = mediaCount == 0
          ? 0
          : _currentImageIndex.clamp(0, mediaCount - 1).toInt();

      setState(() {
        _place = place;
        _reviews = reviewResult.items;
        _currentUserReview = currentUserReview;
        _reviewTotal = reviewResult.total;
        _locationLabel = locationLabel;
        _currentImageIndex = imageIndex;
        _loading = false;
        _checkingCurrentUserReview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'load_failed';
        _loading = false;
        _checkingCurrentUserReview = false;
      });
    }
  }

  Future<PlaceReviewVm?> _loadCurrentUserReview(String currentUserId) async {
    if (currentUserId.isEmpty) {
      return null;
    }
    try {
      return await _api.getMyReview(widget.placeId);
    } catch (_) {
      return null;
    }
  }

  PlaceReviewVm? _findReviewByAuthor(
    List<PlaceReviewVm> reviews,
    String currentUserId,
  ) {
    if (currentUserId.isEmpty) {
      return null;
    }
    for (final review in reviews) {
      if (review.author.userId.trim() == currentUserId) {
        return review;
      }
    }
    return null;
  }

  bool get _hasCurrentUserReview => _currentUserReview != null;

  bool get _shouldShowReviewAction =>
      !_checkingCurrentUserReview && !_hasCurrentUserReview;

  Future<String> _resolveLocationLabel(PlaceVm place, String locale) async {
    final fallback = _fallbackLocationLabel(place);
    final countryCode = place.countryCode.trim().toUpperCase();
    final cityId = place.cityId.trim();
    if (countryCode.isEmpty && cityId.isEmpty) {
      return fallback;
    }

    try {
      final cityFuture = countryCode.isEmpty
          ? Future<List<ReferenceCity>>.value(const [])
          : _referenceApi.citiesByCountry(countryCode, lang: locale);
      final countryFuture = countryCode.isEmpty
          ? Future<ReferenceCountry?>.value(null)
          : _referenceApi.getCountry(countryCode, lang: locale);

      final results = await Future.wait<dynamic>([cityFuture, countryFuture]);
      final cities = results[0] as List<ReferenceCity>;
      final country = results[1] as ReferenceCountry?;

      String? cityName;
      for (final city in cities) {
        if (city.id == cityId) {
          cityName = city.name;
          break;
        }
      }

      final parts = <String>[
        if ((cityName ?? cityId).trim().isNotEmpty) (cityName ?? cityId).trim(),
        if ((country?.name ?? countryCode).trim().isNotEmpty)
          (country?.name ?? countryCode).trim(),
      ];
      return parts.isEmpty ? fallback : parts.join(', ');
    } catch (_) {
      return fallback;
    }
  }

  String _fallbackLocationLabel(PlaceVm place) {
    final parts = <String>[
      if (place.cityId.trim().isNotEmpty) place.cityId.trim(),
      if (place.countryCode.trim().isNotEmpty)
        place.countryCode.trim().toUpperCase(),
    ];
    return parts.join(', ');
  }

  Future<void> _openExcursionsForPlace() async {
    final place = _place;
    if (place == null || _isOpeningExcursions) return;

    final placeId = place.id.trim().isNotEmpty
        ? place.id.trim()
        : widget.placeId.trim();
    if (placeId.isEmpty) {
      context.push('/excursions');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isOpeningExcursions = true);

    ExcursionVm? excursion;
    var didFail = false;
    try {
      excursion = await context
          .read<ExcursionProvider>()
          .findFirstExcursionForPlace(placeId);
    } catch (_) {
      didFail = true;
    }

    if (!mounted) return;
    setState(() => _isOpeningExcursions = false);

    if (didFail) {
      await _showErrorMessage(l10n.excursionsLoadFailed);
      if (!mounted) return;
      context.push('/excursions');
      return;
    }

    final excursionId = excursion?.id.trim() ?? '';
    if (excursionId.isNotEmpty) {
      context.push(
        '/excursions/${Uri.encodeComponent(excursionId)}',
        extra: excursion,
      );
      return;
    }

    context.push(
      '/excursions',
      extra: ExcursionsRouteArgs.noPlaceExcursions(
        placeId: placeId,
        placeTitle: place.title.trim(),
      ),
    );
  }

  Future<void> _openReviewSheet() async {
    if (_place == null) return;
    final l10n = AppLocalizations.of(context)!;

    await showAppModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.placeColors.transparent,
      builder: (context) =>
          _CreateReviewSheet(l10n: l10n, onSubmit: _submitReview),
    );
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
      await _showErrorMessage(
        provider.actionErrorMessage ?? l10n.myExcursionsReviewFailed,
      );
      return;
    }
    await _refreshExcursionReviewSources(savedReview);
    if (!mounted) return;
    _showSnack(l10n.excursionReviewUpdated);
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
      await _showErrorMessage(
        provider.actionErrorMessage ?? l10n.myExcursionsReviewDeleteFailed,
      );
      return;
    }
    await _refreshExcursionReviewSources(review);
    if (!mounted) return;
    _showSnack(l10n.excursionReviewDeleted);
  }

  Future<void> _refreshExcursionReviewSources(ExcursionReviewVm review) async {
    final provider = context.read<ExcursionProvider>();
    final productId = review.productId.trim();
    if (productId.isNotEmpty) {
      await provider.loadExcursionReviews(productId: productId);
    }
    await provider.loadExcursionReviews(landmarkId: widget.placeId);
  }

  Future<void> _openImageGallery(
    List<PlaceMediaVm> media,
    int initialIndex,
  ) async {
    if (media.isEmpty) return;
    final selectedIndex = await showAppModalDialog<int>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: context.placeColors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _PlaceImageGallery(
          media: media,
          initialIndex: initialIndex.clamp(0, media.length - 1).toInt(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (!mounted || selectedIndex == null || selectedIndex >= media.length) {
      return;
    }

    setState(() => _currentImageIndex = selectedIndex);
    if (_heroImageController.hasClients) {
      await _heroImageController.animateToPage(
        selectedIndex,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<bool> _submitReview(
    double rating,
    String comment,
    List<_ReviewDraftMedia> media,
  ) async {
    if (_submittingReview) {
      return false;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _submittingReview = true);

    try {
      final uploadedMedia = <PlaceReviewMediaInput>[];
      for (var i = 0; i < media.length; i++) {
        final item = media[i];
        final upload = await _fileApi.createPlaceReviewMediaUpload(
          originalName: item.fileName,
          contentType: item.contentType,
          sizeBytes: item.bytes.lengthInBytes,
        );
        await _fileApi.uploadBinary(
          upload: upload,
          bytes: item.bytes,
          contentType: item.contentType,
        );
        await _fileApi.completeUpload(upload.fileId);
        uploadedMedia.add(
          PlaceReviewMediaInput(
            fileId: upload.fileId,
            mediaType: item.mediaType,
            position: i,
          ),
        );
      }

      final createdReview = await _api.createReview(
        widget.placeId,
        rating: rating,
        comment: comment,
        media: uploadedMedia,
      );
      if (!mounted) return true;
      await _loadData();
      if (!mounted) return true;
      if (_currentUserReview == null) {
        setState(() => _currentUserReview = createdReview);
      }
      _showSnack(l10n.placeReviewSubmitSuccess);
      return true;
    } on DioException catch (e) {
      if (mounted) {
        await _showErrorMessage(DioErrorMapper.toMessage(e));
      }
      return false;
    } catch (_) {
      if (mounted) {
        await _showErrorMessage(l10n.placeReviewSubmitFailed);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _submittingReview = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _showErrorMessage(String message) {
    final l10n = AppLocalizations.of(context)!;
    return showErrorDialog(context, title: l10n.error, message: message);
  }

  String _resolvedLocationLabel(PlaceVm place) {
    final resolved = (_locationLabel?.trim().isNotEmpty ?? false)
        ? _locationLabel!.trim()
        : _fallbackLocationLabel(place);
    return resolved.trim().isNotEmpty
        ? resolved.trim()
        : place.countryCode.trim().toUpperCase();
  }

  void _openMap() {
    unawaited(_openRouteToPlace());
  }

  Future<void> _openRouteToPlace() async {
    final place = _place;
    if (place != null && place.hasLocation) {
      final destination = _placeMapTarget(place);
      if (_isBuildingRoute ||
          context.read<AuthProvider>().state != AuthState.authenticated) {
        context.push('/map', extra: destination);
        return;
      }

      final routingProvider = context.read<RoutingProvider>();
      final l10n = AppLocalizations.of(context)!;

      setState(() => _isBuildingRoute = true);
      try {
        final coordinates = await _deviceContextService.detectCoordinates(
          requestPermission: true,
        );
        if (!mounted) return;

        if (coordinates == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
          context.push('/map', extra: destination);
          return;
        }

        final origin = RoutePointVm(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          name: l10n.homeNavMap,
        );

        final route = await routingProvider.buildRoute(
          RouteRequestVm(
            profile: RouteProfile.touristWalk,
            points: [
              origin,
              RoutePointVm(
                latitude: place.latitude!,
                longitude: place.longitude!,
                name: place.title,
              ),
            ],
          ),
        );
        if (!mounted) return;

        if (route == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                routingProvider.errorMessage ?? l10n.mapUsingFallbackLocation,
              ),
            ),
          );
          context.push('/map', extra: destination);
          return;
        }

        final routePreview = MapRoutePreview(
          route: route,
          origin: origin,
          destination: destination,
        );
        context.push('/map', extra: routePreview);
      } finally {
        if (mounted) {
          setState(() => _isBuildingRoute = false);
        }
      }
      return;
    }

    context.push('/map');
  }

  MapTarget _placeMapTarget(PlaceVm place) {
    final subtitle = _resolvedLocationLabel(place);
    return MapTarget(
      title: place.title,
      subtitle: subtitle,
      latitude: place.latitude!,
      longitude: place.longitude!,
      sourceUrl: AppMapLinks.buildUrl(
        latitude: place.latitude!,
        longitude: place.longitude!,
        title: place.title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlaceTextScale(
      child: Builder(
        builder: (context) {
          final adaptive = PlaceAdaptive.of(context);
          final l10n = AppLocalizations.of(context)!;
          final waitingForLocalizedDetails =
              _loading && (_place == null || _locationLabel == null);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: context.placeColors.background,
              body: SafeArea(
                bottom: false,
                child: waitingForLocalizedDetails
                    ? Center(
                        child: CircularProgressIndicator(
                          color: context.placeColors.primary,
                        ),
                      )
                    : _error != null && _place == null
                    ? _buildError(l10n, adaptive)
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                _buildTopBar(adaptive, l10n),
                                Expanded(
                                  child: RefreshIndicator(
                                    color: context.placeColors.primary,
                                    backgroundColor:
                                        context.placeColors.background,
                                    onRefresh: _loadData,
                                    child: CustomScrollView(
                                      controller: _scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: _buildHero(adaptive, l10n),
                                        ),
                                        SliverToBoxAdapter(
                                          child: _buildContent(adaptive, l10n),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildBottomCta(adaptive, l10n),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n, PlaceAdaptive a) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.placeDetailsLoadFailed,
            style: AppTextStyle(color: context.placeColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: a.scale(12)),
          TextButton(
            onPressed: _loadData,
            child: Text(
              l10n.retryButton,
              style: AppTextStyle(color: context.placeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  // ---------------------------------------------------------------------------
  // Top bar (non-floating, sits in scroll content header)
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(PlaceAdaptive a, AppLocalizations l10n) {
    return Container(
      height: a.scale(74, minFactor: 0.9),
      padding: AppEdgeInsets.fromLTRB(
        a.scale(28, minFactor: 0.78),
        a.scale(14),
        a.scale(28, minFactor: 0.78),
        a.scale(14),
      ),
      decoration: AppBoxDecoration(
        color: context.placeColors.background,
        border: Border(
          bottom: BorderSide(color: context.placeColors.surfaceHigh),
        ),
      ),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: context.placeColors.textPrimary,
            background: context.placeColors.transparent,
            size: a.scale(42),
            iconSize: a.scale(20),
            tooltip: l10n.placeBackTooltip,
            onTap: _onBack,
          ),
          Expanded(
            child: Padding(
              padding: AppEdgeInsets.symmetric(horizontal: a.scale(8)),
              child: Text(
                l10n.placeDetailsTitle,
                textAlign: TextAlign.center,
                style: AppTextStyle(
                  color: context.placeColors.textPrimary,
                  fontSize: a.scale(19, minFactor: 0.9),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _circleIconButton(
            icon: Icons.notifications_outlined,
            color: context.placeColors.primary,
            background: context.placeColors.primary.withValues(alpha: 0.12),
            size: a.scale(42),
            iconSize: a.scale(20),
            tooltip: l10n.placeNotificationsTooltip,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required Color color,
    required Color background,
    required double size,
    required double iconSize,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.placeColors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: AppBoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero image with page indicator
  // ---------------------------------------------------------------------------

  Widget _buildHero(PlaceAdaptive a, AppLocalizations l10n) {
    final place = _place!;
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.top - mq.padding.bottom;
    final heroHeight = (available * 0.42).clamp(240.0, 360.0);
    final media = place.media.isNotEmpty
        ? (List<PlaceMediaVm>.from(place.media)
            ..sort((x, y) => x.position.compareTo(y.position)))
        : <PlaceMediaVm>[];

    final padX = a.scale(28);
    final locationLabel = _resolvedLocationLabel(place);
    final heroOverlayGradient = _placeHeroOverlayGradient(context);
    final heroTitleColor = _placeHeroTitleColor(
      context,
      hasMedia: media.isNotEmpty,
    );

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.isNotEmpty)
            PageView.builder(
              controller: _heroImageController,
              itemCount: media.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (_, i) => _buildHeroMediaPage(
                media: media,
                index: i,
                logicalWidth: mq.size.width,
              ),
            )
          else
            _heroPlaceholder(),
          if (heroOverlayGradient != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: AppBoxDecoration(gradient: heroOverlayGradient),
                ),
              ),
            ),
          Positioned(
            left: padX,
            right: padX,
            bottom: a.scale(38, minFactor: 0.68),
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (media.length > 1) ...[
                    Center(child: _buildImageIndicator(media.length, a)),
                    SizedBox(height: a.scale(12)),
                  ],
                  if (place.rating >= 4.0) ...[
                    Container(
                      height: a.scale(27, minFactor: 0.9),
                      padding: AppEdgeInsets.symmetric(horizontal: a.scale(13)),
                      alignment: Alignment.center,
                      decoration: AppBoxDecoration(
                        color: context.placeColors.primary,
                        borderRadius: AppBorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.placeMustVisitBadge.toUpperCase(),
                        style: AppTextStyle(
                          color: context.placeColors.white,
                          fontSize: a.scale(11),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: a.scale(10)),
                  ],
                  Text(
                    place.title,
                    style: AppTextStyle(
                      color: heroTitleColor,
                      fontSize: a.scale(38, minFactor: 0.86),
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -3.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: a.scale(8)),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: context.placeColors.primary,
                        size: a.scale(14),
                      ),
                      SizedBox(width: a.scale(6)),
                      Expanded(
                        child: Text(
                          locationLabel.toUpperCase(),
                          style: AppTextStyle(
                            color: context.placeColors.primary,
                            fontSize: a.scale(14, minFactor: 0.82),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildHeroMediaPage({
    required List<PlaceMediaVm> media,
    required int index,
    required double logicalWidth,
  }) {
    final imageTargetWidth = placeImageTargetWidth(
      context,
      logicalWidth,
      minWidth: 900,
      maxWidth: 1600,
    );
    final url = resolvePlaceMediaUrl(
      media[index],
      targetWidth: imageTargetWidth,
    );
    if (url == null) {
      return _heroPlaceholder();
    }

    return GestureDetector(
      onTap: () => _openImageGallery(media, index),
      behavior: HitTestBehavior.opaque,
      child: Image.network(
        url,
        headers: placeImageRequestHeaders(url),
        fit: BoxFit.cover,
        cacheWidth: imageTargetWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return _heroPlaceholder();
        },
        errorBuilder: (_, _, _) => _heroPlaceholder(),
      ),
    );
  }

  Widget _buildImageIndicator(int count, PlaceAdaptive a) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: AppEdgeInsets.symmetric(horizontal: a.scale(3)),
          width: _currentImageIndex == i ? a.scale(18) : a.scale(6),
          height: a.scale(6),
          decoration: AppBoxDecoration(
            color: _currentImageIndex == i
                ? context.placeColors.primary
                : context.placeColors.white.withValues(alpha: 0.35),
            borderRadius: AppBorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: context.placeColors.white.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: context.placeColors.textMuted,
          size: 64,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content below hero
  // ---------------------------------------------------------------------------

  Widget _buildContent(PlaceAdaptive a, AppLocalizations l10n) {
    final place = _place!;
    final padX = a.scale(28);
    final mq = MediaQuery.of(context);
    final hasStructuredVisitPlanning = _hasStructuredVisitPlanning(place);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        border: Border(
          top: BorderSide(color: context.placeColors.detailCardBorder),
        ),
      ),
      child: Padding(
        padding: AppEdgeInsets.fromLTRB(
          padX,
          a.scale(24, minFactor: 0.72),
          padX,
          mq.padding.bottom + a.scale(110),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStats(place, a, l10n),
            SizedBox(height: a.scale(18, minFactor: 0.72)),
            _buildLocationBlock(place, a, l10n),
            SizedBox(height: a.scale(46, minFactor: 0.72)),
            _buildExperience(place, a, l10n),
            if (hasStructuredVisitPlanning) ...[
              SizedBox(height: a.scale(46, minFactor: 0.72)),
              _buildVisitOverview(place, a, l10n),
              if (_hasVisitCostInfo(place)) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildVisitCostBlock(place, a, l10n),
              ],
              if (_hasVisitSeasonInfo(place)) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildVisitSeasonBlock(place, a, l10n),
              ],
              if (_hasVisitAccessInfo(place)) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildVisitAccessBlock(place, a, l10n),
              ],
              if (_hasVisitTimeInfo(place)) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildVisitTimeBlock(place, a, l10n),
              ],
              if (place.visitInfo.recommendedItems.isNotEmpty) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildRecommendedItemsBlock(place, a, l10n),
              ],
              if (place.visitInfo.practicalNotes.isNotEmpty) ...[
                SizedBox(height: a.scale(16, minFactor: 0.72)),
                _buildPracticalNotesBlock(place, a, l10n),
              ],
            ] else if (place.feeDetails.isNotEmpty) ...[
              SizedBox(height: a.scale(46, minFactor: 0.72)),
              _buildFeeDetails(place, a, l10n),
            ],
            if (!hasStructuredVisitPlanning) ...[
              SizedBox(height: a.scale(56)),
              _buildVisitPlan(place, a, l10n),
            ],
            SizedBox(height: a.scale(24, minFactor: 0.72)),
            _buildReviews(a, l10n),
            SizedBox(height: a.scale(28, minFactor: 0.72)),
            ContextualHelpSection(
              surface: HelpCenterSurface.placeDetails,
              tags: const ['places', 'rules'],
              supportContext: {
                'screen': 'place_details',
                'locale': Localizations.localeOf(context).languageCode,
                'place_id': widget.placeId,
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBlock(
    PlaceVm v,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final locationLabel = _resolvedLocationLabel(v);
    final radius = AppBorderRadius.circular(a.radius(16));

    return Semantics(
      button: true,
      label: l10n.placeMapLink,
      child: Material(
        color: context.placeColors.transparent,
        child: InkWell(
          onTap: _isBuildingRoute ? null : _openMap,
          borderRadius: radius,
          child: Ink(
            padding: AppEdgeInsets.symmetric(
              horizontal: a.scale(14),
              vertical: a.scale(13, minFactor: 0.84),
            ),
            decoration: AppBoxDecoration(
              color: context.placeColors.detailCardSurface,
              borderRadius: radius,
              border: Border.all(color: context.placeColors.detailCardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: a.scale(42, minFactor: 0.84),
                  height: a.scale(42, minFactor: 0.84),
                  decoration: AppBoxDecoration(
                    color: context.placeColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: context.placeColors.primary,
                    size: a.scale(21, minFactor: 0.86),
                  ),
                ),
                SizedBox(width: a.scale(12, minFactor: 0.78)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locationLabel,
                        style: AppTextStyle(
                          color: context.placeColors.textPrimary,
                          fontSize: a.scale(16, minFactor: 0.86),
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: a.scale(3, minFactor: 0.7)),
                      Text(
                        l10n.placeMapLink,
                        style: AppTextStyle(
                          color: context.placeColors.primary,
                          fontSize: a.scale(12, minFactor: 0.88),
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: a.scale(10, minFactor: 0.72)),
                Container(
                  width: a.scale(40, minFactor: 0.86),
                  height: a.scale(40, minFactor: 0.86),
                  decoration: AppBoxDecoration(
                    color: context.placeColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isBuildingRoute
                      ? Padding(
                          padding: AppEdgeInsets.all(a.scale(10)),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.placeColors.white,
                          ),
                        )
                      : Icon(
                          Icons.map_rounded,
                          color: context.placeColors.white,
                          size: a.scale(20, minFactor: 0.86),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats card (3 cells, orange icons, dividers)
  // ---------------------------------------------------------------------------

  Widget _buildStats(PlaceVm v, PlaceAdaptive a, AppLocalizations l10n) {
    final duration = formatPlaceDurationLabel(l10n, v);
    return Container(
      decoration: AppBoxDecoration(
        color: context.placeColors.detailCardSurface,
        borderRadius: AppBorderRadius.circular(a.radius(18)),
        border: Border.all(color: context.placeColors.detailCardBorder),
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.circular(a.radius(15)),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.star_rounded,
                  value: v.rating.toStringAsFixed(1),
                  label: l10n.placeStatRating,
                  a: a,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _statCell(
                  icon: Icons.schedule_rounded,
                  value: duration.isNotEmpty ? duration : '—',
                  label: l10n.placeStatDuration,
                  a: a,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _statCell(
                  icon: Icons.confirmation_number_outlined,
                  value: _formatDetailsPriceLabel(context, l10n, v),
                  label: l10n.placeStatPrice,
                  a: a,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, color: context.placeColors.detailCardBorder);
  }

  String _formatDetailsPriceLabel(
    BuildContext context,
    AppLocalizations l10n,
    PlaceVm place,
  ) {
    if (place.priceAmount == null) {
      return l10n.placePriceVariesShort;
    }
    return formatPlacePriceLabel(
      context,
      l10n,
      place,
      preferredCurrency: context.watch<SessionProvider>().profile?.currency,
      currencyRates: context.watch<CurrencyRateProvider>(),
    );
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String label,
    required PlaceAdaptive a,
  }) {
    return Container(
      color: context.placeColors.surfaceHigh,
      constraints: BoxConstraints(minHeight: a.scale(94, minFactor: 0.86)),
      padding: AppEdgeInsets.symmetric(
        horizontal: a.scale(8),
        vertical: a.scale(19),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.placeColors.primary, size: a.scale(22)),
          SizedBox(height: a.scale(7)),
          Text(
            value,
            style: AppTextStyle(
              color: context.placeColors.textPrimary,
              fontSize: a.scale(19, minFactor: 0.86),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: a.scale(3)),
          Text(
            label.toUpperCase(),
            style: AppTextStyle(
              color: context.placeColors.primary,
              fontSize: a.scale(10),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // The Experience (description)
  // ---------------------------------------------------------------------------

  Widget _buildExperience(PlaceVm v, PlaceAdaptive a, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(l10n.placeExperienceSection, a),
        SizedBox(height: a.scale(16)),
        _buildReadableDescriptionCard(v.description, a),
      ],
    );
  }

  Widget _buildReadableDescriptionCard(String description, PlaceAdaptive a) {
    final radius = AppBorderRadius.circular(a.radius(18));

    return Container(
      width: double.infinity,
      padding: AppEdgeInsets.all(a.scale(16, minFactor: 0.82)),
      decoration: AppBoxDecoration(
        color: context.placeColors.surfaceHigh,
        borderRadius: radius,
        border: Border.all(color: context.placeColors.border),
      ),
      child: Text(
        description,
        style: AppTextStyle(
          color: context.placeColors.textPrimary,
          fontSize: a.scale(16, minFactor: 0.88),
          fontWeight: FontWeight.w600,
          height: 1.62,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildFeeDetails(PlaceVm v, PlaceAdaptive a, AppLocalizations l10n) {
    final details = v.feeDetails;
    if (details.isEmpty) return const SizedBox.shrink();
    final radius = AppBorderRadius.circular(a.radius(16));

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: context.placeColors.transparent,
        splashColor: context.placeColors.primary.withValues(alpha: 0.08),
        highlightColor: context.placeColors.primary.withValues(alpha: 0.05),
      ),
      child: Container(
        decoration: AppBoxDecoration(
          color: context.placeColors.surfaceHigh,
          borderRadius: radius,
          border: Border.all(
            color: context.placeColors.white.withValues(alpha: 0.07),
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExpansionTile(
            key: PageStorageKey<String>('place-fee-details-${v.id}'),
            initiallyExpanded: false,
            maintainState: true,
            tilePadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              a.scale(5, minFactor: 0.7),
              a.scale(10),
              a.scale(5, minFactor: 0.7),
            ),
            childrenPadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              0,
              a.scale(14),
              a.scale(14, minFactor: 0.72),
            ),
            iconColor: context.placeColors.primary,
            collapsedIconColor: context.placeColors.primary,
            textColor: context.placeColors.textPrimary,
            collapsedTextColor: context.placeColors.textPrimary,
            backgroundColor: context.placeColors.surfaceHigh,
            collapsedBackgroundColor: context.placeColors.surfaceHigh,
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            leading: Container(
              width: a.scale(34, minFactor: 0.78),
              height: a.scale(34, minFactor: 0.78),
              decoration: AppBoxDecoration(
                color: context.placeColors.surfaceWarm,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: context.placeColors.primary,
                size: a.scale(17, minFactor: 0.8),
              ),
            ),
            title: Text(
              l10n.placeFeeDetailsTitle,
              style: AppTextStyle(
                color: context.placeColors.textPrimary,
                fontSize: a.scale(15, minFactor: 0.84),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: AppEdgeInsets.only(top: a.scale(2)),
              child: Text(
                l10n.placeFeeDetailsNote,
                style: AppTextStyle(
                  color: context.placeColors.primary,
                  fontSize: a.scale(11, minFactor: 0.82),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            children: [
              for (var i = 0; i < details.length; i++) ...[
                _FeeDetailRow(place: v, fee: details[i], adaptive: a),
                if (i < details.length - 1)
                  Divider(
                    height: a.scale(1),
                    thickness: 1,
                    color: context.placeColors.white.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasStructuredVisitPlanning(PlaceVm place) {
    return _hasVisitCostInfo(place) ||
        _hasVisitSeasonInfo(place) ||
        _hasVisitAccessInfo(place) ||
        _hasVisitTimeInfo(place) ||
        place.visitInfo.recommendedItems.isNotEmpty ||
        place.visitInfo.practicalNotes.isNotEmpty;
  }

  bool _hasVisitCostInfo(PlaceVm place) {
    return place.feeDetails.isNotEmpty ||
        (place.visitInfo.priceNote ?? '').trim().isNotEmpty;
  }

  bool _hasVisitSeasonInfo(PlaceVm place) {
    return (place.visitInfo.bestTime ?? '').trim().isNotEmpty ||
        (place.visitInfo.season?.note ?? '').trim().isNotEmpty ||
        (place.visitInfo.openingHours ?? '').trim().isNotEmpty;
  }

  bool _hasVisitAccessInfo(PlaceVm place) {
    return place.visitInfo.accessOptions.isNotEmpty ||
        (place.visitInfo.roadCondition ?? '').trim().isNotEmpty;
  }

  bool _hasVisitTimeInfo(PlaceVm place) {
    return place.visitInfo.timeOnSite != null ||
        place.visitInfo.carTravelTime != null;
  }

  Widget _buildVisitOverview(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final rows = <_VisitPlanItem>[
      _VisitPlanItem(
        icon: Icons.confirmation_number_outlined,
        label: l10n.placeStatPrice,
        value: _formatDetailsPriceLabel(context, l10n, place),
      ),
      if (place.visitInfo.timeOnSite != null)
        _VisitPlanItem(
          icon: Icons.schedule_rounded,
          label: l10n.placeVisitDurationLabel,
          value: _durationWithNote(l10n, place.visitInfo.timeOnSite!),
        )
      else
        _VisitPlanItem(
          icon: Icons.schedule_rounded,
          label: l10n.placeVisitDurationLabel,
          value: formatPlaceDurationLabel(l10n, place).trim().isEmpty
              ? l10n.placeVisitDurationFlexible
              : formatPlaceDurationLabel(l10n, place),
        ),
      if (place.visitInfo.carTravelTime != null)
        _VisitPlanItem(
          icon: Icons.directions_car_rounded,
          label: l10n.placeVisitCarTimeLabel,
          value: _durationWithNote(l10n, place.visitInfo.carTravelTime!),
        ),
      _VisitPlanItem(
        icon: Icons.wb_twilight_rounded,
        label: l10n.placeVisitBestTimeLabel,
        value: _bestSeasonLabel(place, l10n),
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    return _buildVisitInfoBlock(
      title: l10n.placeVisitOverviewTitle,
      icon: Icons.dashboard_customize_rounded,
      a: a,
      storageKey: 'place-visit-overview-${place.id}',
      initiallyExpanded: true,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _VisitPlanRow(item: rows[i], adaptive: a),
          if (i < rows.length - 1) _visitInfoDivider(a),
        ],
      ],
    );
  }

  Widget _buildVisitCostBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < place.feeDetails.length; i++) {
      rows.add(
        _FeeDetailRow(place: place, fee: place.feeDetails[i], adaptive: a),
      );
      if (i < place.feeDetails.length - 1) {
        rows.add(_visitInfoDivider(a));
      }
    }
    final priceNote = (place.visitInfo.priceNote ?? '').trim();
    if (priceNote.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(_visitInfoDivider(a));
      rows.add(
        _VisitPlanRow(
          item: _VisitPlanItem(
            icon: Icons.info_outline_rounded,
            label: l10n.placeVisitPriceNoteLabel,
            value: priceNote,
          ),
          adaptive: a,
        ),
      );
    }

    return _buildVisitInfoBlock(
      title: l10n.placeVisitCostTitle,
      icon: Icons.receipt_long_rounded,
      a: a,
      storageKey: 'place-visit-cost-${place.id}',
      children: rows,
    );
  }

  Widget _buildVisitSeasonBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final rows = <_VisitPlanItem>[
      if ((place.visitInfo.bestTime ?? '').trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.wb_twilight_rounded,
          label: l10n.placeVisitBestTimeLabel,
          value: _bestSeasonLabel(place, l10n),
        ),
      if ((place.visitInfo.bestTime ?? '').trim().isEmpty &&
          (place.visitInfo.season?.note ?? '').trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.wb_twilight_rounded,
          label: l10n.placeVisitBestTimeLabel,
          value: _bestSeasonLabel(place, l10n),
        ),
      if ((place.visitInfo.openingHours ?? '').trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.access_time_rounded,
          label: l10n.placeVisitOpeningHoursLabel,
          value: place.visitInfo.openingHours!.trim(),
        ),
    ];

    return _buildVisitInfoBlock(
      title: l10n.placeVisitSeasonTitle,
      icon: Icons.event_available_rounded,
      a: a,
      storageKey: 'place-visit-season-${place.id}',
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _VisitPlanRow(item: rows[i], adaptive: a),
          if (i < rows.length - 1) _visitInfoDivider(a),
        ],
      ],
    );
  }

  Widget _buildVisitAccessBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final children = <Widget>[];
    for (var i = 0; i < place.visitInfo.accessOptions.length; i++) {
      final option = place.visitInfo.accessOptions[i];
      children.add(_AccessOptionCard(option: option, l10n: l10n, adaptive: a));
      if (i < place.visitInfo.accessOptions.length - 1) {
        children.add(SizedBox(height: a.scale(10, minFactor: 0.72)));
      }
    }
    final roadCondition = _roadConditionLabel(
      place.visitInfo.roadCondition,
      l10n,
    );
    if (children.isEmpty && roadCondition.trim().isNotEmpty) {
      children.add(
        _VisitPlanRow(
          item: _VisitPlanItem(
            icon: Icons.route_rounded,
            label: l10n.placeVisitRoadConditionLabel,
            value: roadCondition,
          ),
          adaptive: a,
        ),
      );
    }

    return _buildVisitInfoBlock(
      title: l10n.placeVisitAccessTitle,
      icon: Icons.route_rounded,
      a: a,
      storageKey: 'place-visit-access-${place.id}',
      children: children,
    );
  }

  Widget _buildVisitTimeBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    final rows = <_VisitPlanItem>[
      if (place.visitInfo.timeOnSite != null)
        _VisitPlanItem(
          icon: Icons.schedule_rounded,
          label: l10n.placeVisitDurationLabel,
          value: _durationWithNote(l10n, place.visitInfo.timeOnSite!),
        ),
      if (place.visitInfo.carTravelTime != null)
        _VisitPlanItem(
          icon: Icons.directions_car_rounded,
          label: l10n.placeVisitCarTimeLabel,
          value: _durationWithNote(l10n, place.visitInfo.carTravelTime!),
        ),
    ];

    return _buildVisitInfoBlock(
      title: l10n.placeVisitTimeTitle,
      icon: Icons.more_time_rounded,
      a: a,
      storageKey: 'place-visit-time-${place.id}',
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _VisitPlanRow(item: rows[i], adaptive: a),
          if (i < rows.length - 1) _visitInfoDivider(a),
        ],
      ],
    );
  }

  Widget _buildRecommendedItemsBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    if (!place.visitInfo.recommendedItems.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return _buildVisitInfoBlock(
      title: l10n.placeVisitRecommendedItemsTitle,
      icon: Icons.backpack_rounded,
      a: a,
      storageKey: 'place-visit-items-${place.id}',
      children: [
        Wrap(
          spacing: a.scale(8, minFactor: 0.72),
          runSpacing: a.scale(8, minFactor: 0.72),
          children: [
            for (final item in place.visitInfo.recommendedItems)
              _RecommendedItemChip(item: item, l10n: l10n, adaptive: a),
          ],
        ),
      ],
    );
  }

  Widget _buildPracticalNotesBlock(
    PlaceVm place,
    PlaceAdaptive a,
    AppLocalizations l10n,
  ) {
    return _buildVisitInfoBlock(
      title: l10n.placeVisitPracticalNotesTitle,
      icon: Icons.tips_and_updates_rounded,
      a: a,
      storageKey: 'place-visit-practical-${place.id}',
      children: [
        for (var i = 0; i < place.visitInfo.practicalNotes.length; i++) ...[
          _PracticalNoteRow(
            note: place.visitInfo.practicalNotes[i],
            adaptive: a,
            l10n: l10n,
          ),
          if (i < place.visitInfo.practicalNotes.length - 1)
            _visitInfoDivider(a),
        ],
      ],
    );
  }

  Widget _buildVisitInfoBlock({
    required String title,
    required IconData icon,
    required PlaceAdaptive a,
    required String storageKey,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    final radius = AppBorderRadius.circular(a.radius(16));

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: context.placeColors.transparent,
        splashColor: context.placeColors.primary.withValues(alpha: 0.08),
        highlightColor: context.placeColors.primary.withValues(alpha: 0.05),
      ),
      child: Container(
        width: double.infinity,
        decoration: AppBoxDecoration(
          color: context.placeColors.surfaceHigh,
          borderRadius: radius,
          border: Border.all(
            color: context.placeColors.primary.withValues(alpha: 0.16),
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExpansionTile(
            key: PageStorageKey<String>(storageKey),
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              a.scale(5, minFactor: 0.7),
              a.scale(10),
              a.scale(5, minFactor: 0.7),
            ),
            childrenPadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              0,
              a.scale(14),
              a.scale(14, minFactor: 0.72),
            ),
            iconColor: context.placeColors.primary,
            collapsedIconColor: context.placeColors.primary,
            textColor: context.placeColors.textPrimary,
            collapsedTextColor: context.placeColors.textPrimary,
            backgroundColor: context.placeColors.surfaceHigh,
            collapsedBackgroundColor: context.placeColors.surfaceHigh,
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            leading: Container(
              width: a.scale(34, minFactor: 0.78),
              height: a.scale(34, minFactor: 0.78),
              decoration: AppBoxDecoration(
                color: context.placeColors.surfaceWarm,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: context.placeColors.primary,
                size: a.scale(17, minFactor: 0.8),
              ),
            ),
            title: Text(
              title,
              style: AppTextStyle(
                color: context.placeColors.textPrimary,
                fontSize: a.scale(15, minFactor: 0.84),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _visitInfoDivider(PlaceAdaptive a) {
    return Divider(
      height: a.scale(1),
      thickness: 1,
      color: context.placeColors.white.withValues(alpha: 0.06),
    );
  }

  Widget _eyebrow(String text, PlaceAdaptive a) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyle(
        color: context.placeColors.primary,
        fontSize: a.scale(11),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Visit plan (practical, localized, data-driven)
  // ---------------------------------------------------------------------------

  Widget _buildVisitPlan(PlaceVm v, PlaceAdaptive a, AppLocalizations l10n) {
    final items = _visitPlanItems(context, v, l10n);
    final tip = _localizedInflapTip(context, v, l10n);
    final summary = _visitPlanSummary(items);
    final radius = AppBorderRadius.circular(a.radius(16));

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: context.placeColors.transparent,
        splashColor: context.placeColors.primary.withValues(alpha: 0.08),
        highlightColor: context.placeColors.primary.withValues(alpha: 0.05),
      ),
      child: Container(
        decoration: AppBoxDecoration(
          color: context.placeColors.surfaceHigh,
          borderRadius: radius,
          border: Border.all(
            color: context.placeColors.white.withValues(alpha: 0.07),
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExpansionTile(
            key: PageStorageKey<String>('place-visit-plan-${v.id}'),
            initiallyExpanded: false,
            maintainState: true,
            tilePadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              a.scale(5, minFactor: 0.7),
              a.scale(10),
              a.scale(5, minFactor: 0.7),
            ),
            childrenPadding: AppEdgeInsets.fromLTRB(
              a.scale(14),
              0,
              a.scale(14),
              a.scale(14, minFactor: 0.72),
            ),
            iconColor: context.placeColors.primary,
            collapsedIconColor: context.placeColors.primary,
            textColor: context.placeColors.textPrimary,
            collapsedTextColor: context.placeColors.textPrimary,
            backgroundColor: context.placeColors.surfaceHigh,
            collapsedBackgroundColor: context.placeColors.surfaceHigh,
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            leading: Container(
              width: a.scale(34, minFactor: 0.78),
              height: a.scale(34, minFactor: 0.78),
              decoration: AppBoxDecoration(
                color: context.placeColors.surfaceWarm,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: context.placeColors.primary,
                size: a.scale(17, minFactor: 0.8),
              ),
            ),
            title: Text(
              l10n.placeVisitPlanSection,
              style: AppTextStyle(
                color: context.placeColors.textPrimary,
                fontSize: a.scale(15, minFactor: 0.84),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: summary.isEmpty
                ? null
                : Padding(
                    padding: AppEdgeInsets.only(top: a.scale(2)),
                    child: Text(
                      summary,
                      style: AppTextStyle(
                        color: context.placeColors.primary,
                        fontSize: a.scale(11, minFactor: 0.82),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            children: [
              _InflapTipCard(tip: tip, l10n: l10n, adaptive: a),
              SizedBox(height: a.scale(8, minFactor: 0.72)),
              for (var i = 0; i < items.length; i++) ...[
                _VisitPlanRow(item: items[i], adaptive: a),
                if (i < items.length - 1)
                  Divider(
                    height: a.scale(1),
                    thickness: 1,
                    color: context.placeColors.white.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reviews section
  // ---------------------------------------------------------------------------

  Widget _buildReviews(PlaceAdaptive a, AppLocalizations l10n) {
    final excursionReviews = context
        .watch<ExcursionProvider>()
        .excursionReviewsForLandmark(widget.placeId);
    final currentUserId =
        (context.watch<SessionProvider>().profile?.userId ?? '').trim();
    final hasAnyReviews = _reviews.isNotEmpty || excursionReviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.placeReviewsTitle,
                style: AppTextStyle(
                  color: context.placeColors.textPrimary,
                  fontSize: a.scale(24, minFactor: 0.86),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_reviewTotal > 0)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: context.placeColors.primary,
                      padding: AppEdgeInsets.symmetric(horizontal: a.scale(8)),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.placeSeeAllReviews(_reviewTotal),
                      style: AppTextStyle(
                        fontSize: a.scale(13),
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: a.scale(12, minFactor: 0.72)),
        if (!hasAnyReviews)
          Container(
            width: double.infinity,
            padding: AppEdgeInsets.all(a.scale(14, minFactor: 0.74)),
            decoration: AppBoxDecoration(
              color: context.placeColors.white.withValues(alpha: 0.04),
              borderRadius: AppBorderRadius.circular(a.radius(14)),
              border: Border.all(
                color: context.placeColors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.placeNoReviews,
                  style: AppTextStyle(
                    color: context.placeColors.textMuted,
                    fontSize: a.scale(13, minFactor: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.32,
                  ),
                ),
                SizedBox(height: a.scale(12, minFactor: 0.72)),
                ElevatedButton.icon(
                  onPressed: _shouldShowReviewAction ? _openReviewSheet : null,
                  icon: Icon(
                    Icons.rate_review_rounded,
                    size: a.scale(17, minFactor: 0.82),
                  ),
                  label: Text(
                    l10n.placeAddReview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.placeColors.primary,
                    foregroundColor: context.placeColors.textPrimary,
                    disabledBackgroundColor: context.placeColors.primary
                        .withValues(alpha: 0.35),
                    disabledForegroundColor: context.placeColors.textPrimary
                        .withValues(alpha: 0.45),
                    elevation: 0,
                    minimumSize: Size(double.infinity, a.scale(44)),
                    padding: AppEdgeInsets.symmetric(horizontal: a.scale(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.circular(a.radius(12)),
                    ),
                    textStyle: AppTextStyle(
                      fontSize: a.scale(13, minFactor: 0.84),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < _reviews.length; i++) ...[
                _ReviewCard(review: _reviews[i], l10n: l10n, adaptive: a),
                if (i < _reviews.length - 1 || excursionReviews.isNotEmpty)
                  SizedBox(height: a.scale(14)),
              ],
              for (var i = 0; i < excursionReviews.length; i++) ...[
                _ExcursionPlaceReviewCard(
                  review: excursionReviews[i],
                  l10n: l10n,
                  adaptive: a,
                  currentUserId: currentUserId,
                  onLongPress: _openExcursionReviewActions,
                ),
                if (i < excursionReviews.length - 1)
                  SizedBox(height: a.scale(14)),
              ],
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom CTA — always visible "Find excursions"
  // ---------------------------------------------------------------------------

  Widget _buildBottomCta(PlaceAdaptive a, AppLocalizations l10n) {
    if (_place == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final padX = a.scale(28);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: AppEdgeInsets.fromLTRB(
          padX,
          a.scale(20),
          padX,
          mq.padding.bottom + a.scale(20),
        ),
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.placeColors.background.withValues(alpha: 0.0),
              context.placeColors.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isOpeningExcursions ? null : _openExcursionsForPlace,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.placeColors.primary,
              foregroundColor: context.placeColors.textPrimary,
              shadowColor: context.placeColors.primary.withValues(alpha: 0.22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.circular(a.radius(15)),
              ),
              minimumSize: Size.fromHeight(a.scale(55)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isOpeningExcursions) ...[
                  SizedBox(
                    width: a.scale(18),
                    height: a.scale(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.placeColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: a.scale(12)),
                ],
                Flexible(
                  child: Text(
                    l10n.placeFindExcursions,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle(
                      fontSize: a.scale(15),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (!_isOpeningExcursions) ...[
                  SizedBox(width: a.scale(10)),
                  Icon(Icons.chevron_right_rounded, size: a.scale(22)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceImageGallery extends StatefulWidget {
  const _PlaceImageGallery({required this.media, required this.initialIndex})
    : assert(media.length > 0);

  final List<PlaceMediaVm> media;
  final int initialIndex;

  @override
  State<_PlaceImageGallery> createState() => _PlaceImageGalleryState();
}

class _PlaceImageGalleryState extends State<_PlaceImageGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex
        .clamp(0, widget.media.length - 1)
        .toInt();
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.placeColors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.media.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) =>
                      _buildGalleryPage(context, widget.media[index]),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _GalleryIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onTap: () => Navigator.of(context).pop(_currentIndex),
                ),
              ),
              if (widget.media.length > 1)
                Positioned(
                  top: 15,
                  left: 76,
                  right: 76,
                  child: Center(
                    child: Container(
                      height: 38,
                      padding: const AppEdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: AppBoxDecoration(
                        color: context.placeColors.black.withValues(
                          alpha: 0.48,
                        ),
                        borderRadius: AppBorderRadius.circular(999),
                        border: Border.all(
                          color: context.placeColors.white.withValues(
                            alpha: 0.14,
                          ),
                        ),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.media.length}',
                        style: AppTextStyle(
                          color: context.placeColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildGalleryPage(BuildContext context, PlaceMediaVm media) {
    final mq = MediaQuery.of(context);
    final imageTargetWidth = placeImageTargetWidth(
      context,
      mq.size.width,
      minWidth: 900,
      maxWidth: 2200,
    );
    final url = resolvePlaceMediaUrl(media, targetWidth: imageTargetWidth);
    if (url == null) {
      return const _GalleryPlaceholder();
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(
        child: Image.network(
          url,
          headers: placeImageRequestHeaders(url),
          fit: BoxFit.contain,
          cacheWidth: imageTargetWidth,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return const _GalleryLoading();
          },
          errorBuilder: (_, _, _) => const _GalleryPlaceholder(),
        ),
      ),
    );
  }
}

class _GalleryIconButton extends StatelessWidget {
  const _GalleryIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: AppBoxDecoration(
            shape: BoxShape.circle,
            color: context.placeColors.black.withValues(alpha: 0.54),
            border: Border.all(
              color: context.placeColors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(icon, color: context.placeColors.white, size: 24),
        ),
      ),
    );
  }
}

class _GalleryLoading extends StatelessWidget {
  const _GalleryLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: context.placeColors.primary,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: context.placeColors.textMuted,
        size: 54,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visit plan cards and copy
// ---------------------------------------------------------------------------

class _FeeDetailRow extends StatelessWidget {
  const _FeeDetailRow({
    required this.place,
    required this.fee,
    required this.adaptive,
  });

  final PlaceVm place;
  final PlaceFeeDetailVm fee;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountLabel = formatPlaceFeeAmountLabel(
      context,
      l10n,
      place,
      fee,
      preferredCurrency: context.watch<SessionProvider>().profile?.currency,
      currencyRates: context.watch<CurrencyRateProvider>(),
    );
    final title = fee.title.trim();
    final descriptionParts = <String>[
      fee.description.trim(),
      fee.isRequired
          ? l10n.placeVisitRequiredLabel
          : l10n.placeVisitOptionalLabel,
      fee.note.trim(),
    ].where((part) => part.isNotEmpty).toList();
    final description = descriptionParts.join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackAmount =
            constraints.maxWidth < adaptive.scale(300, minFactor: 0.9) ||
            adaptive.textScaleFactor > 1.18;
        final textColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: AppTextStyle(
                  color: context.placeColors.textPrimary,
                  fontSize: adaptive.scale(13.5, minFactor: 0.84),
                  fontWeight: FontWeight.w900,
                  height: 1.16,
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (description.isNotEmpty) ...[
              SizedBox(height: adaptive.scale(3, minFactor: 0.72)),
              Text(
                description,
                style: AppTextStyle(
                  color: context.placeColors.primary,
                  fontSize: adaptive.scale(11.5, minFactor: 0.84),
                  fontWeight: FontWeight.w600,
                  height: 1.22,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

        final amountText = amountLabel.trim().isEmpty
            ? const SizedBox.shrink()
            : Text(
                amountLabel,
                style: AppTextStyle(
                  color: context.placeColors.primary,
                  fontSize: adaptive.scale(13, minFactor: 0.84),
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
                textAlign: stackAmount ? TextAlign.start : TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );

        if (stackAmount) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textColumn,
              if (amountLabel.trim().isNotEmpty) ...[
                SizedBox(height: adaptive.scale(6, minFactor: 0.72)),
                amountText,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textColumn),
            if (amountLabel.trim().isNotEmpty) ...[
              SizedBox(width: adaptive.scale(12, minFactor: 0.74)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: adaptive.scale(132)),
                child: amountText,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VisitPlanItem {
  const _VisitPlanItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _VisitPlanRow extends StatelessWidget {
  const _VisitPlanRow({required this.item, required this.adaptive});

  final _VisitPlanItem item;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = adaptive.scale(30, minFactor: 0.78);

    return Padding(
      padding: AppEdgeInsets.symmetric(vertical: adaptive.scale(9)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: AppBoxDecoration(
              color: context.placeColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: context.placeColors.primary,
              size: adaptive.scale(15, minFactor: 0.82),
            ),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyle(
                    color: context.placeColors.textPrimary,
                    fontSize: adaptive.scale(12.5, minFactor: 0.84),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: adaptive.scale(2, minFactor: 0.72)),
                Text(
                  item.value,
                  style: AppTextStyle(
                    color: context.placeColors.primary,
                    fontSize: adaptive.scale(11.5, minFactor: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessOptionCard extends StatelessWidget {
  const _AccessOptionCard({
    required this.option,
    required this.l10n,
    required this.adaptive,
  });

  final PlaceAccessOptionVm option;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final title = _transportTypeLabel(option.transportType, l10n);
    final duration = _formatVisitDurationRange(
      l10n,
      option.durationMinMinutes,
      option.durationMaxMinutes,
    );
    final distance = _formatDistanceKm(option.distanceKm, l10n);
    final road = _roadConditionLabel(option.roadCondition, l10n);
    final facts = <String>[
      if (duration.isNotEmpty) duration,
      if (distance.isNotEmpty) distance,
      if (road.isNotEmpty) road,
      if (option.requires4x4) l10n.placeVisitRequires4x4,
    ];
    final notes = <_VisitPlanItem>[
      if (option.routeHint.trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.near_me_rounded,
          label: l10n.placeVisitRouteHintLabel,
          value: option.routeHint.trim(),
        ),
      if (option.parkingNote.trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.local_parking_rounded,
          label: l10n.placeVisitParkingLabel,
          value: option.parkingNote.trim(),
        ),
      if (option.lastSegmentNote.trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.hiking_rounded,
          label: l10n.placeVisitLastSegmentLabel,
          value: option.lastSegmentNote.trim(),
        ),
      if (option.note.trim().isNotEmpty)
        _VisitPlanItem(
          icon: Icons.info_outline_rounded,
          label: l10n.placeInflapTipTitle,
          value: option.note.trim(),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: AppEdgeInsets.all(adaptive.scale(12, minFactor: 0.74)),
      decoration: AppBoxDecoration(
        color: context.placeColors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(adaptive.radius(12)),
        border: Border.all(
          color: context.placeColors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.directions_car_rounded,
                color: context.placeColors.primary,
                size: adaptive.scale(18, minFactor: 0.82),
              ),
              SizedBox(width: adaptive.scale(8, minFactor: 0.72)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle(
                        color: context.placeColors.textPrimary,
                        fontSize: adaptive.scale(13.5, minFactor: 0.84),
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (facts.isNotEmpty) ...[
                      SizedBox(height: adaptive.scale(4, minFactor: 0.72)),
                      Text(
                        facts.join(' · '),
                        style: AppTextStyle(
                          color: context.placeColors.primary,
                          fontSize: adaptive.scale(11.5, minFactor: 0.84),
                          fontWeight: FontWeight.w700,
                          height: 1.24,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            SizedBox(height: adaptive.scale(6, minFactor: 0.72)),
            for (var i = 0; i < notes.length; i++) ...[
              _VisitPlanRow(item: notes[i], adaptive: adaptive),
              if (i < notes.length - 1)
                Divider(
                  height: adaptive.scale(1),
                  thickness: 1,
                  color: context.placeColors.white.withValues(alpha: 0.06),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RecommendedItemChip extends StatelessWidget {
  const _RecommendedItemChip({
    required this.item,
    required this.l10n,
    required this.adaptive,
  });

  final PlaceRecommendedItemVm item;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final title =
        _knownRecommendedItemLabel(item.itemType, l10n) ??
        (item.title.trim().isNotEmpty
            ? item.title.trim()
            : _recommendedItemFallbackLabel(item.itemType, l10n));
    final note = item.note.trim();
    final importance = _code(item.importance) == 'REQUIRED'
        ? l10n.placeVisitRequiredLabel
        : l10n.placeVisitRecommendedLabel;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: adaptive.scale(132, minFactor: 0.74),
        maxWidth: adaptive.width < 380
            ? double.infinity
            : adaptive.scale(184, minFactor: 0.82),
      ),
      child: Container(
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(11, minFactor: 0.74),
          vertical: adaptive.scale(10, minFactor: 0.74),
        ),
        decoration: AppBoxDecoration(
          color: context.placeColors.surfaceHigh,
          borderRadius: AppBorderRadius.circular(adaptive.radius(12)),
          border: Border.all(
            color: context.placeColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _recommendedItemIcon(item.itemType),
              color: context.placeColors.primary,
              size: adaptive.scale(18, minFactor: 0.82),
            ),
            SizedBox(width: adaptive.scale(8, minFactor: 0.72)),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle(
                      color: context.placeColors.textPrimary,
                      fontSize: adaptive.scale(12.5, minFactor: 0.84),
                      fontWeight: FontWeight.w900,
                      height: 1.14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: adaptive.scale(2, minFactor: 0.72)),
                  Text(
                    note.isEmpty ? importance : '$importance · $note',
                    style: AppTextStyle(
                      color: context.placeColors.primary,
                      fontSize: adaptive.scale(10.8, minFactor: 0.82),
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticalNoteRow extends StatelessWidget {
  const _PracticalNoteRow({
    required this.note,
    required this.adaptive,
    required this.l10n,
  });

  final PlacePracticalNoteVm note;
  final PlaceAdaptive adaptive;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final title = _practicalNoteTitle(note, l10n);
    final body = note.body.trim();

    return Padding(
      padding: AppEdgeInsets.symmetric(vertical: adaptive.scale(9)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: adaptive.scale(30, minFactor: 0.78),
            height: adaptive.scale(30, minFactor: 0.78),
            decoration: AppBoxDecoration(
              color: context.placeColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _practicalNoteIcon(note.noteType),
              color: context.placeColors.primary,
              size: adaptive.scale(15, minFactor: 0.82),
            ),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: AppTextStyle(
                      color: context.placeColors.textPrimary,
                      fontSize: adaptive.scale(12.5, minFactor: 0.84),
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (body.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(2, minFactor: 0.72)),
                  Text(
                    body,
                    style: AppTextStyle(
                      color: context.placeColors.primary,
                      fontSize: adaptive.scale(11.5, minFactor: 0.84),
                      fontWeight: FontWeight.w600,
                      height: 1.24,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InflapTipCard extends StatelessWidget {
  const _InflapTipCard({
    required this.tip,
    required this.l10n,
    required this.adaptive,
  });

  final String tip;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppEdgeInsets.fromLTRB(
        adaptive.scale(12),
        adaptive.scale(11),
        adaptive.scale(12),
        adaptive.scale(11),
      ),
      decoration: AppBoxDecoration(
        color: context.placeColors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(adaptive.radius(13)),
        border: Border.all(
          color: context.placeColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: adaptive.scale(32, minFactor: 0.8),
            height: adaptive.scale(32, minFactor: 0.8),
            decoration: AppBoxDecoration(
              color: context.placeColors.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: context.placeColors.primary,
              size: adaptive.scale(16, minFactor: 0.82),
            ),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.placeInflapTipTitle,
                  style: AppTextStyle(
                    color: context.placeColors.textPrimary,
                    fontSize: adaptive.scale(12.5, minFactor: 0.84),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: adaptive.scale(3, minFactor: 0.72)),
                Text(
                  tip,
                  style: AppTextStyle(
                    color: context.placeColors.primary,
                    fontSize: adaptive.scale(11.5, minFactor: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _durationWithNote(AppLocalizations l10n, PlaceVisitDurationVm duration) {
  final label = _formatVisitDurationRange(
    l10n,
    duration.minMinutes,
    duration.maxMinutes,
  );
  final note = duration.note.trim();
  if (label.isEmpty) return note;
  if (note.isEmpty) return label;
  return '$label · $note';
}

String _formatVisitDurationRange(
  AppLocalizations l10n,
  int? minMinutes,
  int? maxMinutes,
) {
  if (minMinutes == null && maxMinutes == null) return '';
  if (minMinutes != null && maxMinutes != null) {
    if (minMinutes == maxMinutes) return _formatVisitMinutes(l10n, minMinutes);
    return '${_formatVisitMinutes(l10n, minMinutes)}–${_formatVisitMinutes(l10n, maxMinutes)}';
  }
  return _formatVisitMinutes(l10n, minMinutes ?? maxMinutes ?? 0);
}

String _formatVisitMinutes(AppLocalizations l10n, int minutes) {
  if (minutes <= 0) return l10n.placeVisitMinutes(0);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return l10n.placeVisitMinutes(minutes);
  if (rest == 0) return l10n.placeVisitHoursOnly(hours);
  return l10n.placeVisitHoursMinutes(hours, rest);
}

String _formatDistanceKm(double? value, AppLocalizations l10n) {
  if (value == null) return '';
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  return l10n.placeVisitDistanceKm(text);
}

String _transportTypeLabel(String? raw, AppLocalizations l10n) {
  switch (_code(raw)) {
    case 'CAR':
      return l10n.placeVisitTransportCar;
    case 'WALK':
    case 'WALKING':
      return l10n.placeVisitTransportWalk;
    case 'TAXI':
      return l10n.placeVisitTransportTaxi;
    case 'BUS':
      return l10n.placeVisitTransportBus;
    case 'CABLE_CAR':
    case 'CABLECAR':
      return l10n.placeVisitTransportCableCar;
    case 'SHUTTLE':
      return l10n.placeVisitTransportShuttle;
    case 'HORSE':
      return l10n.placeVisitTransportHorse;
    case 'TRAIN':
      return l10n.placeVisitTransportTrain;
    case 'BOAT':
      return l10n.placeVisitTransportBoat;
    default:
      final value = (raw ?? '').trim();
      return value.isEmpty ? l10n.placeVisitAccessLabel : value;
  }
}

String _roadConditionLabel(String? raw, AppLocalizations l10n) {
  switch (_code(raw)) {
    case 'PAVED':
    case 'ASPHALT':
      return l10n.placeVisitRoadPaved;
    case 'GRAVEL':
      return l10n.placeVisitRoadGravel;
    case 'MOUNTAIN':
      return l10n.placeVisitRoadMountain;
    case 'MIXED':
      return l10n.placeVisitRoadMixed;
    case 'OFFROAD':
    case 'OFF_ROAD':
    case 'DIRT':
      return l10n.placeVisitRoadOffroad;
    default:
      return (raw ?? '').trim();
  }
}

String _recommendedItemFallbackLabel(String? raw, AppLocalizations l10n) {
  final localized = _knownRecommendedItemLabel(raw, l10n);
  if (localized != null) return localized;
  final value = (raw ?? '').trim();
  return value.isEmpty ? l10n.placeVisitRecommendedLabel : value;
}

String? _knownRecommendedItemLabel(String? raw, AppLocalizations l10n) {
  switch (_code(raw)) {
    case 'WATER':
      return l10n.placeVisitItemWater;
    case 'SHOES':
    case 'BOOTS':
      return l10n.placeVisitItemShoes;
    case 'CASH':
      return l10n.placeVisitItemCash;
    case 'WARM_CLOTHES':
      return l10n.placeVisitItemWarmClothes;
    case 'POWERBANK':
      return l10n.placeVisitItemPowerbank;
    case 'DOCUMENTS':
      return l10n.placeVisitItemDocuments;
    case 'FOOD':
      return l10n.placeVisitItemFood;
    case 'SPF':
    case 'SUNSCREEN':
    case 'HAT':
      return l10n.placeVisitItemSpf;
    case 'RAIN':
    case 'RAINCOAT':
      return l10n.placeVisitItemRain;
    case 'MAP':
    case 'OFFLINE_MAP':
      return l10n.placeVisitItemMap;
    case 'REPELLENT':
      return l10n.placeVisitItemRepellent;
    case 'FIRST_AID':
    case 'MEDKIT':
      return l10n.placeVisitItemFirstAid;
    case 'OTHER':
      return l10n.placeVisitItemOther;
    default:
      return null;
  }
}

IconData _recommendedItemIcon(String? raw) {
  switch (_code(raw)) {
    case 'WATER':
      return Icons.water_drop_rounded;
    case 'SHOES':
    case 'BOOTS':
      return Icons.hiking_rounded;
    case 'CASH':
      return Icons.payments_rounded;
    case 'WARM_CLOTHES':
      return Icons.checkroom_rounded;
    case 'POWERBANK':
      return Icons.battery_charging_full_rounded;
    case 'DOCUMENTS':
      return Icons.badge_rounded;
    case 'FOOD':
      return Icons.restaurant_rounded;
    case 'SPF':
    case 'SUNSCREEN':
    case 'HAT':
      return Icons.wb_sunny_rounded;
    case 'RAIN':
    case 'RAINCOAT':
      return Icons.umbrella_rounded;
    case 'MAP':
    case 'OFFLINE_MAP':
      return Icons.map_rounded;
    case 'REPELLENT':
      return Icons.bug_report_rounded;
    case 'FIRST_AID':
    case 'MEDKIT':
      return Icons.medical_services_rounded;
    default:
      return Icons.backpack_rounded;
  }
}

String _practicalNoteTitle(PlacePracticalNoteVm note, AppLocalizations l10n) {
  switch (_code(note.noteType)) {
    case 'GENERAL':
    case 'TEMPORARY_PLACEHOLDER':
      return l10n.placeVisitPracticalGeneral;
    case 'CONNECTION':
      return l10n.placeVisitPracticalConnection;
    case 'TOILET':
      return l10n.placeVisitPracticalToilet;
    case 'CAFE':
    case 'FOOD':
      return l10n.placeVisitPracticalCafe;
    case 'SAFETY':
      return l10n.placeVisitPracticalSafety;
    case 'KIDS':
      return l10n.placeVisitPracticalKids;
    case 'WEATHER':
      return l10n.placeVisitPracticalWeather;
    default:
      final title = note.title.trim();
      return title.isNotEmpty ? title : note.noteType.trim();
  }
}

IconData _practicalNoteIcon(String? raw) {
  switch (_code(raw)) {
    case 'CONNECTION':
      return Icons.signal_cellular_alt_rounded;
    case 'TOILET':
      return Icons.wc_rounded;
    case 'CAFE':
    case 'FOOD':
      return Icons.restaurant_rounded;
    case 'SAFETY':
      return Icons.health_and_safety_rounded;
    case 'KIDS':
      return Icons.family_restroom_rounded;
    case 'WEATHER':
      return Icons.cloud_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

List<_VisitPlanItem> _visitPlanItems(
  BuildContext context,
  PlaceVm place,
  AppLocalizations l10n,
) {
  final duration = formatPlaceDurationLabel(l10n, place);
  final ticket = place.priceAmount == null
      ? l10n.placeVisitFreeEntry
      : formatPlacePriceLabel(
          context,
          l10n,
          place,
          preferredCurrency: context.watch<SessionProvider>().profile?.currency,
          currencyRates: context.watch<CurrencyRateProvider>(),
        );
  final bookingSuffix = place.visitInfo.bookingRequired == true
      ? ' · ${l10n.placeVisitBookingRecommended}'
      : '';
  final goodFor = _audienceLabels(place, l10n);
  final safety = _safetyLabels(place.visitInfo.safetyNotes, l10n);

  return [
    _VisitPlanItem(
      icon: Icons.schedule_rounded,
      label: l10n.placeVisitDurationLabel,
      value: duration.isNotEmpty ? duration : l10n.placeVisitDurationFlexible,
    ),
    _VisitPlanItem(
      icon: Icons.confirmation_number_outlined,
      label: l10n.placeVisitTicketsLabel,
      value: '$ticket$bookingSuffix',
    ),
    _VisitPlanItem(
      icon: Icons.wb_twilight_rounded,
      label: l10n.placeVisitBestTimeLabel,
      value: _bestTimeLabel(place, l10n),
    ),
    _VisitPlanItem(
      icon: Icons.groups_rounded,
      label: l10n.placeVisitGoodForLabel,
      value: goodFor.isEmpty
          ? l10n.placeTagUniqueSubtitle
          : goodFor.join(' · '),
    ),
    _VisitPlanItem(
      icon: Icons.accessible_rounded,
      label: l10n.placeVisitAccessLabel,
      value: _accessibilityLabel(place.visitInfo.accessibility, l10n),
    ),
    if (safety.isNotEmpty)
      _VisitPlanItem(
        icon: Icons.health_and_safety_rounded,
        label: l10n.placeVisitSafetyLabel,
        value: safety.join(' · '),
      ),
  ];
}

String _visitPlanSummary(List<_VisitPlanItem> items) {
  final values = <String>[];
  for (final item in items) {
    final value = item.value.trim();
    if (value.isEmpty) continue;
    values.add(value);
    if (values.length == 2) break;
  }
  return values.join(' · ');
}

String _localizedInflapTip(
  BuildContext context,
  PlaceVm place,
  AppLocalizations l10n,
) {
  final locale = Localizations.localeOf(context).languageCode.toLowerCase();
  final tips = place.visitInfo.localizedTips;
  final localized = tips[locale] ?? tips[place.locale] ?? tips['en'];
  if ((localized ?? '').trim().isNotEmpty) {
    return localized!.trim();
  }

  final category = place.category.toUpperCase();
  final isLongRoute =
      place.durationUnit?.toUpperCase() == 'DAYS' ||
      (place.durationValue ?? 0) >= 6;
  if (_isNatureLikeCategory(category) || isLongRoute) {
    return l10n.placeVisitTipNature;
  }
  if (_isCultureLikeCategory(category)) {
    return l10n.placeVisitTipCulture;
  }
  return l10n.placeVisitTipDefault;
}

String _bestTimeLabel(PlaceVm place, AppLocalizations l10n) {
  final code = _code(place.visitInfo.bestTime);
  switch (code.isEmpty ? _fallbackBestTimeCode(place) : code) {
    case 'EARLY_MORNING':
      return l10n.placeVisitBestTimeEarlyMorning;
    case 'MORNING':
      return l10n.placeVisitBestTimeMorning;
    case 'AFTERNOON':
      return l10n.placeVisitBestTimeAfternoon;
    case 'SUNSET':
      return l10n.placeVisitBestTimeSunset;
    default:
      return l10n.placeVisitBestTimeAnytime;
  }
}

String _bestSeasonLabel(PlaceVm place, AppLocalizations l10n) {
  final note = place.visitInfo.season?.note.trim() ?? '';
  if (note.isNotEmpty) return note;
  return _bestTimeLabel(place, l10n);
}

String _fallbackBestTimeCode(PlaceVm place) {
  final category = place.category.toUpperCase();
  if (_isNatureLikeCategory(category)) return 'EARLY_MORNING';
  if (_isCultureLikeCategory(category)) return 'MORNING';
  return 'AFTERNOON';
}

String _accessibilityLabel(String? raw, AppLocalizations l10n) {
  switch (_code(raw)) {
    case 'GOOD':
      return l10n.placeVisitAccessGood;
    case 'LIMITED':
      return l10n.placeVisitAccessLimited;
    default:
      return l10n.placeVisitAccessUnknown;
  }
}

List<String> _audienceLabels(PlaceVm place, AppLocalizations l10n) {
  final codes = <String>{
    ...place.visitInfo.audience.map(_code),
    ..._recognizedAudienceCodesFromTags(place.tags),
  }..remove('');

  const ordered = [
    'FAMILY',
    'COUPLES',
    'PHOTO',
    'OUTDOOR',
    'HISTORY',
    'ADVENTURE',
    'WELLNESS',
  ];
  return [
    for (final code in ordered)
      if (codes.contains(code)) _audienceLabel(code, l10n),
  ].take(3).toList();
}

String _audienceLabel(String code, AppLocalizations l10n) {
  switch (code) {
    case 'FAMILY':
      return l10n.placeTagFamilyLabel;
    case 'COUPLES':
      return l10n.placeVisitAudienceCouples;
    case 'PHOTO':
      return l10n.placeTagPhotoLabel;
    case 'OUTDOOR':
      return l10n.placeTagOutdoorLabel;
    case 'HISTORY':
      return l10n.placeTagHistoryLabel;
    case 'ADVENTURE':
      return l10n.placeTagAdventureLabel;
    case 'WELLNESS':
      return l10n.placeVisitAudienceWellness;
    default:
      return l10n.placeTagUniqueSubtitle;
  }
}

Set<String> _recognizedAudienceCodesFromTags(List<String> tags) {
  final result = <String>{};
  for (final rawTag in tags) {
    final tag = rawTag.toLowerCase().replaceAll('_', '-');
    if (tag.contains('family')) result.add('FAMILY');
    if (tag.contains('photo') || tag.contains('viewpoint')) result.add('PHOTO');
    if (tag.contains('nature') ||
        tag.contains('lake') ||
        tag.contains('park')) {
      result.add('OUTDOOR');
    }
    if (tag.contains('history') ||
        tag.contains('museum') ||
        tag.contains('unesco') ||
        tag.contains('heritage')) {
      result.add('HISTORY');
    }
    if (tag.contains('hiking') ||
        tag.contains('ski') ||
        tag.contains('sport') ||
        tag.contains('adventure')) {
      result.add('ADVENTURE');
    }
    if (tag.contains('wellness') || tag.contains('beach')) {
      result.add('WELLNESS');
    }
  }
  return result;
}

List<String> _safetyLabels(List<String> codes, AppLocalizations l10n) {
  final result = <String>[];
  for (final raw in codes) {
    switch (_code(raw)) {
      case 'CHECK_WEATHER':
        result.add(l10n.placeVisitSafetyCheckWeather);
      case 'BRING_WATER':
        result.add(l10n.placeVisitSafetyBringWater);
      case 'CHECK_HOURS':
        result.add(l10n.placeVisitSafetyCheckHours);
    }
    if (result.length >= 2) break;
  }
  return result;
}

bool _isNatureLikeCategory(String category) {
  return {'NATURE', 'BEACH', 'PARK', 'PARKS'}.contains(category);
}

bool _isCultureLikeCategory(String category) {
  return {'ARCHITECTURE', 'MUSEUM', 'MUSEUMS', 'TEMPLE'}.contains(category);
}

String _code(String? raw) {
  return (raw ?? '')
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

// ---------------------------------------------------------------------------
// Review card with orange left bar
// ---------------------------------------------------------------------------

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.l10n,
    required this.adaptive,
  });

  final PlaceReviewVm review;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = review.author.avatarFileId != null
        ? resolvePublicFileContentUrl(review.author.avatarFileId!)
        : null;

    return Container(
      decoration: AppBoxDecoration(
        color: context.placeColors.surfaceHigh,
        borderRadius: AppBorderRadius.circular(adaptive.radius(15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: adaptive.scale(8),
            bottom: adaptive.scale(8),
            child: Container(
              width: 4,
              decoration: AppBoxDecoration(
                color: context.placeColors.primary,
                borderRadius: AppBorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: AppEdgeInsets.fromLTRB(
              adaptive.scale(26, minFactor: 0.7),
              adaptive.scale(25),
              adaptive.scale(22, minFactor: 0.78),
              adaptive.scale(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: adaptive.scale(19),
                      backgroundColor: context.placeColors.secondary,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person_rounded,
                              color: context.placeColors.white.withValues(
                                alpha: 0.85,
                              ),
                              size: adaptive.scale(20),
                            )
                          : null,
                    ),
                    SizedBox(width: adaptive.scale(14, minFactor: 0.7)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.author.nickname ??
                                l10n.placeTravelerFallback,
                            style: AppTextStyle(
                              color: context.placeColors.textPrimary,
                              fontSize: adaptive.scale(14),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: adaptive.scale(3)),
                          Text(
                            l10n.placeVerifiedNomad.toUpperCase(),
                            style: AppTextStyle(
                              color: context.placeColors.primary,
                              fontSize: adaptive.scale(10),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: adaptive.scale(8)),
                    _buildStars(context, review.rating, adaptive),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(16)),
                  SizedBox(height: adaptive.scale(4)),
                  Text(
                    '"${review.comment}"',
                    style: AppTextStyle(
                      color: context.placeColors.primary,
                      fontSize: adaptive.scale(14),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (review.media.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(14)),
                  _buildMediaStrip(review.media, adaptive),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaStrip(List<PlaceMediaVm> media, PlaceAdaptive a) {
    final sorted = List<PlaceMediaVm>.from(media)
      ..sort((x, y) => x.position.compareTo(y.position));
    return SizedBox(
      height: a.scale(82),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, _) => SizedBox(width: a.scale(8)),
        itemBuilder: (context, index) =>
            _buildMediaTile(context, sorted[index], a),
      ),
    );
  }

  Widget _buildMediaTile(
    BuildContext context,
    PlaceMediaVm media,
    PlaceAdaptive a,
  ) {
    final imageTargetWidth = placeImageTargetWidth(
      context,
      a.scale(96),
      minWidth: 220,
      maxWidth: 360,
    );
    final url = resolvePlaceMediaUrl(media, targetWidth: imageTargetWidth);
    final isVideo = media.mediaType.toUpperCase() == 'VIDEO';

    return ClipRRect(
      borderRadius: AppBorderRadius.circular(a.radius(10)),
      child: Container(
        width: a.scale(96),
        height: a.scale(82),
        color: context.placeColors.white.withValues(alpha: 0.07),
        child: isVideo
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: context.placeColors.black.withValues(alpha: 0.35),
                  ),
                  Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: context.placeColors.primary,
                      size: a.scale(32),
                    ),
                  ),
                ],
              )
            : (url == null
                  ? Icon(
                      Icons.image_rounded,
                      color: context.placeColors.textMuted,
                      size: a.scale(28),
                    )
                  : Image.network(
                      url,
                      headers: placeImageRequestHeaders(url),
                      fit: BoxFit.cover,
                      cacheWidth: imageTargetWidth,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }
                        return Icon(
                          Icons.image_rounded,
                          color: context.placeColors.textMuted,
                          size: a.scale(28),
                        );
                      },
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_not_supported_rounded,
                        color: context.placeColors.textMuted,
                        size: a.scale(28),
                      ),
                    )),
      ),
    );
  }

  Widget _buildStars(BuildContext context, double rating, PlaceAdaptive a) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return Icon(
            Icons.star_rounded,
            color: context.placeColors.primary,
            size: a.scale(13),
          );
        }
        if (i == fullStars && hasHalf) {
          return Icon(
            Icons.star_half_rounded,
            color: context.placeColors.primary,
            size: a.scale(13),
          );
        }
        return Icon(
          Icons.star_border_rounded,
          color: context.placeColors.primary.withValues(alpha: 0.4),
          size: a.scale(13),
        );
      }),
    );
  }
}

class _ExcursionPlaceReviewCard extends StatelessWidget {
  const _ExcursionPlaceReviewCard({
    required this.review,
    required this.l10n,
    required this.adaptive,
    required this.currentUserId,
    this.onLongPress,
  });

  final ExcursionReviewVm review;
  final AppLocalizations l10n;
  final PlaceAdaptive adaptive;
  final String currentUserId;
  final ValueChanged<ExcursionReviewVm>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final guideName = review.guideDisplayName.trim().isEmpty
        ? l10n.myExcursionsGuideFallback
        : review.guideDisplayName.trim();
    final authorName = review.author.resolvedDisplayName.isEmpty
        ? l10n.placeTravelerFallback
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
        decoration: AppBoxDecoration(
          color: context.placeColors.surfaceHigh,
          borderRadius: AppBorderRadius.circular(adaptive.radius(15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: adaptive.scale(8),
              bottom: adaptive.scale(8),
              child: Container(
                width: 4,
                decoration: AppBoxDecoration(
                  color: context.placeColors.primary,
                  borderRadius: AppBorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: AppEdgeInsets.fromLTRB(
                adaptive.scale(26, minFactor: 0.7),
                adaptive.scale(22),
                adaptive.scale(22, minFactor: 0.78),
                adaptive.scale(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: adaptive.scale(8),
                    runSpacing: adaptive.scale(8),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: AppEdgeInsets.symmetric(
                          horizontal: adaptive.scale(10),
                          vertical: adaptive.scale(6),
                        ),
                        decoration: AppBoxDecoration(
                          color: context.placeColors.primary.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: AppBorderRadius.circular(999),
                          border: Border.all(
                            color: context.placeColors.primary.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.excursionReviewSourcePlaceBadge,
                          style: AppTextStyle(
                            color: context.placeColors.primary,
                            fontSize: adaptive.scale(10),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      _buildExcursionStars(context, review.rating, adaptive),
                    ],
                  ),
                  SizedBox(height: adaptive.scale(12)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: adaptive.scale(18),
                        backgroundColor: context.placeColors.secondary,
                        backgroundImage: authorAvatarUrl != null
                            ? NetworkImage(authorAvatarUrl)
                            : null,
                        child: authorAvatarUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                color: context.placeColors.white.withValues(
                                  alpha: 0.85,
                                ),
                                size: adaptive.scale(19),
                              )
                            : null,
                      ),
                      SizedBox(width: adaptive.scale(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle(
                                color: context.placeColors.textPrimary,
                                fontSize: adaptive.scale(14),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: adaptive.scale(3)),
                            Text(
                              l10n.excursionReviewViaGuide(guideName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle(
                                color: context.placeColors.primary,
                                fontSize: adaptive.scale(11),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review.comment.trim().isNotEmpty) ...[
                    SizedBox(height: adaptive.scale(12)),
                    Text(
                      '"${review.comment}"',
                      style: AppTextStyle(
                        color: context.placeColors.primary,
                        fontSize: adaptive.scale(14),
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.55,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildExcursionStars(
  BuildContext context,
  double rating,
  PlaceAdaptive adaptive,
) {
  final fullStars = rating.floor();
  final hasHalf = (rating - fullStars) >= 0.5;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      if (index < fullStars) {
        return Icon(
          Icons.star_rounded,
          color: context.placeColors.primary,
          size: adaptive.scale(13),
        );
      }
      if (index == fullStars && hasHalf) {
        return Icon(
          Icons.star_half_rounded,
          color: context.placeColors.primary,
          size: adaptive.scale(13),
        );
      }
      return Icon(
        Icons.star_border_rounded,
        color: context.placeColors.primary.withValues(alpha: 0.4),
        size: adaptive.scale(13),
      );
    }),
  );
}

typedef _SubmitReviewCallback =
    Future<bool> Function(
      double rating,
      String comment,
      List<_ReviewDraftMedia> media,
    );

class _ReviewDraftMedia {
  const _ReviewDraftMedia({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    required this.mediaType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
  final String mediaType;

  bool get isPhoto => mediaType == 'PHOTO';
}

class _CreateReviewSheet extends StatefulWidget {
  const _CreateReviewSheet({required this.l10n, required this.onSubmit});

  final AppLocalizations l10n;
  final _SubmitReviewCallback onSubmit;

  @override
  State<_CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<_CreateReviewSheet> {
  static const int _maxReviewMediaItems = 5;
  static const int _maxPhotoBytes = 20 * 1024 * 1024;
  static const int _maxVideoBytes = 50 * 1024 * 1024;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  final List<_ReviewDraftMedia> _media = [];

  double _rating = 5;
  bool _submitting = false;
  String? _errorText;
  String? _mediaErrorText;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_handleCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_handleCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _handleCommentChanged() {
    if (_errorText != null) {
      setState(() => _errorText = null);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final canSubmit = !_submitting && _commentController.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
          decoration: AppBoxDecoration(
            color: context.placeColors.background,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const AppEdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: AppBoxDecoration(
                      color: context.placeColors.white.withValues(alpha: 0.22),
                      borderRadius: AppBorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.l10n.placeReviewSheetTitle,
                        style: AppTextStyle(
                          color: context.placeColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close_rounded),
                      color: context.placeColors.textSecondary,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.l10n.placeReviewRatingLabel,
                  style: AppTextStyle(
                    color: context.placeColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRatingPicker(),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  style: AppTextStyle(
                    color: context.placeColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: AppInputDecoration(
                    labelText: widget.l10n.placeReviewCommentLabel,
                    hintText: widget.l10n.placeReviewCommentHint,
                    errorText: _errorText,
                    filled: true,
                    fillColor: context.placeColors.white.withValues(
                      alpha: 0.06,
                    ),
                    counterStyle: AppTextStyle(
                      color: context.placeColors.textMuted,
                      fontSize: 11,
                    ),
                    labelStyle: AppTextStyle(
                      color: context.placeColors.textMuted,
                    ),
                    hintStyle: AppTextStyle(
                      color: context.placeColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppBorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: context.placeColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMediaActions(),
                if (_mediaErrorText != null) ...[
                  AppInlineFieldError(message: _mediaErrorText!),
                ],
                if (_media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDraftMediaStrip(),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.placeColors.primary,
                      foregroundColor: context.placeColors.textPrimary,
                      disabledBackgroundColor: context.placeColors.white
                          .withValues(alpha: 0.12),
                      disabledForegroundColor: context.placeColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.placeColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  widget.l10n.placeReviewSubmitting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.l10n.placeReviewSubmit,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildRatingPicker() {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= _rating.round();
        return IconButton(
          onPressed: _submitting
              ? null
              : () => setState(() => _rating = value.toDouble()),
          padding: AppEdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 42, height: 42),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected
                ? context.placeColors.primary
                : context.placeColors.textMuted,
            size: 34,
          ),
        );
      }),
    );
  }

  Widget _buildMediaActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final photoButton = OutlinedButton.icon(
          onPressed: _submitting ? null : _pickPhoto,
          icon: Icon(Icons.photo_camera_rounded, size: 18),
          label: Text(
            widget.l10n.placeReviewAddPhoto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: _mediaButtonStyle(context),
        );
        final videoButton = OutlinedButton.icon(
          onPressed: _submitting ? null : _pickVideo,
          icon: Icon(Icons.videocam_rounded, size: 18),
          label: Text(
            widget.l10n.placeReviewAddVideo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: _mediaButtonStyle(context),
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [photoButton, const SizedBox(height: 8), videoButton],
          );
        }

        return Row(
          children: [
            Expanded(child: photoButton),
            const SizedBox(width: 10),
            Expanded(child: videoButton),
          ],
        );
      },
    );
  }

  ButtonStyle _mediaButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: context.placeColors.primary,
      side: BorderSide(
        color: context.placeColors.primary.withValues(alpha: 0.55),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(12)),
      padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildDraftMediaStrip() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _media.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _media[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: AppBorderRadius.circular(12),
                child: Container(
                  width: 104,
                  height: 88,
                  color: context.placeColors.white.withValues(alpha: 0.07),
                  child: item.isPhoto
                      ? Image.memory(
                          item.bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: context.placeColors.primary,
                              size: 34,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const AppEdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                widget.l10n.placeReviewVideoPreview,
                                style: AppTextStyle(
                                  color: context.placeColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: widget.l10n.placeReviewRemoveMedia,
                  child: InkWell(
                    onTap: _submitting
                        ? null
                        : () => setState(() => _media.removeAt(index)),
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 26,
                      height: 26,
                      decoration: AppBoxDecoration(
                        color: context.placeColors.black.withValues(
                          alpha: 0.62,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.placeColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (!_ensureMediaSlot()) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showError(widget.l10n.placeReviewPickFailed);
        return;
      }
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        _showError(widget.l10n.placeReviewMediaTooLarge);
        return;
      }

      final contentType =
          _detectImageContentType(bytes) ?? _contentTypeFromName(picked.name);
      if (contentType == null || !_isAllowedPhotoContentType(contentType)) {
        _showError(widget.l10n.placeReviewUnsupportedFormat);
        return;
      }

      setState(() {
        _mediaErrorText = null;
        _media.add(
          _ReviewDraftMedia(
            bytes: bytes,
            fileName: _normalizeMediaFileName(picked.name, contentType),
            contentType: contentType,
            mediaType: 'PHOTO',
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        _showError(widget.l10n.placeReviewPickFailed);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (!_ensureMediaSlot()) return;

    try {
      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showError(widget.l10n.placeReviewPickFailed);
        return;
      }
      if (bytes.lengthInBytes > _maxVideoBytes) {
        _showError(widget.l10n.placeReviewMediaTooLarge);
        return;
      }

      final contentType = picked.mimeType ?? _contentTypeFromName(picked.name);
      if (contentType == null || !_isAllowedVideoContentType(contentType)) {
        _showError(widget.l10n.placeReviewUnsupportedFormat);
        return;
      }

      setState(() {
        _mediaErrorText = null;
        _media.add(
          _ReviewDraftMedia(
            bytes: bytes,
            fileName: _normalizeMediaFileName(picked.name, contentType),
            contentType: contentType,
            mediaType: 'VIDEO',
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        _showError(widget.l10n.placeReviewPickFailed);
      }
    }
  }

  bool _ensureMediaSlot() {
    if (_media.length < _maxReviewMediaItems) {
      return true;
    }
    _showError(widget.l10n.placeReviewMediaLimit(_maxReviewMediaItems));
    return false;
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _errorText = widget.l10n.placeReviewCommentRequired);
      return;
    }

    setState(() => _submitting = true);
    final success = await widget.onSubmit(
      _rating,
      comment,
      List<_ReviewDraftMedia>.unmodifiable(_media),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  void _showError(String message) {
    setState(() => _mediaErrorText = message);
  }

  String? _detectImageContentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  String? _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }
    if (lower.endsWith('.m4v')) {
      return 'video/x-m4v';
    }
    return null;
  }

  bool _isAllowedPhotoContentType(String? contentType) {
    return contentType == 'image/jpeg' ||
        contentType == 'image/png' ||
        contentType == 'image/webp';
  }

  bool _isAllowedVideoContentType(String? contentType) {
    return contentType == 'video/mp4' ||
        contentType == 'video/quicktime' ||
        contentType == 'video/webm' ||
        contentType == 'video/x-m4v';
  }

  String _normalizeMediaFileName(String rawName, String contentType) {
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'video/mp4' => 'mp4',
      'video/quicktime' => 'mov',
      'video/webm' => 'webm',
      'video/x-m4v' => 'm4v',
      _ => 'jpg',
    };
    final trimmed = rawName.trim().split('/').last;
    final dotIndex = trimmed.lastIndexOf('.');
    final base = dotIndex > 0 ? trimmed.substring(0, dotIndex) : trimmed;
    final safeBase = base
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');

    return '${safeBase.isEmpty ? 'place-review-media' : safeBase}.$extension';
  }
}
