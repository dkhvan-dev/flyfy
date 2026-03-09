import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/locale_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        final profile = session.profile;

        if (profile == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.profileTitle),
            ),
            body: Center(
              child: Text(l10n.profileNotAvailable),
            ),
          );
        }

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
                    if (!profile.isProfileCompleted) ...[
                      Card(
                        color: const Color(0xFF2A1F0A),
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                          title: Text(l10n.profileIncompleteTitle),
                          subtitle: Text(l10n.profileIncompleteDescription),
                          trailing: TextButton(
                            onPressed: () async {
                              final updated = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );

                              if (updated == true && context.mounted) {
                                await context.read<SessionProvider>().reloadProfile();
                              }
                            },
                            child: Text(l10n.fillNowButton),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                        textAlign: TextAlign.center,
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
                    Card(
                      child: ListTile(
                        title: Text(l10n.appLanguageTitle),
                        subtitle: Text(_languageLabel(context.watch<LocaleProvider>().locale.languageCode)),
                        trailing: DropdownButton<String>(
                          value: context.watch<LocaleProvider>().locale.languageCode,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 'ru', child: Text('Русский')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await context.read<LocaleProvider>().setLocale(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );

                        if (updated == true && context.mounted) {
                          await context.read<SessionProvider>().reloadProfile();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.editProfileButton),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'kk':
        return 'Қазақша';
      case 'ru':
      default:
        return 'Русский';
    }
  }
}