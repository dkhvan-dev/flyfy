import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'auth_responsive.dart';
import 'terms_agreement_text.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String email;
  final String mode;
  final String? from;

  const OtpScreen({
    super.key,
    this.phone = '',
    this.email = '',
    this.mode = 'phone',
    this.from,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _countdownDurationSeconds = 60;

  final _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _countdownTimer;
  int _remainingSeconds = _countdownDurationSeconds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingSeconds = _countdownDurationSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds == 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  String _formatCountdown() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    return '$paddedMinutes:$paddedSeconds';
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleCodeChanged(String value) {
    if (value.trim().length != 6 || _isSubmitting) {
      return;
    }

    _dismissKeyboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_codeController.text.trim().length != 6) return;
      _submit();
    });
  }

  void _submit() async {
    if (_isSubmitting) return;
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = ctx.read<AuthProvider>();
    if (auth.isVerifyingOtp) return;

    _dismissKeyboard();
    _isSubmitting = true;
    bool success = false;
    try {
      success = widget.mode == 'emailRegistration'
          ? await auth.verifyEmailRegistration(widget.email, code)
          : await auth.verifyOtp(widget.phone, code);
    } finally {
      _isSubmitting = false;
    }

    if (!ctx.mounted) return;

    if (success) {
      final updatedAuth = ctx.read<AuthProvider>();
      final emailHint = widget.mode == 'emailRegistration'
          ? updatedAuth.lastPrimaryEmailHint ?? widget.email
          : updatedAuth.lastPrimaryEmailHint;

      await ctx.read<SessionProvider>().restoreSession(
        primaryPhoneHint: widget.mode == 'emailRegistration'
            ? updatedAuth.lastPrimaryPhoneHint
            : updatedAuth.lastPrimaryPhoneHint ?? widget.phone,
        primaryEmailHint: emailHint,
      );

      if (!ctx.mounted) return;

      _finishOtpAuthenticatedNavigation(ctx, widget.from);
    } else {
      await showErrorDialog(
        ctx,
        title: l10n.error,
        message: auth.errorMessage ?? l10n.otpInvalid,
      );
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 0) return;

    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    final auth = ctx.read<AuthProvider>();
    final success = widget.mode == 'emailRegistration'
        ? await auth.resendEmailRegistrationCode(widget.email)
        : await auth.sendOtp(widget.phone);

    if (!ctx.mounted) return;

    if (success) {
      _codeController.clear();
      setState(() {
        _startCountdown();
      });
      _focusNode.requestFocus();
      return;
    }

    await showErrorDialog(
      ctx,
      title: l10n.error,
      message: auth.errorMessage ?? l10n.otpSendFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScale = mediaQuery.textScaler.scale(1);
    final isCompact = screenWidth < 375 || textScale > 1.02;
    final isUltraCompact = screenWidth < 350 || textScale > 1.12;
    final isEmailRegistration = widget.mode == 'emailRegistration';
    final destination = isEmailRegistration ? widget.email : widget.phone;
    final colors = AppDesignSystem.colorsFor(context);

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: Scaffold(
        backgroundColor: colors.background,
        body: AuthResponsiveTextScope(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _OtpV2Background(),
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
                      max: 26,
                    );
                    final topPadding = authScaled(
                      context,
                      isCompact ? 20 : 24,
                      min: 16,
                      max: 24,
                    );
                    final headerTopGap = authScaled(
                      context,
                      isCompact ? 12 : 16,
                      min: 8,
                      max: 16,
                    );
                    final sectionGap = authScaled(
                      context,
                      keyboardOpen ? 24 : (compactHeight ? 32 : 48),
                      min: 18,
                      max: 48,
                    );
                    final timerGap = authScaled(
                      context,
                      keyboardOpen ? 16 : 24,
                      min: 12,
                      max: 24,
                    );
                    final footerTopGap = authScaled(
                      context,
                      keyboardOpen ? 20 : (compactHeight ? 24 : 32),
                      min: 16,
                      max: 32,
                    );
                    final footerBottomGap = authScaled(
                      context,
                      keyboardOpen ? 16 : 36,
                      min: 12,
                      max: 40,
                    );
                    final headerButtonSize = authScaled(
                      context,
                      48,
                      min: 42,
                      max: 48,
                    );
                    final titleSize = authScaled(
                      context,
                      isCompact ? 28 : 32,
                      min: 24,
                      max: 32,
                    );
                    final bodySize = authScaled(context, 16, min: 14, max: 16);
                    final otpGap = authScaled(
                      context,
                      isCompact ? 8 : 10,
                      min: 6,
                      max: 10,
                    );
                    final minBoxWidth = isUltraCompact ? 36.0 : 40.0;
                    final maxBoxWidth = isCompact ? 48.0 : 52.0;
                    final boxHeight = authScaled(
                      context,
                      isUltraCompact ? 54 : (isCompact ? 60 : 64),
                      min: 52,
                      max: 64,
                    );
                    final otpRadius = authScaled(context, 12, min: 10, max: 12);
                    final otpFontSize = authScaled(
                      context,
                      isUltraCompact ? 20 : (isCompact ? 22 : 24),
                      min: 18,
                      max: 24,
                    );
                    final buttonHeight = authScaled(
                      context,
                      64,
                      min: 54,
                      max: 64,
                    );
                    final cardRadius = authScaled(
                      context,
                      16,
                      min: 14,
                      max: 16,
                    );

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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: AppEdgeInsets.symmetric(
                                      vertical: topPadding,
                                    ),
                                    child: Row(
                                      children: [
                                        Material(
                                          color: AppPalette.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: const CircleBorder(),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            onTap: () => context.pop(),
                                            child: SizedBox(
                                              width: headerButtonSize,
                                              height: headerButtonSize,
                                              child: Icon(
                                                Icons.arrow_back,
                                                color: AppPalette.primary,
                                                size: authScaled(
                                                  context,
                                                  22,
                                                  min: 20,
                                                  max: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: authScaled(
                                            context,
                                            16,
                                            min: 10,
                                            max: 16,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => context.go('/'),
                                          borderRadius:
                                              AppBorderRadius.circular(999),
                                          child: Padding(
                                            padding: AppEdgeInsets.symmetric(
                                              horizontal: authScaled(
                                                context,
                                                4,
                                                min: 2,
                                                max: 4,
                                              ),
                                              vertical: authScaled(
                                                context,
                                                6,
                                                min: 4,
                                                max: 6,
                                              ),
                                            ),
                                            child: Text(
                                              'Inflap',
                                              style: AppTextStyle(
                                                fontSize: authScaled(
                                                  context,
                                                  20,
                                                  min: 18,
                                                  max: 20,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                color: AppPalette.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: headerTopGap),
                                  Text(
                                    isEmailRegistration
                                        ? l10n.verifyYourEmail
                                        : l10n.verifyYourPhone,
                                    style: AppTextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.bold,
                                      color: context.appColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      12,
                                      min: 8,
                                      max: 12,
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      style: AppTextStyle(
                                        fontSize: bodySize,
                                        color: context.appColors.textSecondary,
                                        height: 1.5,
                                      ),
                                      children: [
                                        if (isEmailRegistration)
                                          TextSpan(
                                            text: l10n.enterEmailAuthCode,
                                          )
                                        else
                                          TextSpan(text: l10n.enterAuthCode),
                                        TextSpan(
                                          text: destination,
                                          style: AppTextStyle(
                                            color: AppPalette.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(height: sectionGap),
                                  LayoutBuilder(
                                    builder: (context, otpConstraints) {
                                      final boxWidth =
                                          ((otpConstraints.maxWidth -
                                                      otpGap * 5) /
                                                  6)
                                              .clamp(minBoxWidth, maxBoxWidth);

                                      return Stack(
                                        children: [
                                          Row(
                                            children: [
                                              for (
                                                var index = 0;
                                                index < 6;
                                                index++
                                              ) ...[
                                                Builder(
                                                  builder: (context) {
                                                    final text =
                                                        _codeController.text;
                                                    final char =
                                                        index < text.length
                                                        ? text[index]
                                                        : '';
                                                    final isFocused =
                                                        index == text.length &&
                                                        _focusNode.hasFocus;

                                                    return Container(
                                                      width: boxWidth,
                                                      height: boxHeight,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: AppBoxDecoration(
                                                        color: AppPalette
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.05,
                                                            ),
                                                        borderRadius:
                                                            AppBorderRadius.circular(
                                                              otpRadius,
                                                            ),
                                                        border: Border.all(
                                                          color: isFocused
                                                              ? AppPalette
                                                                    .primary
                                                              : AppPalette
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        char.isEmpty
                                                            ? '·'
                                                            : char,
                                                        style: AppTextStyle(
                                                          fontSize: otpFontSize,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: char.isEmpty
                                                              ? AppPalette
                                                                    .textMuted
                                                              : AppPalette
                                                                    .textPrimary,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                if (index != 5)
                                                  SizedBox(width: otpGap),
                                              ],
                                            ],
                                          ),
                                          Positioned.fill(
                                            child: TextField(
                                              controller: _codeController,
                                              focusNode: _focusNode,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: AppTextStyle(
                                                color: AppPalette.transparent,
                                              ),
                                              cursorColor:
                                                  AppPalette.transparent,
                                              enableInteractiveSelection: false,
                                              autofocus: true,
                                              onTapOutside: (_) =>
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus(),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  6,
                                                ),
                                              ],
                                              onChanged: _handleCodeChanged,
                                              decoration:
                                                  const AppInputDecoration(
                                                    border: InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    disabledBorder:
                                                        InputBorder.none,
                                                    contentPadding:
                                                        AppEdgeInsets.zero,
                                                    fillColor:
                                                        AppPalette.transparent,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: sectionGap),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: context.appColors.borderSoft,
                                        ),
                                      ),
                                      Padding(
                                        padding: AppEdgeInsets.symmetric(
                                          horizontal: authScaled(
                                            context,
                                            16,
                                            min: 10,
                                            max: 16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: authScaled(
                                                context,
                                                16,
                                                min: 14,
                                                max: 16,
                                              ),
                                              color:
                                                  context.appColors.textMuted,
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
                                              _formatCountdown(),
                                              style: AppTextStyle(
                                                color:
                                                    context.appColors.textMuted,
                                                fontSize: authScaled(
                                                  context,
                                                  14,
                                                  min: 12,
                                                  max: 14,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: context.appColors.borderSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: timerGap),
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      final isResending = isEmailRegistration
                                          ? auth.isEmailRegistrationLoading
                                          : auth.isSendingOtp;
                                      final canResend =
                                          _remainingSeconds == 0 &&
                                          !isResending;

                                      return Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            l10n.didntReceiveOTP,
                                            style: AppTextStyle(
                                              color: context
                                                  .appColors
                                                  .textSecondary,
                                              fontSize: authScaled(
                                                context,
                                                14,
                                                min: 12,
                                                max: 14,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: canResend
                                                ? _resendCode
                                                : null,
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppPalette.primary,
                                              disabledForegroundColor: context
                                                  .appColors
                                                  .textDisabled,
                                              padding: AppEdgeInsets.symmetric(
                                                horizontal: authScaled(
                                                  context,
                                                  6,
                                                  min: 4,
                                                  max: 6,
                                                ),
                                                vertical: authScaled(
                                                  context,
                                                  2,
                                                  min: 0,
                                                  max: 2,
                                                ),
                                              ),
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: isResending
                                                ? SizedBox(
                                                    width: authScaled(
                                                      context,
                                                      16,
                                                      min: 14,
                                                      max: 16,
                                                    ),
                                                    height: authScaled(
                                                      context,
                                                      16,
                                                      min: 14,
                                                      max: 16,
                                                    ),
                                                    child:
                                                        const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: AppPalette
                                                              .textPrimary,
                                                        ),
                                                  )
                                                : Text(
                                                    l10n.resendCode,
                                                    style: AppTextStyle(
                                                      fontSize: authScaled(
                                                        context,
                                                        14,
                                                        min: 12,
                                                        max: 14,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Padding(
                                padding: AppEdgeInsets.only(top: footerTopGap),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) {
                                        if (auth.isVerifyingOtp) {
                                          return Container(
                                            height: buttonHeight,
                                            decoration: AppBoxDecoration(
                                              color: AppPalette.primary,
                                              borderRadius:
                                                  AppBorderRadius.circular(
                                                    cardRadius,
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: context
                                                    .appColors
                                                    .textPrimary,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          );
                                        }

                                        final canSubmit =
                                            _codeController.text
                                                .trim()
                                                .length ==
                                            6;

                                        return FilledButton(
                                          onPressed: canSubmit ? _submit : null,
                                          style:
                                              AppButtonStyles.primary(
                                                context.appColors,
                                              ).copyWith(
                                                padding:
                                                    WidgetStateProperty.all(
                                                      AppEdgeInsets.zero,
                                                    ),
                                                minimumSize:
                                                    WidgetStateProperty.all(
                                                      Size(
                                                        double.infinity,
                                                        buttonHeight,
                                                      ),
                                                    ),
                                                shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        AppBorderRadius.circular(
                                                          cardRadius,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.verifyAndLogin,
                                                style: AppTextStyle(
                                                  fontSize: authScaled(
                                                    context,
                                                    18,
                                                    min: 15,
                                                    max: 18,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                  color: canSubmit
                                                      ? context
                                                            .appColors
                                                            .textPrimary
                                                      : AppPalette.textDisabled,
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
                                              Icon(
                                                Icons.arrow_forward,
                                                size: authScaled(
                                                  context,
                                                  24,
                                                  min: 20,
                                                  max: 24,
                                                ),
                                                color: canSubmit
                                                    ? context
                                                          .appColors
                                                          .textPrimary
                                                    : context
                                                          .appColors
                                                          .textDisabled,
                                              ),
                                            ],
                                          ),
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
                                    SizedBox(height: footerBottomGap),
                                  ],
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
}

class _OtpV2Background extends StatelessWidget {
  const _OtpV2Background();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: AppBoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.screenGradientColors,
        ),
      ),
    );
  }
}

void _finishOtpAuthenticatedNavigation(BuildContext ctx, String? from) {
  final target = from?.trim();
  if (target == null || target.isEmpty || target == '/') {
    ctx.go('/');
    return;
  }

  ctx.pushReplacement(target);
}
