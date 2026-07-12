import 'package:flutter/material.dart';

import 'app_design_system.dart';
import 'app_emoji_platform.dart' as platform;

const _emojiAssetRoot = 'assets/emoji/noto';
const _inlineEmojiScale = 1.08;

const _emojiAssetByGlyph = <String, String>{
  '😀': '$_emojiAssetRoot/emoji_u1f600.png',
  '😄': '$_emojiAssetRoot/emoji_u1f604.png',
  '😂': '$_emojiAssetRoot/emoji_u1f602.png',
  '😊': '$_emojiAssetRoot/emoji_u1f60a.png',
  '😍': '$_emojiAssetRoot/emoji_u1f60d.png',
  '😘': '$_emojiAssetRoot/emoji_u1f618.png',
  '😎': '$_emojiAssetRoot/emoji_u1f60e.png',
  '🥳': '$_emojiAssetRoot/emoji_u1f973.png',
  '😇': '$_emojiAssetRoot/emoji_u1f607.png',
  '🙂': '$_emojiAssetRoot/emoji_u1f642.png',
  '😉': '$_emojiAssetRoot/emoji_u1f609.png',
  '🤔': '$_emojiAssetRoot/emoji_u1f914.png',
  '😅': '$_emojiAssetRoot/emoji_u1f605.png',
  '😭': '$_emojiAssetRoot/emoji_u1f62d.png',
  '😤': '$_emojiAssetRoot/emoji_u1f624.png',
  '👍': '$_emojiAssetRoot/emoji_u1f44d.png',
  '🙏': '$_emojiAssetRoot/emoji_u1f64f.png',
  '👏': '$_emojiAssetRoot/emoji_u1f44f.png',
  '🔥': '$_emojiAssetRoot/emoji_u1f525.png',
  '❤': '$_emojiAssetRoot/emoji_u2764.png',
  '💛': '$_emojiAssetRoot/emoji_u1f49b.png',
  '✨': '$_emojiAssetRoot/emoji_u2728.png',
  '🎉': '$_emojiAssetRoot/emoji_u1f389.png',
  '✅': '$_emojiAssetRoot/emoji_u2705.png',
  '👀': '$_emojiAssetRoot/emoji_u1f440.png',
  '📍': '$_emojiAssetRoot/emoji_u1f4cd.png',
  '🧭': '$_emojiAssetRoot/emoji_u1f9ed.png',
  '✈': '$_emojiAssetRoot/emoji_u2708.png',
  '🏔': '$_emojiAssetRoot/emoji_u1f3d4.png',
  '🏝': '$_emojiAssetRoot/emoji_u1f3dd.png',
  '🌅': '$_emojiAssetRoot/emoji_u1f305.png',
  '🧳': '$_emojiAssetRoot/emoji_u1f9f3.png',
  '😮': '$_emojiAssetRoot/emoji_u1f62e.png',
  '😢': '$_emojiAssetRoot/emoji_u1f622.png',
};

TextStyle appEmojiCompatibleTextStyle(TextStyle style) {
  return resolveAppEmojiCompatibleTextStyle(
    style,
    requiresBundledFallback: platform.requiresBundledEmojiTextFallback,
  );
}

@visibleForTesting
TextStyle resolveAppEmojiCompatibleTextStyle(
  TextStyle style, {
  required bool requiresBundledFallback,
}) {
  final fallbacks = <String>{
    if (requiresBundledFallback) AppTypography.bundledEmojiFontFamily,
    if (requiresBundledFallback && style.fontFamily != null) style.fontFamily!,
    ...?style.fontFamilyFallback,
    ...AppTypography.emojiFontFallback,
  }.toList(growable: false);
  return style.copyWith(
    // Flutter's iOS 26 font fallback can route the whole text run through the
    // broken color-emoji font. Keeping normal text on an explicit iOS system
    // family lets only unsupported glyphs reach the bundled fallback.
    fontFamily: requiresBundledFallback ? 'Helvetica' : null,
    fontFamilyFallback: fallbacks,
  );
}

@immutable
class AppEmojiTextSegment {
  const AppEmojiTextSegment({required this.value, required this.isColorEmoji});

  final String value;
  final bool isColorEmoji;
}

List<AppEmojiTextSegment> splitAppEmojiText(String value) {
  if (value.isEmpty) return const [];

  final segments = <AppEmojiTextSegment>[];
  final plainText = StringBuffer();

  void flushPlainText() {
    if (plainText.isEmpty) return;
    segments.add(
      AppEmojiTextSegment(value: plainText.toString(), isColorEmoji: false),
    );
    plainText.clear();
  }

  for (final grapheme in value.characters) {
    if (_emojiAssetByGlyph.containsKey(_normalizeEmoji(grapheme))) {
      flushPlainText();
      segments.add(AppEmojiTextSegment(value: grapheme, isColorEmoji: true));
    } else {
      plainText.write(grapheme);
    }
  }
  flushPlainText();

  return List.unmodifiable(segments);
}

