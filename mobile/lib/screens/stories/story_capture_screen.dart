import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/network/file_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../features/stories/models/story_vm.dart';
import '../../l10n/generated/app_localizations.dart';

const _storyCaptureMaxVideoDuration = Duration(seconds: 30);

enum _StoryCaptureMode { photo, video }

enum _StoryCaptureMediaKind { photo, video }

enum _StoryFlashMode { off, auto, on }

class StoryCaptureScreen extends StatefulWidget {
  const StoryCaptureScreen({
    super.key,
    FileApi? fileApi,
    StoryApi? storyApi,
    ImagePicker? imagePicker,
  }) : _fileApiOverride = fileApi,
       _storyApiOverride = storyApi,
       _imagePickerOverride = imagePicker;

  final FileApi? _fileApiOverride;
  final StoryApi? _storyApiOverride;
  final ImagePicker? _imagePickerOverride;

  @override
  State<StoryCaptureScreen> createState() => _StoryCaptureScreenState();
}

class _StoryCaptureScreenState extends State<StoryCaptureScreen>
    with WidgetsBindingObserver {
  late final FileApi _fileApi = widget._fileApiOverride ?? FileApi();
  late final StoryApi _storyApi = widget._storyApiOverride ?? StoryApi();
  late final ImagePicker _imagePicker =
      widget._imagePickerOverride ?? ImagePicker();
  final _captionController = TextEditingController();

  List<CameraDescription> _cameras = const [];
  CameraDescription? _selectedCamera;
  CameraController? _cameraController;
  Timer? _recordingTimer;
  _StoryCaptureMode _mode = _StoryCaptureMode.photo;
  _StoryFlashMode _flashMode = _StoryFlashMode.off;
  XFile? _selectedFile;
  _StoryCaptureMediaKind? _selectedKind;
  bool _loadingCamera = true;
  bool _cameraBusy = false;
  bool _recording = false;
  bool _publishing = false;
  Duration _recordingDuration = Duration.zero;
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
    _captionController.dispose();
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCameraForLifecycle());
      return;
    }
    if (state == AppLifecycleState.resumed && _selectedFile == null) {
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
          _loadingCamera = false;
          _errorMessage = AppLocalizations.of(
            context,
          )!.storyCaptureCameraUnavailable;
        });
        return;
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      setState(() {
        _cameras = cameras;
        _selectedCamera = selected;
      });
      await _initializeCamera(selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCamera = false;
        _errorMessage = AppLocalizations.of(
          context,
        )!.storyCaptureCameraUnavailable;
      });
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    final oldController = _cameraController;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: _mode == _StoryCaptureMode.video,
    );

    setState(() {
      _cameraController = controller;
      _selectedCamera = camera;
      _loadingCamera = true;
      _cameraBusy = false;
      _recording = false;
      _recordingDuration = Duration.zero;
      _errorMessage = null;
    });
    _recordingTimer?.cancel();
    await oldController?.dispose();

    try {
      await controller.initialize();
      if (!mounted || _cameraController != controller) {
        await controller.dispose();
        return;
      }
      await _applyFlashMode(controller);
      if (!mounted || _cameraController != controller) {
        await controller.dispose();
        return;
      }
      setState(() => _loadingCamera = false);
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted || _cameraController != controller) return;
      setState(() {
        _cameraController = null;
        _loadingCamera = false;
        _errorMessage = _cameraErrorLabel(context, error);
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted || _cameraController != controller) return;
      setState(() {
        _cameraController = null;
        _loadingCamera = false;
        _errorMessage = AppLocalizations.of(context)!.storyCaptureCaptureFailed;
      });
    }
  }

  Future<void> _disposeCameraForLifecycle() async {
    final controller = _cameraController;
    _recordingTimer?.cancel();
    if (mounted) {
      setState(() {
        _cameraController = null;
        _recording = false;
        _recordingDuration = Duration.zero;
        _loadingCamera = true;
      });
    }
    await controller?.dispose();
  }

  Future<void> _setMode(_StoryCaptureMode mode) async {
    if (_mode == mode || _cameraBusy || _recording) return;
    setState(() {
      _mode = mode;
      if (_mode == _StoryCaptureMode.video &&
          _flashMode == _StoryFlashMode.auto) {
        _flashMode = _StoryFlashMode.off;
      }
    });
    final camera = _selectedCamera;
    if (camera != null) {
      await _initializeCamera(camera);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _cameraBusy || _recording) return;
    final current = _selectedCamera;
    final currentIndex = current == null ? -1 : _cameras.indexOf(current);
    final next = _cameras[(currentIndex + 1) % _cameras.length];
    await _initializeCamera(next);
  }

  Future<void> _cycleFlashMode() async {
    if (_cameraBusy || _recording) return;

    final supportedModes = _mode == _StoryCaptureMode.video
        ? const [_StoryFlashMode.off, _StoryFlashMode.on]
        : _StoryFlashMode.values;
    final currentIndex = supportedModes.indexOf(_flashMode);
    final nextMode = currentIndex < 0
        ? supportedModes.first
        : supportedModes[(currentIndex + 1) % supportedModes.length];

    setState(() {
      _flashMode = nextMode;
      _errorMessage = null;
    });
    await _applyFlashMode(_cameraController);
  }

  Future<void> _applyFlashMode(CameraController? controller) async {
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final mode = _cameraFlashModeFor(_flashMode, _mode);
    try {
      await controller.setFlashMode(mode);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _flashMode = _StoryFlashMode.off;
        _errorMessage = AppLocalizations.of(
          context,
        )!.storyCaptureFlashUnsupported;
      });
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        // Some camera backends do not expose flash control at all.
      }
    }
  }

  Future<void> _capture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _cameraBusy ||
        _loadingCamera) {
      return;
    }

    if (_mode == _StoryCaptureMode.video) {
      if (_recording) {
        await _stopVideoRecording();
      } else {
        await _startVideoRecording();
      }
      return;
    }

    setState(() {
      _cameraBusy = true;
      _errorMessage = null;
    });
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _selectedFile = file;
        _selectedKind = _StoryCaptureMediaKind.photo;
        _cameraBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraBusy = false;
        _errorMessage = AppLocalizations.of(context)!.storyCaptureCaptureFailed;
      });
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _cameraBusy = true;
      _errorMessage = null;
    });
    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _recording = true;
        _cameraBusy = false;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final next = _recordingDuration + const Duration(seconds: 1);
        setState(() => _recordingDuration = next);
        if (next >= _storyCaptureMaxVideoDuration) {
          timer.cancel();
          unawaited(_stopVideoRecording());
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraBusy = false;
        _recording = false;
        _errorMessage = AppLocalizations.of(context)!.storyCaptureCaptureFailed;
      });
    }
  }

  Future<void> _stopVideoRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;
    _recordingTimer?.cancel();
    setState(() => _cameraBusy = true);
    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _selectedFile = file;
        _selectedKind = _StoryCaptureMediaKind.video;
        _recording = false;
        _cameraBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _cameraBusy = false;
        _errorMessage = AppLocalizations.of(context)!.storyCaptureCaptureFailed;
      });
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (!mounted || file == null) return;
    setState(() {
      _selectedFile = file;
      _selectedKind = _StoryCaptureMediaKind.photo;
      _errorMessage = null;
    });
  }

  Future<void> _pickVideoFromGallery() async {
    final file = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: _storyCaptureMaxVideoDuration,
    );
    if (!mounted || file == null) return;
    setState(() {
      _selectedFile = file;
      _selectedKind = _StoryCaptureMediaKind.video;
      _errorMessage = null;
    });
  }

  Future<void> _showGallerySourceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<_StoryCaptureMediaKind>(
      context: context,
      backgroundColor: const Color(0xFF1B1008),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                _StoryCaptureSheetTile(
                  icon: Icons.photo_library_rounded,
                  label: l10n.storyCapturePhotoFromGallery,
                  onTap: () =>
                      Navigator.of(context).pop(_StoryCaptureMediaKind.photo),
                ),
                const SizedBox(height: 10),
                _StoryCaptureSheetTile(
                  icon: Icons.video_library_rounded,
                  label: l10n.storyCaptureVideoFromGallery,
                  onTap: () =>
                      Navigator.of(context).pop(_StoryCaptureMediaKind.video),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == _StoryCaptureMediaKind.photo) {
      await _pickPhotoFromGallery();
    } else if (selected == _StoryCaptureMediaKind.video) {
      await _pickVideoFromGallery();
    }
  }

  Future<void> _publish() async {
    final file = _selectedFile;
    final kind = _selectedKind;
    if (file == null || kind == null || _publishing) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _publishing = true;
      _errorMessage = null;
    });

    try {
      final coverFileId = await _uploadStoryMedia(
        file: file,
        kind: kind,
        cover: true,
      );

      final caption = _captionController.text.trim();
      final story = await _storyApi.createStory(
        CreateStoryRequest(
          caption: caption,
          mediaFileId: coverFileId,
          coverFileId: coverFileId,
          mediaType: kind == _StoryCaptureMediaKind.video
              ? StoryMediaType.video
              : StoryMediaType.image,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storyCapturePublishedMessage)),
      );
      context.pop<StoryVm>(story);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _errorMessage = l10n.storyCapturePublishFailed;
      });
    }
  }

  Future<String> _uploadStoryMedia({
    required XFile file,
    required _StoryCaptureMediaKind kind,
    required bool cover,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeForFile(file, kind);
    final uploadFactory = cover
        ? _fileApi.createStoryCoverUpload
        : _fileApi.createStoryInlineImageUpload;
    final upload = await uploadFactory(
      originalName: _fileNameFor(file, kind),
      contentType: contentType,
      sizeBytes: bytes.length,
    );
    await _fileApi.uploadBinary(
      upload: upload,
      bytes: bytes,
      contentType: contentType,
    );
    await _fileApi.completeUpload(upload.fileId);
    return upload.fileId;
  }

  void _retake() {
    setState(() {
      _selectedFile = null;
      _selectedKind = null;
      _errorMessage = null;
    });
  }

  Future<void> _close() async {
    if (_recording) {
      try {
        await _cameraController?.stopVideoRecording();
      } catch (_) {
        // Best-effort cleanup before closing.
      }
    }
    if (!mounted) return;

    if (await Navigator.of(context).maybePop()) {
      return;
    }
    if (!mounted) return;

    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _selectedFile;
    final kind = _selectedKind;
    return Scaffold(
      key: const ValueKey('story-capture-screen'),
      backgroundColor: Colors.black,
      body: file == null || kind == null
          ? _buildCameraBody(context)
          : _buildPreviewBody(context, file, kind),
    );
  }

  Widget _buildCameraBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _cameraController;
    final initialized =
        controller != null && controller.value.isInitialized && !_loadingCamera;

    return Stack(
      children: [
        Positioned.fill(
          child: initialized
              ? _StoryCameraPreview(controller: controller)
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
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
                    Colors.black.withValues(alpha: 0.66),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.76),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    _CaptureIconButton(
                      icon: Icons.close_rounded,
                      label: l10n.storyCaptureCloseLabel,
                      onPressed: _publishing ? null : () => unawaited(_close()),
                    ),
                    Expanded(
                      child: Text(
                        l10n.storyCaptureTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    _CaptureIconButton(
                      icon: _flashIconForMode(_flashMode),
                      label: _flashLabelForMode(l10n, _flashMode),
                      onPressed: initialized && !_cameraBusy && !_recording
                          ? () => unawaited(_cycleFlashMode())
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Spacer(),
                if (_recording)
                  _RecordingPill(duration: _recordingDuration)
                else if (_errorMessage != null)
                  _CaptureErrorPill(message: _errorMessage!),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CaptureModeButton(
                      selected: _mode == _StoryCaptureMode.photo,
                      label: l10n.storyCapturePhotoMode,
                      onTap: () => unawaited(_setMode(_StoryCaptureMode.photo)),
                    ),
                    _CaptureModeButton(
                      selected: _mode == _StoryCaptureMode.video,
                      label: l10n.storyCaptureVideoMode,
                      onTap: () => unawaited(_setMode(_StoryCaptureMode.video)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GalleryButton(
                      label: l10n.storyCaptureGalleryAction,
                      onPressed: () => unawaited(_showGallerySourceSheet()),
                    ),
                    _CaptureButton(
                      recording: _recording,
                      busy: _cameraBusy,
                      videoMode: _mode == _StoryCaptureMode.video,
                      onPressed: initialized
                          ? () => unawaited(_capture())
                          : null,
                      photoLabel: l10n.storyCaptureCaptureButtonLabel,
                      recordLabel: l10n.storyCaptureRecordButtonLabel,
                      stopLabel: l10n.storyCaptureStopButtonLabel,
                    ),
                    _CaptureIconButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: l10n.storyCaptureFlipCameraLabel,
                      onPressed:
                          _cameras.length > 1 && !_cameraBusy && !_recording
                          ? () => unawaited(_flipCamera())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBody(
    BuildContext context,
    XFile file,
    _StoryCaptureMediaKind kind,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: _StoryCapturePreview(file: file, kind: kind),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    _CaptureIconButton(
                      icon: Icons.close_rounded,
                      label: l10n.storyCaptureCloseLabel,
                      onPressed: _publishing ? null : () => unawaited(_close()),
                    ),
                    Expanded(
                      child: Text(
                        l10n.storyCapturePreviewTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),
                if (_errorMessage != null) ...[
                  _CaptureErrorPill(message: _errorMessage!),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _captionController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.storyCaptureCaptionHint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stackActions =
                        constraints.maxWidth < 360 || textScale > 1.18;
                    final retakeButton = OutlinedButton.icon(
                      onPressed: _publishing ? null : _retake,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        l10n.storyCaptureRetakeAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    final publishButton = FilledButton.icon(
                      onPressed: _publishing
                          ? null
                          : () => unawaited(_publish()),
                      icon: _publishing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF211307),
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _publishing
                            ? l10n.storyCapturePublishing
                            : l10n.storyCapturePublishAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );

                    if (stackActions) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          retakeButton,
                          const SizedBox(height: 10),
                          publishButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: retakeButton),
                        const SizedBox(width: 12),
                        Expanded(child: publishButton),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _cameraErrorLabel(BuildContext context, CameraException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' ||
      'AudioAccessDenied' ||
      'AudioAccessDeniedWithoutPrompt' ||
      'AudioAccessRestricted' => l10n.storyCapturePermissionDenied,
      _ => l10n.storyCaptureCaptureFailed,
    };
  }
}

class _StoryCameraPreview extends StatelessWidget {
  const _StoryCameraPreview({required this.controller});

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

class _StoryCapturePreview extends StatefulWidget {
  const _StoryCapturePreview({required this.file, required this.kind});

  final XFile file;
  final _StoryCaptureMediaKind kind;

  @override
  State<_StoryCapturePreview> createState() => _StoryCapturePreviewState();
}

class _StoryCapturePreviewState extends State<_StoryCapturePreview> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.kind == _StoryCaptureMediaKind.video) {
      unawaited(_initializeVideo());
    }
  }

  @override
  void didUpdateWidget(covariant _StoryCapturePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.kind != widget.kind) {
      unawaited(_videoController?.dispose());
      _videoController = null;
      if (widget.kind == _StoryCaptureMediaKind.video) {
        unawaited(_initializeVideo());
      }
    }
  }

  @override
  void dispose() {
    unawaited(_videoController?.dispose());
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.file(File(widget.file.path));
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      if (mounted && _videoController == controller) {
        setState(() => _videoController = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == _StoryCaptureMediaKind.photo) {
      return Image.file(File(widget.file.path), fit: BoxFit.cover);
    }

    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    );
  }
}

class _CaptureIconButton extends StatelessWidget {
  const _CaptureIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.32),
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.36),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _CaptureModeButton extends StatelessWidget {
  const _CaptureModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w800,
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
    required this.onPressed,
    required this.photoLabel,
    required this.recordLabel,
    required this.stopLabel,
  });

  final bool recording;
  final bool busy;
  final bool videoMode;
  final VoidCallback? onPressed;
  final String photoLabel;
  final String recordLabel;
  final String stopLabel;

  @override
  Widget build(BuildContext context) {
    final label = videoMode
        ? (recording ? stopLabel : recordLabel)
        : photoLabel;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: videoMode
                  ? (recording ? AppColors.destructive : Colors.redAccent)
                  : Colors.white,
              shape: recording ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: recording ? BorderRadius.circular(8) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.36),
          foregroundColor: Colors.white,
          minimumSize: const Size.square(52),
        ),
        icon: const Icon(Icons.photo_library_rounded),
      ),
    );
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          '$minutes:$seconds',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CaptureErrorPill extends StatelessWidget {
  const _CaptureErrorPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A180E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.34),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StoryCaptureSheetTile extends StatelessWidget {
  const _StoryCaptureSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.white.withValues(alpha: 0.08),
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _contentTypeForFile(XFile file, _StoryCaptureMediaKind kind) {
  final mime = file.mimeType?.trim();
  if (mime != null && mime.isNotEmpty) {
    return mime;
  }

  final name = _fileNameFor(file, kind).toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.heic')) return 'image/heic';
  if (name.endsWith('.heif')) return 'image/heif';
  if (name.endsWith('.mov')) return 'video/quicktime';
  if (name.endsWith('.webm')) return 'video/webm';
  if (name.endsWith('.m4v')) return 'video/x-m4v';
  if (name.endsWith('.mp4')) return 'video/mp4';
  return kind == _StoryCaptureMediaKind.video ? 'video/mp4' : 'image/jpeg';
}

String _fileNameFor(XFile file, _StoryCaptureMediaKind kind) {
  final name = file.name.trim();
  if (name.isNotEmpty) return name;
  final path = file.path.trim();
  if (path.isNotEmpty) {
    final slash = math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    if (slash >= 0 && slash < path.length - 1) {
      return path.substring(slash + 1);
    }
  }
  return kind == _StoryCaptureMediaKind.video ? 'story.mp4' : 'story.jpg';
}

FlashMode _cameraFlashModeFor(
  _StoryFlashMode flashMode,
  _StoryCaptureMode captureMode,
) {
  return switch (flashMode) {
    _StoryFlashMode.off => FlashMode.off,
    _StoryFlashMode.auto =>
      captureMode == _StoryCaptureMode.video ? FlashMode.off : FlashMode.auto,
    _StoryFlashMode.on =>
      captureMode == _StoryCaptureMode.video
          ? FlashMode.torch
          : FlashMode.always,
  };
}

IconData _flashIconForMode(_StoryFlashMode flashMode) {
  return switch (flashMode) {
    _StoryFlashMode.off => Icons.flash_off_rounded,
    _StoryFlashMode.auto => Icons.flash_auto_rounded,
    _StoryFlashMode.on => Icons.flash_on_rounded,
  };
}

String _flashLabelForMode(AppLocalizations l10n, _StoryFlashMode flashMode) {
  return switch (flashMode) {
    _StoryFlashMode.off => l10n.storyCaptureFlashOffLabel,
    _StoryFlashMode.auto => l10n.storyCaptureFlashAutoLabel,
    _StoryFlashMode.on => l10n.storyCaptureFlashOnLabel,
  };
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
