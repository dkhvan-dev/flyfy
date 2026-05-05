import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/reference_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/stories/models/save_story_request.dart';
import '../../features/stories/story_content_codec.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key, this.storyId, this.initialStory});

  final String? storyId;
  final StoryVm? initialStory;

  bool get isEditMode =>
      (storyId ?? '').trim().isNotEmpty || initialStory != null;

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  static const _maxTitleLength = 160;
  static const _maxContentLength = 2500;
  static const _maxTags = 8;
  static const _maxCoverBytes = 20 * 1024 * 1024;

  final _storyApi = StoryApi();
  final _fileApi = FileApi();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _tagController = TextEditingController();

  ReferenceCountry? _selectedCountry;
  ReferenceCity? _selectedCity;
  final List<_StoryComposerSection> _sections = <_StoryComposerSection>[];

  int _step = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingCover = false;
  bool _isUploadingInlineImage = false;
  String _selectedCategory = 'JOURNAL';
  String? _coverFileId;
  String? _coverImageUrl;
  Uint8List? _coverPreviewBytes;
  final List<String> _tags = <String>[];
  int _activeSectionIndex = 0;

  String? _titleError;
  String? _coverError;
  String? _categoryError;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _setComposerSectionsFromContent('');
    final story = widget.initialStory;
    if (story != null) {
      _prefill(story);
    }
    if ((widget.storyId ?? '').trim().isNotEmpty) {
      _loadStoryForEdit(showLoader: story == null);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _disposeSections();
    super.dispose();
  }

  Future<void> _loadStoryForEdit({bool showLoader = true}) async {
    final storyId = (widget.storyId ?? '').trim();
    if (storyId.isEmpty) {
      return;
    }

    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final story = await _storyApi.getStoryById(storyId);
      if (!mounted) {
        return;
      }
      _prefill(story);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await _showApiError(DioErrorMapper.toMessage(e));
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _prefill(StoryVm story) {
    _titleController.text = story.title;
    _setComposerSectionsFromContent((story.content ?? '').trim());
    _selectedCategory = story.category.trim().isEmpty
        ? 'JOURNAL'
        : story.category.trim();
    _coverFileId = (story.coverFileId ?? '').trim().isEmpty
        ? null
        : story.coverFileId!.trim();
    _coverImageUrl = story.coverUrl;
    _coverPreviewBytes = null;
    _tags
      ..clear()
      ..addAll(story.tags);

    final countryCode = (story.placeCountryCode ?? '').trim();
    final placeName = (story.placeName ?? '').trim();
    if (countryCode.isNotEmpty) {
      _selectedCountry = ReferenceCountry(code: countryCode, name: countryCode);
      _resolveCountryName(countryCode);
    }
    if (placeName.isNotEmpty) {
      // placeName may be "City, Country" — extract just the city part.
      final cityName = placeName.contains(',')
          ? placeName.split(',').first.trim()
          : placeName;
      _selectedCity = ReferenceCity(
        id: '',
        countryCode: countryCode,
        name: cityName,
      );
    }
    setState(() {});
  }

  Future<void> _resolveCountryName(String code) async {
    final lang = Localizations.localeOf(context).languageCode;
    final country = await ReferenceApi().getCountry(code, lang: lang);
    if (country != null && mounted) {
      setState(() {
        _selectedCountry = country;
      });
    }
  }

  String? _buildPlaceName() {
    final city = _selectedCity?.name;
    final country = _selectedCountry?.name;
    // Don't use raw code as display name (e.g. "KZ").
    final countryDisplay =
        (country != null && country != _selectedCountry?.code) ? country : null;
    if (city != null && countryDisplay != null) {
      return '$city, $countryDisplay';
    }
    return city ?? countryDisplay;
  }

  void _disposeSections() {
    for (final section in _sections) {
      section.dispose();
    }
    _sections.clear();
  }

  _StoryComposerSection _buildComposerSection({
    String text = '',
    List<_StoryInlineImageDraft>? images,
  }) {
    return _StoryComposerSection(
      initialText: text,
      images: images ?? const <_StoryInlineImageDraft>[],
    );
  }

  void _setComposerSectionsFromContent(String content) {
    _disposeSections();

    final parts = parseStoryContentParts(content);
    final sections = <_StoryComposerSection>[];
    var currentText = '';
    var currentImages = <_StoryInlineImageDraft>[];

    void flushCurrent() {
      sections.add(
        _buildComposerSection(text: currentText, images: currentImages),
      );
      currentText = '';
      currentImages = <_StoryInlineImageDraft>[];
    }

    for (final part in parts) {
      if (part.isText) {
        final text = (part.text ?? '').trim();
        if (text.isEmpty) {
          continue;
        }
        if (currentImages.isNotEmpty) {
          flushCurrent();
        }
        currentText = currentText.isEmpty ? text : '$currentText\n\n$text';
        continue;
      }

      final fileId = (part.imageFileId ?? '').trim();
      if (fileId.isEmpty) {
        continue;
      }
      currentImages.add(_StoryInlineImageDraft(fileId: fileId));
    }

    if (currentText.isNotEmpty ||
        currentImages.isNotEmpty ||
        sections.isEmpty) {
      flushCurrent();
    }

    if (sections.isEmpty) {
      sections.add(_buildComposerSection());
    }

    _sections.addAll(sections);
    _activeSectionIndex = 0;
  }

  String _serializedStoryContent() {
    final parts = <String>[];
    for (final section in _sections) {
      final text = section.controller.text.trim();
      if (text.isNotEmpty) {
        parts.add(text);
      }
      for (final image in section.images) {
        final marker = storyImageMarker(image.fileId);
        if (marker.isNotEmpty) {
          parts.add(marker);
        }
      }
    }
    return parts.join('\n\n').trim();
  }

  void _handleSectionChanged() {
    if (_contentError != null) {
      setState(() {
        _contentError = null;
      });
      return;
    }
    setState(() {});
  }

  void _setActiveSection(int index) {
    if (index < 0 ||
        index >= _sections.length ||
        _activeSectionIndex == index) {
      return;
    }
    setState(() {
      _activeSectionIndex = index;
    });
  }

  void _ensureTrailingSectionAfter(int sectionIndex) {
    if (sectionIndex < 0 || sectionIndex >= _sections.length) {
      return;
    }
    if (sectionIndex == _sections.length - 1) {
      _sections.add(_buildComposerSection());
    }
  }

  Future<void> _pickCover() async {
    if (_isUploadingCover || _isSaving) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (picked == null || !mounted) {
      return;
    }

    final contentType = _resolveImageContentType(picked.name);
    if (contentType == null) {
      setState(() {
        _coverError = AppLocalizations.of(context)!.storyCoverUnsupported;
      });
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxCoverBytes) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coverError = AppLocalizations.of(context)!.storyCoverTooLarge;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final previousFileId = _coverFileId;
    final previousPreview = _coverPreviewBytes;

    setState(() {
      _isUploadingCover = true;
      _coverPreviewBytes = bytes;
      _coverError = null;
    });

    try {
      final upload = await _fileApi.createStoryCoverUpload(
        originalName: picked.name,
        contentType: contentType,
        sizeBytes: bytes.length,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) {
        return;
      }
      setState(() {
        _coverFileId = upload.fileId;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coverFileId = previousFileId;
        _coverPreviewBytes = previousPreview;
        _coverError = DioErrorMapper.toMessage(e);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coverFileId = previousFileId;
        _coverPreviewBytes = previousPreview;
        _coverError = AppLocalizations.of(context)!.storyCoverUploadFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCover = false;
        });
      }
    }
  }

  Future<void> _pickInlineImage({int? sectionIndex}) async {
    if (_isUploadingInlineImage || _isSaving || _sections.isEmpty) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (picked == null || !mounted) {
      return;
    }

    final contentType = _resolveImageContentType(picked.name);
    if (contentType == null) {
      await _showApiError(
        AppLocalizations.of(context)!.storyInlineImageUnsupported,
      );
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxCoverBytes) {
      if (!mounted) {
        return;
      }
      await _showApiError(
        AppLocalizations.of(context)!.storyInlineImageTooLarge,
      );
      return;
    }

    final targetIndex = ((sectionIndex ?? _activeSectionIndex)).clamp(
      0,
      _sections.length - 1,
    );

    setState(() {
      _isUploadingInlineImage = true;
    });

    try {
      final upload = await _fileApi.createStoryInlineImageUpload(
        originalName: picked.name,
        contentType: contentType,
        sizeBytes: bytes.length,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: bytes,
        contentType: contentType,
      );
      await _fileApi.completeUpload(upload.fileId);

      if (!mounted) {
        return;
      }

      final nextIndex = targetIndex == _sections.length - 1
          ? targetIndex + 1
          : targetIndex + 1;
      setState(() {
        _sections[targetIndex].images.add(
          _StoryInlineImageDraft(fileId: upload.fileId, previewBytes: bytes),
        );
        _contentError = null;
        _ensureTrailingSectionAfter(targetIndex);
        _activeSectionIndex = nextIndex.clamp(0, _sections.length - 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || nextIndex >= _sections.length) {
          return;
        }
        _sections[nextIndex].focusNode.requestFocus();
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await _showApiError(DioErrorMapper.toMessage(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _showApiError(
        AppLocalizations.of(context)!.storyInlineImageUploadFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingInlineImage = false;
        });
      }
    }
  }

  void _removeInlineImage(int sectionIndex, _StoryInlineImageDraft image) {
    if (sectionIndex < 0 || sectionIndex >= _sections.length) {
      return;
    }
    setState(() {
      _sections[sectionIndex].images.remove(image);
    });
  }

  void _addTagFromInput() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) {
      return;
    }
    final next = raw.replaceAll(RegExp(r'^[#\s]+'), '');
    if (next.isEmpty) {
      _tagController.clear();
      return;
    }
    if (_tags.length >= _maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.storyTagsLimit)),
      );
      return;
    }
    if (_tags.any((item) => item.toLowerCase() == next.toLowerCase())) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(next);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  bool _validateStepOne() {
    final l10n = AppLocalizations.of(context)!;
    String? titleError;
    String? coverError;
    String? categoryError;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      titleError = l10n.storyTitleRequired;
    } else if (title.length > _maxTitleLength) {
      titleError = l10n.storyTitleTooLong(_maxTitleLength);
    }
    if ((_coverFileId ?? '').trim().isEmpty) {
      coverError = l10n.storyCoverRequired;
    }
    if (_selectedCategory.trim().isEmpty) {
      categoryError = l10n.storyCategoryRequired;
    }

    setState(() {
      _titleError = titleError;
      _coverError = coverError;
      _categoryError = categoryError;
    });

    return titleError == null && coverError == null && categoryError == null;
  }

  bool _validateStepTwo() {
    final l10n = AppLocalizations.of(context)!;
    String? contentError;
    final content = extractStoryVisibleText(_serializedStoryContent());
    if (content.isEmpty) {
      contentError = l10n.storyContentRequired;
    } else if (content.characters.length > _maxContentLength) {
      contentError = l10n.storyContentTooLong(_maxContentLength);
    }

    setState(() {
      _contentError = contentError;
    });
    return contentError == null;
  }

  Future<void> _saveStory(String status) async {
    if (_isSaving) {
      return;
    }
    final stepOneValid = _validateStepOne();
    final stepTwoValid = _validateStepTwo();
    if (!stepOneValid) {
      setState(() {
        _step = 0;
      });
      return;
    }
    if (!stepTwoValid) {
      setState(() {
        _step = 1;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final request = SaveStoryRequest(
      title: _titleController.text.trim(),
      content: _serializedStoryContent(),
      category: _selectedCategory,
      status: status,
      coverFileId: _coverFileId,
      placeName: _buildPlaceName(),
      placeCountryCode: _selectedCountry?.code,
      tags: _tags,
    );

    try {
      if (widget.isEditMode) {
        final storyId = (widget.storyId ?? widget.initialStory?.id ?? '')
            .trim();
        if (storyId.isEmpty) {
          throw StateError('Missing story id');
        }
        final updatedStory = await _storyApi.updateStory(storyId, request);
        if (!mounted) {
          return;
        }
        context.pop(updatedStory);
      } else {
        final createdStory = await _storyApi.createStory(request);
        if (!mounted) {
          return;
        }
        context.pop(createdStory);
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await _showApiError(DioErrorMapper.toMessage(e));
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _showApiError(AppLocalizations.of(context)!.storySaveFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showApiError(String message) {
    final l10n = AppLocalizations.of(context)!;
    return showErrorDialog(context, title: l10n.error, message: message);
  }

  String? _resolveImageContentType(String fileName) {
    final normalized = fileName.toLowerCase().trim();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalized.endsWith('.heic')) {
      return 'image/heic';
    }
    if (normalized.endsWith('.heif')) {
      return 'image/heif';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: StoryPalette.backgroundDeep,
      body: DecoratedBox(
        decoration: storyScreenBackground(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight =
                  adaptive.isShort || constraints.maxHeight < 720;
              final isVeryCompactHeight =
                  adaptive.isVeryShort || constraints.maxHeight < 660;
              final horizontalPadding = adaptive.scale(
                adaptive.isVeryNarrow ? 14 : 16,
                minFactor: 0.86,
                maxFactor: 1.0,
              );
              final verticalPadding = adaptive.scale(
                isVeryCompactHeight ? 12 : 18,
                minFactor: 0.82,
                maxFactor: 1.0,
              );
              final topSpacing = adaptive.scale(
                isCompactHeight ? 12 : 18,
                minFactor: 0.8,
                maxFactor: 1.0,
              );
              final contentSpacing = adaptive.scale(
                isVeryCompactHeight ? 18 : 26,
                minFactor: 0.8,
                maxFactor: 1.0,
              );
              final footerSpacing = adaptive.scale(
                isCompactHeight ? 12 : 18,
                minFactor: 0.8,
                maxFactor: 1.0,
              );
              return _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        verticalPadding,
                      ),
                      child: Column(
                        children: [
                          _CreateStoryTopBar(
                            title: l10n.storyCreateTitle,
                            onBackTap: () {
                              if (_step == 1) {
                                setState(() {
                                  _step = 0;
                                });
                                return;
                              }
                              context.pop();
                            },
                          ),
                          SizedBox(height: topSpacing),
                          _CreateStoryStepper(step: _step),
                          SizedBox(height: contentSpacing),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _step == 0
                                  ? _CreateStoryStepOne(
                                      key: const ValueKey('step1'),
                                      titleController: _titleController,
                                      tagController: _tagController,
                                      selectedCountry: _selectedCountry,
                                      selectedCity: _selectedCity,
                                      onCountryChanged: (country) {
                                        setState(() {
                                          _selectedCountry = country;
                                          if (country == null) {
                                            _selectedCity = null;
                                          }
                                        });
                                      },
                                      onCityChanged: (city) {
                                        setState(() {
                                          _selectedCity = city;
                                          if (city != null &&
                                              _selectedCountry == null) {
                                            _selectedCountry = ReferenceCountry(
                                              code: city.countryCode,
                                              name: city.countryCode,
                                            );
                                          }
                                        });
                                      },
                                      tags: _tags,
                                      selectedCategory: _selectedCategory,
                                      coverFileId: _coverFileId,
                                      coverImageUrl: _coverImageUrl,
                                      coverPreviewBytes: _coverPreviewBytes,
                                      isUploadingCover: _isUploadingCover,
                                      titleError: _titleError,
                                      coverError: _coverError,
                                      categoryError: _categoryError,
                                      onPickCover: _pickCover,
                                      onSelectCategory: (category) {
                                        setState(() {
                                          _selectedCategory = category;
                                          _categoryError = null;
                                        });
                                      },
                                      onAddTag: _addTagFromInput,
                                      onRemoveTag: _removeTag,
                                    )
                                  : _CreateStoryStepTwo(
                                      key: const ValueKey('step2'),
                                      sections: _sections,
                                      maxContentLength: _maxContentLength,
                                      contentError: _contentError,
                                      isUploadingInlineImage:
                                          _isUploadingInlineImage,
                                      onContentChanged: _handleSectionChanged,
                                      onSectionFocused: _setActiveSection,
                                      onPickExtraMedia: _pickInlineImage,
                                      onRemoveImage: _removeInlineImage,
                                    ),
                            ),
                          ),
                          SizedBox(height: footerSpacing),
                          if (_step == 0)
                            _CreateStoryPrimaryButton(
                              label: l10n.storyContinueAction,
                              isLoading: false,
                              onTap: () {
                                if (_validateStepOne()) {
                                  setState(() {
                                    _step = 1;
                                  });
                                }
                              },
                            )
                          else ...[
                            _CreateStoryActions(
                              isSaving: _isSaving,
                              publishLabel: widget.isEditMode
                                  ? l10n.storyUpdateAction
                                  : l10n.storyPublishAction,
                              onPublishTap: () => _saveStory('PUBLISHED'),
                            ),
                            SizedBox(
                              height: adaptive.scale(
                                isCompactHeight ? 6 : 10,
                                minFactor: 0.8,
                                maxFactor: 1.0,
                              ),
                            ),
                            TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveStory('DRAFT'),
                              child: Text(
                                l10n.storySaveDraftAction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: adaptive.scale(15),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _CreateStoryTopBar extends StatelessWidget {
  const _CreateStoryTopBar({required this.title, required this.onBackTap});

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final buttonSize = adaptive.scale(
      adaptive.isVeryShort ? 38 : 42,
      minFactor: 0.82,
      maxFactor: 1.0,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: buttonSize),
      child: Row(
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: GestureDetector(
              onTap: onBackTap,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: StoryPalette.text,
                size: adaptive.scale(22),
              ),
            ),
          ),
          SizedBox(width: adaptive.scale(10, minFactor: 0.8, maxFactor: 1.0)),
          Expanded(
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: StoryPalette.text,
                fontSize: adaptive.scale(
                  adaptive.isVeryNarrow ? 16 : 18,
                  minFactor: 0.82,
                  maxFactor: 1.0,
                ),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          SizedBox(width: adaptive.scale(10, minFactor: 0.8, maxFactor: 1.0)),
          SizedBox(width: buttonSize, height: buttonSize),
        ],
      ),
    );
  }
}

class _CreateStoryStepper extends StatelessWidget {
  const _CreateStoryStepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final currentColor = AppColors.accent;
    final doneColor = const Color(0xFF22D063);
    final dotSize = adaptive.scale(
      adaptive.isVeryNarrow || adaptive.isVeryShort ? 54 : 62,
      minFactor: 0.82,
      maxFactor: 1.0,
    );
    final connectorWidth = adaptive.scale(
      adaptive.isVeryNarrow ? 42 : 62,
      minFactor: 0.78,
      maxFactor: 1.0,
    );
    final gap = adaptive.scale(
      adaptive.isVeryNarrow ? 10 : 18,
      minFactor: 0.78,
      maxFactor: 1.0,
    );

    Widget dot(int index) {
      final isCurrent = step == index;
      final isDone = step > index;
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone
              ? doneColor
              : (isCurrent
                    ? currentColor
                    : currentColor.withValues(alpha: 0.18)),
          boxShadow: isCurrent || isDone
              ? [
                  BoxShadow(
                    color: (isDone ? doneColor : currentColor).withValues(
                      alpha: 0.22,
                    ),
                    blurRadius: adaptive.scale(20),
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isDone
              ? Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: adaptive.scale(24),
                )
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: adaptive.scale(18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(0),
        Container(
          width: connectorWidth,
          height: adaptive.scale(4),
          margin: EdgeInsets.symmetric(horizontal: gap),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(adaptive.radius(999)),
            color: step > 0
                ? const Color(0xFF28DB72)
                : AppColors.accent.withValues(alpha: 0.22),
          ),
        ),
        dot(1),
      ],
    );
  }
}

class _CreateStoryStepOne extends StatelessWidget {
  const _CreateStoryStepOne({
    super.key,
    required this.titleController,
    required this.tagController,
    required this.selectedCountry,
    required this.selectedCity,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.tags,
    required this.selectedCategory,
    required this.coverFileId,
    required this.coverImageUrl,
    required this.coverPreviewBytes,
    required this.isUploadingCover,
    required this.titleError,
    required this.coverError,
    required this.categoryError,
    required this.onPickCover,
    required this.onSelectCategory,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final TextEditingController titleController;
  final TextEditingController tagController;
  final ReferenceCountry? selectedCountry;
  final ReferenceCity? selectedCity;
  final ValueChanged<ReferenceCountry?> onCountryChanged;
  final ValueChanged<ReferenceCity?> onCityChanged;
  final List<String> tags;
  final String selectedCategory;
  final String? coverFileId;
  final String? coverImageUrl;
  final Uint8List? coverPreviewBytes;
  final bool isUploadingCover;
  final String? titleError;
  final String? coverError;
  final String? categoryError;
  final VoidCallback onPickCover;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final categories = <(String value, IconData icon)>[
      ('JOURNAL', Icons.menu_book_rounded),
      ('GUIDE', Icons.explore_rounded),
      ('PHOTO_ESSAY', Icons.photo_library_outlined),
      ('CULINARY', Icons.restaurant_menu_rounded),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverUploadBox(
            coverFileId: coverFileId,
            coverImageUrl: coverImageUrl,
            coverPreviewBytes: coverPreviewBytes,
            isUploading: isUploadingCover,
            errorText: coverError,
            onTap: onPickCover,
          ),
          SizedBox(height: adaptive.scale(26)),
          _StoryFormField(
            label: l10n.storyTitleLabel,
            controller: titleController,
            hint: l10n.storyTitleHint,
            errorText: titleError,
          ),
          SizedBox(height: adaptive.scale(28)),
          Text(
            l10n.storyPlacePrompt,
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(14),
              height: 0.97,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
          ),
          SizedBox(height: adaptive.scale(18)),
          _ReferenceSearchField<ReferenceCountry>(
            hint: l10n.storyCountryHint,
            leadingIcon: Icons.flag_outlined,
            selectedLabel: selectedCountry?.name,
            onSearch: (query) async {
              final lang = Localizations.localeOf(context).languageCode;
              return ReferenceApi().searchCountries(query, lang: lang);
            },
            itemLabel: (c) => c.name,
            onSelected: onCountryChanged,
            onCleared: () => onCountryChanged(null),
          ),
          SizedBox(height: adaptive.scale(14)),
          _ReferenceSearchField<ReferenceCity>(
            hint: l10n.storyCityHint,
            leadingIcon: Icons.location_city_outlined,
            selectedLabel: selectedCity?.name,
            onSearch: (query) async {
              final lang = Localizations.localeOf(context).languageCode;
              return ReferenceApi().searchCities(
                query,
                countryCode: selectedCountry?.code,
                lang: lang,
              );
            },
            itemLabel: (c) => c.name,
            onSelected: onCityChanged,
            onCleared: () => onCityChanged(null),
          ),
          SizedBox(height: adaptive.scale(24)),
          _TagEntrySection(
            controller: tagController,
            tags: tags,
            onSubmitted: onAddTag,
            onRemoveTag: onRemoveTag,
          ),
          SizedBox(height: adaptive.scale(28)),
          Text(
            l10n.storyCategoryLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: adaptive.scale(14),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: adaptive.scale(16)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: adaptive.isVeryNarrow ? 1 : 2,
              crossAxisSpacing: adaptive.scale(16),
              mainAxisSpacing: adaptive.scale(16),
              mainAxisExtent: adaptive.scale(
                adaptive.isVeryNarrow ? 96 : 104,
                minFactor: 0.82,
                maxFactor: 1.0,
              ),
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category.$1;
              return _StoryCategoryCard(
                label: formatStoryCategory(l10n, category.$1),
                icon: category.$2,
                selected: isSelected,
                onTap: () => onSelectCategory(category.$1),
              );
            },
          ),
          if (categoryError != null) ...[
            SizedBox(height: adaptive.scale(10)),
            Text(
              categoryError!,
              style: TextStyle(
                color: const Color(0xFFFF8A65),
                fontSize: adaptive.scale(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateStoryStepTwo extends StatelessWidget {
  const _CreateStoryStepTwo({
    super.key,
    required this.sections,
    required this.maxContentLength,
    required this.contentError,
    required this.isUploadingInlineImage,
    required this.onContentChanged,
    required this.onSectionFocused,
    required this.onPickExtraMedia,
    required this.onRemoveImage,
  });

  final List<_StoryComposerSection> sections;
  final int maxContentLength;
  final String? contentError;
  final bool isUploadingInlineImage;
  final VoidCallback onContentChanged;
  final ValueChanged<int> onSectionFocused;
  final Future<void> Function({int? sectionIndex}) onPickExtraMedia;
  final void Function(int sectionIndex, _StoryInlineImageDraft image)
  onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final visibleText = sections
        .map((section) => section.controller.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
    final count = visibleText.characters.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in sections.indexed) ...[
            _StoryComposerSectionCard(
              section: entry.$2,
              index: entry.$1,
              isFirst: entry.$1 == 0,
              adaptive: adaptive,
              isUploadingInlineImage: isUploadingInlineImage,
              onChanged: onContentChanged,
              onFocus: () => onSectionFocused(entry.$1),
              onAddImage: () => onPickExtraMedia(sectionIndex: entry.$1),
              onRemoveImage: (image) => onRemoveImage(entry.$1, image),
            ),
            if (entry.$1 != sections.length - 1)
              SizedBox(height: adaptive.scale(18)),
          ],
          if (contentError != null) ...[
            SizedBox(height: adaptive.scale(10)),
            Text(
              contentError!,
              style: TextStyle(
                color: const Color(0xFFFF8A65),
                fontSize: adaptive.scale(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: adaptive.scale(18)),
          Container(
            padding: EdgeInsets.only(top: adaptive.scale(22)),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.storyCharacterCountLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: adaptive.scale(16),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                SizedBox(height: adaptive.scale(14)),
                Text(
                  '$count / $maxContentLength',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: adaptive.scale(18),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: adaptive.scale(22)),
          Container(
            padding: EdgeInsets.all(adaptive.scale(18)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(adaptive.radius(24)),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: adaptive.scale(52),
                  height: adaptive.scale(52),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(adaptive.radius(14)),
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.accent,
                    size: adaptive.scale(24),
                  ),
                ),
                SizedBox(width: adaptive.scale(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.storyWritersNoteTitle,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: adaptive.scale(15),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(height: adaptive.scale(6)),
                      Text(
                        l10n.storyWritersNoteBody,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: adaptive.scale(16),
                          height: 1.48,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStoryActions extends StatelessWidget {
  const _CreateStoryActions({
    required this.isSaving,
    required this.publishLabel,
    required this.onPublishTap,
  });

  final bool isSaving;
  final String publishLabel;
  final VoidCallback onPublishTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final buttonHeight = adaptive.scale(
      adaptive.isShort ? 66 : 74,
      minFactor: 0.82,
      maxFactor: 1.0,
    );
    final shouldStack =
        adaptive.isVeryNarrow || adaptive.textScaleFactor > 1.15;

    Widget publishButton() {
      return ElevatedButton(
        onPressed: isSaving ? null : onPublishTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(adaptive.radius(999)),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: adaptive.scale(22),
                height: adaptive.scale(22),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                publishLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: adaptive.scale(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
      );
    }

    if (shouldStack) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: publishButton()),
          SizedBox(height: adaptive.scale(12, minFactor: 0.82, maxFactor: 1)),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: adaptive.scale(16)),
        Expanded(child: publishButton()),
      ],
    );
  }
}

class _StoryComposerSection {
  _StoryComposerSection({
    String initialText = '',
    List<_StoryInlineImageDraft> images = const <_StoryInlineImageDraft>[],
  }) : controller = TextEditingController(text: initialText),
       focusNode = FocusNode(),
       images = List<_StoryInlineImageDraft>.from(images);

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_StoryInlineImageDraft> images;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _StoryInlineImageDraft {
  const _StoryInlineImageDraft({required this.fileId, this.previewBytes});

  final String fileId;
  final Uint8List? previewBytes;
}

class _StoryComposerSectionCard extends StatelessWidget {
  const _StoryComposerSectionCard({
    required this.section,
    required this.index,
    required this.isFirst,
    required this.adaptive,
    required this.isUploadingInlineImage,
    required this.onChanged,
    required this.onFocus,
    required this.onAddImage,
    required this.onRemoveImage,
  });

  final _StoryComposerSection section;
  final int index;
  final bool isFirst;
  final StoryAdaptive adaptive;
  final bool isUploadingInlineImage;
  final VoidCallback onChanged;
  final VoidCallback onFocus;
  final VoidCallback onAddImage;
  final ValueChanged<_StoryInlineImageDraft> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImages = section.images.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        adaptive.scale(18),
        adaptive.scale(16),
        adaptive.scale(18),
        adaptive.scale(16),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        color: Colors.white.withValues(alpha: 0.025),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: section.controller,
            focusNode: section.focusNode,
            minLines: isFirst ? 8 : 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textAlignVertical: TextAlignVertical.top,
            onTap: onFocus,
            onChanged: (_) => onChanged(),
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(
                adaptive.isVeryNarrow ? 20 : 23,
                minFactor: 0.82,
                maxFactor: 1.0,
              ),
              height: 1.5,
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isFirst
                  ? l10n.storyContentHint
                  : l10n.storyContinueSectionHint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.24),
                fontSize: adaptive.scale(
                  adaptive.isVeryNarrow ? 20 : 23,
                  minFactor: 0.82,
                  maxFactor: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(height: adaptive.scale(10)),
          Row(
            children: [
              _InlineImageActionChip(
                icon: isUploadingInlineImage
                    ? Icons.hourglass_top_rounded
                    : Icons.add_photo_alternate_outlined,
                label: l10n.storyInlineImageAddAction,
                onTap: isUploadingInlineImage ? null : onAddImage,
              ),
            ],
          ),
          if (hasImages) ...[
            SizedBox(height: adaptive.scale(14)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.images.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: adaptive.isVeryNarrow ? 2 : 3,
                crossAxisSpacing: adaptive.scale(10),
                mainAxisSpacing: adaptive.scale(10),
                mainAxisExtent: adaptive.scale(
                  120,
                  minFactor: 0.84,
                  maxFactor: 1,
                ),
              ),
              itemBuilder: (context, imageIndex) {
                final image = section.images[imageIndex];
                return _InlineImageCard(
                  image: image,
                  onRemove: () => onRemoveImage(image),
                );
              },
            ),
          ],
          if (index > 0 || hasImages) ...[
            SizedBox(height: adaptive.scale(6)),
            Text(
              hasImages
                  ? l10n.storyInlineImageHint
                  : l10n.storyContinueSectionLabel,
              style: TextStyle(
                color: StoryPalette.textMuted,
                fontSize: adaptive.scale(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineImageActionChip extends StatelessWidget {
  const _InlineImageActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: adaptive.scale(14),
            vertical: adaptive.scale(10),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(adaptive.radius(999)),
            color: AppColors.accent.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.accent, size: adaptive.scale(18)),
              SizedBox(width: adaptive.scale(8)),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: adaptive.scale(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineImageCard extends StatelessWidget {
  const _InlineImageCard({required this.image, required this.onRemove});

  final _StoryInlineImageDraft image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final imageUrl = resolvePublicFileContentUrl(image.fileId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(adaptive.radius(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF2A1708)),
            child: image.previewBytes != null
                ? Image.memory(image.previewBytes!, fit: BoxFit.cover)
                : (imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white54,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                              ),
                            );
                          },
                        )),
          ),
          Positioned(
            top: adaptive.scale(8),
            right: adaptive.scale(8),
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: adaptive.scale(28),
                height: adaptive.scale(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.52),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: adaptive.scale(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStoryPrimaryButton extends StatelessWidget {
  const _CreateStoryPrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return SizedBox(
      width: double.infinity,
      height: adaptive.scale(
        adaptive.isShort ? 66 : 74,
        minFactor: 0.82,
        maxFactor: 1.0,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(adaptive.radius(999)),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: adaptive.scale(22),
                height: adaptive.scale(22),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: adaptive.scale(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _CoverUploadBox extends StatelessWidget {
  const _CoverUploadBox({
    required this.coverFileId,
    required this.coverImageUrl,
    required this.coverPreviewBytes,
    required this.isUploading,
    required this.errorText,
    required this.onTap,
  });

  final String? coverFileId;
  final String? coverImageUrl;
  final Uint8List? coverPreviewBytes;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final normalizedCoverUrl = (coverImageUrl ?? '').trim();
    final hasCover =
        (coverFileId ?? '').trim().isNotEmpty ||
        coverPreviewBytes != null ||
        normalizedCoverUrl.isNotEmpty;
    final minHeight = adaptive.scale(
      adaptive.isVeryShort ? 220 : (adaptive.isShort ? 260 : 332),
      minFactor: 0.72,
      maxFactor: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(adaptive.radius(26)),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: EdgeInsets.all(adaptive.scale(22)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(adaptive.radius(26)),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFFF8A65)
                    : AppColors.accent.withValues(alpha: 0.28),
                width: 2.4,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              color: Colors.white.withValues(alpha: 0.01),
            ),
            child: hasCover
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(adaptive.radius(22)),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: coverPreviewBytes != null
                              ? Image.memory(
                                  coverPreviewBytes!,
                                  fit: BoxFit.cover,
                                )
                              : normalizedCoverUrl.isNotEmpty
                              ? Image.network(
                                  normalizedCoverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2A1708),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_rounded,
                                          color: Colors.white54,
                                          size: 34,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2A1708),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_rounded,
                                      color: Colors.white54,
                                      size: 34,
                                    ),
                                  ),
                                ),
                        ),
                        if (isUploading)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x66000000),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: adaptive.scale(
                          adaptive.isShort ? 92 : 124,
                          minFactor: 0.76,
                          maxFactor: 1.0,
                        ),
                        height: adaptive.scale(
                          adaptive.isShort ? 92 : 124,
                          minFactor: 0.76,
                          maxFactor: 1.0,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: AppColors.accent,
                          size: adaptive.scale(46),
                        ),
                      ),
                      SizedBox(height: adaptive.scale(24)),
                      Text(
                        l10n.storyCoverUploadTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: adaptive.scale(16),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      SizedBox(height: adaptive.scale(10)),
                      Text(
                        l10n.storyCoverUploadSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.46),
                          fontSize: adaptive.scale(15),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: adaptive.scale(10)),
          Text(
            errorText!,
            style: TextStyle(
              color: const Color(0xFFFF8A65),
              fontSize: adaptive.scale(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReferenceSearchField<T> extends StatefulWidget {
  const _ReferenceSearchField({
    super.key,
    required this.hint,
    required this.leadingIcon,
    required this.onSearch,
    required this.itemLabel,
    required this.onSelected,
    required this.onCleared,
    this.selectedLabel,
  });

  final String hint;
  final IconData leadingIcon;
  final String? selectedLabel;
  final Future<List<T>> Function(String query) onSearch;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onSelected;
  final VoidCallback onCleared;

  @override
  State<_ReferenceSearchField<T>> createState() =>
      _ReferenceSearchFieldState<T>();
}

class _ReferenceSearchFieldState<T> extends State<_ReferenceSearchField<T>> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _results = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedLabel != null) {
      _controller.text = widget.selectedLabel!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _ReferenceSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLabel != oldWidget.selectedLabel &&
        widget.selectedLabel != null &&
        !_focusNode.hasFocus) {
      _controller.text = widget.selectedLabel!;
    }
    if (widget.selectedLabel == null && oldWidget.selectedLabel != null) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _removeOverlay();
      if (widget.selectedLabel != null) {
        widget.onCleared();
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final results = await widget.onSearch(query);
      if (!mounted) return;
      _results = results;
      if (_results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (_) {
      // Silently handle search errors.
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final adaptive = StoryAdaptive.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, adaptive.scale(52)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: adaptive.scale(220)),
              decoration: BoxDecoration(
                color: const Color(0xFF271609),
                borderRadius: BorderRadius.circular(adaptive.scale(16)),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(adaptive.scale(16)),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: adaptive.scale(6)),
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return InkWell(
                      onTap: () {
                        _controller.text = widget.itemLabel(item);
                        widget.onSelected(item);
                        _removeOverlay();
                        _focusNode.unfocus();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: adaptive.scale(18),
                          vertical: adaptive.scale(12),
                        ),
                        child: Text(
                          widget.itemLabel(item),
                          style: TextStyle(
                            color: StoryPalette.text,
                            fontSize: adaptive.scale(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final height = adaptive.scale(
      adaptive.isShort ? 64 : 72,
      minFactor: 0.84,
      maxFactor: 1.0,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: AppColors.accent.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            SizedBox(width: adaptive.scale(20)),
            Icon(
              widget.leadingIcon,
              color: Colors.white.withValues(alpha: 0.55),
              size: adaptive.scale(24),
            ),
            SizedBox(width: adaptive.scale(12)),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                style: TextStyle(
                  color: StoryPalette.text,
                  fontSize: adaptive.scale(
                    adaptive.isVeryNarrow ? 16 : 18,
                    minFactor: 0.86,
                    maxFactor: 1.0,
                  ),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: adaptive.scale(
                      adaptive.isVeryNarrow ? 16 : 18,
                      minFactor: 0.86,
                      maxFactor: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            if (_isSearching)
              Padding(
                padding: EdgeInsets.only(right: adaptive.scale(16)),
                child: SizedBox(
                  width: adaptive.scale(18),
                  height: adaptive.scale(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              )
            else if (widget.selectedLabel != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clear();
                  _removeOverlay();
                  widget.onCleared();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptive.scale(12),
                    vertical: adaptive.scale(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: adaptive.scale(20),
                  ),
                ),
              )
            else
              SizedBox(width: adaptive.scale(20)),
          ],
        ),
      ),
    );
  }
}

class _StoryFormField extends StatelessWidget {
  const _StoryFormField({
    this.label,
    required this.controller,
    required this.hint,
    this.errorText,
  });

  final String? label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final height = adaptive.scale(
      adaptive.isShort ? 64 : 72,
      minFactor: 0.84,
      maxFactor: 1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((label ?? '').trim().isNotEmpty) ...[
          Text(
            label!,
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: adaptive.scale(12)),
        ],
        Container(
          constraints: BoxConstraints(minHeight: height),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: AppColors.accent.withValues(alpha: 0.08),
            border: Border.all(
              color: errorText == null
                  ? Colors.transparent
                  : const Color(0xFFFF8A65),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: adaptive.scale(24)),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 2,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(
                      adaptive.isVeryNarrow ? 16 : 18,
                      minFactor: 0.86,
                      maxFactor: 1.0,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: adaptive.scale(
                        adaptive.isVeryNarrow ? 16 : 18,
                        minFactor: 0.86,
                        maxFactor: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: adaptive.scale(20)),
            ],
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: adaptive.scale(10)),
          Text(
            errorText!,
            style: TextStyle(
              color: const Color(0xFFFF8A65),
              fontSize: adaptive.scale(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TagEntrySection extends StatelessWidget {
  const _TagEntrySection({
    required this.controller,
    required this.tags,
    required this.onSubmitted,
    required this.onRemoveTag,
  });

  final TextEditingController controller;
  final List<String> tags;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.storyTagsFieldLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: adaptive.scale(14),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: adaptive.scale(10)),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackInput =
                adaptive.isVeryNarrow || constraints.maxWidth < 320;
            final addButton = ElevatedButton(
              onPressed: onSubmitted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: Size(
                  stackInput ? double.infinity : adaptive.scale(54),
                  adaptive.scale(54),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(adaptive.radius(18)),
                ),
              ),
              child: Icon(Icons.add_rounded, size: adaptive.scale(20)),
            );

            if (stackInput) {
              return Column(
                children: [
                  _StoryFormField(
                    controller: controller,
                    hint: l10n.storyTagHint,
                  ),
                  SizedBox(height: adaptive.scale(10)),
                  SizedBox(width: double.infinity, child: addButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _StoryFormField(
                    controller: controller,
                    hint: l10n.storyTagHint,
                  ),
                ),
                SizedBox(width: adaptive.scale(10)),
                addButton,
              ],
            );
          },
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: adaptive.scale(14)),
          Wrap(
            spacing: adaptive.scale(12),
            runSpacing: adaptive.scale(12),
            children: [
              for (final tag in tags)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptive.scale(16),
                    vertical: adaptive.scale(14),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(adaptive.radius(999)),
                    color: AppColors.accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: adaptive.scale(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: adaptive.scale(8)),
                      GestureDetector(
                        onTap: () => onRemoveTag(tag),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.accent,
                          size: adaptive.scale(18),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StoryCategoryCard extends StatelessWidget {
  const _StoryCategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(adaptive.radius(24)),
      child: Container(
        padding: EdgeInsets.all(adaptive.scale(18)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(adaptive.radius(24)),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.accent.withValues(alpha: 0.12),
            width: 1.5,
          ),
          color: selected
              ? AppColors.accent.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.01),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.85),
              size: adaptive.scale(30),
            ),
            SizedBox(width: adaptive.scale(14)),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.85),
                  fontSize: adaptive.scale(17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
