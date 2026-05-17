import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/attractions/attraction_ui.dart';
import '../../features/attractions/data/attraction_api.dart';
import '../../features/attractions/models/attraction_review_vm.dart';
import '../../features/attractions/models/attraction_vm.dart';
import '../../features/excursions/models/excursion_booking_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/excursion_provider.dart';
import '../../providers/session_provider.dart';
import '../map/map_screen.dart';

class AttractionDetailsScreen extends StatefulWidget {
  const AttractionDetailsScreen({
    super.key,
    required this.attractionId,
    this.initialAttraction,
  });

  final String attractionId;
  final AttractionVm? initialAttraction;

  @override
  State<AttractionDetailsScreen> createState() =>
      _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> {
  final AttractionApi _api = AttractionApi();
  final FileApi _fileApi = FileApi();
  final ReferenceApi _referenceApi = ReferenceApi();
  final ScrollController _scrollController = ScrollController();
  final PageController _heroImageController = PageController();

  AttractionVm? _attraction;
  List<AttractionReviewVm> _reviews = [];
  AttractionReviewVm? _currentUserReview;
  int _reviewTotal = 0;
  bool _loading = true;
  bool _submittingReview = false;
  bool _checkingCurrentUserReview = false;
  String? _error;
  String? _locationLabel;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _attraction = widget.initialAttraction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
      _loading = _attraction == null;
      _checkingCurrentUserReview = currentUserId.isNotEmpty;
      _error = null;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final excursionProvider = context.read<ExcursionProvider>();
      final results = await Future.wait([
        _api.getAttraction(widget.attractionId, locale: locale),
        _api.getReviews(widget.attractionId, limit: 5),
        _loadCurrentUserReview(currentUserId),
        excursionProvider.loadExcursionReviews(landmarkId: widget.attractionId),
      ]);

      if (!mounted) return;
      final attraction = results[0] as AttractionVm;
      final reviewResult =
          results[1] as ({List<AttractionReviewVm> items, int total});
      final currentUserReview =
          (results[2] as AttractionReviewVm?) ??
          _findReviewByAuthor(reviewResult.items, currentUserId);
      final locationLabel = await _resolveLocationLabel(attraction, locale);
      final mediaCount = attraction.media.length;
      final imageIndex = mediaCount == 0
          ? 0
          : _currentImageIndex.clamp(0, mediaCount - 1).toInt();

      setState(() {
        _attraction = attraction;
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

  Future<AttractionReviewVm?> _loadCurrentUserReview(
    String currentUserId,
  ) async {
    if (currentUserId.isEmpty) {
      return null;
    }
    try {
      return await _api.getMyReview(widget.attractionId);
    } catch (_) {
      return null;
    }
  }

  AttractionReviewVm? _findReviewByAuthor(
    List<AttractionReviewVm> reviews,
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

  Future<String> _resolveLocationLabel(
    AttractionVm attraction,
    String locale,
  ) async {
    final fallback = _fallbackLocationLabel(attraction);
    final countryCode = attraction.countryCode.trim().toUpperCase();
    final cityId = attraction.cityId.trim();
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

  String _fallbackLocationLabel(AttractionVm attraction) {
    final parts = <String>[
      if (attraction.cityId.trim().isNotEmpty) attraction.cityId.trim(),
      if (attraction.countryCode.trim().isNotEmpty)
        attraction.countryCode.trim().toUpperCase(),
    ];
    return parts.join(', ');
  }

  Future<void> _openReviewSheet() async {
    if (_attraction == null) return;
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CreateReviewSheet(l10n: l10n, onSubmit: _submitReview),
    );
  }

  Future<void> _openImageGallery(
    List<AttractionMediaVm> media,
    int initialIndex,
  ) async {
    if (media.isEmpty) return;
    final selectedIndex = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AttractionImageGallery(
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
      final uploadedMedia = <AttractionReviewMediaInput>[];
      for (var i = 0; i < media.length; i++) {
        final item = media[i];
        final upload = await _fileApi.createAttractionReviewMediaUpload(
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
          AttractionReviewMediaInput(
            fileId: upload.fileId,
            mediaType: item.mediaType,
            position: i,
          ),
        );
      }

      final createdReview = await _api.createReview(
        widget.attractionId,
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
      _showSnack(l10n.attractionReviewSubmitSuccess);
      return true;
    } on DioException catch (e) {
      if (mounted) {
        _showSnack(DioErrorMapper.toMessage(e));
      }
      return false;
    } catch (_) {
      if (mounted) {
        _showSnack(l10n.attractionReviewSubmitFailed);
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

  String _resolvedLocationLabel(AttractionVm attraction) {
    final resolved = (_locationLabel?.trim().isNotEmpty ?? false)
        ? _locationLabel!.trim()
        : _fallbackLocationLabel(attraction);
    return resolved.trim().isNotEmpty
        ? resolved.trim()
        : attraction.countryCode.trim().toUpperCase();
  }

  void _openMap() {
    final attraction = _attraction;
    if (attraction != null && attraction.hasLocation) {
      final sourceUrl = attraction.locationSourceUrl.trim();
      context.push(
        '/map',
        extra: MapTarget(
          title: attraction.title,
          subtitle: _resolvedLocationLabel(attraction),
          latitude: attraction.latitude!,
          longitude: attraction.longitude!,
          sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
        ),
      );
      return;
    }

    context.push('/map');
  }

  @override
  Widget build(BuildContext context) {
    return AttractionTextScale(
      child: Builder(
        builder: (context) {
          final adaptive = AttractionAdaptive.of(context);
          final l10n = AppLocalizations.of(context)!;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: const Color(0xFF211609),
              body: SafeArea(
                bottom: false,
                child: _loading && _attraction == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    : _error != null && _attraction == null
                    ? _buildError(l10n, adaptive)
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                _buildTopBar(adaptive, l10n),
                                Expanded(
                                  child: RefreshIndicator(
                                    color: AppColors.accent,
                                    backgroundColor: const Color(0xFF271609),
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

  Widget _buildError(AppLocalizations l10n, AttractionAdaptive a) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.attractionDetailsLoadFailed,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: a.scale(12)),
          TextButton(
            onPressed: _loadData,
            child: Text(
              l10n.retryButton,
              style: const TextStyle(color: AppColors.accent),
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

  Widget _buildTopBar(AttractionAdaptive a, AppLocalizations l10n) {
    return Container(
      height: a.scale(74, minFactor: 0.9),
      padding: EdgeInsets.fromLTRB(
        a.scale(28, minFactor: 0.78),
        a.scale(14),
        a.scale(28, minFactor: 0.78),
        a.scale(14),
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF211609),
        border: Border(bottom: BorderSide(color: Color(0xFF332416))),
      ),
      child: Row(
        children: [
          _circleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            background: Colors.transparent,
            size: a.scale(42),
            iconSize: a.scale(20),
            tooltip: l10n.attractionBackTooltip,
            onTap: _onBack,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: a.scale(8)),
              child: Text(
                l10n.attractionDetailsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
            color: AppColors.accent,
            background: AppColors.accent.withValues(alpha: 0.12),
            size: a.scale(42),
            iconSize: a.scale(20),
            tooltip: l10n.attractionNotificationsTooltip,
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
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
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

  Widget _buildHero(AttractionAdaptive a, AppLocalizations l10n) {
    final attraction = _attraction!;
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.top - mq.padding.bottom;
    final heroHeight = (available * 0.42).clamp(240.0, 360.0);
    final media = attraction.media.isNotEmpty
        ? (List<AttractionMediaVm>.from(attraction.media)
            ..sort((x, y) => x.position.compareTo(y.position)))
        : <AttractionMediaVm>[];

    final padX = a.scale(28);
    final locationLabel = _resolvedLocationLabel(attraction);

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
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF211609).withValues(alpha: 0.96),
                    ],
                    stops: const [0.42, 1.0],
                  ),
                ),
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
                  if (attraction.rating >= 4.0) ...[
                    Container(
                      height: a.scale(27, minFactor: 0.9),
                      padding: EdgeInsets.symmetric(horizontal: a.scale(13)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.attractionMustVisitBadge.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
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
                    attraction.title,
                    style: TextStyle(
                      color: Colors.white,
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
                        color: AppColors.accent,
                        size: a.scale(14),
                      ),
                      SizedBox(width: a.scale(6)),
                      Expanded(
                        child: Text(
                          locationLabel.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFFD8C2AD),
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
    required List<AttractionMediaVm> media,
    required int index,
    required double logicalWidth,
  }) {
    final imageTargetWidth = attractionImageTargetWidth(
      context,
      logicalWidth,
      minWidth: 900,
      maxWidth: 1600,
    );
    final url = resolveAttractionMediaUrl(media[index]);
    if (url == null) {
      return _heroPlaceholder();
    }

    return GestureDetector(
      onTap: () => _openImageGallery(media, index),
      behavior: HitTestBehavior.opaque,
      child: Image.network(
        url,
        headers: attractionImageRequestHeaders(url),
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
        errorBuilder: (_, __, ___) => _heroPlaceholder(),
      ),
    );
  }

  Widget _buildImageIndicator(int count, AttractionAdaptive a) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: a.scale(3)),
          width: _currentImageIndex == i ? a.scale(18) : a.scale(6),
          height: a.scale(6),
          decoration: BoxDecoration(
            color: _currentImageIndex == i
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          color: AppColors.textCaption,
          size: 64,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content below hero
  // ---------------------------------------------------------------------------

  Widget _buildContent(AttractionAdaptive a, AppLocalizations l10n) {
    final attraction = _attraction!;
    final padX = a.scale(28);
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        padX,
        a.scale(24, minFactor: 0.72),
        padX,
        mq.padding.bottom + a.scale(110),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(attraction, a, l10n),
          SizedBox(height: a.scale(18, minFactor: 0.72)),
          _buildLocationBlock(attraction, a, l10n),
          SizedBox(height: a.scale(46, minFactor: 0.72)),
          _buildExperience(attraction, a, l10n),
          SizedBox(height: a.scale(56)),
          _buildVisitPlan(attraction, a, l10n),
          SizedBox(height: a.scale(56)),
          _buildReviews(a, l10n),
        ],
      ),
    );
  }

  Widget _buildLocationBlock(
    AttractionVm v,
    AttractionAdaptive a,
    AppLocalizations l10n,
  ) {
    final locationLabel = _resolvedLocationLabel(v);
    final radius = BorderRadius.circular(a.radius(16));

    return Semantics(
      button: true,
      label: l10n.attractionMapLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openMap,
          borderRadius: radius,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: a.scale(14),
              vertical: a.scale(13, minFactor: 0.84),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF332416),
              borderRadius: radius,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: a.scale(42, minFactor: 0.84),
                  height: a.scale(42, minFactor: 0.84),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
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
                        style: TextStyle(
                          color: AppColors.textPrimary,
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
                        l10n.attractionMapLink,
                        style: TextStyle(
                          color: const Color(0xFFD8C2AD),
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
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    color: Colors.white,
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

  Widget _buildStats(
    AttractionVm v,
    AttractionAdaptive a,
    AppLocalizations l10n,
  ) {
    final duration = formatAttractionDurationLabel(l10n, v);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A1A),
        borderRadius: BorderRadius.circular(a.radius(18)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(a.radius(15)),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _statCell(
                  icon: Icons.star_rounded,
                  value: v.rating.toStringAsFixed(1),
                  label: l10n.attractionStatRating,
                  a: a,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _statCell(
                  icon: Icons.schedule_rounded,
                  value: duration.isNotEmpty ? duration : '—',
                  label: l10n.attractionStatDuration,
                  a: a,
                ),
              ),
              _statDivider(),
              Expanded(
                child: _statCell(
                  icon: Icons.confirmation_number_outlined,
                  value: _formatDetailsPriceLabel(context, l10n, v),
                  label: l10n.attractionStatPrice,
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
    return Container(width: 4, color: Colors.white.withValues(alpha: 0.035));
  }

  String _formatDetailsPriceLabel(
    BuildContext context,
    AppLocalizations l10n,
    AttractionVm attraction,
  ) {
    if (attraction.priceAmount == null) {
      return l10n.attractionPriceVariesShort;
    }
    return formatAttractionPriceLabel(context, l10n, attraction);
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String label,
    required AttractionAdaptive a,
  }) {
    return Container(
      color: const Color(0xFF332416),
      constraints: BoxConstraints(minHeight: a.scale(94, minFactor: 0.86)),
      padding: EdgeInsets.symmetric(
        horizontal: a.scale(8),
        vertical: a.scale(19),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: a.scale(22)),
          SizedBox(height: a.scale(7)),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
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
            style: TextStyle(
              color: const Color(0xFFD8C2AD),
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

  Widget _buildExperience(
    AttractionVm v,
    AttractionAdaptive a,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(l10n.attractionExperienceSection, a),
        SizedBox(height: a.scale(16)),
        Text(
          v.description,
          style: TextStyle(
            color: const Color(0xFFE6CDB8),
            fontSize: a.scale(18, minFactor: 0.86),
            fontWeight: FontWeight.w500,
            height: 1.47,
            letterSpacing: -0.45,
          ),
        ),
      ],
    );
  }

  Widget _eyebrow(String text, AttractionAdaptive a) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.accent,
        fontSize: a.scale(11),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Visit plan (practical, localized, data-driven)
  // ---------------------------------------------------------------------------

  Widget _buildVisitPlan(
    AttractionVm v,
    AttractionAdaptive a,
    AppLocalizations l10n,
  ) {
    final items = _visitPlanItems(context, v, l10n);
    final tip = _localizedFlyFyTip(context, v, l10n);
    final summary = _visitPlanSummary(items);
    final radius = BorderRadius.circular(a.radius(16));

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.05),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF332416),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ExpansionTile(
            key: PageStorageKey<String>('attraction-visit-plan-${v.id}'),
            initiallyExpanded: false,
            maintainState: true,
            tilePadding: EdgeInsets.fromLTRB(
              a.scale(14),
              a.scale(5, minFactor: 0.7),
              a.scale(10),
              a.scale(5, minFactor: 0.7),
            ),
            childrenPadding: EdgeInsets.fromLTRB(
              a.scale(14),
              0,
              a.scale(14),
              a.scale(14, minFactor: 0.72),
            ),
            iconColor: AppColors.accent,
            collapsedIconColor: AppColors.accent,
            textColor: AppColors.textPrimary,
            collapsedTextColor: AppColors.textPrimary,
            backgroundColor: const Color(0xFF332416),
            collapsedBackgroundColor: const Color(0xFF332416),
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            leading: Container(
              width: a.scale(34, minFactor: 0.78),
              height: a.scale(34, minFactor: 0.78),
              decoration: const BoxDecoration(
                color: Color(0xFF5A350B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: AppColors.accent,
                size: a.scale(17, minFactor: 0.8),
              ),
            ),
            title: Text(
              l10n.attractionVisitPlanSection,
              style: TextStyle(
                color: AppColors.textPrimary,
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
                    padding: EdgeInsets.only(top: a.scale(2)),
                    child: Text(
                      summary,
                      style: TextStyle(
                        color: const Color(0xFFA9917B),
                        fontSize: a.scale(11, minFactor: 0.82),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            children: [
              _FlyFyTipCard(tip: tip, l10n: l10n, adaptive: a),
              SizedBox(height: a.scale(8, minFactor: 0.72)),
              for (var i = 0; i < items.length; i++) ...[
                _VisitPlanRow(item: items[i], adaptive: a),
                if (i < items.length - 1)
                  Divider(
                    height: a.scale(1),
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reviews section (orange eyebrow + Reviews title + Add review inline)
  // ---------------------------------------------------------------------------

  Widget _buildReviews(AttractionAdaptive a, AppLocalizations l10n) {
    final excursionReviews = context
        .watch<ExcursionProvider>()
        .excursionReviewsForLandmark(widget.attractionId);
    final hasAnyReviews = _reviews.isNotEmpty || excursionReviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(l10n.attractionReviewsSection, a),
        SizedBox(height: a.scale(14)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.attractionReviewsTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
                      foregroundColor: AppColors.accent,
                      padding: EdgeInsets.symmetric(horizontal: a.scale(8)),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.attractionSeeAllReviews(_reviewTotal),
                      style: TextStyle(
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
        SizedBox(height: a.scale(20)),
        if (!hasAnyReviews)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _shouldShowReviewAction ? _openReviewSheet : null,
              borderRadius: BorderRadius.circular(a.radius(14)),
              child: Ink(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: a.scale(28)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(a.radius(14)),
                ),
                child: Center(
                  child: Text(
                    l10n.attractionNoReviews,
                    style: const TextStyle(
                      color: AppColors.textCaption,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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
                _ExcursionAttractionReviewCard(
                  review: excursionReviews[i],
                  l10n: l10n,
                  adaptive: a,
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
  // Bottom CTA — always visible "Find excursions →"
  // ---------------------------------------------------------------------------

  Widget _buildBottomCta(AttractionAdaptive a, AppLocalizations l10n) {
    if (_attraction == null) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final padX = a.scale(28);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          padX,
          a.scale(20),
          padX,
          mq.padding.bottom + a.scale(20),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF211609).withValues(alpha: 0.0),
              const Color(0xFF211609),
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shadowColor: AppColors.accent.withValues(alpha: 0.22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(a.radius(15)),
              ),
              minimumSize: Size.fromHeight(a.scale(55)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.attractionFindExcursions.toUpperCase(),
                  style: TextStyle(
                    fontSize: a.scale(13),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(width: a.scale(12)),
                Icon(Icons.arrow_forward_rounded, size: a.scale(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttractionImageGallery extends StatefulWidget {
  const _AttractionImageGallery({
    required this.media,
    required this.initialIndex,
  }) : assert(media.length > 0);

  final List<AttractionMediaVm> media;
  final int initialIndex;

  @override
  State<_AttractionImageGallery> createState() =>
      _AttractionImageGalleryState();
}

class _AttractionImageGalleryState extends State<_AttractionImageGallery> {
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
        backgroundColor: Colors.black,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.media.length}',
                        style: const TextStyle(
                          color: Colors.white,
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

  Widget _buildGalleryPage(BuildContext context, AttractionMediaVm media) {
    final mq = MediaQuery.of(context);
    final imageTargetWidth = attractionImageTargetWidth(
      context,
      mq.size.width,
      minWidth: 900,
      maxWidth: 2200,
    );
    final url = resolveAttractionMediaUrl(media);
    if (url == null) {
      return const _GalleryPlaceholder();
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(
        child: Image.network(
          url,
          headers: attractionImageRequestHeaders(url),
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
          errorBuilder: (_, __, ___) => const _GalleryPlaceholder(),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.54),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _GalleryLoading extends StatelessWidget {
  const _GalleryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: AppColors.accent,
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
    return const Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: AppColors.textCaption,
        size: 54,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visit plan cards and copy
// ---------------------------------------------------------------------------

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
  final AttractionAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = adaptive.scale(30, minFactor: 0.78);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: adaptive.scale(9)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: const BoxDecoration(
              color: Color(0xFF5A350B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: AppColors.accent,
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                  style: TextStyle(
                    color: const Color(0xFFA9917B),
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

class _FlyFyTipCard extends StatelessWidget {
  const _FlyFyTipCard({
    required this.tip,
    required this.l10n,
    required this.adaptive,
  });

  final String tip;
  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        adaptive.scale(12),
        adaptive.scale(11),
        adaptive.scale(12),
        adaptive.scale(11),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2B1C),
        borderRadius: BorderRadius.circular(adaptive.radius(13)),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: adaptive.scale(32, minFactor: 0.8),
            height: adaptive.scale(32, minFactor: 0.8),
            decoration: const BoxDecoration(
              color: Color(0xFF5A350B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.accent,
              size: adaptive.scale(16, minFactor: 0.82),
            ),
          ),
          SizedBox(width: adaptive.scale(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attractionFlyFyTipTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: adaptive.scale(12.5, minFactor: 0.84),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),
                SizedBox(height: adaptive.scale(3, minFactor: 0.72)),
                Text(
                  tip,
                  style: TextStyle(
                    color: const Color(0xFFD7BFAA),
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

List<_VisitPlanItem> _visitPlanItems(
  BuildContext context,
  AttractionVm attraction,
  AppLocalizations l10n,
) {
  final duration = formatAttractionDurationLabel(l10n, attraction);
  final ticket = attraction.priceAmount == null
      ? l10n.attractionVisitFreeEntry
      : formatAttractionPriceLabel(context, l10n, attraction);
  final bookingSuffix = attraction.visitInfo.bookingRequired == true
      ? ' · ${l10n.attractionVisitBookingRecommended}'
      : '';
  final goodFor = _audienceLabels(attraction, l10n);
  final safety = _safetyLabels(attraction.visitInfo.safetyNotes, l10n);

  return [
    _VisitPlanItem(
      icon: Icons.schedule_rounded,
      label: l10n.attractionVisitDurationLabel,
      value: duration.isNotEmpty
          ? duration
          : l10n.attractionVisitDurationFlexible,
    ),
    _VisitPlanItem(
      icon: Icons.confirmation_number_outlined,
      label: l10n.attractionVisitTicketsLabel,
      value: '$ticket$bookingSuffix',
    ),
    _VisitPlanItem(
      icon: Icons.wb_twilight_rounded,
      label: l10n.attractionVisitBestTimeLabel,
      value: _bestTimeLabel(attraction, l10n),
    ),
    _VisitPlanItem(
      icon: Icons.groups_rounded,
      label: l10n.attractionVisitGoodForLabel,
      value: goodFor.isEmpty
          ? l10n.attractionTagUniqueSubtitle
          : goodFor.join(' · '),
    ),
    _VisitPlanItem(
      icon: Icons.accessible_rounded,
      label: l10n.attractionVisitAccessLabel,
      value: _accessibilityLabel(attraction.visitInfo.accessibility, l10n),
    ),
    if (safety.isNotEmpty)
      _VisitPlanItem(
        icon: Icons.health_and_safety_rounded,
        label: l10n.attractionVisitSafetyLabel,
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

String _localizedFlyFyTip(
  BuildContext context,
  AttractionVm attraction,
  AppLocalizations l10n,
) {
  final locale = Localizations.localeOf(context).languageCode.toLowerCase();
  final tips = attraction.visitInfo.localizedTips;
  final localized = tips[locale] ?? tips[attraction.locale] ?? tips['en'];
  if ((localized ?? '').trim().isNotEmpty) {
    return localized!.trim();
  }

  final category = attraction.category.toUpperCase();
  final isLongRoute =
      attraction.durationUnit?.toUpperCase() == 'DAYS' ||
      (attraction.durationValue ?? 0) >= 6;
  if (_isNatureLikeCategory(category) || isLongRoute) {
    return l10n.attractionVisitTipNature;
  }
  if (_isCultureLikeCategory(category)) {
    return l10n.attractionVisitTipCulture;
  }
  return l10n.attractionVisitTipDefault;
}

String _bestTimeLabel(AttractionVm attraction, AppLocalizations l10n) {
  final code = _code(attraction.visitInfo.bestTime);
  switch (code.isEmpty ? _fallbackBestTimeCode(attraction) : code) {
    case 'EARLY_MORNING':
      return l10n.attractionVisitBestTimeEarlyMorning;
    case 'MORNING':
      return l10n.attractionVisitBestTimeMorning;
    case 'AFTERNOON':
      return l10n.attractionVisitBestTimeAfternoon;
    case 'SUNSET':
      return l10n.attractionVisitBestTimeSunset;
    default:
      return l10n.attractionVisitBestTimeAnytime;
  }
}

String _fallbackBestTimeCode(AttractionVm attraction) {
  final category = attraction.category.toUpperCase();
  if (_isNatureLikeCategory(category)) return 'EARLY_MORNING';
  if (_isCultureLikeCategory(category)) return 'MORNING';
  return 'AFTERNOON';
}

String _accessibilityLabel(String? raw, AppLocalizations l10n) {
  switch (_code(raw)) {
    case 'GOOD':
      return l10n.attractionVisitAccessGood;
    case 'LIMITED':
      return l10n.attractionVisitAccessLimited;
    default:
      return l10n.attractionVisitAccessUnknown;
  }
}

List<String> _audienceLabels(AttractionVm attraction, AppLocalizations l10n) {
  final codes = <String>{
    ...attraction.visitInfo.audience.map(_code),
    ..._recognizedAudienceCodesFromTags(attraction.tags),
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
      return l10n.attractionTagFamilyLabel;
    case 'COUPLES':
      return l10n.attractionVisitAudienceCouples;
    case 'PHOTO':
      return l10n.attractionTagPhotoLabel;
    case 'OUTDOOR':
      return l10n.attractionTagOutdoorLabel;
    case 'HISTORY':
      return l10n.attractionTagHistoryLabel;
    case 'ADVENTURE':
      return l10n.attractionTagAdventureLabel;
    case 'WELLNESS':
      return l10n.attractionVisitAudienceWellness;
    default:
      return l10n.attractionTagUniqueSubtitle;
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
        result.add(l10n.attractionVisitSafetyCheckWeather);
      case 'BRING_WATER':
        result.add(l10n.attractionVisitSafetyBringWater);
      case 'CHECK_HOURS':
        result.add(l10n.attractionVisitSafetyCheckHours);
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

  final AttractionReviewVm review;
  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = review.author.avatarFileId != null
        ? resolvePublicFileContentUrl(review.author.avatarFileId!)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B2B1C),
        borderRadius: BorderRadius.circular(adaptive.radius(15)),
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
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
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
                      backgroundColor: const Color(0xFF245163),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Icon(
                              Icons.person_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
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
                            review.author.displayName ??
                                l10n.attractionTravelerFallback,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: adaptive.scale(14),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: adaptive.scale(3)),
                          Text(
                            l10n.attractionVerifiedNomad.toUpperCase(),
                            style: TextStyle(
                              color: const Color(0xFFD8C2AD),
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
                    _buildStars(review.rating, adaptive),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  SizedBox(height: adaptive.scale(16)),
                  SizedBox(height: adaptive.scale(4)),
                  Text(
                    '"${review.comment}"',
                    style: TextStyle(
                      color: const Color(0xFFD7BFAA),
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

  Widget _buildMediaStrip(List<AttractionMediaVm> media, AttractionAdaptive a) {
    final sorted = List<AttractionMediaVm>.from(media)
      ..sort((x, y) => x.position.compareTo(y.position));
    return SizedBox(
      height: a.scale(82),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sorted.length,
        separatorBuilder: (_, __) => SizedBox(width: a.scale(8)),
        itemBuilder: (context, index) =>
            _buildMediaTile(context, sorted[index], a),
      ),
    );
  }

  Widget _buildMediaTile(
    BuildContext context,
    AttractionMediaVm media,
    AttractionAdaptive a,
  ) {
    final imageTargetWidth = attractionImageTargetWidth(
      context,
      a.scale(96),
      minWidth: 220,
      maxWidth: 360,
    );
    final url = resolveAttractionMediaUrl(media);
    final isVideo = media.mediaType.toUpperCase() == 'VIDEO';

    return ClipRRect(
      borderRadius: BorderRadius.circular(a.radius(10)),
      child: Container(
        width: a.scale(96),
        height: a.scale(82),
        color: Colors.white.withValues(alpha: 0.07),
        child: isVideo
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.35)),
                  Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.accent,
                      size: a.scale(32),
                    ),
                  ),
                ],
              )
            : (url == null
                  ? Icon(
                      Icons.image_rounded,
                      color: AppColors.textCaption,
                      size: a.scale(28),
                    )
                  : Image.network(
                      url,
                      headers: attractionImageRequestHeaders(url),
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
                          color: AppColors.textCaption,
                          size: a.scale(28),
                        );
                      },
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_rounded,
                        color: AppColors.textCaption,
                        size: a.scale(28),
                      ),
                    )),
      ),
    );
  }

  Widget _buildStars(double rating, AttractionAdaptive a) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return Icon(
            Icons.star_rounded,
            color: AppColors.accent,
            size: a.scale(13),
          );
        }
        if (i == fullStars && hasHalf) {
          return Icon(
            Icons.star_half_rounded,
            color: AppColors.accent,
            size: a.scale(13),
          );
        }
        return Icon(
          Icons.star_border_rounded,
          color: AppColors.accent.withValues(alpha: 0.4),
          size: a.scale(13),
        );
      }),
    );
  }
}

class _ExcursionAttractionReviewCard extends StatelessWidget {
  const _ExcursionAttractionReviewCard({
    required this.review,
    required this.l10n,
    required this.adaptive,
  });

  final ExcursionReviewVm review;
  final AppLocalizations l10n;
  final AttractionAdaptive adaptive;

  @override
  Widget build(BuildContext context) {
    final guideName = review.guideDisplayName.trim().isEmpty
        ? l10n.myExcursionsGuideFallback
        : review.guideDisplayName.trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B2B1C),
        borderRadius: BorderRadius.circular(adaptive.radius(15)),
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
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
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
                      padding: EdgeInsets.symmetric(
                        horizontal: adaptive.scale(10),
                        vertical: adaptive.scale(6),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        l10n.excursionReviewSourceAttractionBadge,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: adaptive.scale(10),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    _buildExcursionStars(review.rating, adaptive),
                  ],
                ),
                SizedBox(height: adaptive.scale(12)),
                Text(
                  l10n.excursionReviewViaGuide(guideName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: adaptive.scale(14),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: adaptive.scale(12)),
                Text(
                  '"${review.comment}"',
                  style: TextStyle(
                    color: const Color(0xFFD7BFAA),
                    fontSize: adaptive.scale(14),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                  maxLines: 5,
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

Widget _buildExcursionStars(double rating, AttractionAdaptive adaptive) {
  final fullStars = rating.floor();
  final hasHalf = (rating - fullStars) >= 0.5;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      if (index < fullStars) {
        return Icon(
          Icons.star_rounded,
          color: AppColors.accent,
          size: adaptive.scale(13),
        );
      }
      if (index == fullStars && hasHalf) {
        return Icon(
          Icons.star_half_rounded,
          color: AppColors.accent,
          size: adaptive.scale(13),
        );
      }
      return Icon(
        Icons.star_border_rounded,
        color: AppColors.accent.withValues(alpha: 0.4),
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
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
          decoration: const BoxDecoration(
            color: Color(0xFF241509),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.l10n.attractionReviewSheetTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
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
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.l10n.attractionReviewRatingLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.l10n.attractionReviewCommentLabel,
                    hintText: widget.l10n.attractionReviewCommentHint,
                    errorText: _errorText,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    counterStyle: const TextStyle(
                      color: AppColors.textCaption,
                      fontSize: 11,
                    ),
                    labelStyle: const TextStyle(color: AppColors.textCaption),
                    hintStyle: const TextStyle(color: AppColors.textCaption),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMediaActions(),
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
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: Colors.black,
                      disabledForegroundColor: AppColors.textCaption,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textCaption,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  widget.l10n.attractionReviewSubmitting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            widget.l10n.attractionReviewSubmit,
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
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 42, height: 42),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected ? AppColors.accent : AppColors.textCaption,
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
          icon: const Icon(Icons.photo_camera_rounded, size: 18),
          label: Text(
            widget.l10n.attractionReviewAddPhoto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: _mediaButtonStyle(),
        );
        final videoButton = OutlinedButton.icon(
          onPressed: _submitting ? null : _pickVideo,
          icon: const Icon(Icons.videocam_rounded, size: 18),
          label: Text(
            widget.l10n.attractionReviewAddVideo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: _mediaButtonStyle(),
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

  ButtonStyle _mediaButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.accent,
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildDraftMediaStrip() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _media[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 104,
                  height: 88,
                  color: Colors.white.withValues(alpha: 0.07),
                  child: item.isPhoto
                      ? Image.memory(
                          item.bytes,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: AppColors.accent,
                              size: 34,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                widget.l10n.attractionReviewVideoPreview,
                                style: const TextStyle(
                                  color: AppColors.textCaption,
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
                  message: widget.l10n.attractionReviewRemoveMedia,
                  child: InkWell(
                    onTap: _submitting
                        ? null
                        : () => setState(() => _media.removeAt(index)),
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
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
        _showError(widget.l10n.attractionReviewPickFailed);
        return;
      }
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        _showError(widget.l10n.attractionReviewMediaTooLarge);
        return;
      }

      final contentType =
          _detectImageContentType(bytes) ?? _contentTypeFromName(picked.name);
      if (contentType == null || !_isAllowedPhotoContentType(contentType)) {
        _showError(widget.l10n.attractionReviewUnsupportedFormat);
        return;
      }

      setState(() {
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
        _showError(widget.l10n.attractionReviewPickFailed);
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
        _showError(widget.l10n.attractionReviewPickFailed);
        return;
      }
      if (bytes.lengthInBytes > _maxVideoBytes) {
        _showError(widget.l10n.attractionReviewMediaTooLarge);
        return;
      }

      final contentType = picked.mimeType ?? _contentTypeFromName(picked.name);
      if (contentType == null || !_isAllowedVideoContentType(contentType)) {
        _showError(widget.l10n.attractionReviewUnsupportedFormat);
        return;
      }

      setState(() {
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
        _showError(widget.l10n.attractionReviewPickFailed);
      }
    }
  }

  bool _ensureMediaSlot() {
    if (_media.length < _maxReviewMediaItems) {
      return true;
    }
    _showError(widget.l10n.attractionReviewMediaLimit(_maxReviewMediaItems));
    return false;
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _errorText = widget.l10n.attractionReviewCommentRequired);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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

    return '${safeBase.isEmpty ? 'attraction-review-media' : safeBase}.$extension';
  }
}
