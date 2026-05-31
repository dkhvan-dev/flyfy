import 'package:flutter/services.dart';

enum AppFileOpenStatus { done, noApp, fileNotFound, failed }

class AppFileOpenResult {
  const AppFileOpenResult({required this.status, this.message});

  final AppFileOpenStatus status;
  final String? message;

  bool get isDone => status == AppFileOpenStatus.done;
}

class AppFileOpener {
  AppFileOpener({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('inflap/file_opener');

  final MethodChannel _channel;

  Future<AppFileOpenResult> open(String path, {String? contentType}) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return const AppFileOpenResult(
        status: AppFileOpenStatus.fileNotFound,
        message: 'File path is empty',
      );
    }

    final normalizedContentType = contentType?.trim();
    try {
      final response = await _channel
          .invokeMapMethod<String, Object?>('openFile', <String, Object?>{
            'path': normalizedPath,
            'contentType':
                normalizedContentType == null || normalizedContentType.isEmpty
                ? null
                : normalizedContentType,
          });

      return AppFileOpenResult(
        status: _statusFrom(response?['status'] as String?),
        message: response?['message'] as String?,
      );
    } on PlatformException catch (error) {
      return AppFileOpenResult(
        status: AppFileOpenStatus.failed,
        message: error.message,
      );
    }
  }

  AppFileOpenStatus _statusFrom(String? rawStatus) {
    switch (rawStatus) {
      case 'done':
        return AppFileOpenStatus.done;
      case 'no_app':
        return AppFileOpenStatus.noApp;
      case 'file_not_found':
        return AppFileOpenStatus.fileNotFound;
      default:
        return AppFileOpenStatus.failed;
    }
  }
}
