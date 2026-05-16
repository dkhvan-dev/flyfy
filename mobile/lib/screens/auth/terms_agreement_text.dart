import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/ui/app_colors.dart';

class TermsAgreementRichText extends StatelessWidget {
  const TermsAgreementRichText({
    super.key,
    required this.text,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final String text;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: AppColors.textCaption,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );

    final linkStyle = TextStyle(
      color: AppColors.accent,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accent.withValues(alpha: 0.3),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: _buildSpans(
          text,
          linkStyle: linkStyle,
          onTermsTap: onTermsTap,
          onPrivacyTap: onPrivacyTap,
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans(
    String text, {
    required TextStyle linkStyle,
    required VoidCallback onTermsTap,
    required VoidCallback onPrivacyTap,
  }) {
    final spans = <InlineSpan>[];

    final pattern = RegExp(r'<(terms|privacy)>(.*?)</\1>');
    int currentIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      final tag = match.group(1)!;
      final content = match.group(2)!;

      spans.add(
        TextSpan(
          text: content,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = tag == 'terms' ? onTermsTap : onPrivacyTap,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
  }
}
