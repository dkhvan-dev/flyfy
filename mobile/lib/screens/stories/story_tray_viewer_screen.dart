import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../core/network/chat_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/chat/models/message_vm.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';

const _defaultStoryDuration = Duration(seconds: 5);
const _maxVisibleProgressSegments = 7;
const _viewerTopControlsReservedHeight = 92.0;
const _viewerBottomPadding = 28.0;
const _viewerMetadataGap = 12.0;

class StoryTrayViewerRouteData {
  const StoryTrayViewerRouteData({
    required this.stories,
    this.initialIndex = 0,
    this.source = 'feed_tray',
    this.allowExpired = false,
    this.trackSeen = true,
  });

  final List<StoryVm> stories;
  final int initialIndex;
  final String source;
  final bool allowExpired;
  final bool trackSeen;
}

class StoryTrayViewerScreen extends StatefulWidget {
  const StoryTrayViewerScreen({
    super.key,
    required this.data,
    StoryApi? storyApi,
    ChatApi? chatApi,
    this.storyDuration = _defaultStoryDuration,
  }) : _storyApiOverride = storyApi,
       _chatApiOverride = chatApi;

  final StoryTrayViewerRouteData data;
  final Duration storyDuration;
  final StoryApi? _storyApiOverride;
  final ChatApi? _chatApiOverride;

  @override
  State<StoryTrayViewerScreen> createState() => _StoryTrayViewerScreenState();
}

