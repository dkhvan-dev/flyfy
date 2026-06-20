import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/network/file_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/formatters/app_money_formatter.dart';
import 'models/place_vm.dart';

const double placeTypographyScaleFactor = 0.8;
const int _defaultExternalPlaceImageTargetWidth = 480;

String localizedPlaceCategoryLabel(AppLocalizations l10n, String? category) {
  final normalized = category?.trim().toUpperCase() ?? '';
  switch (normalized) {
    case 'PARK':
    case 'PARKS':
      return l10n.placeFilterCategoryParks;
    case 'MUSEUM':
    case 'MUSEUMS':
      return l10n.placeFilterCategoryMuseums;
    case 'NATURE':
      return l10n.placeFilterCategoryNature;
    case 'ARCHITECTURE':
      return l10n.placeFilterCategoryArchitecture;
    case 'BEACH':
      return l10n.placeFilterCategoryBeach;
    case 'TEMPLE':
      return l10n.placeFilterCategoryTemple;
    case 'ENTERTAINMENT':
      return l10n.placeFilterCategoryEntertainment;
    case 'FOOD':
      return l10n.placeFilterCategoryFood;
    case 'MARKET':
      return l10n.placeFilterCategoryMarket;
    case 'SHOPPING':
      return l10n.placeFilterCategoryShopping;
    case 'OTHER':
      return l10n.placeFilterCategoryOther;
    case 'HISTORY':
      return l10n.placeFilterCategoryHistory;
    case 'ADVENTURE':
      return l10n.placeFilterCategoryAdventure;
  }
  if (normalized.isEmpty) return l10n.placeFilterCategoryOther;
  return normalized
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part
            : '${part.substring(0, 1)}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class PlaceTextScale extends StatelessWidget {
  const PlaceTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final baseFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    final systemScale =
        mediaQuery.textScaler.scale(baseFontSize) / baseFontSize;
    final adjustedScale = (systemScale * placeTypographyScaleFactor)
        .clamp(0.78, 1.08)
        .toDouble();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(adjustedScale)),
      child: child,
    );
  }
}

class PlaceAdaptive {
  PlaceAdaptive._({
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

  factory PlaceAdaptive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler;
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final textScaleFactor =
        textScaler.scale(baseStyle?.fontSize ?? 14) /
        (baseStyle?.fontSize ?? 14);

    return PlaceAdaptive._(
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
    return value * factor;
  }

  double radius(double value) => scale(value, minFactor: 0.84, maxFactor: 1.04);
}

int placeImageTargetWidth(
  BuildContext context,
  double logicalWidth, {
  int minWidth = 360,
  int maxWidth = 1600,
}) {
  final devicePixelRatio = MediaQuery.devicePixelRatioOf(
    context,
  ).clamp(1.0, 3.0);
  return (logicalWidth * devicePixelRatio)
      .round()
      .clamp(minWidth, maxWidth)
      .toInt();
}

String? resolvePlaceMediaUrl(PlaceMediaVm media, {int? targetWidth}) {
  final fileUrl = resolvePublicFileContentUrl(media.fileId);
  if (fileUrl != null) {
    return fileUrl;
  }

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(externalUrl);
  if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
    return null;
  }
  return _optimizeExternalPlaceMediaUrl(uri, targetWidth) ?? externalUrl;
}

Map<String, String>? placeImageRequestHeaders(String? url) {
  return null;
}

String? _optimizeExternalPlaceMediaUrl(Uri uri, int? targetWidth) {
  final width = _normalizedImageTargetWidth(targetWidth);
  if (width == null) return null;

  final host = uri.host.toLowerCase();
  if (host == 'commons.wikimedia.org' &&
      uri.path.startsWith('/wiki/Special:FilePath/')) {
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'width': '$width'})
        .toString();
  }

  if (host == 'upload.wikimedia.org' &&
      uri.path.startsWith('/wikipedia/commons/')) {
    final fileName = _wikimediaUploadFileName(uri);
    if (fileName != null) {
      return Uri.https(
        'commons.wikimedia.org',
        '/wiki/Special:FilePath/$fileName',
        {'width': '$width'},
      ).toString();
    }
  }

  return null;
}

String? _wikimediaUploadFileName(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length < 4 ||
      segments[0] != 'wikipedia' ||
      segments[1] != 'commons') {
    return null;
  }

  if (segments[2] == 'thumb') {
    if (segments.length < 6) return null;
    return segments[5].trim().isEmpty ? null : segments[5];
  }

  final fileName = segments.last.trim();
  return fileName.isEmpty ? null : fileName;
}

int? _normalizedImageTargetWidth(int? targetWidth) {
  if (targetWidth == null || targetWidth <= 0) {
    return _defaultExternalPlaceImageTargetWidth;
  }
  return targetWidth.clamp(240, 2200).toInt();
}

String formatPlaceDurationLabel(AppLocalizations l10n, PlaceVm place) {
  final value = place.durationValue;
  final unit = place.durationUnit?.toUpperCase();
  if (value == null || unit == null) return '';

  if (unit == 'DAYS') {
    return l10n.placeDurationDays(value);
  }
  return l10n.placeDurationHours(value);
}

String formatPlacePriceLabel(
  BuildContext context,
  AppLocalizations l10n,
  PlaceVm place,
) {
  final amount = place.priceAmount;
  if (amount == null) return l10n.placePriceVaries;

  final locale = Localizations.localeOf(context).toLanguageTag();
  return formatAppMoney(
    amount: amount,
    currency: place.priceCurrency ?? 'USD',
    localeName: locale,
  );
}
