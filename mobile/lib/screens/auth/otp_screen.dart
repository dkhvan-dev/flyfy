import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import 'auth_responsive.dart';
import 'terms_agreement_text.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? from;

  const OtpScreen({super.key, required this.phone, this.from});

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
      success = await auth.verifyOtp(widget.phone, code);
    } finally {
      _isSubmitting = false;
    }

    if (!ctx.mounted) return;

    if (success) {
      final updatedAuth = ctx.read<AuthProvider>();

      await ctx.read<SessionProvider>().restoreSession(
            primaryPhoneHint: updatedAuth.lastPrimaryPhoneHint ?? widget.phone,
            primaryEmailHint: updatedAuth.lastPrimaryEmailHint,
          );

      if (!ctx.mounted) return;

      ctx.go(widget.from?.isNotEmpty == true ? widget.from! : '/');
    } else {
      await showErrorDialog(
        ctx,
        title: l10n.error,
        message: auth.errorMessage ?? l10n.otpInvalid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScale = mediaQuery.textScaler.scale(1);
    final isCompact = screenWidth < 375 || textScale > 1.02;
    final isUltraCompact = screenWidth < 350 || textScale > 1.12;

    return Scaffold(
      body: AuthResponsiveTextScope(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.background),
            Positioned(
              top: 0,
              right: 0,
              child: FractionalTranslation(
                translation: const Offset(0.3, -0.3),
                child: Container(
                  width: authScaled(context, 250, min: 180, max: 250),
                  height: authScaled(context, 250, min: 180, max: 250),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: FractionalTranslation(
                translation: const Offset(-0.3, 0.3),
                child: Container(
                  width: authScaled(context, 350, min: 240, max: 350),
                  height: authScaled(context, 350, min: 240, max: 350),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
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
                  final cardRadius = authScaled(context, 16, min: 14, max: 16);

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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: topPadding,
                                  ),
                                  child: Row(
                                    children: [
                                      Material(
                                        color: AppColors.accent.withValues(
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
                                              color: AppColors.accent,
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
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
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
                                            style: TextStyle(
                                              fontSize: authScaled(
                                                context,
                                                20,
                                                min: 18,
                                                max: 20,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: headerTopGap),
                                Text(
                                  l10n.verifyYourPhone,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                    letterSpacing: -0.5,
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
                                    style: TextStyle(
                                      fontSize: bodySize,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(text: l10n.enterAuthCode),
                                      TextSpan(
                                        text: widget.phone,
                                        style: const TextStyle(
                                          color: AppColors.accent,
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
                                    final boxWidth = ((otpConstraints.maxWidth -
                                                otpGap * 5) /
                                            6)
                                        .clamp(minBoxWidth, maxBoxWidth);

                                    return Stack(
                                      children: [
                                        Row(
                                          children: [
                                            for (var index = 0;
                                                index < 6;
                                                index++) ...[
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
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accent
                                                          .withValues(
                                                        alpha: 0.05,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        otpRadius,
                                                      ),
                                                      border: Border.all(
                                                        color: isFocused
                                                            ? AppColors.accent
                                                            : AppColors.accent
                                                                .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      char.isEmpty ? '·' : char,
                                                      style: TextStyle(
                                                        fontSize: otpFontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: char.isEmpty
                                                            ? AppColors
                                                                .textCaption
                                                            : AppColors
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
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(
                                              color: Colors.transparent,
                                            ),
                                            cursorColor: Colors.transparent,
                                            enableInteractiveSelection: false,
                                            autofocus: true,
                                            onTapOutside: (_) => FocusScope.of(
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
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              fillColor: Colors.transparent,
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
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
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
                                            color: AppColors.textCaption,
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
                                            style: TextStyle(
                                              color: AppColors.textCaption,
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
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: timerGap),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      l10n.didntReceiveOTP,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: authScaled(
                                          context,
                                          14,
                                          min: 12,
                                          max: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      l10n.resendCode,
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: authScaled(
                                          context,
                                          14,
                                          min: 12,
                                          max: 14,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: footerTopGap),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      if (auth.isVerifyingOtp) {
                                        return Container(
                                          height: buttonHeight,
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius: BorderRadius.circular(
                                              cardRadius,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: AppColors.background,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        );
                                      }

                                      final canSubmit =
                                          _codeController.text.trim().length ==
                                              6;

                                      return ElevatedButton(
                                        onPressed: canSubmit ? _submit : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accent,
                                          foregroundColor: AppColors.background,
                                          disabledBackgroundColor: AppColors
                                              .accent
                                              .withValues(alpha: 0.5),
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(
                                            double.infinity,
                                            buttonHeight,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              cardRadius,
                                            ),
                                          ),
                                          elevation: canSubmit ? 4 : 0,
                                          shadowColor: AppColors.accent
                                              .withValues(alpha: 0.5),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              l10n.verifyAndLogin,
                                              style: TextStyle(
                                                fontSize: authScaled(
                                                  context,
                                                  18,
                                                  min: 15,
                                                  max: 18,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
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
                                              color: AppColors.textPrimary,
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
    );
  }
}
