import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/dio_error_mapper.dart';
import '../../core/network/file_api.dart';
import '../../core/network/post_api.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../features/feed/data/feed_api.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../features/stories/editor/domain/story_document.dart';
import '../../features/stories/models/post_vm.dart';
import '../../features/stories/story_ui.dart';
import '../../features/stories/widgets/story_document_renderer.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';

class StoryDetailsScreen extends StatefulWidget {
  const StoryDetailsScreen({
    super.key,
    required this.slug,
    this.initialStory,
    this.initialCommentId,
    PostApi? postApi,
    FeedApi? feedApi,
    ProfileApi? profileApi,
    FileApi? fileApi,
  }) : _postApiOverride = postApi,
       _feedApiOverride = feedApi,
       _profileApiOverride = profileApi,
       _fileApiOverride = fileApi;

  final String slug;
  final PostVm? initialStory;
  final String? initialCommentId;
  final PostApi? _postApiOverride;
  final FeedApi? _feedApiOverride;
  final ProfileApi? _profileApiOverride;
  final FileApi? _fileApiOverride;

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  late final PostApi _postApi;
  late final FeedApi _feedApi;
  late final ProfileApi _profileApi;
  late final FileApi _fileApi;
  final _scrollController = ScrollController();
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _commentsSectionKey = GlobalKey();
  final _commentComposerKey = GlobalKey();
  final Map<String, GlobalKey> _commentCardKeys = <String, GlobalKey>{};

