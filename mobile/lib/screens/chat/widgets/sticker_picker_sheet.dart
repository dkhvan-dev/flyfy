import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/file_api.dart';
import '../../../core/ui/app_colors.dart';
import '../../../features/chat/models/sticker_pack_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/sticker_catalog_provider.dart';

class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({super.key, required this.onStickerSelected});

  final ValueChanged<StickerVm> onStickerSelected;

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      unawaited(
        context.read<StickerCatalogProvider>().loadCatalog(locale: locale),
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    final query = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final provider = context.read<StickerCatalogProvider>();
      if (query.isEmpty) {
        provider.clearSearch();
        return;
      }
      final locale = Localizations.localeOf(context).languageCode;
      unawaited(provider.search(query, locale: locale));
      if (_showRecent) {
        setState(() => _showRecent = false);
      }
    });
  }

  Future<void> _retry() async {
    final locale = Localizations.localeOf(context).languageCode;
    await context.read<StickerCatalogProvider>().loadCatalog(
      locale: locale,
      forceRefresh: true,
    );
  }

  Future<void> _selectRecent() async {
    setState(() => _showRecent = true);
    await context.read<StickerCatalogProvider>().loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          key: const ValueKey('sticker-picker-sheet'),
          height: _sheetHeight(context),
          decoration: const BoxDecoration(
            color: Color(0xFF1d120b),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Consumer<StickerCatalogProvider>(
            builder: (context, provider, _) {
              final searchActive = _searchController.text.trim().isNotEmpty;
              final packs = provider.groups
                  .expand((group) => group.packs)
                  .toList(growable: false);
              final selectedPack =
                  provider.selectedPack ?? (packs.isEmpty ? null : packs.first);
              final stickers = searchActive
                  ? provider.searchResults
                  : _showRecent
                  ? provider.recentStickers
                  : selectedPack?.stickers ?? const <StickerVm>[];

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: _StickerSearchField(
                      controller: _searchController,
                      hintText: l10n.stickersSearchHint,
                      searching: provider.isSearching,
                      onChanged: _handleSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        provider.clearSearch();
                        setState(() => _showRecent = false);
                      },
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey('sticker-pack-tabs'),
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: packs.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _StickerTab(
                            label: l10n.stickersTabRecent,
                            icon: Icons.history_rounded,
                            selected: _showRecent && !searchActive,
                            onTap: _selectRecent,
                          );
                        }

                        final pack = packs[index - 1];
                        return _StickerTab(
                          label: pack.titleFor(
                            Localizations.localeOf(context).languageCode,
                          ),
                          selected:
                              !_showRecent &&
                              !searchActive &&
                              selectedPack?.id == pack.id,
                          onTap: () {
                            unawaited(provider.selectPack(pack));
                            setState(() => _showRecent = false);
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _StickerGridContent(
                      loading: provider.isLoading,
                      error: provider.error,
                      hasCatalog: packs.isNotEmpty,
                      stickers: stickers,
                      searchActive: searchActive,
                      showRecent: _showRecent,
                      emptyRecentText: l10n.stickersEmptyRecent,
                      emptySearchText: l10n.stickersEmptySearch,
                      loadFailedText: l10n.stickersLoadFailed,
                      retryText: l10n.stickersRetry,
                      onRetry: _retry,
                      onStickerSelected: widget.onStickerSelected,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _sheetHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final target = size.height * 0.56;
    return target.clamp(360.0, 520.0).toDouble();
  }
}

class _StickerSearchField extends StatelessWidget {
  const _StickerSearchField({
    required this.controller,
    required this.hintText,
    required this.searching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Color(0xFFf5f3ef),
            fontSize: 15,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.52),
            ),
            suffixIcon: searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : hasText
                ? IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  )
                : null,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.46),
              fontSize: 15,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: const Color(0xFF2a1a10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.42),
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
    );
  }
}

