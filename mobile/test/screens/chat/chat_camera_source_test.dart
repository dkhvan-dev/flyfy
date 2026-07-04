import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'chat camera exposes device-like focus, flash, and zoom controls',
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
    },
  );

  test(
    'chat camera uses a less cropped preview cover scale for 1x zoom',
    () async {
      final source = await File(
        'lib/screens/chat/chat_camera_screen.dart',
      ).readAsString();

      expect(source, contains('_cameraPreviewCoverScale'));
      expect(source, contains('previewAspectRatio * screenAspectRatio'));
      expect(source, contains('math.max(1,'));
    },
  );

  test(
    'chat camera opens recorded video review before returning capture',
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
    },
  );

  test('recorded video review uses adaptive V2 colors directly', () async {
    final reviewSource = await File(
      'lib/screens/chat/chat_recorded_video_review_screen.dart',
    ).readAsString();

    expect(reviewSource, contains('app_design_system.dart'));
    expect(reviewSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(reviewSource, contains('colors.backgroundDeep'));
    expect(reviewSource, contains('colors.scrim'));
    expect(reviewSource, contains('colors.primary'));
    expect(reviewSource, contains('colors.secondary'));
    expect(reviewSource, contains('colors.borderSecondary'));
    expect(reviewSource, contains('colors.white'));
    expect(reviewSource, isNot(contains('AppPalette.')));
  });

  test(
    'recorded video trim metadata uses secondary without recoloring media controls',
    () async {
      final reviewSource = await File(
        'lib/screens/chat/chat_recorded_video_review_screen.dart',
      ).readAsString();
      final trimStart = reviewSource.indexOf('class _TrimRangeSelector');
      final buttonStart = reviewSource.indexOf('class _ReviewIconButton');

      expect(trimStart, isNonNegative);
      expect(buttonStart, greaterThan(trimStart));

      final trimSource = reviewSource.substring(trimStart, buttonStart);
      expect(trimSource, contains('colors.borderSecondary'));
      expect(trimSource, contains('color: colors.secondary'));
      expect(trimSource, contains('activeColor: colors.primary'));
      expect(trimSource, contains('inactiveColor: colors.white'));
    },
  );

  test('chat camera screen uses adaptive V2 colors directly', () async {
    final source = await File(
      'lib/screens/chat/chat_camera_screen.dart',
    ).readAsString();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.backgroundDeep'));
    expect(source, contains('colors.scrim'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.danger'));
    expect(source, contains('colors.white'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test(
    'chat camera configures smoother and clearer capture settings',
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
    },
  );
}
