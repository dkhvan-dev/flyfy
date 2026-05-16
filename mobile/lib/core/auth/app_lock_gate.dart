import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../ui/app_colors.dart';
import '../../screens/auth/auth_responsive.dart';
import 'app_lock_service.dart';
import 'biometric_auth_service.dart';

const Color _appLockModalTopColor = Color(0xFF2E251B);
const Color _appLockModalBottomColor = Color(0xFF38250E);
const Color _appLockModalFieldColor = Color(0xFF332315);

IconData _appLockBiometricIcon(AppBiometricKind kind) {
  switch (kind) {
    case AppBiometricKind.face:
      return Icons.face_retouching_natural_rounded;
    case AppBiometricKind.fingerprint:
      return Icons.fingerprint_rounded;
    case AppBiometricKind.biometrics:
    case AppBiometricKind.none:
      return Icons.verified_user_rounded;
  }
}

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
  final biometricKind = await biometricAuthService.preferredBiometricKind();
  if (!context.mounted) {
    return false;
  }

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
                child: Icon(
                  _appLockBiometricIcon(biometricKind),
                  size: 34,
                  color: AppColors.textPrimary,
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

  await biometricAuthService.authenticate(
    reason: l10n.appLockBiometricEnableDescription,
  );
  return true;
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
  AppBiometricKind _biometricKind = AppBiometricKind.none;
  bool _isLocked = false;
  bool _showPinUnlock = false;
  bool _isBiometricInFlight = false;
  bool _isUnlocking = false;
  bool _isLoadingState = true;
  bool _setupPromptActive = false;
  int _failedBiometricAttempts = 0;
  String? _unlockError;
  bool _unlockSubmitQueued = false;
  bool _autoBiometricQueued = false;

  bool get _shouldAutoStartBiometric =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlockPinController.addListener(_handleUnlockPinControllerChanged);
    unawaited(_loadStateAndMaybeLock(initial: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unlockPinController.removeListener(_handleUnlockPinControllerChanged);
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
    final auth = context.watch<AuthProvider>();

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

    final shouldSuppressLockOverlay =
        auth.state == AuthState.unauthenticated && !session.isAuthenticated;

    if (shouldSuppressLockOverlay &&
        (_isLocked ||
            _showPinUnlock ||
            _unlockError != null ||
            _isLoadingState ||
            _isUnlocking ||
            _isBiometricInFlight ||
            _failedBiometricAttempts != 0 ||
            _unlockPinController.text.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isLocked = false;
          _showPinUnlock = false;
          _isBiometricInFlight = false;
          _isUnlocking = false;
          _isLoadingState = false;
          _unlockError = null;
          _failedBiometricAttempts = 0;
          _unlockPinController.clear();
        });
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if ((_isLocked || _isLoadingState) && !shouldSuppressLockOverlay)
          _AppLockOverlay(
            isLoadingState: _isLoadingState,
            isUnlocking: _isUnlocking,
            isBiometricInFlight: _isBiometricInFlight,
            biometricKind: _biometricKind,
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
    final biometricKind = await _biometricAuthService.preferredBiometricKind();
    final biometricAvailable = biometricKind != AppBiometricKind.none;
    final hasStoredSession = await authProvider.hasStoredSessionForUnlock();

    if (!mounted) return;

    setState(() {
      _pinConfigured = pinConfigured;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _biometricKind = biometricKind;
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

    if (_shouldAutoStartBiometric && (initial || !_isBiometricInFlight)) {
      _scheduleAutoBiometricUnlock();
    }
  }

  void _scheduleAutoBiometricUnlock() {
    if (_autoBiometricQueued ||
        !_isLocked ||
        _showPinUnlock ||
        _isBiometricInFlight) {
      return;
    }

    _autoBiometricQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }

      _autoBiometricQueued = false;
      if (!mounted || !_isLocked || _showPinUnlock || _isBiometricInFlight) {
        return;
      }

      await _attemptBiometricUnlock();
    });
  }

  Future<bool> _runMandatoryPinSetup() async {
    final configured = await ensureAppLockSetup(context);
    if (!mounted) return configured;

    final biometricKind = await _biometricAuthService.preferredBiometricKind();
    final biometricAvailable = biometricKind != AppBiometricKind.none;
    final biometricEnabled = await _appLockService.isBiometricEnabled();

    setState(() {
      _pinConfigured = configured;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _biometricKind = biometricKind;
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

    final outcome = await _biometricAuthService.authenticateWithOutcome(
      reason: l10n.appLockBiometricUnlockDescription,
    );

    if (!mounted) return;

    setState(() {
      _isBiometricInFlight = false;
    });

    if (outcome.result == AppBiometricAttemptResult.success) {
      await _completeUnlock();
      return;
    }

    if (outcome.result == AppBiometricAttemptResult.canceled) {
      return;
    }

    if (outcome.result == AppBiometricAttemptResult.fallbackToPin) {
      setState(() {
        _showPinUnlock = true;
        _unlockError = l10n.appLockBiometricFallback;
      });
      _focusPinField();
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
    if (_isUnlocking) return;
    _unlockSubmitQueued = false;
    final l10n = AppLocalizations.of(context)!;
    final pin = _unlockPinController.text.trim();
    _dismissKeyboard();
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

  void _handleUnlockPinControllerChanged() {
    if (!_showPinUnlock || !_isLocked) {
      _unlockSubmitQueued = false;
      return;
    }

    final value = _unlockPinController.text.trim();
    if (_unlockError != null) {
      setState(() {
        _unlockError = null;
      });
    }

    if (value.trim().length != 4 || _isUnlocking) {
      _unlockSubmitQueued = false;
      return;
    }

    if (_unlockSubmitQueued) {
      return;
    }

    _unlockSubmitQueued = true;
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      if (!_showPinUnlock || !_isLocked) {
        _unlockSubmitQueued = false;
        return;
      }
      if (_unlockPinController.text.trim().length != 4) {
        _unlockSubmitQueued = false;
        return;
      }
      _dismissKeyboard();
      unawaited(_unlockWithPin());
    });
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
    final unlockSucceeded = sessionProvider.isAuthenticated ||
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

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class _AppLockOverlay extends StatelessWidget {
  const _AppLockOverlay({
    required this.isLoadingState,
    required this.isUnlocking,
    required this.isBiometricInFlight,
    required this.biometricKind,
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
  final AppBiometricKind biometricKind;
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

    return AuthResponsiveTextScope(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.56),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final compactHeight =
                    constraints.maxHeight < 720 || textScale > 1.02;
                final horizontalPadding = authScaled(
                  context,
                  compactHeight ? 18 : 24,
                  min: 14,
                  max: 24,
                );
                final cardPadding = authScaled(
                  context,
                  compactHeight ? 20 : 24,
                  min: 16,
                  max: 24,
                );
                final iconSize = authScaled(context, 72, min: 58, max: 72);
                final borderRadius = authScaled(context, 30, min: 24, max: 30);

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
                    padding: EdgeInsets.all(horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                cardPadding,
                                authScaled(context, 28, min: 20, max: 28),
                                cardPadding,
                                cardPadding,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _appLockModalTopColor,
                                    _appLockModalBottomColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: authScaled(
                                      context,
                                      22,
                                      min: 16,
                                      max: 22,
                                    ),
                                    offset: Offset(
                                      0,
                                      authScaled(context, 10, min: 6, max: 10),
                                    ),
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: authScaled(
                                          context,
                                          10,
                                          min: 8,
                                          max: 10,
                                        ),
                                        vertical: authScaled(
                                          context,
                                          6,
                                          min: 4,
                                          max: 6,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        showPinUnlock
                                            ? 'PIN'
                                            : l10n.loginWithBiometrics,
                                        style: TextStyle(
                                          fontSize: authScaled(
                                            context,
                                            12,
                                            min: 11,
                                            max: 12,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      18,
                                      min: 14,
                                      max: 18,
                                    ),
                                  ),
                                  Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFFDF9F4),
                                          Color(0xFFF2E7DA),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.accent,
                                        width: authScaled(
                                          context,
                                          3,
                                          min: 2,
                                          max: 3,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: authScaled(
                                            context,
                                            22,
                                            min: 16,
                                            max: 22,
                                          ),
                                          offset: Offset(
                                            0,
                                            authScaled(
                                              context,
                                              10,
                                              min: 6,
                                              max: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      showPinUnlock
                                          ? Icons.pin_outlined
                                          : _appLockBiometricIcon(
                                              biometricKind,
                                            ),
                                      color: AppColors.background,
                                      size: authScaled(
                                        context,
                                        34,
                                        min: 28,
                                        max: 34,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      20,
                                      min: 16,
                                      max: 20,
                                    ),
                                  ),
                                  Text(
                                    l10n.appLockUnlockTitle,
                                    style: TextStyle(
                                      fontSize: authScaled(
                                        context,
                                        24,
                                        min: 20,
                                        max: 24,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
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
                                    isLoadingState
                                        ? l10n.appLockLoading
                                        : showPinUnlock
                                            ? l10n.appLockPinUnlockDescription
                                            : l10n
                                                .appLockBiometricUnlockDescription,
                                    style: TextStyle(
                                      fontSize: authScaled(
                                        context,
                                        15,
                                        min: 14,
                                        max: 15,
                                      ),
                                      height: 1.45,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      24,
                                      min: 18,
                                      max: 24,
                                    ),
                                  ),
                                  if (isLoadingState) ...[
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
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
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      onSubmitted: (_) => onUnlockPressed(),
                                      style: TextStyle(
                                        fontSize: authScaled(
                                          context,
                                          28,
                                          min: 24,
                                          max: 28,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: authScaled(
                                          context,
                                          10,
                                          min: 8,
                                          max: 10,
                                        ),
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: '••••',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          letterSpacing: authScaled(
                                            context,
                                            10,
                                            min: 8,
                                            max: 10,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: _appLockModalFieldColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            authScaled(
                                              context,
                                              20,
                                              min: 16,
                                              max: 20,
                                            ),
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.accent.withValues(
                                              alpha: 0.20,
                                            ),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            authScaled(
                                              context,
                                              20,
                                              min: 16,
                                              max: 20,
                                            ),
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.accent.withValues(
                                              alpha: 0.20,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            authScaled(
                                              context,
                                              20,
                                              min: 16,
                                              max: 20,
                                            ),
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: authScaled(
                                        context,
                                        16,
                                        min: 12,
                                        max: 16,
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          isUnlocking ? null : onUnlockPressed,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.accent
                                            .withValues(alpha: 0.95),
                                        foregroundColor: AppColors.textPrimary,
                                        minimumSize: Size(
                                          0,
                                          authScaled(
                                            context,
                                            52,
                                            min: 48,
                                            max: 52,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: authScaled(
                                            context,
                                            14,
                                            min: 12,
                                            max: 14,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            authScaled(
                                              context,
                                              20,
                                              min: 16,
                                              max: 20,
                                            ),
                                          ),
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
                                          : Text(
                                              l10n.appLockUnlockButton,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ] else ...[
                                    if (isBiometricInFlight)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    if (!isBiometricInFlight)
                                      FilledButton.icon(
                                        onPressed: onRetryBiometric,
                                        icon: Icon(
                                          _appLockBiometricIcon(biometricKind),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.accent
                                              .withValues(alpha: 0.95),
                                          foregroundColor:
                                              AppColors.textPrimary,
                                          minimumSize: Size(
                                            0,
                                            authScaled(
                                              context,
                                              54,
                                              min: 50,
                                              max: 54,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: authScaled(
                                              context,
                                              16,
                                              min: 14,
                                              max: 16,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              authScaled(
                                                context,
                                                20,
                                                min: 16,
                                                max: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        label: Text(
                                          l10n.appLockRetryBiometricButton,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
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
                                    OutlinedButton(
                                      onPressed: onUsePin,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accent,
                                        side: BorderSide(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.24,
                                          ),
                                        ),
                                        backgroundColor:
                                            _appLockModalFieldColor,
                                        minimumSize: Size(
                                          0,
                                          authScaled(
                                            context,
                                            54,
                                            min: 50,
                                            max: 54,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: authScaled(
                                            context,
                                            16,
                                            min: 14,
                                            max: 16,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            authScaled(
                                              context,
                                              20,
                                              min: 16,
                                              max: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.appLockUsePinButton,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if ((errorText ?? '').isNotEmpty) ...[
                                    SizedBox(
                                      height: authScaled(
                                        context,
                                        14,
                                        min: 10,
                                        max: 14,
                                      ),
                                    ),
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
                );
              },
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
  bool _submitQueued = false;

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
        body: AuthResponsiveTextScope(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final compactHeight =
                    constraints.maxHeight < 720 || textScale > 1.02;
                final horizontalPadding = authScaled(
                  context,
                  compactHeight ? 18 : 24,
                  min: 14,
                  max: 24,
                );
                final cardPadding = authScaled(
                  context,
                  compactHeight ? 20 : 24,
                  min: 16,
                  max: 24,
                );
                final iconSize = authScaled(context, 72, min: 58, max: 72);
                final borderRadius = authScaled(context, 30, min: 24, max: 30);

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
                    padding: EdgeInsets.all(horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                cardPadding,
                                authScaled(context, 28, min: 20, max: 28),
                                cardPadding,
                                cardPadding,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _appLockModalTopColor,
                                    _appLockModalBottomColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: authScaled(
                                      context,
                                      22,
                                      min: 16,
                                      max: 22,
                                    ),
                                    offset: Offset(
                                      0,
                                      authScaled(context, 10, min: 6, max: 10),
                                    ),
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: authScaled(
                                          context,
                                          10,
                                          min: 8,
                                          max: 10,
                                        ),
                                        vertical: authScaled(
                                          context,
                                          6,
                                          min: 4,
                                          max: 6,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'PIN',
                                        style: TextStyle(
                                          fontSize: authScaled(
                                            context,
                                            12,
                                            min: 11,
                                            max: 12,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      18,
                                      min: 14,
                                      max: 18,
                                    ),
                                  ),
                                  Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFFDF9F4),
                                          Color(0xFFF2E7DA),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.accent,
                                        width: authScaled(
                                          context,
                                          3,
                                          min: 2,
                                          max: 3,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: authScaled(
                                            context,
                                            22,
                                            min: 16,
                                            max: 22,
                                          ),
                                          offset: Offset(
                                            0,
                                            authScaled(
                                              context,
                                              10,
                                              min: 6,
                                              max: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.pin_outlined,
                                      size: authScaled(
                                        context,
                                        34,
                                        min: 28,
                                        max: 34,
                                      ),
                                      color: AppColors.background,
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      20,
                                      min: 16,
                                      max: 20,
                                    ),
                                  ),
                                  Text(
                                    l10n.appLockSetupTitle,
                                    style: TextStyle(
                                      fontSize: authScaled(
                                        context,
                                        24,
                                        min: 20,
                                        max: 24,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
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
                                    _isConfirmStep
                                        ? l10n.appLockSetupConfirmDescription
                                        : l10n.appLockSetupDescription,
                                    style: TextStyle(
                                      fontSize: authScaled(
                                        context,
                                        15,
                                        min: 14,
                                        max: 15,
                                      ),
                                      height: 1.45,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      24,
                                      min: 18,
                                      max: 24,
                                    ),
                                  ),
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
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    onChanged: _handlePinChanged,
                                    onSubmitted: (_) => _submit(),
                                    style: TextStyle(
                                      fontSize: authScaled(
                                        context,
                                        28,
                                        min: 24,
                                        max: 28,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: authScaled(
                                        context,
                                        10,
                                        min: 8,
                                        max: 10,
                                      ),
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '••••',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        letterSpacing: authScaled(
                                          context,
                                          10,
                                          min: 8,
                                          max: 10,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: _appLockModalFieldColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          authScaled(
                                            context,
                                            20,
                                            min: 16,
                                            max: 20,
                                          ),
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.20,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          authScaled(
                                            context,
                                            20,
                                            min: 16,
                                            max: 20,
                                          ),
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.20,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          authScaled(
                                            context,
                                            20,
                                            min: 16,
                                            max: 20,
                                          ),
                                        ),
                                        borderSide: const BorderSide(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if ((_errorText ?? '').isNotEmpty) ...[
                                    SizedBox(
                                      height: authScaled(
                                        context,
                                        12,
                                        min: 10,
                                        max: 12,
                                      ),
                                    ),
                                    Text(
                                      _errorText!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFF8B8B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  SizedBox(
                                    height: authScaled(
                                      context,
                                      18,
                                      min: 14,
                                      max: 18,
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accent
                                          .withValues(alpha: 0.95),
                                      minimumSize: Size(
                                        0,
                                        authScaled(
                                          context,
                                          52,
                                          min: 48,
                                          max: 52,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: authScaled(
                                          context,
                                          14,
                                          min: 12,
                                          max: 14,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          authScaled(
                                            context,
                                            20,
                                            min: 16,
                                            max: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _isConfirmStep
                                          ? l10n.appLockSetupConfirmButton
                                          : l10n.appLockSetupCreateButton,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
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
              },
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    _submitQueued = false;
    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    _dismissKeyboard();
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

  void _handlePinChanged(String value) {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }

    if (value.trim().length != 4) {
      _submitQueued = false;
      return;
    }

    if (_submitQueued) {
      return;
    }

    _submitQueued = true;
    _dismissKeyboard();
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      if (_pinController.text.trim().length != 4) {
        _submitQueued = false;
        return;
      }
      _submit();
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
