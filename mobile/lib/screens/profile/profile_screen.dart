import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/android_back_swipe_scope.dart';
import '../../features/profile/data/profile_api.dart';
import '../../features/profile/models/user_profile_vm.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/session_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.initialProfile});

  final String? userId;
  final UserProfileVm? initialProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApi _profileApi = ProfileApi();

  Future<UserProfileVm>? _foreignProfileFuture;

  @override
  void initState() {
    super.initState();
    _configureForeignProfileFuture();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.initialProfile?.userId != widget.initialProfile?.userId) {
      _configureForeignProfileFuture();
    }
  }

  void _configureForeignProfileFuture() {
    final userId = widget.userId?.trim() ?? '';
    if (userId.isEmpty) {
      _foreignProfileFuture = null;
      return;
    }

    final initialProfile = widget.initialProfile;
    if (initialProfile != null && initialProfile.userId == userId) {
      _foreignProfileFuture = Future<UserProfileVm>.value(initialProfile);
      return;
    }

    _foreignProfileFuture = _profileApi.getUserById(userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = context.watch<SessionProvider>();
    final requestedUserId = widget.userId?.trim() ?? '';
    final currentUserId = session.profile?.userId.trim() ?? '';
    final isOwnProfile =
        requestedUserId.isEmpty || requestedUserId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: isOwnProfile
          ? _OwnProfileBody(session: session)
          : FutureBuilder<UserProfileVm>(
              future: _foreignProfileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = snapshot.data;
                if (profile == null) {
                  return Center(child: Text(l10n.profileNotAvailable));
                }

                return _ProfileContent(
                  profile: profile,
                  showAccountContacts: false,
                  showPreferences: false,
                  showMyActivities: false,
                  onEditProfile: null,
                );
              },
            ),
    );
  }
}

class _OwnProfileBody extends StatelessWidget {
  const _OwnProfileBody({required this.session});

  final SessionProvider session;

  @override
  Widget build(BuildContext context) {
    final profile = session.profile;
    final l10n = AppLocalizations.of(context)!;

    if (profile == null) {
      return Center(child: Text(l10n.profileNotAvailable));
    }

    return _ProfileContent(
      profile: profile,
      showAccountContacts: true,
      showPreferences: true,
      showMyActivities: true,
      onEditProfile: () async {
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                const AndroidBackSwipeScope(child: EditProfileScreen()),
          ),
        );

        if (updated == true && context.mounted) {
          await context.read<SessionProvider>().reloadProfile();
        }
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.showAccountContacts,
    required this.showPreferences,
    required this.showMyActivities,
    required this.onEditProfile,
  });

  final UserProfileVm profile;
  final bool showAccountContacts;
  final bool showPreferences;
  final bool showMyActivities;
  final Future<void> Function()? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = onEditProfile != null;
    final bio = (profile.bio ?? '').trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (canEdit && !profile.isProfileCompleted) ...[
          Card(
            color: const Color(0xFF2A1F0A),
            child: ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
              ),
              title: Text(l10n.profileIncompleteTitle),
              subtitle: Text(l10n.profileIncompleteDescription),
              trailing: TextButton(
                onPressed: onEditProfile,
                child: Text(l10n.fillNowButton),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Center(child: CircleAvatar(radius: 42, child: Text(profile.initials))),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.preferredName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(bio, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (showAccountContacts) ...[
          ListTile(
            title: Text(l10n.profilePhone),
            subtitle: Text(profile.primaryPhone ?? l10n.notSpecified),
          ),
          ListTile(
            title: Text(l10n.profileEmail),
            subtitle: Text(profile.primaryEmail ?? l10n.notSpecified),
          ),
        ],
        ListTile(
          title: Text(l10n.profileVisibility),
          subtitle: Text(
            profile.isPublic ? l10n.profilePublic : l10n.profilePrivate,
          ),
        ),
        ListTile(
          title: Text(l10n.profileLocale),
          subtitle: Text(profile.locale),
        ),
        ListTile(
          title: Text(l10n.profileTimezone),
          subtitle: Text(profile.timezone),
        ),
        if ((profile.countryCode ?? '').trim().isNotEmpty)
          ListTile(
            title: Text(l10n.profileCountry),
            subtitle: Text(profile.countryCode!),
          ),
        if ((profile.currency ?? '').trim().isNotEmpty)
          ListTile(
            title: Text(l10n.profileCurrency),
            subtitle: Text(profile.currency!),
          ),
        if (showPreferences) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(l10n.appLanguageTitle),
              subtitle: Text(
                _languageLabel(
                  context.watch<LocaleProvider>().locale.languageCode,
                ),
              ),
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
        ],
        if (showMyActivities) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: Text(l10n.myActivitiesTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/me/activities'),
            ),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.editProfileButton),
          ),
        ],
      ],
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
