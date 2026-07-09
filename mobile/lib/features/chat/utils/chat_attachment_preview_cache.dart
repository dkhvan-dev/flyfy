import 'dart:typed_data';

import '../../../core/files/chat_file_cache.dart';
import '../../../core/network/file_api.dart';

class ChatAttachmentPreviewData {
  const ChatAttachmentPreviewData({
    required this.fileId,
    this.metadata,
    this.imageBytes,
    this.downloaded = false,
  });

  final String fileId;
  final FileMetadataVm? metadata;
  final Uint8List? imageBytes;
  final bool downloaded;

  ChatAttachmentPreviewData copyWith({
    FileMetadataVm? metadata,
    Uint8List? imageBytes,
    bool? downloaded,
  }) {
    return ChatAttachmentPreviewData(
      fileId: fileId,
      metadata: metadata ?? this.metadata,
      imageBytes: imageBytes ?? this.imageBytes,
      downloaded: downloaded ?? this.downloaded,
    );
  }
}

class ChatAttachmentPreviewCache {
  ChatAttachmentPreviewCache._();

  static final _fileApi = FileApi();
  static final _fileCache = ChatFileCache();
  static final Map<String, ChatAttachmentPreviewData> _previewByFileId = {};
  static final Map<String, Future<ChatAttachmentPreviewData>> _previewFutures =
      {};

  static ChatAttachmentPreviewData? peek(String fileId) {
    final normalized = _normalize(fileId);
    if (normalized.isEmpty) return null;
    return _previewByFileId[normalized];
  }

  static Future<ChatAttachmentPreviewData> load(String fileId) {
    final normalized = _normalize(fileId);
    if (normalized.isEmpty) {
      return Future.value(const ChatAttachmentPreviewData(fileId: ''));
    }

    final cached = _previewByFileId[normalized];
    if (cached != null) return Future.value(cached);

    final existing = _previewFutures[normalized];
    if (existing != null) return existing;

    final load = _fetch(normalized);
    _previewFutures[normalized] = load;
    return load;
  }

  static Future<List<ChatAttachmentPreviewData>> loadMany(
    Iterable<String> fileIds,
  ) async {
    final normalized = _normalizedUnique(fileIds);
    if (normalized.isEmpty) return const [];
    return Future.wait(normalized.map(load));
  }

  static Future<void> preload(
    Iterable<String> fileIds, {
    required int limit,
    required int concurrency,
  }) async {
    final normalized = _normalizedUnique(fileIds).take(limit).toList();
    if (normalized.isEmpty) return;

    var nextIndex = 0;
    final safeConcurrency = concurrency < 1 ? 1 : concurrency;
    final workerCount = normalized.length < safeConcurrency
        ? normalized.length
        : safeConcurrency;

    await Future.wait(
      List.generate(workerCount, (_) async {
        while (nextIndex < normalized.length) {
          final fileId = normalized[nextIndex];
          nextIndex += 1;
          await load(fileId);
        }
      }),
    );
  }

  static void rememberDownloaded(
    String fileId, {
    FileMetadataVm? metadata,
    Uint8List? imageBytes,
  }) {
    final normalized = _normalize(fileId);
    if (normalized.isEmpty) return;

    final current = _previewByFileId[normalized];
    _previewByFileId[normalized] = ChatAttachmentPreviewData(
      fileId: normalized,
      metadata: metadata ?? current?.metadata,
      imageBytes: imageBytes ?? current?.imageBytes,
      downloaded: true,
    );
  }

  static Future<ChatAttachmentPreviewData> _fetch(String fileId) async {
    FileMetadataVm? metadata;
    Uint8List? imageBytes;
    var downloaded = false;

    try {
      metadata = await _fileApi.getFileMetadata(fileId);
      final localFile = await _fileCache.downloadedFile(
        fileId,
        metadata: metadata,
      );
      downloaded = localFile != null;

      if (metadata.isImage && localFile != null) {
        imageBytes = await localFile.file.readAsBytes();
      } else if (metadata.isImage) {
        final content = await _fileApi.downloadContent(fileId);
        imageBytes = content.bytes.isEmpty ? null : content.bytes;
      }
    } catch (_) {
      final fallback = ChatAttachmentPreviewData(fileId: fileId);
      _previewFutures.remove(fileId);
      return fallback;
    }

    final preview = ChatAttachmentPreviewData(
      fileId: fileId,
      metadata: metadata,
      imageBytes: imageBytes,
      downloaded: downloaded,
    );
    _previewByFileId[fileId] = preview;
    return preview;
  }

  static List<String> _normalizedUnique(Iterable<String> fileIds) {
    final result = <String>[];
    final seen = <String>{};
    for (final fileId in fileIds) {
      final normalized = _normalize(fileId);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      result.add(normalized);
    }
    return result;
  }

  static String _normalize(String fileId) => fileId.trim();
}
