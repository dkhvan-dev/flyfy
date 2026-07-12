import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/post_api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../providers/auth_provider.dart';

Future<bool> ensurePostCreateAllowed(
  BuildContext context, {
  required PostApi postApi,
  required String loginFrom,
}) async {
  final authProvider = context.read<AuthProvider>();
  if (authProvider.state != AuthState.authenticated) {
    context.push(
      Uri(path: '/login', queryParameters: {'from': loginFrom}).toString(),
    );
    return false;
  }

  try {
    final eligibility = await postApi.checkCreateEligibility();
    if (eligibility.canCreate) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    await showPostRateLimitSheet(
      context,
      retryAfter: eligibility.retryAfter,
      nextAvailableAt: eligibility.nextAvailableAt,
    );
    return false;
  } on DioException catch (error) {
    if (!context.mounted) {
      return false;
    }
    if (error.response?.statusCode == 401) {
      context.push(
        Uri(path: '/login', queryParameters: {'from': loginFrom}).toString(),
      );
      return false;
    }
    _showPreflightWarning(context);
    return true;
  } catch (_) {
    if (!context.mounted) {
      return false;
    }
    _showPreflightWarning(context);
    return true;
  }
}

Future<void> showPostRateLimitSheet(
  BuildContext context, {
  required Duration retryAfter,
  DateTime? nextAvailableAt,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colors = AppDesignSystem.colorsFor(context);
  return showAppModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    showDragHandle: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppBorderRadius.vertical(top: AppRadiusValue.circular(28)),
    ),
    builder: (sheetContext) {
      final colors = AppDesignSystem.colorsFor(sheetContext);
      final theme = AppDesignSystem.themeFor(sheetContext);

      return Theme(
        data: theme,
        child: SafeArea(
          child: Padding(
            padding: const AppEdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: AppBoxDecoration(
                    color: colors.primary.withValues(alpha: 0.16),
                    borderRadius: AppBorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.hourglass_bottom_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.postCreateRateLimitTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                PostRateLimitCountdownText(
                  retryAfter: retryAfter,
                  nextAvailableAt: nextAvailableAt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.postCreateRateLimitAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PostRateLimitCountdownText extends StatefulWidget {
  const PostRateLimitCountdownText({
    super.key,
    required this.retryAfter,
    this.nextAvailableAt,
    this.style,
    this.textAlign,
    this.onElapsed,
    this.now = DateTime.now,
  });

  final Duration retryAfter;
  final DateTime? nextAvailableAt;
  final TextStyle? style;
  final TextAlign? textAlign;
  final VoidCallback? onElapsed;
  final DateTime Function() now;

  @override
  State<PostRateLimitCountdownText> createState() =>
      _PostRateLimitCountdownTextState();
}

class _PostRateLimitCountdownTextState
    extends State<PostRateLimitCountdownText> {
  Timer? _timer;
  late DateTime _deadline;
  Duration _remaining = Duration.zero;
  bool _elapsedNotified = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(PostRateLimitCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryAfter != widget.retryAfter ||
        oldWidget.nextAvailableAt != widget.nextAvailableAt) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _elapsedNotified = false;
    final now = widget.now().toUtc();
    _deadline = widget.retryAfter > Duration.zero
        ? now.add(widget.retryAfter)
        : widget.nextAvailableAt?.toUtc() ?? now;
    _updateRemaining(notify: false);
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
    }
  }

  void _updateRemaining({bool notify = true}) {
    final difference = _deadline.difference(widget.now().toUtc());
    final remaining = difference <= Duration.zero
        ? Duration.zero
        : Duration(seconds: (difference.inMilliseconds + 999) ~/ 1000);
    if (notify && mounted) {
      setState(() => _remaining = remaining);
    } else {
      _remaining = remaining;
    }
    if (remaining == Duration.zero && !_elapsedNotified) {
      _elapsedNotified = true;
      _timer?.cancel();
      widget.onElapsed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.postCreateRateLimitMessage(_formatCountdown(_remaining)),
      key: const ValueKey('post-rate-limit-countdown'),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

String _formatCountdown(Duration value) {
  final seconds = value.inSeconds.clamp(0, 359999);
  final minutesPart = seconds ~/ 60;
  final secondsPart = seconds % 60;
  return '${minutesPart.toString().padLeft(2, '0')}:'
      '${secondsPart.toString().padLeft(2, '0')}';
}

void _showPreflightWarning(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final colors = AppDesignSystem.colorsFor(context);
  final theme = AppDesignSystem.themeFor(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(
      MaterialBanner(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: Container(
          width: 40,
          height: 40,
          decoration: AppBoxDecoration(
            color: colors.primary.withValues(alpha: 0.14),
            borderRadius: AppBorderRadius.circular(14),
          ),
          child: Icon(Icons.info_outline_rounded, color: colors.primary),
        ),
        content: Text(
          l10n.postCreatePreflightFailed,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
}
