import '../../l10n/generated/app_localizations.dart';

String formatActivityStatus(String value, AppLocalizations l10n) {
  switch (value.toUpperCase()) {
    case 'DRAFT':
      return l10n.activityStatusDraft;
    case 'REVIEW_REQUIRED':
      return l10n.activityStatusReviewRequired;
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
    default:
      return value;
  }
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
