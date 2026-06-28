import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/generated/app_localizations.dart';
import 'models/post_vm.dart';
import 'models/story_vm.dart';

class StoryAdaptive {
  StoryAdaptive._({
    required this.size,
    required this.width,
    required this.height,
    required this.shortestSide,
    required this.textScaleFactor,
  });

  final Size size;
  final double width;
  final double height;
  final double shortestSide;
  final double textScaleFactor;

  factory StoryAdaptive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler;
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final textScaleFactor =
        textScaler.scale(baseStyle?.fontSize ?? 14) /
        (baseStyle?.fontSize ?? 14);

    return StoryAdaptive._(
      size: mq.size,
      width: mq.size.width,
      height: mq.size.height,
      shortestSide: mq.size.shortestSide,
      textScaleFactor: textScaleFactor.clamp(1.0, 1.4),
    );
  }

  bool get isNarrow => width < 370;
  bool get isVeryNarrow => width < 342;
  bool get isShort => height < 760;
  bool get isVeryShort => height < 700;

  double scale(
    double value, {
    double minFactor = 0.82,
    double maxFactor = 1.06,
  }) {
    final baseFactor = (shortestSide / 393).clamp(minFactor, maxFactor);
    final textPenalty = textScaleFactor > 1.1
        ? 1 - ((textScaleFactor - 1.1) * 0.12)
        : 1.0;
    final factor = math.max(
      minFactor,
      math.min(maxFactor, baseFactor * textPenalty),
    );
    final tunedFactor = math.max(minFactor, math.min(maxFactor, factor * 0.90));
    return value * tunedFactor;
  }

  double radius(double value) => scale(value, minFactor: 0.84, maxFactor: 1.04);
}

abstract final class StoryPalette {
  static const backgroundTop = AppPalette.warmInk58;
  static const background = AppPalette.background;
  static const backgroundDeep = AppPalette.warmInk01;
  static const surface = AppPalette.warmInk97;
  static const surfaceRaised = AppPalette.warmSurface23;
  static const surfaceCard = AppPalette.warmInk85;
  static const text = AppPalette.textWarm;
  static const textSoft = AppPalette.orangeLight14;
  static const textMuted = AppPalette.warmMuted08;
  static const line = AppPalette.orangeOverlaySoft02;
}

String formatStoryCategory(AppLocalizations l10n, String rawCategory) {
  switch (rawCategory.trim().toUpperCase()) {
    case 'GUIDE':
      return l10n.storyCategoryGuide;
    case 'PHOTO_ESSAY':
      return l10n.storyCategoryPhotoEssay;
    case 'CULINARY':
      return l10n.storyCategoryCulinary;
    case 'JOURNAL':
    default:
      return l10n.storyCategoryJournal;
  }
}

String formatStoryFormat(AppLocalizations l10n, String rawFormat) {
  switch (rawFormat.trim().toUpperCase()) {
    case 'GUIDE':
      return l10n.storyFormatGuide;
    case 'PHOTO_ESSAY':
      return l10n.storyFormatPhotoEssay;
    case 'ARTICLE':
      return l10n.storyFormatArticle;
    case 'CULINARY':
      return l10n.storyFormatCulinary;
    case 'STORY':
    default:
      return l10n.storyFormatStory;
  }
}

String formatStoryDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return '';
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMM yyyy', locale).format(value.toLocal());
}

String formatStoryCountCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return value.toString();
}

enum StoryEntryState { available, seen, expired, pending, hidden }

extension StoryEntryStateX on StoryEntryState {
  bool get disablesEntry {
    return switch (this) {
      StoryEntryState.expired ||
      StoryEntryState.pending ||
      StoryEntryState.hidden => true,
      StoryEntryState.available || StoryEntryState.seen => false,
    };
  }

  String get keySuffix {
    return switch (this) {
      StoryEntryState.available => 'available',
      StoryEntryState.seen => 'seen',
      StoryEntryState.expired => 'expired',
      StoryEntryState.pending => 'pending',
      StoryEntryState.hidden => 'hidden',
    };
  }

