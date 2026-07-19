import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_design_system.dart';
import '../../features/saved/domain/saved_operation.dart';
import '../../features/saved/domain/saved_target.dart';
import '../../features/saved/presentation/state/saved_screen_controller.dart';
import '../../features/saved/presentation/widgets/saved_bookmark_button.dart';
import '../../providers/session_provider.dart';

class AppSavedBookmarkButton extends StatelessWidget {
  const AppSavedBookmarkButton({
    super.key,
    required this.target,
    required this.sourceSurface,
    this.previewTitle,
    this.previewSubtitle,
    this.previewImageUrl,
  });

  final SavedTarget target;
  final SavedSourceSurface sourceSurface;
  final String? previewTitle;
  final String? previewSubtitle;
  final String? previewImageUrl;

  @override
  Widget build(BuildContext context) {
    // Public routes and reusable cards can be rendered in isolation (for
    // previews, tests, or nested navigators) without the app-level Saved tree.
    if (context.read<SessionProvider?>() == null ||
        context.read<SavedScreenController?>() == null) {
      return const SizedBox.shrink();
    }

    final sessionStatus = context.select<SessionProvider, SessionStatus>(
      (session) => session.status,
    );
    final isAuthResolved =
        sessionStatus == SessionStatus.authenticated ||
        sessionStatus == SessionStatus.unauthenticated;
    final isAuthenticated = sessionStatus == SessionStatus.authenticated;
    final isOnline = context.select<SavedScreenController, bool>(
      (controller) => controller.isOnline,
    );

    // Own taps that a disabled bookmark cannot claim from an ancestor card.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () {},
      child: SizedBox.square(
        dimension: AppSizes.minTapTarget,
        child: SavedBookmarkButton(
          target: target,
          sourceSurface: sourceSurface,
          isAuthResolved: isAuthResolved,
          isAuthenticated: isAuthenticated,
          isOnline: isOnline,
          previewTitle: previewTitle,
          previewSubtitle: previewSubtitle,
          previewImageUrl: previewImageUrl,
          onAuthRequired: () {
            final from = GoRouterState.of(context).uri.toString();
            context.push('/login?from=${Uri.encodeComponent(from)}');
          },
        ),
      ),
    );
  }
}
