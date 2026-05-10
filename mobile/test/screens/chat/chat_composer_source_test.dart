import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat composer does not expose a standalone sticker button', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, isNot(contains('Icons.sticky_note_2_outlined')));
  });

  test('sticker warm-up uses the same byte cache as the grid', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    expect(source, contains('_StickerImageCache.preload'));
    expect(source, isNot(contains('precacheImage(NetworkImage')));
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
}
