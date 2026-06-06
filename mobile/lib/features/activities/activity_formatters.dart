import '../../l10n/generated/app_localizations.dart';
import 'models/activity_list_item_vm.dart';

String formatActivityStatus(String value, AppLocalizations l10n) {
  switch (value.toUpperCase()) {
    case 'DRAFT':
      return l10n.activityStatusDraft;
    case 'PUBLISHED':
      return l10n.activityStatusPublished;
    case 'ENROLLMENT_OPEN':
      return l10n.activityStatusEnrollmentOpen;
    case 'FULL':
      return l10n.activityStatusFull;
    case 'STARTED':
      return l10n.activityStatusStarted;
    case 'COMPLETED':
      return l10n.activityStatusCompleted;
    case 'CANCELLED':
      return l10n.activityStatusCancelled;
    case 'ARCHIVED':
      return l10n.activityStatusArchived;
    case 'INVITED':
    case 'REQUESTED':
    case 'APPROVED':
    case 'WAITLISTED':
    case 'PENDING_PAYMENT':
    case 'CONFIRMED':
    case 'DECLINED':
    case 'EXPIRED':
    case 'CHECKED_IN':
    case 'NO_SHOW':
      return formatParticipantStatus(value, l10n);
    default:
      return value;
  }
}

String formatActivityDisplayStatus(
  ActivityListItemVm activity,
  AppLocalizations l10n,
) {
  if (activity.isCompletedEarly) {
    return l10n.activityStatusCompletedEarly;
  }
  return formatActivityStatus(activity.status, l10n);
}

String activityLocationFallbackText(
  ActivityListItemVm activity,
  AppLocalizations l10n,
) {
  final city = activity.cityName?.trim() ?? '';
  if (city.isNotEmpty) return city;

  final address = activity.addressText?.trim() ?? '';
  if (address.isNotEmpty) return address;

  return formatActivityDisplayStatus(activity, l10n);
}

String formatActivityFormat(String value, AppLocalizations l10n) {
  switch (value.toUpperCase()) {
    case 'OFFLINE':
      return l10n.activityFormatOffline;
    case 'ONLINE':
      return l10n.activityFormatOnline;
    case 'HYBRID':
      return l10n.activityFormatHybrid;
    default:
      return value;
  }
}

String formatParticipantStatus(String value, AppLocalizations l10n) {
  switch (value.toUpperCase()) {
    case 'INVITED':
      return l10n.participantStatusInvited;
    case 'REQUESTED':
      return l10n.participantStatusRequested;
    case 'APPROVED':
      return l10n.participantStatusApproved;
    case 'WAITLISTED':
      return l10n.participantStatusWaitlisted;
    case 'PENDING_PAYMENT':
      return l10n.participantStatusPendingPayment;
    case 'CONFIRMED':
      return l10n.participantStatusConfirmed;
    case 'DECLINED':
      return l10n.participantStatusDeclined;
    case 'CANCELLED':
      return l10n.participantStatusCancelled;
    case 'EXPIRED':
      return l10n.participantStatusExpired;
    case 'CHECKED_IN':
      return l10n.participantStatusCheckedIn;
    case 'NO_SHOW':
      return l10n.participantStatusNoShow;
    default:
      return value
          .split('_')
          .where((part) => part.isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}
