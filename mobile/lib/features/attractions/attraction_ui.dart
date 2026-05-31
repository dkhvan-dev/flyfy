import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/network/file_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/formatters/app_money_formatter.dart';
import 'models/attraction_vm.dart';

const double attractionTypographyScaleFactor = 0.8;

class AttractionTextScale extends StatelessWidget {
  const AttractionTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final baseFontSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    final systemScale =
        mediaQuery.textScaler.scale(baseFontSize) / baseFontSize;
    final adjustedScale = (systemScale * attractionTypographyScaleFactor)
        .clamp(0.78, 1.08)
        .toDouble();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(adjustedScale)),
      child: child,
    );
  }
}

class AttractionAdaptive {
  AttractionAdaptive._({
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

  factory AttractionAdaptive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = mq.textScaler;
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final textScaleFactor =
        textScaler.scale(baseStyle?.fontSize ?? 14) /
        (baseStyle?.fontSize ?? 14);

    return AttractionAdaptive._(
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

int attractionImageTargetWidth(
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

String? resolveAttractionMediaUrl(AttractionMediaVm media, {int? targetWidth}) {
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
  return _optimizeExternalAttractionMediaUrl(uri, targetWidth) ?? externalUrl;
}

Map<String, String>? attractionImageRequestHeaders(String? url) {
  return null;
}

String? _optimizeExternalAttractionMediaUrl(Uri uri, int? targetWidth) {
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
  if (targetWidth == null || targetWidth <= 0) return null;
  return targetWidth.clamp(240, 2200).toInt();
}

String formatAttractionDurationLabel(
  AppLocalizations l10n,
  AttractionVm attraction,
) {
  final value = attraction.durationValue;
  final unit = attraction.durationUnit?.toUpperCase();
  if (value == null || unit == null) return '';

  if (unit == 'DAYS') {
    return l10n.attractionDurationDays(value);
  }
  return l10n.attractionDurationHours(value);
}

String formatAttractionPriceLabel(
  BuildContext context,
  AppLocalizations l10n,
  AttractionVm attraction,
) {
  final amount = attraction.priceAmount;
  if (amount == null) return l10n.attractionPriceVaries;

  final locale = Localizations.localeOf(context).toLanguageTag();
  return formatAppMoney(
    amount: amount,
    currency: attraction.priceCurrency ?? 'USD',
    localeName: locale,
  );
}
