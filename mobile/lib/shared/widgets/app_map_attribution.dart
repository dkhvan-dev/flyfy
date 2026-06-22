import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../map/app_map_links.dart';

class AppMapAttribution extends StatelessWidget {
  const AppMapAttribution({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(10),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _showAttributionSheet(context),
              child: Ink(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    'InflapMap · OpenMapTiles · OpenStreetMap',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: l10n.mapAttributionSheetTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.76,
                      ),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
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
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mapAttributionSheetSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              unawaited(launchUrl(uri, mode: LaunchMode.externalApplication)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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
