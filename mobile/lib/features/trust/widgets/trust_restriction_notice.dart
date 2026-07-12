import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_design_system.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'trust_status_banner.dart';

class TrustRestrictionNotice extends StatelessWidget {
  const TrustRestrictionNotice({super.key, this.creation = false});

  final bool creation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TrustStatusBanner(
      kind: TrustStatusBannerKind.blocked,
      title: l10n.trustRestrictionTitle,
      message: creation
          ? l10n.trustCreationRestrictionMessage
          : l10n.trustFeatureRestrictionMessage,
      actionLabel: l10n.trustRestrictionSupportAction,
      onAction: () => context.push('/help/support'),
    );
  }
}

class TrustRestrictedScaffold extends StatelessWidget {
  const TrustRestrictedScaffold({super.key, this.creation = false});

  final bool creation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.trustRestrictionTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const AppEdgeInsets.all(16),
              child: TrustRestrictionNotice(creation: creation),
            ),
          ),
        ),
      ),
    );
  }
}
