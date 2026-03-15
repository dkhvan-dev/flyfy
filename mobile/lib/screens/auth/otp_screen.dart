import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import 'terms_agreement_text.dart';
class OtpScreen extends StatefulWidget {
  final String phone;
  final String? from;
  
  const OtpScreen({
    super.key,
    required this.phone,
    this.from,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    
    // Auto focus the input when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    final ctx = context;
    final l10n = AppLocalizations.of(ctx)!;
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = ctx.read<AuthProvider>();
    final success = await auth.verifyOtp(widget.phone, code);

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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.background),
          
          // Background Decorative Elements
          Positioned(
            top: 0,
            right: 0,
            child: FractionalTranslation(
              translation: const Offset(0.3, -0.3),
              child: Container(
                width: 250,
                height: 250,
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
                width: 350,
                height: 350,
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
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.pop(),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.arrow_back, color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'FlyFy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        // Header Section
                        Text(
                          l10n.verifyYourPhone,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
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
                        const SizedBox(height: 48),

                        // OTP Input Fields
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                final text = _codeController.text;
                                final char = index < text.length ? text[index] : '';
                                final isFocused = index == text.length && _focusNode.hasFocus;
                                
                                return Container(
                                  width: 48,
                                  height: 64,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFocused
                                          ? AppColors.accent
                                          : AppColors.accent.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    char.isEmpty ? '·' : char,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: char.isEmpty
                                          ? AppColors.textCaption
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // Invisible text field taking full width to capture input
                            Positioned.fill(
                              child: TextField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.transparent),
                                cursorColor: Colors.transparent,
                                enableInteractiveSelection: false,
                                autofocus: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
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
                        ),
                        const SizedBox(height: 48),

                        // Timer & Resend Section (Visual)
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: AppColors.borderLight)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: AppColors.textCaption),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '00:59',
                                    style: TextStyle(
                                      color: AppColors.textCaption,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: AppColors.borderLight)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.didntReceiveOTP,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.resendCode,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Footer Action
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.isVerifyingOtp) {
                              return Container(
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2.5),
                                ),
                              );
                            }

                            final canSubmit = _codeController.text.trim().length == 6;

                            return ElevatedButton(
                              onPressed: canSubmit ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.background,
                                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                                padding: const EdgeInsets.symmetric(vertical: 0),
                                minimumSize: const Size(double.infinity, 64),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: canSubmit ? 4 : 0,
                                shadowColor: AppColors.accent.withValues(alpha: 0.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.verifyAndLogin,
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 24),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Footer Terms
                        TermsAgreementRichText(
                          text: l10n.termsAgreementText,
                          onTermsTap: () {},
                          onPrivacyTap: () {},
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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

