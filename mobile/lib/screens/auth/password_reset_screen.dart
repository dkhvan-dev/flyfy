import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'auth_responsive.dart';

enum _PasswordResetStep { request, verify }

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  static const int _resendCooldownSeconds = 60;

  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _identifierFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  _PasswordResetStep _step = _PasswordResetStep.request;
  bool _showRequestValidation = false;
  bool _showVerifyValidation = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _resendCooldownTimer;
  int _resendRemainingSeconds = 0;
  String? _notice;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _identifierController,
      _codeController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFormChanged);
    }
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    for (final controller in [
      _identifierController,
      _codeController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_handleFormChanged);
      controller.dispose();
    }
    _identifierFocusNode.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submitIdentifier() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    setState(() => _showRequestValidation = true);

    final identifierError = _identifierValidationMessage(l10n);
    if (identifierError != null) {
      _identifierFocusNode.requestFocus();
      return;
    }

    final identifier = _identifierController.text.trim();
    final auth = ctx.read<AuthProvider>();
    final success = await auth.startPasswordReset(identifier);

    if (!ctx.mounted) return;
    if (success) {
      _dismissKeyboardBeforeStepChange();
      setState(() {
        _step = _PasswordResetStep.verify;
        _notice = l10n.passwordResetSentNotice;
        _showVerifyValidation = false;
      });
      _startResendCooldown();
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: auth.errorMessage ?? l10n.passwordResetStartFailed,
    );
  }

  void _dismissKeyboardBeforeStepChange() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendRemainingSeconds = _resendCooldownSeconds;
    });
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendRemainingSeconds == 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendRemainingSeconds -= 1;
      });
    });
  }

  String _formatResendCountdown() {
    final minutes = _resendRemainingSeconds ~/ 60;
    final seconds = _resendRemainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendPasswordResetCode() async {
    if (_resendRemainingSeconds > 0) return;
    _codeController.clear();
    await _submitIdentifier();
  }

  Future<void> _submitNewPassword() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    setState(() => _showVerifyValidation = true);

    final codeError = _codeValidationMessage(l10n);
    final passwordError = _passwordValidationMessage(
      l10n,
      _passwordController.text,
    );
    final confirmError = _confirmPasswordValidationMessage(l10n);
    if (codeError != null) {
      _codeFocusNode.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocusNode.requestFocus();
      return;
    }
    if (confirmError != null) {
      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    final auth = ctx.read<AuthProvider>();
    final success = await auth.verifyPasswordReset(
      _identifierController.text.trim(),
      _codeController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!ctx.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordResetSuccess)));
      ctx.go('/login');
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: auth.errorMessage ?? l10n.passwordResetVerifyFailed,
    );
  }

  String? _identifierValidationMessage(AppLocalizations l10n) {
    if (_identifierController.text.trim().isEmpty) {
      return l10n.passwordResetIdentifierRequiredError;
    }
    return null;
  }

  String? _codeValidationMessage(AppLocalizations l10n) {
    if (_codeController.text.trim().isEmpty) {
      return l10n.passwordResetCodeRequiredError;
    }
    return null;
  }

  String? _passwordValidationMessage(AppLocalizations l10n, String value) {
    final password = value.trim();
    if (password.isEmpty) {
      return l10n.passwordRequiredError;
    }
    if (password.length < 8 ||
        !RegExp(r'[A-Za-zА-Яа-я]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return l10n.passwordWeakError;
    }
    return null;
  }

  String? _confirmPasswordValidationMessage(AppLocalizations l10n) {
    if (_confirmPasswordController.text.trim().isEmpty) {
      return l10n.passwordRequiredError;
    }
    if (_confirmPasswordController.text.trim() !=
        _passwordController.text.trim()) {
      return l10n.authPasswordMismatchError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 375;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppPalette.backgroundWarm,
      body: AuthResponsiveTextScope(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = authScaled(
                context,
                isCompact ? 18 : 24,
                min: 16,
                max: 28,
              );
              final verticalPadding = authScaled(context, 22, min: 18, max: 28);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppEdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PasswordResetHeader(
                            title: l10n.passwordResetTitle,
                            onBack: () => context.go('/login'),
                          ),
                          SizedBox(
                            height: authScaled(context, 22, min: 18, max: 24),
                          ),
                          _PasswordResetPanel(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _step == _PasswordResetStep.request
                                  ? _buildRequestStep(context, l10n)
                                  : _buildVerifyStep(context, l10n),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequestStep(BuildContext context, AppLocalizations l10n) {
    final identifierError = _showRequestValidation
        ? _identifierValidationMessage(l10n)
        : null;
    final canSubmit =
        identifierError == null && _identifierController.text.trim().isNotEmpty;

    return _PasswordResetFieldsScrollView(
      key: const ValueKey('password-reset-request'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: l10n.passwordResetIdentifierLabel,
            description: l10n.passwordResetRequestDescription,
          ),
          SizedBox(height: authScaled(context, 18, min: 14, max: 20)),
          _ResetTextField(
            controller: _identifierController,
            focusNode: _identifierFocusNode,
            label: l10n.passwordResetIdentifierLabel,
            hint: l10n.passwordResetIdentifierHint,
            icon: Icons.alternate_email_rounded,
            errorText: identifierError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            onSubmitted: (_) => _submitIdentifier(),
          ),
          SizedBox(height: authScaled(context, 16, min: 14, max: 18)),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => _ResetPrimaryButton(
              label: l10n.passwordResetSendCodeAction,
              icon: Icons.mark_email_read_outlined,
              isLoading: auth.isPasswordResetLoading,
              onPressed: canSubmit ? _submitIdentifier : null,
            ),
          ),
          SizedBox(height: authScaled(context, 12, min: 10, max: 14)),
          _BackToLoginButton(label: l10n.passwordResetBackToLogin),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(BuildContext context, AppLocalizations l10n) {
    final codeError = _showVerifyValidation
        ? _codeValidationMessage(l10n)
        : null;
    final passwordError = _showVerifyValidation
        ? _passwordValidationMessage(l10n, _passwordController.text)
        : null;
    final confirmError = _showVerifyValidation
        ? _confirmPasswordValidationMessage(l10n)
        : null;
    final canSubmit =
        codeError == null &&
        passwordError == null &&
        confirmError == null &&
        _codeController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty;

    return _PasswordResetFieldsScrollView(
      key: const ValueKey('password-reset-verify'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: l10n.passwordResetCodeLabel,
            description: l10n.passwordResetVerifyDescription,
          ),
          if (_notice != null) ...[
            SizedBox(height: authScaled(context, 12, min: 10, max: 12)),
            _NoticeText(text: _notice!),
          ],
          SizedBox(height: authScaled(context, 18, min: 14, max: 20)),
          _ResetTextField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            label: l10n.passwordResetCodeLabel,
            hint: l10n.passwordResetCodeHint,
            icon: Icons.pin_outlined,
            errorText: codeError,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 12),
          _ResetTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: l10n.passwordResetNewPasswordLabel,
            hint: l10n.passwordHint,
            icon: Icons.lock_outline_rounded,
            errorText: passwordError,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ResetTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: l10n.passwordResetConfirmPasswordLabel,
            hint: l10n.passwordHint,
            icon: Icons.check_circle_outline_rounded,
            errorText: confirmError,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submitNewPassword(),
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              onPressed: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          SizedBox(height: authScaled(context, 16, min: 14, max: 18)),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => _ResetPrimaryButton(
              label: l10n.passwordResetSavePasswordAction,
              icon: Icons.check_rounded,
              isLoading: auth.isPasswordResetLoading,
              onPressed: canSubmit ? _submitNewPassword : null,
            ),
          ),
          SizedBox(height: authScaled(context, 10, min: 8, max: 12)),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final canResendPasswordResetCode =
                  _resendRemainingSeconds == 0 && !auth.isPasswordResetLoading;
              final resendLabel = _resendRemainingSeconds > 0
                  ? l10n.passwordResetResendCodeCountdown(
                      _formatResendCountdown(),
                    )
                  : l10n.passwordResetResendCodeAction;

              return TextButton.icon(
                onPressed: canResendPasswordResetCode
                    ? _resendPasswordResetCode
                    : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(resendLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppPalette.primary,
                  disabledForegroundColor: AppPalette.textCaption,
                ),
              );
            },
          ),
          _BackToLoginButton(label: l10n.passwordResetBackToLogin),
        ],
      ),
    );
  }
}

