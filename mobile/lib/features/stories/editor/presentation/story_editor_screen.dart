import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/file_api.dart';
import '../../../../core/ui/error_dialog.dart';
import '../../../../core/ui/filter_sheet_chrome.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../trust/widgets/trust_status_banner.dart';
import '../../../user_routes/models/user_route_models.dart';
import '../../../user_routes/user_route_feature_flags.dart';
import '../../models/post_profile_contract.dart';
import '../../models/post_vm.dart';
import '../../story_ui.dart';
import '../../widgets/story_document_renderer.dart';
import '../domain/story_document.dart';
import '../../../../providers/user_routes_provider.dart';
import 'story_editor_controller.dart';
import 'story_editor_trust_context.dart';
import 'widgets/story_add_block_sheet.dart';
import 'widgets/story_block_canvas.dart';
import 'widgets/story_editor_style.dart';
import 'widgets/story_editor_toolbar.dart';
import 'widgets/story_metadata_panel.dart';
import 'widgets/story_publish_panel.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum StoryEditorImagePickPurpose { cover, inlineImage, gallery }

enum StoryEditorImagePickFailureReason { tooLarge, unsupported, failed }

class StoryEditorPickedImage {
  const StoryEditorPickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get byteSize => bytes.lengthInBytes;
}

class StoryEditorImagePickException implements Exception {
  const StoryEditorImagePickException(this.reason);

  final StoryEditorImagePickFailureReason reason;
}

abstract class StoryEditorImagePickerGateway {
  Future<StoryEditorPickedImage?> pickImage(
    StoryEditorImagePickPurpose purpose,
  );

  Future<List<StoryEditorPickedImage>> pickImages(
    StoryEditorImagePickPurpose purpose,
  );
}

class StoryEditorImagePickerGatewayAdapter
    implements StoryEditorImagePickerGateway {
  StoryEditorImagePickerGatewayAdapter({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const _maxImageBytes = 20 * 1024 * 1024;
  static const _maxGalleryImages = 12;

  final ImagePicker _imagePicker;

  @override
  Future<StoryEditorPickedImage?> pickImage(
    StoryEditorImagePickPurpose purpose,
  ) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 92,
      );
      if (picked == null) {
        return null;
      }

      return await _pickedImageFromXFile(picked);
    } on StoryEditorImagePickException {
      rethrow;
    } catch (_) {
      throw const StoryEditorImagePickException(
        StoryEditorImagePickFailureReason.failed,
      );
    }
  }

  @override
  Future<List<StoryEditorPickedImage>> pickImages(
    StoryEditorImagePickPurpose purpose,
  ) async {
    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 2400,
        imageQuality: 92,
        limit: _maxGalleryImages,
      );
      if (picked.isEmpty) {
        return const [];
      }
      return await Future.wait(picked.map(_pickedImageFromXFile));
    } on StoryEditorImagePickException {
      rethrow;
    } catch (_) {
      throw const StoryEditorImagePickException(
        StoryEditorImagePickFailureReason.failed,
      );
    }
  }

  Future<StoryEditorPickedImage> _pickedImageFromXFile(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const StoryEditorImagePickException(
        StoryEditorImagePickFailureReason.failed,
      );
    }
    if (bytes.lengthInBytes > _maxImageBytes) {
      throw const StoryEditorImagePickException(
        StoryEditorImagePickFailureReason.tooLarge,
      );
    }
    final mimeType = _detectImageMimeType(bytes, fallbackName: picked.name);
    if (mimeType == null) {
      throw const StoryEditorImagePickException(
        StoryEditorImagePickFailureReason.unsupported,
      );
    }

    return StoryEditorPickedImage(
      bytes: bytes,
      fileName: _normalizeImageFileName(picked.name, mimeType),
      mimeType: mimeType,
    );
  }

  String? _detectImageMimeType(
    Uint8List bytes, {
    required String fallbackName,
  }) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    final lowerName = fallbackName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    return null;
  }

  String _normalizeImageFileName(String rawName, String mimeType) {
    final trimmed = rawName.trim();
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    if (trimmed.isEmpty) {
      return 'story-image.$extension';
    }
    final lowerName = trimmed.toLowerCase();
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp')) {
      return trimmed;
    }
    return '$trimmed.$extension';
  }
}

class _StoryTemplateDefinition {
  const _StoryTemplateDefinition({
    required this.id,
    required this.version,
    required this.format,
    required this.category,
    required this.blocks,
  });

  final String id;
  final String version;
  final String format;
  final String category;
  final List<StoryBlock> blocks;
}

enum _StoryTemplateConflictAction { replace, append, metadataOnly }

extension on _StoryTemplateConflictAction {
  StoryEditorTemplateApplyMode get applyMode {
    return switch (this) {
      _StoryTemplateConflictAction.replace =>
        StoryEditorTemplateApplyMode.replace,
      _StoryTemplateConflictAction.append =>
        StoryEditorTemplateApplyMode.append,
      _StoryTemplateConflictAction.metadataOnly =>
        StoryEditorTemplateApplyMode.metadataOnly,
    };
  }
}

