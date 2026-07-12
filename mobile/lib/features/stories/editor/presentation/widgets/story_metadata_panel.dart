import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

import '../../../../../core/network/file_api.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/widgets/app_city_filter_section.dart';
import '../../../story_ui.dart';
import '../../data/story_editor_dto.dart';
import '../story_editor_controller.dart';
import 'story_editor_focus_visibility.dart';
import 'story_editor_style.dart';

class StoryMetadataPanel extends StatefulWidget {
  const StoryMetadataPanel({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onFormatChanged,
    required this.onCategoryChanged,
    required this.onPlaceChanged,
    required this.onTagsChanged,
    required this.onPickCover,
    required this.onClearCover,
    required this.onApplyTemplate,
    this.fieldKeys,
    this.hidePlaceFields = false,
    this.showTemplatePicker = true,
    this.showMaterialTaxonomy = true,
    this.showTags = true,
    this.showCover = true,
    this.onTextFieldFocusChanged,
    this.onTextFieldFocused,
  });

  final StoryEditorState state;
  final StoryMetadataPanelFieldKeys? fieldKeys;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String> onCategoryChanged;
  final void Function({
    String? placeName,
    String? placeCountryCode,
    String? placeCityId,
    bool? clearCountryCode,
    bool? clearCityId,
  })
  onPlaceChanged;
  final ValueChanged<List<String>> onTagsChanged;
  final VoidCallback onPickCover;
  final VoidCallback onClearCover;
  final ValueChanged<StoryEditorTemplatePreset> onApplyTemplate;
  final bool hidePlaceFields;
  final bool showTemplatePicker;
  final bool showMaterialTaxonomy;
  final bool showTags;
  final bool showCover;
  final ValueChanged<bool>? onTextFieldFocusChanged;
  final ValueChanged<BuildContext>? onTextFieldFocused;

  @override
  State<StoryMetadataPanel> createState() => _StoryMetadataPanelState();
}

class StoryMetadataPanelFieldKeys {
  const StoryMetadataPanelFieldKeys({
    this.title,
    this.format,
    this.category,
    this.cover,
    this.place,
  });

  final GlobalKey? title;
  final GlobalKey? format;
  final GlobalKey? category;
  final GlobalKey? cover;
  final GlobalKey? place;
}

