import '../../../l10n/generated/app_localizations.dart';
import '../models/conversation_vm.dart';

String chatPresenceStatusLabel(
  AppLocalizations l10n,
  ParticipantInfo? participant,
) {
  if (participant?.isOnline ?? false) {
    return l10n.chatPresenceOnline;
  }

  final lastSeenAt = participant?.lastSeenAt;
  if (lastSeenAt == null) {
    return l10n.chatPresenceOffline;
  }

  final diff = DateTime.now().difference(lastSeenAt.toLocal());
  if (diff.inMinutes < 1) {
    return l10n.chatPresenceLastSeenJustNow;
  }
  if (diff.inHours < 1) {
    return l10n.chatPresenceLastSeenMinutes(diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return l10n.chatPresenceLastSeenHours(diff.inHours);
  }
  return l10n.chatPresenceLastSeenDays(diff.inDays);
}
