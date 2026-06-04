import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';

void main() {
  test('sticker model preserves telegram tgs metadata', () {
    final sticker = StickerVm.fromJson({
      'id': 'sticker-id',
      'packId': 'pack-id',
      'slug': 'airport-sprint',
      'fileId': 'file-id',
      'fallbackFileId': 'fallback-file-id',
      'previewFileId': 'preview-file-id',
      'contentType': 'application/x-tgsticker',
      'width': 512,
      'height': 512,
      'durationMs': 1080,
      'emoji': '✈️',
      'keywords': ['travel', 'flight'],
      'status': 'ACTIVE',
    });

    expect(sticker.contentType, 'application/x-tgsticker');
    expect(sticker.fileId, 'file-id');
    expect(sticker.fallbackFileId, 'fallback-file-id');
    expect(sticker.previewFileId, 'preview-file-id');
    expect(sticker.width, 512);
    expect(sticker.height, 512);
    expect(sticker.durationMs, 1080);
  });

  test('sticker api does not expose custom sticker upload helpers', () async {
    final source = await File(
      'lib/core/network/sticker_api.dart',
    ).readAsString();

    expect(source, isNot(contains('createStickerUploadRequest')));
    expect(source, isNot(contains('finalizeStickerUpload')));
    expect(source, isNot(contains('StickerUploadRequestVm')));
  });
}
