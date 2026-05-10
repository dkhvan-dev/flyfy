import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/file_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_view.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/tours/models/tour_vm.dart';
import '../../features/tours/tour_cover_url.dart';
import '../../features/tours/tour_localization.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/tour_provider.dart';

class TourDetailsScreen extends StatefulWidget {
  const TourDetailsScreen({
    super.key,
    required this.tourId,
    this.initialTour,
  });

  final String tourId;
  final TourVm? initialTour;

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  final ProfileApi _profileApi = ProfileApi();
  Map<String, UserProfileVm> _resolvedProfiles = const {};
  String? _resolvingGuideUserId;

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

  Future<void> _retry() {
    return context.read<TourProvider>().loadTourDetails(
          widget.tourId,
          initialTour: widget.initialTour,
        );
  }

  void _showSoon(String message) {
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

  void _scheduleResolveGuideProfile(
    String guideUserId,
    UserProfileVm? currentProfile,
    bool canFetch,
  ) {
    if (guideUserId.isEmpty) {
      return;
    }

    final currentUserId = (currentProfile?.userId ?? '').trim();
    if (currentUserId == guideUserId) {
      return;
    }

    if (!canFetch ||
        _resolvedProfiles.containsKey(guideUserId) ||
        _resolvingGuideUserId == guideUserId) {
      return;
    }

    _resolvingGuideUserId = guideUserId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveGuideProfile(guideUserId);
    });
  }

  Future<void> _resolveGuideProfile(String guideUserId) async {
    try {
      final profile = await _profileApi.getUserById(guideUserId);
      if (!mounted) return;
      setState(() {
        _resolvedProfiles = {
          ..._resolvedProfiles,
          guideUserId: profile,
        };
        _resolvingGuideUserId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingGuideUserId = null);
    }
  }

  void _openGuideProfile(String guideUserId, {required bool isAuthor}) {
    final l10n = AppLocalizations.of(context)!;
    if (isAuthor) {
      context.push('/profile');
      return;
    }
    if (guideUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileNotAvailable)),
      );
      return;
    }
    context.push('/users/$guideUserId/profile',
        extra: _resolvedProfiles[guideUserId]);
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

          final guideUserId = (tour.guideUserId ?? '').trim();
          final currentUserId = (session.profile?.userId ?? '').trim();
          final isAuthor =
              guideUserId.isNotEmpty && currentUserId == guideUserId;
          _scheduleResolveGuideProfile(
            guideUserId,
            session.profile,
            session.isAuthenticated,
          );
          final guideProfile =
              isAuthor ? session.profile : _resolvedProfiles[guideUserId];
          final guideName = _resolveTourGuideName(
            guideUserId,
            guideProfile,
            l10n,
          );
          final guideAvatarUrl = _resolveTourGuideAvatarUrl(guideProfile);

          return TourDetailsContent(
            tour: tour,
            guideName: guideName,
            guideAvatarUrl: guideAvatarUrl,
            guideAvatarFallbackText: _displayInitials(guideName),
            showMessageGuide: !isAuthor,
            showBookingAction: !isAuthor,
            onBackTap: _goBack,
            onNotificationsTap: () => context.push('/notifications'),
            onGuideProfileTap: () =>
                _openGuideProfile(guideUserId, isAuthor: isAuthor),
            onBookTap: () => _showSoon(l10n.tourDetailsBookingComingSoon),
            onMessageGuideTap: () =>
                _showSoon(l10n.tourDetailsGuideChatComingSoon),
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
    required this.onBookTap,
    required this.onMessageGuideTap,
    this.guideName,
    this.guideAvatarUrl,
    this.guideAvatarFallbackText = 'FG',
    this.showMessageGuide = true,
    this.showBookingAction = true,
    this.onGuideProfileTap,
    this.onBackTap,
    this.onNotificationsTap,
  });

  final TourVm tour;
  final VoidCallback onBookTap;
  final VoidCallback onMessageGuideTap;
  final String? guideName;
  final String? guideAvatarUrl;
  final String guideAvatarFallbackText;
  final bool showMessageGuide;
  final bool showBookingAction;
  final VoidCallback? onGuideProfileTap;
  final VoidCallback? onBackTap;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final resolvedGuideName = guideName ?? l10n.tourDetailsGuideName;
    final scrollBottomPadding =
        (showBookingAction ? 116.0 : 24.0) + bottomPadding;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF20150B),
            Color(0xFF1A1209),
            Color(0xFF181006),
          ],
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
                        _TourHero(tour: tour),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TourStatsGrid(tour: tour),
                              const SizedBox(height: 40),
                              _TourExperienceSection(tour: tour),
                              const SizedBox(height: 44),
                              _TourGuideAndMapSection(
                                tour: tour,
                                guideName: resolvedGuideName,
                                guideAvatarUrl: guideAvatarUrl,
                                guideAvatarFallbackText:
                                    guideAvatarFallbackText,
                                showMessageGuide: showMessageGuide,
                                onGuideProfileTap: onGuideProfileTap,
                                onMessageGuideTap: onMessageGuideTap,
                              ),
                              const SizedBox(height: 44),
                              _TourItinerarySection(tour: tour),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showBookingAction)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _TourCheckoutBar(tour: tour, onBookTap: onBookTap),
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
            decoration:
                BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _TourHero extends StatelessWidget {
  const _TourHero({required this.tour});

  final TourVm tour;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveTourCoverUrl(tour)?.trim() ?? '';
    final label = _categoryLabel(context, tour.categorySlug);

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
                        tour.title,
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
                      label: _formatDuration(context, tour.durationMinutes)
                          .toUpperCase(),
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
      ..shader = RadialGradient(
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
              SizedBox(width: itemWidth, child: _TourStatCard(data: card)),
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
  const _TourExperienceSection({required this.tour});

  final TourVm tour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = tour.description.trim().isNotEmpty
        ? tour.description.trim()
        : tour.summary.trim().isNotEmpty
            ? tour.summary.trim()
            : l10n.tourDetailsNoDescription;
    final features = _resolveTourIncludedFeatures(tour);

    return _TourSection(
      title: l10n.tourDetailsExperience,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFC6B6A7),
              fontSize: 16,
              height: 1.58,
              letterSpacing: 0,
            ),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 25),
            Text(
              l10n.tourDetailsWhatToExpect.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                for (var index = 0; index < features.length; index++) ...[
                  _TourFeatureCard(feature: features[index]),
                  if (index != features.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
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
  const _TourIncludedFeature({
    required this.type,
    required this.label,
  });

  final _TourIncludedFeatureType type;
  final String label;
}

List<_TourIncludedFeature> _resolveTourIncludedFeatures(TourVm tour) {
  final source = tour.includedItems.isNotEmpty ? tour.includedItems : tour.tags;
  return source
      .map(_parseTourIncludedFeature)
      .where((feature) => feature.label.isNotEmpty)
      .toList(growable: false);
}

_TourIncludedFeature _parseTourIncludedFeature(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return const _TourIncludedFeature(
      type: _TourIncludedFeatureType.other,
      label: '',
    );
  }

  final separatorIndex = value.indexOf(':');
  if (separatorIndex > 0) {
    final prefix = value.substring(0, separatorIndex).trim().toLowerCase();
    final label = value.substring(separatorIndex + 1).trim();
    final type = _includedFeatureTypeFromPrefix(prefix);
    if (type != null && label.isNotEmpty) {
      return _TourIncludedFeature(type: type, label: label);
    }
  }

  return _TourIncludedFeature(
    type: _guessIncludedFeatureType(value),
    label: value,
  );
}

_TourIncludedFeatureType? _includedFeatureTypeFromPrefix(String prefix) {
  return switch (prefix) {
    'transport' => _TourIncludedFeatureType.transport,
    'food' || 'meal' || 'meals' => _TourIncludedFeatureType.food,
    'tickets' || 'ticket' => _TourIncludedFeatureType.tickets,
    'equipment' || 'gear' => _TourIncludedFeatureType.equipment,
    'guide' => _TourIncludedFeatureType.guide,
    'photo' || 'photos' => _TourIncludedFeatureType.photo,
    'other' => _TourIncludedFeatureType.other,
    _ => null,
  };
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

class _TourGuideAndMapSection extends StatelessWidget {
  const _TourGuideAndMapSection({
    required this.tour,
    required this.guideName,
    required this.guideAvatarFallbackText,
    required this.showMessageGuide,
    required this.onMessageGuideTap,
    this.guideAvatarUrl,
    this.onGuideProfileTap,
  });

  final TourVm tour;
  final String guideName;
  final String? guideAvatarUrl;
  final String guideAvatarFallbackText;
  final bool showMessageGuide;
  final VoidCallback onMessageGuideTap;
  final VoidCallback? onGuideProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guideHeader = Row(
      children: [
        _GuideAvatar(
          imageUrl: guideAvatarUrl,
          fallbackText: guideAvatarFallbackText,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guideName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tourDetailsGuideSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onGuideProfileTap != null) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFCAB9A5),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF312316),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tourDetailsLeadGuide.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFCAB9A5),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onGuideProfileTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: guideHeader,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '"${l10n.tourDetailsGuideQuote}"',
                style: const TextStyle(
                  color: Color(0xFFC1B2A2),
                  fontSize: 14,
                  height: 1.38,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (showMessageGuide) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: onMessageGuideTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    l10n.tourDetailsMessageGuide,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        _TourMapPreview(tour: tour),
      ],
    );
  }
}

