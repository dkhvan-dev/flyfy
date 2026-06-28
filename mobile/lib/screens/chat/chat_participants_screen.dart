import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/file_api.dart';
import '../../features/chat/models/conversation_vm.dart';
import '../../features/chat/utils/chat_presence_status.dart';
import '../../l10n/generated/app_localizations.dart';

class ChatParticipantsScreen extends StatelessWidget {
  const ChatParticipantsScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  final ConversationDetail conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final participants = _orderedParticipants;
    final organizer = participants.where((p) => p.role == 'admin').firstOrNull;
    final currentUserIsOrganizer =
        organizer?.userId.trim() == currentUserId.trim();
    final joined = _currentUserFirstJoinedParticipants(
      participants: participants,
      organizer: organizer,
      currentUserIsOrganizer: currentUserIsOrganizer,
    );

    return Scaffold(
      backgroundColor: AppPalette.warmInk54,
      body: Container(
        decoration: const AppBoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 0.9,
            colors: [AppPalette.warmOverlayMuted03, AppPalette.clearWarmInk02],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.clamp(320.0, 430.0);
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ParticipantsHeader(
                        title:
                            conversation.title ??
                            l10n.chatActivityFallbackTitle,
                        count: participants.length,
                        horizontalPadding: horizontalPadding,
                      ),
                    ),
                    SliverPadding(
                      padding: AppEdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        MediaQuery.paddingOf(context).bottom + 32,
                      ),
                      sliver: SliverList.list(
                        children: [
                          if (organizer != null) ...[
                            _SectionTitle(l10n.chatParticipantsHostSection),
                            const SizedBox(height: 18),
                            _OrganizerCard(
                              participant: organizer,
                              onTap: () =>
                                  _openParticipantProfile(context, organizer),
                            ),
                            const SizedBox(height: 28),
                          ],
                          _SectionTitle(l10n.chatParticipantsJoinedSection),
                          const SizedBox(height: 18),
                          if (joined.isEmpty)
                            const _EmptyParticipants()
                          else
                            ...joined.map(
                              (participant) => Padding(
                                padding: const AppEdgeInsets.only(bottom: 34),
                                child: _ParticipantRow(
                                  participant: participant,
                                  onTap: () => _openParticipantProfile(
                                    context,
                                    participant,
                                  ),
                                ),
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
      ),
    );
  }

  List<ParticipantInfo> get _orderedParticipants {
    final items = [...conversation.participants];
    items.sort((a, b) {
      if (a.role == 'admin' && b.role != 'admin') return -1;
      if (a.role != 'admin' && b.role == 'admin') return 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
    return items;
  }

  List<ParticipantInfo> _currentUserFirstJoinedParticipants({
    required List<ParticipantInfo> participants,
    required ParticipantInfo? organizer,
    required bool currentUserIsOrganizer,
  }) {
    final joined = participants
        .where((p) => organizer == null || p.userId != organizer.userId)
        .toList(growable: false);
    final currentUserId = this.currentUserId.trim();
    if (currentUserIsOrganizer || currentUserId.isEmpty) return joined;

    final currentParticipant = joined
        .where((participant) => participant.userId.trim() == currentUserId)
        .firstOrNull;
    if (currentParticipant == null) return joined;

    final others = joined
        .where((participant) => participant.userId.trim() != currentUserId)
        .toList(growable: false);
    return [currentParticipant, ...others];
  }

  void _openParticipantProfile(
    BuildContext context,
    ParticipantInfo participant,
  ) {
    final userId = participant.userId.trim();
    if (userId.isEmpty) return;

    if (userId == currentUserId.trim()) {
      context.push('/profile');
      return;
    }

    context.push('/users/${Uri.encodeComponent(userId)}/profile');
  }
}

class _ParticipantsHeader extends StatelessWidget {
  const _ParticipantsHeader({
    required this.title,
    required this.count,
    required this.horizontalPadding,
  });

  final String title;
  final int count;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: AppEdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding + 26,
        horizontalPadding,
        18,
      ),
      decoration: AppBoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppPalette.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _BackButton(onTap: () => Navigator.of(context).pop()),
          ),
          Padding(
            padding: const AppEdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.trim().isEmpty
                      ? l10n.chatActivityFallbackTitle
                      : title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const AppTextStyle(
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.75,
                    color: AppPalette.orangeWash14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: AppBoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.primary.withValues(alpha: 0.08),
                            blurRadius: 0,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.chatParticipantsCount(count),
                      style: const AppTextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: AppPalette.primary,
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 24,
          color: AppPalette.orangeWash14,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyle(
        fontSize: MediaQuery.sizeOf(context).width < 360 ? 14 : 16,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.92,
        color: AppPalette.orangeWash14.withValues(alpha: 0.48),
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.participant, required this.onTap});

  final ParticipantInfo participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 178),
        padding: AppEdgeInsets.symmetric(
          horizontal: compact ? 18 : 22,
          vertical: compact ? 20 : 24,
        ),
        decoration: AppBoxDecoration(
          borderRadius: AppBorderRadius.circular(32),
          color: AppPalette.white.withValues(alpha: 0.04),
          border: Border.all(color: AppPalette.primary.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            _ParticipantAvatar(
              participant: participant,
              size: compact ? 84 : 96,
              highlighted: true,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _ParticipantText(
                participant: participant,
                nameSize: compact ? 22 : 25,
                status: chatPresenceStatusLabel(l10n, participant),
                online: participant.isOnline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant, required this.onTap});

  final ParticipantInfo participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _ParticipantAvatar(participant: participant, size: compact ? 58 : 66),
          const SizedBox(width: 18),
          Expanded(
            child: _ParticipantText(
              participant: participant,
              nameSize: compact ? 22 : 25,
              status: chatPresenceStatusLabel(l10n, participant),
              online: participant.isOnline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantText extends StatelessWidget {
  const _ParticipantText({
    required this.participant,
    required this.nameSize,
    required this.status,
    this.online = false,
  });

  final ParticipantInfo participant;
  final double nameSize;
  final String status;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = participant.displayName.trim().isEmpty
        ? l10n.chatUserFallbackName
        : participant.displayName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle(
            fontSize: nameSize,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.75,
            color: AppPalette.orangeWash14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (online) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const AppBoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle(
                  fontSize: nameSize >= 25 ? 18 : 16,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.72,
                  color: online
                      ? AppPalette.primary
                      : AppPalette.orangeWash14.withValues(alpha: 0.48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.participant,
    required this.size,
    this.highlighted = false,
  });

  final ParticipantInfo participant;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolvePublicFileContentUrl(
      participant.avatarFileId ?? '',
    );

    return Container(
      width: size,
      height: size,
      padding: AppEdgeInsets.all(highlighted ? 4 : 0),
      decoration: AppBoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? AppPalette.primary : AppPalette.transparent,
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppPalette.primary.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Container(
          color: AppPalette.neutralInk01,
          child: imageUrl == null
              ? _AvatarFallback(name: participant.displayName)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _AvatarFallback(name: participant.displayName),
                ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      decoration: const AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalette.neutralSurfaceHigh01,
            AppPalette.neutralSurface01,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const AppTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppPalette.orangeWash14,
          ),
        ),
      ),
    );
  }
}

class _EmptyParticipants extends StatelessWidget {
  const _EmptyParticipants();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const AppEdgeInsets.symmetric(vertical: 16),
      child: Text(
        l10n.chatParticipantsEmpty,
        style: AppTextStyle(
          fontSize: 16,
          color: AppPalette.orangeWash14.withValues(alpha: 0.48),
        ),
      ),
    );
  }
}
