import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/models/message_vm.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openConversation(widget.conversationId);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMoreMessages();
    }
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<ChatProvider>().sendMessage(text);
    context.read<ChatProvider>().markAsRead();
  }

  void _handleTyping() {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {});
    context.read<ChatProvider>().sendTyping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      resizeToAvoidBottomInset: true,
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.messagesLoading && chat.messages.isEmpty) {
            return const _LoadingState();
          }

          if (chat.messagesError != null && chat.messages.isEmpty) {
            return _ErrorState(
              onRetry: () =>
                  chat.openConversation(widget.conversationId),
            );
          }

          final conv = chat.activeConversation;
          if (conv == null) return const _LoadingState();

          return Column(
            children: [
              _ChatTopBar(conversation: conv),
              Expanded(
                child: _MessageList(
                  messages: chat.messages,
                  conversation: conv,
                  scrollController: _scrollController,
                  currentUserId: '', // filled via session
                ),
              ),
              _ChatComposer(
                controller: _messageController,
                focusNode: _focusNode,
                onSend: _handleSend,
                onTyping: _handleTyping,
                sending: chat.sendingMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({required this.conversation});

  final ConversationDetail conversation;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: mq.padding.top + 18,
        left: 18,
        right: 18,
        bottom: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1d120b),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Icon(Icons.arrow_back_ios_new,
                    size: 20, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Contact info
          if (conversation.isDirect) ...[
            _DirectTopBarContent(conversation: conversation),
          ] else ...[
            _GroupTopBarContent(conversation: conversation),
            const SizedBox(width: 14),
            // Participants button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x2EFF9D00),
                ),
                color: const Color(0x0DFF9900),
              ),
              child: const Center(
                child: Icon(Icons.group_outlined,
                    size: 22, color: Color(0xFFff9800)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectTopBarContent extends StatelessWidget {
  const _DirectTopBarContent({required this.conversation});

  final ConversationDetail conversation;

  @override
  Widget build(BuildContext context) {
    final otherParticipant = conversation.participants.isNotEmpty
        ? conversation.participants.first
        : null;

    return Expanded(
      child: Row(
        children: [
          // Avatar
          _ChatAvatar(
            size: 56,
            name: otherParticipant?.displayName ?? '',
            avatarFileId: otherParticipant?.avatarFileId,
          ),
          const SizedBox(width: 14),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherParticipant?.displayName ??
                      conversation.title ??
                      'Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.03 * 22,
                    color: Color(0xFFffb11e),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00c853),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00c853)
                                .withValues(alpha: 0.15),
                            blurRadius: 3,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE NOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.17 * 11,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTopBarContent extends StatelessWidget {
  const _GroupTopBarContent({required this.conversation});

  final ConversationDetail conversation;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            conversation.title ?? 'Group Chat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.03 * 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${conversation.participants.length} participants',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFf4a020),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pinned message ───────────────────────────────────────────────

class _PinnedMessageBanner extends StatelessWidget {
  const _PinnedMessageBanner({required this.pinned});

  final PinnedMessageInfo pinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 18, 0, 26),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        gradient: const LinearGradient(
          colors: [
            Color(0x05FF9100),
            Color(0x24FF9100),
            Color(0x05FF9100),
          ],
        ),
        color: const Color(0xB842220C),
        border: Border.all(
          color: const Color(0x40FF9800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, size: 18, color: Color(0xFFff9800)),
              const SizedBox(width: 10),
              Text(
                'PINNED MESSAGE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.06 * 16,
                  color: const Color(0xFFff9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pinned.content,
            style: const TextStyle(
              fontSize: 18,
              height: 1.42,
              letterSpacing: -0.03 * 18,
              color: Color(0xFFf3ede7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message list ─────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.conversation,
    required this.scrollController,
    required this.currentUserId,
  });

  final List<MessageVm> messages;
  final ConversationDetail conversation;
  final ScrollController scrollController;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return CustomScrollView(
      controller: scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(
              height: conversation.isGroup ? 34 : 42,
            ),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems() {
    final items = <Widget>[];

    String? lastDateLabel;
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateLabel = _dateLabelFor(msg.sentAt);

      // Insert day separator when date changes (reverse order)
      final nextMsg = i + 1 < messages.length ? messages[i + 1] : null;
      final nextLabel =
          nextMsg != null ? _dateLabelFor(nextMsg.sentAt) : null;
      if (dateLabel != lastDateLabel && dateLabel != nextLabel) {
        lastDateLabel = dateLabel;
      }

      items.add(
        _MessageBubble(
          message: msg,
          isGroup: conversation.isGroup,
          isMine: msg.senderUserId == currentUserId,
        ),
      );

      // Add day separator after messages of a different day (in reversed view it appears above)
      if (nextMsg != null && dateLabel != _dateLabelFor(nextMsg.sentAt)) {
        items.add(
          _DaySeparator(
            label: dateLabel,
            isGroup: conversation.isGroup,
          ),
        );
      }
    }

    // Add separator at the very top for the oldest visible messages
    if (messages.isNotEmpty) {
      final oldest = messages.last;
      items.add(
        _DaySeparator(
          label: _dateLabelFor(oldest.sentAt),
          isGroup: conversation.isGroup,
        ),
      );
    }

    // Pinned message at the very end (top of screen in reversed view)
    if (conversation.pinnedMessage != null) {
      items.add(
        _PinnedMessageBanner(pinned: conversation.pinnedMessage!),
      );
    }

    return items;
  }

  String _dateLabelFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Day separator ────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label, required this.isGroup});

  final String label;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      // Group style: pill badge (matches group_chat.html)
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0x734C2F15),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.02),
                offset: const Offset(0, 1),
                blurRadius: 0,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 15,
              color: Color(0xFFb9a48d),
            ),
          ),
        ),
      );
    }

    // Direct style: line divider (matches personal_chat.html)
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.14 * 12,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────

const _nameColors = [
  Color(0xFF2d7dff), // blue
  Color(0xFF00df85), // green
  Color(0xFFf4a020), // orange
  Color(0xFFe040fb), // purple
  Color(0xFF00bcd4), // cyan
  Color(0xFFff5252), // red
];

Color _nameColorFor(String userId) {
  var hash = 0;
  for (var i = 0; i < userId.length; i++) {
    hash = userId.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _nameColors[hash.abs() % _nameColors.length];
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isGroup,
    required this.isMine,
  });

  final MessageVm message;
  final bool isGroup;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Opacity(
        opacity: 0.4,
        child: Text(
          'Message deleted',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        _ChatAvatar(
          size: isGroup ? 56 : 42,
          name: message.senderDisplayName,
        ),
        SizedBox(width: isGroup ? 14 : 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta row: name + time + ticks
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.senderDisplayName,
                      style: TextStyle(
                        fontSize: isGroup ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: -0.02 * 18,
                        color: _nameColorFor(message.senderUserId),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatMessageTime(message.sentAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '✓✓',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFff9800),
                            letterSpacing: -0.08 * 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bubble
              Container(
                width: double.infinity,
                padding: isGroup
                    ? const EdgeInsets.fromLTRB(28, 28, 28, 24)
                    : const EdgeInsets.fromLTRB(30, 26, 30, 26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: isGroup
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xA34D2D13),
                            Color(0xD13C210D),
                          ],
                        )
                      : null,
                  color: isGroup ? null : const Color(0xAD462E1B),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.03),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: isGroup ? 22 : 17,
                    height: isGroup ? 1.46 : 1.55,
                    letterSpacing: isGroup ? -0.035 * 22 : -0.02 * 17,
                    color: Colors.white.withValues(alpha: 0.98),
                  ),
                ),
              ),
              if (message.isEdited)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 6),
                  child: Text(
                    'edited',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} PM';
  }
}

// ── Avatar ────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.size,
    required this.name,
    this.avatarFileId,
  });

  final double size;
  final String name;
  final String? avatarFileId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment(-0.3, -0.4),
          end: Alignment(0.8, 1),
          colors: [Color(0xFFf3d7b3), Color(0xFFca9a6d), Color(0xFF6f3f22)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2b1606),
          ),
        ),
      ),
    );
  }

  String get _initial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

// ── Composer ──────────────────────────────────────────────────────

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onTyping,
    required this.sending,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onTyping;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        14,
        14,
        18 + mq.padding.bottom,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        color: const Color(0xB8140B06),
      ),
      child: Row(
        children: [
          // Plus button
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xD136230F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xB8412A18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (_) => onTyping(),
                      onSubmitted: (_) => onSend(),
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFf5f3ef),
                        letterSpacing: -0.02 * 16,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.48),
                          letterSpacing: -0.02 * 16,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    child: Text(
                      '☺',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFff9d00),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error states ───────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF100802),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFff9800)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100802),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load chat',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFff9800))),
            ),
          ],
        ),
      ),
    );
  }
}
