import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/post_api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

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
  return showAppModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    showDragHandle: true,
    backgroundColor: AppPalette.surfaceCool,
    shape: const RoundedRectangleBorder(
      borderRadius: AppBorderRadius.vertical(top: AppRadiusValue.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
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
                  color: AppPalette.primary.withValues(alpha: 0.16),
                  borderRadius: AppBorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: AppPalette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.postCreateRateLimitTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.postCreateRateLimitMessage(retryMinutes),
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textCoolSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    foregroundColor: AppPalette.textPrimary,
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
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppPalette.surfaceCool,
        elevation: 1,
        leading: Container(
          width: 40,
          height: 40,
          decoration: AppBoxDecoration(
            color: AppPalette.primary.withValues(alpha: 0.14),
            borderRadius: AppBorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppPalette.primary,
          ),
        ),
        content: Text(
          l10n.postCreatePreflightFailed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppPalette.textPrimary,
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