  PostDetailVm? _detail;
  UserProfileVm? _authorProfile;
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;
  bool _isSharing = false;
  bool _isSubmittingReport = false;
  bool _isFollowing = false;
  bool _didMarkSeen = false;
  bool _didHandleInitialCommentJump = false;
  String? _errorMessage;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _postApi = widget._postApiOverride ?? PostApi();
    _feedApi = widget._feedApiOverride ?? FeedApi();
    _profileApi = widget._profileApiOverride ?? ProfileApi();
    _fileApi = widget._fileApiOverride ?? FileApi();
    if (widget.initialStory != null) {
      _detail = PostDetailVm(
        post: widget.initialStory!,
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
    final initialStory = widget.initialStory;
    final shouldLoadOwnedStory =
        initialStory != null && !initialStory.isPublished;
    if (!silent) {
      setState(() {
        _isLoading = _detail == null;
        _errorMessage = null;
      });
    }

    try {
      if (shouldLoadOwnedStory) {
        final storyId = initialStory.id.trim().isNotEmpty
            ? initialStory.id.trim()
            : widget.slug.trim();
        final story = await _postApi.getPostById(storyId);
        if (!mounted) {
          return;
        }
        setState(() {
          _detail = PostDetailVm(
            post: story,
            related: const [],
            comments: const [],
          );
          _isLoading = false;
          _errorMessage = null;
        });
        await _loadAuthorProfile();
        return;
      }

      final detail = await _postApi.getPublicPostBySlug(widget.slug);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
        _errorMessage = null;
      });

      await Future.wait<void>([_loadAuthorProfile(), _markSeenIfNeeded()]);
      await _handleInitialCommentJump();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      if (shouldLoadOwnedStory && _detail != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
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
      if (shouldLoadOwnedStory && _detail != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.storyLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAuthorProfile() async {
    final story = _detail?.post;
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
    if (!detail.post.isPublished) {
      _didHandleInitialCommentJump = true;
      return;
    }

    if (!detail.comments.any((comment) => comment.id == targetCommentId)) {
      try {
        final comments = await _postApi.listComments(
          detail.post.id,
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
    final targetContext =
        _commentComposerKey.currentContext ??
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

  Future<void> _markSeenIfNeeded() async {
    if (_didMarkSeen) {
      return;
    }
    final story = _detail?.post;
    if (story == null ||
        !story.isPublished ||
        story.id.trim().isEmpty ||
        story.isSeenByViewer ||
        story.isExpired) {
      _didMarkSeen = true;
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.state != AuthState.authenticated) {
      return;
    }

    try {
      final seenAt = await _postApi.markPostSeen(story.id);
      if (!mounted) {
        return;
      }
      _didMarkSeen = true;
      setState(() {
        final currentStory = _detail?.post;
        if (currentStory == null) {
          return;
        }
        _detail = _detail?.copyWith(
          post: currentStory.copyWith(
            seenByViewer: true,
            seenAt: seenAt ?? DateTime.now().toUtc(),
          ),
        );
      });
    } catch (_) {
      _didMarkSeen = true;
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
      context.push('/login?from=/posts/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    setState(() {
      _isTogglingLike = true;
    });

    try {
      final likes = detail.post.likedByViewer
          ? await _postApi.unlikePost(detail.post.id)
          : await _postApi.likePost(detail.post.id);
      if (!mounted) {
        return;
      }
      final updatedStory = detail.post.copyWith(
        likedByViewer: !detail.post.likedByViewer,
        stats: detail.post.stats.copyWith(likes: likes),
      );
      setState(() {
        _detail = detail.copyWith(post: updatedStory);
      });
      if (!detail.post.likedByViewer) {
        unawaited(
          _trackPostEngagement(
            updatedStory,
            FeedEventTypes.like,
            metadata: {'engagementType': FeedEventTypes.like},
          ),
        );
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
          _isTogglingLike = false;
        });
      }
    }
  }

  Future<void> _sharePost() async {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    if (detail == null || _isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final result = await _postApi.sharePost(detail.post.id);
      final shareUrl = result.$1;
      final shares = result.$2;
      if (!mounted) {
        return;
      }
      final updatedStory = detail.post.copyWith(
        shareUrl: shareUrl,
        stats: detail.post.stats.copyWith(shares: shares),
      );
      setState(() {
        _detail = detail.copyWith(post: updatedStory);
      });
      unawaited(
        _trackPostEngagement(
          updatedStory,
          FeedEventTypes.share,
          metadata: {
            'engagementType': FeedEventTypes.share,
            if (shareUrl.trim().isNotEmpty) 'shareUrl': shareUrl.trim(),
          },
        ),
      );
      if (!mounted) {
        return;
      }
      await _shareTextViaSystemSheet(
        text: shareUrl,
        title: detail.post.title,
        subject: detail.post.title,
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

  Future<void> _reportPost() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final detail = _detail;
    if (detail == null || _isSubmittingReport) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/posts/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    final report = await showModalBottomSheet<_StoryReportFormResult>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF23140A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return const _StoryReportSheet();
      },
    );
    if (report == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmittingReport = true;
    });

    try {
      final result = await _postApi.reportPost(
        detail.post.id,
        reason: report.reason,
        details: report.details,
      );
      unawaited(_trackPostReport(detail.post, report.reason));
      if (!mounted) {
        return;
      }
      final message = result.autoHidden
          ? l10n.storyReportAutoHidden
          : l10n.storyReportSubmitted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReport = false;
        });
      }
    }
  }

  Future<void> _trackPostEngagement(
    PostVm post,
    String eventType, {
    Map<String, Object?> metadata = const {},
  }) async {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    try {
      await _feedApi.trackFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: eventType,
          surface: 'content',
          tab: 'details',
          blockId: 'post:$postId:details',
          blockType: 'post_card',
          postId: postId,
          communityId: _trimmedOrNull(post.communityId),
          occurredAt: DateTime.now().toUtc(),
          metadata: {
            'source': 'post_details',
            'action': eventType,
            'entityType': 'post',
            'entityId': postId,
            'categorySlug': post.category.trim().toLowerCase(),
            if (_trimmedOrNull(post.postProfileKey) != null)
              'postProfileKey': post.postProfileKey!.trim(),
            if (_trimmedOrNull(post.communityId) != null)
              'communityId': post.communityId!.trim(),
            if (_trimmedOrNull(post.placeCountryCode) != null)
              'countryCode': post.placeCountryCode!.trim().toUpperCase(),
            if (_trimmedOrNull(post.placeCityId) != null)
              'cityId': post.placeCityId!.trim(),
            if (post.tags.isNotEmpty) 'tags': post.tags,
            ...metadata,
          },
        ),
      ]);
    } catch (_) {
      // Feed analytics must not block post engagement actions.
    }
  }

  Future<void> _trackPostReport(PostVm post, String reason) async {
    final postId = post.id.trim();
    if (postId.isEmpty) {
      return;
    }
    try {
      await _feedApi.trackFeedEvents([
        FeedEventRequest(
          eventId: _uuidV4(),
          eventType: FeedEventTypes.report,
          surface: 'content',
          tab: 'details',
          blockId: 'post:$postId:details',
          blockType: 'post_card',
          postId: postId,
          communityId: _trimmedOrNull(post.communityId),
          occurredAt: DateTime.now().toUtc(),
          metadata: {
            'source': 'post_details',
            'action': FeedEventTypes.report,
            'entityType': 'post',
            'entityId': postId,
            'feedbackType': FeedEventTypes.report,
            'reason': reason.trim(),
            'categorySlug': post.category.trim().toLowerCase(),
            if (_trimmedOrNull(post.postProfileKey) != null)
              'postProfileKey': post.postProfileKey!.trim(),
            if (_trimmedOrNull(post.communityId) != null)
              'communityId': post.communityId!.trim(),
            if (_trimmedOrNull(post.placeCountryCode) != null)
              'countryCode': post.placeCountryCode!.trim().toUpperCase(),
            if (_trimmedOrNull(post.placeCityId) != null)
              'cityId': post.placeCityId!.trim(),
            if (post.tags.isNotEmpty) 'tags': post.tags,
          },
        ),
      ]);
    } catch (_) {
      // Feed analytics must not block moderation reports.
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
      context.push('/login?from=/posts/${Uri.encodeComponent(widget.slug)}');
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
    if (detail == null ||
        !detail.post.isPublished ||
        body.isEmpty ||
        _isSubmittingComment) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/posts/${Uri.encodeComponent(widget.slug)}');
      return;
    }
    if (editingCommentId == null && _commentLockEndsAt(currentUserId) != null) {
      await showErrorDialog(
        context,
        title: l10n.error,
        message: l10n.storyCommentRateLimit,
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = editingCommentId == null
          ? await _postApi.createComment(detail.post.id, body)
          : await _postApi.updateComment(
              detail.post.id,
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
          ? detail.post.copyWith(
              stats: detail.post.stats.copyWith(
                comments: detail.post.stats.comments + 1,
              ),
            )
          : detail.post;
      setState(() {
        _editingCommentId = null;
        _detail = detail.copyWith(post: nextStory, comments: nextComments);
      });
      if (editingCommentId == null) {
        unawaited(
          _trackPostEngagement(
            nextStory,
            FeedEventTypes.comment,
            metadata: {
              'engagementType': FeedEventTypes.comment,
              'commentId': result.id,
            },
          ),
        );
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

  Future<void> _toggleCommentLike(PostCommentVm comment) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final detail = _detail;
    if (detail == null) {
      return;
    }
    if (auth.state != AuthState.authenticated) {
      context.push('/login?from=/posts/${Uri.encodeComponent(widget.slug)}');
      return;
    }

    try {
      final result = comment.likedByMe
          ? await _postApi.unlikeComment(detail.post.id, comment.id)
          : await _postApi.likeComment(detail.post.id, comment.id);
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

  Future<void> _shareComment(PostCommentVm comment) async {
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final shareUrl = comment.shareUrl.trim().isNotEmpty
        ? comment.shareUrl.trim()
        : '${detail.post.shareUrl}?comment=${comment.id}';
    try {
      await _shareTextViaSystemSheet(
        text: shareUrl,
        title: detail.post.title,
        subject: detail.post.title,
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

  Future<void> _openStoryImages(
    List<StoryImagePayload> images,
    int initialIndex,
  ) async {
    final preferPrivateContent = !(_detail?.post.isPublished ?? true);
    final visibleImages = images
        .where((image) {
          final fileId = image.fileId.trim();
          if (fileId.isEmpty) {
            return false;
          }
          return preferPrivateContent ||
              resolvePublicFileContentUrl(fileId) != null;
        })
        .toList(growable: false);
    if (visibleImages.isEmpty || !mounted) {
      return;
    }
    final page = initialIndex.clamp(0, visibleImages.length - 1).toInt();
    await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _StoryImageGalleryViewer(
          images: visibleImages,
          initialIndex: page,
          preferPrivateContent: preferPrivateContent,
          fileApi: _fileApi,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _startEditingComment(PostCommentVm comment) {
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

  PostCommentVm? _latestRecentOwnComment(String currentUserId) {
    final normalizedUserId = currentUserId.trim();
    if (normalizedUserId.isEmpty) {
      return null;
    }
    final detail = _detail;
    if (detail == null) {
      return null;
    }

    final now = DateTime.now();
    PostCommentVm? latest;
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
    )!.storyCommentCooldownUntil(formattedTime);
  }

  Future<void> _deleteComment(PostCommentVm comment) async {
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
      await _postApi.deleteComment(detail.post.id, comment.id);
      if (!mounted) {
        return;
      }
      final nextComments = detail.comments
          .where((item) => item.id != comment.id)
          .toList(growable: false);
      final nextStory = detail.post.copyWith(
        stats: detail.post.stats.copyWith(
          comments: (detail.post.stats.comments - 1).clamp(0, 1 << 31),
        ),
      );
      setState(() {
        if (_editingCommentId == comment.id) {
          _editingCommentId = null;
          _commentController.clear();
        }
        _detail = detail.copyWith(post: nextStory, comments: nextComments);
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
    final story = _detail?.post;
    if (story == null) {
      return;
    }
    final result = await context.push<Object?>(
      '/posts/${story.id}/edit',
      extra: story,
    );
    if (result is! PostVm || !mounted) {
      return;
    }
    final refreshed = result;
    if (mounted) {
      setState(() {
        _detail = _detail?.copyWith(post: refreshed);
      });
      await _loadDetail(silent: true);
      if (!mounted) {
        return;
      }
      context.pop(true);
    }
  }

  Future<void> _deletePost() async {
    final l10n = AppLocalizations.of(context)!;
    final story = _detail?.post;
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
      await _postApi.deletePost(story.id);
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
    final story = detail?.post;
    final isAuthor = story?.isOwnedBy(currentUserId) ?? false;

    return Scaffold(
      backgroundColor: StoryPalette.backgroundDeep,
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
                    final showSocialSections = currentDetail.post.isPublished;
                    final commentLockEndsAt =
                        showSocialSections && _editingCommentId == null
                        ? _commentLockEndsAt(currentUserId)
                        : null;
                    final isCommentComposerLocked = commentLockEndsAt != null;
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
                            onShareTap: _sharePost,
                            onOpenImages: _openStoryImages,
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
                                    onDeleteTap: _deletePost,
                                    onReportTap: showSocialSections && !isAuthor
                                        ? _reportPost
                                        : null,
                                    isReporting: _isSubmittingReport,
                                    onViewsTap: null,
                                    onLikesTap: _toggleLike,
                                    onCommentsTap: showSocialSections
                                        ? () => _scrollToComments(
                                            focusComposer: true,
                                          )
                                        : null,
                                    onSharesTap: _sharePost,
                                  ),
                                ),
                                SizedBox(height: adaptive.scale(18)),
                                _StoryArticle(
                                  story: story,
                                  onOpenImages: _openStoryImages,
                                ),
                                if (showSocialSections) ...[
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
                                        '/posts/${Uri.encodeComponent(story.slug)}',
                                        extra: story,
                                      );
                                    },
                                  ),
                                ],
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

const _storyReportReasons = <String>[
  'SPAM',
  'HARASSMENT',
  'HATE',
  'SEXUAL_CONTENT',
  'VIOLENCE',
  'MISINFORMATION',
  'ILLEGAL',
  'OTHER',
];

class _StoryReportFormResult {
  const _StoryReportFormResult({required this.reason, required this.details});

  final String reason;
  final String details;
}

class _StoryReportSheet extends StatefulWidget {
  const _StoryReportSheet();

  @override
  State<_StoryReportSheet> createState() => _StoryReportSheetState();
}

class _StoryReportSheetState extends State<_StoryReportSheet> {
  final _detailsController = TextEditingController();
  String _reason = _storyReportReasons.first;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adaptive = StoryAdaptive.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          adaptive.scale(18),
          adaptive.scale(18),
          adaptive.scale(18),
          bottomInset + adaptive.scale(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: adaptive.scale(42),
                height: adaptive.scale(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: adaptive.scale(18)),
            Text(
              l10n.storyReportTitle,
              style: TextStyle(
                color: StoryPalette.text,
                fontSize: adaptive.scale(20),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: adaptive.scale(8)),
            Text(
              l10n.storyReportSubtitle,
              style: TextStyle(
                color: StoryPalette.textSoft,
                fontSize: adaptive.scale(13),
                height: 1.35,
              ),
            ),
            SizedBox(height: adaptive.scale(14)),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _reason = value;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reason in _storyReportReasons)
                    RadioListTile<String>(
                      value: reason,
                      activeColor: AppColors.accent,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _storyReportReasonLabel(l10n, reason),
                        style: TextStyle(
                          color: StoryPalette.text,
                          fontSize: adaptive.scale(13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: adaptive.scale(8)),
            TextField(
              key: const ValueKey('story-report-details-field'),
              controller: _detailsController,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: StoryPalette.text),
              decoration: InputDecoration(
                labelText: l10n.storyReportDetailsLabel,
                hintText: l10n.storyReportDetailsHint,
                labelStyle: const TextStyle(color: StoryPalette.textMuted),
                hintStyle: const TextStyle(color: StoryPalette.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(adaptive.radius(18)),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(adaptive.radius(18)),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            SizedBox(height: adaptive.scale(14)),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                SizedBox(width: adaptive.scale(10)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _StoryReportFormResult(
                          reason: _reason,
                          details: _detailsController.text.trim(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          adaptive.radius(18),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(l10n.storyReportSubmitAction),
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

String _storyReportReasonLabel(AppLocalizations l10n, String reason) {
  switch (reason) {
    case 'SPAM':
      return l10n.storyReportReasonSpam;
    case 'HARASSMENT':
      return l10n.storyReportReasonHarassment;
    case 'HATE':
      return l10n.storyReportReasonHate;
    case 'SEXUAL_CONTENT':
      return l10n.storyReportReasonSexualContent;
    case 'VIOLENCE':
      return l10n.storyReportReasonViolence;
    case 'MISINFORMATION':
      return l10n.storyReportReasonMisinformation;
    case 'ILLEGAL':
      return l10n.storyReportReasonIllegal;
    case 'OTHER':
    default:
      return l10n.storyReportReasonOther;
  }
}

class _StoryHero extends StatelessWidget {
  const _StoryHero({
    required this.story,
    required this.titleLabel,
    required this.isSharing,
    required this.onBackTap,
    required this.onShareTap,
    required this.onOpenImages,
  });

  final PostVm story;
  final String titleLabel;
  final bool isSharing;
  final VoidCallback onBackTap;
  final VoidCallback onShareTap;
  final StoryImageOpenCallback onOpenImages;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    final heroHeight = adaptive.scale(430, minFactor: 0.82, maxFactor: 1.02);
    final topInset = MediaQuery.paddingOf(context).top;
    final coverFileId = (story.coverFileId ?? '').trim();
    final canOpenCover = resolvePublicFileContentUrl(coverFileId) != null;

    return Stack(
      children: [
        Semantics(
          button: canOpenCover,
          image: true,
          child: GestureDetector(
            onTap: canOpenCover
                ? () =>
                      onOpenImages([StoryImagePayload(fileId: coverFileId)], 0)
                : null,
            behavior: canOpenCover ? HitTestBehavior.opaque : null,
            child: Container(
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
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
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
                semanticLabel: AppLocalizations.of(
                  context,
                )!.storyCommentShareAction,
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
                  letterSpacing: 0,
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
  const _OverlayIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      child: GestureDetector(
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
          color: accent
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.9),
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
    required this.onReportTap,
    required this.isReporting,
    required this.onViewsTap,
    required this.onLikesTap,
    required this.onCommentsTap,
    required this.onSharesTap,
  });

  final PostVm story;
  final UserProfileVm? authorProfile;
  final bool isAuthor;
  final bool isFollowing;
  final VoidCallback onProfileTap;
  final VoidCallback onFollowTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onReportTap;
  final bool isReporting;
  final VoidCallback? onViewsTap;
  final VoidCallback? onLikesTap;
  final VoidCallback? onCommentsTap;
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
                      foregroundColor: AppColors.destructive,
                    ),
                    child: Text(l10n.storyDeleteAction),
                  ),
                ),
              ],
            )
          else if (authorProfile != null || onReportTap != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: adaptive.scale(10),
                runSpacing: adaptive.scale(8),
                children: [
                  if (authorProfile != null)
                    OutlinedButton(
                      onPressed: isFollowing ? null : onFollowTap,
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
                        authorProfile!.isFollowedByMe
                            ? l10n.storyFollowingAction
                            : (isFollowing
                                  ? l10n.storyFollowingAction
                                  : l10n.storyFollowAction),
                      ),
                    ),
                  if (onReportTap != null)
                    OutlinedButton.icon(
                      onPressed: isReporting ? null : onReportTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: BorderSide(
                          color: AppColors.destructive.withValues(alpha: 0.26),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            adaptive.radius(999),
                          ),
                        ),
                      ),
                      icon: Icon(Icons.flag_outlined, size: adaptive.scale(16)),
                      label: Text(
                        isReporting
                            ? l10n.storyReportSending
                            : l10n.storyReportAction,
                      ),
                    ),
                ],
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
  const _StoryArticle({required this.story, required this.onOpenImages});

  final PostVm story;
  final StoryImageOpenCallback onOpenImages;

  @override
  Widget build(BuildContext context) {
    final adaptive = StoryAdaptive.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryDocumentRenderer(
          story: story,
          onOpenImages: onOpenImages,
          onOpenRoute: (routeId) =>
              context.push('/user-routes/${Uri.encodeComponent(routeId)}'),
        ),
        if (story.tags.isNotEmpty) ...[
          SizedBox(height: adaptive.scale(24)),
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
              onPressed: isSubmitting || (!enabled && !isEditing)
                  ? null
                  : onSubmit,
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

  final List<PostCommentVm> comments;
  final GlobalKey Function(String commentId) commentKeyForId;
  final ValueChanged<PostCommentVm> onEditComment;
  final ValueChanged<PostCommentVm> onDeleteComment;
  final ValueChanged<PostCommentVm> onLikeComment;
  final ValueChanged<PostCommentVm> onShareComment;

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
                  onEdit: comment.editable
                      ? () => onEditComment(comment)
                      : null,
                  onDelete: comment.deletable
                      ? () => onDeleteComment(comment)
                      : null,
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

  final PostCommentVm comment;
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

const double _storyImageViewerHorizontalSwipeDistance = 72;
const double _storyImageViewerDismissSwipeDistance = 96;
const double _storyImageViewerSwipeAxisDominance = 1.2;
const double _storyImageViewerTransitionSlideDistance = 0.16;
const Duration _storyImageViewerTransitionDuration = Duration(
  milliseconds: 320,
);
const Duration _storyImageViewerReverseTransitionDuration = Duration(
  milliseconds: 260,
);

class _StoryImageGalleryViewer extends StatefulWidget {
  const _StoryImageGalleryViewer({
    required this.images,
    required this.initialIndex,
    required this.preferPrivateContent,
    required this.fileApi,
  }) : assert(images.length > 0);

  final List<StoryImagePayload> images;
  final int initialIndex;
  final bool preferPrivateContent;
  final FileApi fileApi;

  @override
  State<_StoryImageGalleryViewer> createState() =>
      _StoryImageGalleryViewerState();
}

class _StoryImageGalleryViewerState extends State<_StoryImageGalleryViewer> {
  late int _currentIndex;
  final Set<int> _activeSwipePointers = <int>{};
  Offset? _swipeStartPosition;
  Offset? _swipeLatestPosition;
  bool _ignoreSwipeUntilPointersUp = false;
  int _transitionDirection = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex
        .clamp(0, widget.images.length - 1)
        .toInt();
  }

  bool get _hasPrevious => _currentIndex > 0;

  bool get _hasNext => _currentIndex < widget.images.length - 1;

  void _showPreviousImage() {
    if (!_hasPrevious) {
      return;
    }
    setState(() {
      _transitionDirection = -1;
      _currentIndex -= 1;
    });
  }

  void _showNextImage() {
    if (!_hasNext) {
      return;
    }
    setState(() {
      _transitionDirection = 1;
      _currentIndex += 1;
    });
  }

  void _closeViewer() {
    Navigator.of(context).pop(_currentIndex);
  }

  void _startSwipeTracking(PointerDownEvent event) {
    _activeSwipePointers.add(event.pointer);
    if (_activeSwipePointers.length > 1) {
      _ignoreSwipeUntilPointersUp = true;
      _swipeStartPosition = null;
      _swipeLatestPosition = null;
      return;
    }
    _ignoreSwipeUntilPointersUp = false;
    _swipeStartPosition = event.position;
    _swipeLatestPosition = event.position;
  }

  void _trackSwipeMovement(PointerMoveEvent event) {
    if (_ignoreSwipeUntilPointersUp ||
        !_activeSwipePointers.contains(event.pointer)) {
      return;
    }
    _swipeLatestPosition = event.position;
  }

  void _completeSwipeTracking(PointerUpEvent event) {
    final start = _swipeStartPosition;
    final end = _swipeLatestPosition ?? event.position;
    final canHandleSwipe =
        !_ignoreSwipeUntilPointersUp &&
        start != null &&
        _activeSwipePointers.length == 1 &&
        _activeSwipePointers.contains(event.pointer);
    _activeSwipePointers.remove(event.pointer);
    if (_activeSwipePointers.isEmpty) {
      _ignoreSwipeUntilPointersUp = false;
      _swipeStartPosition = null;
      _swipeLatestPosition = null;
    }
    if (canHandleSwipe) {
      _handleSwipe(end - start);
    }
  }

  void _cancelSwipeTracking(PointerCancelEvent event) {
    _activeSwipePointers.remove(event.pointer);
    if (_activeSwipePointers.isEmpty) {
      _ignoreSwipeUntilPointersUp = false;
      _swipeStartPosition = null;
      _swipeLatestPosition = null;
    }
  }

  void _handleSwipe(Offset delta) {
    final horizontalDistance = delta.dx.abs();
    final verticalDistance = delta.dy.abs();
    if (delta.dy > _storyImageViewerDismissSwipeDistance &&
        verticalDistance >
            horizontalDistance * _storyImageViewerSwipeAxisDominance) {
      _closeViewer();
      return;
    }
    if (horizontalDistance < _storyImageViewerHorizontalSwipeDistance ||
        horizontalDistance <
            verticalDistance * _storyImageViewerSwipeAxisDominance) {
      return;
    }
    if (delta.dx < 0) {
      _showNextImage();
    } else {
      _showPreviousImage();
    }
  }

  Widget _buildImageTransition(
    Widget child,
    Animation<double> animation, {
    required bool isCurrentChild,
  }) {
    final slideDirection = _transitionDirection == 0
        ? 0.0
        : _transitionDirection.toDouble();
    final slideOffset = isCurrentChild ? slideDirection : -slideDirection;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(
            slideOffset * _storyImageViewerTransitionSlideDistance,
            0,
          ),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_currentIndex];
    final localizations = MaterialLocalizations.of(context);
    final currentChildKey = ValueKey<String>(
      'story-viewer-page-${image.fileId}-$_currentIndex',
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _startSwipeTracking,
          onPointerMove: _trackSwipeMovement,
          onPointerUp: _completeSwipeTracking,
          onPointerCancel: _cancelSwipeTracking,
          child: SizedBox.expand(
            child: ColoredBox(
              color: Colors.black,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: _storyImageViewerTransitionDuration,
                        reverseDuration:
                            _storyImageViewerReverseTransitionDuration,
                        switchInCurve: Curves.easeOutQuart,
                        switchOutCurve: Curves.easeInQuart,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          return _buildImageTransition(
                            child,
                            animation,
                            isCurrentChild: child.key == currentChildKey,
                          );
                        },
                        child: _StoryImageViewerPage(
                          key: currentChildKey,
                          image: image,
                          preferPrivateContent: widget.preferPrivateContent,
                          fileApi: widget.fileApi,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: _StoryImageViewerIconButton(
                        icon: Icons.close_rounded,
                        tooltip: localizations.closeButtonTooltip,
                        onTap: _closeViewer,
                      ),
                    ),
                    if (widget.images.length > 1)
                      PositionedDirectional(
                        top: 15,
                        start: 76,
                        end: 76,
                        child: Center(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${widget.images.length}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_hasPrevious)
                      PositionedDirectional(
                        start: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _StoryImageViewerIconButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: localizations.previousPageTooltip,
                            onTap: _showPreviousImage,
                          ),
                        ),
                      ),
                    if (_hasNext)
                      PositionedDirectional(
                        end: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _StoryImageViewerIconButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: localizations.nextPageTooltip,
                            onTap: _showNextImage,
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
    );
  }
}

class _StoryImageViewerPage extends StatelessWidget {
  const _StoryImageViewerPage({
    super.key,
    required this.image,
    required this.preferPrivateContent,
    required this.fileApi,
  });

  final StoryImagePayload image;
  final bool preferPrivateContent;
  final FileApi fileApi;

  @override
  Widget build(BuildContext context) {
    final url = resolvePublicFileContentUrl(image.fileId);
    final view = MediaQuery.of(context);
    final cacheWidth = _storyFullscreenImageTargetWidth(
      context,
      view.size.width,
      minWidth: 900,
      maxWidth: 2200,
    );
    if (preferPrivateContent) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: _StoryDraftImage(
            publicUrl: url,
            fileApi: fileApi,
            image: image,
            cacheWidth: cacheWidth,
          ),
        ),
      );
    }
    if (url != null) {
      return InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: _StoryPublicImage(
            url: url,
            image: image,
            cacheWidth: cacheWidth,
          ),
        ),
      );
    }
    return const _StoryImageViewerPlaceholder();
  }
}

class _StoryDraftImage extends StatefulWidget {
  const _StoryDraftImage({
    required this.publicUrl,
    required this.fileApi,
    required this.image,
    required this.cacheWidth,
  });

  final String? publicUrl;
  final FileApi fileApi;
  final StoryImagePayload image;
  final int cacheWidth;

  @override
  State<_StoryDraftImage> createState() => _StoryDraftImageState();
}

class _StoryDraftImageState extends State<_StoryDraftImage> {
  bool _usePrivateFallback = false;

  void _showPrivateFallback() {
    if (!mounted || _usePrivateFallback) {
      return;
    }
    setState(() => _usePrivateFallback = true);
  }

  @override
  void didUpdateWidget(covariant _StoryDraftImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.fileId != widget.image.fileId ||
        oldWidget.publicUrl != widget.publicUrl ||
        oldWidget.fileApi != widget.fileApi) {
      _usePrivateFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicUrl = widget.publicUrl;
    if (!_usePrivateFallback && publicUrl != null) {
      return Image.network(
        publicUrl,
        fit: BoxFit.contain,
        cacheWidth: widget.cacheWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const _StoryImageViewerLoading();
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPrivateFallback();
          });
          return const _StoryImageViewerLoading();
        },
      );
    }

    return _StoryPrivateImage(
      fileApi: widget.fileApi,
      image: widget.image,
      cacheWidth: widget.cacheWidth,
      publicUrl: publicUrl,
    );
  }
}

class _StoryPublicImage extends StatelessWidget {
  const _StoryPublicImage({
    required this.url,
    required this.image,
    required this.cacheWidth,
  });

  final String url;
  final StoryImagePayload image;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const _StoryImageViewerLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        return const _StoryImageViewerPlaceholder();
      },
    );
  }
}

class _StoryPrivateImage extends StatefulWidget {
  const _StoryPrivateImage({
    required this.fileApi,
    required this.image,
    required this.cacheWidth,
    required this.publicUrl,
  });

  final FileApi fileApi;
  final StoryImagePayload image;
  final int cacheWidth;
  final String? publicUrl;

  @override
  State<_StoryPrivateImage> createState() => _StoryPrivateImageState();
}

class _StoryPrivateImageState extends State<_StoryPrivateImage> {
  late Future<FileContentVm> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = widget.fileApi.downloadContent(widget.image.fileId);
  }

  @override
  void didUpdateWidget(covariant _StoryPrivateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.fileId != widget.image.fileId ||
        oldWidget.fileApi != widget.fileApi) {
      _contentFuture = widget.fileApi.downloadContent(widget.image.fileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FileContentVm>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StoryImageViewerLoading();
        }
        final content = snapshot.data;
        if (snapshot.hasError || content == null || content.bytes.isEmpty) {
          final publicUrl = widget.publicUrl;
          if (publicUrl != null) {
            return _StoryPublicImage(
              url: publicUrl,
              image: widget.image,
              cacheWidth: widget.cacheWidth,
            );
          }
          return const _StoryImageViewerPlaceholder();
        }

        return Image.memory(
          content.bytes,
          fit: BoxFit.contain,
          cacheWidth: widget.cacheWidth,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const _StoryImageViewerPlaceholder();
          },
        );
      },
    );
  }
}

int _storyFullscreenImageTargetWidth(
  BuildContext context,
  double displayWidth, {
  required int minWidth,
  required int maxWidth,
}) {
  final normalizedWidth = displayWidth.isFinite && displayWidth > 0
      ? displayWidth
      : MediaQuery.sizeOf(context).width;
  final targetWidth = normalizedWidth * MediaQuery.devicePixelRatioOf(context);
  return targetWidth.clamp(minWidth, maxWidth).round();
}

class _StoryImageViewerIconButton extends StatelessWidget {
  const _StoryImageViewerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.54),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _StoryImageViewerLoading extends StatelessWidget {
  const _StoryImageViewerLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _StoryImageViewerPlaceholder extends StatelessWidget {
  const _StoryImageViewerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: AppColors.textCaption,
        size: 54,
      ),
    );
  }
}