class _StoryTrayViewerScreenState extends State<StoryTrayViewerScreen>
    with SingleTickerProviderStateMixin {
  late final StoryApi _storyApi = widget._storyApiOverride ?? StoryApi();
  late final ChatApi _chatApi = widget._chatApiOverride ?? ChatApi();
  late final List<StoryVm> _stories = widget.data.stories
      .where(
        (story) =>
            _isStoryViewable(story, allowExpired: widget.data.allowExpired),
      )
      .toList(growable: false);
  late final String? _initialStoryId = _storyIdAt(
    widget.data.stories,
    widget.data.initialIndex,
  );
  late final AnimationController _progressController;
  late int _index = _initialIndex();
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  final Set<String> _seenStoryIds = <String>{};
  final Set<String> _likedStoryIds = <String>{};
  final Set<String> _likingStoryIds = <String>{};
  bool _isHoldingProgress = false;
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.storyDuration > Duration.zero
          ? widget.storyDuration
          : _defaultStoryDuration,
    )..addStatusListener(_handleProgressStatus);
    _likedStoryIds.addAll(
      _stories
          .where((story) => story.likedByViewer)
          .map((story) => story.id.trim())
          .where((storyId) => storyId.isNotEmpty),
    );
    _replyFocusNode.addListener(_handleReplyFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _markCurrentStorySeen();
      _restartProgress();
    });
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_handleProgressStatus);
    _progressController.dispose();
    _replyFocusNode.removeListener(_handleReplyFocusChanged);
    _replyFocusNode.dispose();
    _replyController.dispose();
    super.dispose();
  }

  int _initialIndex() {
    if (_stories.isEmpty) {
      return 0;
    }
    final initialStoryId = _initialStoryId;
    if (initialStoryId != null) {
      final filteredIndex = _stories.indexWhere(
        (story) => story.id == initialStoryId,
      );
      if (filteredIndex >= 0) {
        return filteredIndex;
      }
    }
    return widget.data.initialIndex.clamp(0, _stories.length - 1).toInt();
  }

  StoryVm? get _currentStory {
    if (_stories.isEmpty || _index < 0 || _index >= _stories.length) {
      return null;
    }
    return _stories[_index];
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_isHoldingProgress) {
      _goNext();
    }
  }

  void _restartProgress() {
    if (_stories.isEmpty) {
      return;
    }
    _progressController
      ..stop()
      ..forward(from: 0);
  }

  Future<void> _markCurrentStorySeen() async {
    if (!widget.data.trackSeen) {
      return;
    }
    final story = _currentStory;
    final storyId = story?.id.trim() ?? '';
    if (story == null || storyId.isEmpty || !_seenStoryIds.add(storyId)) {
      return;
    }

    final auth = _readAuthProvider(context);
    if (auth?.state != AuthState.authenticated) {
      return;
    }

    try {
      await _storyApi.markStorySeen(storyId);
    } catch (_) {
      // Seen sync is best-effort; the viewer should never block browsing.
    }
  }

  void _goNext() {
    _progressController.stop();
    if (_stories.isEmpty) {
      _close();
      return;
    }
    if (_index >= _stories.length - 1) {
      _close();
      return;
    }
    setState(() {
      _index += 1;
    });
    _markCurrentStorySeen();
    _restartProgress();
  }

  void _goPrevious() {
    if (_stories.isEmpty || _index == 0) {
      return;
    }
    _progressController.stop();
    setState(() {
      _index -= 1;
    });
    _markCurrentStorySeen();
    _restartProgress();
  }

  void _pauseProgress() {
    if (_stories.isEmpty) {
      return;
    }
    _isHoldingProgress = true;
    _progressController.stop();
  }

  void _resumeProgress() {
    if (_stories.isEmpty) {
      return;
    }
    _isHoldingProgress = false;
    if (!_progressController.isAnimating) {
      _progressController.forward();
    }
  }

  void _handleReplyFocusChanged() {
    if (_replyFocusNode.hasFocus) {
      _pauseProgress();
      return;
    }
    if (!_isSendingReply) {
      _isHoldingProgress = false;
      _resumeProgress();
    }
  }

  Future<void> _sendReplyToCurrentStory() async {
    final story = _currentStory;
    final text = _replyController.text.trim();
    final authorUserId = story?.author.userId.trim() ?? '';
    if (story == null ||
        text.isEmpty ||
        authorUserId.isEmpty ||
        _isSendingReply) {
      return;
    }

    _pauseProgress();
    setState(() => _isSendingReply = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      final conversationId = await _chatApi.createDirectConversation(
        authorUserId,
      );
      await _chatApi.sendMessage(
        conversationId,
        content: text,
        storyReply: _storyReplyContext(story),
      );
      if (!mounted) {
        return;
      }
      _replyController.clear();
      _replyFocusNode.unfocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storyReplySentMessage)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyReplySendFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
        if (!_replyFocusNode.hasFocus) {
          _isHoldingProgress = false;
          _resumeProgress();
        }
      }
    }
  }

  Future<void> _likeCurrentStory() async {
    final story = _currentStory;
    final storyId = story?.id.trim() ?? '';
    if (story == null ||
        storyId.isEmpty ||
        _likedStoryIds.contains(storyId) ||
        _likingStoryIds.contains(storyId)) {
      return;
    }

    setState(() {
      _likingStoryIds.add(storyId);
    });

    final l10n = AppLocalizations.of(context)!;
    try {
      await _storyApi.likeStory(storyId);
      if (!mounted) {
        return;
      }
      setState(() {
        _likedStoryIds.add(storyId);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyLikeSendFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _likingStoryIds.remove(storyId);
        });
      }
    }
  }

  void _close() {
    if (!mounted) {
      return;
    }
    _progressController.stop();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop<Set<String>>(_seenStoryIds);
      return;
    }

    try {
      context.go('/feed');
    } catch (_) {
      // When embedded outside GoRouter and not on a stack, there is no
      // navigation target to close to.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final story = _currentStory;
    final currentUserId = _currentUserId(context);
    final canReply =
        story != null &&
        !story.isOwnedBy(currentUserId) &&
        story.author.userId.trim().isNotEmpty;
    final currentStoryId = story?.id.trim() ?? '';
    final isCurrentStoryLiked =
        currentStoryId.isNotEmpty &&
        (story?.likedByViewer == true ||
            _likedStoryIds.contains(currentStoryId));
    final isCurrentStoryLiking =
        currentStoryId.isNotEmpty && _likingStoryIds.contains(currentStoryId);

    return PopScope<Set<String>>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _close();
        }
      },
      child: Theme(
        data: AppDesignSystem.themeFor(context),
        child: Scaffold(
          key: const ValueKey('story-sequence-viewer'),
          backgroundColor: colors.black,
          body: SafeArea(
            child: story == null
                ? _EmptyViewer(onClose: _close)
                : _ViewerBody(
                    stories: _stories,
                    currentIndex: _index,
                    currentProgress: _progressController.view,
                    story: story,
                    onClose: _close,
                    onNext: _goNext,
                    onPrevious: _goPrevious,
                    onPause: _pauseProgress,
                    onResume: _resumeProgress,
                    replyController: _replyController,
                    replyFocusNode: _replyFocusNode,
                    canReply: canReply,
                    isSendingReply: _isSendingReply,
                    isLiked: isCurrentStoryLiked,
                    isLiking: isCurrentStoryLiking,
                    onSendReply: _sendReplyToCurrentStory,
                    onLike: _likeCurrentStory,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ViewerBody extends StatelessWidget {
  const _ViewerBody({
    required this.stories,
    required this.currentIndex,
    required this.currentProgress,
    required this.story,
    required this.onClose,
    required this.onNext,
    required this.onPrevious,
    required this.onPause,
    required this.onResume,
    required this.replyController,
    required this.replyFocusNode,
    required this.canReply,
    required this.isSendingReply,
    required this.isLiked,
    required this.isLiking,
    required this.onSendReply,
    required this.onLike,
  });

  final List<StoryVm> stories;
  final int currentIndex;
  final Animation<double> currentProgress;
  final StoryVm story;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final TextEditingController replyController;
  final FocusNode replyFocusNode;
  final bool canReply;
  final bool isSendingReply;
  final bool isLiked;
  final bool isLiking;
  final VoidCallback onSendReply;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final textTheme = Theme.of(context).textTheme;

    void closeOnDownSwipe(DragEndDetails details) {
      if ((details.primaryVelocity ?? 0) > 500) {
        onClose();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final metadataMaxHeight = _metadataMaxHeightFor(constraints.maxHeight);
        final useCompactMetadata = metadataMaxHeight < 96;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: closeOnDownSwipe,
          child: Stack(
            children: [
              Positioned.fill(child: StoryCoverImage(url: story.coverUrl)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: AppBoxDecoration(
                    gradient: _storyViewerOverlayGradient(colors),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('story-sequence-previous'),
                        behavior: HitTestBehavior.translucent,
                        onTap: onPrevious,
                        onLongPressStart: (_) => onPause(),
                        onLongPressEnd: (_) => onResume(),
                        onLongPressUp: onResume,
                        onLongPressCancel: onResume,
                        onVerticalDragEnd: closeOnDownSwipe,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('story-sequence-next'),
                        behavior: HitTestBehavior.translucent,
                        onTap: onNext,
                        onLongPressStart: (_) => onPause(),
                        onLongPressEnd: (_) => onResume(),
                        onLongPressUp: onResume,
                        onLongPressCancel: onResume,
                        onVerticalDragEnd: closeOnDownSwipe,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StoryProgressStrip(
                      stories: stories,
                      currentIndex: currentIndex,
                      currentProgress: currentProgress,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StoryAvatar(
                          label: story.author.initials,
                          imageUrl: story.author.avatarUrl,
                          size: 36,
                          borderColor: colors.white.withValues(alpha: 0.72),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            story.author.preferredName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('story-sequence-close'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                          color: colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (metadataMaxHeight > 0)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: _viewerBottomPadding,
                  child: ConstrainedBox(
                    key: const ValueKey('story-sequence-metadata'),
                    constraints: BoxConstraints(maxHeight: metadataMaxHeight),
                    child: useCompactMetadata
                        ? Align(
                            alignment: Alignment.bottomLeft,
                            child: canReply
                                ? _StoryReplyComposer(
                                    controller: replyController,
                                    focusNode: replyFocusNode,
                                    isSending: isSendingReply,
                                    isLiked: isLiked,
                                    isLiking: isLiking,
                                    onSend: onSendReply,
                                    onLike: onLike,
                                  )
                                : const SizedBox.shrink(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        story.title,
                                        key: ValueKey(
                                          'story-sequence-title-${story.id}',
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      if (story.excerpt.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          story.excerpt.trim(),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colors.white.withValues(
                                              alpha: 0.82,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (canReply) ...[
                                const SizedBox(height: 14),
                                _StoryReplyComposer(
                                  controller: replyController,
                                  focusNode: replyFocusNode,
                                  isSending: isSendingReply,
                                  isLiked: isLiked,
                                  isLiking: isLiking,
                                  onSend: onSendReply,
                                  onLike: onLike,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StoryReplyComposer extends StatefulWidget {
  const _StoryReplyComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isLiked,
    required this.isLiking,
    required this.onSend,
    required this.onLike,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isLiked;
  final bool isLiking;
  final VoidCallback onSend;
  final VoidCallback onLike;

  @override
  State<_StoryReplyComposer> createState() => _StoryReplyComposerState();
}

class _StoryReplyComposerState extends State<_StoryReplyComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncTextState);
    _syncTextState();
  }

  @override
  void didUpdateWidget(covariant _StoryReplyComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncTextState);
      widget.controller.addListener(_syncTextState);
      _syncTextState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTextState);
    super.dispose();
  }

  void _syncTextState() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: _storyViewerPillDecoration(colors),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('story-sequence-reply-field'),
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (_hasText && !widget.isSending) {
                  widget.onSend();
                }
              },
              style: AppTextStyle(
                color: colors.white,
                fontWeight: FontWeight.w700,
              ),
              decoration: AppInputDecoration(
                hintText: l10n.storyReplyInputHint,
                hintStyle: AppTextStyle(
                  color: colors.white.withValues(alpha: 0.68),
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const AppEdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('story-sequence-like-story'),
            tooltip: l10n.storyLikeAction,
            onPressed: widget.isLiked || widget.isLiking ? null : widget.onLike,
            color: widget.isLiked
                ? colors.danger
                : colors.white.withValues(alpha: 0.92),
            disabledColor: widget.isLiked
                ? colors.danger
                : colors.white.withValues(alpha: 0.44),
            icon: widget.isLiking
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textPrimary,
                    ),
                  )
                : Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 24,
                  ),
          ),
          Padding(
            padding: const AppEdgeInsets.only(right: 5),
            child: IconButton.filled(
              key: const ValueKey('story-sequence-send-reply'),
              tooltip: l10n.storyReplySendAction,
              onPressed: _hasText && !widget.isSending ? widget.onSend : null,
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.white.withValues(alpha: 0.16),
                foregroundColor: colors.onPrimary,
                disabledForegroundColor: colors.textSecondary.withValues(
                  alpha: 0.38,
                ),
                minimumSize: const Size.square(38),
              ),
              icon: widget.isSending
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryProgressStrip extends StatelessWidget {
  const _StoryProgressStrip({
    required this.stories,
    required this.currentIndex,
    required this.currentProgress,
  });

  final List<StoryVm> stories;
  final int currentIndex;
  final Animation<double> currentProgress;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return AnimatedBuilder(
      animation: currentProgress,
      builder: (context, _) {
        final window = _ProgressWindow.forStories(
          storyCount: stories.length,
          currentIndex: currentIndex,
        );

        return Row(
          children: [
            for (var index = window.start; index < window.end; index++) ...[
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'story-sequence-progress-${stories[index].id}',
                    ),
                    minHeight: 3,
                    value: index < currentIndex
                        ? 1
                        : index == currentIndex
                        ? currentProgress.value
                        : 0,
                    backgroundColor: colors.white.withValues(alpha: 0.28),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index == currentIndex
                          ? colors.primary
                          : colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              if (index != window.end - 1) const SizedBox(width: 4),
            ],
          ],
        );
      },
    );
  }
}

double _metadataMaxHeightFor(double viewportHeight) {
  final available =
      viewportHeight -
      _viewerTopControlsReservedHeight -
      _viewerBottomPadding -
      _viewerMetadataGap;
  if (available <= 0) {
    return 0;
  }

  final proportionalCap = viewportHeight * 0.56;
  final cappedHeight = available < proportionalCap
      ? available
      : proportionalCap;
  return cappedHeight < 0 ? 0 : cappedHeight.toDouble();
}

class _ProgressWindow {
  const _ProgressWindow({required this.start, required this.end});

  final int start;
  final int end;

  static _ProgressWindow forStories({
    required int storyCount,
    required int currentIndex,
  }) {
    if (storyCount <= _maxVisibleProgressSegments) {
      return _ProgressWindow(start: 0, end: storyCount);
    }

    final halfWindow = _maxVisibleProgressSegments ~/ 2;
    final maxStart = storyCount - _maxVisibleProgressSegments;
    final start = (currentIndex - halfWindow).clamp(0, maxStart).toInt();
    return _ProgressWindow(
      start: start,
      end: start + _maxVisibleProgressSegments,
    );
  }
}

class _EmptyViewer extends StatelessWidget {
  const _EmptyViewer({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const AppEdgeInsets.all(24),
            child: Text(
              l10n.storyEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: IconButton(
            key: const ValueKey('story-sequence-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: colors.white,
          ),
        ),
      ],
    );
  }
}

LinearGradient _storyViewerOverlayGradient(AppColors colors) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      colors.black.withValues(alpha: 0.64),
      colors.black.withValues(alpha: 0.08),
      colors.black.withValues(alpha: 0.78),
    ],
    stops: const [0, 0.42, 1],
  );
}

BoxDecoration _storyViewerPillDecoration(AppColors colors) {
  return AppBoxDecoration(
    color: colors.white.withValues(alpha: 0.14),
    borderRadius: AppBorderRadius.circular(999),
    border: Border.all(color: colors.white.withValues(alpha: 0.24)),
  );
}

bool _isStoryViewable(StoryVm story, {bool allowExpired = false}) {
  return story.isPublished &&
      (allowExpired || !story.isExpired) &&
      story.slug.trim().isNotEmpty;
}

String? _storyIdAt(List<StoryVm> stories, int index) {
  if (index < 0 || index >= stories.length) {
    return null;
  }
  final id = stories[index].id.trim();
  return id.isEmpty ? null : id;
}

AuthProvider? _readAuthProvider(BuildContext context) {
  try {
    return context.read<AuthProvider>();
  } catch (_) {
    return null;
  }
}

String? _currentUserId(BuildContext context) {
  try {
    return context.read<SessionProvider>().profile?.userId;
  } catch (_) {
    return null;
  }
}

StoryReplyContextVm _storyReplyContext(StoryVm story) {
  return StoryReplyContextVm(
    storyId: story.id,
    storyAuthorUserId: story.author.userId,
    storyTitle: story.title,
    storyPreviewFileId: story.coverFileId,
    storyPreviewUrl: story.coverImageUrl,
    storyExpiresAt: story.expiresAt,
  );
}