class _PasswordResetHeader extends StatelessWidget {
  const _PasswordResetHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppPalette.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        SizedBox(width: authScaled(context, 8, min: 6, max: 8)),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle(
              color: AppPalette.textPrimary,
              fontSize: authScaled(context, 26, min: 22, max: 28),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordResetPanel extends StatelessWidget {
  const _PasswordResetPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.all(authScaled(context, 24, min: 18, max: 28)),
      decoration: AppBoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.07),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.14)),
        borderRadius: AppBorderRadius.circular(
          authScaled(context, 24, min: 18, max: 24),
        ),
      ),
      child: child,
    );
  }
}

class _PasswordResetFieldsScrollView extends StatelessWidget {
  const _PasswordResetFieldsScrollView({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentWidth = authScaled(context, 312, min: 286, max: 320);
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : minContentWidth;
        final contentWidth = availableWidth < minContentWidth
            ? minContentWidth
            : availableWidth;
        final floatingLabelReserve = authScaled(context, 8, min: 6, max: 8);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: AppEdgeInsets.only(top: floatingLabelReserve),
            child: SizedBox(width: contentWidth, child: child),
          ),
        );
      },
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle(
            color: AppPalette.textPrimary,
            fontSize: authScaled(context, 20, min: 18, max: 22),
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        SizedBox(height: authScaled(context, 8, min: 6, max: 8)),
        Text(
          description,
          style: AppTextStyle(
            color: AppPalette.textCoolSecondary,
            fontSize: authScaled(context, 14, min: 13, max: 15),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _NoticeText extends StatelessWidget {
  const _NoticeText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.symmetric(
        horizontal: authScaled(context, 12, min: 10, max: 12),
        vertical: authScaled(context, 10, min: 8, max: 10),
      ),
      decoration: AppBoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.circular(
          authScaled(context, 12, min: 10, max: 12),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyle(
          color: AppPalette.textPrimary,
          fontSize: authScaled(context, 13, min: 12, max: 14),
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ResetTextField extends StatelessWidget {
  const _ResetTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: 1,
      scrollPhysics: const BouncingScrollPhysics(),
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: const AppTextStyle(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: AppInputDecoration(
        labelText: label,
        labelStyle: const AppTextStyle(color: AppPalette.textCoolSecondary),
        hintText: hint,
        hintStyle: const AppTextStyle(color: AppPalette.textCaption),
        errorText: errorText,
        filled: true,
        fillColor: AppPalette.white.withValues(alpha: 0.05),
        prefixIcon: Icon(icon, color: AppPalette.primary),
        suffixIcon: suffixIcon,
        contentPadding: AppEdgeInsets.symmetric(
          horizontal: authScaled(context, 18, min: 14, max: 18),
          vertical: authScaled(context, 15, min: 13, max: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(
            authScaled(context, 16, min: 14, max: 16),
          ),
          borderSide: BorderSide(
            color: AppPalette.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(
            authScaled(context, 16, min: 14, max: 16),
          ),
          borderSide: BorderSide(
            color: AppPalette.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(
            authScaled(context, 16, min: 14, max: 16),
          ),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ResetPrimaryButton extends StatelessWidget {
  const _ResetPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = authScaled(context, 56, min: 50, max: 56);
    if (isLoading) {
      return Container(
        height: buttonHeight,
        decoration: AppBoxDecoration(
          color: AppPalette.primary,
          borderRadius: AppBorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppPalette.backgroundWarm,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppPalette.textPrimary),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: AppTextStyle(
          color: AppPalette.textPrimary,
          fontSize: authScaled(context, 16, min: 14, max: 16),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.backgroundWarm,
        disabledBackgroundColor: AppPalette.primary.withValues(alpha: 0.45),
        minimumSize: Size(double.infinity, buttonHeight),
        padding: AppEdgeInsets.symmetric(
          horizontal: authScaled(context, 16, min: 12, max: 18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.circular(999),
        ),
        elevation: 0,
      ),
    );
  }
}

class _BackToLoginButton extends StatelessWidget {
  const _BackToLoginButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go('/login'),
      icon: const Icon(Icons.login_rounded),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.textCoolSecondary,
      ),
    );
  }
}