  IconData get icon {
    return switch (this) {
      StoryEntryState.available => Icons.auto_stories_outlined,
      StoryEntryState.seen => Icons.check_rounded,
      StoryEntryState.expired => Icons.schedule_rounded,
      StoryEntryState.pending => Icons.hourglass_top_rounded,
      StoryEntryState.hidden => Icons.visibility_off_rounded,
    };
  }

  Color get foreground {
    return switch (this) {
      StoryEntryState.available => StoryPalette.textSoft,
      StoryEntryState.seen => AppPalette.greenInk02,
      StoryEntryState.expired => AppPalette.orangeLight49,
      StoryEntryState.pending => AppPalette.warmInk116,
      StoryEntryState.hidden => AppPalette.redWash02,
    };
  }

  Color background(BuildContext context) {
    return switch (this) {
      StoryEntryState.available => AppPalette.transparent,
      StoryEntryState.seen => AppPalette.success,
      StoryEntryState.expired => AppPalette.black.withValues(alpha: 0.64),
      StoryEntryState.pending => AppPalette.amberSoft09,
      StoryEntryState.hidden => AppPalette.danger.withValues(alpha: 0.88),
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      StoryEntryState.available => '',
      StoryEntryState.seen => l10n.storyStateSeenLabel,
      StoryEntryState.expired => l10n.storyStateExpiredLabel,
      StoryEntryState.pending => l10n.storyStatePendingLabel,
      StoryEntryState.hidden => l10n.storyStateHiddenLabel,
    };
  }
}

StoryEntryState resolveStoryEntryState(StoryVm story) {
  final status = story.status.trim().toUpperCase();
  final moderationStatus = story.moderationStatus.trim().toUpperCase();
  if (_isHiddenStoryState(status) || _isHiddenStoryState(moderationStatus)) {
    return StoryEntryState.hidden;
  }
  if (story.isExpired) {
    return StoryEntryState.expired;
  }
  if (_isPendingStoryState(status) || _isPendingStoryState(moderationStatus)) {
    return StoryEntryState.pending;
  }
  if (story.isSeenByViewer) {
    return StoryEntryState.seen;
  }
  return StoryEntryState.available;
}

StoryEntryState resolvePostEntryState(PostVm post) {
  final status = post.status.trim().toUpperCase();
  final moderationStatus = post.moderationStatus.trim().toUpperCase();
  if (_isHiddenStoryState(status) || _isHiddenStoryState(moderationStatus)) {
    return StoryEntryState.hidden;
  }
  if (_isPendingStoryState(status) || _isPendingStoryState(moderationStatus)) {
    return StoryEntryState.pending;
  }
  if (post.isSeenByViewer) {
    return StoryEntryState.seen;
  }
  return StoryEntryState.available;
}

bool _isHiddenStoryState(String value) {
  return value == 'HIDDEN' ||
      value == 'AUTO_HIDDEN' ||
      value == 'TAKEN_DOWN' ||
      value == 'REMOVED';
}

bool _isPendingStoryState(String value) {
  return value == 'PENDING' ||
      value == 'PENDING_REVIEW' ||
      value == 'IN_REVIEW' ||
      value == 'QUEUED';
}

class StoryStateAffordance extends StatelessWidget {
  const StoryStateAffordance({
    super.key,
    required this.state,
    this.compact = false,
  });

  factory StoryStateAffordance.fromStory(
    StoryVm story, {
    Key? key,
    bool compact = false,
  }) {
    return StoryStateAffordance(
      key: key,
      state: resolveStoryEntryState(story),
      compact: compact,
    );
  }

  factory StoryStateAffordance.fromPost(
    PostVm post, {
    Key? key,
    bool compact = false,
  }) {
    return StoryStateAffordance(
      key: key,
      state: resolvePostEntryState(post),
      compact: compact,
    );
  }

