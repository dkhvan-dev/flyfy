import 'package:flutter/material.dart';

import '../reference/app_location_label_resolver.dart';

class AppLocalizedLocationText extends StatefulWidget {
  const AppLocalizedLocationText({
    super.key,
    required this.countryCode,
    required this.cityId,
    required this.cityName,
    required this.fallbackText,
    this.addressText,
    this.resolver,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String? countryCode;
  final String? cityId;
  final String? cityName;
  final String fallbackText;
  final String? addressText;
  final AppLocationLabelResolver? resolver;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  State<AppLocalizedLocationText> createState() =>
      _AppLocalizedLocationTextState();
}

class _AppLocalizedLocationTextState extends State<AppLocalizedLocationText> {
  static final AppLocationLabelResolver _defaultResolver =
      AppLocationLabelResolver();

  late final AppLocationLabelResolver _resolver =
      widget.resolver ?? _defaultResolver;
  String? _resolvedText;
  int _requestSerial = 0;

  bool get _hasReferenceLookup {
    final countryCode = widget.countryCode?.trim() ?? '';
    final cityId = widget.cityId?.trim() ?? '';
    final cityName = widget.cityName?.trim() ?? '';
    return countryCode.isNotEmpty || cityId.isNotEmpty || cityName.isNotEmpty;
  }

  String get _displayText {
    final resolved = _resolvedText?.trim() ?? '';
    if (resolved.isNotEmpty) return resolved;

    if (_hasReferenceLookup) return '';

    return widget.fallbackText.trim();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AppLocalizedLocationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryCode != widget.countryCode ||
        oldWidget.cityId != widget.cityId ||
        oldWidget.cityName != widget.cityName ||
        oldWidget.fallbackText != widget.fallbackText ||
        oldWidget.addressText != widget.addressText ||
        oldWidget.resolver != widget.resolver) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final serial = ++_requestSerial;
    final localeName = Localizations.localeOf(context).toString();
    final fallback = widget.fallbackText.trim();
    if (_hasReferenceLookup) {
      if (_resolvedText != null) {
        setState(() => _resolvedText = null);
      }
    } else if (fallback.isNotEmpty && _resolvedText == null) {
      setState(() => _resolvedText = fallback);
    }

    final addressText = widget.addressText?.trim() ?? '';
    String resolved;
    try {
      resolved = addressText.isEmpty
          ? await _resolver.resolve(
              countryCode: widget.countryCode,
              cityId: widget.cityId,
              cityName: widget.cityName,
              localeName: localeName,
            )
          : await _resolver.resolveAddress(
              countryCode: widget.countryCode,
              cityId: widget.cityId,
              cityName: widget.cityName,
              addressText: addressText,
              localeName: localeName,
            );
    } catch (_) {
      resolved = fallback;
    }
    if (!mounted || serial != _requestSerial) return;
    setState(
      () => _resolvedText = resolved.trim().isEmpty ? fallback : resolved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      style: widget.style,
    );
  }
}
