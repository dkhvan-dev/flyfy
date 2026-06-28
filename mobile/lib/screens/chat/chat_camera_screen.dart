import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../l10n/generated/app_localizations.dart';
import 'chat_recorded_video_review_screen.dart';

const _chatCameraResolutionPreset = ResolutionPreset.veryHigh;
const _chatCameraFps = 30;
const _chatCameraVideoBitrate = 8 * 1000 * 1000;
const _chatCameraAudioBitrate = 128 * 1000;

enum _ChatCameraMode { photo, video }

class ChatCameraScreen extends StatefulWidget {
  const ChatCameraScreen({
    super.key,
    this.maxVideoDuration = const Duration(minutes: 5),
  });

  final Duration maxVideoDuration;

  @override
  State<ChatCameraScreen> createState() => _ChatCameraScreenState();
}

class _ChatCameraScreenState extends State<ChatCameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraDescription? _selectedCamera;
  CameraController? _controller;
  Timer? _recordingTimer;
  Timer? _focusReticleTimer;

  _ChatCameraMode _mode = _ChatCameraMode.photo;
  Duration _recordingDuration = Duration.zero;
  FlashMode _flashMode = FlashMode.off;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _currentZoom = 1;
  double _zoomOnScaleStart = 1;
  Offset? _focusPoint;
  double? _pendingZoomLevel;
  bool _busy = false;
  bool _loading = true;
  bool _zoomUpdateInFlight = false;
  bool _recording = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCameras());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _focusReticleTimer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_releaseCameraForLifecycle());
    } else if (state == AppLifecycleState.resumed) {
      final camera = _selectedCamera;
      if (camera != null) {
        unawaited(_initializeCamera(camera));
      }
    }
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameras = const [];
          _selectedCamera = null;
          _loading = false;
          _errorMessage = AppLocalizations.of(context)!.chatCameraUnavailable;
        });
        return;
      }

      final selected = _preferredCamera(cameras);
      setState(() {
        _cameras = cameras;
        _selectedCamera = selected;
      });
      await _initializeCamera(selected);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _cameraExceptionMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = AppLocalizations.of(context)!.chatCameraUnavailable;
      });
    }
  }

  CameraDescription _preferredCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return cameras.first;
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    final oldController = _controller;
    final isVideoMode = _mode == _ChatCameraMode.video;
    final controller = CameraController(
      camera,
      _chatCameraResolutionPreset,
      enableAudio: isVideoMode,
      fps: _chatCameraFps,
      videoBitrate: isVideoMode ? _chatCameraVideoBitrate : null,
      audioBitrate: isVideoMode ? _chatCameraAudioBitrate : null,
    );

    setState(() {
      _loading = true;
      _busy = false;
      _recording = false;
      _recordingDuration = Duration.zero;
      _errorMessage = null;
      _controller = controller;
      _selectedCamera = camera;
    });

    _recordingTimer?.cancel();
    await oldController?.dispose();

    try {
      await controller.initialize();
      await _configureCameraForCapture(controller);
      await _applyFlashMode(controller, _flashMode);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final zoom = _currentZoom.clamp(minZoom, maxZoom).toDouble();
      if (zoom != _currentZoom) {
        await controller.setZoomLevel(zoom);
      }
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _currentZoom = zoom;
        _zoomOnScaleStart = zoom;
        _focusPoint = null;
        _loading = false;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      if (!mounted || _controller != controller) return;
      setState(() {
        _controller = null;
        _loading = false;
        _errorMessage = _cameraExceptionMessage(context, e);
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted || _controller != controller) return;
      setState(() {
        _controller = null;
        _loading = false;
        _errorMessage = AppLocalizations.of(context)!.chatCameraCaptureFailed;
      });
    }
  }

  Future<void> _configureCameraForCapture(CameraController controller) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
    } on CameraException {
      // Some devices expose fixed-focus lenses.
    }
    try {
      await controller.setExposureMode(ExposureMode.auto);
    } on CameraException {
      // Exposure mode control is best-effort across Android camera HALs.
    }
  }

  Future<void> _releaseCameraForLifecycle() async {
    final controller = _controller;
    _recordingTimer?.cancel();
    if (mounted) {
      setState(() {
        _controller = null;
        _recording = false;
        _recordingDuration = Duration.zero;
        _loading = true;
      });
    }
    try {
      if (controller?.value.isRecordingVideo ?? false) {
        await controller!.stopVideoRecording();
      }
    } catch (_) {
      // Discard lifecycle-interrupted recordings.
    }
    await controller?.dispose();
  }

  Future<void> _setMode(_ChatCameraMode mode) async {
    if (_busy || _recording || _mode == mode) return;
    setState(() => _mode = mode);

    final camera = _selectedCamera;
    if (camera != null) {
      await _initializeCamera(camera);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomOnScaleStart = _currentZoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2 || _maxZoom <= _minZoom) {
      return;
    }

    final zoom = (_zoomOnScaleStart * details.scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    if ((zoom - _currentZoom).abs() < 0.01) {
      return;
    }
    unawaited(_setZoomLevel(zoom));
  }

  Future<void> _setZoomLevel(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final clamped = zoom.clamp(_minZoom, _maxZoom).toDouble();
    if (mounted) {
      setState(() => _currentZoom = clamped);
    }

    _pendingZoomLevel = clamped;
    if (_zoomUpdateInFlight) {
      return;
    }

    _zoomUpdateInFlight = true;
    try {
      while (_pendingZoomLevel != null) {
        final nextZoom = _pendingZoomLevel!;
        _pendingZoomLevel = null;
        final activeController = _controller;
        if (activeController == null || !activeController.value.isInitialized) {
          return;
        }
        await activeController.setZoomLevel(nextZoom);
      }
    } on CameraException {
      // Some devices reject zoom changes while camera state is settling.
    } finally {
      _zoomUpdateInFlight = false;
    }
  }

  List<double> _zoomStops() {
    final candidates = <double>[
      if (_minZoom < 1) _minZoom,
      1,
      2,
      3,
      5,
      _maxZoom,
    ];
    final stops = <double>[];

    for (final candidate in candidates) {
      final clamped = candidate.clamp(_minZoom, _maxZoom).toDouble();
      if (stops.any((value) => (value - clamped).abs() < 0.08)) continue;
      stops.add(clamped);
    }

    stops.sort();
    return stops;
  }

  Future<void> _applyFlashMode(
    CameraController controller,
    FlashMode mode,
  ) async {
    try {
      await controller.setFlashMode(mode);
    } on CameraException {
      if (mode == FlashMode.off) return;
      _flashMode = FlashMode.off;
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Some front cameras do not expose flash control.
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (_busy ||
        controller == null ||
        !controller.value.isInitialized ||
        _loading) {
      return;
    }

    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      FlashMode.always || FlashMode.torch => FlashMode.off,
    };

    setState(() => _flashMode = nextMode);
    try {
      await controller.setFlashMode(nextMode);
    } on CameraException {
      if (!mounted) return;
      setState(() => _flashMode = FlashMode.off);
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Leave the UI in safe "off" state when the device rejects flash.
      }
    }
  }

  Future<void> _handlePreviewTapDown(
    TapDownDetails details,
    Size previewSize,
  ) async {
    final controller = _controller;
    if (_busy ||
        previewSize.width <= 0 ||
        previewSize.height <= 0 ||
        controller == null ||
        !controller.value.isInitialized ||
        _loading) {
      return;
    }

    final localPoint = details.localPosition;
    final normalizedPoint = Offset(
      (localPoint.dx / previewSize.width).clamp(0.0, 1.0),
      (localPoint.dy / previewSize.height).clamp(0.0, 1.0),
    );

    setState(() => _focusPoint = localPoint);
    _focusReticleTimer?.cancel();
    _focusReticleTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusPoint = null);
    });

    try {
      await controller.setFocusPoint(normalizedPoint);
      await controller.setExposurePoint(normalizedPoint);
    } on CameraException {
      // Focus/exposure points are best-effort: some devices accept only center.
    }
  }

  Future<void> _flipCamera() async {
    if (_busy || _recording || _cameras.length < 2) return;
    final selected = _selectedCamera;
    final currentIndex = selected == null ? -1 : _cameras.indexOf(selected);
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _cameras.length;
    await _initializeCamera(_cameras[nextIndex]);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy ||
        controller == null ||
        !controller.value.isInitialized ||
        _loading) {
      return;
    }

    if (_mode == _ChatCameraMode.video) {
      if (_recording) {
        await _stopVideoRecording();
      } else {
        await _startVideoRecording();
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = _cameraExceptionMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = AppLocalizations.of(context)!.chatCameraCaptureFailed;
      });
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      if (!mounted) return;

      setState(() {
        _busy = false;
        _recording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final next = _recordingDuration + const Duration(seconds: 1);
        setState(() => _recordingDuration = next);
        if (next >= widget.maxVideoDuration) {
          unawaited(_stopVideoRecording());
        }
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _errorMessage = _cameraExceptionMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _errorMessage = AppLocalizations.of(context)!.chatCameraCaptureFailed;
      });
    }
  }

  Future<void> _stopVideoRecording() async {
    final controller = _controller;
    if (_busy ||
        controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isRecordingVideo) {
      return;
    }

    _recordingTimer?.cancel();
    setState(() => _busy = true);

    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _recordingDuration = Duration.zero;
      });
      final reviewedFile = await _reviewRecordedVideo(file);
      if (!mounted) return;
      if (reviewedFile != null) {
        Navigator.of(context).pop(reviewedFile);
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _recordingDuration = Duration.zero;
        _errorMessage = _cameraExceptionMessage(context, e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _recordingDuration = Duration.zero;
        _errorMessage = AppLocalizations.of(context)!.chatCameraCaptureFailed;
      });
    }
  }

  Future<XFile?> _reviewRecordedVideo(XFile file) {
    return Navigator.of(context).push<XFile>(
      MaterialPageRoute<XFile>(
        fullscreenDialog: true,
        builder: (_) => ChatRecordedVideoReviewScreen(file: file),
      ),
    );
  }

  Future<void> _close() async {
    final controller = _controller;
    _recordingTimer?.cancel();
    try {
      if (controller?.value.isRecordingVideo ?? false) {
        await controller!.stopVideoRecording();
      }
    } catch (_) {
      // Best-effort cleanup before closing.
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _cameraExceptionMessage(BuildContext context, CameraException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' ||
      'AudioAccessDenied' ||
      'AudioAccessDeniedWithoutPrompt' ||
      'AudioAccessRestricted' => l10n.chatCameraPermissionDenied,
      _ => l10n.chatCameraCaptureFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final canFlip = _cameras.length > 1 && !_recording && !_busy;
    final canUseFlash =
        controller != null &&
        controller.value.isInitialized &&
        !_loading &&
        !_busy;

    return Scaffold(
      backgroundColor: AppPalette.black,
      body: Stack(
        children: [
          Positioned.fill(
            child:
                controller == null ||
                    _loading ||
                    !controller.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(color: AppPalette.primary),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => unawaited(
                          _handlePreviewTapDown(details, constraints.biggest),
                        ),
                        onScaleStart: _handleScaleStart,
                        onScaleUpdate: _handleScaleUpdate,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _CameraPreviewCover(controller: controller),
                            if (_focusPoint != null)
                              Positioned(
                                left: (_focusPoint!.dx - 38).clamp(
                                  8.0,
                                  math.max(8.0, constraints.maxWidth - 84),
                                ),
                                top: (_focusPoint!.dy - 38).clamp(
                                  8.0,
                                  math.max(8.0, constraints.maxHeight - 84),
                                ),
                                child: const _FocusReticle(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.black.withValues(alpha: 0.52),
                      AppPalette.transparent,
                      AppPalette.black.withValues(alpha: 0.68),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const AppEdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CameraIconButton(
                        icon: Icons.close_rounded,
                        label: l10n.chatCameraCloseButtonLabel,
                        onPressed: _busy ? null : () => unawaited(_close()),
                      ),
                      const Spacer(),
                      if (_recording)
                        _RecordingBadge(
                          label: l10n.chatCameraRecording,
                          duration: _recordingDuration,
                        ),
                      const Spacer(),
                      _CameraIconButton(
                        icon: _flashIcon(_flashMode),
                        label: _flashLabel(l10n, _flashMode),
                        onPressed: canUseFlash
                            ? () => unawaited(_toggleFlash())
                            : null,
                      ),
                      const SizedBox(width: 10),
                      _CameraIconButton(
                        icon: Icons.flip_camera_ios_rounded,
                        label: l10n.chatCameraFlipButtonLabel,
                        onPressed: canFlip
                            ? () => unawaited(_flipCamera())
                            : null,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_errorMessage != null) ...[
                    _CameraErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (_maxZoom > _minZoom) ...[
                    _ZoomLevelSelector(
                      levels: _zoomStops(),
                      currentZoom: _currentZoom,
                      enabled: !_busy,
                      onSelected: (zoom) => unawaited(_setZoomLevel(zoom)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _CameraModeSwitch(
                    mode: _mode,
                    photoLabel: l10n.chatCameraPhotoMode,
                    videoLabel: l10n.chatCameraVideoMode,
                    enabled: !_busy && !_recording,
                    onChanged: (mode) => unawaited(_setMode(mode)),
                  ),
                  const SizedBox(height: 18),
                  _CaptureButton(
                    recording: _recording,
                    busy: _busy,
                    videoMode: _mode == _ChatCameraMode.video,
                    photoLabel: l10n.chatCameraCapturePhotoButtonLabel,
                    recordLabel: l10n.chatCameraRecordVideoButtonLabel,
                    stopLabel: l10n.chatCameraStopRecordingButtonLabel,
                    onPressed: _loading ? null : () => unawaited(_capture()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final previewAspectRatio = controller.value.aspectRatio;
    final screenAspectRatio = mediaSize.aspectRatio;
    final scale = _cameraPreviewCoverScale(
      previewAspectRatio: previewAspectRatio,
      screenAspectRatio: screenAspectRatio,
    );

    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

double _cameraPreviewCoverScale({
  required double previewAspectRatio,
  required double screenAspectRatio,
}) {
  if (previewAspectRatio <= 0 || screenAspectRatio <= 0) return 1;

  final rawScale = screenAspectRatio < 1
      ? 1 / (previewAspectRatio * screenAspectRatio)
      : previewAspectRatio / screenAspectRatio;
  return math.max(1, rawScale).toDouble();
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Semantics(
      button: true,
      label: label,
      enabled: !disabled,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: AppBoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.black.withValues(alpha: 0.34),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.12)),
          ),
          child: Icon(
            icon,
            color: AppPalette.white.withValues(alpha: disabled ? 0.36 : 0.95),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge({required this.label, required this.duration});

  final String label;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.materialDanger.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.circular(999),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fiber_manual_record,
              color: AppPalette.white,
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              '$label ${_formatRecordingDuration(duration)}',
              style: const AppTextStyle(
                color: AppPalette.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomLevelSelector extends StatelessWidget {
  const _ZoomLevelSelector({
    required this.levels,
    required this.currentZoom,
    required this.enabled,
    required this.onSelected,
  });

  final List<double> levels;
  final double currentZoom;
  final bool enabled;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.black.withValues(alpha: 0.48),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final level in levels)
              _ZoomLevelChip(
                level: level,
                selected: (level - currentZoom).abs() < 0.12,
                enabled: enabled,
                onTap: () => onSelected(level),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomLevelChip extends StatelessWidget {
  const _ZoomLevelChip({
    required this.level,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final double level;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = level < 1
        ? level.toStringAsFixed(1)
        : level.toStringAsFixed(level.roundToDouble() == level ? 0 : 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const AppEdgeInsets.symmetric(horizontal: 2),
        width: 42,
        height: 34,
        alignment: Alignment.center,
        decoration: AppBoxDecoration(
          color: selected ? AppPalette.white : AppPalette.transparent,
          borderRadius: AppBorderRadius.circular(999),
        ),
        child: Text(
          '${label}x',
          style: AppTextStyle(
            color: selected
                ? AppPalette.black
                : AppPalette.white.withValues(alpha: enabled ? 0.78 : 0.34),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _FocusReticle extends StatelessWidget {
  const _FocusReticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 76,
        height: 76,
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(18),
          border: Border.all(color: AppPalette.white, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: const AppBoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraModeSwitch extends StatelessWidget {
  const _CameraModeSwitch({
    required this.mode,
    required this.photoLabel,
    required this.videoLabel,
    required this.enabled,
    required this.onChanged,
  });

  final _ChatCameraMode mode;
  final String photoLabel;
  final String videoLabel;
  final bool enabled;
  final ValueChanged<_ChatCameraMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.black.withValues(alpha: 0.36),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeChip(
              label: photoLabel,
              selected: mode == _ChatCameraMode.photo,
              enabled: enabled,
              onTap: () => onChanged(_ChatCameraMode.photo),
            ),
            _ModeChip(
              label: videoLabel,
              selected: mode == _ChatCameraMode.video,
              enabled: enabled,
              onTap: () => onChanged(_ChatCameraMode.video),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppBorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const AppEdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppBoxDecoration(
          color: selected ? AppPalette.white : AppPalette.transparent,
          borderRadius: AppBorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyle(
            color: selected
                ? AppPalette.black
                : AppPalette.white.withValues(alpha: enabled ? 0.78 : 0.36),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.recording,
    required this.busy,
    required this.videoMode,
    required this.photoLabel,
    required this.recordLabel,
    required this.stopLabel,
    required this.onPressed,
  });

  final bool recording;
  final bool busy;
  final bool videoMode;
  final String photoLabel;
  final String recordLabel;
  final String stopLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = videoMode
        ? recording
              ? stopLabel
              : recordLabel
        : photoLabel;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 76,
          height: 76,
          decoration: AppBoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.white, width: 5),
            color: videoMode
                ? AppPalette.materialDanger.withValues(
                    alpha: recording ? 0.18 : 0.95,
                  )
                : AppPalette.white.withValues(alpha: 0.18),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppPalette.white,
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: recording ? 28 : 52,
                    height: recording ? 28 : 52,
                    decoration: AppBoxDecoration(
                      color: videoMode
                          ? AppPalette.materialDanger
                          : AppPalette.white,
                      borderRadius: AppBorderRadius.circular(
                        recording ? 8 : 999,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CameraErrorBanner extends StatelessWidget {
  const _CameraErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.black.withValues(alpha: 0.62),
        borderRadius: AppBorderRadius.circular(14),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const AppTextStyle(
            color: AppPalette.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

IconData _flashIcon(FlashMode mode) {
  return switch (mode) {
    FlashMode.off => Icons.flash_off_rounded,
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always || FlashMode.torch => Icons.flash_on_rounded,
  };
}

String _flashLabel(AppLocalizations l10n, FlashMode mode) {
  return switch (mode) {
    FlashMode.off => l10n.chatCameraFlashOffButtonLabel,
    FlashMode.auto => l10n.chatCameraFlashAutoButtonLabel,
    FlashMode.always || FlashMode.torch => l10n.chatCameraFlashOnButtonLabel,
  };
}

String _formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
