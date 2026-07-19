import 'package:dio/dio.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/saved_api.dart';
import '../domain/saved_error.dart';
import 'state/saved_screen_controller.dart';

String savedErrorMessage(AppLocalizations l10n, Object error) {
  if (error is SavedApiException) {
    final code = error.error?.code;
    if (error.cause.response == null &&
        error.cause.type != DioExceptionType.cancel) {
      return l10n.savedErrorNetwork;
    }
    return switch (code) {
      SavedErrorCode.collectionTitleConflict =>
        l10n.savedErrorDuplicateCollection,
      SavedErrorCode.collectionLimitReached ||
      SavedErrorCode.collectionItemLimitReached ||
      SavedErrorCode.membershipLimitReached ||
      SavedErrorCode.itemLimitReached => l10n.savedErrorQuota,
      SavedErrorCode.mutationStale ||
      SavedErrorCode.collectionDeleted ||
      SavedErrorCode.collectionNotFound => l10n.savedErrorConflict,
      SavedErrorCode.targetUnavailable ||
      SavedErrorCode.targetTypeUnsupported =>
        l10n.savedBookmarkUnavailableTooltip,
      SavedErrorCode.platformPersonalDataLocked => l10n.savedErrorPolicyLocked,
      SavedErrorCode.temporarilyUnavailable ||
      SavedErrorCode.dependencyUnavailable => l10n.savedErrorNetwork,
      _ => l10n.savedErrorGeneric,
    };
  }
  if (error is DioException && error.response == null) {
    return l10n.savedErrorNetwork;
  }
  return l10n.savedErrorGeneric;
}

bool isSavedTargetUnavailableError(Object error) {
  return error is SavedApiException &&
      error.error?.code == SavedErrorCode.targetUnavailable;
}

bool isSavedErrorRetryable(Object error) {
  if (error is SavedApiException) {
    if (error.cause.response == null &&
        error.cause.type != DioExceptionType.cancel) {
      return true;
    }
    return error.error?.retryable ?? false;
  }
  return error is DioException &&
      error.response == null &&
      error.type != DioExceptionType.cancel;
}

String savedActionMessage(AppLocalizations l10n, SavedUserActionResult result) {
  return switch (result) {
    SavedUserActionResult.pending => l10n.savedActionPending,
    SavedUserActionResult.rejected => l10n.savedActionRejected,
    SavedUserActionResult.expired => l10n.savedActionExpired,
    SavedUserActionResult.superseded => l10n.savedErrorGeneric,
    SavedUserActionResult.applied || SavedUserActionResult.noOp => '',
  };
}
