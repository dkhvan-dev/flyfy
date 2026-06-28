import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_bottom_navigation_bars.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/help_center_api.dart';
import '../widgets/help_article_tile.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

const _helpCenterBackground = AppPalette.warmInk22;
const _helpCenterBackgroundTop = AppPalette.warmSurface22;
const _helpCenterSurface = AppPalette.warmSurface12;
const _helpCenterSurfaceHigh = AppPalette.warmSurface55;
const _helpCenterHeroStart = AppPalette.warmSurface97;
const _helpCenterHeroEnd = AppPalette.warmInk88;
const _helpCenterAmberSoft = AppPalette.amberLight06;
const _helpCenterPageSize = 20;
const _helpCenterSearchDebounce = Duration(milliseconds: 450);
const _helpCenterCompactCategoryLimit = 5;

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key, this.api});

  final HelpCenterApi? api;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  late final HelpCenterApi _api = widget.api ?? HelpCenterApi();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  var _articles = const <HelpArticleVm>[];
  var _categories = const <HelpCategoryVm>[];
  var _isLoading = true;
  var _isLoadingMore = false;
  var _hasError = false;
  var _isSearchMode = false;
  var _hasMore = false;
  var _locale = '';
  var _selectedCategoryId = '';
  int? _nextOffset;
  var _requestId = 0;
  final _feedbackSelections = <String, bool>{};
  final _submittingFeedbackArticleIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale == locale && !_isLoading) return;
    _locale = locale;
    unawaited(_loadCategories());
    unawaited(_loadPopular(categoryId: _selectedCategoryId));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _api.helpCategories(
        locale: _locale,
        surface: HelpCenterSurface.helpCenter,
      );
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      if (!mounted) return;
      setState(() => _categories = const []);
    }
  }

  Future<void> _loadPopular({String categoryId = ''}) async {
    final requestId = ++_requestId;
    final cleanCategoryId = categoryId.trim();
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasError = false;
      _isSearchMode = false;
      _hasMore = false;
      _nextOffset = null;
      _selectedCategoryId = cleanCategoryId;
    });

    try {
      final page = await _api.contextualArticlePage(
        locale: _locale,
        surface: HelpCenterSurface.helpCenter,
        categoryId: cleanCategoryId.isEmpty ? null : cleanCategoryId,
        limit: _helpCenterPageSize,
        offset: 0,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _articles = page.items;
        _hasMore = page.hasMore;
        _nextOffset = page.nextOffset;
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

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || _isSearchMode || !_hasMore) return;
    final requestId = _requestId;
    final offset = _nextOffset ?? _articles.length;
    setState(() => _isLoadingMore = true);

    try {
      final page = await _api.contextualArticlePage(
        locale: _locale,
        surface: HelpCenterSurface.helpCenter,
        categoryId: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
        limit: _helpCenterPageSize,
        offset: offset,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _articles = [..._articles, ...page.items];
        _hasMore = page.hasMore;
        _nextOffset = page.nextOffset;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _runSearch(String value) async {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      await _loadPopular(categoryId: _selectedCategoryId);
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasError = false;
      _isSearchMode = true;
      _hasMore = false;
      _nextOffset = null;
      _selectedCategoryId = '';
    });

    try {
      final articles = await _api.searchArticles(
        locale: _locale,
        query: value,
        surface: HelpCenterSurface.helpCenter,
        limit: 20,
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

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      unawaited(_loadPopular(categoryId: _selectedCategoryId));
      return;
    }
    _searchDebounce = Timer(
      _helpCenterSearchDebounce,
      () => unawaited(_runSearch(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;
    final horizontalPadding = isCompact ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: _helpCenterBackground,
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.services,
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onMapTap: () => context.push('/map'),
        onServicesTap: () => context.push('/services'),
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: const AppBoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _helpCenterBackgroundTop,
              _helpCenterBackground,
              _helpCenterBackground,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: AppEdgeInsets.fromLTRB(
                  horizontalPadding,
                  isCompact ? 16 : 24,
                  horizontalPadding,
                  18,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HelpCenterHeader(
                            l10n: l10n,
                            onSupportRequestsTap: () =>
                                context.push('/help/support'),
                          ),
                          const SizedBox(height: 18),
                          _HelpCenterSearchField(
                            controller: _searchController,
                            hint: l10n.helpCenterSearchHint,
                            onChanged: _scheduleSearch,
                            onSubmitted: _runSearch,
                            onClear: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              unawaited(
                                _loadPopular(categoryId: _selectedCategoryId),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _HelpCenterCategoryChips(
                            categories: _helpCenterCategories(
                              l10n,
                              _categories,
                            ),
                            selectedId: _selectedCategoryId,
                            compact: isCompact,
                            moreLabel: l10n.helpCenterMoreCategories,
                            onShowAll: () => unawaited(
                              _openCategoryPicker(
                                l10n,
                                _helpCenterCategories(l10n, _categories),
                              ),
                            ),
                            onSelected: (categoryId) {
                              _searchController.clear();
                              unawaited(_loadPopular(categoryId: categoryId));
                            },
                          ),
                          const SizedBox(height: 24),
                          _HelpCenterSectionHeading(
                            title: _isSearchMode
                                ? l10n.helpCenterSearchResultsTitle
                                : l10n.helpCenterPopularTitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: AppEdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  28 + mediaQuery.padding.bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _buildContent(l10n),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker(
    AppLocalizations l10n,
    List<_HelpCenterCategoryOption> categories,
  ) async {
    if (categories.length <= _helpCenterCompactCategoryLimit) return;
    final selectedCategoryId = await showAppModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => _HelpCenterCategorySheet(
        title: l10n.helpCenterCategoriesTitle,
        categories: categories,
        selectedId: _selectedCategoryId,
      ),
    );
    if (!mounted || selectedCategoryId == null) return;
    _searchController.clear();
    unawaited(_loadPopular(categoryId: selectedCategoryId));
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) return const _HelpCenterSkeleton();
    if (_hasError) {
      return _HelpCenterStateMessage(
        icon: Icons.wifi_off_rounded,
        title: l10n.helpCenterLoadFailedTitle,
        message: l10n.contextualHelpLoadFailed,
        actionLabel: l10n.helpCenterRetry,
        onAction: _isSearchMode
            ? () => unawaited(_runSearch(_searchController.text))
            : () => unawaited(_loadPopular(categoryId: _selectedCategoryId)),
      );
    }
    if (_articles.isEmpty) {
      return _HelpCenterStateMessage(
        icon: Icons.search_off_rounded,
        title: l10n.helpCenterNoResultsTitle,
        message: l10n.helpCenterNoResultsMessage,
        actionLabel: l10n.helpCenterOpenChat,
        actionIcon: Icons.support_agent_rounded,
        onAction: _openSupportChatFromNoResults,
      );
    }

    return Column(
      children: [
        ..._articles.map(
          (article) => Padding(
            padding: const AppEdgeInsets.only(bottom: 12),
            child: HelpArticleTile(
              article: _articleWithoutSupportAction(article),
              initiallyExpanded: _articles.length == 1,
              onActionSelected: _handleAction,
              selectedFeedback: _feedbackSelections[article.id],
              isFeedbackSubmitting: _submittingFeedbackArticleIds.contains(
                article.id,
              ),
              onFeedback: (helpful) =>
                  unawaited(_submitFeedback(article, helpful)),
            ),
          ),
        ),
        if (!_isSearchMode && _hasMore)
          Padding(
            padding: const AppEdgeInsets.only(top: 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('help-center-load-more'),
                onPressed: _isLoadingMore ? null : () => unawaited(_loadMore()),
                icon: _isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(l10n.helpCenterLoadMore),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleAction(HelpArticleVm article, HelpArticleActionVm action) {
    if (action.type == HelpArticleActionType.openRoute &&
        action.target.trim().startsWith('/')) {
      context.push(action.target.trim());
      return;
    }

    if (action.type == HelpArticleActionType.contactSupport) {
      return;
    }

    if (action.type == HelpArticleActionType.openChat) {
      context.push('/chats');
    }
  }

  void _openSupportChatFromNoResults() {
    final query = _searchController.text.trim();
    final supportContext = {
      'screen': HelpCenterSurface.helpCenter.wireValue,
      'source_route': '/help',
      'locale': _locale,
      if (query.isNotEmpty) 'failed_search': query,
      if (query.isNotEmpty) 'search_query': query,
    };

    context.push(
      '/help/support',
      extra: SupportChatOpenIntent(
        category: SupportTicketCategory.technical,
        source: HelpCenterSurface.helpCenter.wireValue,
        intent: query.isEmpty
            ? 'help_center_no_results'
            : 'failed_search:$query',
        context: supportContext,
      ),
    );
  }

  Future<void> _submitFeedback(HelpArticleVm article, bool helpful) async {
    final l10n = AppLocalizations.of(context)!;
    final articleId = article.id.trim();
    if (articleId.isEmpty ||
        _feedbackSelections[articleId] == helpful ||
        _submittingFeedbackArticleIds.contains(articleId)) {
      return;
    }
    setState(() => _submittingFeedbackArticleIds.add(articleId));
    try {
      await _api.submitArticleFeedback(
        articleId: articleId,
        locale: _locale,
        helpful: helpful,
        reason: helpful ? '' : 'not_helpful_from_help_center',
        escalatedToSupport: false,
      );
      if (!mounted) return;
      setState(() {
        _feedbackSelections[articleId] = helpful;
        _submittingFeedbackArticleIds.remove(articleId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.helpCenterFeedbackSaved)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submittingFeedbackArticleIds.remove(articleId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contextualHelpLoadFailed)));
    }
  }

  HelpArticleVm _articleWithoutSupportAction(HelpArticleVm article) {
    return HelpArticleVm(
      id: article.id,
      slug: article.slug,
      title: article.title,
      shortAnswer: article.shortAnswer,
      body: article.body,
      actions: article.actions
          .where(
            (action) => action.type != HelpArticleActionType.contactSupport,
          )
          .toList(growable: false),
      relatedArticleIds: article.relatedArticleIds,
      tags: article.tags,
      updatedAt: article.updatedAt,
    );
  }
}

class _HelpCenterSectionHeading extends StatelessWidget {
  const _HelpCenterSectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.16),
            borderRadius: AppBorderRadius.circular(12),
            border: Border.all(
              color: AppPalette.primary.withValues(alpha: 0.28),
            ),
          ),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _helpCenterAmberSoft,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const AppTextStyle(
              color: AppPalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

List<_HelpCenterCategoryOption> _helpCenterCategories(
  AppLocalizations l10n,
  List<HelpCategoryVm> categories,
) {
  return [
    _HelpCenterCategoryOption(
      id: '',
      label: l10n.helpCenterCategoryAll,
      key: 'help-center-category-all',
    ),
    ...categories.map(
      (category) => _HelpCenterCategoryOption(
        id: category.id,
        label: _helpCenterCategoryLabel(l10n, category),
        key: _helpCenterCategoryKey(category),
      ),
    ),
  ];
}

class _HelpCenterCategoryOption {
  const _HelpCenterCategoryOption({
    required this.id,
    required this.label,
    required this.key,
  });

  final String id;
  final String label;
  final String key;
}

String _helpCenterCategoryLabel(
  AppLocalizations l10n,
  HelpCategoryVm category,
) {
  final backendTitle = category.title.trim();
  if (backendTitle.isNotEmpty) return backendTitle;
  return switch (category.id) {
    'documents_visas_entry' => l10n.helpCenterCategoryDocuments,
    'airport_flights_baggage' => l10n.helpCenterCategoryFlights,
    'booking_accommodation' => l10n.helpCenterCategoryAccommodation,
    'money_cards_connectivity' => l10n.helpCenterCategoryMoney,
    'health_safety_insurance' => l10n.helpCenterCategorySafety,
    'local_transport' => l10n.helpCenterCategoryTransport,
    'route_budget_planning' => l10n.helpCenterCategoryPlanning,
    'local_rules_culture_special' => l10n.helpCenterCategoryCulture,
    _ => _humanizeCategorySlug(
      category.slug.isEmpty ? category.id : category.slug,
    ),
  };
}

String _helpCenterCategoryKey(HelpCategoryVm category) {
  final suffix = switch (category.id) {
    'documents_visas_entry' => 'documents',
    'airport_flights_baggage' => 'flights',
    'booking_accommodation' => 'accommodation',
    'money_cards_connectivity' => 'money',
    'health_safety_insurance' => 'safety',
    'local_transport' => 'transport',
    'route_budget_planning' => 'planning',
    'local_rules_culture_special' => 'culture',
    _ => category.slug.isEmpty ? category.id : category.slug,
  };
  return 'help-center-category-$suffix';
}

String _humanizeCategorySlug(String value) {
  final words = value
      .replaceAll('_', '-')
      .split('-')
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return value;
  return words
      .map(
        (word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class _HelpCenterCategoryChips extends StatelessWidget {
  const _HelpCenterCategoryChips({
    required this.categories,
    required this.selectedId,
    required this.compact,
    required this.moreLabel,
    required this.onSelected,
    required this.onShowAll,
  });

  final List<_HelpCenterCategoryOption> categories;
  final String selectedId;
  final bool compact;
  final String moreLabel;
  final ValueChanged<String> onSelected;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = compact
        ? _compactHelpCenterCategories(categories, selectedId)
        : categories;
    final chips = visibleCategories
        .map(
          (category) => _HelpCenterCategoryChip(
            category: category,
            selected: category.id == selectedId,
            onSelected: onSelected,
          ),
        )
        .toList(growable: false);

    if (compact) {
      final hasMore = categories.length > _helpCenterCompactCategoryLimit;
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < chips.length; index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    chips[index],
                  ],
                ],
              ),
            ),
          ),
          if (hasMore) ...[
            const SizedBox(width: 8),
            _HelpCenterMoreCategoriesChip(
              label: moreLabel,
              onPressed: onShowAll,
            ),
          ],
        ],
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _HelpCenterCategoryChip extends StatelessWidget {
  const _HelpCenterCategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final _HelpCenterCategoryOption category;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey(category.key),
      label: Text(category.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onSelected(category.id),
      selectedColor: AppPalette.primary,
      backgroundColor: _helpCenterSurfaceHigh.withValues(alpha: 0.76),
      labelStyle: AppTextStyle(
        color: AppPalette.textPrimary,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        letterSpacing: 0,
      ),
      side: BorderSide(
        color: selected
            ? AppPalette.primary
            : AppPalette.primary.withValues(alpha: 0.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _HelpCenterMoreCategoriesChip extends StatelessWidget {
  const _HelpCenterMoreCategoriesChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key: const ValueKey('help-center-category-more'),
      avatar: const Icon(
        Icons.tune_rounded,
        size: 18,
        color: AppPalette.textPrimary,
      ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: onPressed,
      backgroundColor: AppPalette.primary,
      labelStyle: const AppTextStyle(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      side: const BorderSide(color: AppPalette.primary),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

List<_HelpCenterCategoryOption> _compactHelpCenterCategories(
  List<_HelpCenterCategoryOption> categories,
  String selectedId,
) {
  if (categories.length <= _helpCenterCompactCategoryLimit) return categories;
  final visible = categories
      .take(_helpCenterCompactCategoryLimit)
      .toList(growable: false);
  if (selectedId.isEmpty ||
      visible.any((category) => category.id == selectedId)) {
    return visible;
  }
  final selectedIndex = categories.indexWhere(
    (category) => category.id == selectedId,
  );
  if (selectedIndex < 0) return visible;
  return [
    ...visible.take(_helpCenterCompactCategoryLimit - 1),
    categories[selectedIndex],
  ];
}

String _helpCenterCategorySheetKey(_HelpCenterCategoryOption category) {
  return category.key.replaceFirst(
    'help-center-category-',
    'help-center-category-sheet-',
  );
}

class _HelpCenterCategorySheet extends StatelessWidget {
  const _HelpCenterCategorySheet({
    required this.title,
    required this.categories,
    required this.selectedId,
  });

  final String title;
  final List<_HelpCenterCategoryOption> categories;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: mediaQuery.size.height * 0.82,
        ),
        child: DecoratedBox(
          key: const ValueKey('help-center-category-sheet'),
          decoration: const AppBoxDecoration(
            color: _helpCenterSurface,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(26),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const AppEdgeInsets.fromLTRB(18, 12, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const AppTextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppPalette.primary,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const AppEdgeInsets.fromLTRB(12, 0, 12, 16),
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = category.id == selectedId;
                      return _HelpCenterCategorySheetItem(
                        key: ValueKey(_helpCenterCategorySheetKey(category)),
                        category: category,
                        selected: selected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCenterCategorySheetItem extends StatelessWidget {
  const _HelpCenterCategorySheetItem({
    super.key,
    required this.category,
    required this.selected,
  });

  final _HelpCenterCategoryOption category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppPalette.primary.withValues(alpha: 0.16)
          : _helpCenterSurfaceHigh.withValues(alpha: 0.74),
      borderRadius: AppBorderRadius.circular(16),
      child: InkWell(
        borderRadius: AppBorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(category.id),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? AppPalette.primary : _helpCenterAmberSoft,
                size: selected ? 22 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCenterHeader extends StatelessWidget {
  const _HelpCenterHeader({
    required this.l10n,
    required this.onSupportRequestsTap,
  });

  final AppLocalizations l10n;
  final VoidCallback onSupportRequestsTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 375;
    final textScale = MediaQuery.textScalerOf(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _helpCenterHeroStart,
            _helpCenterSurfaceHigh,
            _helpCenterHeroEnd,
          ],
        ),
        borderRadius: AppBorderRadius.circular(24),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: AppEdgeInsets.all(isCompact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go('/services');
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.white.withValues(alpha: 0.10),
                    foregroundColor: AppPalette.textPrimary,
                    minimumSize: const Size(44, 44),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: onSupportRequestsTap,
                      icon: const Icon(Icons.support_agent_rounded, size: 19),
                      label: Text(
                        l10n.helpCenterSupportChatButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: AppPalette.textPrimary,
                        minimumSize: const Size(44, 44),
                        padding: AppEdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: AppBoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.15),
                    borderRadius: AppBorderRadius.circular(16),
                    border: Border.all(
                      color: AppPalette.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Padding(
                    padding: AppEdgeInsets.all(10),
                    child: Icon(
                      Icons.tips_and_updates_rounded,
                      color: _helpCenterAmberSoft,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.helpCenterTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: textScale.clamp(maxScaleFactor: 1.18),
                        style: AppTextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: isCompact ? 27 : 30,
                          height: 1.06,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.helpCenterSubtitle,
                        textScaler: textScale.clamp(maxScaleFactor: 1.18),
                        style: const AppTextStyle(
                          color: _helpCenterAmberSoft,
                          fontSize: 14,
                          height: 1.38,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCenterSearchField extends StatelessWidget {
  const _HelpCenterSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('help-center-search-field'),
      controller: controller,
      textInputAction: TextInputAction.search,
      style: const AppTextStyle(
        color: AppPalette.textPrimary,
        letterSpacing: 0,
      ),
      decoration: AppInputDecoration(
        filled: true,
        fillColor: _helpCenterSurface,
        hintText: hint,
        hintStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: AppPalette.primary),
        suffixIcon: IconButton(
          onPressed: onClear,
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          color: AppPalette.primary,
          icon: const Icon(Icons.close_rounded),
        ),
        contentPadding: const AppEdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppPalette.primary.withValues(alpha: 0.18),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppPalette.primary.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.4),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class _HelpCenterSkeleton extends StatelessWidget {
  const _HelpCenterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const AppEdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: _helpCenterSurfaceHigh.withValues(alpha: 0.68),
              borderRadius: AppBorderRadius.circular(16),
              border: Border.all(
                color: AppPalette.primary.withValues(alpha: 0.10),
              ),
            ),
            child: const SizedBox(height: 96, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

class _HelpCenterStateMessage extends StatelessWidget {
  const _HelpCenterStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: _helpCenterSurface,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: AppBoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.14),
                borderRadius: AppBorderRadius.circular(14),
              ),
              child: Padding(
                padding: const AppEdgeInsets.all(10),
                child: Icon(icon, color: _helpCenterAmberSoft, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const AppTextStyle(
                color: AppPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const AppTextStyle(
                color: AppPalette.textCoolSecondary,
                fontSize: 14,
                height: 1.38,
                letterSpacing: 0,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
