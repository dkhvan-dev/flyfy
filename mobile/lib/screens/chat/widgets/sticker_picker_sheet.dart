import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/network/file_api.dart';
import '../../../features/chat/models/sticker_pack_vm.dart';
import '../../../features/chat/utils/sticker_asset_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/sticker_catalog_provider.dart';

typedef StickerPreviewContentLoader =
    Future<FileContentVm?> Function(String fileId);

class StickerPickerSheet extends StatefulWidget {
  const StickerPickerSheet({
    super.key,
    required this.onStickerSelected,
    this.previewContentLoader,
  });

  final ValueChanged<StickerVm> onStickerSelected;
  final StickerPreviewContentLoader? previewContentLoader;

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      unawaited(
        context.read<StickerCatalogProvider>().loadCatalog(
          locale: locale,
          preloadAllPacks: true,
        ),
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
    });
  }

  Future<void> _retry() async {
    final locale = Localizations.localeOf(context).languageCode;
    await context.read<StickerCatalogProvider>().loadCatalog(
      locale: locale,
      forceRefresh: true,
      preloadAllPacks: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: AppEdgeInsets.only(bottom: bottomInset),
        child: Container(
          key: const ValueKey('sticker-picker-sheet'),
          height: _sheetHeight(context),
          decoration: AppBoxDecoration(
            color: colors.background,
            borderRadius: const AppBorderRadius.vertical(
              top: AppRadiusValue.circular(22),
            ),
          ),
          child: Consumer<StickerCatalogProvider>(
            builder: (context, provider, _) {
              final searchActive = _searchController.text.trim().isNotEmpty;
              final packs = provider.groups
                  .expand((group) => group.packs)
                  .toList(growable: false);
              final allStickers = packs
                  .expand((pack) => pack.stickers)
                  .toList(growable: false);
              final stickers = searchActive
                  ? provider.searchResults
                  : allStickers;

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: AppBoxDecoration(
                      color: colors.textDisabled.withValues(alpha: 0.36),
                      borderRadius: AppBorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const AppEdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: _StickerSearchField(
                      controller: _searchController,
                      hintText: l10n.stickersSearchHint,
                      searching: provider.isSearching,
                      onChanged: _handleSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        provider.clearSearch();
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
                      showRecent: false,
                      emptyRecentText: l10n.stickersEmptyRecent,
                      emptySearchText: l10n.stickersEmptySearch,
                      loadFailedText: l10n.stickersLoadFailed,
                      retryText: l10n.stickersRetry,
                      onRetry: _retry,
                      onStickerSelected: widget.onStickerSelected,
                      previewContentLoader: widget.previewContentLoader,
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
    final colors = AppDesignSystem.colorsFor(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            letterSpacing: 0,
          ),
          decoration: AppInputDecoration(
            prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
            suffixIcon: searching
                ? Padding(
                    padding: AppEdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  )
                : hasText
                ? IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: Icon(Icons.close_rounded, color: colors.primary),
                  )
                : null,
            hintText: hintText,
            hintStyle: AppTextStyle(
              color: colors.textMuted,
              fontSize: 15,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: colors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppBorderRadius.circular(16),
              borderSide: BorderSide(color: colors.borderPrimary),
            ),
            isDense: true,
            contentPadding: const AppEdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
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
    required this.previewContentLoader,
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
  final StickerPreviewContentLoader? previewContentLoader;

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
          padding: const AppEdgeInsets.fromLTRB(16, 12, 16, 18),
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
              previewContentLoader: previewContentLoader,
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
    final colors = AppDesignSystem.colorsFor(context);

    return GridView.builder(
      padding: const AppEdgeInsets.fromLTRB(16, 12, 16, 18),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => DecoratedBox(
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(16),
          color: colors.surfaceHigh,
        ),
      ),
    );
  }
}

class _StickerButton extends StatelessWidget {
  const _StickerButton({
    super.key,
    required this.sticker,
    required this.previewContentLoader,
    required this.onTap,
  });

  final StickerVm sticker;
  final StickerPreviewContentLoader? previewContentLoader;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _stickerSemanticLabel(context, sticker);
    final colors = AppDesignSystem.colorsFor(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(16),
        onTap: onTap,
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            borderRadius: AppBorderRadius.circular(16),
            color: colors.surfaceHigh,
            border: Border.all(color: colors.borderSoft),
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(8),
            child: _StickerPreview(
              sticker: sticker,
              previewContentLoader: previewContentLoader,
            ),
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
  const _StickerPreview({
    required this.sticker,
    required this.previewContentLoader,
  });

  final StickerVm sticker;
  final StickerPreviewContentLoader? previewContentLoader;

  @override
  Widget build(BuildContext context) {
    final fileId = sticker.displayFileId;
    final emoji = sticker.emoji?.trim() ?? '';

    if (fileId.isEmpty) {
      return _StickerFallback(emoji: emoji);
    }

    return _StickerPreviewImage(
      fileId: fileId,
      emoji: emoji,
      declaredContentType: sticker.contentType,
      previewContentLoader: previewContentLoader,
    );
  }
}

class _StickerPreviewImage extends StatelessWidget {
  const _StickerPreviewImage({
    required this.fileId,
    required this.emoji,
    required this.declaredContentType,
    required this.previewContentLoader,
  });

  final String fileId;
  final String emoji;
  final String declaredContentType;
  final StickerPreviewContentLoader? previewContentLoader;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StickerPreviewAsset?>(
      future: _StickerPreviewAssetCache.assetFor(
        fileId,
        contentLoader: previewContentLoader,
      ),
      builder: (context, snapshot) {
        final asset = snapshot.data?.withDeclaredContentType(
          declaredContentType,
        );
        if (asset == null || asset.bytes.isEmpty) {
          return _StickerFallback(
            emoji: emoji,
            loading: snapshot.connectionState == ConnectionState.waiting,
          );
        }

        if (asset.isLottieSticker) {
          return Lottie.memory(
            asset.bytes,
            decoder: asset.lottieDecoder,
            errorBuilder: (context, error, stackTrace) =>
                _StickerFallback(emoji: emoji),
            fit: BoxFit.contain,
            frameRate: const FrameRate(60),
            repeat: true,
            renderCache: RenderCache.drawingCommands,
          );
        }

        if (asset.format == StickerAssetContentFormat.rasterImage) {
          return Image.memory(
            asset.bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          );
        }

        return _StickerFallback(emoji: emoji);
      },
    );
  }
}

class _StickerPreviewAsset {
  const _StickerPreviewAsset({
    required this.bytes,
    required this.responseContentType,
    this.declaredContentType = '',
  });

  final Uint8List bytes;
  final String responseContentType;
  final String declaredContentType;

  _StickerPreviewAsset withDeclaredContentType(String contentType) {
    return _StickerPreviewAsset(
      bytes: bytes,
      responseContentType: responseContentType,
      declaredContentType: contentType,
    );
  }

  StickerAssetContentFormat get format {
    return resolveStickerAssetContentFormat(
      bytes,
      responseContentType: responseContentType,
      declaredContentType: declaredContentType,
    );
  }

  bool get isLottieSticker {
    return format == StickerAssetContentFormat.tgsGzip ||
        format == StickerAssetContentFormat.lottieJson;
  }

  LottieDecoder? get lottieDecoder {
    return format == StickerAssetContentFormat.tgsGzip
        ? LottieComposition.decodeGZip
        : null;
  }
}

class _StickerPreviewAssetCache {
  static final FileApi _fileApi = FileApi();
  static final Map<String, Future<_StickerPreviewAsset?>> _assetFutures = {};

  static Future<_StickerPreviewAsset?> assetFor(
    String fileId, {
    StickerPreviewContentLoader? contentLoader,
  }) {
    final normalizedFileId = fileId.trim();
    if (normalizedFileId.isEmpty) {
      return Future<_StickerPreviewAsset?>.value(null);
    }

    if (contentLoader != null) {
      return _load(normalizedFileId, contentLoader);
    }

    final cached = _assetFutures[normalizedFileId];
    if (cached != null) return cached;

    final load = _load(normalizedFileId, _fileApi.downloadStickerContent);
    _assetFutures[normalizedFileId] = load;
    return load;
  }

  static Future<_StickerPreviewAsset?> _load(
    String normalizedFileId,
    StickerPreviewContentLoader contentLoader,
  ) async {
    try {
      final content = await contentLoader(normalizedFileId);
      if (content == null || content.bytes.isEmpty) {
        _assetFutures.remove(normalizedFileId);
        return null;
      }
      return _StickerPreviewAsset(
        bytes: content.bytes,
        responseContentType: content.contentType,
      );
    } catch (_) {
      _assetFutures.remove(normalizedFileId);
      return null;
    }
  }
}

class _StickerFallback extends StatelessWidget {
  const _StickerFallback({required this.emoji, this.loading = false});

  final String emoji;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && emoji.isEmpty) {
      final colors = AppDesignSystem.colorsFor(context);
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
      );
    }

    return Center(
      child: Text(
        emoji.isEmpty ? '✦' : emoji,
        textAlign: TextAlign.center,
        style: const AppTextStyle(fontSize: 30, height: 1, letterSpacing: 0),
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
    final colors = AppDesignSystem.colorsFor(context);

    return Center(
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: AppBoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondaryContainer,
                border: Border.all(color: colors.borderSecondary),
              ),
              child: Padding(
                padding: const AppEdgeInsets.all(14),
                child: Icon(icon, size: 30, color: colors.secondary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textSecondary,
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
                  style: AppTextStyle(color: colors.primary, letterSpacing: 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
