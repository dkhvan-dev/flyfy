import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/ui/error_dialog.dart';
import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  void _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone);

    if (!mounted) return;

    if (success) {
      final uri = Uri(
        path: '/otp',
        queryParameters: {
          'phone': phone,
          if (widget.from != null && widget.from!.isNotEmpty) 'from': widget.from!,
        },
      );

      context.push(uri.toString());
    } else {
      await showErrorDialog(
        context,
        title: 'Ошибка',
        message: auth.errorMessage ?? 'Не удалось отправить код.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.flight_takeoff, size: 80, color: Color(0xFF00BCD4)),
              const SizedBox(height: 32),
              Text(
                l10n.welcomeToFlyFy,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterPhoneToContinue,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(16),
                  _PhonePrefixFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintText: '+77051698779',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF00BCD4)),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isSendingOtp) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
                    );
                  }

                  return ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.sendCode,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white24)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isAnyOAuthLoading = auth.isGoogleLoading || auth.isAppleLoading;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _OAuthButton(
                        icon: Icons.g_mobiledata,
                        color: Colors.white,
                        iconColor: Colors.black87,
                        isLoading: auth.isGoogleLoading,
                        onPressed: isAnyOAuthLoading
                            ? null
                            : () async {
                                final authProvider = context.read<AuthProvider>();
                                final idToken = 'mock_google_token';

                                final success = await authProvider.loginWithGoogle(idToken);

                                if (!mounted) return;

                                if (success) {
                                  context.go('/');
                                } else {
                                  await showErrorDialog(
                                    context,
                                    title: 'Ошибка входа',
                                    message: authProvider.errorMessage ??
                                        'Не удалось выполнить вход через Google.',
                                  );
                                }
                              },
                      ),
                      _OAuthButton(
                        icon: Icons.apple,
                        color: Colors.black,
                        iconColor: Colors.white,
                        border: Border.all(color: Colors.white24),
                        isLoading: auth.isAppleLoading,
                        onPressed: isAnyOAuthLoading
                            ? null
                            : () async {
                                final authProvider = context.read<AuthProvider>();
                                final idToken = 'mock_apple_token';

                                final success = await authProvider.loginWithApple(idToken);

                                if (!mounted) return;

                                if (success) {
                                  context.go('/');
                                } else {
                                  await showErrorDialog(
                                    context,
                                    title: 'Ошибка входа',
                                    message: authProvider.errorMessage ??
                                        'Не удалось выполнить вход через Apple ID.',
                                  );
                                }
                              },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

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
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Border? border;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _OAuthButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.border,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: border,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 36),
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
