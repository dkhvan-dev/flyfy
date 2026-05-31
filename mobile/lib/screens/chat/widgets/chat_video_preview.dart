import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/files/chat_file_cache.dart';
import '../../../core/network/file_api.dart';
import '../../../core/ui/app_colors.dart';
import '../chat_video_viewer_screen.dart';

class ChatVideoPreview extends StatefulWidget {
  const ChatVideoPreview({
    super.key,
    required this.fileId,
    this.aspectRatio = 4 / 3,
    this.borderRadius = 18,
    this.enablePlayback = true,
    this.showPlayBadge = true,
    this.playBadgeSize = 48,
    this.fit = BoxFit.cover,
    this.loadLocalPreview,
    this.maxLocalPreviewBytes,
  });

  final String fileId;
  final double aspectRatio;
  final double borderRadius;
  final bool enablePlayback;
  final bool showPlayBadge;
  final double playBadgeSize;
  final BoxFit fit;
  final bool? loadLocalPreview;
  final int? maxLocalPreviewBytes;

  @override
  State<ChatVideoPreview> createState() => _ChatVideoPreviewState();
}

class _ChatVideoPreviewState extends State<ChatVideoPreview> {
  final _fileApi = FileApi();
  final _fileCache = ChatFileCache();
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  String? _loadError;
  int _loadGeneration = 0;

  bool get _shouldLoadLocalPreview =>
      widget.loadLocalPreview ?? widget.enablePlayback;

  @override
  void initState() {
    super.initState();
    _initializeFuture = _initialize();
  }

  @override
  void didUpdateWidget(covariant ChatVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId.trim() == widget.fileId.trim()) return;
    _loadGeneration++;
    unawaited(_disposeController());
    _initializeFuture = _initialize();
  }

  @override
  void dispose() {
    _loadGeneration++;
    unawaited(_disposeController());
    super.dispose();
  }

  Future<void> _initialize() async {
    final generation = ++_loadGeneration;
    final fileId = widget.fileId.trim();
    if (fileId.isEmpty) {
      setState(() => _loadError = 'missing_file');
      return;
    }

    setState(() => _loadError = null);

    try {
      final url = await _fileApi.createDownloadUrl(fileId);
      if (!mounted || generation != _loadGeneration) return;
      if (url == null || url.isEmpty) {
        if (await _initializeLocalPreview(
          generation: generation,
          fileId: fileId,
        )) {
          return;
        }
        setState(() => _loadError = 'missing_url');
        return;
      }

      final initialized = await _initializeController(
        VideoPlayerController.networkUrl(Uri.parse(url)),
        generation: generation,
      );
      if (initialized) {
        return;
      }
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
    }

    if (await _initializeLocalPreview(generation: generation, fileId: fileId)) {
      return;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() => _loadError = 'load_failed');
  }

  Future<bool> _initializeLocalPreview({
    required int generation,
    required String fileId,
  }) async {
    if (!_shouldLoadLocalPreview) return false;
    try {
      final maxBytes = widget.maxLocalPreviewBytes;
      FileMetadataVm? metadata;
      if (maxBytes != null) {
        metadata = await _fileApi.getFileMetadata(fileId);
        if (metadata.sizeBytes > maxBytes) return false;
      }
      final downloaded = await _fileCache.download(fileId, metadata: metadata);
      if (!mounted || generation != _loadGeneration) return false;
      return _initializeController(
        VideoPlayerController.file(downloaded.file),
        generation: generation,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _initializeController(
    VideoPlayerController controller, {
    required int generation,
  }) async {
    controller.addListener(_handleControllerChanged);
    try {
      await controller.initialize();
    } catch (_) {
      controller.removeListener(_handleControllerChanged);
      await controller.dispose();
      return false;
    }
    if (!mounted || generation != _loadGeneration) {
      controller.removeListener(_handleControllerChanged);
      await controller.dispose();
      return false;
    }
    await _disposeController();
    if (!mounted || generation != _loadGeneration) {
      controller.removeListener(_handleControllerChanged);
      await controller.dispose();
      return false;
    }
    setState(() => _controller = controller);
    return true;
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_handleControllerChanged);
    await controller.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openFullscreen() async {
    if (!widget.enablePlayback) return;
    final fileId = widget.fileId.trim();
    if (fileId.isEmpty) return;

    final controller = _controller;
    if (controller?.value.isPlaying ?? false) {
      await controller!.pause();
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatVideoViewerScreen(fileId: fileId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enablePlayback ? () => unawaited(_openFullscreen()) : null,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3b2414), Color(0xFF100802)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    final controller = _controller;
                    if (controller != null && controller.value.isInitialized) {
                      return FittedBox(
                        fit: widget.fit,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      );
                    }

                    if (_loadError != null) {
                      return const _VideoFallback(icon: Icons.movie_outlined);
                    }

                    return const _VideoFallback(
                      progress: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
                if (widget.showPlayBadge)
                  _VideoPlayBadge(
                    controller: _controller,
                    busy: false,
                    size: widget.playBadgeSize,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback({this.icon, this.progress});

  final IconData? icon;
  final Widget? progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          progress ??
          Icon(
            icon ?? Icons.movie_rounded,
            color: Colors.white.withValues(alpha: 0.52),
            size: 28,
          ),
    );
  }
}

class _VideoPlayBadge extends StatelessWidget {
  const _VideoPlayBadge({
    required this.controller,
    required this.busy,
    required this.size,
  });

  final VideoPlayerController? controller;
  final bool busy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isPlaying = controller?.value.isPlaying ?? false;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: busy
            ? Center(
                child: SizedBox(
                  width: size * 0.38,
                  height: size * 0.38,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: size * 0.62,
              ),
      ),
    );
  }
}
