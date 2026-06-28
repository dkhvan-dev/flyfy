import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/help_center_api.dart';
import 'help_article_tile.dart';

class ContextualHelpSection extends StatefulWidget {
  const ContextualHelpSection({
    super.key,
    required this.surface,
    this.api,
    this.tags = const [],
    this.supportContext = const {},
    this.userState,
    this.paymentStatus,
    this.limit = 5,
    this.onActionSelected,
  });

  final HelpCenterApi? api;
  final HelpCenterSurface surface;
  final List<String> tags;
  final Map<String, String> supportContext;
  final String? userState;
  final String? paymentStatus;
  final int limit;
  final HelpArticleActionCallback? onActionSelected;

  @override
  State<ContextualHelpSection> createState() => _ContextualHelpSectionState();
}

class _ContextualHelpSectionState extends State<ContextualHelpSection> {
  late final HelpCenterApi _api = widget.api ?? HelpCenterApi();
  var _articles = const <HelpArticleVm>[];
  var _isLoading = true;
  var _hasError = false;
  var _locale = '';
  var _requestId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale == locale && !_isLoading) return;
    _locale = locale;
    unawaited(_load());
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final articles = await _api.contextualArticles(
        locale: _locale,
        surface: widget.surface,
        tags: widget.tags,
        userState: widget.userState,
        paymentStatus: widget.paymentStatus,
        limit: widget.limit,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && !_hasError && _articles.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.warmSurface03,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppBoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.16),
                    borderRadius: AppBorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: AppPalette.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.contextualHelpTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const AppTextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/help'),
                  child: Text(l10n.contextualHelpOpenAll),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const _ContextualHelpSkeleton()
            else if (_hasError)
              _ContextualHelpError(l10n: l10n, onRetry: _load)
            else
              ..._articles
                  .take(widget.limit)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const AppEdgeInsets.only(bottom: 10),
                      child: HelpArticleTile(
                        article: entry.value,
                        compact: true,
                        initiallyExpanded: entry.key == 0,
                        onActionSelected: _handleAction,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _handleAction(HelpArticleVm article, HelpArticleActionVm action) {
    final callback = widget.onActionSelected;
    if (callback != null) {
      callback(article, action);
      return;
    }

    if (action.type == HelpArticleActionType.openRoute &&
        action.target.trim().startsWith('/')) {
      context.push(action.target.trim());
      return;
    }

    if (action.type == HelpArticleActionType.contactSupport) {
      _openSupportChat(article);
    }
  }

  void _openSupportChat(HelpArticleVm article) {
    final supportContext = {
      ...widget.supportContext,
      'article_id': article.id,
      'source_route': widget.surface.wireValue,
    };
    context.push(
      '/help/support',
      extra: SupportChatOpenIntent(
        category: _categoryFromTags(article.tags),
        source: widget.surface.wireValue,
        intent: 'article:${article.id}',
        context: supportContext,
      ),
    );
  }

  SupportTicketCategory _categoryFromTags(List<String> tags) {
    final normalized = tags.map((tag) => tag.trim().toLowerCase()).toSet();
    if (normalized.contains('payments') || normalized.contains('refunds')) {
      return SupportTicketCategory.payments;
    }
    if (normalized.contains('excursions') || normalized.contains('guides')) {
      return SupportTicketCategory.excursions;
    }
    if (normalized.contains('places')) return SupportTicketCategory.places;
    if (normalized.contains('currency')) return SupportTicketCategory.currency;
    if (normalized.contains('activities')) {
      return SupportTicketCategory.activities;
    }
    return SupportTicketCategory.technical;
  }
}

class _ContextualHelpSkeleton extends StatelessWidget {
  const _ContextualHelpSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const AppEdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: AppPalette.white.withValues(alpha: 0.05),
              borderRadius: AppBorderRadius.circular(14),
            ),
            child: const SizedBox(height: 72, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

class _ContextualHelpError extends StatelessWidget {
  const _ContextualHelpError({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.contextualHelpLoadFailed,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const AppTextStyle(
              color: AppPalette.textCoolSecondary,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onRetry,
          child: Text(l10n.contextualHelpTryAgain),
        ),
      ],
    );
  }
}
