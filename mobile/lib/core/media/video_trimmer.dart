import 'package:flutter/services.dart';

class VideoTrimmer {
  VideoTrimmer({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('flyfy/video_tools');

  final MethodChannel _channel;

  Future<String> trimVideoPath({
    required String inputPath,
    required Duration start,
    required Duration end,
  }) async {
    final normalizedPath = inputPath.trim();
    if (normalizedPath.isEmpty) {
      throw ArgumentError.value(inputPath, 'inputPath', 'Video path is empty');
    }
    if (end <= start) {
      throw ArgumentError.value(end, 'end', 'Trim end must be after start');
    }

    final outputPath = await _channel.invokeMethod<String>('trimVideo', {
      'inputPath': normalizedPath,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
    });
    if (outputPath == null || outputPath.trim().isEmpty) {
      throw StateError('Native video trimmer returned an empty path');
    }
    return outputPath;
  }
}
