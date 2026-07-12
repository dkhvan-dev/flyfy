import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:provider/provider.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/app_preferences_section.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated =
        context.watch<AuthProvider>().state == AuthState.authenticated;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        key: const ValueKey('app-settings-screen'),
        backgroundColor: colors.background,
        body: DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _AppSettingsHeader(title: l10n.profileSettingsPageTitle),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth < 360
                          ? 16.0
                          : 20.0;
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: AppEdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          32,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!isAuthenticated) ...[
                                    _SettingsSectionTitle(
                                      title: l10n.profileAccountSectionTitle,
                                    ),
                                    const SizedBox(height: 14),
                                    const _GuestAccountActions(),
                                    const SizedBox(height: 30),
                                  ],
                                  _SettingsSectionTitle(
                                    title: l10n.profilePreferencesTitle,
                                  ),
                                  const SizedBox(height: 14),
                                  const AppPreferencesSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSettingsHeader extends StatelessWidget {
  const _AppSettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const AppEdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppBoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSoft)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('app-settings-back-button'),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    return Text(
      title,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GuestAccountActions extends StatelessWidget {
  const _GuestAccountActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final loginButton = FilledButton.icon(
      key: const ValueKey('app-settings-login-button'),
      onPressed: () => context.push('/login?mode=login'),
      icon: const Icon(Icons.login_rounded),
      label: Text(l10n.authLoginAction),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
    );
    final registerButton = OutlinedButton.icon(
      key: const ValueKey('app-settings-register-button'),
      onPressed: () => context.push('/login?mode=register'),
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: Text(l10n.authRegisterAction),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.borderPrimary),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 430 || textScale > 1.1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [loginButton, const SizedBox(height: 10), registerButton],
          );
        }

        return Row(
          children: [
            Expanded(child: loginButton),
            const SizedBox(width: 12),
            Expanded(child: registerButton),
          ],
        );
      },
    );
  }
}
