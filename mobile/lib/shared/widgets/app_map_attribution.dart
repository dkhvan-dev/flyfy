import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: DecoratedBox(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AttributionLink(label: 'Inflap Map', uri: _inflapMapUri),
                    Text(
                      ' · ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.42,
                        ),
                      ),
                    ),
                    _AttributionLink(
                      label: 'OpenMapTiles',
                      uri: _openMapTilesUri,
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.42,
                        ),
                      ),
                    ),
                    _AttributionLink(
                      label: 'OpenStreetMap',
                      uri: _openStreetMapUri,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttributionLink extends StatelessWidget {
  const _AttributionLink({required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
