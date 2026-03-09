import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../screens/profile/edit_profile_screen.dart';
import 'profile_guard_result.dart';

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
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (!context.mounted) {
      return ProfileGuardResult.cancelled;
    }

    if (updated == true) {
      await context.read<SessionProvider>().reloadProfile();
    }

    final refreshedProfile = context.read<SessionProvider>().profile;
    if (refreshedProfile != null && refreshedProfile.isProfileCompleted) {
      return ProfileGuardResult.redirectedToEditProfile;
    }

    return ProfileGuardResult.cancelled;
  }

  static Future<bool?> _showIncompleteProfileDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.profileRequiredTitle),
          content: Text(l10n.profileRequiredDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.laterButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.fillNowButton),
            ),
          ],
        );
      },
    );
  }
}