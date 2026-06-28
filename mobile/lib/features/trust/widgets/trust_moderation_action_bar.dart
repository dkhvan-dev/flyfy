import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

enum TrustModerationAction { report, mute, unmute, appeal }

typedef TrustModerationActionCallback = FutureOr<void> Function();

class TrustModerationActionBar extends StatefulWidget {
  const TrustModerationActionBar({
    super.key,
    this.reportLabel,
    this.muteLabel,
    this.unmuteLabel,
    this.appealLabel,
    this.onReport,
    this.onMute,
    this.onUnmute,
    this.onAppeal,
    this.isMuted = false,
    this.enabled = true,
    this.dense = false,
    this.alignment = WrapAlignment.start,
  });

  final String? reportLabel;
  final String? muteLabel;
  final String? unmuteLabel;
  final String? appealLabel;
  final TrustModerationActionCallback? onReport;
  final TrustModerationActionCallback? onMute;
  final TrustModerationActionCallback? onUnmute;
  final TrustModerationActionCallback? onAppeal;
  final bool isMuted;
  final bool enabled;
  final bool dense;
  final WrapAlignment alignment;

  @override
  State<TrustModerationActionBar> createState() =>
      _TrustModerationActionBarState();
}

class _TrustModerationActionBarState extends State<TrustModerationActionBar> {
  TrustModerationAction? _busyAction;

  @override
  Widget build(BuildContext context) {
    final entries = _entries();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxButtonWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: widget.alignment,
          children: [
            for (final entry in entries)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxButtonWidth),
                child: _TrustModerationActionButton(
                  entry: entry,
                  dense: widget.dense,
                  isBusy: _busyAction == entry.action,
                  isEnabled: widget.enabled && _busyAction == null,
                  onPressed: () => _run(entry),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_TrustModerationActionEntry> _entries() {
    final entries = <_TrustModerationActionEntry>[];
    final reportLabel = widget.reportLabel?.trim();
    final muteLabel = widget.muteLabel?.trim();
    final unmuteLabel = widget.unmuteLabel?.trim();
    final appealLabel = widget.appealLabel?.trim();

    if (reportLabel != null &&
        reportLabel.isNotEmpty &&
        widget.onReport != null) {
      entries.add(
        _TrustModerationActionEntry(
          action: TrustModerationAction.report,
          icon: Icons.flag_outlined,
          label: reportLabel,
          callback: widget.onReport!,
        ),
      );
    }

    if (widget.isMuted) {
      if (unmuteLabel != null &&
          unmuteLabel.isNotEmpty &&
          widget.onUnmute != null) {
        entries.add(
          _TrustModerationActionEntry(
            action: TrustModerationAction.unmute,
            icon: Icons.notifications_active_outlined,
            label: unmuteLabel,
            callback: widget.onUnmute!,
          ),
        );
      }
    } else if (muteLabel != null &&
        muteLabel.isNotEmpty &&
        widget.onMute != null) {
      entries.add(
        _TrustModerationActionEntry(
          action: TrustModerationAction.mute,
          icon: Icons.notifications_off_outlined,
          label: muteLabel,
          callback: widget.onMute!,
        ),
      );
    }

    if (appealLabel != null &&
        appealLabel.isNotEmpty &&
        widget.onAppeal != null) {
      entries.add(
        _TrustModerationActionEntry(
          action: TrustModerationAction.appeal,
          icon: Icons.rate_review_outlined,
          label: appealLabel,
          callback: widget.onAppeal!,
        ),
      );
    }

    return entries;
  }

  Future<void> _run(_TrustModerationActionEntry entry) async {
    if (!widget.enabled || _busyAction != null) {
      return;
    }

    setState(() => _busyAction = entry.action);
    try {
      await Future<void>.sync(entry.callback);
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }
}

class _TrustModerationActionButton extends StatelessWidget {
  const _TrustModerationActionButton({
    required this.entry,
    required this.dense,
    required this.isBusy,
    required this.isEnabled,
    required this.onPressed,
  });

  final _TrustModerationActionEntry entry;
  final bool dense;
  final bool isBusy;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 16.0 : 18.0;
    final verticalPadding = dense ? 6.0 : 8.0;

    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.textPrimary,
        side: BorderSide(color: AppPalette.outlineOverlay),
        padding: AppEdgeInsets.symmetric(
          horizontal: 10,
          vertical: verticalPadding,
        ),
        minimumSize: Size(48, dense ? 36 : 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            SizedBox.square(
              dimension: iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(entry.icon, size: iconSize),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              entry.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustModerationActionEntry {
  const _TrustModerationActionEntry({
    required this.action,
    required this.icon,
    required this.label,
    required this.callback,
  });

  final TrustModerationAction action;
  final IconData icon;
  final String label;
  final TrustModerationActionCallback callback;
}
