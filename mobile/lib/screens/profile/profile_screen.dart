import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        final profile = session.profile;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.profileTitle),
          ),
          body: profile == null
              ? Center(
                  child: Text(l10n.profileNotAvailable),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 42,
                        child: Text(profile.initials),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        profile.preferredName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: Text(l10n.profilePhone),
                      subtitle: Text(profile.primaryPhone ?? l10n.notSpecified),
                    ),
                    ListTile(
                      title: Text(l10n.profileEmail),
                      subtitle: Text(profile.primaryEmail ?? l10n.notSpecified),
                    ),
                    ListTile(
                      title: Text(l10n.profileLocale),
                      subtitle: Text(profile.locale),
                    ),
                    ListTile(
                      title: Text(l10n.profileTimezone),
                      subtitle: Text(profile.timezone),
                    ),
                  ],
                ),
        );
      },
    );
  }
}