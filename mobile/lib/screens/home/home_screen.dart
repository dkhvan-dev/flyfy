import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.logoutDialogTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutDialogMessage,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.logoutConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      await context.read<SessionProvider>().clearSession();

      if (context.mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    void _openProtectedRoute(BuildContext context, String route) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.state == AuthState.authenticated;

      if (isLoggedIn) {
        context.push(route);
      } else {
        context.push('/login');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Consumer2<AuthProvider, SessionProvider>(
          builder: (context, auth, session, _) {
            final isLoggedIn = auth.state == AuthState.authenticated;
            final profile = session.profile;

            if (!isLoggedIn) {
              return Text(
                l10n.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            final userName = profile?.preferredName ?? l10n.userFallbackName;
            final initials = profile?.initials ?? 'F';

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => context.push('/profile'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF00BCD4).withOpacity(0.2),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.welcomeUser(userName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          l10n.openProfileHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isLoggedIn = auth.state == AuthState.authenticated;

              if (isLoggedIn) {
                return IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    _confirmLogout(context);
                  },
                );
              }

              return TextButton(
                onPressed: () {
                  context.push('/login');
                },
                child: Text(
                  l10n.loginButton,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF1565C0)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeWelcomeBack, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.homeTravelQuestion, 
                      style: TextStyle(fontSize: 16, color: Colors.white70)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.homeExploreServices, 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _ServiceCard(
                      title: l10n.serviceTours,
                      icon: Icons.map,
                      color: const Color(0xFF00838F),
                      onTap: () => _openProtectedRoute(context, '/services/tours'),
                    ),
                    _ServiceCard(
                      title: l10n.serviceGuides,
                      icon: Icons.person,
                      color: const Color(0xFFF57F17),
                      onTap: () => _openProtectedRoute(context, '/services/guides'),
                    ),
                    _ServiceCard(
                      title: l10n.serviceHotels,
                      icon: Icons.hotel,
                      color: const Color(0xFFC62828),
                      onTap: () => _openProtectedRoute(context, '/services/hotels'),
                    ),
                    _ServiceCard(
                      title: l10n.serviceTransport,
                      icon: Icons.local_taxi,
                      color: const Color(0xFF283593),
                      onTap: () => _openProtectedRoute(context, '/services/transport'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