class _RelatedStoriesSection extends StatelessWidget {
  const _RelatedStoriesSection({
    required this.stories,
    required this.onStoryTap,
  });

  final List<PostVm> stories;
  final ValueChanged<PostVm> onStoryTap;

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
              onTap: () => context.go('/posts'),
              child: Text(
                l10n.storyViewAll,
                style: TextStyle(
                  color: AppColors.accent,
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
                Builder(
                  builder: (context) {
                    final state = resolvePostEntryState(story);
                    return GestureDetector(
                      onTap: state.disablesEntry
                          ? null
                          : () => onStoryTap(story),
                      child: Container(
                        margin: EdgeInsets.only(bottom: adaptive.scale(14)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            adaptive.radius(14),
                          ),
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
                                  if (state.disablesEntry)
                                    Positioned.fill(
                                      child: ColoredBox(
                                        color: Colors.black.withValues(
                                          alpha: 0.38,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    left: adaptive.scale(10),
                                    top: adaptive.scale(10),
                                    child: _HeroChip(
                                      label:
                                          (story.placeName ?? '').trim().isEmpty
                                          ? formatStoryCategory(
                                              l10n,
                                              story.category,
                                            )
                                          : story.placeName!.trim(),
                                    ),
                                  ),
                                  Positioned(
                                    left: adaptive.scale(10),
                                    bottom: adaptive.scale(10),
                                    child: StoryStateAffordance.fromPost(
                                      story,
                                      compact: true,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
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
                    );
                  },
                ),
              ],
            ],
          ),
      ],
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(hexByte).join();
  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20),
  ].join('-');
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
    final adaptive = StoryAdaptive.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          adaptive.scale(24, minFactor: 0.86, maxFactor: 1.04),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.accent,
              size: adaptive.scale(42, minFactor: 0.86, maxFactor: 1.04),
            ),
            SizedBox(height: adaptive.scale(14, minFactor: 0.86)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: StoryPalette.textSoft),
            ),
            SizedBox(height: adaptive.scale(18, minFactor: 0.86)),
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
