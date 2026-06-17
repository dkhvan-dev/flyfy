import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/chat/models/sticker_pack_vm.dart';

void main() {
  test(
    'StickerVm displayFileId prefers preview, then fallback, then original',
    () {
      expect(
        const StickerVm(
          id: 'sticker-1',
          packId: 'pack-1',
          fileId: 'original-file',
          fallbackFileId: 'fallback-file',
          previewFileId: 'preview-file',
          status: 'active',
        ).displayFileId,
        'preview-file',
      );

      expect(
        const StickerVm(
          id: 'sticker-2',
          packId: 'pack-1',
          fileId: 'original-file',
          fallbackFileId: 'fallback-file',
          status: 'active',
        ).displayFileId,
        'fallback-file',
      );

      expect(
        const StickerVm(
          id: 'sticker-3',
          packId: 'pack-1',
          fileId: 'original-file',
          status: 'active',
        ).displayFileId,
        'original-file',
      );
    },
  );
}
