import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/file_api.dart';
import '../../l10n/generated/app_localizations.dart';
import 'models/attraction_vm.dart';

const double attractionTypographyScaleFactor = 0.8;
const Map<String, String> attractionExternalImageHeaders = {
  'User-Agent': 'FlyFyMobile/1.0 FlutterImageLoader',
  'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
};

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
  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) {
    return _withWikimediaImageWidth(externalUrl, targetWidth);
  }
  return resolvePublicFileContentUrl(media.fileId);
}

Map<String, String>? attractionImageRequestHeaders(String? url) {
  final uri = Uri.tryParse((url ?? '').trim());
  if (uri == null) {
    return null;
  }

  final host = uri.host.toLowerCase();
  if (host == 'commons.wikimedia.org' || host.endsWith('.wikimedia.org')) {
    return attractionExternalImageHeaders;
  }
  return null;
}

String _withWikimediaImageWidth(String url, int? targetWidth) {
  if (targetWidth == null) {
    return url;
  }

  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.host.toLowerCase() != 'commons.wikimedia.org' ||
      !uri.path.contains('/Special:FilePath/')) {
    return url;
  }

  final queryParameters = Map<String, String>.from(uri.queryParameters)
    ..['width'] = targetWidth.toString();
  return uri.replace(queryParameters: queryParameters).toString();
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

  final currencyCode = (attraction.priceCurrency ?? 'USD').trim().toUpperCase();
  final locale = Localizations.localeOf(context).toLanguageTag();
  final decimalDigits = amount == amount.roundToDouble() ? 0 : 2;

  return NumberFormat.currency(
    locale: locale,
    name: currencyCode,
    decimalDigits: decimalDigits,
  ).format(amount);
}
