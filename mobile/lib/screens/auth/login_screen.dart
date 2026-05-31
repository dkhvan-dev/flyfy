import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_responsive.dart';
import 'terms_agreement_text.dart';

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _showPhoneValidation = false;

  void _submit() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    final validationMessage = _phoneValidationMessage(l10n);
    if (validationMessage != null) {
      setState(() {
        _showPhoneValidation = true;
      });
      _phoneFocusNode.requestFocus();
      return;
    }

    final phone = _normalizedPhone();
    if (phone.isEmpty) {
      return;
    }

    final auth = ctx.read<AuthProvider>();
    final success = await auth.sendOtp(phone);

    if (!ctx.mounted) return;

    if (success) {
      final uri = Uri(
        path: '/otp',
        queryParameters: {
          'phone': phone,
          if (widget.from != null && widget.from!.isNotEmpty)
            'from': widget.from!,
        },
      );

      ctx.push(uri.toString());
    } else {
      await showErrorDialog(
        ctx,
        title: l10n.error,
        message: auth.errorMessage ?? l10n.otpSendFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isCompact = screenWidth < 375 || textScale > 1.02;
    final isNarrow = screenWidth < 360 || textScale > 1.08;
    final phoneErrorText = _showPhoneValidation
        ? _phoneValidationMessage(l10n)
        : null;
    final canSubmitPhone = _isPhoneValid();

    return Scaffold(
      body: AuthResponsiveTextScope(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBduazwzIicGU9fDEXAz9OgOyFeni4k4elOe6XduNdQoG3iY1-qa2p2g8PvzmXdNrTJctUljZlDddvYm99io6whN9d3A0r8s6v6c-1W2giZFcC3P3wiIhlpfiKdGpC0fK8sY4vBFTQDRjqXUHRHyTgxLx5_rxq0mI11TkZ2NTQ_Kmi8c9Sb7EtHqmi-DOVm2ZpH5eFB89IKkMgkReWTlea9VKkr7SlVd8mHVoYpo5204yiI4tQxuNcUlQrjU2R2epHWOD9Ij-h0bTHM',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: AppColors.background),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.2),
                    AppColors.background.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
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
                  final cardPadding = authScaled(
                    context,
                    compactHeight ? 22 : 30,
                    min: 18,
                    max: 32,
                  );
                  final bottomCardPadding = authScaled(
                    context,
                    keyboardOpen ? 18 : (compactHeight ? 28 : 48),
                    min: 14,
                    max: 52,
                  );
                  final titleSize = authScaled(
                    context,
                    isCompact ? 28 : 32,
                    min: 24,
                    max: 32,
                  );
                  final sectionGap = authScaled(
                    context,
                    keyboardOpen ? 20 : (compactHeight ? 24 : 32),
                    min: 18,
                    max: 34,
                  );
                  final logoSize = authScaled(context, 40, min: 34, max: 40);
                  final cardRadius = authScaled(context, 24, min: 18, max: 24);

                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
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
                              padding: EdgeInsets.symmetric(
                                vertical: authScaled(
                                  context,
                                  isCompact ? 20 : 24,
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
                                    borderRadius: BorderRadius.circular(999),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: logoSize,
                                          height: logoSize,
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.flight_takeoff,
                                            color: AppColors.background,
                                            size: authScaled(
                                              context,
                                              24,
                                              min: 20,
                                              max: 24,
                                            ),
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
                                          style: TextStyle(
                                            fontSize: authScaled(
                                              context,
                                              24,
                                              min: 20,
                                              max: 24,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/'),
                                    child: Text(
                                      'Skip',
                                      style: TextStyle(
                                        color: AppColors.textPrimary.withValues(
                                          alpha: 0.8,
                                        ),
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
                              padding: EdgeInsets.only(
                                bottom: bottomCardPadding,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(cardRadius),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(cardPadding),
                                    decoration: BoxDecoration(
                                      color: AppColors.background.withValues(
                                        alpha: 0.4,
                                      ),
                                      border: Border.all(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        cardRadius,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          l10n.welcomeTitle,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            height: 1.1,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(
                                          height: authScaled(
                                            context,
                                            8,
                                            min: 6,
                                            max: 8,
                                          ),
                                        ),
                                        Text(
                                          l10n.welcomeDescription,
                                          style: TextStyle(
                                            fontSize: authScaled(
                                              context,
                                              16,
                                              min: 14,
                                              max: 16,
                                            ),
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                        SizedBox(height: sectionGap),
                                        TextField(
                                          controller: _phoneController,
                                          focusNode: _phoneFocusNode,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.done,
                                          onTapOutside: (_) =>
                                              FocusScope.of(context).unfocus(),
                                          onSubmitted: (_) => _submit(),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9+]'),
                                            ),
                                            LengthLimitingTextInputFormatter(
                                              16,
                                            ),
                                            _PhonePrefixFormatter(),
                                          ],
                                          decoration: InputDecoration(
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                            hintText: '+7 705 169 8779',
                                            hintStyle: const TextStyle(
                                              color: AppColors.textCaption,
                                            ),
                                            errorText: phoneErrorText,
                                            filled: true,
                                            fillColor: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: authScaled(
                                                    context,
                                                    20,
                                                    min: 16,
                                                    max: 20,
                                                  ),
                                                  vertical: authScaled(
                                                    context,
                                                    16,
                                                    min: 14,
                                                    max: 16,
                                                  ),
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    authScaled(
                                                      context,
                                                      16,
                                                      min: 14,
                                                      max: 16,
                                                    ),
                                                  ),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    authScaled(
                                                      context,
                                                      16,
                                                      min: 14,
                                                      max: 16,
                                                    ),
                                                  ),
                                              borderSide: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.phone_iphone,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: authScaled(
                                            context,
                                            12,
                                            min: 10,
                                            max: 12,
                                          ),
                                        ),
                                        Consumer<AuthProvider>(
                                          builder: (consumerContext, auth, _) {
                                            if (auth.isSendingOtp) {
                                              return Container(
                                                height: authScaled(
                                                  context,
                                                  56,
                                                  min: 50,
                                                  max: 56,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                alignment: Alignment.center,
                                                child: const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: AppColors
                                                            .background,
                                                        strokeWidth: 2.5,
                                                      ),
                                                ),
                                              );
                                            }

                                            return ElevatedButton(
                                              onPressed: canSubmitPhone
                                                  ? _submit
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.accent,
                                                foregroundColor:
                                                    AppColors.background,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: authScaled(
                                                    context,
                                                    16,
                                                    min: 14,
                                                    max: 16,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.sms_rounded,
                                                    size: 20,
                                                    color:
                                                        AppColors.textPrimary,
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
                                                    l10n.authByPhone,
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: authScaled(
                                                        context,
                                                        16,
                                                        min: 14,
                                                        max: 16,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Consumer<AuthProvider>(
                                          builder: (consumerContext, auth, _) {
                                            final isAnyOAuthLoading =
                                                auth.isGoogleLoading ||
                                                auth.isAppleLoading;

                                            if (isNarrow) {
                                              return Column(
                                                children: [
                                                  _OAuthButton(
                                                    icon: Icons.g_mobiledata,
                                                    label: 'Google',
                                                    isLoading:
                                                        auth.isGoogleLoading,
                                                    onPressed: isAnyOAuthLoading
                                                        ? null
                                                        : () async {
                                                            final ctx = context;
                                                            final authProvider =
                                                                ctx
                                                                    .read<
                                                                      AuthProvider
                                                                    >();
                                                            final success =
                                                                await authProvider
                                                                    .loginWithGoogle(
                                                                      'mock_google_token',
                                                                    );

                                                            if (!ctx.mounted) {
                                                              return;
                                                            }
                                                            if (success) {
                                                              await _completeAuthenticatedEntry(
                                                                ctx,
                                                                authProvider,
                                                              );
                                                            } else {
                                                              await showErrorDialog(
                                                                ctx,
                                                                title:
                                                                    l10n.error,
                                                                message:
                                                                    authProvider
                                                                        .errorMessage ??
                                                                    l10n.googleLoginFailed,
                                                              );
                                                            }
                                                          },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _OAuthButton(
                                                    icon: Icons.apple,
                                                    label: 'Apple',
                                                    isLoading:
                                                        auth.isAppleLoading,
                                                    onPressed: isAnyOAuthLoading
                                                        ? null
                                                        : () async {
                                                            final ctx = context;
                                                            final authProvider =
                                                                ctx
                                                                    .read<
                                                                      AuthProvider
                                                                    >();
                                                            final success =
                                                                await authProvider
                                                                    .loginWithApple(
                                                                      'mock_apple_token',
                                                                    );

                                                            if (!ctx.mounted) {
                                                              return;
                                                            }
                                                            if (success) {
                                                              await _completeAuthenticatedEntry(
                                                                ctx,
                                                                authProvider,
                                                              );
                                                            } else {
                                                              await showErrorDialog(
                                                                ctx,
                                                                title:
                                                                    l10n.error,
                                                                message:
                                                                    authProvider
                                                                        .errorMessage ??
                                                                    l10n.appleLoginFailed,
                                                              );
                                                            }
                                                          },
                                                  ),
                                                ],
                                              );
                                            }

                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: _OAuthButton(
                                                    icon: Icons.g_mobiledata,
                                                    label: 'Google',
                                                    isLoading:
                                                        auth.isGoogleLoading,
                                                    onPressed: isAnyOAuthLoading
                                                        ? null
                                                        : () async {
                                                            final ctx = context;
                                                            final authProvider =
                                                                ctx
                                                                    .read<
                                                                      AuthProvider
                                                                    >();
                                                            final success =
                                                                await authProvider
                                                                    .loginWithGoogle(
                                                                      'mock_google_token',
                                                                    );

                                                            if (!ctx.mounted) {
                                                              return;
                                                            }
                                                            if (success) {
                                                              await _completeAuthenticatedEntry(
                                                                ctx,
                                                                authProvider,
                                                              );
                                                            } else {
                                                              await showErrorDialog(
                                                                ctx,
                                                                title:
                                                                    l10n.error,
                                                                message:
                                                                    authProvider
                                                                        .errorMessage ??
                                                                    l10n.googleLoginFailed,
                                                              );
                                                            }
                                                          },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _OAuthButton(
                                                    icon: Icons.apple,
                                                    label: 'Apple',
                                                    isLoading:
                                                        auth.isAppleLoading,
                                                    onPressed: isAnyOAuthLoading
                                                        ? null
                                                        : () async {
                                                            final ctx = context;
                                                            final authProvider =
                                                                ctx
                                                                    .read<
                                                                      AuthProvider
                                                                    >();
                                                            final success =
                                                                await authProvider
                                                                    .loginWithApple(
                                                                      'mock_apple_token',
                                                                    );

                                                            if (!ctx.mounted) {
                                                              return;
                                                            }
                                                            if (success) {
                                                              await _completeAuthenticatedEntry(
                                                                ctx,
                                                                authProvider,
                                                              );
                                                            } else {
                                                              await showErrorDialog(
                                                                ctx,
                                                                title:
                                                                    l10n.error,
                                                                message:
                                                                    authProvider
                                                                        .errorMessage ??
                                                                    l10n.appleLoginFailed,
                                                              );
                                                            }
                                                          },
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          height: authScaled(
                                            context,
                                            24,
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: authScaled(context, 4, min: 3, max: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.accent.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(_handlePhoneChanged);
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus && _phoneController.text.isEmpty) {
        _phoneController.value = const TextEditingValue(
          text: '+',
          selection: TextSelection.collapsed(offset: 1),
        );
      }
    });
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handlePhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handlePhoneChanged() {
    if (!mounted) return;
    setState(() {
      // Rebuild is needed both for button enabled state and inline validation.
    });
  }

  String _normalizedPhone() {
    final digits = _extractPhoneDigits(_phoneController.text);
    if (digits.isEmpty) {
      return '';
    }
    return '+$digits';
  }

  bool _isPhoneValid() {
    final digits = _extractPhoneDigits(_phoneController.text);
    return digits.length >= 10 && digits.length <= 15;
  }

  String? _phoneValidationMessage(AppLocalizations l10n) {
    final digits = _extractPhoneDigits(_phoneController.text);
    if (digits.isEmpty) {
      return l10n.phoneRequiredError;
    }
    if (digits.length < 10 || digits.length > 15) {
      return l10n.phoneInvalidError;
    }
    return null;
  }

  String _extractPhoneDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
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

    ctx.go(widget.from ?? '/');
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
    final buttonHeight = authScaled(context, 56, min: 50, max: 56);
    final iconSize = authScaled(context, 24, min: 20, max: 24);
    final labelSize = authScaled(context, 16, min: 14, max: 16);

    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: iconSize),
                    SizedBox(width: authScaled(context, 8, min: 6, max: 8)),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }
}

class _PhonePrefixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '+',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    text = text.replaceAll('+', '');
    text = '+$text';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