class _StickerTab extends StatelessWidget {
  const _StickerTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(minWidth: 44),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFFffd08a)
                      : Colors.white.withValues(alpha: 0.66),
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFFffd08a)
                        : Colors.white.withValues(alpha: 0.68),
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerGridContent extends StatelessWidget {
  const _StickerGridContent({
    required this.loading,
    required this.error,
    required this.hasCatalog,
    required this.stickers,
    required this.searchActive,
    required this.showRecent,
    required this.emptyRecentText,
    required this.emptySearchText,
    required this.loadFailedText,
    required this.retryText,
    required this.onRetry,
    required this.onStickerSelected,
  });

  final bool loading;
  final Object? error;
  final bool hasCatalog;
  final List<StickerVm> stickers;
  final bool searchActive;
  final bool showRecent;
  final String emptyRecentText;
  final String emptySearchText;
  final String loadFailedText;
  final String retryText;
  final VoidCallback onRetry;
  final ValueChanged<StickerVm> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    if (loading && !hasCatalog) {
      return const _StickerGridSkeleton();
    }

    if (error != null && !hasCatalog) {
      return _StickerMessageState(
        icon: Icons.cloud_off_rounded,
        title: loadFailedText,
        actionLabel: retryText,
        onAction: onRetry,
      );
    }

    if (stickers.isEmpty) {
      final title = searchActive
          ? emptySearchText
          : showRecent
          ? emptyRecentText
          : emptySearchText;
      return _StickerMessageState(
        icon: searchActive ? Icons.search_off_rounded : Icons.history_rounded,
        title: title,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawColumns = (constraints.maxWidth / 86).floor();
        final columns = rawColumns.clamp(4, 7).toInt();

        return GridView.builder(
          key: const ValueKey('sticker-grid'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: stickers.length,
          itemBuilder: (context, index) {
            final sticker = stickers[index];
            return _StickerButton(
              key: ValueKey('sticker-${sticker.id}'),
              sticker: sticker,
              onTap: () => onStickerSelected(sticker),
            );
          },
        );
      },
    );
  }
}

class _StickerGridSkeleton extends StatelessWidget {
  const _StickerGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

class _StickerButton extends StatelessWidget {
  const _StickerButton({super.key, required this.sticker, required this.onTap});

  final StickerVm sticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _stickerSemanticLabel(context, sticker);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _StickerPreview(sticker: sticker),
          ),
        ),
      ),
    );
  }

  String _stickerSemanticLabel(BuildContext context, StickerVm sticker) {
    final emoji = sticker.emoji?.trim() ?? '';
    if (emoji.isNotEmpty) return emoji;
    if (sticker.keywords.isNotEmpty) return sticker.keywords.first;
    return AppLocalizations.of(context)!.chatStickerMessage;
  }
}

class _StickerPreview extends StatelessWidget {
  const _StickerPreview({required this.sticker});

  final StickerVm sticker;

  @override
  Widget build(BuildContext context) {
    final fileId = _previewFileId(sticker);
    final url = resolvePublicFileContentUrl(fileId);
    final emoji = sticker.emoji?.trim() ?? '';

    if (url == null) {
      return _StickerFallback(emoji: emoji);
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _StickerFallback(emoji: emoji, loading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        return _StickerFallback(emoji: emoji);
      },
    );
  }

  String _previewFileId(StickerVm sticker) {
    final preview = sticker.previewFileId?.trim() ?? '';
    if (preview.isNotEmpty) return preview;
    final fallback = sticker.fallbackFileId.trim();
    if (fallback.isNotEmpty) return fallback;
    return sticker.fileId.trim();
  }
}

class _StickerFallback extends StatelessWidget {
  const _StickerFallback({required this.emoji, this.loading = false});

  final String emoji;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && emoji.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }

    return Center(
      child: Text(
        emoji.isEmpty ? '✦' : emoji,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30, height: 1, letterSpacing: 0),
      ),
    );
  }
}

class _StickerMessageState extends StatelessWidget {
  const _StickerMessageState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: Colors.white.withValues(alpha: 0.40)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.accent,
                    letterSpacing: 0,
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
