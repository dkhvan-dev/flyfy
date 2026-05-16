import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/files/chat_file_cache.dart';
import '../../../core/network/file_api.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';

class ChatVoiceAttachmentPlayer extends StatefulWidget {
  const ChatVoiceAttachmentPlayer({
    super.key,
    required this.fileId,
    required this.metadata,
    this.dense = false,
    this.padding,
    this.backgroundColor,
    this.borderColor,
  });

  final String fileId;
  final FileMetadataVm? metadata;
  final bool dense;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<ChatVoiceAttachmentPlayer> createState() =>
      _ChatVoiceAttachmentPlayerState();
}

class _ChatVoiceAttachmentPlayerState extends State<ChatVoiceAttachmentPlayer> {
  final _fileCache = ChatFileCache();
  final _player = AudioPlayer();
  bool _preparing = false;
  int _prepareGeneration = 0;
  String? _preparedFileId;

  @override
  void dispose() {
    _prepareGeneration++;
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_preparing) {
      await _stopLoading();
      return;
    }

    try {
      final completed = _player.processingState == ProcessingState.completed;
      if (_player.playing && !completed) {
        await _player.pause();
        return;
      }

      final prepared = await _prepareVoiceSource();
      if (!prepared) return;

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!mounted || _preparing) return;
      unawaited(_playPrepared(_prepareGeneration));
    } catch (_) {
      if (!mounted) return;
      await _showPlaybackError();
    }
  }

  Future<bool> _prepareVoiceSource({double? seekFraction}) async {
    if (_preparedFileId == widget.fileId) return true;
    if (_preparing) return false;

    final prepareGeneration = ++_prepareGeneration;
    setState(() => _preparing = true);

    try {
      final downloaded = await _fileCache.download(
        widget.fileId,
        metadata: widget.metadata,
      );
      if (!mounted || prepareGeneration != _prepareGeneration) return false;
      final duration = await _player.setFilePath(downloaded.file.path);
      if (!mounted || prepareGeneration != _prepareGeneration) return false;
      _preparedFileId = widget.fileId;

      if (seekFraction != null && duration != null) {
        await _seekPreparedSource(seekFraction, duration);
      }
      return true;
    } catch (_) {
      if (mounted && prepareGeneration == _prepareGeneration) {
        await _showPlaybackError();
      }
      return false;
    } finally {
      if (mounted && prepareGeneration == _prepareGeneration && _preparing) {
        setState(() => _preparing = false);
      }
    }
  }

  Future<void> _stopLoading() async {
    _prepareGeneration++;
    if (mounted) {
      setState(() => _preparing = false);
    }
    _preparedFileId = null;
    try {
      await _player.stop();
    } catch (_) {
      // The player may not have an active source yet.
    }
  }

  Future<void> _playPrepared(int generation) async {
    try {
      await _player.play();
    } catch (_) {
      if (!mounted || generation != _prepareGeneration) return;
      await _showPlaybackError();
    }
  }

  Future<void> _seekToFraction(double seekFraction, Duration duration) async {
    if (_preparing) return;
    if (duration.inMilliseconds <= 0) {
      await _prepareVoiceSource(seekFraction: seekFraction);
      return;
    }
    await _seekPreparedSource(seekFraction, duration);
  }

  Future<void> _seekPreparedSource(
    double seekFraction,
    Duration duration,
  ) async {
    if (duration.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (duration.inMilliseconds * seekFraction.clamp(0.0, 1.0))
          .round(),
    );
    await _player.seek(target);
  }

  Future<void> _showPlaybackError() {
    final l10n = AppLocalizations.of(context)!;
    return showErrorDialog(
      context,
      title: l10n.error,
      message: l10n.chatVoicePlaybackFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = _voiceScale(context, widget.dense);

    return Container(
      padding: widget.padding ?? EdgeInsets.all(scale(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale(widget.dense ? 18 : 22)),
        color: widget.backgroundColor ?? Colors.black.withValues(alpha: 0.14),
        border: Border.all(
          color: widget.borderColor ?? Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final processing = snapshot.data?.processingState;
              final busy =
                  _preparing ||
                  processing == ProcessingState.loading ||
                  processing == ProcessingState.buffering;
              final playing =
                  (snapshot.data?.playing ?? false) &&
                  processing != ProcessingState.completed;

              return GestureDetector(
                onTap: busy ? _stopLoading : _toggle,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: scale(widget.dense ? 42 : 48),
                  height: scale(widget.dense ? 42 : 48),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: Center(
                    child: busy
                        ? SizedBox(
                            width: scale(18),
                            height: scale(18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: scale(widget.dense ? 27 : 30),
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: scale(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatVoiceMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: scale(widget.dense ? 14 : 15),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFf5ede6),
                  ),
                ),
                SizedBox(height: scale(widget.dense ? 7 : 8)),
                StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration =
                        durationSnapshot.data ??
                        _player.duration ??
                        Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position =
                            positionSnapshot.data ?? _player.position;
                        final progress = duration.inMilliseconds <= 0
                            ? 0.0
                            : (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0);

                        return Row(
                          children: [
                            Expanded(
                              child: _ChatVoiceWaveform(
                                progress: progress,
                                dense: widget.dense,
                                enabled: !_preparing,
                                onSeekFraction: (fraction) =>
                                    _seekToFraction(fraction, duration),
                              ),
                            ),
                            if (duration.inMilliseconds > 0) ...[
                              SizedBox(width: scale(10)),
                              Text(
                                _formatVoiceDuration(
                                  position == Duration.zero
                                      ? duration
                                      : position,
                                ),
                                style: TextStyle(
                                  fontSize: scale(widget.dense ? 11 : 12),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(
                                    0xFFc8b39a,
                                  ).withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatVoiceWaveform extends StatelessWidget {
  const _ChatVoiceWaveform({
    required this.progress,
    required this.dense,
    this.enabled = false,
    this.onSeekFraction,
  });

  final double progress;
  final bool dense;
  final bool enabled;
  final ValueChanged<double>? onSeekFraction;

  @override
  Widget build(BuildContext context) {
    const bars = [0.25, 0.45, 0.72, 0.38, 0.9, 0.56, 0.34, 0.68, 0.48, 0.8];
    final activeBars = (bars.length * progress).ceil();
    final scale = _voiceScale(context, dense);

    return LayoutBuilder(
      builder: (context, constraints) {
        void seekAt(Offset localPosition) {
          final width = constraints.maxWidth;
          if (!enabled || onSeekFraction == null || width <= 0) return;
          onSeekFraction!((localPosition.dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          onHorizontalDragStart: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          onHorizontalDragUpdate: enabled
              ? (details) => seekAt(details.localPosition)
              : null,
          child: SizedBox(
            height: scale(dense ? 24 : 28),
            child: Row(
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        heightFactor: bars[i],
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: i < activeBars
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i != bars.length - 1) SizedBox(width: scale(4)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

double Function(double) _voiceScale(BuildContext context, bool dense) {
  final width = MediaQuery.sizeOf(context).width.clamp(320.0, 430.0);
  final factor = (width / 390) * (dense ? 0.94 : 1.0);
  return (base) => base * factor;
}

String _formatVoiceDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