  final StoryEntryState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (state == StoryEntryState.available) {
      return const SizedBox.shrink();
    }

    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;
    final label = state.label(l10n);
    final horizontalPadding = compact ? 8.0 : 10.0;
    final verticalPadding = compact ? 5.0 : 7.0;

    return Semantics(
      label: label,
      container: true,
      child: Container(
        key: ValueKey('story-state-pill-${state.keySuffix}'),
        constraints: BoxConstraints(
          maxWidth: adaptive.scale(compact ? 128 : 180),
        ),
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(horizontalPadding),
          vertical: adaptive.scale(verticalPadding),
        ),
        decoration: AppBoxDecoration(
          color: state.background(context),
          borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
          border: Border.all(color: AppPalette.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.icon,
              color: state.foreground,
              size: adaptive.scale(compact ? 13 : 15),
            ),
            SizedBox(width: adaptive.scale(5)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: state.foreground,
                  fontSize: adaptive.scale(compact ? 11 : 12),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration storyScreenBackground() {
  return const AppBoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        StoryPalette.backgroundTop,
        StoryPalette.background,
        StoryPalette.backgroundDeep,
      ],
      stops: [0, 0.34, 1],
    ),
  );
}

class StoryAvatar extends StatelessWidget {
  const StoryAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 42,
    this.borderColor,
  });

  final String label;
  final String? imageUrl;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppPalette.primary.withValues(alpha: 0.35);
    final normalized = label.trim().isEmpty ? 'F' : label.trim().toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: math.max(1.5, size * 0.06)),
      ),
      child: ClipOval(
        child: imageUrl == null
            ? DecoratedBox(
                decoration: const AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppPalette.orangeWash17, AppPalette.orangeSoft37],
                  ),
                ),
                child: Center(
                  child: Text(
                    normalized,
                    style: AppTextStyle(
                      color: AppPalette.warmSurface26,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
                    decoration: const AppBoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppPalette.orangeWash17,
                          AppPalette.orangeSoft37,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        normalized,
                        style: AppTextStyle(
                          color: AppPalette.warmSurface26,
                          fontSize: size * 0.38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class StorySeenMarker extends StatelessWidget {
  const StorySeenMarker({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.success,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppPalette.background.withValues(alpha: 0.82),
          width: math.max(1.2, size * 0.08),
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          Icons.check_rounded,
          color: AppPalette.greenInk01,
          size: size * 0.72,
        ),
      ),
    );
  }
}

class StoryCoverImage extends StatelessWidget {
  const StoryCoverImage({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return DecoratedBox(
        decoration: AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.primary.withValues(alpha: 0.25),
              AppPalette.warmInk86,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: AppPalette.white.withValues(alpha: 0.72),
            size: StoryAdaptive.of(context).scale(44),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screenWidth;
        final cacheWidth =
            (logicalWidth * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(320, 1600)
                .toInt();

        return Image.network(
          url!,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const _StoryImageLoadingPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            return _StoryVideoCover(url: url!);
          },
        );
      },
    );
  }
}

class _StoryVideoCover extends StatefulWidget {
  const _StoryVideoCover({required this.url});

  final String url;

  @override
  State<_StoryVideoCover> createState() => _StoryVideoCoverState();
}

class _StoryVideoCoverState extends State<_StoryVideoCover> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _StoryVideoCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          if (_controller == controller) {
            _controller = null;
          }
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    if (_failed) {
      return const DecoratedBox(
        decoration: AppBoxDecoration(color: AppPalette.warmInk86),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppPalette.white54,
            size: 34,
          ),
        ),
      );
    }
    return const _StoryImageLoadingPlaceholder();
  }
}

class _StoryImageLoadingPlaceholder extends StatelessWidget {
  const _StoryImageLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const AppBoxDecoration(color: AppPalette.warmInk86),
      child: Center(
        child: SizedBox.square(
          dimension: StoryAdaptive.of(context).scale(26),
          child: CircularProgressIndicator(
            strokeWidth: StoryAdaptive.of(context).scale(2),
            color: AppPalette.primary,
          ),
        ),
      ),
    );
  }
}
