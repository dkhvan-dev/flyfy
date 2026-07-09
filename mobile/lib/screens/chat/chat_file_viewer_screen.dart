import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../core/files/app_file_opener.dart';
import '../../core/files/chat_file_cache.dart';
import '../../core/network/file_api.dart';
import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';

class ChatFileViewerScreen extends StatefulWidget {
  const ChatFileViewerScreen({
    super.key,
    required this.downloaded,
    this.fileOpener,
  });

  final ChatDownloadedFile downloaded;
  final AppFileOpener? fileOpener;

  @override
  State<ChatFileViewerScreen> createState() => _ChatFileViewerScreenState();
}

class _ChatFileViewerScreenState extends State<ChatFileViewerScreen> {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

  late final AppFileOpener _fileOpener = widget.fileOpener ?? AppFileOpener();
  double _dragOffset = 0;
  bool _opening = false;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? details.delta.dy;
    if (delta == 0) return;

    setState(() => _dragOffset = math.max(0, _dragOffset + delta));
  }

  void _dismissBySwipeDown(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragOffset >= _dismissDistance || velocity >= _dismissVelocity;
    if (shouldDismiss) {
      Navigator.of(context).pop();
      return;
    }
    if (_dragOffset == 0) return;
    setState(() => _dragOffset = 0);
  }

  void _resetDragOffset() {
    if (_dragOffset == 0) return;
    setState(() => _dragOffset = 0);
  }

  Future<void> _openExternal() async {
    if (_opening) return;

    final l10n = AppLocalizations.of(context)!;
    final contentType = widget.downloaded.metadata?.effectiveContentType ?? '';

    setState(() => _opening = true);
    final result = await _fileOpener.open(
      widget.downloaded.file.path,
      contentType: contentType.trim().isEmpty ? null : contentType,
    );
    if (!mounted) return;

    setState(() => _opening = false);
    if (result.isDone) return;

    await showErrorDialog(
      context,
      title: l10n.error,
      message: l10n.chatAttachmentOpenFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final metadata = widget.downloaded.metadata;
    final title = _fileTitle(context, widget.downloaded);
    final subtitle = _fileSubtitle(metadata);
    final contentOpacity = (1 - (_dragOffset / 360)).clamp(0.62, 1.0);

    return Scaffold(
      backgroundColor: colors.backgroundDeep,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _dismissBySwipeDown,
          onVerticalDragCancel: _resetDragOffset,
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Opacity(
                    opacity: contentOpacity.toDouble(),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 84,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: AppBoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primaryContainer.withValues(
                                    alpha: 0.18,
                                  ),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.32,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  _fileIcon(metadata),
                                  color: colors.primary,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle(
                                  color: colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle(
                                    color: colors.white.withValues(alpha: 0.68),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.28,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _opening
                                      ? null
                                      : () => unawaited(_openExternal()),
                                  icon: _opening
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.textPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.open_in_new_rounded),
                                  label: Text(l10n.chatExternalLinkOpenAction),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.textPrimary,
                                    disabledBackgroundColor: colors.primary
                                        .withValues(alpha: 0.5),
                                    disabledForegroundColor: colors.textPrimary
                                        .withValues(alpha: 0.72),
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppBorderRadius.circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _ViewerIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: AppBoxDecoration(
          shape: BoxShape.circle,
          color: colors.scrim.withValues(alpha: 0.46),
          border: Border.all(color: colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: colors.white, size: 24),
      ),
    );
  }
}

String _fileTitle(BuildContext context, ChatDownloadedFile downloaded) {
  final metadataName = downloaded.metadata?.originalName.trim() ?? '';
  if (metadataName.isNotEmpty) return metadataName;

  final segments = downloaded.file.uri.pathSegments;
  final localName = segments.isEmpty ? '' : Uri.decodeComponent(segments.last);
  if (localName.trim().isNotEmpty) return localName.trim();

  return AppLocalizations.of(context)!.chatSharedUnknownFile;
}

String _fileSubtitle(FileMetadataVm? metadata) {
  if (metadata == null) return '';

  final size = _formatAttachmentSize(metadata.sizeBytes);
  final extension = metadata.extensionLabel.trim();
  return extension.isEmpty ? size : '$size | $extension';
}

IconData _fileIcon(FileMetadataVm? metadata) {
  final extension = metadata?.extensionLabel.toLowerCase() ?? '';
  if (extension == 'pdf') return Icons.picture_as_pdf_rounded;
  if (extension == 'zip' || extension == 'rar' || extension == '7z') {
    return Icons.archive_rounded;
  }
  if (extension == 'xls' || extension == 'xlsx' || extension == 'csv') {
    return Icons.table_chart_rounded;
  }
  if (extension == 'doc' || extension == 'docx' || extension == 'txt') {
    return Icons.article_rounded;
  }
  if (metadata?.isAudio ?? false) return Icons.mic_rounded;
  if (metadata?.isVideo ?? false) return Icons.movie_rounded;
  if (metadata?.isImage ?? false) return Icons.image_rounded;
  return Icons.description_rounded;
}

String _formatAttachmentSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final fractionDigits = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(fractionDigits)} ${units[unitIndex]}';
}
