import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../ui/app_colors.dart';
import 'app_lock_service.dart';
import 'biometric_auth_service.dart';

const Color _appLockModalTopColor = Color(0xFF2E251B);
const Color _appLockModalBottomColor = Color(0xFF38250E);
const Color _appLockModalFieldColor = Color(0xFF332315);

Future<bool> ensureAppLockSetup(BuildContext context) async {
  final appLockService = AppLockService();
  final biometricAuthService = BiometricAuthService();

  if (await appLockService.hasPin()) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }

  final pin = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'pin_setup',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => const _PinSetupDialog(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (!context.mounted || pin == null || pin.isEmpty) {
    return false;
  }

  await appLockService.savePin(pin);

  final biometricAvailable = await biometricAuthService.isAvailable();
  var biometricEnabled = false;
  if (context.mounted && biometricAvailable) {
    biometricEnabled = await _showBiometricEnablePrompt(
      context,
      biometricAuthService,
    );
  }

  await appLockService.setBiometricEnabled(biometricEnabled);
  return true;
}

Future<bool> _showBiometricEnablePrompt(
  BuildContext context,
  BiometricAuthService biometricAuthService,
) async {
  final l10n = AppLocalizations.of(context)!;

  final enable = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_appLockModalTopColor, _appLockModalBottomColor],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.loginWithBiometrics,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFDF9F4), Color(0xFFF2E7DA)],
                  ),
                  border: Border.all(color: AppColors.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 34,
                  color: AppColors.background,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appLockBiometricEnableTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appLockBiometricEnableDescription,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.24),
                        ),
                        backgroundColor: _appLockModalFieldColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(l10n.appLockBiometricSkipButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.appLockBiometricEnableButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (enable != true) {
    return false;
  }

  return biometricAuthService.authenticate(
    reason: l10n.appLockBiometricEnableDescription,
  );
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final AppLockService _appLockService = AppLockService();
  final BiometricAuthService _biometricAuthService = BiometricAuthService();
  final TextEditingController _unlockPinController = TextEditingController();
  final FocusNode _unlockPinFocusNode = FocusNode();

  bool _pinConfigured = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLocked = false;
  bool _showPinUnlock = false;
  bool _isBiometricInFlight = false;
  bool _isUnlocking = false;
  bool _isLoadingState = true;
  bool _setupPromptActive = false;
  int _failedBiometricAttempts = 0;
  String? _unlockError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadStateAndMaybeLock(initial: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unlockPinController.dispose();
    _unlockPinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isBiometricInFlight || _setupPromptActive) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSessionOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (!_setupPromptActive && session.isAuthenticated && !_pinConfigured) {
      _setupPromptActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final configured = await _runMandatoryPinSetup();
        if (!mounted) return;
        setState(() {
          _pinConfigured = configured;
          _setupPromptActive = false;
        });
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isLocked || _isLoadingState)
          _AppLockOverlay(
            isLoadingState: _isLoadingState,
            isUnlocking: _isUnlocking,
            isBiometricInFlight: _isBiometricInFlight,
            showPinUnlock: _showPinUnlock,
            errorText: _unlockError,
            pinController: _unlockPinController,
            pinFocusNode: _unlockPinFocusNode,
            onUsePin: _showPinEntry,
            onUnlockPressed: _unlockWithPin,
            onRetryBiometric: _attemptBiometricUnlock,
          ),
      ],
    );
  }

  Future<void> _loadStateAndMaybeLock({required bool initial}) async {
    final authProvider = context.read<AuthProvider>();
    final pinConfigured = await _appLockService.hasPin();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final biometricAvailable = await _biometricAuthService.isAvailable();
    final hasStoredSession = await authProvider.hasStoredSessionForUnlock();

    if (!mounted) return;

    setState(() {
      _pinConfigured = pinConfigured;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _isLoadingState = false;
    });

    if (!pinConfigured || !hasStoredSession) {
      if (_isLocked && mounted) {
        setState(() {
          _isLocked = false;
          _showPinUnlock = false;
          _unlockError = null;
          _failedBiometricAttempts = 0;
        });
      }
      return;
    }

    if (!_isLocked) {
      setState(() {
        _isLocked = true;
        _showPinUnlock = !(_biometricEnabled && _biometricAvailable);
        _unlockError = null;
        _failedBiometricAttempts = 0;
        _unlockPinController.clear();
      });
    }

    if (_showPinUnlock) {
      _focusPinField();
      return;
    }

    if (initial || !_isBiometricInFlight) {
      await _attemptBiometricUnlock();
    }
  }

  Future<bool> _runMandatoryPinSetup() async {
    final configured = await ensureAppLockSetup(context);
    if (!mounted) return configured;

    final biometricAvailable = await _biometricAuthService.isAvailable();
    final biometricEnabled = await _appLockService.isBiometricEnabled();

    setState(() {
      _pinConfigured = configured;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
    });

    return configured;
  }

  Future<void> _attemptBiometricUnlock() async {
    if (!_isLocked || _isBiometricInFlight || _showPinUnlock) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBiometricInFlight = true;
      _unlockError = null;
    });

    final success = await _biometricAuthService.authenticate(
      reason: l10n.appLockBiometricUnlockDescription,
    );

    if (!mounted) return;

    setState(() {
      _isBiometricInFlight = false;
    });

    if (success) {
      await _completeUnlock();
      return;
    }

    setState(() {
      _failedBiometricAttempts += 1;
      if (_failedBiometricAttempts >= 3) {
        _showPinUnlock = true;
        _unlockError = l10n.appLockBiometricFallback;
      } else {
        _unlockError = l10n.appLockBiometricFailed;
      }
    });

    if (_showPinUnlock) {
      _focusPinField();
    }
  }

  void _showPinEntry() {
    if (!_isLocked) return;
    setState(() {
      _showPinUnlock = true;
      _unlockError = null;
    });
    _focusPinField();
  }

  Future<void> _unlockWithPin() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _unlockPinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _unlockError = l10n.appLockPinInvalid;
      });
      _focusPinField();
      return;
    }

    final valid = await _appLockService.verifyPin(pin);
    if (!mounted) return;
    if (!valid) {
      setState(() {
        _unlockPinController.clear();
        _unlockError = l10n.appLockPinIncorrect;
      });
      _focusPinField();
      return;
    }

    await _completeUnlock();
  }

  Future<void> _completeUnlock() async {
    if (_isUnlocking) return;
    setState(() {
      _isUnlocking = true;
      _unlockError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    await sessionProvider.restoreSession();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    final hasStoredSession = await authProvider.hasStoredSessionForUnlock();
    final unlockSucceeded =
        sessionProvider.isAuthenticated ||
        (authProvider.state == AuthState.authenticated && hasStoredSession);

    if (unlockSucceeded) {
      setState(() {
        _isUnlocking = false;
        _isLocked = false;
        _showPinUnlock = false;
        _unlockError = null;
        _failedBiometricAttempts = 0;
        _unlockPinController.clear();
      });
      return;
    }

    setState(() {
      _isUnlocking = false;
      _isLocked = false;
    });
  }

  Future<void> _refreshSessionOnResume() async {
    if (!mounted || _isLocked || _isLoadingState) {
      return;
    }

    final sessionProvider = context.read<SessionProvider>();
    final authProvider = context.read<AuthProvider>();

    await sessionProvider.refreshSessionSilently();
    if (!mounted) return;
    await authProvider.checkAuthStatus();
  }

  void _focusPinField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _unlockPinFocusNode.requestFocus();
    });
  }
}

