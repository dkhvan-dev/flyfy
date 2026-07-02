import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/file_api.dart';
import '../../../core/network/chat_ws_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/session_provider.dart';
import '../data/help_center_api.dart';

const _maxSupportAttachmentBytes = 25 * 1024 * 1024;
const _supportTicketDetailRefreshInterval = Duration(seconds: 8);

class SupportPickedAttachment {
  const SupportPickedAttachment({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'attachment' : trimmed;
  }
}

String? supportContentTypeForFileName(String fileName) {
  final lower = fileName.trim().toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.txt')) return 'text/plain';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  return null;
}

bool _supportIntentCreatesOnReply(SupportChatOpenIntent intent) {
  final source = intent.source.trim().toLowerCase();
  if (source != HelpCenterSurface.helpCenter.wireValue) return false;
  final intentValue = intent.intent.trim().toLowerCase();
  return intent.context.containsKey('failed_search') ||
      intentValue.startsWith('failed_search:') ||
      intentValue == 'help_center_no_results';
}

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key, this.api});

  final HelpCenterApi? api;

  @override
  Widget build(BuildContext context) => SupportTicketDetailScreen(api: api);
}

class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({
    super.key,
    this.ticketId,
    this.initialIntent,
    this.fileApi,
    this.attachmentPicker,
    this.api,
  });

  final String? ticketId;
  final SupportChatOpenIntent? initialIntent;
  final FileApi? fileApi;
  final Future<List<SupportPickedAttachment>> Function()? attachmentPicker;
  final HelpCenterApi? api;

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  late final HelpCenterApi _api = widget.api ?? HelpCenterApi();
  late final FileApi _fileApi = widget.fileApi ?? FileApi();
  final _replyController = TextEditingController();
  final _csatCommentController = TextEditingController();
  final _scrollController = ScrollController();

  SupportTicketDetailVm? _detail;
  var _isLoading = true;
  var _hasError = false;
  var _isSending = false;
  var _isClosing = false;
  var _isSubmittingCSAT = false;
  var _isRefreshingDetail = false;
  var _hasSubmittedCSAT = false;
  int? _selectedCSATRating;
  var _didRequestInitialDetail = false;
  var _isPickingAttachment = false;
  var _outboxMessages = const <_SupportOutboxMessage>[];
  var _pendingAttachments = const <SupportPickedAttachment>[];
  var _realtimeEvents = const <SupportTicketEventVm>[];
  Timer? _detailRefreshTimer;
  StreamSubscription<ChatEvent>? _supportRealtimeSubscription;
  ChatProvider? _chatProvider;
  SupportChatOpenIntent? _deferredInitialIntent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToSupportRealtime();
    if (_didRequestInitialDetail) return;
    _didRequestInitialDetail = true;
    unawaited(_loadDetail());
  }

  @override
  void dispose() {
    _detailRefreshTimer?.cancel();
    unawaited(_supportRealtimeSubscription?.cancel());
    _replyController.dispose();
    _csatCommentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToSupportRealtime() {
    final provider = _maybeReadChatProvider(context);
    if (identical(provider, _chatProvider)) return;

    unawaited(_supportRealtimeSubscription?.cancel());
    _supportRealtimeSubscription = null;
    _chatProvider = provider;

    if (provider == null) return;

    _supportRealtimeSubscription = provider.realtimeEvents.listen(
      _handleSupportRealtimeEvent,
    );
    provider.connectWebSocket();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final detail = await _fetchSupportDetail(processInitialIntent: true);
      if (!mounted) return;
      final mergedDetail = _detailWithMergedRealtimeEvents(detail);
      setState(() {
        _detail = mergedDetail;
        _hasSubmittedCSAT = supportTicketHasSubmittedCSAT(mergedDetail);
        _selectedCSATRating = null;
        _outboxMessages = _supportReconciledOutboxMessages(
          _outboxMessages,
          mergedDetail.events,
        );
        _isLoading = false;
      });
      _startDetailRefreshPolling();
      _scheduleScrollToLatest();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<SupportTicketDetailVm> _fetchSupportDetail({
    required bool processInitialIntent,
  }) {
    final cleanTicketId = widget.ticketId?.trim() ?? '';
    if (cleanTicketId.isNotEmpty) {
      return _api.getSupportTicket(cleanTicketId);
    }
    return _openSupportConversation(processInitialIntent: processInitialIntent);
  }

  Future<SupportTicketDetailVm> _openSupportConversation({
    required bool processInitialIntent,
  }) async {
    final locale = Localizations.localeOf(context).languageCode;
    final intent = widget.initialIntent;
    if (processInitialIntent && intent != null) {
      if (_supportIntentCreatesOnReply(intent)) {
        _deferredInitialIntent = intent;
      } else {
        await _createTicketFromIntent(intent, locale: locale);
      }
    }
    return _api.getSupportConversation(locale: locale);
  }

  void _startDetailRefreshPolling() {
    _detailRefreshTimer ??= Timer.periodic(
      _supportTicketDetailRefreshInterval,
      (_) => unawaited(_refreshDetailInBackground()),
    );
  }

  Future<void> _refreshDetailInBackground() async {
    if (_isLoading ||
        _isRefreshingDetail ||
        _isSending ||
        _isClosing ||
        _isSubmittingCSAT) {
      return;
    }
    final previousLatestEventKey = _supportLatestEventKey(
      _detail?.events ?? const [],
    );
    _isRefreshingDetail = true;
    try {
      final detail = await _fetchSupportDetail(processInitialIntent: false);
      if (!mounted) return;
      final mergedDetail = _detailWithMergedRealtimeEvents(detail);
      final nextLatestEventKey = _supportLatestEventKey(mergedDetail.events);
      final hasNewLatestEvent =
          nextLatestEventKey.isNotEmpty &&
          nextLatestEventKey != previousLatestEventKey;
      setState(() {
        _detail = mergedDetail;
        _hasSubmittedCSAT = supportTicketHasSubmittedCSAT(mergedDetail);
        _outboxMessages = _supportReconciledOutboxMessages(
          _outboxMessages,
          mergedDetail.events,
        );
        if (_hasSubmittedCSAT) {
          _selectedCSATRating = null;
        }
      });
      if (hasNewLatestEvent) {
        _scheduleScrollToLatest(animated: true);
      }
    } catch (_) {
      // Background refresh is best effort; the next poll or manual retry will sync.
    } finally {
      _isRefreshingDetail = false;
    }
  }

  Future<SupportTicketVm> _createTicketFromIntent(
    SupportChatOpenIntent intent, {
    required String locale,
  }) {
    return _api.createSupportTicket(
      category: intent.category,
      source: intent.source,
      locale: locale,
      context: intent.context,
      idempotencyKey: HelpCenterApi.supportTicketIdempotencyKey(
        source: intent.source,
        intent: intent.intent,
        context: intent.context,
      ),
    );
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    final attachments = List<SupportPickedAttachment>.of(_pendingAttachments);
    if ((message.isEmpty && attachments.isEmpty) || _isSending) return;
    final outboxMessage = _SupportOutboxMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ticketId: _currentTicketId(),
      message: message.isEmpty
          ? _attachmentFallbackMessage(attachments)
          : message,
      actorNickname: _currentUserNickname(),
      attachments: attachments,
      status: _SupportOutboxStatus.sending,
      createdAt: DateTime.now().toUtc(),
    );
    if (outboxMessage.ticketId.isEmpty) return;

    setState(() {
      _outboxMessages = [..._outboxMessages, outboxMessage];
      _replyController.clear();
      _pendingAttachments = const [];
    });
    _scheduleScrollToLatest(animated: true);
    await _deliverOutboxReply(outboxMessage.id);
  }

  void _handleSupportRealtimeEvent(ChatEvent event) {
    if (!mounted || event.type != 'message_sent') return;

    final detail = _detail;
    if (detail == null) return;

    final conversationId = detail.ticket.conversationId.trim();
    if (conversationId.isEmpty ||
        event.conversationId.trim() != conversationId) {
      return;
    }

    final realtimeEvent = _supportRealtimeEventFromChatEvent(
      event,
      ticketId: detail.ticket.id,
      currentUserId: _currentUserId(),
    );
    if (realtimeEvent == null ||
        _supportEventExists(detail.events, realtimeEvent) ||
        _supportEventExists(_realtimeEvents, realtimeEvent)) {
      return;
    }

    final nextRealtimeEvents = [..._realtimeEvents, realtimeEvent];
    final nextDetail = _detailWithMergedRealtimeEvents(
      detail,
      realtimeEvents: nextRealtimeEvents,
    );
    setState(() {
      _realtimeEvents = nextRealtimeEvents;
      _detail = nextDetail;
      _hasSubmittedCSAT = supportTicketHasSubmittedCSAT(nextDetail);
    });
    _scheduleScrollToLatest(animated: true);
  }

  SupportTicketDetailVm _detailWithMergedRealtimeEvents(
    SupportTicketDetailVm detail, {
    List<SupportTicketEventVm>? realtimeEvents,
  }) {
    final events = realtimeEvents ?? _realtimeEvents;
    if (events.isEmpty) return detail;

    final mergedEvents = [...detail.events];
    for (final event in events) {
      if (_supportEventExists(mergedEvents, event)) continue;
      mergedEvents.add(event);
    }
    mergedEvents.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    return SupportTicketDetailVm(ticket: detail.ticket, events: mergedEvents);
  }

  String _attachmentFallbackMessage(List<SupportPickedAttachment> attachments) {
    if (attachments.length == 1) {
      return attachments.first.displayName;
    }
    return '${attachments.length} attachments';
  }

  Future<void> _pickSupportAttachment() async {
    if (_isPickingAttachment || _isSending) return;
    setState(() => _isPickingAttachment = true);
    try {
      final picker = widget.attachmentPicker ?? _defaultSupportAttachmentPicker;
      final picked = await picker();
      if (!mounted || picked.isEmpty) return;
      for (final attachment in picked) {
        if (attachment.bytes.isEmpty) continue;
        if (attachment.bytes.lengthInBytes > _maxSupportAttachmentBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.chatAttachmentTooLarge,
              ),
            ),
          );
          return;
        }
      }
      final valid = picked
          .where((attachment) => attachment.bytes.isNotEmpty)
          .toList(growable: false);
      if (valid.isEmpty) return;
      setState(() {
        _pendingAttachments = [
          ..._pendingAttachments,
          ...valid,
        ].take(10).toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.chatAttachmentUploadFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  void _removePendingAttachment(int index) {
    if (index < 0 || index >= _pendingAttachments.length) return;
    setState(() {
      _pendingAttachments = [
        for (var i = 0; i < _pendingAttachments.length; i++)
          if (i != index) _pendingAttachments[i],
      ];
    });
  }

  Future<List<SupportPickedAttachment>>
  _defaultSupportAttachmentPicker() async {
    final files = await file_selector.openFiles();
    final attachments = <SupportPickedAttachment>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      var name = file.name.trim();
      if (name.isEmpty) {
        name = 'attachment_${DateTime.now().millisecondsSinceEpoch}.bin';
      }
      attachments.add(
        SupportPickedAttachment(
          name: name,
          contentType:
              supportContentTypeForFileName(name) ??
              file.mimeType ??
              'application/octet-stream',
          bytes: bytes,
        ),
      );
    }
    return attachments;
  }

  Future<void> _retryOutboxReply(String outboxID) async {
    if (_isSending) return;
    setState(() {
      _outboxMessages = _outboxMessages
          .map(
            (message) => message.id == outboxID
                ? message.copyWith(status: _SupportOutboxStatus.sending)
                : message,
          )
          .toList(growable: false);
    });
    await _deliverOutboxReply(outboxID);
  }

  Future<void> _deliverOutboxReply(String outboxID) async {
    final outboxMessage = _outboxMessageByID(outboxID);
    if (outboxMessage == null ||
        outboxMessage.status != _SupportOutboxStatus.sending) {
      return;
    }
    final message = outboxMessage.message.trim();
    if (message.isEmpty || _isSending) return;
    final currentDetail = _detail;
    var ticketId = outboxMessage.ticketId.trim();
    if (ticketId.isEmpty) return;
    final locale = Localizations.localeOf(context).languageCode;

    setState(() => _isSending = true);
    try {
      var fileIds = outboxMessage.fileIds;
      if (fileIds.isEmpty && outboxMessage.attachments.isNotEmpty) {
        fileIds = await _uploadSupportAttachments(outboxMessage.attachments);
        _replaceOutboxMessage(
          outboxID,
          (message) => message.copyWith(fileIds: fileIds),
        );
      }
      final deferredIntent = _deferredInitialIntent;
      if (deferredIntent != null) {
        final createdTicket = await _createTicketFromIntent(
          deferredIntent,
          locale: locale,
        );
        _deferredInitialIntent = null;
        ticketId = createdTicket.id;
        _replaceOutboxMessage(
          outboxID,
          (message) =>
              message.copyWith(ticketId: ticketId, startsNewRequest: true),
        );
      } else if (currentDetail != null &&
          _ticketStartsNewRequest(currentDetail.ticket)) {
        final createdTicket = await _createFollowUpTicket(currentDetail.ticket);
        ticketId = createdTicket.id;
        _replaceOutboxMessage(
          outboxID,
          (message) =>
              message.copyWith(ticketId: ticketId, startsNewRequest: true),
        );
      }
      final ticket = await _api.replyToSupportTicket(
        ticketId: ticketId,
        message: message,
        actorNickname: outboxMessage.actorNickname,
        fileIds: fileIds,
        idempotencyKey:
            'support-reply|$ticketId|${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        final updatedDetail = SupportTicketDetailVm(
          ticket: ticket,
          events: _detail?.events ?? const [],
        );
        _detail = updatedDetail;
        _hasSubmittedCSAT = supportTicketHasSubmittedCSAT(updatedDetail);
        if (_hasSubmittedCSAT) {
          _selectedCSATRating = null;
        }
        _outboxMessages = _outboxMessages
            .map(
              (message) => message.id == outboxID
                  ? message.copyWith(
                      ticketId: ticket.id,
                      status: _SupportOutboxStatus.sent,
                    )
                  : message,
            )
            .toList(growable: false);
        _isSending = false;
      });
      _scheduleScrollToLatest(animated: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _outboxMessages = _outboxMessages
            .map(
              (message) => message.id == outboxID
                  ? message.copyWith(status: _SupportOutboxStatus.failed)
                  : message,
            )
            .toList(growable: false);
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.supportReplyFailed),
        ),
      );
    }
  }

  _SupportOutboxMessage? _outboxMessageByID(String id) {
    for (final message in _outboxMessages) {
      if (message.id == id) return message;
    }
    return null;
  }

  void _replaceOutboxMessage(
    String id,
    _SupportOutboxMessage Function(_SupportOutboxMessage message) replace,
  ) {
    if (!mounted) return;
    setState(() {
      _outboxMessages = _outboxMessages
          .map((message) => message.id == id ? replace(message) : message)
          .toList(growable: false);
    });
  }

  Future<List<String>> _uploadSupportAttachments(
    List<SupportPickedAttachment> attachments,
  ) async {
    final fileIds = <String>[];
    for (final attachment in attachments) {
      final upload = await _fileApi.createChatAttachmentUpload(
        originalName: attachment.displayName,
        contentType: attachment.contentType,
        sizeBytes: attachment.bytes.lengthInBytes,
      );
      await _fileApi.uploadBinary(
        upload: upload,
        bytes: attachment.bytes,
        contentType: attachment.contentType,
      );
      await _fileApi.completeUpload(upload.fileId);
      fileIds.add(upload.fileId);
    }
    return fileIds;
  }

  Future<SupportTicketVm> _createFollowUpTicket(
    SupportTicketVm previousTicket,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final nickname = _currentUserNickname();
    final supportContext = {
      'source_route': '/help/support',
      'previous_ticket_id': previousTicket.id,
      if (nickname.isNotEmpty) 'user_nickname': nickname,
    };
    final followUpSeed = DateTime.now().millisecondsSinceEpoch.toString();
    return _api.createSupportTicket(
      category: SupportTicketCategory.technical,
      source: 'support_follow_up',
      locale: locale,
      context: supportContext,
      idempotencyKey: HelpCenterApi.supportTicketIdempotencyKey(
        source: 'support_follow_up',
        intent: followUpSeed,
        context: supportContext,
      ),
    );
  }

  Future<void> _closeTicket() async {
    if (_isClosing) return;
    final ticketId = _currentTicketId();
    if (ticketId.isEmpty) return;
    setState(() => _isClosing = true);
    try {
      final ticket = await _api.closeSupportTicket(
        ticketId: ticketId,
        reason: 'closed_from_mobile',
      );
      if (!mounted) return;
      setState(() {
        _detail = SupportTicketDetailVm(
          ticket: ticket,
          events: _detail?.events ?? const [],
        );
        _isClosing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isClosing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.contextualHelpLoadFailed),
        ),
      );
    }
  }

  Future<void> _submitCSAT(int rating) async {
    if (_isSubmittingCSAT || rating < 1 || rating > 5) return;
    final ticketId = _currentTicketId();
    if (ticketId.isEmpty) return;
    setState(() => _isSubmittingCSAT = true);
    try {
      await _api.submitSupportTicketCSAT(
        ticketId: ticketId,
        rating: rating,
        comment: _csatCommentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        final detail = _detail;
        if (detail != null) {
          _detail = SupportTicketDetailVm(
            ticket: detail.ticket,
            events: [
              ...detail.events,
              SupportTicketEventVm(
                ticketId: detail.ticket.id,
                actorId: '',
                actorType: 'user',
                eventType: 'ticket_csat_submitted',
                payload: {'rating': rating.toString()},
                createdAt: DateTime.now().toUtc(),
              ),
            ],
          );
        }
        _isSubmittingCSAT = false;
        _hasSubmittedCSAT = true;
        _selectedCSATRating = rating;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmittingCSAT = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.supportTicketCSATFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final colors = AppDesignSystem.colorsFor(context);
    final isCompact = mediaQuery.size.width < 600;
    final horizontalPadding = isCompact ? 18.0 : 32.0;
    final detail = _detail;
    final showReplyComposer =
        detail != null && _ticketCanShowComposer(detail.ticket);
    final expectedResponseNote = detail == null
        ? null
        : supportTicketExpectedResponseText(l10n, detail.ticket);
    final topOverlayExtent = expectedResponseNote == null
        ? (isCompact ? 142.0 : 152.0)
        : (isCompact ? 168.0 : 176.0);
    final bottomOverlayExtent = showReplyComposer
        ? 98.0 + mediaQuery.padding.bottom
        : 0.0;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            DecoratedBox(
              decoration: AppBoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.screenGradientColors,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: AppEdgeInsets.fromLTRB(
                        horizontalPadding,
                        topOverlayExtent,
                        horizontalPadding,
                        20,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _buildDetailContent(l10n),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: AppEdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        bottomOverlayExtent + 24,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child:
                                detail != null &&
                                    _ticketCanShowCSAT(detail.ticket)
                                ? _SupportTicketCSATPanel(
                                    controller: _csatCommentController,
                                    isSubmitting: _isSubmittingCSAT,
                                    submitted: _hasSubmittedCSAT,
                                    selectedRating: _selectedCSATRating,
                                    onRate: (rating) => setState(
                                      () => _selectedCSATRating = rating,
                                    ),
                                    onSubmit: _selectedCSATRating == null
                                        ? null
                                        : () => unawaited(
                                            _submitCSAT(_selectedCSATRating!),
                                          ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('support-ticket-header-overlay'),
              top: 0,
              left: 0,
              right: 0,
              child: _SupportChatHeaderDock(
                horizontalPadding: horizontalPadding,
                child: _SupportTicketDetailHeader(
                  l10n: l10n,
                  ticket: detail?.ticket,
                  expectedResponseNote: expectedResponseNote,
                  isClosing: _isClosing,
                  onClose: _ticketCanClose(detail?.ticket)
                      ? () => unawaited(_closeTicket())
                      : null,
                ),
              ),
            ),
            if (showReplyComposer)
              Positioned(
                key: const ValueKey('support-ticket-input-overlay'),
                left: 0,
                right: 0,
                bottom: 0,
                child: _SupportChatInputDock(
                  horizontalPadding: horizontalPadding,
                  bottomInset: mediaQuery.padding.bottom,
                  child: _ReplyComposer(
                    key: const ValueKey('support-ticket-reply-composer'),
                    controller: _replyController,
                    enabled: true,
                    isSending: _isSending,
                    isPickingAttachment: _isPickingAttachment,
                    attachments: _pendingAttachments,
                    hint: l10n.supportTicketReplyHint,
                    onAttach: () => unawaited(_pickSupportAttachment()),
                    onRemoveAttachment: _removePendingAttachment,
                    onSend: () => unawaited(_sendReply()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _ticketCanShowComposer(SupportTicketVm ticket) {
    return _ticketCanReply(ticket) || _ticketStartsNewRequest(ticket);
  }

  bool _ticketStartsNewRequest(SupportTicketVm ticket) {
    return ticket.status == 'closed' || ticket.status == 'resolved';
  }

  Widget _buildDetailContent(AppLocalizations l10n) {
    if (_isLoading) return const _SupportTicketSkeleton();
    if (_hasError) {
      return _SupportTicketStateMessage(
        icon: Icons.wifi_off_rounded,
        title: l10n.supportRequestsLoadFailedTitle,
        message: l10n.contextualHelpLoadFailed,
        actionLabel: l10n.helpCenterRetry,
        onAction: () => unawaited(_loadDetail()),
      );
    }
    final detail = _detail;
    if (detail == null || (detail.events.isEmpty && _outboxMessages.isEmpty)) {
      return _SupportTicketStateMessage(
        icon: Icons.forum_rounded,
        title: l10n.supportTicketNoMessagesTitle,
        message: l10n.supportTicketNoMessagesMessage,
        actionLabel: l10n.helpCenterRetry,
        onAction: () => unawaited(_loadDetail()),
      );
    }

    return Column(
      children:
          _supportTimelineItems(
                detail.events,
                currentTicketId: detail.ticket.id,
                outboxMessages: _outboxMessages,
              )
              .map(
                (item) => Padding(
                  padding: const AppEdgeInsets.only(bottom: 10),
                  child: switch (item) {
                    _SupportTimelineEpisodeStart(:final createdAt) =>
                      _SupportEpisodeDivider(createdAt: createdAt),
                    _SupportTimelineStatus(:final labelBuilder) =>
                      _SupportEpisodeStatusDivider(label: labelBuilder(l10n)),
                    _SupportTimelineEvent(:final event) => _SupportEventBubble(
                      event: event,
                    ),
                    _SupportTimelineOutbox(:final message) =>
                      _SupportOutboxBubble(
                        message: message,
                        onRetry: () => unawaited(_retryOutboxReply(message.id)),
                      ),
                  },
                ),
              )
              .toList(growable: false),
    );
  }

  bool _ticketCanReply(SupportTicketVm ticket) {
    return ticket.status != 'closed' && ticket.status != 'resolved';
  }

  bool _ticketCanClose(SupportTicketVm? ticket) {
    if (ticket == null) return false;
    return ticket.status != 'closed' && ticket.status != 'resolved';
  }

  bool _ticketCanShowCSAT(SupportTicketVm ticket) {
    return ticket.status == 'closed' || ticket.status == 'resolved';
  }

  String _currentUserNickname() {
    try {
      return context.read<SessionProvider>().profile?.nickname?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _currentUserId() {
    try {
      return context.read<SessionProvider>().profile?.userId.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _currentTicketId() {
    final loadedID = _detail?.ticket.id.trim() ?? '';
    if (loadedID.isNotEmpty) return loadedID;
    return widget.ticketId?.trim() ?? '';
  }

  void _scheduleScrollToLatest({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      if (target <= position.minScrollExtent) {
        return;
      }
      if (animated) {
        unawaited(
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }
}

sealed class _SupportTimelineItem {
  const _SupportTimelineItem();
}

class _SupportTimelineEpisodeStart extends _SupportTimelineItem {
  const _SupportTimelineEpisodeStart({required this.createdAt});

  final DateTime createdAt;
}

class _SupportTimelineStatus extends _SupportTimelineItem {
  const _SupportTimelineStatus({required this.labelBuilder});

  final String Function(AppLocalizations l10n) labelBuilder;
}

class _SupportTimelineEvent extends _SupportTimelineItem {
  const _SupportTimelineEvent({required this.event});

  final SupportTicketEventVm event;
}

class _SupportTimelineOutbox extends _SupportTimelineItem {
  const _SupportTimelineOutbox({required this.message});

  final _SupportOutboxMessage message;
}

List<_SupportTimelineItem> _supportTimelineItems(
  List<SupportTicketEventVm> events, {
  String? currentTicketId,
  List<_SupportOutboxMessage> outboxMessages = const [],
}) {
  final items = <_SupportTimelineItem>[];
  final activeTicketId = currentTicketId?.trim() ?? '';
  var timelineTicketId = '';
  for (final event in events) {
    final ticketId = event.ticketId.trim();
    final isActiveTicket =
        activeTicketId.isEmpty ||
        ticketId.isEmpty ||
        ticketId == activeTicketId;
    if (ticketId.isNotEmpty && ticketId != timelineTicketId) {
      timelineTicketId = ticketId;
      items.add(
        _SupportTimelineEpisodeStart(
          createdAt: event.createdAt ?? DateTime.now().toUtc(),
        ),
      );
    }

    final eventType = event.eventType.trim().toLowerCase();
    if (eventType == 'ticket_created') {
      continue;
    }
    if (eventType == 'ticket_resolved') {
      if (!isActiveTicket) {
        items.add(
          _SupportTimelineStatus(
            labelBuilder: (l10n) => l10n.supportStatusResolved,
          ),
        );
      }
    } else if (eventType == 'ticket_closed_by_user') {
      if (!isActiveTicket) {
        items.add(
          _SupportTimelineStatus(
            labelBuilder: (l10n) => l10n.supportStatusClosed,
          ),
        );
      }
    }
    items.add(_SupportTimelineEvent(event: event));
  }
  for (final message in outboxMessages) {
    if (message.startsNewRequest) {
      items.add(
        _SupportTimelineStatus(
          labelBuilder: (l10n) => l10n.supportEpisodeNewRequestCreated,
        ),
      );
    }
    items.add(_SupportTimelineOutbox(message: message));
  }
  return items;
}

String _supportLatestEventKey(List<SupportTicketEventVm> events) {
  if (events.isEmpty) {
    return '';
  }
  final event = events.last;
  return [
    event.ticketId.trim(),
    event.actorId.trim(),
    event.actorType.trim(),
    event.eventType.trim(),
    event.createdAt?.toUtc().toIso8601String() ?? '',
    _supportEventPayloadFingerprint(event.payload),
  ].join('|');
}

String _supportEventPayloadFingerprint(Map<String, String> payload) {
  for (final key in const [
    'message_preview',
    'message',
    'note',
    'resolution',
    'comment',
    'rating',
  ]) {
    final value = payload[key]?.trim() ?? '';
    if (value.isNotEmpty) {
      return '$key=$value';
    }
  }
  final entries = payload.entries.toList(growable: false)
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries
      .map((entry) => '${entry.key.trim()}=${entry.value.trim()}')
      .join('&');
}

ChatProvider? _maybeReadChatProvider(BuildContext context) {
  try {
    return context.read<ChatProvider>();
  } on ProviderNotFoundException {
    return null;
  }
}

SupportTicketEventVm? _supportRealtimeEventFromChatEvent(
  ChatEvent event, {
  required String ticketId,
  required String currentUserId,
}) {
  final payload = event.payload;
  final senderUserId = _supportPayloadString(payload, 'senderUserId');
  if (senderUserId.isNotEmpty &&
      currentUserId.isNotEmpty &&
      senderUserId == currentUserId) {
    return null;
  }

  final message = _supportPayloadString(payload, 'content');
  final fileIds = _supportRealtimeStringList(payload['fileIds']);
  if (message.isEmpty && fileIds.isEmpty) {
    return null;
  }

  final messageId = _supportFirstPayloadString(payload, const [
    'messageId',
    'id',
  ]);
  final clientMessageId = _supportPayloadString(payload, 'clientMessageId');
  final actorDisplayName = _supportPayloadString(payload, 'senderDisplayName');
  final eventPayload = <String, String>{};
  if (message.isNotEmpty) {
    eventPayload['message_preview'] = message;
  }
  if (actorDisplayName.isNotEmpty) {
    eventPayload['actor_display_name'] = actorDisplayName;
  }
  if (messageId.isNotEmpty) {
    eventPayload['message_id'] = messageId;
  }
  if (clientMessageId.isNotEmpty) {
    eventPayload['client_message_id'] = clientMessageId;
  }
  if (fileIds.isNotEmpty) {
    eventPayload['file_ids'] = fileIds.join(',');
    eventPayload['attachment_count'] = '${fileIds.length}';
  }

  return SupportTicketEventVm(
    ticketId: ticketId.trim(),
    actorId: senderUserId,
    actorType: 'support_agent',
    eventType: 'agent_replied',
    payload: eventPayload,
    createdAt: event.timestamp.toUtc(),
  );
}

bool _supportEventExists(
  List<SupportTicketEventVm> events,
  SupportTicketEventVm candidate,
) {
  final candidateMessageId = candidate.payload['message_id']?.trim() ?? '';
  final candidateClientMessageId =
      candidate.payload['client_message_id']?.trim() ?? '';
  final candidateKey = _supportLatestEventKey([candidate]);

  return events.any((event) {
    final messageId = event.payload['message_id']?.trim() ?? '';
    if (candidateMessageId.isNotEmpty && messageId == candidateMessageId) {
      return true;
    }

    final clientMessageId = event.payload['client_message_id']?.trim() ?? '';
    if (candidateClientMessageId.isNotEmpty &&
        clientMessageId == candidateClientMessageId) {
      return true;
    }

    return _supportLatestEventKey([event]) == candidateKey;
  });
}

String _supportFirstPayloadString(
  Map<String, dynamic> payload,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _supportPayloadString(payload, key);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _supportPayloadString(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value == null) return '';
  return value.toString().trim();
}

List<String> _supportRealtimeStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<_SupportOutboxMessage> _supportReconciledOutboxMessages(
  List<_SupportOutboxMessage> messages,
  List<SupportTicketEventVm> events,
) {
  if (messages.isEmpty || events.isEmpty) {
    return messages;
  }
  return messages
      .where((message) => !_supportOutboxMessageHasServerEvent(message, events))
      .toList(growable: false);
}

bool _supportOutboxMessageHasServerEvent(
  _SupportOutboxMessage message,
  List<SupportTicketEventVm> events,
) {
  if (message.status != _SupportOutboxStatus.sent) {
    return false;
  }
  final messageText = message.message.trim();
  if (messageText.isEmpty) {
    return false;
  }
  final messageTicketId = message.ticketId.trim();
  for (final event in events) {
    if (event.actorType.trim().toLowerCase() != 'user') {
      continue;
    }
    final eventTicketId = event.ticketId.trim();
    if (messageTicketId.isNotEmpty &&
        eventTicketId.isNotEmpty &&
        eventTicketId != messageTicketId) {
      continue;
    }
    if (_supportEventMessageText(event.payload) == messageText) {
      return true;
    }
  }
  return false;
}

String _supportEventMessageText(Map<String, String> payload) {
  for (final key in const ['message_preview', 'message']) {
    final value = payload[key]?.trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

enum _SupportOutboxStatus { sending, sent, failed }

class _SupportOutboxMessage {
  const _SupportOutboxMessage({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.actorNickname,
    required this.status,
    required this.createdAt,
    this.attachments = const [],
    this.fileIds = const [],
    this.startsNewRequest = false,
  });

  final String id;
  final String ticketId;
  final String message;
  final String actorNickname;
  final _SupportOutboxStatus status;
  final DateTime createdAt;
  final List<SupportPickedAttachment> attachments;
  final List<String> fileIds;
  final bool startsNewRequest;

  _SupportOutboxMessage copyWith({
    String? ticketId,
    _SupportOutboxStatus? status,
    List<String>? fileIds,
    bool? startsNewRequest,
  }) {
    return _SupportOutboxMessage(
      id: id,
      ticketId: ticketId ?? this.ticketId,
      message: message,
      actorNickname: actorNickname,
      status: status ?? this.status,
      createdAt: createdAt,
      attachments: attachments,
      fileIds: fileIds ?? this.fileIds,
      startsNewRequest: startsNewRequest ?? this.startsNewRequest,
    );
  }
}

class _SupportTicketDetailHeader extends StatelessWidget {
  const _SupportTicketDetailHeader({
    required this.l10n,
    required this.ticket,
    required this.expectedResponseNote,
    required this.isClosing,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final SupportTicketVm? ticket;
  final String? expectedResponseNote;
  final bool isClosing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return _HeaderShell(
      title: l10n.supportTicketDetailTitle,
      subtitle: ticket == null
          ? l10n.supportRequestsSubtitle
          : supportTicketPreviewText(l10n, ticket!),
      supportNote: expectedResponseNote,
      status: ticket == null
          ? null
          : supportTicketStatusLabel(l10n, ticket!.status),
      trailing: onClose == null
          ? null
          : IconButton(
              onPressed: isClosing ? null : onClose,
              tooltip: l10n.supportTicketClose,
              icon: isClosing
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        color: colors.textPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              color: colors.primary,
            ),
    );
  }
}

class _HeaderShell extends StatelessWidget {
  const _HeaderShell({
    required this.title,
    required this.subtitle,
    this.supportNote,
    this.status,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? supportNote;
  final String? status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/help');
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: colors.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.38,
                  letterSpacing: 0,
                ),
              ),
              if (supportNote != null && supportNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  supportNote!,
                  style: AppTextStyle(
                    color: colors.primary,
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
              if (status != null && status!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _StatusPill(status: status!),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SupportEpisodeDivider extends StatelessWidget {
  const _SupportEpisodeDivider({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SupportTimelineChip(
      icon: Icons.chat_bubble_outline_rounded,
      label: l10n.supportEpisodeStarted(
        supportEpisodeDateLabel(Localizations.localeOf(context), createdAt),
      ),
    );
  }
}

class _SupportEpisodeStatusDivider extends StatelessWidget {
  const _SupportEpisodeStatusDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _SupportTimelineChip(icon: Icons.check_rounded, label: label);
  }
}

class _SupportTimelineChip extends StatelessWidget {
  const _SupportTimelineChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Center(
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: AppBorderRadius.circular(999),
          border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.primary, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _SupportEventBubble extends StatelessWidget {
  const _SupportEventBubble({required this.event});

  final SupportTicketEventVm event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final isUser = event.actorType == 'user';
    final message = supportEventMessage(l10n, event);
    final attachmentLabels = supportEventAttachmentLabels(l10n, event);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            color: isUser ? null : colors.surface,
            gradient: isUser
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.primaryPressed],
                  )
                : null,
            borderRadius: AppBorderRadius.only(
              topLeft: const AppRadiusValue.circular(18),
              topRight: const AppRadiusValue.circular(18),
              bottomLeft: AppRadiusValue.circular(isUser ? 18 : 6),
              bottomRight: AppRadiusValue.circular(isUser ? 6 : 18),
            ),
            border: Border.all(
              color: isUser
                  ? colors.primary.withValues(alpha: 0.48)
                  : colors.borderPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: (isUser ? colors.primary : colors.black).withValues(
                  alpha: isUser ? 0.16 : 0.22,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supportEventActorLabel(l10n, event),
                  style: AppTextStyle(
                    color: isUser ? colors.textPrimary : colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (attachmentLabels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SupportBubbleAttachmentChips(
                    labels: attachmentLabels,
                    isUser: isUser,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportOutboxBubble extends StatelessWidget {
  const _SupportOutboxBubble({required this.message, required this.onRetry});

  final _SupportOutboxMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final attachmentLabels = _supportOutboxAttachmentLabels(l10n, message);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryPressed],
            ),
            borderRadius: const AppBorderRadius.only(
              topLeft: AppRadiusValue.circular(18),
              topRight: AppRadiusValue.circular(18),
              bottomLeft: AppRadiusValue.circular(18),
              bottomRight: AppRadiusValue.circular(6),
            ),
            border: Border.all(color: colors.primary.withValues(alpha: 0.48)),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const AppEdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.supportUserFallbackName,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.message,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (attachmentLabels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SupportBubbleAttachmentChips(
                    labels: attachmentLabels,
                    isUser: true,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _supportOutboxStatusIcon(message.status),
                      color: colors.textPrimary.withValues(alpha: 0.72),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _supportOutboxStatusLabel(l10n, message.status),
                      style: AppTextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    if (message.status == _SupportOutboxStatus.failed) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        key: ValueKey('support-ticket-retry-${message.id}'),
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          padding: const AppEdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(l10n.supportMessageRetry),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportBubbleAttachmentChips extends StatelessWidget {
  const _SupportBubbleAttachmentChips({
    required this.labels,
    required this.isUser,
  });

  final List<String> labels;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final colors = AppDesignSystem.colorsFor(context);
    final foreground = isUser ? colors.textPrimary : colors.primary;
    final borderColor = foreground.withValues(alpha: isUser ? 0.28 : 0.32);
    final background = isUser
        ? colors.textPrimary.withValues(alpha: 0.12)
        : colors.primary.withValues(alpha: 0.12);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (label) => DecoratedBox(
              decoration: AppBoxDecoration(
                color: background,
                borderRadius: AppBorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const AppEdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file_rounded,
                      color: foreground,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle(
                          color: foreground,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SupportChatHeaderDock extends StatelessWidget {
  const _SupportChatHeaderDock({
    required this.horizontalPadding,
    required this.child,
  });

  final double horizontalPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.background.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppEdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            12,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportChatInputDock extends StatelessWidget {
  const _SupportChatInputDock({
    required this.horizontalPadding,
    required this.bottomInset,
    required this.child,
  });

  final double horizontalPadding;
  final double bottomInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.background.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.borderPrimary)),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: AppEdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            10 + bottomInset,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportPendingAttachmentsStrip extends StatelessWidget {
  const _SupportPendingAttachmentsStrip({
    required this.attachments,
    required this.onRemove,
  });

  final List<SupportPickedAttachment> attachments;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _SupportPendingAttachmentChip(
            key: ValueKey('support-ticket-pending-attachment-$index'),
            attachment: attachments[index],
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}

class _SupportPendingAttachmentChip extends StatelessWidget {
  const _SupportPendingAttachmentChip({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  final SupportPickedAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: AppBorderRadius.circular(14),
          border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                color: colors.primary,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  attachment.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatSupportAttachmentSize(attachment.bytes.lengthInBytes),
                style: AppTextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 3),
              InkWell(
                borderRadius: AppBorderRadius.circular(12),
                onTap: onRemove,
                child: Padding(
                  padding: const AppEdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.primary,
                    size: 16,
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

String _formatSupportAttachmentSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.isPickingAttachment,
    required this.attachments,
    required this.hint,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final bool isPickingAttachment;
  final List<SupportPickedAttachment> attachments;
  final String hint;
  final VoidCallback onAttach;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty) ...[
              _SupportPendingAttachmentsStrip(
                attachments: attachments,
                onRemove: onRemoveAttachment,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  key: const ValueKey('support-ticket-attach-file'),
                  onPressed: enabled && !isSending && !isPickingAttachment
                      ? onAttach
                      : null,
                  tooltip: l10n.chatComposerAttachButtonLabel,
                  style: IconButton.styleFrom(
                    foregroundColor: colors.primary,
                    disabledForegroundColor: colors.primary.withValues(
                      alpha: 0.58,
                    ),
                    minimumSize: const Size(42, 42),
                  ),
                  icon: isPickingAttachment
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textPrimary,
                          ),
                        )
                      : const Icon(Icons.attach_file_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    key: const ValueKey('support-ticket-reply-field'),
                    controller: controller,
                    enabled: enabled && !isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: AppTextStyle(
                      color: colors.textPrimary,
                      letterSpacing: 0,
                    ),
                    decoration: AppInputDecoration(
                      hintText: hint,
                      hintStyle: AppTextStyle(color: colors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const AppEdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const ValueKey('support-ticket-send-reply'),
                  onPressed: enabled && !isSending ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textPrimary,
                    disabledBackgroundColor: colors.primary.withValues(
                      alpha: 0.34,
                    ),
                    disabledForegroundColor: colors.textPrimary.withValues(
                      alpha: 0.58,
                    ),
                    minimumSize: const Size(46, 46),
                  ),
                  icon: isSending
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketCSATPanel extends StatelessWidget {
  const _SupportTicketCSATPanel({
    required this.controller,
    required this.isSubmitting,
    required this.submitted,
    required this.selectedRating,
    required this.onRate,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final bool submitted;
  final int? selectedRating;
  final ValueChanged<int> onRate;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    if (submitted) {
      return DecoratedBox(
        decoration: AppBoxDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: AppBorderRadius.circular(18),
          border: Border.all(color: colors.primary.withValues(alpha: 0.26)),
        ),
        child: Padding(
          padding: const AppEdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.supportTicketCSATThanks,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.supportTicketCSATTitle,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('support-ticket-csat-comment'),
              controller: controller,
              enabled: !isSubmitting,
              minLines: 1,
              maxLines: 3,
              style: AppTextStyle(color: colors.textPrimary, letterSpacing: 0),
              decoration: AppInputDecoration(
                hintText: l10n.supportTicketCSATCommentHint,
                hintStyle: AppTextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected =
                    selectedRating != null && rating <= selectedRating!;
                return IconButton(
                  key: ValueKey('support-ticket-csat-$rating'),
                  onPressed: isSubmitting ? null : () => onRate(rating),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSubmitting ? colors.textDisabled : colors.primary,
                    size: 30,
                  ),
                  style: IconButton.styleFrom(
                    fixedSize: const Size(48, 48),
                    minimumSize: const Size(48, 48),
                    padding: AppInsets.none,
                    foregroundColor: colors.primary,
                    backgroundColor: isSelected
                        ? colors.primary.withValues(alpha: 0.16)
                        : colors.primary.withValues(alpha: 0.08),
                    disabledBackgroundColor: colors.surfaceHigh,
                    disabledForegroundColor: colors.textDisabled,
                    side: BorderSide(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.48)
                          : colors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  tooltip: rating.toString(),
                );
              }),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('support-ticket-csat-submit'),
                onPressed: isSubmitting || selectedRating == null
                    ? null
                    : onSubmit,
                icon: isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.supportTicketCSATSubmit),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.textPrimary,
                  disabledBackgroundColor: colors.surfaceHigh,
                  disabledForegroundColor: colors.textDisabled,
                  minimumSize: const Size(0, 44),
                  padding: const AppEdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.18),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const AppEdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          status,
          style: AppTextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String supportTicketStatusLabel(AppLocalizations l10n, String status) {
  return switch (status.trim().toLowerCase()) {
    'new' => l10n.supportStatusNew,
    'open' => l10n.supportStatusOpen,
    'assigned' => l10n.supportStatusAssigned,
    'waiting_user' => l10n.supportStatusWaitingUser,
    'waiting_support' => l10n.supportStatusWaitingSupport,
    'resolved' => l10n.supportStatusResolved,
    'closed' => l10n.supportStatusClosed,
    'reopened' => l10n.supportStatusReopened,
    _ => l10n.supportStatusOpen,
  };
}

String supportTicketPreviewText(AppLocalizations l10n, SupportTicketVm ticket) {
  return switch (ticket.status.trim().toLowerCase()) {
    'waiting_user' => l10n.supportPreviewWaitingUser,
    'waiting_support' => l10n.supportPreviewWaitingSupport,
    'resolved' || 'closed' => l10n.supportPreviewResolved,
    _ => l10n.supportPreviewNew,
  };
}

String? supportTicketExpectedResponseText(
  AppLocalizations l10n,
  SupportTicketVm ticket,
) {
  final status = ticket.status.trim().toLowerCase();
  if (status == 'waiting_user' || status == 'resolved' || status == 'closed') {
    return null;
  }
  if (ticket.firstResponseAt != null) return null;
  final target = _supportFirstResponseTarget(ticket.priority);
  return l10n.supportExpectedResponseWithin(
    _supportDurationLabel(l10n, target),
  );
}

Duration _supportFirstResponseTarget(String priority) {
  return switch (priority.trim().toLowerCase()) {
    'urgent' => const Duration(minutes: 10),
    'high' => const Duration(minutes: 20),
    _ => const Duration(minutes: 30),
  };
}

String _supportDurationLabel(AppLocalizations l10n, Duration duration) {
  final locale = l10n.localeName.toLowerCase();
  final minutes = duration.inMinutes;
  if (minutes < 60) {
    return locale.startsWith('en') ? '$minutes min' : '$minutes мин';
  }
  final hours = duration.inHours;
  return locale.startsWith('en') ? '$hours h' : '$hours ч';
}

String supportEpisodeDateLabel(Locale locale, DateTime value) {
  final normalized = locale.languageCode.toLowerCase();
  final localDate = value.toLocal();
  final months = switch (normalized) {
    'ru' => const [
      'янв.',
      'фев.',
      'мар.',
      'апр.',
      'мая',
      'июн.',
      'июл.',
      'авг.',
      'сен.',
      'окт.',
      'ноя.',
      'дек.',
    ],
    'kk' => const [
      'қаң.',
      'ақп.',
      'нау.',
      'сәу.',
      'мам.',
      'мау.',
      'шіл.',
      'там.',
      'қыр.',
      'қаз.',
      'қар.',
      'жел.',
    ],
    _ => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
  };
  final month = months[(localDate.month - 1).clamp(0, months.length - 1)];
  if (normalized == 'ru' || normalized == 'kk') {
    return '${localDate.day} $month';
  }
  return '$month ${localDate.day}';
}

bool supportTicketHasSubmittedCSAT(SupportTicketDetailVm detail) {
  final currentTicketId = detail.ticket.id.trim();
  return detail.events.any((event) {
    final eventTicketId = event.ticketId.trim();
    final belongsToCurrentTicket =
        eventTicketId.isEmpty || eventTicketId == currentTicketId;
    return belongsToCurrentTicket &&
        event.eventType.trim().toLowerCase() == 'ticket_csat_submitted';
  });
}

String supportEventMessage(AppLocalizations l10n, SupportTicketEventVm event) {
  final explicitMessage =
      event.payload['message_preview'] ??
      event.payload['message'] ??
      event.payload['resolution'];
  if (explicitMessage != null && explicitMessage.trim().isNotEmpty) {
    return explicitMessage.trim();
  }

  return switch (event.eventType.trim().toLowerCase()) {
    'ticket_closed_by_user' => l10n.supportEventTicketClosedByUser,
    'ticket_csat_submitted' => l10n.supportEventCSATSubmitted,
    'ticket_resolved' => l10n.supportEventTicketResolved,
    'ticket_segment_calculated' => l10n.supportEventSegmentCalculated,
    'user_replied' => l10n.supportEventUserReplied,
    'agent_replied' => l10n.supportEventAgentReplied,
    _ => l10n.supportEventUpdated,
  };
}

List<String> supportEventAttachmentLabels(
  AppLocalizations l10n,
  SupportTicketEventVm event,
) {
  final explicitNames = _supportPayloadList(
    event.payload['file_names'] ?? event.payload['attachment_names'],
  );
  final fileIds = _supportPayloadList(event.payload['file_ids']);
  var count = explicitNames.length;
  if (fileIds.length > count) count = fileIds.length;
  final payloadCount = int.tryParse(
    (event.payload['attachment_count'] ?? '').trim(),
  );
  if (payloadCount != null && payloadCount > count) count = payloadCount;
  return _supportAttachmentLabels(l10n, count, explicitNames);
}

List<String> _supportOutboxAttachmentLabels(
  AppLocalizations l10n,
  _SupportOutboxMessage message,
) {
  final explicitNames = message.attachments
      .map((attachment) => attachment.displayName)
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: false);
  var count = explicitNames.length;
  if (message.fileIds.length > count) count = message.fileIds.length;
  return _supportAttachmentLabels(l10n, count, explicitNames);
}

List<String> _supportAttachmentLabels(
  AppLocalizations l10n,
  int count,
  List<String> explicitNames,
) {
  if (count <= 0) return const [];
  return List<String>.generate(count, (index) {
    if (index < explicitNames.length) {
      final explicit = explicitNames[index].trim();
      if (explicit.isNotEmpty) return explicit;
    }
    return '${l10n.chatAttachmentFile} ${index + 1}';
  }, growable: false);
}

List<String> _supportPayloadList(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String supportEventActorLabel(
  AppLocalizations l10n,
  SupportTicketEventVm event,
) {
  final displayName =
      event.payload['actor_display_name'] ??
      event.payload['actorDisplayName'] ??
      event.payload['display_name'];
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }

  final nickname =
      event.payload['actor_nickname'] ??
      event.payload['actorNickname'] ??
      event.payload['nickname'];
  if (nickname != null && nickname.trim().isNotEmpty) {
    return nickname.trim();
  }

  if (event.actorType == 'user') return l10n.supportUserFallbackName;
  if (event.actorType == 'support_agent' ||
      event.actorType == 'support_admin') {
    return l10n.supportAgentFallbackName;
  }
  return l10n.supportSystemFallbackName;
}

String _supportOutboxStatusLabel(
  AppLocalizations l10n,
  _SupportOutboxStatus status,
) {
  return switch (status) {
    _SupportOutboxStatus.sending => l10n.supportMessageSending,
    _SupportOutboxStatus.sent => l10n.supportMessageSent,
    _SupportOutboxStatus.failed => l10n.supportMessageNotSent,
  };
}

IconData _supportOutboxStatusIcon(_SupportOutboxStatus status) {
  return switch (status) {
    _SupportOutboxStatus.sending => Icons.schedule_rounded,
    _SupportOutboxStatus.sent => Icons.done_all_rounded,
    _SupportOutboxStatus.failed => Icons.error_outline_rounded,
  };
}

class _SupportTicketSkeleton extends StatelessWidget {
  const _SupportTicketSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const AppEdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: AppBorderRadius.circular(14),
            ),
            child: const SizedBox(height: 86, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

class _SupportTicketStateMessage extends StatelessWidget {
  const _SupportTicketStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.circular(18),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Padding(
        padding: const AppEdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.38,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.support_agent_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textPrimary,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.34),
                disabledForegroundColor: colors.textPrimary.withValues(
                  alpha: 0.58,
                ),
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
