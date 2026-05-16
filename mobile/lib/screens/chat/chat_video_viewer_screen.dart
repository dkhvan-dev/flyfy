import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/files/chat_file_cache.dart';
import '../../core/ui/app_colors.dart';

class ChatVideoViewerScreen extends StatefulWidget {
  const ChatVideoViewerScreen({super.key, required this.fileId})
      : localFilePath = null;

  const ChatVideoViewerScreen.localFile({
    super.key,
    required String path,
  })  : fileId = '',
        localFilePath = path;

  final String fileId;
  final String? localFilePath;

  @override
  State<ChatVideoViewerScreen> createState() => _ChatVideoViewerScreenState();
}

class _ChatVideoViewerScreenState extends State<ChatVideoViewerScreen> {
  final _fileCache = ChatFileCache();
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _loadFailed = false;
  bool _scrubbing = false;
  bool _resumeAfterScrub = false;

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
    final localFilePath = widget.localFilePath?.trim();
    if (localFilePath != null && localFilePath.isNotEmpty) {
      await _initializeFile(File(localFilePath));
      return;
    }

    final fileId = widget.fileId.trim();
    if (fileId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
      return;
    }

    try {
      final downloaded = await _fileCache.download(fileId);
      await _initializeFile(downloaded.file);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _initializeFile(File file) async {
    if (!await file.exists()) {
      throw StateError('Video file does not exist');
    }
    if (!mounted) return;

    final controller = VideoPlayerController.file(file);
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

    setState(() {
      _controller = controller;
      _loading = false;
      _loadFailed = false;
    });
    await controller.play();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_scrubbing) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
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

  Future<void> _dismissBySwipeDown(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < 420) return;
    final controller = _controller;
    if (controller?.value.isPlaying ?? false) {
      await controller!.pause();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;
    final duration = initialized ? controller!.value.duration : Duration.zero;
    final position = initialized ? controller!.value.position : Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: initialized ? () => unawaited(_togglePlayback()) : null,
                onVerticalDragEnd: _dismissBySwipeDown,
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: AppColors.accent,
                        )
                      : _loadFailed || !initialized
                          ? Icon(
                              Icons.movie_outlined,
                              color: Colors.white.withValues(alpha: 0.48),
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
                        Colors.black.withValues(alpha: 0.56),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
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
              child: _ViewerIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (initialized && !controller!.value.isPlaying && !_scrubbing)
              Center(
                child: _ViewerIconButton(
                  icon: Icons.play_arrow_rounded,
                  size: 68,
                  iconSize: 42,
                  onTap: () => unawaited(_togglePlayback()),
                ),
              ),
            if (initialized)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: _VideoProgressBar(
                  position: position,
                  duration: duration,
                  onChangeStart: (value) => unawaited(_handleScrubStart(value)),
                  onChanged: (value) => unawaited(_handleScrubChanged(value)),
                  onChangeEnd: (value) => unawaited(_handleScrubEnd(value)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoProgressBar extends StatelessWidget {
  const _VideoProgressBar({
    required this.position,
    required this.duration,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final max =
        duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max).toDouble();

    return SliderTheme(
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
        onChangeStart: onChangeStart,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.46),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
