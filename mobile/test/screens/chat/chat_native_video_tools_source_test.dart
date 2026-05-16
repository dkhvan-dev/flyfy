import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android video trimming writes tracks with separate extractors',
      () async {
    final source = await File(
      'android/app/src/main/kotlin/dev/dkhvan/flyfy/superapp/MainActivity.kt',
    ).readAsString();

    expect(source, contains('writeSelectedTrack'));
    expect(source, contains('val trackExtractor = MediaExtractor()'));
    expect(source, contains('trackExtractor.selectTrack(sourceTrackIndex)'));
    expect(source, contains('firstSampleTimeUs'));
    expect(source, contains('baseSampleTimeUs'));
    expect(source, contains('sampleTimeUs - baseSampleTimeUs'));
    expect(source, isNot(contains('sampleTimeUs - startUs')));
  });

  test('android video trimming uses a large direct sample buffer', () async {
    final source = await File(
      'android/app/src/main/kotlin/dev/dkhvan/flyfy/superapp/MainActivity.kt',
    ).readAsString();

    expect(source, contains('MIN_TRIM_SAMPLE_BUFFER_SIZE'));
    expect(source, contains('16 * 1024 * 1024'));
    expect(source, contains('ByteBuffer.allocateDirect(maxBufferSize)'));
    expect(source, contains('buffer.limit(sampleSize)'));
  });

  test('ios video trimming uses output extension matching export file type',
      () async {
    final source = await File('ios/Runner/AppDelegate.swift').readAsString();

    expect(source, contains('preferredOutputFileType'));
    expect(source, contains('outputExtension'));
    expect(source, contains('appendingPathComponent("flyfy_trimmed_'));
    expect(source, contains('AVFileType.mp4'));
  });

  test('ios video trimming clamps range and exports a composition', () async {
    final source = await File('ios/Runner/AppDelegate.swift').readAsString();

    expect(source, contains('clampedTrimTimeRange'));
    expect(source, contains('AVMutableComposition'));
    expect(source, contains('insertTimeRange'));
    expect(source, contains('compositionTimeRange'));
  });
}
