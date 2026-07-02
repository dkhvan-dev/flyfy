import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../map/app_map_links.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class AppMapAttribution extends StatelessWidget {
  const AppMapAttribution({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.padding = const AppEdgeInsets.all(10),
    this.safeAreaTop = true,
  });

  static final Uri _inflapMapUri = Uri.https(
    AppMapLinks.host,
    AppMapLinks.path,
  );
  static final Uri _openMapTilesUri = Uri.parse('https://openmaptiles.org');
  static final Uri _openStreetMapUri = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );
  static final Uri _odblUri = Uri.parse(
    'https://opendatacommons.org/licenses/odbl/',
  );

  final Alignment alignment;
  final EdgeInsetsGeometry padding;
  final bool safeAreaTop;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: safeAreaTop,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Material(
            color: colors.transparent,
            child: InkWell(
              borderRadius: AppBorderRadius.circular(999),
              onTap: () => _showAttributionSheet(context),
              child: Ink(
                decoration: AppBoxDecoration(
                  color: colors.surface.withValues(alpha: 0.92),
                  borderRadius: AppBorderRadius.circular(999),
                  border: Border.all(color: colors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: colors.black.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const AppEdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    'InflapMap · OpenMapTiles · OpenStreetMap',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: l10n.mapAttributionSheetTitle,
                    style: AppTypography.captionStyle.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAttributionSheet(BuildContext context) {
    showAppModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppDesignSystem.colorsFor(context).surface,
      builder: (sheetContext) {
        return _MapAttributionSheet(
          inflapMapUri: _inflapMapUri,
          openMapTilesUri: _openMapTilesUri,
          openStreetMapUri: _openStreetMapUri,
          odblUri: _odblUri,
        );
      },
    );
  }
}

class _MapAttributionSheet extends StatelessWidget {
  const _MapAttributionSheet({
    required this.inflapMapUri,
    required this.openMapTilesUri,
    required this.openStreetMapUri,
    required this.odblUri,
  });

  final Uri inflapMapUri;
  final Uri openMapTilesUri;
  final Uri openStreetMapUri;
  final Uri odblUri;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: AppEdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.mapAttributionSheetTitle,
            style: AppTypography.titleStyle.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mapAttributionSheetSubtitle,
            style: AppTypography.bodyStyle.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _MapAttributionSourceRow(
            label: l10n.mapAttributionStyleLabel,
            value: 'InflapMap',
            uri: inflapMapUri,
          ),
          _MapAttributionSourceRow(
            label: l10n.mapAttributionTilesLabel,
            value: 'OpenMapTiles',
            uri: openMapTilesUri,
          ),
          _MapAttributionSourceRow(
            label: l10n.mapAttributionDataLabel,
            value: 'OpenStreetMap',
            uri: openStreetMapUri,
          ),
          _MapAttributionSourceRow(
            label: l10n.mapAttributionLicenseLabel,
            value: 'ODbL',
            uri: odblUri,
          ),
        ],
      ),
    );
  }
}

class _MapAttributionSourceRow extends StatelessWidget {
  const _MapAttributionSourceRow({
    required this.label,
    required this.value,
    required this.uri,
  });

  final String label;
  final String value;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(8),
        child: InkWell(
          borderRadius: AppBorderRadius.circular(8),
          onTap: () =>
              unawaited(launchUrl(uri, mode: LaunchMode.externalApplication)),
          child: Padding(
            padding: const AppEdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionStyle.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStyle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: l10n.mapAttributionOpenLink,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