List<InlineSpan> appEmojiInlineSpans(
  BuildContext context,
  String value, {
  required TextStyle style,
}) {
  final segments = splitAppEmojiText(value);
  if (segments.isEmpty) return const [];

  final inheritedFontSize = DefaultTextStyle.of(context).style.fontSize;
  final fontSize = style.fontSize ?? inheritedFontSize ?? AppTypography.body;
  final emojiSize =
      MediaQuery.textScalerOf(context).scale(fontSize) * _inlineEmojiScale;

  return [
    for (final segment in segments)
      if (segment.isColorEmoji)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: AppEmoji(
            value: segment.value,
            size: emojiSize,
            semanticLabel: segment.value,
          ),
        )
      else
        TextSpan(text: segment.value),
  ];
}

class AppEmojiText extends StatelessWidget {
  const AppEmojiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = appEmojiCompatibleTextStyle(
      style ?? DefaultTextStyle.of(context).style,
    );
    final segments = splitAppEmojiText(data);
    final hasColorEmoji = segments.any((segment) => segment.isColorEmoji);

    if (!hasColorEmoji) {
      return Text(
        data,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }

    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: appEmojiInlineSpans(context, data, style: effectiveStyle),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

class AppEmojiEditingController extends TextEditingController {
  AppEmojiEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final segments = splitAppEmojiText(text);
    final hasColorEmoji = segments.any((segment) => segment.isColorEmoji);
    final composing = withComposing && _isValidComposingRange(value)
        ? value.composing
        : TextRange.empty;

    if (!hasColorEmoji && !composing.isValid) {
      return TextSpan(style: style, text: text);
    }

    final spans = <InlineSpan>[];
    var segmentStart = 0;
    for (final segment in segments) {
      final segmentEnd = segmentStart + segment.value.length;
      final boundaries = <int>{segmentStart, segmentEnd};
      if (composing.isValid) {
        if (composing.start > segmentStart && composing.start < segmentEnd) {
          boundaries.add(composing.start);
        }
        if (composing.end > segmentStart && composing.end < segmentEnd) {
          boundaries.add(composing.end);
        }
      }
      final sortedBoundaries = boundaries.toList()..sort();

      for (var index = 0; index < sortedBoundaries.length - 1; index++) {
        final start = sortedBoundaries[index];
        final end = sortedBoundaries[index + 1];
        final isComposing =
            composing.isValid &&
            start >= composing.start &&
            end <= composing.end;
        TextStyle? segmentStyle;
        if (segment.isColorEmoji) {
          segmentStyle = AppTextStyle(
            color: AppPalette.transparent,
            fontSize:
                (style?.fontSize ?? AppTypography.body) * _inlineEmojiScale,
          );
        }
        if (isComposing) {
          segmentStyle = (segmentStyle ?? const AppTextStyle()).merge(
            const AppTextStyle(decoration: TextDecoration.underline),
          );
        }
        spans.add(
          TextSpan(text: text.substring(start, end), style: segmentStyle),
        );
      }
      segmentStart = segmentEnd;
    }

    return TextSpan(style: style, children: spans);
  }
}

class AppEmojiEditingOverlay extends StatelessWidget {
  const AppEmojiEditingOverlay({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.style,
  });

  final TextEditingController controller;
  final ScrollController scrollController;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([controller, scrollController]),
          builder: (context, child) {
            final text = controller.text;
            final hasColorEmoji = splitAppEmojiText(
              text,
            ).any((segment) => segment.isColorEmoji);
            if (!hasColorEmoji) return const SizedBox.shrink();

            final horizontalOffset = scrollController.hasClients
                ? scrollController.offset
                : 0.0;
            return ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(-horizontalOffset, 0),
                  child: Text.rich(
                    TextSpan(
                      style: style.copyWith(color: AppPalette.transparent),
                      children: appEmojiInlineSpans(
                        context,
                        text,
                        style: style,
                      ),
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

bool _isValidComposingRange(TextEditingValue value) {
  final composing = value.composing;
  return composing.isValid &&
      composing.start >= 0 &&
      composing.end <= value.text.length;
}

class AppEmoji extends StatelessWidget {
  const AppEmoji({
    super.key,
    required this.value,
    required this.size,
    this.semanticLabel,
  });

  final String value;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalizeEmoji(value);
    final assetPath = _emojiAssetByGlyph[normalizedValue];

    return SizedBox.square(
      dimension: size,
      child: assetPath == null
          ? _EmojiFontFallback(
              value: value,
              size: size,
              semanticLabel: semanticLabel,
            )
          : Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
              errorBuilder: (context, error, stackTrace) => _EmojiFontFallback(
                value: value,
                size: size,
                semanticLabel: semanticLabel,
              ),
            ),
    );
  }
}

class _EmojiFontFallback extends StatelessWidget {
  const _EmojiFontFallback({
    required this.value,
    required this.size,
    required this.semanticLabel,
  });

  final String value;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: AppTypography.emojiStyle.copyWith(fontSize: size),
        ),
      ),
    );
  }
}

String _normalizeEmoji(String value) {
  return value.trim().replaceAll('\u{fe0e}', '').replaceAll('\u{fe0f}', '');
}
