import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'profile_style.dart';

class ProfileSecurityScreen extends StatelessWidget {
  const ProfileSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final padding = profileScaled(context, 20, min: 14, max: 20);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: ProfileResponsiveScope(
          child: DecoratedBox(
            decoration: AppBoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.screenGradientColors,
              ),
            ),
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: AppEdgeInsets.fromLTRB(
                  padding,
                  profileScaled(context, 14, min: 10, max: 18),
                  padding,
                  profileScaled(context, 28, min: 20, max: 34),
                ),
                children: [
                  const _SecurityTopBar(),
                  SizedBox(
                    height: profileScaled(context, 24, min: 18, max: 28),
                  ),
                  _SecurityHero(
                    title: l10n.profileSecurityHeroTitle,
                    subtitle: l10n.profileSecurityHeroSubtitle,
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  _SecuritySectionHeading(
                    title: l10n.profileSecurityAccountSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 16, min: 12, max: 18),
                  ),
                  _SecurityInfoTile(
                    icon: Icons.lock_reset_rounded,
                    title: l10n.profileSecurityPasswordTitle,
                    subtitle: l10n.profileSecurityPasswordSubtitle,
                    statusLabel: l10n.profileSecurityPasswordAction,
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                  _SecurityInfoTile(
                    icon: Icons.verified_user_outlined,
                    title: l10n.profileSecurityTwoFactorTitle,
                    subtitle: l10n.profileSecurityTwoFactorSubtitle,
                    statusLabel: l10n.profileDisabledSoon,
                    disabled: true,
                  ),
                  SizedBox(
                    height: profileScaled(context, 28, min: 24, max: 32),
                  ),
                  _SecuritySectionHeading(
                    title: l10n.profileSecurityDataSection,
                  ),
                  SizedBox(
                    height: profileScaled(context, 16, min: 12, max: 18),
                  ),
                  _SecurityInfoTile(
                    icon: Icons.download_outlined,
                    title: l10n.profileSecurityDataExportTitle,
                    subtitle: l10n.profileSecurityDataExportSubtitle,
                    statusLabel: l10n.profileDisabledSoon,
                    disabled: true,
                  ),
                  _SecurityInfoTile(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.profileSecurityDeleteTitle,
                    subtitle: l10n.profileSecurityDeleteSubtitle,
                    statusLabel: l10n.profileDisabledSoon,
                    disabled: true,
                    danger: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showChangePasswordSheet(BuildContext context) {
  final colors = AppDesignSystem.colorsFor(context);
  showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    useSafeArea: false,
    backgroundColor: colors.transparent,
    builder: (context) {
      return const _ChangePasswordSheet();
    },
  );
}

class _SecurityTopBar extends StatelessWidget {
  const _SecurityTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Row(
      children: [
        _SecurityBackButton(icon: Icons.arrow_back, onTap: () => context.pop()),
        Expanded(
          child: Padding(
            padding: AppEdgeInsets.symmetric(
              horizontal: profileScaled(context, 12, min: 8, max: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.profileSecurityPageTitle,
              textAlign: TextAlign.center,
              style: AppTextStyle(
                color: colors.textPrimary,
                fontSize: profileScaled(context, 18, min: 16, max: 20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(width: profileScaled(context, 38, min: 34, max: 40)),
      ],
    );
  }
}

class _SecurityBackButton extends StatelessWidget {
  const _SecurityBackButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final size = profileScaled(context, 38, min: 34, max: 40);
    final iconSize = profileScaled(context, 20, min: 18, max: 20);

    return Material(
      color: colors.surfaceRaised,
      shape: CircleBorder(side: BorderSide(color: colors.borderSoft)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: iconSize, color: colors.textPrimary),
        ),
      ),
    );
  }
}

class _SecuritySectionHeading extends StatelessWidget {
  const _SecuritySectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Text(
      title,
      style: AppTextStyle(
        color: colors.textPrimary,
        fontSize: profileScaled(context, 18, min: 16, max: 22),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 22, min: 18, max: 24)),
      decoration: _securityCardDecoration(
        context,
        colors,
        highlighted: true,
        radius: profileScaled(context, 28, min: 22, max: 30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: profileScaled(context, 54, min: 48, max: 58),
            height: profileScaled(context, 54, min: 48, max: 58),
            decoration: AppBoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: AppBorderRadius.circular(
                profileScaled(context, 18, min: 14, max: 20),
              ),
            ),
            child: Icon(
              Icons.security_rounded,
              color: colors.primary,
              size: profileScaled(context, 26, min: 22, max: 28),
            ),
          ),
          SizedBox(width: profileScaled(context, 16, min: 12, max: 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: profileScaled(context, 20, min: 18, max: 22),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: profileScaled(context, 8, min: 6, max: 8)),
                Text(
                  subtitle,
                  style: AppTextStyle(
                    color: colors.textSecondary,
                    fontSize: profileScaled(context, 14, min: 13, max: 15),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityInfoTile extends StatelessWidget {
  const _SecurityInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.onTap,
    this.disabled = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final VoidCallback? onTap;
  final bool disabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);
    final accentColor = danger ? colors.danger : colors.primary;
    final radius = profileScaled(context, 22, min: 18, max: 24);
    final isActionable = onTap != null && !disabled;

    return Padding(
      padding: AppEdgeInsets.only(
        bottom: profileScaled(context, 14, min: 10, max: 14),
      ),
      child: Container(
        decoration: _securityCardDecoration(
          context,
          colors,
          disabled: disabled,
          radius: radius,
        ),
        child: Material(
          color: colors.transparent,
          borderRadius: AppBorderRadius.circular(radius),
          child: InkWell(
            borderRadius: AppBorderRadius.circular(radius),
            onTap: isActionable ? onTap : null,
            child: Padding(
              padding: AppEdgeInsets.all(
                profileScaled(context, 18, min: 14, max: 20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: profileScaled(context, 46, min: 40, max: 48),
                    height: profileScaled(context, 46, min: 40, max: 48),
                    decoration: AppBoxDecoration(
                      color: accentColor.withValues(
                        alpha: disabled ? 0.06 : 0.14,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  SizedBox(width: profileScaled(context, 14, min: 12, max: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle(
                            color: disabled
                                ? colors.textDisabled
                                : colors.textPrimary,
                            fontSize: profileScaled(
                              context,
                              16,
                              min: 14,
                              max: 17,
                            ),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: profileScaled(context, 6, min: 4, max: 6),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyle(
                            color: disabled
                                ? colors.textDisabled
                                : colors.textSecondary,
                            fontSize: profileScaled(
                              context,
                              13,
                              min: 12,
                              max: 13,
                            ),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
                  if (isActionable)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accentColor,
                      size: profileScaled(context, 24, min: 22, max: 26),
                    )
                  else
                    _StatusTag(
                      label: statusLabel,
                      color: accentColor,
                      disabled: disabled,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  static const int _changePasswordCooldownSeconds = 60;

  final _currentPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _resendCooldownTimer;
  int _resendRemainingSeconds = 0;
  bool _codeSent = false;
  bool _showValidation = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _currentPasswordController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendChangePasswordCode() async {
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);

    final validationError = _firstPasswordChangeValidationError(
      requireCode: false,
    );
    if (validationError != null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.startPasswordChange(
      _currentPasswordController.text,
    );
    if (!mounted) return;

    if (success) {
      setState(() {
        _codeSent = true;
        _showValidation = false;
      });
      _startResendCooldown();
      return;
    }

    _showError(auth.errorMessage);
  }

  Future<void> _verifyPasswordChange() async {
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);

    final validationError = _firstPasswordChangeValidationError(
      requireCode: true,
    );
    if (validationError != null) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyPasswordChange(
      _currentPasswordController.text,
      _codeController.text,
      _newPasswordController.text,
    );
    if (!mounted) return;

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final successMessage = AppLocalizations.of(
        context,
      )!.profileSecurityPasswordSuccess;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }

    await _showError(auth.errorMessage);
  }

  Future<void> _showError(String? message) {
    final l10n = AppLocalizations.of(context)!;
    return showErrorDialog(
      context,
      title: l10n.error,
      message: (message ?? '').trim().isEmpty
          ? l10n.profileSecurityPasswordChangeFailed
          : message!.trim(),
    );
  }

  String? _firstPasswordChangeValidationError({required bool requireCode}) {
    final l10n = AppLocalizations.of(context)!;
    if (_currentPasswordController.text.trim().isEmpty) {
      return l10n.passwordRequiredError;
    }
    if (requireCode && _codeController.text.trim().isEmpty) {
      return l10n.passwordResetCodeRequiredError;
    }
    if (!_passwordLooksStrong(_newPasswordController.text)) {
      return l10n.passwordWeakError;
    }
    if (_newPasswordController.text.trim() ==
        _currentPasswordController.text.trim()) {
      return l10n.profileSecurityPasswordUnchangedError;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      return l10n.profileSecurityPasswordMismatchError;
    }
    return null;
  }

  bool _passwordLooksStrong(String password) {
    final trimmed = password.trim();
    if (trimmed.length < 8 || trimmed.length > 128) {
      return false;
    }
    final hasLetter = trimmed.runes.any((rune) {
      final char = String.fromCharCode(rune);
      return char.toLowerCase() != char.toUpperCase();
    });
    final hasDigit = RegExp(r'\d').hasMatch(trimmed);
    return hasLetter && hasDigit;
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendRemainingSeconds = _changePasswordCooldownSeconds;
    });
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendRemainingSeconds <= 1) {
        timer.cancel();
        setState(() => _resendRemainingSeconds = 0);
        return;
      }
      setState(() => _resendRemainingSeconds--);
    });
  }

  String _formatResendCountdown() {
    final minutes = _resendRemainingSeconds ~/ 60;
    final seconds = _resendRemainingSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final colors = AppDesignSystem.colorsFor(context);
    final isLoading = auth.isPasswordChangeLoading;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - bottomInset;
    final canResendPasswordChangeCode =
        _codeSent && !isLoading && _resendRemainingSeconds == 0;
    final validationError = _showValidation
        ? _firstPasswordChangeValidationError(requireCode: _codeSent)
        : null;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: ProfileResponsiveScope(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: AppEdgeInsets.only(bottom: bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    maxHeight: availableHeight * 0.92,
                  ),
                  child: DecoratedBox(
                    decoration: AppBoxDecoration(
                      color: colors.surface,
                      borderRadius: AppBorderRadius.vertical(
                        top: AppRadiusValue.circular(
                          profileScaled(context, 28, min: 22, max: 30),
                        ),
                      ),
                      border: Border.all(color: colors.border),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: AppEdgeInsets.fromLTRB(
                                profileScaled(context, 20, min: 16, max: 24),
                                profileScaled(context, 14, min: 12, max: 18),
                                profileScaled(context, 20, min: 16, max: 24),
                                profileScaled(context, 16, min: 12, max: 18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: profileScaled(
                                        context,
                                        42,
                                        min: 36,
                                        max: 46,
                                      ),
                                      height: 4,
                                      decoration: AppBoxDecoration(
                                        color: colors.textSecondary.withValues(
                                          alpha: 0.45,
                                        ),
                                        borderRadius: AppBorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: profileScaled(
                                      context,
                                      18,
                                      min: 14,
                                      max: 22,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.profileSecurityPasswordSheetTitle,
                                          style: AppTextStyle(
                                            color: colors.textPrimary,
                                            fontSize: profileScaled(
                                              context,
                                              22,
                                              min: 19,
                                              max: 24,
                                            ),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: isLoading
                                            ? null
                                            : () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close_rounded),
                                        color: colors.primary,
                                        tooltip: MaterialLocalizations.of(
                                          context,
                                        ).closeButtonTooltip,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: profileScaled(
                                      context,
                                      8,
                                      min: 6,
                                      max: 10,
                                    ),
                                  ),
                                  Text(
                                    l10n.profileSecurityPasswordSheetSubtitle,
                                    style: AppTextStyle(
                                      color: colors.textSecondary,
                                      fontSize: profileScaled(
                                        context,
                                        14,
                                        min: 13,
                                        max: 15,
                                      ),
                                      height: 1.45,
                                    ),
                                  ),
                                  SizedBox(
                                    height: profileScaled(
                                      context,
                                      22,
                                      min: 18,
                                      max: 26,
                                    ),
                                  ),
                                  _PasswordField(
                                    controller: _currentPasswordController,
                                    label: l10n
                                        .profileSecurityPasswordCurrentLabel,
                                    hint:
                                        l10n.profileSecurityPasswordCurrentHint,
                                    enabled: !isLoading,
                                    obscureText: _obscureCurrentPassword,
                                    textInputAction: TextInputAction.next,
                                    errorText:
                                        _showValidation &&
                                            _currentPasswordController.text
                                                .trim()
                                                .isEmpty
                                        ? l10n.passwordRequiredError
                                        : null,
                                    onVisibilityToggle: () => setState(
                                      () => _obscureCurrentPassword =
                                          !_obscureCurrentPassword,
                                    ),
                                  ),
                                  SizedBox(
                                    height: profileScaled(
                                      context,
                                      14,
                                      min: 12,
                                      max: 16,
                                    ),
                                  ),
                                  _PasswordField(
                                    controller: _newPasswordController,
                                    label: l10n.profileSecurityPasswordNewLabel,
                                    hint: l10n.passwordHint,
                                    enabled: !isLoading,
                                    obscureText: _obscureNewPassword,
                                    textInputAction: TextInputAction.next,
                                    errorText:
                                        _showValidation &&
                                            !_passwordLooksStrong(
                                              _newPasswordController.text,
                                            )
                                        ? l10n.passwordWeakError
                                        : _showValidation &&
                                              _newPasswordController.text
                                                      .trim() ==
                                                  _currentPasswordController
                                                      .text
                                                      .trim() &&
                                              _newPasswordController.text
                                                  .trim()
                                                  .isNotEmpty
                                        ? l10n.profileSecurityPasswordUnchangedError
                                        : null,
                                    onVisibilityToggle: () => setState(
                                      () => _obscureNewPassword =
                                          !_obscureNewPassword,
                                    ),
                                  ),
                                  SizedBox(
                                    height: profileScaled(
                                      context,
                                      14,
                                      min: 12,
                                      max: 16,
                                    ),
                                  ),
                                  _PasswordField(
                                    controller: _confirmPasswordController,
                                    label: l10n
                                        .profileSecurityPasswordConfirmLabel,
                                    hint: l10n
                                        .profileSecurityPasswordConfirmLabel,
                                    enabled: !isLoading,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: _codeSent
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    errorText:
                                        _showValidation &&
                                            _newPasswordController.text !=
                                                _confirmPasswordController.text
                                        ? l10n.profileSecurityPasswordMismatchError
                                        : null,
                                    onVisibilityToggle: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                    onSubmitted: (_) {
                                      if (isLoading) {
                                        return;
                                      }
                                      if (_codeSent) {
                                        _verifyPasswordChange();
                                      } else {
                                        _sendChangePasswordCode();
                                      }
                                    },
                                  ),
                                  if (_codeSent) ...[
                                    SizedBox(
                                      height: profileScaled(
                                        context,
                                        14,
                                        min: 12,
                                        max: 16,
                                      ),
                                    ),
                                    _InfoBanner(
                                      text: l10n
                                          .profileSecurityPasswordCodeNotice,
                                    ),
                                    SizedBox(
                                      height: profileScaled(
                                        context,
                                        14,
                                        min: 12,
                                        max: 16,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _codeController,
                                      enabled: !isLoading,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode,
                                      ],
                                      decoration: _sheetInputDecoration(
                                        context,
                                        label: l10n.passwordResetCodeLabel,
                                        hint: l10n.passwordResetCodeHint,
                                        errorText:
                                            _showValidation &&
                                                _codeController.text
                                                    .trim()
                                                    .isEmpty
                                            ? l10n.passwordResetCodeRequiredError
                                            : null,
                                      ),
                                    ),
                                  ],
                                  if (validationError != null) ...[
                                    SizedBox(
                                      height: profileScaled(
                                        context,
                                        12,
                                        min: 10,
                                        max: 14,
                                      ),
                                    ),
                                    Text(
                                      validationError,
                                      style: AppTextStyle(
                                        color: colors.danger,
                                        fontSize: profileScaled(
                                          context,
                                          12,
                                          min: 11,
                                          max: 13,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          _PasswordChangeActions(
                            isLoading: isLoading,
                            codeSent: _codeSent,
                            resendRemainingSeconds: _resendRemainingSeconds,
                            resendCountdown: _formatResendCountdown(),
                            onPrimaryPressed: isLoading
                                ? null
                                : _codeSent
                                ? _verifyPasswordChange
                                : _sendChangePasswordCode,
                            onResendPressed: canResendPasswordChangeCode
                                ? _sendChangePasswordCode
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PasswordChangeActions extends StatelessWidget {
  const _PasswordChangeActions({
    required this.isLoading,
    required this.codeSent,
    required this.resendRemainingSeconds,
    required this.resendCountdown,
    required this.onPrimaryPressed,
    required this.onResendPressed,
  });

  final bool isLoading;
  final bool codeSent;
  final int resendRemainingSeconds;
  final String resendCountdown;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onResendPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return DecoratedBox(
      decoration: AppBoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSoft)),
      ),
      child: Padding(
        padding: AppEdgeInsets.fromLTRB(
          profileScaled(context, 20, min: 16, max: 24),
          profileScaled(context, 12, min: 10, max: 14),
          profileScaled(context, 20, min: 16, max: 24),
          profileScaled(context, 16, min: 14, max: 20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: onPrimaryPressed,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textPrimary,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                disabledForegroundColor: colors.textDisabled,
                padding: AppEdgeInsets.symmetric(
                  vertical: profileScaled(context, 15, min: 13, max: 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.circular(
                    profileScaled(context, 16, min: 14, max: 18),
                  ),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: profileScaled(context, 20, min: 18, max: 22),
                      height: profileScaled(context, 20, min: 18, max: 22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.textPrimary,
                      ),
                    )
                  : Text(
                      codeSent
                          ? l10n.profileSecurityPasswordSave
                          : l10n.profileSecurityPasswordSendCode,
                      style: const AppTextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
            if (codeSent) ...[
              SizedBox(height: profileScaled(context, 8, min: 6, max: 10)),
              TextButton(
                onPressed: onResendPressed,
                child: Text(
                  resendRemainingSeconds > 0
                      ? l10n.profileSecurityPasswordResendCodeCountdown(
                          resendCountdown,
                        )
                      : l10n.passwordResetResendCodeAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.obscureText,
    required this.onVisibilityToggle,
    this.textInputAction,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final bool obscureText;
  final VoidCallback onVisibilityToggle;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: onSubmitted,
      decoration: _sheetInputDecoration(
        context,
        label: label,
        hint: hint,
        errorText: errorText,
        suffixIcon: IconButton(
          onPressed: enabled ? onVisibilityToggle : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          tooltip: obscureText ? l10n.authShowPassword : l10n.authHidePassword,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: AppEdgeInsets.all(profileScaled(context, 14, min: 12, max: 16)),
      decoration: AppBoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: AppBorderRadius.circular(
          profileScaled(context, 16, min: 14, max: 18),
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: colors.primary,
            size: profileScaled(context, 20, min: 18, max: 22),
          ),
          SizedBox(width: profileScaled(context, 10, min: 8, max: 12)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle(
                color: colors.textSecondary,
                fontSize: profileScaled(context, 13, min: 12, max: 14),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _sheetInputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  String? errorText,
  Widget? suffixIcon,
}) {
  final colors = AppDesignSystem.colorsFor(context);
  final radius = AppBorderRadius.circular(
    profileScaled(context, 16, min: 14, max: 18),
  );
  return AppInputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: colors.surfaceRaised,
    labelStyle: AppTextStyle(color: colors.textSecondary),
    hintStyle: AppTextStyle(
      color: colors.textSecondary.withValues(alpha: 0.72),
    ),
    errorStyle: AppTextStyle(color: colors.danger, fontWeight: FontWeight.w700),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.7)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.danger),
    ),
  );
}

BoxDecoration _securityCardDecoration(
  BuildContext context,
  AppColors colors, {
  bool highlighted = false,
  bool disabled = false,
  double? radius,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = disabled
      ? colors.borderSoft
      : highlighted
      ? colors.borderPrimary
      : colors.border;

  return AppBoxDecoration(
    color: disabled ? colors.surfaceRaised : colors.surface,
    borderRadius: AppBorderRadius.circular(
      radius ?? profileScaled(context, 22, min: 18, max: 24),
    ),
    border: Border.all(color: borderColor),
    boxShadow: isDark && !disabled
        ? [
            BoxShadow(
              color: colors.black.withValues(alpha: highlighted ? 0.26 : 0.18),
              blurRadius: profileScaled(context, 20, min: 14, max: 24),
              offset: Offset(0, profileScaled(context, 8, min: 5, max: 10)),
            ),
          ]
        : const [],
  );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.color,
    required this.disabled,
  });

  final String label;
  final Color color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppDesignSystem.colorsFor(context);

    return Container(
      padding: AppEdgeInsets.symmetric(
        horizontal: profileScaled(context, 12, min: 10, max: 14),
        vertical: profileScaled(context, 7, min: 6, max: 8),
      ),
      decoration: AppBoxDecoration(
        color: color.withValues(alpha: disabled ? 0.04 : 0.12),
        borderRadius: AppBorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: disabled ? 0.05 : 0.18),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyle(
          color: disabled ? colors.textDisabled : color,
          fontSize: profileScaled(context, 11, min: 10, max: 12),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
