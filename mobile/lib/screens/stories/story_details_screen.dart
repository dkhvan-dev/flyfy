import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/story_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/story_content_codec.dart';
import '../../features/stories/models/story_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'stories_screen.dart';

class StoryDetailsScreen extends StatefulWidget {
  const StoryDetailsScreen({
    super.key,
    required this.slug,
    this.initialStory,
    this.initialCommentId,
  });

  final String slug;
  final StoryVm? initialStory;
  final String? initialCommentId;

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  final _storyApi = StoryApi();
  final _profileApi = ProfileApi();
  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _commentsSectionKey = GlobalKey();
  final _commentComposerKey = GlobalKey();
  final Map<String, GlobalKey> _commentCardKeys = <String, GlobalKey>{};

  StoryDetailVm? _detail;
  UserProfileVm? _authorProfile;
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;
  bool _isSharing = false;
  bool _isFollowing = false;
  bool _didTrackView = false;
  bool _didHandleInitialCommentJump = false;
  String? _errorMessage;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    if (widget.initialStory != null) {
      _detail = StoryDetailVm(
        story: widget.initialStory!,
        related: const [],
        comments: const [],
      );
      _isLoading = false;
    }
    _loadDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDetail({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = _detail == null;
        _errorMessage = null;
      });
    }

    try {
      final detail = await _storyApi.getPublicStoryBySlug(widget.slug);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
        _errorMessage = null;
      });

      await Future.wait<void>([_loadAuthorProfile(), _trackViewIfNeeded()]);
      await _handleInitialCommentJump();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = DioErrorMapper.toMessage(e);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.storyLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAuthorProfile() async {
    final story = _detail?.story;
    if (story == null) {
      return;
    }
    final session = context.read<SessionProvider>();
    final currentUserId = (session.profile?.userId ?? '').trim();
    final authorUserId = story.author.userId.trim();
    if (authorUserId.isEmpty || authorUserId == currentUserId) {
      return;
    }

    try {
      final profile = await _profileApi.getUserById(authorUserId);
      if (!mounted) {
        return;
      }
      setState(() {
        _authorProfile = profile;
      });
    } catch (_) {
      // Soft failure: story should still render.
    }
  }

  GlobalKey _commentKeyFor(String commentId) {
    return _commentCardKeys.putIfAbsent(commentId, GlobalKey.new);
  }

  Future<void> _handleInitialCommentJump() async {
    final targetCommentId = (widget.initialCommentId ?? '').trim();
    if (_didHandleInitialCommentJump || targetCommentId.isEmpty) {
      return;
    }

    var detail = _detail;
    if (detail == null) {
      return;
    }

    if (!detail.comments.any((comment) => comment.id == targetCommentId)) {
      try {
        final comments = await _storyApi.listComments(
          detail.story.id,
          limit: 100,
        );
        if (!mounted) {
          return;
        }
        if (comments.any((comment) => comment.id == targetCommentId)) {
          setState(() {
            _detail = detail!.copyWith(comments: comments);
          });
          detail = _detail;
        }
      } catch (_) {
        // If the deep-linked comment is older than the initial page and the
        // fetch fails, the screen should still open normally.
      }
    }

    _didHandleInitialCommentJump = true;
    if (!(detail?.comments.any((comment) => comment.id == targetCommentId) ??
        false)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToComment(targetCommentId);
    });
  }

  Future<void> _scrollToComments({bool focusComposer = false}) async {
    final targetContext = _commentComposerKey.currentContext ??
        _commentsSectionKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: focusComposer ? 0.12 : 0.04,
      );
    }

    if (focusComposer && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    }
  }

  Future<void> _scrollToComment(String commentId) async {
    final targetContext = _commentKeyFor(commentId).currentContext;
    if (targetContext == null) {
      await _scrollToComments();
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.14,
    );
  }

  Future<void> _trackViewIfNeeded() async {
    if (_didTrackView) {
      return;
    }
    final story = _detail?.story;
    if (story == null) {
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.state != AuthState.authenticated) {
      return;
    }

    try {
      final views = await _storyApi.trackView(story.id);
      if (!mounted) {
        return;
      }
      _didTrackView = true;
      setState(() {
        _detail = _detail?.copyWith(
          story: story.copyWith(stats: story.stats.copyWith(views: views)),
        );
      });
    } catch (_) {
      _didTrackView = true;
    }
  }

  Future<void> _toggleLike() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final detail = _detail;
    if (detail == null || _isTogglingLike) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/stories/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    setState(() {
      _isTogglingLike = true;
    });

    try {
      final likes = detail.story.likedByViewer
          ? await _storyApi.unlikeStory(detail.story.id)
          : await _storyApi.likeStory(detail.story.id);
      if (!mounted) {
        return;
      }
      final updatedStory = detail.story.copyWith(
        likedByViewer: !detail.story.likedByViewer,
        stats: detail.story.stats.copyWith(likes: likes),
      );
      setState(() {
        _detail = detail.copyWith(story: updatedStory);
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLike = false;
        });
      }
    }
  }

  Future<void> _shareStory() async {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    if (detail == null || _isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final result = await _storyApi.shareStory(detail.story.id);
      final shareUrl = result.$1;
      final shares = result.$2;
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail.copyWith(
          story: detail.story.copyWith(
            shareUrl: shareUrl,
            stats: detail.story.stats.copyWith(shares: shares),
          ),
        );
      });
      if (!mounted) {
        return;
      }
      await _shareTextViaSystemSheet(
        text: shareUrl,
        title: detail.story.title,
        subject: detail.story.title,
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyShareFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final author = _authorProfile;
    if (author == null || _isFollowing) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/stories/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    setState(() {
      _isFollowing = true;
    });

    try {
      if (author.isFollowedByMe) {
        await _profileApi.unfollowUser(author.userId);
      } else {
        await _profileApi.followUser(author.userId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _authorProfile = author.copyWith(
          isFollowedByMe: !author.isFollowedByMe,
          followersCount:
              author.followersCount + (author.isFollowedByMe ? -1 : 1),
        );
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final currentUserId =
        (context.read<SessionProvider>().profile?.userId ?? '').trim();
    final detail = _detail;
    final body = _commentController.text.trim();
    final editingCommentId = _editingCommentId;
    if (detail == null || body.isEmpty || _isSubmittingComment) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/stories/${Uri.encodeComponent(widget.slug)}');
      return;
    }
    if (editingCommentId == null && _commentLockEndsAt(currentUserId) != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storyCommentRateLimit)));
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = editingCommentId == null
          ? await _storyApi.createComment(detail.story.id, body)
          : await _storyApi.updateComment(
              detail.story.id,
              editingCommentId,
              body,
            );
      if (!mounted) {
        return;
      }
      _commentController.clear();
      _commentFocusNode.unfocus();
      final nextComments = editingCommentId == null
          ? [result, ...detail.comments]
          : detail.comments
              .map((comment) => comment.id == result.id ? result : comment)
              .toList(growable: false);
      final nextStory = editingCommentId == null
          ? detail.story.copyWith(
              stats: detail.story.stats.copyWith(
                comments: detail.story.stats.comments + 1,
              ),
            )
          : detail.story;
      setState(() {
        _editingCommentId = null;
        _detail = detail.copyWith(story: nextStory, comments: nextComments);
      });
      if (editingCommentId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToComment(result.id);
        });
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _toggleCommentLike(StoryCommentVm comment) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final detail = _detail;
    if (detail == null) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/stories/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    try {
      final result = comment.likedByMe
          ? await _storyApi.unlikeComment(detail.story.id, comment.id)
          : await _storyApi.likeComment(detail.story.id, comment.id);
      if (!mounted) {
        return;
      }
      final nextComments = detail.comments
          .map(
            (item) => item.id == comment.id
                ? item.copyWith(likes: result.$1, likedByMe: result.$2)
                : item,
          )
          .toList(growable: false);
      setState(() {
        _detail = detail.copyWith(comments: nextComments);
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    }
  }

  Future<void> _shareComment(StoryCommentVm comment) async {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final shareUrl = comment.shareUrl.trim().isNotEmpty
        ? comment.shareUrl.trim()
        : '${detail.story.shareUrl}?comment=${comment.id}';
    try {
      await _shareTextViaSystemSheet(
        text: shareUrl,
        title: detail.story.title,
        subject: detail.story.title,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyCommentShareFailed,
      );
    }
  }

  Rect? _sharePositionOrigin() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _shareTextViaSystemSheet({
    required String text,
    String? title,
    String? subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: title,
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  void _startEditingComment(StoryCommentVm comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.body;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _scrollToComments(focusComposer: true);
  }

  void _cancelCommentEditing() {
    setState(() {
      _editingCommentId = null;
      _commentController.clear();
    });
    _commentFocusNode.unfocus();
  }

  StoryCommentVm? _latestRecentOwnComment(String currentUserId) {
    final normalizedUserId = currentUserId.trim();
    if (normalizedUserId.isEmpty) {
      return null;
    }
    final detail = _detail;
    if (detail == null) {
      return null;
    }

    final now = DateTime.now();
    StoryCommentVm? latest;
    for (final comment in detail.comments) {
      if (comment.author.userId.trim() != normalizedUserId) {
        continue;
      }
      if (!comment.createdAt.add(const Duration(hours: 3)).isAfter(now)) {
        continue;
      }
      if (latest == null || comment.createdAt.isAfter(latest.createdAt)) {
        latest = comment;
      }
    }
    return latest;
  }

  DateTime? _commentLockEndsAt(String currentUserId) {
    final latest = _latestRecentOwnComment(currentUserId);
    if (latest == null) {
      return null;
    }
    return latest.createdAt.add(const Duration(hours: 3)).toLocal();
  }

  String _formatCommentCooldownLabel(
    BuildContext context,
    DateTime lockEndsAt,
  ) {
    final localTime = TimeOfDay.fromDateTime(lockEndsAt);
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(localTime);
    return AppLocalizations.of(
      context,
    )!
        .storyCommentCooldownUntil(formattedTime);
  }

  Future<void> _deleteComment(StoryCommentVm comment) async {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    if (detail == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1E11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.storyDeleteCommentTitle,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.storyDeleteCommentMessage,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(l10n.storyDeleteCommentAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _storyApi.deleteComment(detail.story.id, comment.id);
      if (!mounted) {
        return;
      }
      final nextComments = detail.comments
          .where((item) => item.id != comment.id)
          .toList(growable: false);
      final nextStory = detail.story.copyWith(
        stats: detail.story.stats.copyWith(
          comments: (detail.story.stats.comments - 1).clamp(0, 1 << 31),
        ),
      );
      setState(() {
        if (_editingCommentId == comment.id) {
          _editingCommentId = null;
          _commentController.clear();
        }
        _detail = detail.copyWith(story: nextStory, comments: nextComments);
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    }
  }

  Future<void> _editStory() async {
    final story = _detail?.story;
    if (story == null) {
      return;
    }
    final result = await context.push<Object?>(
      '/stories/${story.id}/edit',
      extra: story,
    );
    if (result is! StoryVm || !mounted) {
      return;
    }
    final refreshed = result;
    if (mounted) {
      setState(() {
        _detail = _detail?.copyWith(story: refreshed);
      });
      await _loadDetail(silent: true);
      if (!mounted) {
        return;
      }
      context.pop(true);
    }
  }

  Future<void> _deleteStory() async {
    final l10n = AppLocalizations.of(context)!;
    final story = _detail?.story;
    if (story == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1E11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.storyDeleteTitle,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.storyDeleteMessage,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(l10n.storyDeleteAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _storyApi.deleteStory(story.id);
      if (!mounted) {
        return;
      }
      context.pop(true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      await showErrorDialog(
        context,
        title: l10n.error,
        message: DioErrorMapper.toMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final detail = _detail;
    final currentUserId =
        (context.watch<SessionProvider>().profile?.userId ?? '').trim();
    final story = detail?.story;
    final isAuthor = story?.isOwnedBy(currentUserId) ?? false;
    final commentLockEndsAt =
        _editingCommentId == null ? _commentLockEndsAt(currentUserId) : null;
    final isCommentComposerLocked = commentLockEndsAt != null;

    return Scaffold(
      backgroundColor: StoryPalette.backgroundDeep,
      bottomNavigationBar: StoriesBottomNavBar(
        active: StoriesNavItem.stories,
        onItemTap: (item) {
          switch (item) {
            case StoriesNavItem.home:
              context.go('/');
            case StoriesNavItem.activities:
              context.push('/activities');
            case StoriesNavItem.stories:
              context.go('/stories');
            case StoriesNavItem.chats:
              context.push('/chats');
            case StoriesNavItem.profile:
              context.push('/profile');
          }
        },
      ),
      body: DecoratedBox(
        decoration: storyScreenBackground(),
        child: SafeArea(
          bottom: false,
          child: _isLoading && detail == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : _errorMessage != null && detail == null
                  ? _StoryDetailErrorState(
                      message: _errorMessage!,
                      retryLabel: l10n.retry,
                      onRetry: _loadDetail,
                    )
                  : Builder(
                      builder: (context) {
                        final currentDetail = detail!;
                        return CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _StoryHero(
                                story: story!,
                                titleLabel: l10n.storyDetailsTitle,
                                isSharing: _isSharing,
                                onBackTap: () => context.pop(false),
                                onShareTap: _shareStory,
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                adaptive.scale(16),
                                0,
                                adaptive.scale(16),
                                adaptive.scale(28),
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0, adaptive.scale(8)),
                                      child: _AuthorCard(
                                        story: story,
                                        authorProfile: _authorProfile,
                                        isAuthor: isAuthor,
                                        isFollowing: _isFollowing,
                                        onProfileTap: () {
                                          context.push(
                                            '/users/${story.author.userId}/profile',
                                          );
                                        },
                                        onFollowTap: _toggleFollow,
                                        onEditTap: _editStory,
                                        onDeleteTap: _deleteStory,
                                        onViewsTap: null,
                                        onLikesTap: _toggleLike,
                                        onCommentsTap: () => _scrollToComments(
                                            focusComposer: true),
                                        onSharesTap: _shareStory,
                                      ),
                                    ),
                                    SizedBox(height: adaptive.scale(12)),
                                    _StoryArticle(story: story),
                                    SizedBox(height: adaptive.scale(24)),
                                    _CommentComposer(
                                      key: _commentComposerKey,
                                      controller: _commentController,
                                      focusNode: _commentFocusNode,
                                      isSubmitting: _isSubmittingComment,
                                      enabled: !isCommentComposerLocked,
                                      isEditing: _editingCommentId != null,
                                      helperText: isCommentComposerLocked
                                          ? _formatCommentCooldownLabel(
                                              context,
                                              commentLockEndsAt,
                                            )
                                          : null,
                                      editingTitle: _editingCommentId == null
                                          ? null
                                          : l10n.storyCommentEditingTitle,
                                      submitLabel: _editingCommentId == null
                                          ? null
                                          : l10n.storyCommentSaveAction,
                                      onCancelEdit: _editingCommentId == null
                                          ? null
                                          : _cancelCommentEditing,
                                      onSubmit: _submitComment,
                                    ),
                                    SizedBox(height: adaptive.scale(18)),
                                    _CommentsSection(
                                      key: _commentsSectionKey,
                                      comments: currentDetail.comments,
                                      commentKeyForId: _commentKeyFor,
                                      onEditComment: _startEditingComment,
                                      onDeleteComment: _deleteComment,
                                      onLikeComment: _toggleCommentLike,
                                      onShareComment: _shareComment,
                                    ),
                                    SizedBox(height: adaptive.scale(24)),
                                    _RelatedStoriesSection(
                                      stories: currentDetail.related,
                                      onStoryTap: (story) {
                                        context.pushReplacement(
                                          '/stories/${Uri.encodeComponent(story.slug)}',
                                          extra: story,
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
}

class _StoryHero extends StatelessWidget {
  const _StoryHero({
    required this.story,
    required this.titleLabel,
    required this.isSharing,
    required this.onBackTap,
    required this.onShareTap,
  });

  final StoryVm story;
  final String titleLabel;
  final bool isSharing;
  final VoidCallback onBackTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final heroHeight = adaptive.scale(430, minFactor: 0.82, maxFactor: 1.02);
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Container(
          height: heroHeight,
          decoration: const BoxDecoration(color: Color(0xFF1E1208)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StoryCoverImage(url: story.coverUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.28),
                      const Color(0xF2100703),
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: adaptive.scale(14),
          right: adaptive.scale(14),
          top: topInset + adaptive.scale(10),
          child: Row(
            children: [
              _OverlayIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBackTap,
              ),
              Expanded(
                child: Text(
                  titleLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: adaptive.scale(11),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _OverlayIconButton(
                icon: isSharing
                    ? Icons.hourglass_empty_rounded
                    : Icons.ios_share_rounded,
                onTap: onShareTap,
              ),
            ],
          ),
        ),
        Positioned(
          left: adaptive.scale(16),
          right: adaptive.scale(16),
          bottom: adaptive.scale(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: adaptive.scale(8),
                runSpacing: adaptive.scale(8),
                children: [
                  _HeroChip(
                    label: formatStoryCategory(
                      AppLocalizations.of(context)!,
                      story.category,
                    ),
                  ),
                  if ((story.placeName ?? '').trim().isNotEmpty)
                    _HeroChip(label: story.placeName!.trim(), accent: true),
                ],
              ),
              SizedBox(height: adaptive.scale(12)),
              Text(
                story.title,
                maxLines: adaptive.isNarrow ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: adaptive.scale(24),
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              SizedBox(height: adaptive.scale(12)),
              Row(
                children: [
                  Text(
                    formatStoryDate(context, story.sortDate),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(width: adaptive.scale(8)),
                  Container(
                    width: adaptive.scale(4),
                    height: adaptive.scale(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: adaptive.scale(8)),
                  Text(
                    '${formatStoryCountCompact(story.stats.views)} ${AppLocalizations.of(context)!.storyViewsSuffix}',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: adaptive.scale(36),
        height: adaptive.scale(36),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.18),
        ),
        child: Icon(icon, color: Colors.white, size: adaptive.scale(18)),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: adaptive.scale(9),
        vertical: adaptive.scale(6),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        color: accent
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: accent
              ? AppColors.accent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:
              accent ? AppColors.accent : Colors.white.withValues(alpha: 0.9),
          fontSize: adaptive.scale(9),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.story,
    required this.authorProfile,
    required this.isAuthor,
    required this.isFollowing,
    required this.onProfileTap,
    required this.onFollowTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onViewsTap,
    required this.onLikesTap,
    required this.onCommentsTap,
    required this.onSharesTap,
  });

  final StoryVm story;
  final UserProfileVm? authorProfile;
  final bool isAuthor;
  final bool isFollowing;
  final VoidCallback onProfileTap;
  final VoidCallback onFollowTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onViewsTap;
  final VoidCallback? onLikesTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onSharesTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        adaptive.scale(14),
        adaptive.scale(16),
        adaptive.scale(14),
        adaptive.scale(12),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(24)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A180C), Color(0xFF23140A)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: adaptive.scale(34),
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: StoryAvatar(
                  label: story.author.initials,
                  imageUrl: story.author.avatarUrl,
                  size: adaptive.scale(42),
                ),
              ),
              SizedBox(width: adaptive.scale(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storyAuthorLabel,
                      style: TextStyle(
                        color: StoryPalette.textMuted,
                        fontSize: adaptive.scale(8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: adaptive.scale(4)),
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Text(
                        story.author.preferredName,
                        style: TextStyle(
                          color: StoryPalette.text,
                          fontSize: adaptive.scale(15),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: adaptive.scale(14)),
          if (isAuthor)
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: OutlinedButton(
                    onPressed: onEditTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.24),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          adaptive.radius(999),
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.storyEditAction,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ),
                SizedBox(width: adaptive.scale(10)),
                Expanded(
                  flex: 4,
                  child: TextButton(
                    onPressed: onDeleteTap,
                    style: TextButton.styleFrom(
                      foregroundColor: StoryPalette.textSoft,
                    ),
                    child: Text(l10n.storyDeleteAction),
                  ),
                ),
              ],
            )
          else if (authorProfile != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: isFollowing ? null : onFollowTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.24),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(adaptive.radius(999)),
                  ),
                ),
                child: Text(
                  authorProfile!.isFollowedByMe
                      ? l10n.storyFollowingAction
                      : (isFollowing
                          ? l10n.storyFollowingAction
                          : l10n.storyFollowAction),
                ),
              ),
            ),
          SizedBox(height: adaptive.scale(12)),
          Container(
            padding: EdgeInsets.only(top: adaptive.scale(12)),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.remove_red_eye_outlined,
                    number: formatStoryCountCompact(story.stats.views),
                    label: l10n.storyStatViews,
                    onTap: onViewsTap,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: story.likedByViewer
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    number: formatStoryCountCompact(story.stats.likes),
                    label: l10n.storyStatLikes,
                    onTap: onLikesTap,
                    active: story.likedByViewer,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.mode_comment_outlined,
                    number: formatStoryCountCompact(story.stats.comments),
                    label: l10n.storyStatComments,
                    onTap: onCommentsTap,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.number,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String number;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final iconColor = active ? AppColors.accent : StoryPalette.textSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: adaptive.scale(6),
            horizontal: adaptive.scale(4),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: adaptive.scale(18)),
              SizedBox(height: adaptive.scale(6)),
              Text(
                number,
                style: TextStyle(
                  color: active
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.82),
                  fontSize: adaptive.scale(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: adaptive.scale(2)),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? AppColors.accent : StoryPalette.textMuted,
                  fontSize: adaptive.scale(8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryArticle extends StatelessWidget {
  const _StoryArticle({required this.story});

  final StoryVm story;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final content = (story.content ?? '').trim();
    final parts = content.isEmpty
        ? <StoryContentPart>[StoryContentPart.text(story.excerpt)]
        : parseStoryContentParts(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final part in parts) ...[
          if (part.isText)
            ...((part.text ?? '')
                .split(RegExp(r'\n{2,}'))
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .map(
                  (paragraph) => Padding(
                    padding: EdgeInsets.only(bottom: adaptive.scale(16)),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: adaptive.scale(15),
                        height: 1.8,
                      ),
                    ),
                  ),
                )),
          if (!part.isText && (part.imageFileId ?? '').trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: adaptive.scale(18)),
              child: _StoryArticleImage(fileId: part.imageFileId!.trim()),
            ),
        ],
        if (story.tags.isNotEmpty) ...[
          SizedBox(height: adaptive.scale(8)),
          Text(
            AppLocalizations.of(context)!.storyTagsLabel,
            style: TextStyle(
              color: StoryPalette.textMuted,
              fontSize: adaptive.scale(9),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: adaptive.scale(10)),
          Wrap(
            spacing: adaptive.scale(8),
            runSpacing: adaptive.scale(8),
            children: [
              for (final tag in story.tags)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptive.scale(11),
                    vertical: adaptive.scale(7),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(adaptive.radius(999)),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: adaptive.scale(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StoryArticleImage extends StatelessWidget {
  const _StoryArticleImage({required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final imageUrl = resolvePublicFileContentUrl(fileId);
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(adaptive.radius(22)),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF2A1708)),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.enabled,
    required this.isEditing,
    required this.helperText,
    required this.editingTitle,
    required this.submitLabel,
    required this.onCancelEdit,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final bool enabled;
  final bool isEditing;
  final String? helperText;
  final String? editingTitle;
  final String? submitLabel;
  final VoidCallback? onCancelEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (editingTitle != null) ...[
          Container(
            margin: EdgeInsets.only(bottom: adaptive.scale(10)),
            padding: EdgeInsets.symmetric(
              horizontal: adaptive.scale(14),
              vertical: adaptive.scale(10),
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(adaptive.radius(16)),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    editingTitle!,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: adaptive.scale(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onCancelEdit != null)
                  TextButton(
                    onPressed: onCancelEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: StoryPalette.textSoft,
                      padding: EdgeInsets.symmetric(
                        horizontal: adaptive.scale(8),
                        vertical: adaptive.scale(4),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.cancel),
                  ),
              ],
            ),
          ),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(adaptive.radius(20)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled || isEditing,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(
                    color: StoryPalette.text,
                    fontSize: adaptive.scale(15),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.storyCommentHint,
                    hintStyle: TextStyle(
                      color: StoryPalette.textMuted,
                      fontSize: adaptive.scale(15),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: adaptive.scale(16),
                      vertical: adaptive.scale(14),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: adaptive.scale(10)),
            ElevatedButton(
              onPressed:
                  isSubmitting || (!enabled && !isEditing) ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: Size(adaptive.scale(54), adaptive.scale(54)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(adaptive.radius(18)),
                ),
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: adaptive.scale(18),
                      height: adaptive.scale(18),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : isEditing
                      ? Text(
                          submitLabel ?? l10n.storyCommentSaveAction,
                          style: TextStyle(
                            fontSize: adaptive.scale(13),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Icon(Icons.send_rounded, size: adaptive.scale(18)),
            ),
          ],
        ),
        if ((helperText ?? '').trim().isNotEmpty) ...[
          SizedBox(height: adaptive.scale(8)),
          Text(
            helperText!,
            style: TextStyle(
              color: StoryPalette.textMuted,
              fontSize: adaptive.scale(12),
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    super.key,
    required this.comments,
    required this.commentKeyForId,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onLikeComment,
    required this.onShareComment,
  });

  final List<StoryCommentVm> comments;
  final GlobalKey Function(String commentId) commentKeyForId;
  final ValueChanged<StoryCommentVm> onEditComment;
  final ValueChanged<StoryCommentVm> onDeleteComment;
  final ValueChanged<StoryCommentVm> onLikeComment;
  final ValueChanged<StoryCommentVm> onShareComment;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.storyCommentsTitle,
          style: TextStyle(
            color: StoryPalette.text,
            fontSize: adaptive.scale(20),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: adaptive.scale(14)),
        if (comments.isEmpty)
          Text(
            l10n.storyCommentsEmpty,
            style: TextStyle(
              color: StoryPalette.textSoft,
              fontSize: adaptive.scale(15),
            ),
          )
        else
          Column(
            children: [
              for (final comment in comments) ...[
                _CommentCard(
                  key: commentKeyForId(comment.id),
                  comment: comment,
                  onEdit:
                      comment.editable ? () => onEditComment(comment) : null,
                  onDelete:
                      comment.deletable ? () => onDeleteComment(comment) : null,
                  onLike: () => onLikeComment(comment),
                  onShare: () => onShareComment(comment),
                ),
                SizedBox(height: adaptive.scale(12)),
              ],
            ],
          ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onShare,
    this.onEdit,
    this.onDelete,
  });

  final StoryCommentVm comment;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(adaptive.scale(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(adaptive.radius(18)),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StoryAvatar(
                label: comment.author.initials,
                imageUrl: comment.author.avatarUrl,
                size: adaptive.scale(34),
              ),
              SizedBox(width: adaptive.scale(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.preferredName,
                      style: TextStyle(
                        color: StoryPalette.text,
                        fontSize: adaptive.scale(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatStoryDate(context, comment.createdAt),
                      style: TextStyle(
                        color: StoryPalette.textMuted,
                        fontSize: adaptive.scale(11),
                      ),
                    ),
                    if (comment.edited) ...[
                      SizedBox(height: adaptive.scale(2)),
                      Text(
                        '• ${AppLocalizations.of(context)!.chatEditedLabel}',
                        style: TextStyle(
                          color: StoryPalette.textMuted,
                          fontSize: adaptive.scale(11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: adaptive.scale(10)),
          Text(
            comment.body,
            style: TextStyle(
              color: StoryPalette.textSoft,
              fontSize: adaptive.scale(15),
              height: 1.5,
            ),
          ),
          SizedBox(height: adaptive.scale(12)),
          Wrap(
            spacing: adaptive.scale(10),
            runSpacing: adaptive.scale(10),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CommentActionButton(
                icon: comment.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: formatStoryCountCompact(comment.likes),
                accent: comment.likedByMe,
                onTap: onLike,
              ),
              _CommentActionButton(
                icon: Icons.share_outlined,
                label: AppLocalizations.of(context)!.storyCommentShareAction,
                onTap: onShare,
              ),
              if (onEdit != null)
                _CommentActionButton(
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context)!.storyEditAction,
                  onTap: onEdit!,
                ),
              if (onDelete != null)
                _CommentActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalizations.of(context)!.storyDeleteCommentAction,
                  onTap: onDelete!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentActionButton extends StatelessWidget {
  const _CommentActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final color = accent ? AppColors.accent : StoryPalette.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(adaptive.radius(999)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: adaptive.scale(10),
            vertical: adaptive.scale(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: adaptive.scale(15)),
              SizedBox(width: adaptive.scale(6)),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: adaptive.scale(12),
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

class _RelatedStoriesSection extends StatelessWidget {
  const _RelatedStoriesSection({
    required this.stories,
    required this.onStoryTap,
  });

  final List<StoryVm> stories;
  final ValueChanged<StoryVm> onStoryTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.storyRelatedEyebrow,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: adaptive.scale(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: adaptive.scale(6)),
                  Text(
                    l10n.storyRelatedTitle,
                    style: TextStyle(
                      color: StoryPalette.text,
                      fontSize: adaptive.scale(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/stories'),
              child: Text(
                l10n.storyViewAll,
                style: TextStyle(
                  color: const Color(0xFFFFBD55),
                  fontSize: adaptive.scale(10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: adaptive.scale(14)),
        if (stories.isEmpty)
          Text(
            l10n.storyRelatedEmpty,
            style: TextStyle(
              color: StoryPalette.textSoft,
              fontSize: adaptive.scale(15),
            ),
          )
        else
          Column(
            children: [
              for (final story in stories) ...[
                GestureDetector(
                  onTap: () => onStoryTap(story),
                  child: Container(
                    margin: EdgeInsets.only(bottom: adaptive.scale(14)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(adaptive.radius(14)),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF22140A), Color(0xFF1B1008)],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: adaptive.scale(220),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(adaptive.radius(14)),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              StoryCoverImage(url: story.coverUrl),
                              Positioned(
                                left: adaptive.scale(10),
                                top: adaptive.scale(10),
                                child: _HeroChip(
                                  label: (story.placeName ?? '').trim().isEmpty
                                      ? formatStoryCategory(
                                          l10n,
                                          story.category,
                                        )
                                      : story.placeName!.trim(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            adaptive.scale(12),
                            adaptive.scale(12),
                            adaptive.scale(12),
                            adaptive.scale(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFF6EDE2),
                                  fontSize: adaptive.scale(15),
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: adaptive.scale(4)),
                              Text(
                                story.author.preferredName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.48),
                                  fontSize: adaptive.scale(10),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _StoryDetailErrorState extends StatelessWidget {
  const _StoryDetailErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accent,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: StoryPalette.textSoft),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => onRetry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
