import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/help_center_api.dart';

typedef HelpArticleActionCallback =
    void Function(HelpArticleVm article, HelpArticleActionVm action);

class HelpArticleTile extends StatelessWidget {
  const HelpArticleTile({
    super.key,
    required this.article,
    required this.onActionSelected,
    this.onFeedback,
    this.selectedFeedback,
    this.isFeedbackSubmitting = false,
    this.initiallyExpanded = false,
    this.compact = false,
  });

  final HelpArticleVm article;
  final HelpArticleActionCallback onActionSelected;
  final ValueChanged<bool>? onFeedback;
  final bool? selectedFeedback;
  final bool isFeedbackSubmitting;
  final bool initiallyExpanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textScale = MediaQuery.textScalerOf(context);
    final titleStyle = AppTextStyle(
      color: AppPalette.textPrimary,
      fontSize: compact ? 15 : 16,
      fontWeight: FontWeight.w800,
      height: 1.22,
      letterSpacing: 0,
    );
    final bodyStyle = AppTextStyle(
      color: AppPalette.textCoolSecondary,
      fontSize: compact ? 13 : 14,
      height: 1.4,
      letterSpacing: 0,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: AppPalette.transparent,
        splashColor: AppPalette.primary.withValues(alpha: 0.08),
        highlightColor: AppPalette.primary.withValues(alpha: 0.06),
      ),
      child: Material(
        color: AppPalette.white.withValues(alpha: compact ? 0.04 : 0.055),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(14),
          side: BorderSide(color: AppPalette.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('help-article-${article.id}'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: AppEdgeInsets.fromLTRB(
            compact ? 14 : 16,
            compact ? 8 : 10,
            compact ? 10 : 12,
            compact ? 8 : 10,
          ),
          childrenPadding: AppEdgeInsets.fromLTRB(
            compact ? 14 : 16,
            0,
            compact ? 14 : 16,
            compact ? 14 : 16,
          ),
          iconColor: AppPalette.primary,
          collapsedIconColor: AppPalette.textCoolSecondary,
          title: Text(
            article.title,
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            textScaler: textScale.clamp(maxScaleFactor: 1.25),
            style: titleStyle,
          ),
          subtitle: article.shortAnswer.trim().isEmpty
              ? null
              : Padding(
                  padding: const AppEdgeInsets.only(top: 6),
                  child: Text(
                    article.shortAnswer,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    textScaler: textScale.clamp(maxScaleFactor: 1.18),
                    style: bodyStyle,
                  ),
                ),
          children: [
            if (article.body.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  article.body,
                  textScaler: textScale.clamp(maxScaleFactor: 1.18),
                  style: bodyStyle,
                ),
              ),
            if (article.actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ArticleActions(
                article: article,
                actions: article.actions,
                onActionSelected: onActionSelected,
              ),
            ],
            if (onFeedback != null) ...[
              const SizedBox(height: 14),
              _FeedbackActions(
                onFeedback: onFeedback!,
                selectedFeedback: selectedFeedback,
                isSubmitting: isFeedbackSubmitting,
                l10n: l10n,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArticleActions extends StatelessWidget {
  const _ArticleActions({
    required this.article,
    required this.actions,
    required this.onActionSelected,
  });

  final HelpArticleVm article;
  final List<HelpArticleActionVm> actions;
  final HelpArticleActionCallback onActionSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions
            .map(
              (action) => FilledButton.icon(
                onPressed: () => onActionSelected(article, action),
                icon: Icon(_actionIcon(action.type), size: 18),
                label: Text(
                  _actionLabel(l10n, action),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _isPrimary(action.type)
                      ? AppPalette.primary
                      : AppPalette.white.withValues(alpha: 0.08),
                  foregroundColor: _isPrimary(action.type)
                      ? AppPalette.textPrimary
                      : AppPalette.textPrimary,
                  minimumSize: const Size(44, 42),
                  padding: const AppEdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.circular(12),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  bool _isPrimary(HelpArticleActionType type) {
    return type == HelpArticleActionType.openChat ||
        type == HelpArticleActionType.contactSupport;
  }

  IconData _actionIcon(HelpArticleActionType type) {
    return switch (type) {
      HelpArticleActionType.openChat => Icons.chat_bubble_outline_rounded,
      HelpArticleActionType.contactSupport => Icons.support_agent_rounded,
      HelpArticleActionType.openRoute => Icons.arrow_forward_rounded,
      HelpArticleActionType.unknown => Icons.help_outline_rounded,
    };
  }

  String _actionLabel(AppLocalizations l10n, HelpArticleActionVm action) {
    final explicit = action.label?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return switch (action.type) {
      HelpArticleActionType.openChat => l10n.helpCenterOpenChat,
      HelpArticleActionType.contactSupport => l10n.helpCenterContactSupport,
      HelpArticleActionType.openRoute => l10n.helpCenterOpenRoute,
      HelpArticleActionType.unknown => l10n.helpCenterOpenRoute,
    };
  }
}

class _FeedbackActions extends StatelessWidget {
  const _FeedbackActions({
    required this.onFeedback,
    required this.selectedFeedback,
    required this.isSubmitting,
    required this.l10n,
  });

  final ValueChanged<bool> onFeedback;
  final bool? selectedFeedback;
  final bool isSubmitting;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final helpfulSelected = selectedFeedback == true;
    final notHelpfulSelected = selectedFeedback == false;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.helpCenterWasHelpful,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const AppTextStyle(
              color: AppPalette.textCoolSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('help-article-feedback-helpful'),
          onPressed: isSubmitting || helpfulSelected
              ? null
              : () => onFeedback(true),
          tooltip: l10n.helpCenterHelpful,
          icon: Icon(
            helpfulSelected
                ? Icons.thumb_up_alt_rounded
                : Icons.thumb_up_alt_outlined,
            size: 18,
          ),
          style: _feedbackButtonStyle(helpfulSelected),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          key: const ValueKey('help-article-feedback-not-helpful'),
          onPressed: isSubmitting || notHelpfulSelected
              ? null
              : () => onFeedback(false),
          tooltip: l10n.helpCenterNotHelpful,
          icon: Icon(
            notHelpfulSelected
                ? Icons.thumb_down_alt_rounded
                : Icons.thumb_down_alt_outlined,
            size: 18,
          ),
          style: _feedbackButtonStyle(notHelpfulSelected),
        ),
      ],
    );
  }

  ButtonStyle _feedbackButtonStyle(bool selected) {
    final background = selected
        ? AppPalette.primary
        : AppPalette.white.withValues(alpha: 0.08);
    final foreground = AppPalette.textPrimary;
    return IconButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: selected
          ? AppPalette.primary
          : AppPalette.white.withValues(alpha: 0.05),
      disabledForegroundColor: selected
          ? AppPalette.textPrimary
          : AppPalette.textCoolSecondary,
    );
  }
}
