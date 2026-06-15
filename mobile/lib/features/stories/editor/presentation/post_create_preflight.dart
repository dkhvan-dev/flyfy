import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/post_api.dart';
import '../../../../core/ui/app_colors.dart';
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
    await _showPostRateLimitSheet(context, eligibility);
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

Future<void> _showPostRateLimitSheet(
  BuildContext context,
  PostCreateEligibilityVm eligibility,
) {
  final l10n = AppLocalizations.of(context)!;
  final retrySeconds = eligibility.retryAfter.inSeconds;
  final retryMinutes = retrySeconds <= 0 ? 1 : ((retrySeconds + 59) ~/ 60);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.postCreateRateLimitTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.postCreateRateLimitMessage(retryMinutes),
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.postCreateRateLimitAction),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showPreflightWarning(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.postCreatePreflightFailed),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
