import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_emoji.dart';
import 'package:inflap/core/ui/app_emoji_platform_io.dart';

void main() {
  testWidgets('renders a bundled color asset for a supported emoji', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: AppEmoji(value: '😀', size: 28)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/emoji/noto/emoji_u1f600.png');
    expect(tester.getSize(find.byType(AppEmoji)), const Size.square(28));
  });

  testWidgets('normalizes emoji presentation selectors for asset lookup', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: AppEmoji(value: '❤️', size: 24)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/emoji/noto/emoji_u2764.png');
  });

  testWidgets('uses the bundled font for an emoji without a color asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: AppEmoji(value: '🫠', size: 24)),
      ),
    );

    final text = tester.widget<Text>(find.text('🫠'));

    expect(text.style?.fontFamily, AppTypography.bundledEmojiFontFamily);
    expect(find.byType(Image), findsNothing);
  });

  test('splits supported emoji without breaking grapheme clusters', () {
    final segments = splitAppEmojiText('Привет 😭 и ❤️!');

    expect(
      segments.map((segment) => segment.value),
      orderedEquals(['Привет ', '😭', ' и ', '❤️', '!']),
    );
    expect(
      segments.map((segment) => segment.isColorEmoji),
      orderedEquals([false, true, false, true, false]),
    );
  });

  test('keeps an unsupported compound emoji in the text fallback', () {
    const value = 'Семья 👨‍👩‍👧‍👦';

    final segments = splitAppEmojiText(value);

    expect(segments, hasLength(1));
    expect(segments.single.value, value);
    expect(segments.single.isColorEmoji, isFalse);
  });

  testWidgets('renders emoji-only messages with bundled color assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AppEmojiText('😭😂', style: TextStyle(fontSize: 18)),
        ),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);

    expect(
      assetNames,
      orderedEquals([
        'assets/emoji/noto/emoji_u1f62d.png',
        'assets/emoji/noto/emoji_u1f602.png',
      ]),
    );
  });

  testWidgets('keeps ordinary message text in a text span', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AppEmojiText('Привет 😭!', style: TextStyle(fontSize: 18)),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(AppEmojiText),
        matching: find.byType(Text),
      ),
    );
    final rootSpan = text.textSpan! as TextSpan;

    expect(rootSpan.children, hasLength(3));
    expect(rootSpan.children!.first, isA<TextSpan>());
    expect(rootSpan.children![1], isA<WidgetSpan>());
    expect(rootSpan.children!.last, isA<TextSpan>());
  });

  testWidgets('editing controller hides only supported emoji glyphs', (
    tester,
  ) async {
    final controller = AppEmojiEditingController(text: 'Текст 😍!');
    addTearDown(controller.dispose);
    late TextSpan span;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            span = controller.buildTextSpan(
              context: context,
              style: const TextStyle(fontSize: 15, color: Colors.white),
              withComposing: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(span.toPlainText(), controller.text);
    expect(span.children, hasLength(3));
    expect((span.children![0] as TextSpan).style, isNull);
    expect((span.children![1] as TextSpan).style?.color, Colors.transparent);
    expect((span.children![2] as TextSpan).style, isNull);
  });

  testWidgets('editing controller preserves composing range styling', (
    tester,
  ) async {
    final controller = AppEmojiEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: 'Текст 😍',
      selection: TextSelection.collapsed(offset: 7),
      composing: TextRange(start: 0, end: 5),
    );
    late TextSpan span;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            span = controller.buildTextSpan(
              context: context,
              style: const TextStyle(fontSize: 15, color: Colors.white),
              withComposing: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(span.toPlainText(), controller.text);
    expect(
      (span.children!.first as TextSpan).style?.decoration,
      TextDecoration.underline,
    );
    expect((span.children!.last as TextSpan).style?.color, Colors.transparent);
  });

  testWidgets('editing overlay paints color emoji assets', (tester) async {
    final controller = AppEmojiEditingController(text: '😍😘');
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            height: 42,
            child: AppEmojiEditingOverlay(
              controller: controller,
              scrollController: scrollController,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(
      assetNames,
      orderedEquals([
        'assets/emoji/noto/emoji_u1f60d.png',
        'assets/emoji/noto/emoji_u1f618.png',
      ]),
    );

    controller.text = 'Обычный текст';
    await tester.pump();
    expect(find.byType(Image), findsNothing);
  });

  test('extracts the iOS major version from runtime descriptions', () {
    expect(parseOperatingSystemMajorVersion('Version 26.3 (Build 23D127)'), 26);
    expect(parseOperatingSystemMajorVersion('iOS 17.2'), 17);
    expect(parseOperatingSystemMajorVersion('unknown'), isNull);
  });

  test('normal platforms keep the requested text family', () {
    const original = TextStyle(fontFamily: 'Inter');

    final resolved = resolveAppEmojiCompatibleTextStyle(
      original,
      requiresBundledFallback: false,
    );

    expect(resolved.fontFamily, 'Inter');
  });

  test('affected iOS versions isolate text from the emoji fallback', () {
    const original = TextStyle(fontFamily: 'Inter');

    final resolved = resolveAppEmojiCompatibleTextStyle(
      original,
      requiresBundledFallback: true,
    );

    expect(resolved.fontFamily, 'Helvetica');
    expect(
      resolved.fontFamilyFallback?.take(2),
      orderedEquals([AppTypography.bundledEmojiFontFamily, 'Inter']),
    );
  });
}
