import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview close button dismisses capture instead of retaking media', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();
    final previewStart = source.indexOf('Widget _buildPreviewBody(');
    final previewEnd = source.indexOf('String _cameraErrorLabel', previewStart);
    expect(previewStart, isNonNegative);
    expect(previewEnd, greaterThan(previewStart));

    final previewSource = source.substring(previewStart, previewEnd);
    final closeButtonStart = previewSource.indexOf(
      'label: l10n.storyCaptureCloseLabel',
    );
    final previewTitleStart = previewSource.indexOf(
      'l10n.storyCapturePreviewTitle',
    );
    expect(closeButtonStart, isNonNegative);
    expect(previewTitleStart, greaterThan(closeButtonStart));

    final closeButtonSource = previewSource.substring(
      closeButtonStart,
      previewTitleStart,
    );
    expect(closeButtonSource, contains('unawaited(_close())'));
    expect(closeButtonSource, isNot(contains('_retake')));
  });

  test('capture close uses navigator pop fallback', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();
    final closeStart = source.indexOf('Future<void> _close() async');
    final buildStart = source.indexOf('@override\n  Widget build', closeStart);
    expect(closeStart, isNonNegative);
    expect(buildStart, greaterThan(closeStart));

    final closeSource = source.substring(closeStart, buildStart);
    expect(closeSource, contains('Navigator.of(context).maybePop()'));
    expect(closeSource, contains('GoRouter.maybeOf(context)'));
    expect(closeSource, contains('router.pop()'));
    expect(closeSource, contains("router.go('/feed')"));
  });

  test('story tools do not expose music, collage, or your reply actions', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();
    final cameraStart = source.indexOf('Widget _buildCameraBody(');
    final previewStart = source.indexOf(
      'Widget _buildPreviewBody(',
      cameraStart,
    );
    expect(cameraStart, isNonNegative);
    expect(previewStart, greaterThan(cameraStart));

    final cameraSource = source.substring(cameraStart, previewStart);
    expect(cameraSource, isNot(contains('storyCaptureYourReplyTool')));
    expect(cameraSource, isNot(contains('_pickAudioTrack()')));
    expect(cameraSource, isNot(contains('_pickCollageFromGallery()')));
    expect(cameraSource, isNot(contains('storyCaptureMusicTool')));
    expect(cameraSource, isNot(contains('storyCaptureCollageTool')));
  });

  test('story capture defaults flash off and exposes flash control', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('_StoryFlashMode _flashMode = _StoryFlashMode.off'),
    );
    expect(source, contains('Future<void> _cycleFlashMode() async'));
    expect(source, contains('await controller.setFlashMode('));
    expect(source, contains('storyCaptureFlashOffLabel'));
    expect(source, contains('storyCaptureFlashAutoLabel'));
    expect(source, contains('storyCaptureFlashOnLabel'));
  });

  test('story capture uses V2 colors only', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();

    expect(source, contains('app_design_system.dart'));
    expect(source, contains('AppDesignSystem.themeFor(context)'));
    expect(source, contains('AppDesignSystem.colorsFor(context)'));
    expect(source, contains('colors.primary'));
    expect(source, contains('colors.textPrimary'));
    expect(source, contains('colors.scrim'));
    expect(source, isNot(contains('AppPalette.')));
  });

  test('publish uploads only captured story media blocks', () {
    final source = File(
      'lib/screens/stories/story_capture_screen.dart',
    ).readAsStringSync();
    final publishStart = source.indexOf('Future<void> _publish() async');
    final retakeStart = source.indexOf('void _retake()', publishStart);
    expect(publishStart, isNonNegative);
    expect(retakeStart, greaterThan(publishStart));

    final publishSource = source.substring(publishStart, retakeStart);
    expect(publishSource, contains('_uploadStoryMedia'));
    expect(publishSource, isNot(contains('_uploadStoryAudio')));
    expect(publishSource, isNot(contains('galleryFileIds:')));
    expect(publishSource, isNot(contains('audioFileId:')));
    expect(source, isNot(contains("'type': 'audio'")));
    expect(source, isNot(contains("'type': 'gallery'")));
  });

  test(
    'capture publishes through story circle api instead of editor stories',
    () {
      final source = File(
        'lib/screens/stories/story_capture_screen.dart',
      ).readAsStringSync();
      final publishStart = source.indexOf('Future<void> _publish() async');
      final retakeStart = source.indexOf('void _retake()', publishStart);
      expect(publishStart, isNonNegative);
      expect(retakeStart, greaterThan(publishStart));

      final publishSource = source.substring(publishStart, retakeStart);
      expect(source, contains('StoryApi'));
      expect(publishSource, contains('_storyApi.createStory'));
      expect(publishSource, isNot(contains('SaveStoryRequest(')));
    },
  );

  test(
    'tray viewer renders reply composer without details, audio, or collage',
    () {
      final source = File(
        'lib/screens/stories/story_tray_viewer_screen.dart',
      ).readAsStringSync();

      expect(source, contains("ValueKey('story-sequence-reply-field')"));
      expect(source, contains('createDirectConversation'));
      expect(source, contains('storyReply: _storyReplyContext(story)'));
      expect(source, isNot(contains('story-sequence-open-details')));
      expect(source, isNot(contains('_StoryViewerCollage')));
      expect(source, isNot(contains('_StoryAudioOverlay')));
      expect(source, isNot(contains("package:just_audio/just_audio.dart")));
    },
  );
}