class _AppLockOverlay extends StatelessWidget {
  const _AppLockOverlay({
    required this.isLoadingState,
    required this.isUnlocking,
    required this.isBiometricInFlight,
    required this.showPinUnlock,
    required this.errorText,
    required this.pinController,
    required this.pinFocusNode,
    required this.onUsePin,
    required this.onUnlockPressed,
    required this.onRetryBiometric,
  });

  final bool isLoadingState;
  final bool isUnlocking;
  final bool isBiometricInFlight;
  final bool showPinUnlock;
  final String? errorText;
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final VoidCallback onUsePin;
  final VoidCallback onUnlockPressed;
  final VoidCallback onRetryBiometric;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.56),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _appLockModalTopColor,
                          _appLockModalBottomColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              showPinUnlock ? 'PIN' : l10n.loginWithBiometrics,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFDF9F4), Color(0xFFF2E7DA)],
                            ),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            showPinUnlock
                                ? Icons.pin_outlined
                                : Icons.face_retouching_natural_rounded,
                            color: AppColors.background,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.appLockUnlockTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLoadingState
                              ? l10n.appLockLoading
                              : showPinUnlock
                              ? l10n.appLockPinUnlockDescription
                              : l10n.appLockBiometricUnlockDescription,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (isLoadingState) ...[
                          const Center(child: CircularProgressIndicator()),
                        ] else if (showPinUnlock) ...[
                          TextField(
                            controller: pinController,
                            focusNode: pinFocusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            obscuringCharacter: '•',
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => onUnlockPressed(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 10,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                letterSpacing: 10,
                              ),
                              filled: true,
                              fillColor: _appLockModalFieldColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: isUnlocking ? null : onUnlockPressed,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.95,
                              ),
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: isUnlocking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.appLockUnlockButton),
                          ),
                        ] else ...[
                          if (isBiometricInFlight)
                            const Center(child: CircularProgressIndicator()),
                          if (!isBiometricInFlight)
                            FilledButton.icon(
                              onPressed: onRetryBiometric,
                              icon: const Icon(Icons.face_rounded),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent.withValues(
                                  alpha: 0.95,
                                ),
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              label: Text(l10n.appLockRetryBiometricButton),
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: onUsePin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(
                                color: AppColors.accent.withValues(alpha: 0.24),
                              ),
                              backgroundColor: _appLockModalFieldColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(l10n.appLockUsePinButton),
                          ),
                        ],
                        if ((errorText ?? '').isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF8B8B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  String? _firstPin;
  String? _errorText;

  bool get _isConfirmStep => _firstPin != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_appLockModalTopColor, _appLockModalBottomColor],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFDF9F4), Color(0xFFF2E7DA)],
                          ),
                          border: Border.all(color: AppColors.accent, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.pin_outlined,
                          size: 34,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.appLockSetupTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConfirmStep
                            ? l10n.appLockSetupConfirmDescription
                            : l10n.appLockSetupDescription,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        obscuringCharacter: '•',
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() {
                              _errorText = null;
                            });
                          }
                        },
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 10,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            letterSpacing: 10,
                          ),
                          filled: true,
                          fillColor: _appLockModalFieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.20),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.20),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                        ),
                      ),
                      if ((_errorText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF8B8B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(
                            alpha: 0.95,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _isConfirmStep
                              ? l10n.appLockSetupConfirmButton
                              : l10n.appLockSetupCreateButton,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorText = l10n.appLockPinInvalid;
      });
      return;
    }

    if (!_isConfirmStep) {
      setState(() {
        _firstPin = pin;
        _pinController.clear();
        _errorText = null;
      });
      _pinFocusNode.requestFocus();
      return;
    }

    if (_firstPin != pin) {
      setState(() {
        _pinController.clear();
        _errorText = l10n.appLockSetupMismatch;
      });
      _pinFocusNode.requestFocus();
      return;
    }

    Navigator.of(context).pop(pin);
  }
}
