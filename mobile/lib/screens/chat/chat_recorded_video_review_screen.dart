import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/media/video_trimmer.dart';
import '../../core/ui/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class ChatRecordedVideoReviewScreen extends StatefulWidget {
  const ChatRecordedVideoReviewScreen({
    super.key,
    required this.file,
    this._videoTrimmer,
  });

  final XFile file;
  final VideoTrimmer? _videoTrimmer;

  @override
  State<ChatRecordedVideoReviewScreen> createState() =>
      _ChatRecordedVideoReviewScreenState();
}

class _ChatRecordedVideoReviewScreenState
    extends State<ChatRecordedVideoReviewScreen> {
  late final VideoTrimmer _videoTrimmer =
      widget._videoTrimmer ?? VideoTrimmer();
  VideoPlayerController? _controller;
  RangeValues? _trimRange;
  bool _loading = true;
  bool _loadFailed = false;
  bool _sending = false;
  bool _scrubbing = false;
  bool _resumeAfterScrub = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_handleControllerChanged);
    unawaited(controller?.dispose());
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.file(File(widget.file.path));
      controller.addListener(_handleControllerChanged);
      try {
        await controller.initialize();
        await controller.setLooping(false);
      } catch (_) {
        controller.removeListener(_handleControllerChanged);
        await controller.dispose();
        rethrow;
      }

      if (!mounted) {
        controller.removeListener(_handleControllerChanged);
        await controller.dispose();
        return;
      }

      final durationMs = controller.value.duration.inMilliseconds.toDouble();
      setState(() {
        _controller = controller;
        _trimRange = RangeValues(0, durationMs <= 0 ? 1 : durationMs);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _handleControllerChanged() {
    final controller = _controller;
    final trimRange = _trimRange;
    if (controller != null &&
        trimRange != null &&
        controller.value.isInitialized &&
        !_scrubbing) {
      final positionMs = controller.value.position.inMilliseconds.toDouble();
      if (positionMs > trimRange.end) {
        unawaited(controller.pause());
        unawaited(
          controller.seekTo(Duration(milliseconds: trimRange.start.round())),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    final trimRange = _trimRange;
    if (controller == null ||
        !controller.value.isInitialized ||
        trimRange == null ||
        _scrubbing ||
        _sending) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    final positionMs = controller.value.position.inMilliseconds.toDouble();
    if (positionMs < trimRange.start || positionMs >= trimRange.end) {
      await controller.seekTo(Duration(milliseconds: trimRange.start.round()));
    }
    await controller.play();
  }

  Future<void> _handleScrubStart(double milliseconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _resumeAfterScrub = controller.value.isPlaying;
    if (mounted) setState(() => _scrubbing = true);
    await controller.pause();
    await _seekTo(milliseconds);
  }

  Future<void> _handleScrubChanged(double milliseconds) async {
    await _seekTo(milliseconds);
  }

  Future<void> _handleScrubEnd(double milliseconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final shouldResume = _resumeAfterScrub;
    _resumeAfterScrub = false;
    await _seekTo(milliseconds);
    if (mounted) setState(() => _scrubbing = false);
    if (shouldResume) {
      await controller.play();
    }
  }

  Future<void> _seekTo(double milliseconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.seekTo(Duration(milliseconds: milliseconds.round()));
  }

  Future<void> _updateTrimRange(RangeValues values) async {
    final controller = _controller;
    final duration = controller?.value.duration ?? Duration.zero;
    if (controller == null ||
        !controller.value.isInitialized ||
        duration <= Duration.zero) {
      return;
    }

    final maxMs = duration.inMilliseconds.toDouble();
    var start = values.start.clamp(0.0, maxMs).toDouble();
    var end = values.end.clamp(0.0, maxMs).toDouble();
    const minRangeMs = 600.0;
    if (end - start < minRangeMs) {
      if (start + minRangeMs <= maxMs) {
        end = start + minRangeMs;
      } else {
        start = (end - minRangeMs).clamp(0.0, maxMs).toDouble();
      }
    }

    final normalized = RangeValues(start, end);
    setState(() => _trimRange = normalized);

    final positionMs = controller.value.position.inMilliseconds.toDouble();
    if (positionMs < normalized.start || positionMs > normalized.end) {
      await controller.seekTo(Duration(milliseconds: normalized.start.round()));
    }
  }

  Future<void> _send() async {
    final controller = _controller;
    final trimRange = _trimRange;
    if (_sending ||
        controller == null ||
        !controller.value.isInitialized ||
        trimRange == null) {
      return;
    }

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      await controller.pause();
      final duration = controller.value.duration;
      final hasTrim =
          trimRange.start > 250 ||
          trimRange.end < duration.inMilliseconds.toDouble() - 250;
      if (!hasTrim) {
        if (mounted) Navigator.of(context).pop(widget.file);
        return;
      }

      final outputPath = await _videoTrimmer.trimVideoPath(
        inputPath: widget.file.path,
        start: Duration(milliseconds: trimRange.start.round()),
        end: Duration(milliseconds: trimRange.end.round()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        XFile(
          outputPath,
          mimeType: _videoMimeTypeForPath(outputPath),
          name: _fileNameForPath(outputPath),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorMessage = AppLocalizations.of(context)!.chatCameraTrimFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;
    final duration = initialized ? controller!.value.duration : Duration.zero;
    final position = initialized ? controller!.value.position : Duration.zero;
    final trimRange = _trimRange;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: initialized ? () => unawaited(_togglePlayback()) : null,
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(color: AppColors.accent)
                      : _loadFailed || !initialized
                      ? Icon(
                          Icons.movie_outlined,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 54,
                        )
                      : AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.58),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _ReviewIconButton(
                icon: Icons.close_rounded,
                label: l10n.chatCameraReviewCancelButtonLabel,
                onTap: _sending ? null : () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _SendButton(
                label: _sending
                    ? l10n.chatCameraReviewProcessing
                    : l10n.chatCameraReviewSendButtonLabel,
                onTap: initialized && !_sending
                    ? () => unawaited(_send())
                    : null,
              ),
            ),
            if (initialized && !controller!.value.isPlaying && !_scrubbing)
              Center(
                child: _ReviewIconButton(
                  icon: Icons.play_arrow_rounded,
                  label: l10n.chatCameraReviewPlayButtonLabel,
                  size: 70,
                  iconSize: 44,
                  onTap: _sending ? null : () => unawaited(_togglePlayback()),
                ),
              ),
            if (initialized && trimRange != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: _ReviewControls(
                  duration: duration,
                  position: position,
                  trimRange: trimRange,
                  trimLabel: l10n.chatCameraReviewTrimLabel,
                  onProgressStart: (value) =>
                      unawaited(_handleScrubStart(value)),
                  onProgressChanged: (value) =>
                      unawaited(_handleScrubChanged(value)),
                  onProgressEnd: (value) => unawaited(_handleScrubEnd(value)),
                  onTrimChanged: (values) =>
                      unawaited(_updateTrimRange(values)),
                ),
              ),
            if (_errorMessage != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: initialized ? 176 : 24,
                child: _ReviewErrorBanner(message: _errorMessage!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewControls extends StatelessWidget {
  const _ReviewControls({
    required this.duration,
    required this.position,
    required this.trimRange,
    required this.trimLabel,
    required this.onProgressStart,
    required this.onProgressChanged,
    required this.onProgressEnd,
    required this.onTrimChanged,
  });

  final Duration duration;
  final Duration position;
  final RangeValues trimRange;
  final String trimLabel;
  final ValueChanged<double> onProgressStart;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onProgressEnd;
  final ValueChanged<RangeValues> onTrimChanged;

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max).toDouble();
    final canTrim = duration.inMilliseconds > 1000;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.24),
            thumbColor: Colors.white,
            overlayColor: AppColors.accent.withValues(alpha: 0.18),
          ),
          child: Slider(
            min: 0,
            max: max,
            value: value,
            onChangeStart: onProgressStart,
            onChanged: onProgressChanged,
            onChangeEnd: onProgressEnd,
          ),
        ),
        if (canTrim)
          _TrimRangeSelector(
            duration: duration,
            values: trimRange,
            label: trimLabel,
            onChanged: onTrimChanged,
          ),
      ],
    );
  }
}

class _TrimRangeSelector extends StatelessWidget {
  const _TrimRangeSelector({
    required this.duration,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final Duration duration;
  final RangeValues values;
  final String label;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds.toDouble();
    final start = Duration(milliseconds: values.start.round());
    final end = Duration(milliseconds: values.end.round());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_formatReviewDuration(start)} - ${_formatReviewDuration(end)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            RangeSlider(
              min: 0,
              max: max <= 0 ? 1 : max,
              values: RangeValues(
                values.start.clamp(0.0, max).toDouble(),
                values.end.clamp(0.0, max <= 0 ? 1 : max).toDouble(),
              ),
              activeColor: AppColors.accent,
              inactiveColor: Colors.white.withValues(alpha: 0.24),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewIconButton extends StatelessWidget {
  const _ReviewIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.48),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: onTap == null ? 0.36 : 1),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withValues(alpha: onTap == null ? 0.48 : 1),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewErrorBanner extends StatelessWidget {
  const _ReviewErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _formatReviewDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _fileNameForPath(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) return 'video.mp4';
  final separatorIndex = normalized.lastIndexOf(Platform.pathSeparator);
  if (separatorIndex < 0 || separatorIndex == normalized.length - 1) {
    return normalized;
  }
  return normalized.substring(separatorIndex + 1);
}

String _videoMimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.m4v')) return 'video/x-m4v';
  return 'video/mp4';
}