class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({
    super.key,
    this.controller,
    this.imagePicker,
    this.userId = 'local-user',
    this.initialStory,
    this.storyId,
    this.communityId,
    this.postProfileKey,
    this.availablePostProfileKeys,
    this.communityCountryCode,
    this.communityCityId,
    this.communityCityName,
    this.communityTrustContext,
    this.returnOnSave = false,
    this.onOpenField,
  });

  final StoryEditorController? controller;
  final StoryEditorImagePickerGateway? imagePicker;
  final String userId;
  final PostVm? initialStory;
  final String? storyId;
  final String? communityId;
  final String? postProfileKey;
  final List<String>? availablePostProfileKeys;
  final String? communityCountryCode;
  final String? communityCityId;
  final String? communityCityName;
  final StoryEditorTrustContext? communityTrustContext;
  final bool returnOnSave;
  final ValueChanged<String>? onOpenField;

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  static const _editorToolbarScrollReserve = 88.0;
  static const _focusedFieldVisibleMargin = StoryEditorSpacing.md;
  static const _focusedFieldRevealDuration = Duration(milliseconds: 160);
  static const _focusedFieldRevealShortDelay = Duration(milliseconds: 80);
  static const _focusedFieldRevealLongDelay = Duration(milliseconds: 260);

  late final StoryEditorController _controller;
  late final StoryEditorImagePickerGateway _imagePicker;
  late final bool _ownsController;
  final _scrollController = ScrollController();
  final _scrollViewKey = GlobalKey();
  final _metadataKey = GlobalKey();
  final _canvasKey = GlobalKey();
  final _publishKey = GlobalKey();
  final _titleFieldKey = GlobalKey();
  final _formatFieldKey = GlobalKey();
  final _categoryFieldKey = GlobalKey();
  final _coverFieldKey = GlobalKey();
  final _placeFieldKey = GlobalKey();
  final _quickPostTextController = TextEditingController();
  final _quickPostFocusNode = FocusNode();
  final _textSelections = <String, TextSelection>{};
  bool _preserveSelectionForInlineToolbarTap = false;
  bool _metadataTextFieldFocused = false;

  bool _previewMode = false;
  bool _isLoadingStory = false;
  bool _loadFailed = false;
  int _focusedFieldRevealToken = 0;
  Timer? _focusedFieldRevealShortTimer;
  Timer? _focusedFieldRevealLongTimer;
  int _blockSequence = 0;
  int _mediaSequence = 0;

  bool get _isCommunityPostCreate =>
      (widget.communityId ?? '').trim().isNotEmpty &&
      widget.initialStory == null &&
      (widget.storyId ?? '').trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StoryEditorController();
    _imagePicker = widget.imagePicker ?? StoryEditorImagePickerGatewayAdapter();
    _initializeControllerIfNeeded();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecoveryPrompt());
  }

  @override
  void didUpdateWidget(covariant StoryEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStory?.id != widget.initialStory?.id ||
        oldWidget.userId != widget.userId ||
        oldWidget.communityId != widget.communityId ||
        oldWidget.postProfileKey != widget.postProfileKey ||
        oldWidget.communityCountryCode != widget.communityCountryCode ||
        oldWidget.communityCityId != widget.communityCityId ||
        oldWidget.communityCityName != widget.communityCityName) {
      _initializeControllerIfNeeded(force: true);
    }
  }

  @override
  void dispose() {
    _focusedFieldRevealShortTimer?.cancel();
    _focusedFieldRevealLongTimer?.cancel();
    _quickPostTextController.dispose();
    _quickPostFocusNode.dispose();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: storyEditorTheme(context),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final state = _controller.state;
              final submissionLocked = _isSubmissionLocked(state);
              final isQuickPost = _isQuickPost(state);
              if (isQuickPost) {
                _syncQuickPostTextController(state);
              }
              final keyboardBottomInset = MediaQuery.viewInsetsOf(
                context,
              ).bottom;
              final keyboardVisible = keyboardBottomInset > 0;
              final metadataTextEditing =
                  _metadataTextFieldFocused && keyboardVisible;
              final showKeyboardFormattingToolbar =
                  !_previewMode &&
                  !submissionLocked &&
                  !isQuickPost &&
                  !metadataTextEditing &&
                  _hasSelectedTextBlock(state) &&
                  (keyboardVisible || _hasSelectedTextRange(state));
              final showEditorToolbar =
                  !_previewMode &&
                  !submissionLocked &&
                  !isQuickPost &&
                  !metadataTextEditing &&
                  !showKeyboardFormattingToolbar;
              final toolbarVisible =
                  showKeyboardFormattingToolbar || showEditorToolbar;
              final scrollBottomPadding =
                  keyboardBottomInset +
                  StoryEditorSpacing.xxl +
                  (toolbarVisible ? _editorToolbarScrollReserve : 0);
              if (_isLoadingStory || state.userId.trim().isEmpty) {
                return Scaffold(
                  body: DecoratedBox(
                    decoration: storyScreenBackground(),
                    child: SafeArea(
                      child: Center(child: Text(l10n.storyEditorLoading)),
                    ),
                  ),
                );
              }
              if (_loadFailed) {
                return Scaffold(
                  body: DecoratedBox(
                    decoration: storyScreenBackground(),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const AppEdgeInsets.all(
                            StoryEditorSpacing.lg,
                          ),
                          child: Text(
                            l10n.storyEditorLoadFailed,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return PopScope(
                canPop: !submissionLocked && !_hasUnsavedChanges(state),
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop ||
                      submissionLocked ||
                      !_hasUnsavedChanges(state)) {
                    return;
                  }
                  final discard = await _confirmDiscardChanges();
                  if (discard && context.mounted) {
                    Navigator.of(context).pop(result);
                  }
                },
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: _StoryEditorAppBar(
                    title: _editorTitle(l10n, state),
                    previewMode: _previewMode,
                    isLocked: submissionLocked,
                    onBack: () => unawaited(_requestClose()),
                    onTogglePreview: () {
                      FocusScope.of(context).unfocus();
                      _controller.selectBlock(null);
                      setState(() {
                        _previewMode = !_previewMode;
                      });
                    },
                  ),
                  body: DecoratedBox(
                    decoration: storyScreenBackground(),
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                key: _scrollViewKey,
                                controller: _scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: AppEdgeInsets.fromLTRB(
                                  StoryEditorSpacing.lg,
                                  StoryEditorSpacing.md,
                                  StoryEditorSpacing.lg,
                                  scrollBottomPadding,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1120,
                                    ),
                                    child: AbsorbPointer(
                                      absorbing: submissionLocked,
                                      child: FocusScope(
                                        canRequestFocus: !submissionLocked,
                                        child: _StoryEditorSubmissionBody(
                                          quickPostMode: _isQuickPost(state),
                                          previewMode: _previewMode,
                                          state: state,
                                          constraints: constraints,
                                          metadataKey: _metadataKey,
                                          canvasKey: _canvasKey,
                                          publishKey: _publishKey,
                                          trustBanner: _trustBanner(),
                                          postModeSelector: _postModeSelector(
                                            state,
                                          ),
                                          quickComposer: _quickPostComposer(
                                            state,
                                          ),
                                          quickMedia: _quickPostMediaPanel(
                                            state,
                                          ),
                                          metadata: _metadataPanel(state),
                                          canvas: _canvasOrPreview(state),
                                          publish: _publishPanel(state),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (toolbarVisible)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: keyboardBottomInset,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showKeyboardFormattingToolbar)
                                    StoryEditorKeyboardFormattingToolbar(
                                      key: const ValueKey(
                                        'story-editor-keyboard-formatting-toolbar',
                                      ),
                                      onInteractionStart:
                                          _beginInlineToolbarInteraction,
                                      onBold: () => _markSelectedText(
                                        StoryInlineMarkType.bold,
                                      ),
                                      onItalic: () => _markSelectedText(
                                        StoryInlineMarkType.italic,
                                      ),
                                      onStrikethrough: () => _markSelectedText(
                                        StoryInlineMarkType.strikethrough,
                                      ),
                                      onUnderline: () => _markSelectedText(
                                        StoryInlineMarkType.underline,
                                      ),
                                    ),
                                  if (showEditorToolbar)
                                    StoryEditorToolbar(
                                      onAddBlock: _openAddBlockSheet,
                                      onHeading: () =>
                                          _insertBlock(StoryBlockType.heading),
                                      onList: () => _insertBlock(
                                        StoryBlockType.bulletedList,
                                      ),
                                      onQuote: () =>
                                          _insertBlock(StoryBlockType.quote),
                                      onImage: () =>
                                          unawaited(_addImageBlock()),
                                      onUndo: _controller.undo,
                                      onRedo: _controller.redo,
                                      canUndo: state.canUndo,
                                      canRedo: state.canRedo,
                                    ),
                                ],
                              ),
                            ),
                          if (submissionLocked)
                            _StoryEditorSubmissionLockOverlay(
                              label: AppLocalizations.of(
                                context,
                              )!.storyEditorAutosaveSaving,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isQuickPost(StoryEditorState state) =>
      PostProfileContract.resolve(state.postProfileKey).isInlineThread;

  String _editorTitle(AppLocalizations l10n, StoryEditorState state) {
    final title = state.metadata.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    return _isQuickPost(state)
        ? l10n.storyEditorQuickPostTitle
        : l10n.storyEditorTitle;
  }

  void _syncQuickPostTextController(StoryEditorState state) {
    if (_quickPostFocusNode.hasFocus) {
      return;
    }
    final body = _quickPostBodyText(state);
    if (_quickPostTextController.text == body) {
      return;
    }
    final selection = _quickPostTextController.selection;
    final nextOffset = math.min(body.length, math.max(0, selection.baseOffset));
    _quickPostTextController.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  String _quickPostBodyText(StoryEditorState state) {
    for (final block in state.document.blocks) {
      if (block.isTextBlock) {
        return block.text ?? '';
      }
    }
    return '';
  }

  Widget _quickPostComposer(StoryEditorState state) {
    return _QuickPostComposer(
      controller: _quickPostTextController,
      focusNode: _quickPostFocusNode,
      onChanged: _updateQuickPostBody,
    );
  }

  Widget? _postModeSelector(StoryEditorState state) {
    final keys = _availablePostProfileKeys(state);
    if (keys.length < 2) {
      return null;
    }
    return _StoryEditorPostModeSelector(
      postProfileKeys: keys,
      selectedPostProfileKey:
          PostProfileContract.normalize(state.postProfileKey) ??
          PostProfileKeys.article,
      onSelected: (key) {
        FocusScope.of(context).unfocus();
        _controller.changePostProfileKey(key);
      },
    );
  }

  List<String> _availablePostProfileKeys(StoryEditorState state) {
    final allowed = widget.availablePostProfileKeys ?? const <String>[];
    final keys = <String>[];
    for (final rawKey in allowed) {
      final key = PostProfileContract.normalize(rawKey);
      if (key == null || keys.contains(key)) {
        continue;
      }
      if (PostProfileKeys.supported.contains(key)) {
        keys.add(key);
      }
    }
    final currentKey =
        PostProfileContract.normalize(state.postProfileKey) ??
        PostProfileKeys.article;
    if (!keys.contains(currentKey) &&
        PostProfileKeys.supported.contains(currentKey)) {
      keys.insert(0, currentKey);
    }
    return keys;
  }

  Widget _quickPostMediaPanel(StoryEditorState state) {
    return _QuickPostMediaPanel(
      state: state,
      onAddPhoto: () => unawaited(_addQuickPostPhoto()),
      onClearCover: () => _controller.changeCover(null),
      onRemoveMedia: _controller.removeMediaUpload,
      onRetryMedia: (localMediaId) =>
          unawaited(_controller.retryMediaUpload(localMediaId)),
    );
  }

  Future<void> _addQuickPostPhoto() async {
    if (_hasQuickPostCoverMedia(_controller.state)) {
      await _addImageBlock();
      return;
    }
    await _queueCoverUpload();
  }

  void _updateQuickPostBody(String text) {
    final blocks = _controller.state.document.blocks;
    StoryBlock? bodyBlock;
    for (final block in blocks) {
      if (block.isTextBlock) {
        bodyBlock = block;
        break;
      }
    }
    if (bodyBlock == null) {
      if (text.isEmpty) {
        return;
      }
      _controller.addBlock(
        StoryBlock.paragraph(id: 'quick-post-body', text: text),
      );
      return;
    }
    _controller.updateBlock(
      bodyBlock.id,
      (block) => block.copyWith(text: text, marks: const []),
    );
  }

  bool _isSubmissionLocked(StoryEditorState state) {
    return state.saveStatus.phase == StoryEditorSavePhase.saving &&
        (state.validationScope == StoryEditorValidationScope.draft ||
            state.validationScope == StoryEditorValidationScope.publish);
  }

  Widget _metadataPanel(StoryEditorState state) {
    final profile = PostProfileContract.resolve(state.postProfileKey);
    return KeyedSubtree(
      key: _metadataKey,
      child: StoryMetadataPanel(
        state: state,
        hidePlaceFields: _isCommunityPostCreate,
        showTemplatePicker: profile.showTemplatePicker,
        showMaterialTaxonomy: profile.showMaterialTaxonomy,
        showTags: profile.showTags,
        showCover: profile.showCover,
        fieldKeys: StoryMetadataPanelFieldKeys(
          title: _titleFieldKey,
          format: _formatFieldKey,
          category: _categoryFieldKey,
          cover: _coverFieldKey,
          place: _placeFieldKey,
        ),
        onTitleChanged: _controller.changeTitle,
        onFormatChanged: _controller.changeFormat,
        onCategoryChanged: _controller.changeCategory,
        onPlaceChanged:
            ({
              placeName,
              placeCountryCode,
              placeCityId,
              clearCountryCode = false,
              clearCityId = false,
            }) {
              _controller.changePlace(
                placeName: placeName,
                placeCountryCode: placeCountryCode,
                placeCityId: placeCityId,
                clearCountryCode: clearCountryCode ?? false,
                clearCityId: clearCityId ?? false,
              );
            },
        onTagsChanged: _controller.changeTags,
        onPickCover: () => unawaited(_queueCoverUpload()),
        onClearCover: () => _controller.changeCover(null),
        onApplyTemplate: _applyTemplate,
        onTextFieldFocusChanged: _handleMetadataTextFieldFocusChanged,
        onTextFieldFocused: _scheduleFocusedFieldReveal,
      ),
    );
  }

  Widget _canvasOrPreview(StoryEditorState state) {
    final child = StoryBlockCanvas(
      state: state,
      onSelectBlock: _controller.selectBlock,
      onUpdateTextBlock: _updateBlockText,
      onUpdateTextSelection: _rememberTextSelection,
      onDeleteBlock: _deleteBlock,
      onRetryMedia: _controller.retryMediaUpload,
      onRemoveMedia: _controller.removeMediaUpload,
      onRemoveGalleryImage: (blockId, imageIndex) => _controller
          .removeGalleryImage(blockId: blockId, imageIndex: imageIndex),
      onAddBlock: _openAddBlockSheet,
      onReorderBlock: _controller.reorderBlock,
      scrollController: _scrollController,
      onTextInputFocused: _scheduleFocusedFieldReveal,
    );
    return KeyedSubtree(key: _canvasKey, child: child);
  }

  Widget _publishPanel(StoryEditorState state) {
    final trustContext = widget.communityTrustContext;
    return KeyedSubtree(
      key: _publishKey,
      child: StoryPublishPanel(
        state: state,
        publishEnabled: trustContext?.blocksPublishing != true,
        hidePlaceChecks: _isCommunityPostCreate,
        onSaveDraft: () => unawaited(_saveDraftAndRevealErrors()),
        onPublish: () => unawaited(_publishAndRevealErrors()),
        onOpenField: _openField,
      ),
    );
  }

  Widget? _trustBanner() {
    final trustContext = widget.communityTrustContext;
    if (trustContext == null) {
      return null;
    }
    return TrustStatusBanner(
      kind: _trustBannerKind(trustContext.kind),
      title: trustContext.title,
      message: trustContext.message,
    );
  }

  TrustStatusBannerKind _trustBannerKind(StoryEditorTrustBannerKind kind) {
    return switch (kind) {
      StoryEditorTrustBannerKind.blocked => TrustStatusBannerKind.blocked,
      StoryEditorTrustBannerKind.muted => TrustStatusBannerKind.muted,
      StoryEditorTrustBannerKind.pendingAppeal =>
        TrustStatusBannerKind.pendingAppeal,
      StoryEditorTrustBannerKind.rejected => TrustStatusBannerKind.rejected,
    };
  }

  Future<void> _saveDraftAndRevealErrors() async {
    FocusScope.of(context).unfocus();
    final returnToCaller =
        _controller.state.mode == StoryEditorMode.create || widget.returnOnSave;
    final story = await _controller.saveDraft(showSuccessStatus: false);
    if (!mounted) return;
    if (story != null) {
      _openSavedPost(story, returnToCaller: returnToCaller);
      return;
    }
    _openFirstValidationError();
  }

  Future<void> _publishAndRevealErrors() async {
    FocusScope.of(context).unfocus();
    final returnToCaller =
        _controller.state.mode == StoryEditorMode.create || widget.returnOnSave;
    final story = await _controller.publish(showSuccessStatus: false);
    if (!mounted) return;
    if (story != null) {
      _openSavedPost(story, returnToCaller: returnToCaller);
      return;
    }
    _openFirstValidationError();
  }

  void _openSavedPost(PostVm story, {required bool returnToCaller}) {
    if (returnToCaller) {
      Navigator.of(context).pop(story);
      return;
    }
    final slug = story.slug.trim().isNotEmpty ? story.slug.trim() : story.id;
    final normalized = slug.trim();
    if (normalized.isEmpty) {
      return;
    }
    context.pushReplacement(
      '/posts/${Uri.encodeComponent(normalized)}',
      extra: story,
    );
  }

  Future<void> _requestClose() async {
    final state = _controller.state;
    if (_isSubmissionLocked(state)) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (!_hasUnsavedChanges(state)) {
      Navigator.of(context).maybePop();
      return;
    }
    final discard = await _confirmDiscardChanges();
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _initializeControllerIfNeeded({bool force = false}) {
    if (!force && _controller.state.userId.trim().isNotEmpty) {
      return;
    }
    final story = widget.initialStory;
    if (story != null) {
      _controller.initializeEdit(userId: widget.userId, story: story);
      return;
    }
    final storyId = (widget.storyId ?? '').trim();
    if (storyId.isNotEmpty) {
      _loadStoryForEdit(storyId);
      return;
    }
    _controller.initializeCreate(
      userId: widget.userId,
      communityId: widget.communityId,
      postProfileKey: widget.postProfileKey,
      placeCountryCode: widget.communityCountryCode,
      placeCityId: widget.communityCityId,
      placeName: widget.communityCityName,
    );
  }

  Future<void> _loadStoryForEdit(String storyId) async {
    setState(() {
      _isLoadingStory = true;
      _loadFailed = false;
    });
    try {
      await _controller.loadStoryForEdit(
        userId: widget.userId,
        storyId: storyId,
      );
    } catch (_) {
      if (!mounted) return;
      _loadFailed = true;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStory = false;
        });
      }
    }
  }

  void _handleMetadataTextFieldFocusChanged(bool hasFocus) {
    if (_metadataTextFieldFocused == hasFocus) {
      return;
    }
    setState(() {
      _metadataTextFieldFocused = hasFocus;
    });
    if (hasFocus) {
      _controller.selectBlock(null);
    }
  }

  void _scheduleFocusedFieldReveal(BuildContext focusedContext) {
    final token = ++_focusedFieldRevealToken;
    _focusedFieldRevealShortTimer?.cancel();
    _focusedFieldRevealLongTimer?.cancel();

    void reveal() {
      if (token != _focusedFieldRevealToken) {
        return;
      }
      _revealFocusedField(focusedContext);
    }

    reveal();
    WidgetsBinding.instance.addPostFrameCallback((_) => reveal());
    _focusedFieldRevealShortTimer = Timer(
      _focusedFieldRevealShortDelay,
      reveal,
    );
    _focusedFieldRevealLongTimer = Timer(_focusedFieldRevealLongDelay, reveal);
  }

  void _revealFocusedField(BuildContext focusedContext) {
    if (!mounted || !focusedContext.mounted || !_scrollController.hasClients) {
      return;
    }

    final scrollRenderObject = _scrollViewKey.currentContext
        ?.findRenderObject();
    final focusedRenderObject = focusedContext.findRenderObject();
    if (scrollRenderObject is! RenderBox ||
        focusedRenderObject is! RenderBox ||
        !scrollRenderObject.hasSize ||
        !focusedRenderObject.hasSize) {
      return;
    }

    late final Rect focusedRect;
    try {
      focusedRect = MatrixUtils.transformRect(
        focusedRenderObject.getTransformTo(scrollRenderObject),
        Offset.zero & focusedRenderObject.size,
      );
    } catch (_) {
      return;
    }

    final keyboardBottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final overlayReserve = _focusedFieldOverlayReserve(keyboardBottomInset);
    final viewportHeight = scrollRenderObject.size.height;
    final visibleTop = _focusedFieldVisibleMargin;
    final visibleBottom = math.max(
      visibleTop + kMinInteractiveDimension,
      viewportHeight -
          keyboardBottomInset -
          overlayReserve -
          _focusedFieldVisibleMargin,
    );
    final visibleCenter = (visibleTop + visibleBottom) / 2;
    final scrollDelta = focusedRect.center.dy - visibleCenter;
    if (scrollDelta.abs() < 1) {
      return;
    }

    final targetOffset = (_scrollController.offset + scrollDelta)
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();
    if ((targetOffset - _scrollController.offset).abs() < 1) {
      return;
    }

    unawaited(
      _scrollController.animateTo(
        targetOffset,
        duration: _focusedFieldRevealDuration,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _focusedFieldOverlayReserve(double keyboardBottomInset) {
    if (keyboardBottomInset <= 0 || _previewMode) {
      return 0;
    }
    final state = _controller.state;
    final metadataTextEditing = _metadataTextFieldFocused;
    final showKeyboardFormattingToolbar =
        !metadataTextEditing && _hasSelectedTextBlock(state);
    final showEditorToolbar =
        !metadataTextEditing && !showKeyboardFormattingToolbar;
    return showKeyboardFormattingToolbar || showEditorToolbar
        ? _editorToolbarScrollReserve
        : 0;
  }

  Future<void> _loadRecoveryPrompt() async {
    if (_controller.state.userId.trim().isEmpty) {
      return;
    }
    final found = await _controller.loadRecoverySnapshot();
    if (!found || !mounted) return;
    await showAppModalDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Theme(
          data: storyEditorTheme(context),
          child: AppModalDialogCard(
            title: Text(l10n.storyEditorRecoveryTitle),
            content: Text(l10n.storyEditorRecoveryMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_controller.discardLocalSnapshot());
                },
                child: Text(l10n.storyEditorRecoveryDiscard),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(_controller.recoverLocalSnapshot());
                },
                child: Text(l10n.storyEditorRecoveryRestore),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddBlockSheet() async {
    FocusScope.of(context).unfocus();
    await showAppModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      useSafeArea: true,
      builder: (context) {
        return Theme(
          data: storyEditorTheme(context),
          child: StoryAddBlockSheet(
            onSelected: (type) {
              Navigator.of(context).pop();
              _insertBlock(type);
            },
          ),
        );
      },
    );
  }

  void _insertBlock(StoryBlockType type) {
    if (type == StoryBlockType.image) {
      unawaited(_addImageBlock());
      return;
    }
    if (type == StoryBlockType.gallery) {
      unawaited(_addGalleryBlock());
      return;
    }
    if (type == StoryBlockType.routeReference &&
        UserRouteFeatureFlags.customRoutesEnabled) {
      unawaited(_addRouteReferenceBlock());
      return;
    }
    if (type == StoryBlockType.routeReference) {
      return;
    }
    _controller.addBlock(_newBlock(type));
  }

  Future<void> _addImageBlock() async {
    final image = await _pickImage(StoryEditorImagePickPurpose.inlineImage);
    if (image == null) return;
    _mediaSequence++;
    await _controller.addImage(
      localMediaId: 'local-media-$_mediaSequence',
      fileName: image.fileName,
      mimeType: image.mimeType,
      byteSize: image.byteSize,
      bytes: image.bytes,
    );
  }

  Future<void> _addGalleryBlock() async {
    final images = await _pickImages(StoryEditorImagePickPurpose.gallery);
    if (images.isEmpty) return;
    _mediaSequence++;
    final localGalleryId = 'gallery-local-$_mediaSequence';
    await _controller.addGalleryUploads(
      localGalleryId: localGalleryId,
      images: [
        for (var index = 0; index < images.length; index++)
          StoryEditorGalleryUploadDraft(
            localMediaId: '$localGalleryId-${index + 1}',
            fileName: images[index].fileName,
            mimeType: images[index].mimeType,
            byteSize: images[index].byteSize,
            bytes: images[index].bytes,
          ),
      ],
    );
  }

  Future<void> _addRouteReferenceBlock() async {
    FocusScope.of(context).unfocus();
    final route = await showAppModalBottomSheet<UserRouteVm>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      builder: (context) => const _RouteReferencePickerSheet(),
    );
    if (route == null || !mounted) return;

    final id =
        '${_blockIdPrefix(StoryBlockType.routeReference)}-${++_blockSequence}';
    _controller.addBlock(
      StoryBlock.routeReference(
        id: id,
        route: StoryRouteReference(
          routeId: route.id,
          title: route.title,
          description: route.description,
          profile: route.profile.backendValue,
          distanceMeters: route.snapshot.distanceMeters,
          durationSeconds: route.snapshot.durationSeconds,
          stopsCount: route.points.length,
          shareUrl: _shareUrlForRoute(route.id),
        ),
      ),
    );
  }

  String _shareUrlForRoute(String routeId) {
    return 'https://inflap.app/user-routes/${Uri.encodeComponent(routeId)}';
  }

  Future<void> _queueCoverUpload() async {
    final image = await _pickImage(StoryEditorImagePickPurpose.cover);
    if (image == null) return;
    _mediaSequence++;
    await _controller.uploadCover(
      localMediaId: 'cover-local-$_mediaSequence',
      fileName: image.fileName,
      mimeType: image.mimeType,
      byteSize: image.byteSize,
      bytes: image.bytes,
    );
  }

  Future<StoryEditorPickedImage?> _pickImage(
    StoryEditorImagePickPurpose purpose,
  ) async {
    FocusScope.of(context).unfocus();
    try {
      return await _imagePicker.pickImage(purpose);
    } on StoryEditorImagePickException catch (error) {
      if (!mounted) return null;
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: _imagePickErrorMessage(error.reason),
      );
      return null;
    }
  }

  Future<List<StoryEditorPickedImage>> _pickImages(
    StoryEditorImagePickPurpose purpose,
  ) async {
    FocusScope.of(context).unfocus();
    try {
      return await _imagePicker.pickImages(purpose);
    } on StoryEditorImagePickException catch (error) {
      if (!mounted) return const [];
      final l10n = AppLocalizations.of(context)!;
      await showErrorDialog(
        context,
        title: l10n.error,
        message: _imagePickErrorMessage(error.reason),
      );
      return const [];
    }
  }

  String _imagePickErrorMessage(StoryEditorImagePickFailureReason reason) {
    final l10n = AppLocalizations.of(context)!;
    return switch (reason) {
      StoryEditorImagePickFailureReason.tooLarge =>
        l10n.storyEditorImagePickTooLarge,
      StoryEditorImagePickFailureReason.unsupported =>
        l10n.storyEditorImagePickUnsupported,
      StoryEditorImagePickFailureReason.failed =>
        l10n.storyEditorImagePickFailed,
    };
  }

  StoryBlock _newBlock(StoryBlockType type) {
    final id = '${_blockIdPrefix(type)}-${++_blockSequence}';
    return switch (type) {
      StoryBlockType.paragraph => StoryBlock.paragraph(id: id, text: ''),
      StoryBlockType.heading => StoryBlock.heading(id: id, text: ''),
      StoryBlockType.bulletedList => StoryBlock.bulletedList(id: id, text: ''),
      StoryBlockType.numberedList => StoryBlock.numberedList(id: id, text: ''),
      StoryBlockType.quote => StoryBlock.quote(id: id, text: ''),
      StoryBlockType.callout => StoryBlock.callout(id: id, text: ''),
      StoryBlockType.gallery => StoryBlock.gallery(
        id: id,
        gallery: StoryGalleryPayload(
          images: const [
            StoryImagePayload(
              fileId: '',
              uploadState: StoryUploadState.uploading,
            ),
          ],
        ),
      ),
      StoryBlockType.divider => StoryBlock.divider(id: id),
      StoryBlockType.placeReference => StoryBlock.placeReference(
        id: id,
        place: const StoryPlaceReference(name: ''),
      ),
      StoryBlockType.routeReference => StoryBlock.routeReference(
        id: id,
        route: const StoryRouteReference(routeId: '', title: ''),
      ),
      StoryBlockType.image => StoryBlock.image(
        id: id,
        image: const StoryImagePayload(
          fileId: '',
          uploadState: StoryUploadState.uploading,
        ),
      ),
    };
  }

  void _updateBlockText(String blockId, String text) {
    _controller.updateBlock(blockId, (block) {
      if (block.type == StoryBlockType.placeReference) {
        return block.copyWith(
          place: (block.place ?? const StoryPlaceReference(name: '')).copyWith(
            name: text,
          ),
        );
      }
      if (block.type == StoryBlockType.routeReference) {
        return block;
      }
      return block.copyWith(
        text: text,
        marks: _clampInlineMarks(block.marks, text.length),
      );
    });
  }

  void _rememberTextSelection(String blockId, TextSelection selection) {
    if (_preserveSelectionForInlineToolbarTap && selection.isCollapsed) {
      return;
    }
    _textSelections[blockId] = selection;
  }

  void _beginInlineToolbarInteraction() {
    _preserveSelectionForInlineToolbarTap = true;
  }

  void _deleteBlock(String blockId) {
    _textSelections.remove(blockId);
    _controller.deleteBlock(blockId);
  }

  void _markSelectedText(StoryInlineMarkType markType) {
    try {
      final blockId = _controller.state.selectedBlockId;
      if (blockId == null) return;
      _controller.updateBlock(blockId, (block) {
        if (!block.isTextBlock) return block;
        final text = block.text ?? '';
        if (text.trim().isEmpty) return block;
        final range = _formattingRangeForBlock(block, text.length);
        if (range == null) return block;
        final nextMark = _inlineMarkForRange(markType, range);
        if (nextMark == null) return block;
        return block.copyWith(
          marks: _toggleInlineMark(block.marks, nextMark, text.length),
        );
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preserveSelectionForInlineToolbarTap = false;
      });
    }
  }

  StoryInlineMark? _inlineMarkForRange(
    StoryInlineMarkType markType,
    TextRange range,
  ) {
    return switch (markType) {
      StoryInlineMarkType.bold => StoryInlineMark.bold(
        start: range.start,
        end: range.end,
      ),
      StoryInlineMarkType.italic => StoryInlineMark.italic(
        start: range.start,
        end: range.end,
      ),
      StoryInlineMarkType.underline => StoryInlineMark.underline(
        start: range.start,
        end: range.end,
      ),
      StoryInlineMarkType.strikethrough => StoryInlineMark.strikethrough(
        start: range.start,
        end: range.end,
      ),
      StoryInlineMarkType.link => null,
    };
  }

  TextRange? _formattingRangeForBlock(StoryBlock block, int textLength) {
    if (textLength <= 0) return null;
    final selection = _textSelections[block.id];
    if (selection != null && selection.isValid && !selection.isCollapsed) {
      final start = _clampTextOffset(selection.start, textLength);
      final end = _clampTextOffset(selection.end, textLength);
      final normalizedStart = start < end ? start : end;
      final normalizedEnd = start < end ? end : start;
      if (normalizedEnd > normalizedStart) {
        return TextRange(start: normalizedStart, end: normalizedEnd);
      }
    }
    return null;
  }

  List<StoryInlineMark> _toggleInlineMark(
    List<StoryInlineMark> marks,
    StoryInlineMark mark,
    int textLength,
  ) {
    final normalized = _clampInlineMarks(marks, textLength);
    final alreadyApplied = normalized.any((candidate) {
      return candidate.type == mark.type &&
          candidate.start == mark.start &&
          candidate.end == mark.end;
    });
    if (alreadyApplied) {
      return normalized
          .where(
            (candidate) =>
                candidate.type != mark.type ||
                candidate.start != mark.start ||
                candidate.end != mark.end,
          )
          .toList(growable: false);
    }
    return [...normalized, mark];
  }

  List<StoryInlineMark> _clampInlineMarks(
    List<StoryInlineMark> marks,
    int textLength,
  ) {
    if (textLength <= 0) return const [];
    return marks
        .where((mark) => mark.start >= 0 && mark.end > mark.start)
        .map(
          (mark) => mark.copyWith(
            start: _clampTextOffset(mark.start, textLength),
            end: _clampTextOffset(mark.end, textLength),
          ),
        )
        .where((mark) => mark.end > mark.start)
        .toList(growable: false);
  }

  int _clampTextOffset(int value, int max) => value.clamp(0, max).toInt();

  Future<void> _applyTemplate(StoryEditorTemplatePreset preset) async {
    final l10n = AppLocalizations.of(context)!;
    final template = _buildTemplateDefinition(preset, l10n);
    if (_controller.state.canApplyTemplateSilently) {
      _applyTemplateDefinition(template);
      return;
    }
    final action = await _showTemplateConflictSheet(template);
    if (!mounted || action == null) return;
    _applyTemplateDefinition(template, mode: action.applyMode);
  }

  _StoryTemplateDefinition _buildTemplateDefinition(
    StoryEditorTemplatePreset preset,
    AppLocalizations l10n,
  ) {
    return switch (preset) {
      StoryEditorTemplatePreset.weekendGuide => _StoryTemplateDefinition(
        id: 'weekend_guide',
        version: '1',
        format: 'GUIDE',
        category: 'GUIDE',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateWeekendHeading,
          ),
          StoryBlock.bulletedList(
            id: 'list-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateWeekendList,
          ),
        ],
      ),
      StoryEditorTemplatePreset.photoEssay => _StoryTemplateDefinition(
        id: 'photo_essay',
        version: '1',
        format: 'PHOTO_ESSAY',
        category: 'PHOTO_ESSAY',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplatePhotoHeading,
          ),
        ],
      ),
      StoryEditorTemplatePreset.foodNotes => _StoryTemplateDefinition(
        id: 'food_notes',
        version: '1',
        format: 'CULINARY',
        category: 'CULINARY',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateFoodHeading,
          ),
          StoryBlock.paragraph(
            id: 'paragraph-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateFoodParagraph,
          ),
        ],
      ),
      StoryEditorTemplatePreset.cityWalk => _StoryTemplateDefinition(
        id: 'city_walk',
        version: '1',
        format: 'GUIDE',
        category: 'GUIDE',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCityWalkHeading,
          ),
          StoryBlock.numberedList(
            id: 'list-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCityWalkList,
          ),
          StoryBlock.paragraph(
            id: 'paragraph-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCityWalkParagraph,
          ),
        ],
      ),
      StoryEditorTemplatePreset.hiddenGems => _StoryTemplateDefinition(
        id: 'hidden_gems',
        version: '1',
        format: 'ARTICLE',
        category: 'JOURNAL',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateHiddenGemsHeading,
          ),
          StoryBlock.bulletedList(
            id: 'list-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateHiddenGemsList,
          ),
          StoryBlock.callout(
            id: 'callout-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateHiddenGemsCallout,
          ),
        ],
      ),
      StoryEditorTemplatePreset.practicalTips => _StoryTemplateDefinition(
        id: 'practical_tips',
        version: '1',
        format: 'GUIDE',
        category: 'GUIDE',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplatePracticalTipsHeading,
          ),
          StoryBlock.bulletedList(
            id: 'list-template-${++_blockSequence}',
            text: l10n.storyEditorTemplatePracticalTipsList,
          ),
          StoryBlock.callout(
            id: 'callout-template-${++_blockSequence}',
            text: l10n.storyEditorTemplatePracticalTipsCallout,
          ),
        ],
      ),
      StoryEditorTemplatePreset.cultureRoute => _StoryTemplateDefinition(
        id: 'culture_route',
        version: '1',
        format: 'ARTICLE',
        category: 'JOURNAL',
        blocks: [
          StoryBlock.heading(
            id: 'heading-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCultureRouteHeading,
          ),
          StoryBlock.paragraph(
            id: 'paragraph-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCultureRouteParagraph,
          ),
          StoryBlock.quote(
            id: 'quote-template-${++_blockSequence}',
            text: l10n.storyEditorTemplateCultureRouteQuote,
          ),
        ],
      ),
    };
  }

  void _applyTemplateDefinition(
    _StoryTemplateDefinition template, {
    StoryEditorTemplateApplyMode mode = StoryEditorTemplateApplyMode.replace,
  }) {
    _controller.applyTemplate(
      templateId: template.id,
      templateVersion: template.version,
      format: template.format,
      category: template.category,
      blocks: template.blocks,
      mode: mode,
    );
  }

  Future<_StoryTemplateConflictAction?> _showTemplateConflictSheet(
    _StoryTemplateDefinition template,
  ) {
    return showAppModalBottomSheet<_StoryTemplateConflictAction>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: AppPalette.transparent,
      useSafeArea: true,
      builder: (context) {
        return Theme(
          data: storyEditorTheme(context),
          child: _StoryTemplateConflictSheet(
            template: template,
            onSelected: (action) => Navigator.of(context).pop(action),
          ),
        );
      },
    );
  }

  void _openField(String field) {
    widget.onOpenField?.call(field);
    final target = switch (field) {
      'title' => _titleFieldKey.currentContext ?? _metadataKey.currentContext,
      'format' => _formatFieldKey.currentContext ?? _metadataKey.currentContext,
      'category' =>
        _categoryFieldKey.currentContext ?? _metadataKey.currentContext,
      'coverFileId' =>
        _coverFieldKey.currentContext ?? _metadataKey.currentContext,
      'place' ||
      'country' => _placeFieldKey.currentContext ?? _metadataKey.currentContext,
      'contentBlocks' || 'mediaQueue' => _canvasKey.currentContext,
      _ => _publishKey.currentContext,
    };
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _openFirstValidationError() {
    final state = _controller.state;
    final shouldReveal =
        state.saveStatus.phase == StoryEditorSavePhase.failed ||
        state.saveStatus.phase == StoryEditorSavePhase.conflict;
    if (!shouldReveal || state.publishValidation.errors.isEmpty) {
      return;
    }
    _openField(state.publishValidation.errors.first.field);
  }

  Future<bool> _confirmDiscardChanges() async {
    final result = await showAppModalDialog<_UnsavedDecision>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Theme(
          data: storyEditorTheme(context),
          child: AppModalDialogCard(
            title: Text(l10n.storyEditorDiscardChangesTitle),
            content: Text(l10n.storyEditorDiscardChangesMessage),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_UnsavedDecision.keepEditing),
                child: Text(l10n.storyEditorKeepEditing),
              ),
              TextButton(
                onPressed:
                    _controller.state.saveStatus.phase ==
                        StoryEditorSavePhase.saving
                    ? null
                    : () async {
                        await _controller.saveDraft();
                        if (context.mounted) {
                          Navigator.of(context).pop(_UnsavedDecision.saveDraft);
                        }
                      },
                child: Text(l10n.storyEditorSaveDraft),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(_UnsavedDecision.discard),
                child: Text(l10n.storyEditorRecoveryDiscard),
              ),
            ],
          ),
        );
      },
    );
    return result == _UnsavedDecision.discard ||
        (result == _UnsavedDecision.saveDraft && !_controller.state.isDirty);
  }

  bool _hasUnsavedChanges(StoryEditorState state) {
    if (state.recovery.hasSnapshot) return true;
    if (state.saveStatus.phase == StoryEditorSavePhase.failed ||
        state.saveStatus.phase == StoryEditorSavePhase.conflict) {
      return true;
    }
    return state.isDirty;
  }

  bool _hasSelectedTextBlock(StoryEditorState state) {
    final blockId = state.selectedBlockId;
    if (blockId == null) return false;
    return state.document.blockById(blockId)?.isTextBlock ?? false;
  }

  bool _hasSelectedTextRange(StoryEditorState state) {
    final blockId = state.selectedBlockId;
    if (blockId == null) return false;
    final selection = _textSelections[blockId];
    return selection != null && selection.isValid && !selection.isCollapsed;
  }

  String _blockIdPrefix(StoryBlockType type) {
    return switch (type) {
      StoryBlockType.paragraph => 'paragraph',
      StoryBlockType.heading => 'heading',
      StoryBlockType.bulletedList => 'list',
      StoryBlockType.numberedList => 'numbered-list',
      StoryBlockType.quote => 'quote',
      StoryBlockType.callout => 'callout',
      StoryBlockType.image => 'image',
      StoryBlockType.gallery => 'gallery',
      StoryBlockType.divider => 'divider',
      StoryBlockType.placeReference => 'place',
      StoryBlockType.routeReference => 'route',
    };
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _RouteReferencePickerSheet extends StatefulWidget {
  const _RouteReferencePickerSheet();

  @override
  State<_RouteReferencePickerSheet> createState() =>
      _RouteReferencePickerSheetState();
}

class _RouteReferencePickerSheetState
    extends State<_RouteReferencePickerSheet> {
  Future<void>? _loadFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= context.read<UserRoutesProvider>().loadMyRoutes(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = adaptive.scale(18);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppPalette.warmSurface21, AppPalette.warmInk63],
            ),
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(adaptive.radius(28)),
            ),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.black.withValues(alpha: 0.36),
                blurRadius: adaptive.scale(30),
                offset: Offset(0, adaptive.scale(-8)),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterSheetHeader(
                  title: l10n.storyEditorRouteReferencePickerTitle,
                  clearLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonLabel,
                  onClear: () => Navigator.maybePop(context),
                  height: adaptive.scale(46),
                  horizontalPadding: horizontalPadding,
                  titleFontSize: adaptive.scale(16),
                  clearFontSize: adaptive.scale(12),
                ),
                Flexible(
                  child: FutureBuilder<void>(
                    future: _loadFuture,
                    builder: (context, snapshot) {
                      final provider = context.watch<UserRoutesProvider>();
                      final routes = provider.myRoutes
                          .where(
                            (route) =>
                                route.visibility != UserRouteVisibility.private,
                          )
                          .toList(growable: false);
                      if (snapshot.connectionState != ConnectionState.done &&
                          routes.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppPalette.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError && routes.isEmpty) {
                        return _RouteReferencePickerStateView(
                          icon: Icons.error_outline_rounded,
                          title: l10n.storyEditorRouteReferenceLoadError,
                          actionLabel: l10n.retry,
                          onAction: () {
                            setState(() {
                              _loadFuture = context
                                  .read<UserRoutesProvider>()
                                  .loadMyRoutes(limit: 50);
                            });
                          },
                        );
                      }
                      if (routes.isEmpty) {
                        return _RouteReferencePickerStateView(
                          icon: Icons.route_rounded,
                          title: l10n.storyEditorRouteReferenceEmptyState,
                        );
                      }
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          adaptive.scale(14),
                          horizontalPadding,
                          adaptive.scale(18) + safeBottomInset,
                        ),
                        itemCount: routes.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: adaptive.scale(10)),
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return _RouteReferencePickerTile(
                            route: route,
                            onTap: () => Navigator.of(context).pop(route),
                          );
                        },
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

