import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/network/file_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/currency_rate_provider.dart';
import '../../shared/formatters/app_money_formatter.dart';
import 'models/place_vm.dart';

const double placeTypographyScaleFactor = 0.8;
const int _defaultExternalPlaceImageTargetWidth = 480;
const double _minDiscoverGridTwoColumnWidth = 300;

int placeDiscoverGridColumnCount(double crossAxisExtent) {
  if (!crossAxisExtent.isFinite || crossAxisExtent <= 0) {
    return 1;
  }
  return crossAxisExtent < _minDiscoverGridTwoColumnWidth ? 1 : 2;
}

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

List<String> resolvePlaceMediaUrls(PlaceMediaVm media, {int? targetWidth}) {
  final urls = <String>[];
  final primaryUrl = resolvePlaceMediaUrl(media, targetWidth: targetWidth);
  if (primaryUrl != null) {
    urls.add(primaryUrl);
  }

  final sourceUrl = _wikimediaSpecialFilePathFromSourceUrl(
    media.sourceUrl,
    targetWidth: targetWidth,
  );
  if (sourceUrl != null) {
    _addUniqueUrl(urls, sourceUrl);
  }

  final externalUrl = media.externalUrl.trim();
  if (externalUrl.isNotEmpty) {
    final uri = Uri.tryParse(externalUrl);
    if (uri != null && (uri.isScheme('https') || uri.isScheme('http'))) {
      final optimizedUrl = _optimizeExternalPlaceMediaUrl(uri, targetWidth);
      if (optimizedUrl != null) {
        _addUniqueUrl(urls, optimizedUrl);
      }
      _addUniqueUrl(urls, externalUrl);
    }
  }

  return List.unmodifiable(urls);
}

void _addUniqueUrl(List<String> urls, String url) {
  final normalized = url.trim();
  if (normalized.isEmpty || urls.contains(normalized)) return;
  urls.add(normalized);
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

String? _wikimediaSpecialFilePathFromSourceUrl(
  String sourceUrl, {
  int? targetWidth,
}) {
  final uri = Uri.tryParse(sourceUrl.trim());
  if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (host != 'commons.wikimedia.org' || uri.pathSegments.length < 2) {
    return null;
  }
  if (uri.pathSegments.first != 'wiki') {
    return null;
  }

  final rawFileSegment = Uri.decodeComponent(uri.pathSegments[1]);
  if (!rawFileSegment.startsWith('File:')) {
    return null;
  }
  final fileName = rawFileSegment
      .substring('File:'.length)
      .trim()
      .replaceAll(' ', '_');
  if (fileName.isEmpty) return null;

  final width = _normalizedImageTargetWidth(targetWidth);
  final encodedFileName = Uri.encodeComponent(
    fileName,
  ).replaceAll('%2C', ',').replaceAll('%28', '(').replaceAll('%29', ')');
  final query = width == null ? '' : '?width=$width';
  return 'https://commons.wikimedia.org/wiki/Special:FilePath/$encodedFileName$query';
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
  PlaceVm place, {
  String? preferredCurrency,
  CurrencyRateProvider? currencyRates,
}) {
  final amount = place.priceAmount;
  if (amount == null) {
    final summary = place.priceSummaryLabel?.trim();
    if (summary != null && summary.isNotEmpty) return summary;
    return l10n.placePriceVaries;
  }
  if (amount <= 0) return l10n.placeFreeEntry;

  final locale = Localizations.localeOf(context).toLanguageTag();
  final sourceCurrency =
      resolveAppCurrencyCode(
        currency: place.priceCurrency,
        countryCode: place.countryCode,
      ) ??
      'USD';
  final targetCurrency = normalizeAppCurrencyCode(preferredCurrency);
  var displayAmount = amount;
  var displayCurrency = sourceCurrency;

  if (targetCurrency != null && targetCurrency != sourceCurrency) {
    final converted = currencyRates?.convertAmount(
      amount: amount,
      fromCurrency: sourceCurrency,
      toCurrency: targetCurrency,
    );
    if (converted != null) {
      displayAmount = converted;
      displayCurrency = targetCurrency;
    }
  }

  final formatted = formatAppMoney(
    amount: displayAmount,
    currency: displayCurrency,
    localeName: locale,
    useListCurrencyFormat: true,
  );
  return l10n.placePriceFrom(formatted);
}

String formatPlaceFeeAmountLabel(
  BuildContext context,
  AppLocalizations l10n,
  PlaceVm place,
  PlaceFeeDetailVm fee, {
  String? preferredCurrency,
  CurrencyRateProvider? currencyRates,
}) {
  final amount = fee.amount;
  if (amount == null) return '';

  final locale = Localizations.localeOf(context).toLanguageTag();
  final sourceCurrency =
      resolveAppCurrencyCode(
        currency: fee.currency,
        countryCode: place.countryCode,
      ) ??
      resolveAppCurrencyCode(
        currency: place.priceCurrency,
        countryCode: place.countryCode,
      ) ??
      'USD';
  final targetCurrency = normalizeAppCurrencyCode(preferredCurrency);
  var displayAmount = amount;
  var displayCurrency = sourceCurrency;

  if (targetCurrency != null && targetCurrency != sourceCurrency) {
    final converted = currencyRates?.convertAmount(
      amount: amount,
      fromCurrency: sourceCurrency,
      toCurrency: targetCurrency,
    );
    if (converted != null) {
      displayAmount = converted;
      displayCurrency = targetCurrency;
    }
  }

  var formatted = formatAppMoney(
    amount: displayAmount,
    currency: displayCurrency,
    localeName: locale,
    useListCurrencyFormat: true,
  );
  if (fee.isApproximate) {
    formatted = l10n.placeFeeApproxAmount(formatted);
  }

  final unit = localizedPlaceFeeUnitLabel(l10n, fee.unit);
  if (unit.isEmpty) {
    return formatted;
  }
  return l10n.placeFeePerUnit(formatted, unit);
}

String localizedPlaceFeeUnitLabel(AppLocalizations l10n, String? unit) {
  switch (unit?.trim().toUpperCase()) {
    case 'PERSON':
      return l10n.placeFeeUnitPerson;
    case 'CAR':
      return l10n.placeFeeUnitCar;
    case 'MOTORCYCLE':
      return l10n.placeFeeUnitMotorcycle;
    case 'TICKET':
      return l10n.placeFeeUnitTicket;
    case 'GROUP':
      return l10n.placeFeeUnitGroup;
    case 'ITEM':
      return l10n.placeFeeUnitItem;
    default:
      return '';
  }
}

bool canDisplayInitialPlaceForLocale(PlaceVm? place, Locale locale) {
  if (place == null) return false;
  final placeLanguage = _languageCode(place.locale);
  final currentLanguage = _languageCode(locale.toLanguageTag());
  if (placeLanguage.isEmpty || currentLanguage.isEmpty) return false;
  return placeLanguage == currentLanguage;
}

String _languageCode(String localeName) {
  return localeName.trim().toLowerCase().split(RegExp('[-_]')).first;
}
