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
    'chat composer text field does not draw a nested placeholder surface',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final composerStart = source.indexOf('class _ChatComposer');
      final panelStart = source.indexOf('class _InlineEmojiStickerPanel');

      expect(composerStart, isNonNegative);
      expect(panelStart, greaterThan(composerStart));

      final composerSource = source.substring(composerStart, panelStart);

      expect(composerSource, contains('decoration: AppInputDecoration('));
      expect(composerSource, contains('filled: false'));
      expect(
        composerSource,
        contains('fillColor: context.chatColors.transparent'),
      );
      expect(composerSource, contains('border: InputBorder.none'));
      expect(composerSource, contains('enabledBorder: InputBorder.none'));
      expect(composerSource, contains('focusedBorder: InputBorder.none'));
      expect(composerSource, contains('disabledBorder: InputBorder.none'));
      expect(composerSource, contains('errorBorder: InputBorder.none'));
      expect(composerSource, contains('focusedErrorBorder: InputBorder.none'));
    },
  );

  test('chat light theme composer and header use visible V2 chrome', () async {
    final source = await File(
      'lib/screens/chat/chat_screen.dart',
    ).readAsString();

    final colorsStart = source.indexOf('final class _ChatColors');
    final colorsEnd = source.indexOf('extension _ChatColorContext');
    final topBarStart = source.indexOf('class _ChatTopBar');
    final directActionsStart = source.indexOf('class _DirectActionsButton');
    final composerStart = source.indexOf('class _ChatComposer');
    final panelStart = source.indexOf('class _InlineEmojiStickerPanel');
    final actionStart = source.indexOf('class _ComposerActionButtonSurface');
    final voiceLockStart = source.indexOf('class _VoiceLockHint');
    final circleStart = source.indexOf('class _ComposerCircleButton');

    expect(colorsStart, isNonNegative);
    expect(colorsEnd, greaterThan(colorsStart));
    expect(topBarStart, isNonNegative);
    expect(directActionsStart, greaterThan(topBarStart));
    expect(composerStart, isNonNegative);
    expect(panelStart, greaterThan(composerStart));
    expect(actionStart, isNonNegative);
    expect(voiceLockStart, greaterThan(actionStart));
    expect(circleStart, isNonNegative);

    final colorsSource = source.substring(colorsStart, colorsEnd);
    final topBarSource = source.substring(topBarStart, directActionsStart);
    final composerSource = source.substring(composerStart, panelStart);
    final actionSource = source.substring(actionStart, voiceLockStart);
    final circleSource = source.substring(circleStart);

    expect(colorsSource, contains('Color get headerBorder => colors.border'));
    expect(
      colorsSource,
      contains('Color get headerIcon => colors.textPrimary'),
    );
    expect(
      colorsSource,
      contains('Color get composerSurface => colors.surface'),
    );
    expect(colorsSource, contains('Color get composerBorder => colors.border'));
    expect(
      colorsSource,
      contains('Color get composerFieldSurface => colors.surfaceRaised'),
    );
    expect(
      colorsSource,
      contains('Color get composerFieldBorder => colors.border'),
    );
    expect(
      colorsSource,
      contains('Color get composerControlSurface => colors.surfaceRaised'),
    );
    expect(
      colorsSource,
      contains('Color get composerControlIcon => colors.primary'),
    );
    expect(
      colorsSource,
      contains('Color get composerHintText => colors.textMuted'),
    );
    expect(
      colorsSource,
      contains('Color get actionOnPrimary => colors.textPrimary'),
    );
    expect(source, contains('List<BoxShadow>? _chatDarkThemeShadow('));
    expect(
      source,
      contains('if (Theme.of(context).brightness == Brightness.light)'),
    );

    expect(topBarSource, contains('context.chatColors.headerBorder'));
    expect(topBarSource, contains('context.chatColors.headerIcon'));
    expect(topBarSource, isNot(contains('context.chatColors.white')));

    expect(composerSource, contains('context.chatColors.composerSurface'));
    expect(composerSource, contains('context.chatColors.composerBorder'));
    expect(composerSource, contains('context.chatColors.composerFieldSurface'));
    expect(composerSource, contains('context.chatColors.composerFieldBorder'));
    expect(composerSource, contains('context.chatColors.composerHintText'));
    expect(composerSource, isNot(contains('white.withValues(alpha: 0.03)')));
    expect(composerSource, isNot(contains('white.withValues(alpha: 0.48)')));
    expect(composerSource, isNot(contains('white.withValues(alpha: 0.72)')));

    expect(actionSource, contains('boxShadow: _chatDarkThemeShadow('));
    expect(actionSource, contains('context.chatColors.actionOnPrimary'));
    expect(circleSource, contains('context.chatColors.composerControlSurface'));
    expect(circleSource, contains('context.chatColors.composerControlBorder'));
    expect(circleSource, contains('context.chatColors.composerControlIcon'));
    expect(circleSource, contains('boxShadow: _chatDarkThemeShadow('));
    expect(circleSource, isNot(contains('white.withValues(alpha: disabled')));
  });

  test(
    'chat camera and voice composer buttons share the same size token',
    () async {
      final source = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();

      final composerStart = source.indexOf('class _ChatComposer');
      final panelStart = source.indexOf('class _InlineEmojiStickerPanel');
      expect(composerStart, isNonNegative);
      expect(panelStart, greaterThan(composerStart));

      final composerSource = source.substring(composerStart, panelStart);
      final cameraStart = composerSource.indexOf(
        'icon: Icons.camera_alt_rounded',
      );
      final voiceStart = composerSource.indexOf('_VoiceGestureButton(');

      expect(cameraStart, isNonNegative);
      expect(voiceStart, greaterThan(cameraStart));
      expect(
        composerSource.substring(cameraStart - 120, cameraStart + 220),
        contains('size: btnSize'),
      );
      expect(
        composerSource.substring(voiceStart, voiceStart + 220),
        contains('size: btnSize'),
      );
      expect(composerSource, isNot(contains('size: btnSize +')));
      expect(composerSource, isNot(contains('size: _scale(context, 46)')));
    },
  );

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