class _GuideAvatar extends StatelessWidget {
  const _GuideAvatar({
    required this.fallbackText,
    this.imageUrl,
  });

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
            color: AppColors.accent.withValues(alpha: 0.15), width: 2),
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
    final label = tour.meetingPoint.trim().isNotEmpty
        ? tour.meetingPoint.trim()
        : tour.cityName?.trim().isNotEmpty == true
            ? tour.cityName!.trim()
            : l10n.tourDetailsMapPreview;

    return Container(
      height: 154,
      decoration: BoxDecoration(
        color: const Color(0xFF40372F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: const _MapPreviewPainter())),
          Center(
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.28),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child:
                      const Icon(Icons.circle, color: Colors.white, size: 10),
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
                  color: const Color(0xFF160F0A).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = -size.width; x < size.width * 2; x += 43) {
      canvas.drawLine(Offset(x.toDouble(), 0),
          Offset(x + size.height, size.height), linePaint);
    }
    for (var y = -size.height; y < size.height * 2; y += 34) {
      canvas.drawLine(Offset(0, y.toDouble()),
          Offset(size.width, y - size.width * 0.3), linePaint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.18),
          AppColors.accent.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TourItinerarySection extends StatelessWidget {
  const _TourItinerarySection({required this.tour});

  final TourVm tour;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  : tour.summary,
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
                  isFirst: index == 0,
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
    required this.isFirst,
  });

  final TourItineraryItemVm step;
  final int index;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
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
                step.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.description,
                style: const TextStyle(
                  color: Color(0xFFBAAB9D),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
    required this.onBookTap,
  });

  final TourVm tour;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E140B).withValues(alpha: 0.97),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 13, 14, math.max(13, safeBottom)),
          child: Row(
            children: [
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
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBookTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  label: Text(
                    l10n.tourDetailsBook,
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
      child: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
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

String _formatLanguageLabels(
  AppLocalizations l10n,
  List<String> languageCodes,
) {
  return formatLocalizedTourLanguages(l10n, languageCodes);
}

String _resolveTourGuideName(
  String guideUserId,
  UserProfileVm? profile,
  AppLocalizations l10n,
) {
  if (profile != null && profile.userId == guideUserId) {
    return profile.preferredName;
  }
  return l10n.tourDetailsGuideName;
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