class _StoryMetadataPanelState extends State<StoryMetadataPanel> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _tagsController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _placeFocusNode;
  late final FocusNode _tagsFocusNode;
  bool _textFieldFocusActive = false;

  static const _formats = [
    'POST',
    'GUIDE',
    'PHOTO_ESSAY',
    'ARTICLE',
    'CULINARY',
  ];
  static const _categories = ['JOURNAL', 'GUIDE', 'PHOTO_ESSAY', 'CULINARY'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _placeController = TextEditingController();
    _tagsController = TextEditingController();
    _titleFocusNode = FocusNode()..addListener(_notifyTextFieldFocusChanged);
    _placeFocusNode = FocusNode()..addListener(_notifyTextFieldFocusChanged);
    _tagsFocusNode = FocusNode()..addListener(_notifyTextFieldFocusChanged);
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant StoryMetadataPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _tagsController.dispose();
    _titleFocusNode
      ..removeListener(_notifyTextFieldFocusChanged)
      ..dispose();
    _placeFocusNode
      ..removeListener(_notifyTextFieldFocusChanged)
      ..dispose();
    _tagsFocusNode
      ..removeListener(_notifyTextFieldFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final metadata = widget.state.metadata;
    final hasCover = (metadata.coverFileId ?? '').trim().isNotEmpty;
    final coverUpload = _activeCoverUpload;
    final isCoverUploading =
        coverUpload?.status == StoryEditorMediaStatus.queued ||
        coverUpload?.status == StoryEditorMediaStatus.uploading;
    final titleError = _errorText(l10n, 'title');
    final formatError = _errorText(l10n, 'format');
    final categoryError = _errorText(l10n, 'category');
    final placeError = _errorText(l10n, 'place');
    final coverError = _errorText(l10n, 'coverFileId');

    return DecoratedBox(
      decoration: storyEditorPanelDecoration(context),
      child: Padding(
        padding: const AppEdgeInsets.all(StoryEditorSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.storyEditorMetadataTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: StoryEditorSpacing.md),
            KeyedSubtree(
              key: widget.fieldKeys?.title,
              child: StoryEditorRevealOnFocus(
                onFocus: widget.onTextFieldFocused,
                child: TextField(
                  key: const ValueKey('story-editor-title-field'),
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  textInputAction: TextInputAction.next,
                  maxLength: 160,
                  decoration: storyEditorInputDecoration(
                    context,
                    label: l10n.storyEditorChecklistTitle,
                    hint: l10n.storyEditorTitleFieldHint,
                    errorText: titleError,
                  ),
                  onChanged: widget.onTitleChanged,
                ),
              ),
            ),
            const SizedBox(height: StoryEditorSpacing.md),
            if (widget.showTemplatePicker) ...[
              _StoryTemplatePickerField(
                key: const ValueKey('story-editor-template-picker'),
                selectedPreset: _templatePresetFromId(
                  widget.state.template.appliedTemplateId,
                ),
                onSelected: widget.onApplyTemplate,
              ),
              const SizedBox(height: StoryEditorSpacing.md),
            ],
            if (widget.showMaterialTaxonomy) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 520;
                  final children = [
                    _MetadataPopupField(
                      key: const ValueKey('story-editor-format-field'),
                      label: l10n.storyEditorFormatLabel,
                      value: _safeValue(metadata.format, _formats),
                      values: _formats,
                      displayValue: (value) => _displayFormat(l10n, value),
                      leadingIcon: Icons.auto_stories_outlined,
                      iconFor: _metadataFormatIcon,
                      errorText: formatError,
                      onChanged: widget.onFormatChanged,
                    ),
                    _MetadataPopupField(
                      key: const ValueKey('story-editor-category-field'),
                      label: l10n.storyEditorChecklistCategory,
                      value: _safeValue(metadata.category, _categories),
                      values: _categories,
                      displayValue: (value) => _displayCategory(l10n, value),
                      leadingIcon: Icons.category_outlined,
                      iconFor: _metadataCategoryIcon,
                      errorText: categoryError,
                      onChanged: widget.onCategoryChanged,
                    ),
                  ];
                  if (stack) {
                    return Column(
                      children: [
                        KeyedSubtree(
                          key: widget.fieldKeys?.format,
                          child: children[0],
                        ),
                        const SizedBox(height: StoryEditorSpacing.md),
                        KeyedSubtree(
                          key: widget.fieldKeys?.category,
                          child: children[1],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: widget.fieldKeys?.format,
                          child: children[0],
                        ),
                      ),
                      const SizedBox(width: StoryEditorSpacing.md),
                      Expanded(
                        child: KeyedSubtree(
                          key: widget.fieldKeys?.category,
                          child: children[1],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (!widget.hidePlaceFields) ...[
              const SizedBox(height: StoryEditorSpacing.md),
              KeyedSubtree(
                key: widget.fieldKeys?.place,
                child: StoryEditorRevealOnFocus(
                  onFocus: widget.onTextFieldFocused,
                  child: TextField(
                    key: const ValueKey('story-editor-place-field'),
                    controller: _placeController,
                    focusNode: _placeFocusNode,
                    textInputAction: TextInputAction.next,
                    decoration: storyEditorInputDecoration(
                      context,
                      label: l10n.storyEditorPlaceLabel,
                      errorText: placeError,
                    ),
                    onChanged: (value) =>
                        widget.onPlaceChanged(placeName: value),
                  ),
                ),
              ),
              const SizedBox(height: StoryEditorSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final metadata = widget.state.metadata;
                  final stack = constraints.maxWidth < 520;
                  final maxResultsHeight =
                      MediaQuery.sizeOf(context).height * 0.24;
                  final selectedCountry = AppCountryFilterValue.fromParts(
                    countryCode: metadata.placeCountryCode,
                  );
                  final selectedCity = AppCityFilterValue.fromParts(
                    cityId: metadata.placeCityId,
                    cityName: metadata.placeName,
                    countryCode: metadata.placeCountryCode,
                  );
                  final country = AppCountryFilterSection(
                    title: l10n.storyFilterCountry,
                    allCountriesLabel: l10n.storyFilterCountryAll,
                    searchHint: l10n.storyFilterCountrySearchHint,
                    noResultsText: l10n.storyFilterCountryNoResults,
                    selectedCountry: selectedCountry,
                    maxResultsHeight: maxResultsHeight,
                    onChanged: (value) {
                      widget.onPlaceChanged(
                        placeCountryCode: value?.countryCode,
                        clearCountryCode: value == null,
                        clearCityId: true,
                      );
                    },
                  );
                  final city = AppCityFilterSection(
                    title: l10n.locationFilterCitySection,
                    allCitiesLabel: l10n.locationFilterAllCities,
                    searchHint: l10n.locationFilterCitySearchHint,
                    noResultsText: l10n.locationFilterCityNoResults,
                    selectedCity: selectedCity,
                    countryCode: selectedCountry?.countryCode,
                    maxResultsHeight: maxResultsHeight,
                    onChanged: (value) {
                      widget.onPlaceChanged(
                        placeName: value?.cityName,
                        placeCountryCode:
                            value?.countryCode ?? selectedCountry?.countryCode,
                        placeCityId: value?.cityId,
                        clearCityId: value == null,
                      );
                    },
                  );
                  if (stack) {
                    return Column(
                      children: [
                        country,
                        const SizedBox(height: StoryEditorSpacing.md),
                        city,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: country),
                      const SizedBox(width: StoryEditorSpacing.md),
                      Expanded(child: city),
                    ],
                  );
                },
              ),
              const SizedBox(height: StoryEditorSpacing.md),
            ],
            if (widget.showTags) ...[
              SizedBox(
                key: const ValueKey('story-editor-topic-tags-gap'),
                height: widget.showMaterialTaxonomy
                    ? StoryEditorSpacing.lg
                    : StoryEditorSpacing.md,
              ),
              _TagsEditor(
                controller: _tagsController,
                focusNode: _tagsFocusNode,
                tags: metadata.tags,
                onTagsChanged: widget.onTagsChanged,
                onInputChanged: (_) => setState(() {}),
                onTextFieldFocused: widget.onTextFieldFocused,
              ),
            ],
            if (widget.showCover) ...[
              const SizedBox(height: StoryEditorSpacing.lg),
              KeyedSubtree(
                key: widget.fieldKeys?.cover,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stackActions =
                        constraints.maxWidth < 360 || textScale > 1.25;
                    final actionWidth = stackActions
                        ? constraints.maxWidth - StoryEditorSpacing.md * 2
                        : null;
                    final borderColor = coverError == null
                        ? colors.border
                        : colors.danger;
                    final coverImage = _coverImageProvider(
                      coverUpload,
                      metadata.coverFileId,
                    );
                    return DecoratedBox(
                      key: const ValueKey('story-editor-cover-field'),
                      decoration: AppBoxDecoration(
                        color: colors.surfaceRaised,
                        borderRadius: AppBorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1.4),
                      ),
                      child: Padding(
                        padding: const AppEdgeInsets.all(StoryEditorSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (coverImage != null) ...[
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: stackActions
                                        ? constraints.maxWidth
                                        : constraints.maxWidth * 0.52,
                                  ),
                                  child: ClipRRect(
                                    key: const ValueKey(
                                      'story-editor-cover-thumbnail',
                                    ),
                                    borderRadius: AppBorderRadius.circular(8),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image(
                                            image: coverImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                DecoratedBox(
                                                  decoration: AppBoxDecoration(
                                                    color: colors.surfaceRaised,
                                                    border: Border.all(
                                                      color: colors.border,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: colors.textMuted,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                          if (hasCover && !isCoverUploading)
                                            PositionedDirectional(
                                              top: StoryEditorSpacing.xs,
                                              end: StoryEditorSpacing.xs,
                                              child: Tooltip(
                                                message: l10n.storyEditorClear,
                                                child: IconButton(
                                                  key: const ValueKey(
                                                    'story-editor-cover-remove-overlay',
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
                                                      ),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: colors
                                                        .surface
                                                        .withValues(
                                                          alpha: 0.86,
                                                        ),
                                                    foregroundColor:
                                                        colors.danger,
                                                    side: BorderSide(
                                                      color: colors.danger
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      widget.onClearCover,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: StoryEditorSpacing.md),
                            ],
                            Wrap(
                              spacing: StoryEditorSpacing.md,
                              runSpacing: StoryEditorSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (isCoverUploading)
                                  SizedBox.square(
                                    key: ValueKey(
                                      'story-editor-cover-upload-loader',
                                    ),
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: colors.primary,
                                    ),
                                  )
                                else
                                  Icon(
                                    hasCover
                                        ? Icons.image_rounded
                                        : Icons.add_photo_alternate_outlined,
                                  ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: stackActions
                                        ? constraints.maxWidth -
                                              StoryEditorSpacing.md * 2 -
                                              40
                                        : constraints.maxWidth,
                                  ),
                                  child: Text(
                                    isCoverUploading
                                        ? l10n.storyEditorMediaUploading
                                        : hasCover
                                        ? l10n.storyEditorCoverSelected
                                        : l10n.storyEditorCoverRequired,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: coverError == null
                                        ? null
                                        : Theme.of(context).textTheme.bodyMedium
                                              ?.copyWith(color: colors.danger),
                                  ),
                                ),
                                SizedBox(
                                  width: actionWidth,
                                  child: FilledButton(
                                    onPressed: isCoverUploading
                                        ? null
                                        : widget.onPickCover,
                                    child: _MetadataButtonLabelContent(
                                      icon: Icons.upload_rounded,
                                      label: hasCover
                                          ? l10n.storyEditorReplaceCover
                                          : l10n.storyEditorAddCover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (coverError != null) ...[
                              const SizedBox(height: StoryEditorSpacing.sm),
                              Text(
                                coverError,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.danger),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  void _syncControllers() {
    final metadata = widget.state.metadata;
    _syncText(_titleController, metadata.title);
    _syncText(_placeController, metadata.placeName ?? '');
  }

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _notifyTextFieldFocusChanged() {
    final hasFocus =
        _titleFocusNode.hasFocus ||
        _placeFocusNode.hasFocus ||
        _tagsFocusNode.hasFocus;
    if (_textFieldFocusActive == hasFocus) return;
    _textFieldFocusActive = hasFocus;
    widget.onTextFieldFocusChanged?.call(hasFocus);
  }

  String _safeValue(String value, List<String> values) {
    return values.contains(value.toUpperCase())
        ? value.toUpperCase()
        : values.first;
  }

  String _displayFormat(AppLocalizations l10n, String value) {
    return switch (value.trim().toUpperCase()) {
      'POST' => l10n.storyFormatStory,
      'GUIDE' => l10n.storyFormatGuide,
      'PHOTO_ESSAY' => l10n.storyFormatPhotoEssay,
      'ARTICLE' => l10n.storyFormatArticle,
      'CULINARY' => l10n.storyFormatCulinary,
      _ => l10n.storyFormatStory,
    };
  }

  String _displayCategory(AppLocalizations l10n, String value) {
    return switch (value.trim().toUpperCase()) {
      'GUIDE' => l10n.storyCategoryGuide,
      'PHOTO_ESSAY' => l10n.storyCategoryPhotoEssay,
      'CULINARY' => l10n.storyCategoryCulinary,
      _ => l10n.storyCategoryJournal,
    };
  }

  String? _errorText(AppLocalizations l10n, String field) {
    if (!_shouldShowValidationErrors) {
      return null;
    }
    for (final error in widget.state.publishValidation.errors) {
      if (error.field == field) {
        return _fieldErrorMessage(l10n, error);
      }
    }
    return null;
  }

  StoryEditorMediaQueueItem? get _activeCoverUpload {
    for (final item in widget.state.mediaQueue.items.reversed) {
      if (item.kind == StoryEditorMediaUploadKind.cover &&
          item.status != StoryEditorMediaStatus.removed) {
        return item;
      }
    }
    return null;
  }

  bool get _shouldShowValidationErrors {
    return widget.state.saveStatus.phase == StoryEditorSavePhase.failed ||
        widget.state.saveStatus.phase == StoryEditorSavePhase.conflict;
  }

  String _fieldErrorMessage(
    AppLocalizations l10n,
    StoryEditorFieldError error,
  ) {
    return switch (error.code.trim()) {
      'draft_required' => l10n.storyEditorValidationDraftRequired,
      'title_required' => l10n.storyEditorValidationTitleRequired,
      'format_required' => l10n.storyEditorValidationFormatRequired,
      'category_required' => l10n.storyEditorValidationCategoryRequired,
      'cover_required' => l10n.storyEditorValidationCoverRequired,
      'place_required' => l10n.storyEditorValidationPlaceRequired,
      'content_required' => l10n.storyEditorValidationContentRequired,
      'media_upload_pending' => l10n.storyEditorValidationMediaPending,
      _ => error.message,
    };
  }
}

class _TagsEditor extends StatelessWidget {
  const _TagsEditor({
    required this.controller,
    required this.focusNode,
    required this.tags,
    required this.onTagsChanged,
    required this.onInputChanged,
    this.onTextFieldFocused,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<BuildContext>? onTextFieldFocused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final canAdd =
        _parseTagTokens(controller.text).isNotEmpty && tags.length < 8;
    final input = StoryEditorRevealOnFocus(
      onFocus: onTextFieldFocused,
      child: TextField(
        key: const ValueKey('story-editor-tags-field'),
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        decoration: storyEditorInputDecoration(
          context,
          label: l10n.storyTagsFieldLabel,
          hint: l10n.storyEditorTagsHint,
        ),
        onSubmitted: (_) => _commitInput(),
        onChanged: (value) {
          if (_endsWithTagSeparator(value)) {
            _commitInput();
            return;
          }
          onInputChanged(value);
        },
      ),
    );
    final addButton = FilledButton(
      key: const ValueKey('story-editor-tags-add-button'),
      onPressed: canAdd ? _commitInput : null,
      child: _MetadataButtonLabelContent(
        icon: Icons.add_rounded,
        label: l10n.storyTagHint,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 430;
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  input,
                  const SizedBox(height: StoryEditorSpacing.sm),
                  addButton,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: input),
                const SizedBox(width: StoryEditorSpacing.sm),
                Padding(
                  padding: const AppEdgeInsets.only(top: StoryEditorSpacing.xs),
                  child: addButton,
                ),
              ],
            );
          },
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: StoryEditorSpacing.sm),
          Wrap(
            spacing: StoryEditorSpacing.sm,
            runSpacing: StoryEditorSpacing.sm,
            children: [
              for (final tag in tags)
                InputChip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  deleteIconColor: colors.primary,
                  side: BorderSide(
                    color: colors.primary.withValues(alpha: 0.22),
                  ),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: StoryEditorSpacing.xs),
        Text(
          l10n.storyTagsLimit,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  void _commitInput() {
    final next = _mergeTags(tags, controller.text);
    if (!_sameTags(next, tags)) {
      onTagsChanged(next);
    }
    controller.clear();
    onInputChanged('');
  }

  void _removeTag(String tag) {
    onTagsChanged(
      tags.where((item) => item.toLowerCase() != tag.toLowerCase()).toList(),
    );
  }
}

ImageProvider<Object>? _coverImageProvider(
  StoryEditorMediaQueueItem? coverUpload,
  String? coverFileId,
) {
  final previewBytes = coverUpload?.previewBytes;
  if (previewBytes != null && previewBytes.isNotEmpty) {
    return MemoryImage(previewBytes);
  }

  final fileId = (coverUpload?.fileId ?? coverFileId ?? '').trim();
  final url = resolvePublicFileContentUrl(fileId);
  if (url == null) {
    return null;
  }
  return NetworkImage(url);
}

bool _endsWithTagSeparator(String value) {
  return value.isNotEmpty && RegExp(r'[\s,;]$').hasMatch(value);
}

List<String> _mergeTags(List<String> existing, String input) {
  final next = <String>[];
  final seen = <String>{};
  void add(String tag) {
    final normalized = tag.toLowerCase();
    if (normalized.isEmpty || seen.contains(normalized) || next.length >= 8) {
      return;
    }
    seen.add(normalized);
    next.add(tag);
  }

  for (final tag in existing) {
    add(tag.trim());
  }
  for (final tag in _parseTagTokens(input)) {
    add(tag);
  }
  return List.unmodifiable(next);
}

List<String> _parseTagTokens(String input) {
  return input
      .split(RegExp(r'[\s,;]+'))
      .map((tag) => tag.replaceFirst(RegExp(r'^#+'), '').trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}

bool _sameTags(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

enum StoryEditorTemplatePreset {
  weekendGuide,
  photoEssay,
  foodNotes,
  cityWalk,
  hiddenGems,
  practicalTips,
  cultureRoute,
}

const _templatePresetValues = <StoryEditorTemplatePreset>[
  StoryEditorTemplatePreset.weekendGuide,
  StoryEditorTemplatePreset.photoEssay,
  StoryEditorTemplatePreset.foodNotes,
  StoryEditorTemplatePreset.cityWalk,
  StoryEditorTemplatePreset.hiddenGems,
  StoryEditorTemplatePreset.practicalTips,
  StoryEditorTemplatePreset.cultureRoute,
];

class _StoryTemplatePickerField extends StatelessWidget {
  const _StoryTemplatePickerField({
    super.key,
    required this.selectedPreset,
    required this.onSelected,
  });

  final StoryEditorTemplatePreset? selectedPreset;
  final ValueChanged<StoryEditorTemplatePreset> onSelected;

  Future<void> _openTemplateSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedPreset = this.selectedPreset;
    final selected = await showAppModalBottomSheet<StoryEditorTemplatePreset>(
      context: context,
      title: l10n.storyEditorTemplateAction,
      icon: Icons.dashboard_customize_outlined,
      useSafeArea: false,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final preset in _templatePresetValues)
              Material(
                color: sheetContext.appColors.transparent,
                child: InkWell(
                  borderRadius: AppBorderRadius.circular(16),
                  onTap: () => Navigator.of(sheetContext).pop(preset),
                  child: _StoryTemplateMenuItem(
                    title: _templatePresetTitle(l10n, preset),
                    subtitle:
                        '${_templatePresetFormatLabel(l10n, preset)} / ${_templatePresetCategoryLabel(l10n, preset)}',
                    icon: _templatePresetIcon(preset),
                    selected: preset == selectedPreset,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final selectedPreset = this.selectedPreset;
    final selectedLabel = selectedPreset == null
        ? l10n.storyEditorTemplatePlaceholder
        : _templatePresetTitle(l10n, selectedPreset);

    return Semantics(
      label: l10n.storyEditorTemplateSemantic,
      button: true,
      child: InkWell(
        borderRadius: AppBorderRadius.circular(16),
        onTap: () => _openTemplateSheet(context),
        child: InputDecorator(
          decoration: storyEditorInputDecoration(
            context,
            label: l10n.storyEditorTemplateAction,
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: StoryEditorSpacing.sm),
              Expanded(
                child: Text(
                  selectedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selectedPreset == null
                        ? colors.textSecondary
                        : colors.textPrimary,
                    fontWeight: selectedPreset == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: StoryEditorSpacing.sm),
              Icon(Icons.expand_more_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryTemplateMenuItem extends StatelessWidget {
  const _StoryTemplateMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: const AppEdgeInsets.symmetric(
        horizontal: StoryEditorSpacing.sm,
        vertical: StoryEditorSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.16)
              : colors.surfaceHigh,
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colors.primary.withValues(alpha: 0.36)
                : colors.borderSoft,
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(StoryEditorSpacing.md),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: AppBoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: AppBorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: StoryEditorSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: StoryEditorSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StoryEditorSpacing.sm),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

StoryEditorTemplatePreset? _templatePresetFromId(String? id) {
  return switch ((id ?? '').trim()) {
    'weekend_guide' => StoryEditorTemplatePreset.weekendGuide,
    'photo_essay' => StoryEditorTemplatePreset.photoEssay,
    'food_notes' => StoryEditorTemplatePreset.foodNotes,
    'city_walk' => StoryEditorTemplatePreset.cityWalk,
    'hidden_gems' => StoryEditorTemplatePreset.hiddenGems,
    'practical_tips' => StoryEditorTemplatePreset.practicalTips,
    'culture_route' => StoryEditorTemplatePreset.cultureRoute,
    _ => null,
  };
}

String _templatePresetTitle(
  AppLocalizations l10n,
  StoryEditorTemplatePreset preset,
) {
  return switch (preset) {
    StoryEditorTemplatePreset.weekendGuide =>
      l10n.storyEditorTemplateWeekendGuide,
    StoryEditorTemplatePreset.photoEssay => l10n.storyEditorTemplatePhotoEssay,
    StoryEditorTemplatePreset.foodNotes => l10n.storyEditorTemplateFoodNotes,
    StoryEditorTemplatePreset.cityWalk => l10n.storyEditorTemplateCityWalk,
    StoryEditorTemplatePreset.hiddenGems => l10n.storyEditorTemplateHiddenGems,
    StoryEditorTemplatePreset.practicalTips =>
      l10n.storyEditorTemplatePracticalTips,
    StoryEditorTemplatePreset.cultureRoute =>
      l10n.storyEditorTemplateCultureRoute,
  };
}

String _templatePresetFormatLabel(
  AppLocalizations l10n,
  StoryEditorTemplatePreset preset,
) {
  return formatStoryFormat(l10n, switch (preset) {
    StoryEditorTemplatePreset.weekendGuide => 'GUIDE',
    StoryEditorTemplatePreset.photoEssay => 'PHOTO_ESSAY',
    StoryEditorTemplatePreset.foodNotes => 'CULINARY',
    StoryEditorTemplatePreset.cityWalk => 'GUIDE',
    StoryEditorTemplatePreset.hiddenGems => 'ARTICLE',
    StoryEditorTemplatePreset.practicalTips => 'GUIDE',
    StoryEditorTemplatePreset.cultureRoute => 'ARTICLE',
  });
}

String _templatePresetCategoryLabel(
  AppLocalizations l10n,
  StoryEditorTemplatePreset preset,
) {
  return formatStoryCategory(l10n, switch (preset) {
    StoryEditorTemplatePreset.weekendGuide => 'GUIDE',
    StoryEditorTemplatePreset.photoEssay => 'PHOTO_ESSAY',
    StoryEditorTemplatePreset.foodNotes => 'CULINARY',
    StoryEditorTemplatePreset.cityWalk => 'GUIDE',
    StoryEditorTemplatePreset.hiddenGems => 'JOURNAL',
    StoryEditorTemplatePreset.practicalTips => 'GUIDE',
    StoryEditorTemplatePreset.cultureRoute => 'JOURNAL',
  });
}

IconData _templatePresetIcon(StoryEditorTemplatePreset preset) {
  return switch (preset) {
    StoryEditorTemplatePreset.weekendGuide => Icons.weekend_outlined,
    StoryEditorTemplatePreset.photoEssay => Icons.photo_camera_outlined,
    StoryEditorTemplatePreset.foodNotes => Icons.restaurant_menu_rounded,
    StoryEditorTemplatePreset.cityWalk => Icons.directions_walk_rounded,
    StoryEditorTemplatePreset.hiddenGems => Icons.auto_awesome_outlined,
    StoryEditorTemplatePreset.practicalTips => Icons.checklist_rounded,
    StoryEditorTemplatePreset.cultureRoute => Icons.museum_outlined,
  };
}

IconData _metadataFormatIcon(String value) {
  return switch (value.trim().toUpperCase()) {
    'POST' => Icons.chat_bubble_outline_rounded,
    'GUIDE' => Icons.map_outlined,
    'PHOTO_ESSAY' => Icons.photo_library_outlined,
    'ARTICLE' => Icons.article_outlined,
    'CULINARY' => Icons.restaurant_menu_rounded,
    _ => Icons.dashboard_customize_outlined,
  };
}

IconData _metadataCategoryIcon(String value) {
  return switch (value.trim().toUpperCase()) {
    'GUIDE' => Icons.map_outlined,
    'PHOTO_ESSAY' => Icons.photo_camera_outlined,
    'CULINARY' => Icons.restaurant_menu_rounded,
    'JOURNAL' => Icons.menu_book_outlined,
    _ => Icons.category_outlined,
  };
}

class _MetadataPopupField extends StatelessWidget {
  const _MetadataPopupField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.displayValue,
    required this.leadingIcon,
    required this.iconFor,
    this.errorText,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final String Function(String value) displayValue;
  final IconData leadingIcon;
  final IconData Function(String value) iconFor;
  final String? errorText;
  final ValueChanged<String> onChanged;

  Future<void> _openValueSheet(BuildContext context) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      title: label,
      icon: leadingIcon,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in values)
              Material(
                color: sheetContext.appColors.transparent,
                child: InkWell(
                  borderRadius: AppBorderRadius.circular(16),
                  onTap: () => Navigator.of(sheetContext).pop(item),
                  child: _StoryMetadataMenuItem(
                    title: displayValue(item),
                    icon: iconFor(item),
                    selected: item == value,
                    selectedIcon: Icons.check_circle_rounded,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final selectedLabel = displayValue(value);
    return InkWell(
      borderRadius: AppBorderRadius.circular(16),
      onTap: () => _openValueSheet(context),
      child: InputDecorator(
        decoration: storyEditorInputDecoration(
          context,
          label: label,
          errorText: errorText,
        ),
        isEmpty: selectedLabel.trim().isEmpty,
        child: Row(
          children: [
            Icon(leadingIcon, color: colors.primary, size: 20),
            const SizedBox(width: StoryEditorSpacing.sm),
            Expanded(
              child: Text(
                selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
              ),
            ),
            const SizedBox(width: StoryEditorSpacing.sm),
            Icon(Icons.expand_more_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _StoryMetadataMenuItem extends StatelessWidget {
  const _StoryMetadataMenuItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.selectedIcon,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final IconData selectedIcon;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Padding(
      padding: const AppEdgeInsets.symmetric(
        horizontal: StoryEditorSpacing.sm,
        vertical: StoryEditorSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.16)
              : colors.surfaceHigh,
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colors.primary.withValues(alpha: 0.36)
                : colors.borderSoft,
          ),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(StoryEditorSpacing.md),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: AppBoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: AppBorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: StoryEditorSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: StoryEditorSpacing.sm),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: Icon(selectedIcon, color: colors.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataButtonLabelContent extends StatelessWidget {
  const _MetadataButtonLabelContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: StoryEditorSpacing.sm),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