class _RouteReferencePickerStateView extends StatelessWidget {
  const _RouteReferencePickerStateView({
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
    final adaptive = StoryAdaptive.of(context);
    return Center(
      child: Padding(
        padding: AppEdgeInsets.all(adaptive.scale(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppPalette.primary, size: adaptive.scale(34)),
            SizedBox(height: adaptive.scale(12)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StoryPalette.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: adaptive.scale(14)),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: AppPalette.black,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteReferencePickerTile extends StatelessWidget {
  const _RouteReferencePickerTile({required this.route, required this.onTap});

  final UserRouteVm route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;
    final radius = AppBorderRadius.circular(adaptive.radius(18));
    final description = (route.description ?? '').trim();
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: AppBoxDecoration(
            color: AppPalette.warmSurface28,
            borderRadius: radius,
            border: Border.all(
              color: AppPalette.primary.withValues(alpha: 0.13),
            ),
          ),
          child: Padding(
            padding: AppEdgeInsets.symmetric(
              horizontal: adaptive.scale(14),
              vertical: adaptive.scale(13),
            ),
            child: Row(
              children: [
                Container(
                  width: adaptive.scale(42),
                  height: adaptive.scale(42),
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.primary.withValues(alpha: 0.13),
                    border: Border.all(
                      color: AppPalette.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: AppPalette.primary,
                    size: adaptive.scale(21),
                  ),
                ),
                SizedBox(width: adaptive.scale(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: StoryPalette.text,
                          fontSize: adaptive.scale(15.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: adaptive.scale(4)),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle(
                            color: StoryPalette.textSoft.withValues(
                              alpha: 0.82,
                            ),
                            fontSize: adaptive.scale(12.5),
                            height: 1.22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                      SizedBox(height: adaptive.scale(8)),
                      Wrap(
                        spacing: adaptive.scale(8),
                        runSpacing: adaptive.scale(6),
                        children: [
                          _RoutePickerMetricChip(
                            icon: Icons.schedule_rounded,
                            label: _formatRouteDuration(
                              route.snapshot.durationSeconds,
                              l10n,
                            ),
                          ),
                          _RoutePickerMetricChip(
                            icon: Icons.straighten_rounded,
                            label: _formatRouteDistance(
                              route.snapshot.distanceMeters,
                              l10n,
                            ),
                          ),
                          _RoutePickerMetricChip(
                            icon: Icons.pin_drop_outlined,
                            label: l10n.userRoutesStopsCount(
                              route.points.length,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: adaptive.scale(8)),
                Icon(
                  Icons.add_rounded,
                  color: AppPalette.primary,
                  size: adaptive.scale(22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutePickerMetricChip extends StatelessWidget {
  const _RoutePickerMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
      ),
      child: Padding(
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(8),
          vertical: adaptive.scale(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppPalette.primary, size: adaptive.scale(13)),
            SizedBox(width: adaptive.scale(5)),
            Text(
              label,
              style: AppTextStyle(
                color: AppPalette.amberLight16,
                fontSize: adaptive.scale(11),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRouteDuration(int seconds, AppLocalizations l10n) {
  final minutes = (seconds / 60).round().clamp(1, 1440);
  return l10n.routeDurationMinutesShort(minutes);
}

String _formatRouteDistance(int meters, AppLocalizations l10n) {
  if (meters >= 1000) {
    final kilometers = meters / 1000;
    return l10n.routeDistanceKilometersShort(
      kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1),
    );
  }
  return l10n.routeDistanceMetersShort(meters);
}

class _StoryEditorSubmissionLockOverlay extends StatelessWidget {
  const _StoryEditorSubmissionLockOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Positioned.fill(
      key: const ValueKey('story-editor-submission-lock'),
      child: ColoredBox(
        color: AppPalette.black.withValues(alpha: 0.42),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: adaptive.isNarrow ? 260 : 320,
            ),
            child: DecoratedBox(
              decoration: AppBoxDecoration(
                color: StoryPalette.surfaceRaised,
                borderRadius: AppBorderRadius.circular(adaptive.radius(20)),
                border: Border.all(
                  color: AppPalette.primary.withValues(alpha: 0.20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: AppEdgeInsets.symmetric(
                  horizontal: adaptive.scale(20, minFactor: 0.9),
                  vertical: adaptive.scale(18, minFactor: 0.9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: adaptive.scale(22, minFactor: 0.9),
                      child: const CircularProgressIndicator(
                        color: AppPalette.primary,
                        strokeWidth: 2.4,
                      ),
                    ),
                    SizedBox(width: adaptive.scale(14, minFactor: 0.9)),
                    Flexible(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StoryPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryEditorSubmissionBody extends StatelessWidget {
  const _StoryEditorSubmissionBody({
    required this.quickPostMode,
    required this.previewMode,
    required this.state,
    required this.constraints,
    required this.metadataKey,
    required this.canvasKey,
    required this.publishKey,
    required this.trustBanner,
    required this.postModeSelector,
    required this.quickComposer,
    required this.quickMedia,
    required this.metadata,
    required this.canvas,
    required this.publish,
  });

  final bool quickPostMode;
  final bool previewMode;
  final StoryEditorState state;
  final BoxConstraints constraints;
  final GlobalKey metadataKey;
  final GlobalKey canvasKey;
  final GlobalKey publishKey;
  final Widget? trustBanner;
  final Widget? postModeSelector;
  final Widget quickComposer;
  final Widget quickMedia;
  final Widget metadata;
  final Widget canvas;
  final Widget publish;

  @override
  Widget build(BuildContext context) {
    if (previewMode) {
      return _StoryEditorPreviewPage(state: state);
    }
    if (quickPostMode) {
      return _QuickPostEditorLayout(
        trustBanner: trustBanner,
        postModeSelector: postModeSelector,
        composer: quickComposer,
        media: quickMedia,
        publish: publish,
      );
    }
    return _EditorFormLayout(
      constraints: constraints,
      metadataKey: metadataKey,
      canvasKey: canvasKey,
      publishKey: publishKey,
      trustBanner: trustBanner,
      postModeSelector: postModeSelector,
      metadata: metadata,
      canvas: canvas,
      publish: publish,
    );
  }
}

class _QuickPostEditorLayout extends StatelessWidget {
  const _QuickPostEditorLayout({
    required this.trustBanner,
    required this.postModeSelector,
    required this.composer,
    required this.media,
    required this.publish,
  });

  final Widget? trustBanner;
  final Widget? postModeSelector;
  final Widget composer;
  final Widget media;
  final Widget publish;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (trustBanner != null) ...[
              trustBanner!,
              const SizedBox(height: StoryEditorSpacing.lg),
            ],
            if (postModeSelector != null) ...[
              postModeSelector!,
              const SizedBox(height: StoryEditorSpacing.lg),
            ],
            composer,
            const SizedBox(height: StoryEditorSpacing.lg),
            media,
            const SizedBox(height: StoryEditorSpacing.lg),
            publish,
          ],
        ),
      ),
    );
  }
}

class _StoryEditorPostModeSelector extends StatelessWidget {
  const _StoryEditorPostModeSelector({
    required this.postProfileKeys,
    required this.selectedPostProfileKey,
    required this.onSelected,
  });

  final List<String> postProfileKeys;
  final String selectedPostProfileKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      key: const ValueKey('story-editor-post-mode-selector'),
      decoration: AppBoxDecoration(
        color: StoryPalette.surface,
        borderRadius: AppBorderRadius.circular(22),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(StoryEditorSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.communityPostModeSelectorLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppPalette.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: StoryEditorSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in postProfileKeys)
                  ChoiceChip(
                    key: ValueKey('story-editor-post-mode-$key'),
                    label: Text(_postProfileModeLabel(key, l10n)),
                    selected: key == selectedPostProfileKey,
                    showCheckmark: false,
                    onSelected: (_) => onSelected(key),
                    backgroundColor: StoryPalette.surfaceRaised.withValues(
                      alpha: 0.72,
                    ),
                    selectedColor: AppPalette.primary.withValues(alpha: 0.22),
                    side: BorderSide(
                      color: key == selectedPostProfileKey
                          ? AppPalette.primary
                          : AppPalette.primary.withValues(alpha: 0.16),
                    ),
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(
                          color: key == selectedPostProfileKey
                              ? AppPalette.primary
                              : StoryPalette.textSoft,
                          fontWeight: FontWeight.w800,
                        ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.circular(999),
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

class _QuickPostComposer extends StatelessWidget {
  const _QuickPostComposer({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      key: const ValueKey('quick-post-composer'),
      decoration: AppBoxDecoration(
        color: StoryPalette.surface,
        borderRadius: AppBorderRadius.circular(24),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(StoryEditorSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.storyEditorQuickPostTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: StoryPalette.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: StoryEditorSpacing.xs),
            Text(
              l10n.storyEditorQuickPostSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: StoryPalette.textSoft,
                height: 1.35,
              ),
            ),
            const SizedBox(height: StoryEditorSpacing.lg),
            TextField(
              key: const ValueKey('quick-post-body-field'),
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              minLines: 6,
              maxLines: 12,
              maxLength: StoryDocumentLimits.maxTextBlockLength,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: StoryPalette.text,
                height: 1.35,
              ),
              decoration: AppInputDecoration(
                hintText: l10n.storyEditorQuickPostHint,
                hintStyle: AppTextStyle(
                  color: StoryPalette.textMuted.withValues(alpha: 0.82),
                ),
                filled: true,
                fillColor: StoryPalette.surfaceRaised.withValues(alpha: 0.72),
                counterStyle: AppTextStyle(color: StoryPalette.textMuted),
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppPalette.white.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppPalette.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppPalette.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _postProfileModeLabel(String key, AppLocalizations l10n) {
  return switch (PostProfileContract.normalize(key)) {
    PostProfileKeys.quickPost => l10n.communityPostModeQuickPost,
    PostProfileKeys.listing => l10n.communityPostModeListing,
    PostProfileKeys.eventAnnouncement =>
      l10n.communityPostModeEventAnnouncement,
    PostProfileKeys.questionAnswer => l10n.communityPostModeQuestionAnswer,
    PostProfileKeys.tripPlan => l10n.communityPostModeTripPlan,
    _ => l10n.communityPostModeArticle,
  };
}

class _QuickPostMediaPanel extends StatelessWidget {
  const _QuickPostMediaPanel({
    required this.state,
    required this.onAddPhoto,
    required this.onClearCover,
    required this.onRemoveMedia,
    required this.onRetryMedia,
  });

  final StoryEditorState state;
  final VoidCallback onAddPhoto;
  final VoidCallback onClearCover;
  final ValueChanged<String> onRemoveMedia;
  final ValueChanged<String> onRetryMedia;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaItems = state.mediaQueue.items
        .where((item) => item.status != StoryEditorMediaStatus.removed)
        .toList(growable: false);

    return DecoratedBox(
      key: const ValueKey('quick-post-media-panel'),
      decoration: AppBoxDecoration(
        color: StoryPalette.surface,
        borderRadius: AppBorderRadius.circular(24),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(StoryEditorSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.storyEditorChecklistMedia,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: StoryPalette.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('quick-post-add-photo'),
                  onPressed: onAddPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.storyInlineImageAddAction),
                ),
              ],
            ),
            if (mediaItems.isEmpty) ...[
              const SizedBox(height: StoryEditorSpacing.sm),
              Text(
                l10n.storyContinueSectionLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: StoryPalette.textSoft,
                  height: 1.35,
                ),
              ),
            ] else ...[
              const SizedBox(height: StoryEditorSpacing.md),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaItems.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: StoryEditorSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = mediaItems[index];
                    return _QuickPostMediaThumbnail(
                      item: item,
                      onRetry: () => onRetryMedia(item.localMediaId),
                      onRemove: () {
                        if (item.kind == StoryEditorMediaUploadKind.cover) {
                          onClearCover();
                        }
                        onRemoveMedia(item.localMediaId);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickPostMediaThumbnail extends StatelessWidget {
  const _QuickPostMediaThumbnail({
    required this.item,
    required this.onRetry,
    required this.onRemove,
  });

  final StoryEditorMediaQueueItem item;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = _quickPostMediaPreview(item);
    final isCover = item.kind == StoryEditorMediaUploadKind.cover;
    final isUploading = item.status == StoryEditorMediaStatus.uploading;
    final isFailed = item.status == StoryEditorMediaStatus.failed;

    return SizedBox(
      width: 108,
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: StoryPalette.surfaceRaised,
          borderRadius: AppBorderRadius.circular(8),
          border: Border.all(
            color: isCover
                ? AppPalette.primary.withValues(alpha: 0.62)
                : AppPalette.white.withValues(alpha: 0.08),
          ),
        ),
        child: ClipRRect(
          borderRadius: AppBorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (preview != null)
                Image(image: preview, fit: BoxFit.cover)
              else
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppPalette.primary,
                    size: 30,
                  ),
                ),
              DecoratedBox(
                decoration: AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.black.withValues(alpha: 0.10),
                      AppPalette.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  onPressed: onRemove,
                  iconSize: 16,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: AppEdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.black.withValues(alpha: 0.48),
                    foregroundColor: AppPalette.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppPalette.primary,
                        ),
                      )
                    else if (isFailed)
                      GestureDetector(
                        onTap: onRetry,
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppPalette.primary,
                        ),
                      )
                    else
                      Icon(
                        isCover
                            ? Icons.image_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color: AppPalette.primary,
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isCover
                            ? l10n.storyEditorChecklistCover
                            : l10n.storyEditorBlockImage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _StoryEditorAppBar({
    required this.title,
    required this.previewMode,
    required this.isLocked,
    required this.onBack,
    required this.onTogglePreview,
  });

  final String title;
  final bool previewMode;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onTogglePreview;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact =
        MediaQuery.sizeOf(context).width < StoryEditorBreakpoints.compact;
    final previewLabel = previewMode
        ? l10n.storyEditorEditMode
        : l10n.storyEditorPreviewMode;

    return AppBar(
      backgroundColor: StoryPalette.backgroundTop,
      surfaceTintColor: AppPalette.transparent,
      foregroundColor: StoryPalette.text,
      automaticallyImplyLeading: false,
      leading: IconButton(
        key: const ValueKey('story-editor-back-button'),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: isLocked ? null : onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      titleSpacing: StoryEditorSpacing.md,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: StoryPalette.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        Padding(
          padding: const AppEdgeInsetsDirectional.only(
            end: StoryEditorSpacing.sm,
          ),
          child: compact
              ? IconButton.filledTonal(
                  tooltip: previewLabel,
                  onPressed: isLocked ? null : onTogglePreview,
                  icon: Icon(
                    previewMode
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                  ),
                )
              : SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.storyEditorEditMode),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(l10n.storyEditorPreviewMode),
                    ),
                  ],
                  selected: {previewMode},
                  onSelectionChanged: isLocked
                      ? null
                      : (_) => onTogglePreview(),
                ),
        ),
      ],
    );
  }
}

class _EditorFormLayout extends StatelessWidget {
  const _EditorFormLayout({
    required this.constraints,
    required this.metadataKey,
    required this.canvasKey,
    required this.publishKey,
    required this.trustBanner,
    required this.postModeSelector,
    required this.metadata,
    required this.canvas,
    required this.publish,
  });

  final BoxConstraints constraints;
  final GlobalKey metadataKey;
  final GlobalKey canvasKey;
  final GlobalKey publishKey;
  final Widget? trustBanner;
  final Widget? postModeSelector;
  final Widget metadata;
  final Widget canvas;
  final Widget publish;

  @override
  Widget build(BuildContext context) {
    final expanded = constraints.maxWidth >= StoryEditorBreakpoints.expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trustBanner != null) ...[
          trustBanner!,
          const SizedBox(height: StoryEditorSpacing.lg),
        ],
        if (postModeSelector != null) ...[
          postModeSelector!,
          const SizedBox(height: StoryEditorSpacing.lg),
        ],
        if (expanded)
          _ExpandedEditorLayout(
            metadata: metadata,
            canvas: canvas,
            publish: publish,
          )
        else
          _CompactEditorLayout(
            metadataKey: metadataKey,
            canvasKey: canvasKey,
            publishKey: publishKey,
            metadata: metadata,
            canvas: canvas,
            publish: publish,
          ),
      ],
    );
  }
}

class _CompactEditorLayout extends StatelessWidget {
  const _CompactEditorLayout({
    required this.metadataKey,
    required this.canvasKey,
    required this.publishKey,
    required this.metadata,
    required this.canvas,
    required this.publish,
  });

  final GlobalKey metadataKey;
  final GlobalKey canvasKey;
  final GlobalKey publishKey;
  final Widget metadata;
  final Widget canvas;
  final Widget publish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        canvas,
        const SizedBox(height: StoryEditorSpacing.lg),
        metadata,
        const SizedBox(height: StoryEditorSpacing.lg),
        publish,
      ],
    );
  }
}

class _ExpandedEditorLayout extends StatelessWidget {
  const _ExpandedEditorLayout({
    required this.metadata,
    required this.canvas,
    required this.publish,
  });

  final Widget metadata;
  final Widget canvas;
  final Widget publish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: canvas),
        const SizedBox(width: StoryEditorSpacing.lg),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              metadata,
              const SizedBox(height: StoryEditorSpacing.lg),
              publish,
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryTemplateConflictSheet extends StatelessWidget {
  const _StoryTemplateConflictSheet({
    required this.template,
    required this.onSelected,
  });

  final _StoryTemplateDefinition template;
  final ValueChanged<_StoryTemplateConflictAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = adaptive.scale(18);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: AppEdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          key: const ValueKey('story-template-conflict-sheet-chrome'),
          decoration: AppBoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppPalette.warmSurface21, AppPalette.warmInk63],
            ),
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(adaptive.radius(28)),
            ),
            border: Border.all(color: AppPalette.white.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.black.withValues(alpha: 0.36),
                blurRadius: adaptive.scale(30),
                offset: Offset(0, adaptive.scale(-8)),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterSheetHeader(
                  title: l10n.storyEditorTemplateConflictTitle,
                  clearLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonLabel,
                  onClear: () => Navigator.maybePop(context),
                  height: adaptive.scale(46),
                  horizontalPadding: horizontalPadding,
                  titleFontSize: adaptive.scale(16),
                  clearFontSize: adaptive.scale(12),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: AppEdgeInsets.fromLTRB(
                      horizontalPadding,
                      adaptive.scale(14),
                      horizontalPadding,
                      adaptive.scale(18) + safeBottomInset,
                    ),
                    children: [
                      Text(
                        l10n.storyEditorTemplateConflictMessage(
                          _storyTemplateFormatLabel(l10n, template.format),
                          _storyTemplateCategoryLabel(l10n, template.category),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StoryPalette.textSoft,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: adaptive.scale(14)),
                      _TemplateConflictOption(
                        title: l10n.storyEditorTemplateConflictReplace,
                        subtitle:
                            l10n.storyEditorTemplateConflictReplaceDescription,
                        icon: Icons.auto_fix_high_outlined,
                        onTap: () =>
                            onSelected(_StoryTemplateConflictAction.replace),
                      ),
                      SizedBox(height: adaptive.scale(10)),
                      _TemplateConflictOption(
                        title: l10n.storyEditorTemplateConflictAppend,
                        subtitle:
                            l10n.storyEditorTemplateConflictAppendDescription,
                        icon: Icons.playlist_add_rounded,
                        onTap: () =>
                            onSelected(_StoryTemplateConflictAction.append),
                      ),
                      SizedBox(height: adaptive.scale(10)),
                      _TemplateConflictOption(
                        title: l10n.storyEditorTemplateConflictMetadataOnly,
                        subtitle: l10n
                            .storyEditorTemplateConflictMetadataOnlyDescription,
                        icon: Icons.tune_rounded,
                        onTap: () => onSelected(
                          _StoryTemplateConflictAction.metadataOnly,
                        ),
                      ),
                    ],
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

class _TemplateConflictOption extends StatelessWidget {
  const _TemplateConflictOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final radius = AppBorderRadius.circular(adaptive.radius(18));
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: AppBoxDecoration(
            color: AppPalette.warmSurface28,
            borderRadius: radius,
            border: Border.all(
              color: AppPalette.primary.withValues(alpha: 0.13),
            ),
          ),
          child: Padding(
            padding: AppEdgeInsets.symmetric(
              horizontal: adaptive.scale(14),
              vertical: adaptive.scale(13),
            ),
            child: Row(
              children: [
                Container(
                  width: adaptive.scale(42),
                  height: adaptive.scale(42),
                  decoration: AppBoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.primary.withValues(alpha: 0.13),
                    border: Border.all(
                      color: AppPalette.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppPalette.primary,
                    size: adaptive.scale(21),
                  ),
                ),
                SizedBox(width: adaptive.scale(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: StoryPalette.text,
                          fontSize: adaptive.scale(15.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: adaptive.scale(4)),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: StoryPalette.textSoft.withValues(alpha: 0.82),
                          fontSize: adaptive.scale(12.5),
                          height: 1.22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: adaptive.scale(8)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.primary,
                  size: adaptive.scale(22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _storyTemplateFormatLabel(AppLocalizations l10n, String value) {
  return switch (value.trim().toUpperCase()) {
    'GUIDE' => l10n.storyFormatGuide,
    'PHOTO_ESSAY' => l10n.storyFormatPhotoEssay,
    'ARTICLE' => l10n.storyFormatArticle,
    'CULINARY' => l10n.storyFormatCulinary,
    _ => l10n.storyFormatStory,
  };
}

String _storyTemplateCategoryLabel(AppLocalizations l10n, String value) {
  return switch (value.trim().toUpperCase()) {
    'GUIDE' => l10n.storyCategoryGuide,
    'PHOTO_ESSAY' => l10n.storyCategoryPhotoEssay,
    'CULINARY' => l10n.storyCategoryCulinary,
    _ => l10n.storyCategoryJournal,
  };
}

class _StoryEditorPreviewPage extends StatelessWidget {
  const _StoryEditorPreviewPage({required this.state});

  final StoryEditorState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final metadata = state.metadata;
    final title = metadata.title.trim().isEmpty
        ? l10n.storyEditorPreviewMode
        : metadata.title.trim();
    final place = [
      (metadata.placeName ?? '').trim(),
      (metadata.placeCountryCode ?? '').trim().toUpperCase(),
    ].where((item) => item.isNotEmpty).join(' / ');
    final coverImage = _storyEditorCoverImageProvider(state);

    return DecoratedBox(
      key: const ValueKey('story-editor-preview-page'),
      decoration: storyEditorPanelDecoration(context),
      child: Padding(
        padding: AppEdgeInsets.all(adaptive.scale(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppBorderRadius.circular(adaptive.radius(24)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: DecoratedBox(
                  key: const ValueKey('story-editor-preview-cover'),
                  decoration: AppBoxDecoration(
                    color: StoryPalette.surfaceRaised,
                    border: Border.all(
                      color: AppPalette.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: coverImage == null
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: StoryPalette.textMuted,
                            size: adaptive.scale(42),
                          ),
                        )
                      : Image(
                          image: coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: StoryPalette.textMuted,
                              size: adaptive.scale(36),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: adaptive.scale(18)),
            Wrap(
              spacing: adaptive.scale(8),
              runSpacing: adaptive.scale(8),
              children: [
                _PreviewMetaChip(
                  label: formatStoryFormat(l10n, metadata.format),
                  icon: Icons.article_outlined,
                ),
                _PreviewMetaChip(
                  label: formatStoryCategory(l10n, metadata.category),
                  icon: Icons.local_offer_outlined,
                ),
                if (place.isNotEmpty)
                  _PreviewMetaChip(label: place, icon: Icons.place_outlined),
              ],
            ),
            SizedBox(height: adaptive.scale(14)),
            Text(
              title,
              style: AppTextStyle(
                color: StoryPalette.text,
                fontSize: adaptive.scale(28, minFactor: 0.78, maxFactor: 1.04),
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            if (metadata.tags.isNotEmpty) ...[
              SizedBox(height: adaptive.scale(14)),
              Wrap(
                spacing: adaptive.scale(8),
                runSpacing: adaptive.scale(8),
                children: [
                  for (final tag in metadata.tags) _PreviewTagChip(label: tag),
                ],
              ),
            ],
            SizedBox(height: adaptive.scale(22)),
            StoryDocumentRenderer(document: state.document),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetaChip extends StatelessWidget {
  const _PreviewMetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(10),
          vertical: adaptive.scale(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: adaptive.scale(15), color: AppPalette.primary),
            SizedBox(width: adaptive.scale(6)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: StoryPalette.text,
                fontSize: adaptive.scale(12),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTagChip extends StatelessWidget {
  const _PreviewTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.06),
        borderRadius: AppBorderRadius.circular(adaptive.radius(999)),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: AppEdgeInsets.symmetric(
          horizontal: adaptive.scale(10),
          vertical: adaptive.scale(6),
        ),
        child: Text(
          label,
          style: AppTextStyle(
            color: StoryPalette.textSoft,
            fontSize: adaptive.scale(12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

ImageProvider<Object>? _storyEditorCoverImageProvider(StoryEditorState state) {
  final upload = _activeCoverUploadForState(state);
  final previewBytes = upload?.previewBytes;
  if (previewBytes != null && previewBytes.isNotEmpty) {
    return MemoryImage(previewBytes);
  }

  final fileId = (upload?.fileId ?? state.metadata.coverFileId ?? '').trim();
  final url = resolvePublicFileContentUrl(fileId);
  if (url == null) {
    return null;
  }
  return NetworkImage(url);
}

StoryEditorMediaQueueItem? _activeCoverUploadForState(StoryEditorState state) {
  for (final item in state.mediaQueue.items.reversed) {
    if (item.kind == StoryEditorMediaUploadKind.cover &&
        item.status != StoryEditorMediaStatus.removed) {
      return item;
    }
  }
  return null;
}

bool _hasQuickPostCoverMedia(StoryEditorState state) {
  if ((state.metadata.coverFileId ?? '').trim().isNotEmpty) {
    return true;
  }
  return _activeCoverUploadForState(state) != null;
}

ImageProvider<Object>? _quickPostMediaPreview(StoryEditorMediaQueueItem item) {
  final previewBytes = item.previewBytes;
  if (previewBytes != null && previewBytes.isNotEmpty) {
    return MemoryImage(previewBytes);
  }

  final url = resolvePublicFileContentUrl(item.fileId ?? '');
  if (url == null) {
    return null;
  }
  return NetworkImage(url);
}

void unawaited(Future<void> future) {}

enum _UnsavedDecision { keepEditing, saveDraft, discard }
