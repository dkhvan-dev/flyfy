import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat composer does not expose a standalone sticker button', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('Icons.sticky_note_2_outlined')));
  });

  test('sticker warm-up uses the same asset cache as the grid', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('_StickerImageCache.preload'));
    expect(source, contains('displayFileId'));
    expect(source, isNot(contains('precacheImage(NetworkImage')));
  });

  test('chat sticker renderer supports telegram tgs assets', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains("package:lottie/lottie.dart"));
    expect(source, contains('resolveStickerAssetContentFormat'));
    expect(source, contains('Lottie.memory'));
    expect(source, contains('LottieComposition.decodeGZip'));
    expect(source, contains('RenderCache.drawingCommands'));
    expect(source, contains('FrameRate(60)'));
    expect(source, contains('downloadStickerContent'));
    expect(source, isNot(contains('FrameRate.max')));
  });

  test(
    'creating a custom sticker does not block on full pack reload',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      expect(source, isNot(contains('await _loadStickerPacks(force: true')));
    },
  );

  test('chat does not show a success popup after adding a sticker', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('chatStickerCreated')));
  });

  test('chat composer does not expose custom sticker creation', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('_CreateStickerButton')));
    expect(source, isNot(contains('_createCustomSticker')));
    expect(source, isNot(contains('_PastedImageAction.sendSticker')));
    expect(source, isNot(contains('chatPasteSendSticker')));
  });

  test(
    'inline sticker panel shows one combined grid without pack tabs',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      expect(source, contains('.expand((pack) => pack.stickers)'));
      expect(source, isNot(contains('class _StickerPackChip')));
      expect(source, isNot(contains('onPackSelected')));
    },
  );
}
