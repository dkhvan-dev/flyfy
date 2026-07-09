import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'app_file_opener.dart';
import '../network/file_api.dart';

typedef ChatFileDownloadProgressCallback =
    void Function(int receivedBytes, int totalBytes);

class ChatDownloadedFile {
  const ChatDownloadedFile({required this.file, required this.metadata});

  final File file;
  final FileMetadataVm? metadata;
}

class ChatFileCache {
  ChatFileCache({FileApi? fileApi, AppFileOpener? fileOpener})
    : _fileApi = fileApi ?? FileApi(),
      _fileOpener = fileOpener ?? AppFileOpener();

  final FileApi _fileApi;
  final AppFileOpener _fileOpener;

  Future<bool> isDownloaded(String fileId, {FileMetadataVm? metadata}) async {
    final file = await downloadedFile(fileId, metadata: metadata);
    return file != null;
  }

  Future<ChatDownloadedFile?> downloadedFile(
    String fileId, {
    FileMetadataVm? metadata,
  }) async {
    final normalizedId = fileId.trim();
    if (normalizedId.isEmpty) return null;

    final dir = await _downloadsDir();
    final direct = File(
      '${dir.path}/${_localFileName(normalizedId, metadata)}',
    );
    if (await direct.exists()) {
      return ChatDownloadedFile(file: direct, metadata: metadata);
    }

    final prefix = '${_safeSegment(normalizedId)}__';
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last;
      if (name.startsWith(prefix) && await entity.exists()) {
        return ChatDownloadedFile(file: entity, metadata: metadata);
      }
    }

    return null;
  }

  Future<ChatDownloadedFile> download(
    String fileId, {
    FileMetadataVm? metadata,
    CancelToken? cancelToken,
    ChatFileDownloadProgressCallback? onReceiveProgress,
  }) async {
    final normalizedId = fileId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(fileId, 'fileId', 'File id is required');
    }

    metadata ??= await _safeMetadata(normalizedId);
    final existing = await downloadedFile(normalizedId, metadata: metadata);
    if (existing != null) return existing;

    final content = await _fileApi.downloadContent(
      normalizedId,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    if (content.bytes.isEmpty) {
      throw StateError('Downloaded file is empty');
    }

    return saveBytes(normalizedId, bytes: content.bytes, metadata: metadata);
  }

  Future<ChatDownloadedFile> saveBytes(
    String fileId, {
    required Uint8List bytes,
    FileMetadataVm? metadata,
  }) async {
    final normalizedId = fileId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(fileId, 'fileId', 'File id is required');
    }
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes.length, 'bytes', 'File is empty');
    }

    final dir = await _downloadsDir();
    final file = File('${dir.path}/${_localFileName(normalizedId, metadata)}');
    await file.writeAsBytes(bytes, flush: true);
    return ChatDownloadedFile(file: file, metadata: metadata);
  }

  Future<AppFileOpenResult> open(ChatDownloadedFile downloaded) {
    final type = downloaded.metadata?.effectiveContentType.trim() ?? '';
    return _fileOpener.open(
      downloaded.file.path,
      contentType: type.isEmpty ? null : type,
    );
  }

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/chat_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<FileMetadataVm?> _safeMetadata(String fileId) async {
    try {
      return await _fileApi.getFileMetadata(fileId);
    } catch (_) {
      return null;
    }
  }
}

String _localFileName(String fileId, FileMetadataVm? metadata) {
  final originalName = metadata?.originalName.trim() ?? '';
  final fallbackName = 'file_${_shortId(fileId)}${_extension(metadata)}';
  final safeName = _safeSegment(
    originalName.isEmpty ? fallbackName : originalName,
  );
  return '${_safeSegment(fileId)}__$safeName';
}

String _extension(FileMetadataVm? metadata) {
  final raw = metadata?.extension?.trim() ?? '';
  if (raw.isEmpty) return '';
  return raw.startsWith('.') ? raw : '.$raw';
}

String _safeSegment(String value) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[/\\:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), ' ');
  return safe.isEmpty ? 'file' : safe;
}

String _shortId(String id) {
  final value = id.trim();
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
