import 'package:flutter/services.dart';

class ClipboardMediaItem {
  const ClipboardMediaItem({
    required this.bytes,
    required this.contentType,
    required this.name,
  });

  final Uint8List bytes;
  final String contentType;
  final String name;

  bool get isImage => contentType.toLowerCase().startsWith('image/');
}

class ClipboardMediaService {
  ClipboardMediaService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'flyfy/clipboard_media';

  final MethodChannel _channel;

  Future<ClipboardMediaItem?> readImage() async {
    final result = await _channel.invokeMapMethod<String, Object?>('readImage');
    if (result == null) {
      return null;
    }

    final rawBytes = result['bytes'];
    final contentType = result['contentType']?.toString().trim() ?? '';
    final name = result['name']?.toString().trim() ?? '';
    if (rawBytes is! Uint8List ||
        rawBytes.isEmpty ||
        !contentType.toLowerCase().startsWith('image/')) {
      return null;
    }

    return ClipboardMediaItem(
      bytes: rawBytes,
      contentType: contentType,
      name: name.isEmpty ? _fallbackName(contentType) : name,
    );
  }

  static String _fallbackName(String contentType) {
    final ext = switch (contentType.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'img',
    };
    return 'clipboard_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }
}
