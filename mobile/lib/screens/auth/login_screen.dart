import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'auth_responsive.dart';
import 'terms_agreement_text.dart';

enum _AuthEntryMode { login, register }

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _identifierFocusNode = FocusNode();
  final _loginPasswordFocusNode = FocusNode();
  final _registerEmailFocusNode = FocusNode();
  final _registerPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  _AuthEntryMode _mode = _AuthEntryMode.login;
  bool _showLoginValidation = false;
  bool _showRegisterValidation = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _identifierController,
      _loginPasswordController,
      _registerEmailController,
      _registerPasswordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFormChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _identifierController,
      _loginPasswordController,
      _registerEmailController,
      _registerPasswordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_handleFormChanged);
      controller.dispose();
    }
    _identifierFocusNode.dispose();
    _loginPasswordFocusNode.dispose();
    _registerEmailFocusNode.dispose();
    _registerPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submitLogin() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    setState(() => _showLoginValidation = true);

    final identifierError = _identifierValidationMessage(l10n);
    final passwordError = _passwordValidationMessage(
      l10n,
      _loginPasswordController.text,
    );
    if (identifierError != null) {
      _identifierFocusNode.requestFocus();
      return;
    }
    if (passwordError != null) {
      _loginPasswordFocusNode.requestFocus();
      return;
    }

    final auth = ctx.read<AuthProvider>();
    final success = await auth.loginWithPassword(
      _identifierController.text.trim(),
      _loginPasswordController.text.trim(),
    );

    if (!ctx.mounted) return;
    if (success) {
      await _completeAuthenticatedEntry(ctx, auth);
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: auth.errorMessage ?? l10n.authLoginFailed,
    );
  }

  Future<void> _submitRegistration() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    setState(() => _showRegisterValidation = true);

    final emailError = _emailValidationMessage(l10n);
    final passwordError = _passwordValidationMessage(
      l10n,
      _registerPasswordController.text,
    );
    final confirmError = _confirmPasswordValidationMessage(l10n);
    if (emailError != null) {
      _registerEmailFocusNode.requestFocus();
      return;
    }
    if (passwordError != null) {
      _registerPasswordFocusNode.requestFocus();
      return;
    }
    if (confirmError != null) {
      _confirmPasswordFocusNode.requestFocus();
      return;
    }

    final email = _registerEmailController.text.trim();
    final auth = ctx.read<AuthProvider>();
    final success = await auth.startEmailRegistration(
      email,
      _registerPasswordController.text.trim(),
    );

    if (!ctx.mounted) return;
    if (success) {
      final uri = Uri(
        path: '/otp',
        queryParameters: {
          'mode': 'emailRegistration',
          'email': email,
          if (widget.from?.isNotEmpty == true) 'from': widget.from!,
        },
      );
      ctx.pushReplacement(uri.toString());
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: auth.errorMessage ?? l10n.authRegistrationFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompact = screenWidth < 375 || textScale > 1.02;
    final isNarrow = screenWidth < 360 || textScale > 1.08;
    final colors = AppDesignSystem.colorsFor(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: AuthResponsiveTextScope(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _AuthV2Background(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                    final keyboardOpen = bottomInset > 0;
                    final compactHeight =
                        constraints.maxHeight < 760 || textScale > 1.02;
                    final horizontalPadding = authScaled(
                      context,
                      isCompact ? 20 : 24,
                      min: 16,
                      max: 28,
                    );
                    final panelPadding = authScaled(
                      context,
                      compactHeight ? 20 : 28,
                      min: 18,
                      max: 30,
                    );
                    final bottomPanelPadding = authScaled(
                      context,
                      keyboardOpen ? 16 : (compactHeight ? 24 : 40),
                      min: 14,
                      max: 44,
                    );
                    final titleSize = authScaled(
                      context,
                      isCompact ? 28 : 32,
                      min: 24,
                      max: 32,
                    );
                    final logoSize = authScaled(context, 40, min: 34, max: 40);

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: AppEdgeInsets.only(bottom: bottomInset),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: AppEdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: AppEdgeInsets.symmetric(
                                  vertical: authScaled(
                                    context,
                                    isCompact ? 18 : 24,
                                    min: 16,
                                    max: 24,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => context.go('/'),
                                      borderRadius: AppBorderRadius.circular(
                                        999,
                                      ),
                                      child: Row(
                                        children: [
                                          ClipOval(
                                            child: Image.asset(
                                              'assets/icons/inflap_app_icon_white_bg_256.png',
                                              width: logoSize,
                                              height: logoSize,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(
                                            width: authScaled(
                                              context,
                                              8,
                                              min: 6,
                                              max: 8,
                                            ),
                                          ),
                                          Text(
                                            'Inflap',
                                            style: AppTextStyle(
                                              fontSize: authScaled(
                                                context,
                                                24,
                                                min: 20,
                                                max: 24,
                                              ),
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  context.appColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/'),
                                      child: Text(
                                        l10n.skip,
                                        style: AppTextStyle(
                                          color: AppPalette.primary,
                                          fontSize: authScaled(
                                            context,
                                            14,
                                            min: 13,
                                            max: 14,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: AppEdgeInsets.only(
                                  bottom: bottomPanelPadding,
                                ),
                                child: Container(
                                  padding: AppEdgeInsets.all(panelPadding),
                                  decoration: AppBoxDecoration(
                                    color: context.appColors.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                    border: Border.all(
                                      color: context.appColors.borderPrimary,
                                    ),
                                    borderRadius: AppBorderRadius.circular(
                                      authScaled(context, 24, min: 18, max: 24),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _mode == _AuthEntryMode.login
                                            ? l10n.authLoginTitle
                                            : l10n.authRegisterTitle,
                                        style: AppTextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.textPrimary,
                                          height: 1.1,
                                        ),
                                      ),
                                      SizedBox(
                                        height: authScaled(
                                          context,
                                          20,
                                          min: 16,
                                          max: 22,
                                        ),
                                      ),
                                      _AuthModeSwitch(
                                        mode: _mode,
                                        onChanged: (mode) {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            _mode = mode;
                                            _showLoginValidation = false;
                                            _showRegisterValidation = false;
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        height: authScaled(
                                          context,
                                          20,
                                          min: 16,
                                          max: 22,
                                        ),
                                      ),
                                      IndexedStack(
                                        index: _mode == _AuthEntryMode.login
                                            ? 0
                                            : 1,
                                        sizing: StackFit.loose,
                                        children: [
                                          _AuthModePane(
                                            isActive:
                                                _mode == _AuthEntryMode.login,
                                            child: _buildLoginForm(
                                              context,
                                              l10n,
                                              isNarrow,
                                            ),
                                          ),
                                          _AuthModePane(
                                            isActive:
                                                _mode ==
                                                _AuthEntryMode.register,
                                            child: _buildRegisterForm(
                                              context,
                                              l10n,
                                              isNarrow,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: authScaled(
                                          context,
                                          22,
                                          min: 18,
                                          max: 24,
                                        ),
                                      ),
                                      TermsAgreementRichText(
                                        text: l10n.termsAgreementText,
                                        onTermsTap: () {},
                                        onPrivacyTap: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AppLocalizations l10n,
    bool isNarrow,
  ) {
    final identifierError = _showLoginValidation
        ? _identifierValidationMessage(l10n)
        : null;
    final passwordError = _showLoginValidation
        ? _passwordValidationMessage(l10n, _loginPasswordController.text)
        : null;
    final canSubmit =
        identifierError == null &&
        passwordError == null &&
        _identifierController.text.trim().isNotEmpty &&
        _loginPasswordController.text.trim().isNotEmpty;

    return _AuthFieldsScrollView(
      child: Column(
        key: const ValueKey('login-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            controller: _identifierController,
            focusNode: _identifierFocusNode,
            label: l10n.authIdentifierLabel,
            hint: l10n.authIdentifierHint,
            icon: Icons.alternate_email_rounded,
            errorText: identifierError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            onSubmitted: (_) => _loginPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _loginPasswordController,
            focusNode: _loginPasswordFocusNode,
            label: l10n.passwordLabel,
            hint: l10n.passwordHint,
            icon: Icons.lock_outline_rounded,
            errorText: passwordError,
            obscureText: _obscureLoginPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submitLogin(),
            suffixIcon: IconButton(
              tooltip: _obscureLoginPassword
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              onPressed: () => setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              }),
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/password-reset'),
              icon: Icon(
                Icons.lock_reset_rounded,
                size: authScaled(context, 18, min: 16, max: 18),
              ),
              label: Text(
                l10n.authForgotPasswordAction,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.primary,
                padding: AppEdgeInsets.symmetric(
                  horizontal: authScaled(context, 10, min: 8, max: 10),
                  vertical: authScaled(context, 6, min: 4, max: 6),
                ),
                textStyle: AppTextStyle(
                  fontSize: authScaled(context, 14, min: 12, max: 14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => _PrimaryAuthButton(
              label: l10n.authLoginAction,
              icon: Icons.login_rounded,
              isLoading: auth.isPasswordLoginLoading,
              onPressed: canSubmit ? _submitLogin : null,
            ),
          ),
          SizedBox(height: authScaled(context, 14, min: 12, max: 16)),
          _buildOAuthButtons(context, l10n, isNarrow),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(
    BuildContext context,
    AppLocalizations l10n,
    bool isNarrow,
  ) {
    final emailError = _showRegisterValidation
        ? _emailValidationMessage(l10n)
        : null;
    final passwordError = _showRegisterValidation
        ? _passwordValidationMessage(l10n, _registerPasswordController.text)
        : null;
    final confirmError = _showRegisterValidation
        ? _confirmPasswordValidationMessage(l10n)
        : null;
    final canSubmit =
        emailError == null &&
        passwordError == null &&
        confirmError == null &&
        _registerEmailController.text.trim().isNotEmpty &&
        _registerPasswordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty;

    return _AuthFieldsScrollView(
      child: Column(
        key: const ValueKey('register-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            controller: _registerEmailController,
            focusNode: _registerEmailFocusNode,
            label: l10n.authEmailLabel,
            hint: l10n.authEmailHint,
            icon: Icons.mail_outline_rounded,
            errorText: emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _registerPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _registerPasswordController,
            focusNode: _registerPasswordFocusNode,
            label: l10n.passwordLabel,
            hint: l10n.passwordHint,
            icon: Icons.lock_outline_rounded,
            errorText: passwordError,
            obscureText: _obscureRegisterPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            suffixIcon: IconButton(
              tooltip: _obscureRegisterPassword
                  ? l10n.authShowPassword
                  : l10n.authHidePassword,
              onPressed: () => setState(() {
                _obscureRegisterPassword = !_obscureRegisterPassword;
              }),
              icon: Icon(
                _obscureRegisterPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: l10n.authConfirmPasswordLabel,
            hint: l10n.passwordHint,
            icon: Icons.check_circle_outline_rounded,
            errorText: confirmError,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submitRegistration(),
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
          const SizedBox(height: 14),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => _PrimaryAuthButton(
              label: l10n.authRegisterAction,
              icon: Icons.person_add_alt_1_rounded,
              isLoading: auth.isEmailRegistrationLoading,
              onPressed: canSubmit ? _submitRegistration : null,
            ),
          ),
          SizedBox(height: authScaled(context, 14, min: 12, max: 16)),
          _buildOAuthButtons(context, l10n, isNarrow),
        ],
      ),
    );
  }

  Widget _buildOAuthButtons(
    BuildContext context,
    AppLocalizations l10n,
    bool isNarrow,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAnyOAuthLoading = auth.isGoogleLoading || auth.isAppleLoading;
        final buttons = [
          _OAuthButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            isLoading: auth.isGoogleLoading,
            onPressed: isAnyOAuthLoading
                ? null
                : () => _submitOAuth(
                    context,
                    provider: _OAuthProvider.google,
                    fallbackError: l10n.googleLoginFailed,
                  ),
          ),
          _OAuthButton(
            icon: Icons.apple,
            label: 'Apple',
            isLoading: auth.isAppleLoading,
            onPressed: isAnyOAuthLoading
                ? null
                : () => _submitOAuth(
                    context,
                    provider: _OAuthProvider.apple,
                    fallbackError: l10n.appleLoginFailed,
                  ),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [buttons[0], const SizedBox(height: 10), buttons[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 10),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }

  Future<void> _submitOAuth(
    BuildContext ctx, {
    required _OAuthProvider provider,
    required String fallbackError,
  }) async {
    final l10n = AppLocalizations.of(ctx)!;
    final authProvider = ctx.read<AuthProvider>();
    final success = provider == _OAuthProvider.google
        ? await authProvider.loginWithGoogle('mock_google_token')
        : await authProvider.loginWithApple('mock_apple_token');

    if (!ctx.mounted) return;
    if (success) {
      await _completeAuthenticatedEntry(ctx, authProvider);
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: authProvider.errorMessage ?? fallbackError,
    );
  }

  String? _identifierValidationMessage(AppLocalizations l10n) {
    if (_identifierController.text.trim().isEmpty) {
      return l10n.authIdentifierRequiredError;
    }
    return null;
  }

  String? _emailValidationMessage(AppLocalizations l10n) {
    final email = _registerEmailController.text.trim();
    if (email.isEmpty) {
      return l10n.emailRequiredError;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return l10n.emailInvalidError;
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
        _registerPasswordController.text.trim()) {
      return l10n.authPasswordMismatchError;
    }
    return null;
  }

  Future<void> _completeAuthenticatedEntry(
    BuildContext ctx,
    AuthProvider authProvider,
  ) async {
    await ctx.read<SessionProvider>().restoreSession(
      primaryPhoneHint: authProvider.lastPrimaryPhoneHint,
      primaryEmailHint: authProvider.lastPrimaryEmailHint,
    );

    if (!ctx.mounted) return;

    _finishAuthenticatedNavigation(ctx, widget.from);
  }
}

void _finishAuthenticatedNavigation(BuildContext ctx, String? from) {
  final target = from?.trim();
  if (target == null || target.isEmpty || target == '/') {
    ctx.go('/');
    return;
  }

  ctx.pushReplacement(target);
}

enum _OAuthProvider { google, apple }

const _authScenicBackgroundUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBduazwzIicGU9fDEXAz9OgOyFeni4k4elOe6XduNdQoG3iY1-qa2p2g8PvzmXdNrTJctUljZlDddvYm99io6whN9d3A0r8s6v6c-1W2giZFcC3P3wiIhlpfiKdGpC0fK8sY4vBFTQDRjqXUHRHyTgxLx5_rxq0mI11TkZ2NTQ_Kmi8c9Sb7EtHqmi-DOVm2ZpH5eFB89IKkMgkReWTlea9VKkr7SlVd8mHVoYpo5204yiI4tQxuNcUlQrjU2R2epHWOD9Ij-h0bTHM';

class _AuthV2Background extends StatelessWidget {
  const _AuthV2Background();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.screenGradientColors,
            ),
          ),
        ),
        Image.network(
          _authScenicBackgroundUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          color: isDark
              ? colors.scrim.withValues(alpha: 0.22)
              : colors.white.withValues(alpha: 0.54),
          colorBlendMode: isDark ? BlendMode.darken : BlendMode.lighten,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: AppBoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.48, 1],
              colors: [
                (isDark ? colors.scrim : colors.white).withValues(
                  alpha: isDark ? 0.5 : 0.22,
                ),
                colors.background.withValues(alpha: isDark ? 0.74 : 0.82),
                colors.backgroundDeep.withValues(alpha: isDark ? 0.92 : 0.96),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthModePane extends StatelessWidget {
  final bool isActive;
  final Widget child;

  const _AuthModePane({required this.isActive, required this.child});

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: isActive,
      child: IgnorePointer(
        ignoring: !isActive,
        child: ExcludeFocus(excluding: !isActive, child: child),
      ),
    );
  }
}

class _AuthFieldsScrollView extends StatelessWidget {
  final Widget child;

  const _AuthFieldsScrollView({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, double.infinity).toDouble()
            : MediaQuery.sizeOf(context).width;
        final floatingLabelReserve = authScaled(context, 8, min: 6, max: 8);

        return Padding(
          padding: AppEdgeInsets.only(top: floatingLabelReserve),
          child: SizedBox(width: availableWidth, child: child),
        );
      },
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  final _AuthEntryMode mode;
  final ValueChanged<_AuthEntryMode> onChanged;

  const _AuthModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_AuthEntryMode>(
      segments: [
        ButtonSegment<_AuthEntryMode>(
          value: _AuthEntryMode.login,
          label: Text(l10n.authLoginTab, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.login_rounded),
        ),
        ButtonSegment<_AuthEntryMode>(
          value: _AuthEntryMode.register,
          label: Text(l10n.authRegisterTab, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(context.appColors.textPrimary),
        iconColor: WidgetStateProperty.all(context.appColors.textPrimary),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.primary
              : context.appColors.surfaceRaised,
        ),
        side: WidgetStateProperty.all(
          BorderSide(color: context.appColors.borderPrimary),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
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

  const _AuthTextField({
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
      style: AppTextStyle(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: AppInputDecoration(
        labelText: label,
        labelStyle: AppTextStyle(color: context.appColors.textSecondary),
        hintText: hint,
        hintStyle: AppTextStyle(color: context.appColors.textMuted),
        errorText: errorText,
        filled: true,
        fillColor: context.appColors.surfaceRaised,
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
          borderSide: BorderSide(color: context.appColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(
            authScaled(context, 16, min: 14, max: 16),
          ),
          borderSide: BorderSide(color: context.appColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.circular(
            authScaled(context, 16, min: 14, max: 16),
          ),
          borderSide: BorderSide(color: AppPalette.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

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
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: context.appColors.textPrimary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final contentColor = onPressed == null
        ? context.appColors.textDisabled
        : context.appColors.textPrimary;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: contentColor),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: AppTextStyle(
          color: contentColor,
          fontSize: authScaled(context, 16, min: 14, max: 16),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: AppButtonStyles.primary(context.appColors).copyWith(
        minimumSize: WidgetStateProperty.all(
          Size(double.infinity, buttonHeight),
        ),
        padding: WidgetStateProperty.all(
          AppEdgeInsets.symmetric(
            horizontal: authScaled(context, 16, min: 12, max: 18),
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: AppBorderRadius.circular(999)),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _OAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = authScaled(context, 54, min: 48, max: 54);
    final iconSize = authScaled(context, 24, min: 20, max: 24);
    final labelSize = authScaled(context, 15, min: 13, max: 15);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: context.appColors.surfaceRaised,
          borderRadius: AppBorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              height: buttonHeight,
              decoration: AppBoxDecoration(
                border: Border.all(
                  color: AppPalette.secondary.withValues(alpha: 0.32),
                ),
                borderRadius: AppBorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppPalette.primary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: AppPalette.secondary, size: iconSize),
                        SizedBox(width: authScaled(context, 8, min: 6, max: 8)),
                        Flexible(
                          child: Text(
                            label,
                            style: AppTextStyle(
                              color: context.appColors.textPrimary,
                              fontSize: labelSize,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
