import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../screens/profile/edit_profile_screen.dart';
import 'profile_guard_result.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

class ProfileCompletionGate {
  const ProfileCompletionGate._();

  static Future<ProfileGuardResult> ensureCompleted(
    BuildContext context, {
    bool forceReloadProfile = false,
  }) async {
    final session = context.read<SessionProvider>();

    if (forceReloadProfile) {
      await session.reloadProfile();
    }

    final profile = session.profile;
    if (profile == null) {
      return ProfileGuardResult.cancelled;
    }

    if (profile.isProfileCompleted) {
      return ProfileGuardResult.allowed;
    }

    if (!context.mounted) {
      return ProfileGuardResult.cancelled;
    }

    final shouldOpen = await _showIncompleteProfileDialog(context);
    if (!context.mounted) {
      return ProfileGuardResult.cancelled;
    }

    if (shouldOpen != true) {
      return ProfileGuardResult.cancelled;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AndroidBackSwipeScope(child: EditProfileScreen()),
      ),
    );

    if (!context.mounted) {
      return ProfileGuardResult.cancelled;
    }

    if (updated == true) {
      await context.read<SessionProvider>().reloadProfile();
    }

    if (!context.mounted) {
      return ProfileGuardResult.cancelled;
    }

    final refreshedProfile = context.read<SessionProvider>().profile;
    if (refreshedProfile != null && refreshedProfile.isProfileCompleted) {
      return ProfileGuardResult.redirectedToEditProfile;
    }

    return ProfileGuardResult.cancelled;
  }

  static Future<bool?> _showIncompleteProfileDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return showAppModalDialog<bool>(
      context: context,
      title: l10n.profileRequiredTitle,
      subtitle: l10n.profileRequiredDescription,
      icon: Icons.manage_accounts_rounded,
      actions: [
        AppModalAction<bool>(label: l10n.laterButton, result: false),
        AppModalAction<bool>(
          label: l10n.fillNowButton,
          result: true,
          variant: AppModalActionVariant.primary,
        ),
      ],
    );
  }
}
