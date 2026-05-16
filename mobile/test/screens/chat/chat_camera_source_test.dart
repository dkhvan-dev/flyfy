import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat camera exposes device-like focus, flash, and zoom controls',
      () async {
    final source = await File(
      'lib/screens/chat/chat_camera_screen.dart',
    ).readAsString();

    expect(source, contains('_toggleFlash'));
    expect(source, contains('setFlashMode'));
    expect(source, contains('_handlePreviewTapDown'));
    expect(source, contains('setFocusPoint'));
    expect(source, contains('setExposurePoint'));
    expect(source, contains('_ZoomLevelSelector'));
    expect(source, contains('_FocusReticle'));
  });

  test('chat camera uses a less cropped preview cover scale for 1x zoom',
      () async {
    final source = await File(
      'lib/screens/chat/chat_camera_screen.dart',
    ).readAsString();

    expect(source, contains('_cameraPreviewCoverScale'));
    expect(source, contains('previewAspectRatio * screenAspectRatio'));
    expect(source, contains('math.max(1,'));
  });

  test('chat camera opens recorded video review before returning capture',
      () async {
    final source = await File(
      'lib/screens/chat/chat_camera_screen.dart',
    ).readAsString();
    final reviewFile = File(
      'lib/screens/chat/chat_recorded_video_review_screen.dart',
    );

    expect(reviewFile.existsSync(), isTrue);
    final reviewSource = await reviewFile.readAsString();

    expect(source, contains('ChatRecordedVideoReviewScreen'));
    expect(source, contains('_reviewRecordedVideo'));
    expect(reviewSource, contains('class ChatRecordedVideoReviewScreen'));
    expect(reviewSource, contains('VideoPlayerController.file'));
    expect(reviewSource, contains('_TrimRangeSelector'));
    expect(reviewSource, contains('RangeSlider'));
  });

  test('chat camera configures smoother and clearer capture settings',
      () async {
    final source = await File(
      'lib/screens/chat/chat_camera_screen.dart',
    ).readAsString();

    expect(source, contains('_chatCameraResolutionPreset'));
    expect(source, contains('ResolutionPreset.veryHigh'));
    expect(source, contains('_chatCameraFps'));
    expect(source, contains('fps: _chatCameraFps'));
    expect(
      source,
      contains('videoBitrate: isVideoMode ? _chatCameraVideoBitrate : null'),
    );
    expect(
      source,
      contains('audioBitrate: isVideoMode ? _chatCameraAudioBitrate : null'),
    );
    expect(source, contains('_configureCameraForCapture'));
    expect(source, contains('setFocusMode(FocusMode.auto)'));
    expect(source, contains('setExposureMode(ExposureMode.auto)'));
  });
}
