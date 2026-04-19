import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/stories/models/save_story_request.dart';
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
  final _placeController = TextEditingController();
  final _tagController = TextEditingController();
  final _contentController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingCover = false;
  String _selectedCategory = 'JOURNAL';
  String? _coverFileId;
  Uint8List? _coverPreviewBytes;
  final List<String> _tags = <String>[];

  String? _titleError;
  String? _coverError;
  String? _categoryError;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    final story = widget.initialStory;
    if (story != null) {
      _prefill(story);
    } else if ((widget.storyId ?? '').trim().isNotEmpty) {
      _loadStoryForEdit();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _tagController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryForEdit() async {
    final storyId = (widget.storyId ?? '').trim();
    if (storyId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _prefill(StoryVm story) {
    _titleController.text = story.title;
    _placeController.text = (story.placeName ?? '').trim();
    _contentController.text = (story.content ?? '').trim();
    _selectedCategory = story.category.trim().isEmpty
        ? 'JOURNAL'
        : story.category.trim();
    _coverFileId = (story.coverFileId ?? '').trim().isEmpty
        ? null
        : story.coverFileId!.trim();
    _tags
      ..clear()
      ..addAll(story.tags);
    setState(() {});
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
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      contentError = l10n.storyContentRequired;
    } else if (content.length > _maxContentLength) {
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
      content: _contentController.text.trim(),
      category: _selectedCategory,
      status: status,
      coverFileId: _coverFileId,
      placeName: _placeController.text.trim().isEmpty
          ? null
          : _placeController.text.trim(),
      tags: _tags,
    );

    try {
      if (widget.isEditMode) {
        final storyId = (widget.storyId ?? widget.initialStory?.id ?? '')
            .trim();
        if (storyId.isEmpty) {
          throw StateError('Missing story id');
        }
        await _storyApi.updateStory(storyId, request);
      } else {
        await _storyApi.createStory(request);
      }

      if (!mounted) {
        return;
      }
      context.pop(true);
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: StoryPalette.backgroundDeep,
      body: DecoratedBox(
        decoration: storyScreenBackground(),
        child: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      adaptive.scale(16),
                      adaptive.scale(18),
                      adaptive.scale(16),
                      adaptive.scale(18),
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
                            context.pop(false);
                          },
                        ),
                        SizedBox(height: adaptive.scale(18)),
                        _CreateStoryStepper(step: _step),
                        SizedBox(height: adaptive.scale(26)),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _step == 0
                                ? _CreateStoryStepOne(
                                    key: const ValueKey('step1'),
                                    titleController: _titleController,
                                    placeController: _placeController,
                                    tagController: _tagController,
                                    tags: _tags,
                                    selectedCategory: _selectedCategory,
                                    coverFileId: _coverFileId,
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
                                    contentController: _contentController,
                                    contentError: _contentError,
                                    onBackTap: () {
                                      setState(() {
                                        _step = 0;
                                      });
                                    },
                                    onPickExtraMedia: _pickCover,
                                  ),
                          ),
                        ),
                        SizedBox(height: adaptive.scale(18)),
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
                            backLabel: l10n.backButtonLabel,
                            publishLabel: widget.isEditMode
                                ? l10n.storyUpdateAction
                                : l10n.storyPublishAction,
                            onBackTap: () {
                              setState(() {
                                _step = 0;
                              });
                            },
                            onPublishTap: () => _saveStory('PUBLISHED'),
                          ),
                          SizedBox(height: adaptive.scale(10)),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => _saveStory('DRAFT'),
                            child: Text(
                              l10n.storySaveDraftAction,
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
                  ),
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
    return SizedBox(
      height: adaptive.scale(48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBackTap,
              child: SizedBox(
                width: adaptive.scale(40),
                height: adaptive.scale(40),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: StoryPalette.text,
                  size: adaptive.scale(24),
                ),
              ),
            ),
          ),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: StoryPalette.text,
              fontSize: adaptive.scale(18),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
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

    Widget dot(int index) {
      final isCurrent = step == index;
      final isDone = step > index;
      return Container(
        width: adaptive.scale(62),
        height: adaptive.scale(62),
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
          width: adaptive.scale(62),
          height: adaptive.scale(4),
          margin: EdgeInsets.symmetric(horizontal: adaptive.scale(18)),
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
    required this.placeController,
    required this.tagController,
    required this.tags,
    required this.selectedCategory,
    required this.coverFileId,
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
  final TextEditingController placeController;
  final TextEditingController tagController;
  final List<String> tags;
  final String selectedCategory;
  final String? coverFileId;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverUploadBox(
            coverFileId: coverFileId,
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
              fontSize: adaptive.scale(34),
              height: 0.97,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
          SizedBox(height: adaptive.scale(18)),
          _StoryFormField(
            controller: placeController,
            hint: l10n.storyPlaceHint,
            leadingIcon: Icons.place_outlined,
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
              mainAxisExtent: adaptive.scale(104),
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
    required this.contentController,
    required this.contentError,
    required this.onBackTap,
    required this.onPickExtraMedia,
  });

  final TextEditingController contentController;
  final String? contentError;
  final VoidCallback onBackTap;
  final VoidCallback onPickExtraMedia;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final count = contentController.text.characters.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: adaptive.scale(360, minFactor: 0.75, maxFactor: 1.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.42),
                    width: adaptive.scale(5),
                  ),
                ),
              ),
              child: TextField(
                controller: contentController,
                minLines: 10,
                maxLines: null,
                style: TextStyle(
                  color: StoryPalette.text,
                  fontSize: adaptive.scale(25),
                  height: 1.45,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.storyContentHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.24),
                    fontSize: adaptive.scale(25),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(
                    adaptive.scale(22),
                    adaptive.scale(18),
                    adaptive.scale(6),
                    adaptive.scale(18),
                  ),
                ),
              ),
            ),
          ),
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
                  '$count / $_CreateStoryScreenState._maxContentLength',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: adaptive.scale(18),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: adaptive.scale(20)),
                Row(
                  children: [
                    _ToolButton(label: '99', onTap: null),
                    SizedBox(width: adaptive.scale(14)),
                    _ToolButton(
                      icon: Icons.add_photo_alternate_outlined,
                      onTap: onPickExtraMedia,
                    ),
                    SizedBox(width: adaptive.scale(14)),
                    _ToolButton(
                      icon: Icons.auto_awesome_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.storyAiHintUnavailable)),
                        );
                      },
                    ),
                  ],
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
    required this.backLabel,
    required this.publishLabel,
    required this.onBackTap,
    required this.onPublishTap,
  });

  final bool isSaving;
  final String backLabel;
  final String publishLabel;
  final VoidCallback onBackTap;
  final VoidCallback onPublishTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Row(
      children: [
        Expanded(
          flex: 32,
          child: OutlinedButton(
            onPressed: isSaving ? null : onBackTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.36),
                width: 2,
              ),
              minimumSize: Size(double.infinity, adaptive.scale(74)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(adaptive.radius(999)),
              ),
            ),
            child: Text(
              backLabel,
              style: TextStyle(
                fontSize: adaptive.scale(20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(width: adaptive.scale(16)),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onPublishTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, adaptive.scale(74)),
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
                    style: TextStyle(
                      fontSize: adaptive.scale(21),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
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
      height: adaptive.scale(74),
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
                  fontSize: adaptive.scale(21),
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
    required this.coverPreviewBytes,
    required this.isUploading,
    required this.errorText,
    required this.onTap,
  });

  final String? coverFileId;
  final Uint8List? coverPreviewBytes;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final hasCover =
        (coverFileId ?? '').trim().isNotEmpty || coverPreviewBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(adaptive.radius(26)),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: adaptive.scale(332)),
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
                        width: adaptive.scale(124),
                        height: adaptive.scale(124),
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

class _StoryFormField extends StatelessWidget {
  const _StoryFormField({
    this.label,
    required this.controller,
    required this.hint,
    this.errorText,
    this.leadingIcon,
  });

  final String? label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final height = adaptive.scale(72);

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
          height: height,
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
              if (leadingIcon != null) ...[
                SizedBox(width: adaptive.scale(20)),
                Icon(
                  leadingIcon,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: adaptive.scale(24),
                ),
                SizedBox(width: adaptive.scale(12)),
              ] else
                SizedBox(width: adaptive.scale(24)),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(18),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: adaptive.scale(18),
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
        Row(
          children: [
            Expanded(
              child: _StoryFormField(
                controller: controller,
                hint: l10n.storyTagHint,
              ),
            ),
            SizedBox(width: adaptive.scale(10)),
            ElevatedButton(
              onPressed: onSubmitted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: Size(adaptive.scale(54), adaptive.scale(54)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(adaptive.radius(18)),
                ),
              ),
              child: Icon(Icons.add_rounded, size: adaptive.scale(20)),
            ),
          ],
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

class _ToolButton extends StatelessWidget {
  const _ToolButton({this.label, this.icon, required this.onTap})
    : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: adaptive.scale(54),
        height: adaptive.scale(54),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.045),
          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: adaptive.scale(17),
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: adaptive.scale(22),
                ),
        ),
      ),
    );
  }
}
