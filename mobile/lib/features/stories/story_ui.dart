import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/ui/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

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
  static const backgroundTop = Color(0xFF1E120A);
  static const background = Color(0xFF120B06);
  static const backgroundDeep = Color(0xFF0D0602);
  static const surface = Color(0xFF24160C);
  static const surfaceRaised = Color(0xFF2B190D);
  static const surfaceCard = Color(0xFF22140B);
  static const text = Color(0xFFFFF7EF);
  static const textSoft = Color(0xFFD8C6B4);
  static const textMuted = Color(0xFF8F7A66);
  static const line = Color(0x1FFFA833);
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

BoxDecoration storyScreenBackground() {
  return const BoxDecoration(
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
    final border = borderColor ?? AppColors.accent.withValues(alpha: 0.35);
    final normalized = label.trim().isEmpty ? 'F' : label.trim().toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: math.max(1.5, size * 0.06)),
      ),
      child: ClipOval(
        child: imageUrl == null
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8E8D7), Color(0xFFF1B36B)],
                  ),
                ),
                child: Center(
                  child: Text(
                    normalized,
                    style: TextStyle(
                      color: const Color(0xFF2C1507),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8E8D7), Color(0xFFF1B36B)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        normalized,
                        style: TextStyle(
                          color: const Color(0xFF2C1507),
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

class StoryCoverImage extends StatelessWidget {
  const StoryCoverImage({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accent.withValues(alpha: 0.25),
              const Color(0xFF22160D),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            color: Colors.white.withValues(alpha: 0.72),
            size: StoryAdaptive.of(context).scale(44),
          ),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const _StoryImageLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF22160D)),
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 34,
            ),
          ),
        );
      },
    );
  }
}

class _StoryImageLoadingPlaceholder extends StatelessWidget {
  const _StoryImageLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF22160D)),
      child: Center(
        child: SizedBox.square(
          dimension: StoryAdaptive.of(context).scale(26),
          child: CircularProgressIndicator(
            strokeWidth: StoryAdaptive.of(context).scale(2),
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
