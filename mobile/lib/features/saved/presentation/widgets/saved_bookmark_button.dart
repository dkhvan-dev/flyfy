import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/app_design_system.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/saved_operation.dart';
import '../../domain/saved_status.dart';
import '../../domain/saved_target.dart';
import '../saved_ui_messages.dart';
import '../state/saved_screen_controller.dart';
import '../state/saved_state_registry.dart';
import 'saved_collection_picker.dart';

class SavedBookmarkButton extends StatefulWidget {
  const SavedBookmarkButton({
    super.key,
    required this.target,
    required this.sourceSurface,
    required this.isAuthResolved,
    required this.isAuthenticated,
    required this.isOnline,
    required this.onAuthRequired,
    this.previewTitle,
    this.previewSubtitle,
    this.previewImageUrl,
    this.controller,
  }) : assert(
         sourceSurface == SavedSourceSurface.card ||
             sourceSurface == SavedSourceSurface.detail,
         'SavedBookmarkButton only supports CARD and DETAIL surfaces.',
       );

  final SavedTarget target;
  final SavedSourceSurface sourceSurface;
  final bool isAuthResolved;
  final bool isAuthenticated;
  final bool isOnline;
  final VoidCallback onAuthRequired;
  final String? previewTitle;
  final String? previewSubtitle;
  final String? previewImageUrl;
  final SavedScreenController? controller;

  @override
  State<SavedBookmarkButton> createState() => _SavedBookmarkButtonState();
}

class _SavedBookmarkButtonState extends State<SavedBookmarkButton> {
  SavedScreenController? _controller;
  int _lifecycleEpoch = 0;
  bool _actionInFlight = false;
  bool _bootstrapScheduled = false;
  bool _targetUnavailable = false;
  String? _localError;

  SavedScreenController get _boundController => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindController(widget.controller ?? context.read<SavedScreenController>());
    _scheduleBootstrap();
  }

  @override
  void didUpdateWidget(covariant SavedBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _bindController(
        widget.controller ?? context.read<SavedScreenController>(),
      );
    }
    if (oldWidget.target != widget.target) {
      _localError = null;
      _actionInFlight = false;
      _targetUnavailable = false;
    }
    _scheduleBootstrap();
  }

  @override
  void dispose() {
    _unbindController();
    super.dispose();
  }

  void _bindController(SavedScreenController controller) {
    if (identical(_controller, controller)) return;
    _unbindController();
    _controller = controller;
    _lifecycleEpoch = controller.lifecycleEpoch;
    controller.addListener(_handleControllerChanged);
    controller.registry.addListener(_handleControllerChanged);
  }

  void _unbindController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_handleControllerChanged);
    controller.registry.removeListener(_handleControllerChanged);
    _controller = null;
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final controller = _boundController;
    if (_lifecycleEpoch != controller.lifecycleEpoch) {
      _lifecycleEpoch = controller.lifecycleEpoch;
      _localError = null;
      _actionInFlight = false;
      _targetUnavailable = false;
    }
    setState(() {});
    _scheduleBootstrap();
  }

  void _scheduleBootstrap() {
    final controller = _controller;
    if (_bootstrapScheduled ||
        controller == null ||
        !widget.isAuthResolved ||
        !widget.isAuthenticated ||
        !widget.isOnline ||
        controller.isTargetBootstrapping(widget.target) ||
        controller.hasTargetStatusSnapshot(widget.target) ||
        controller.targetStatusError(widget.target) != null ||
        controller.registry.peekStateFor(widget.target).state !=
            SavedRegistryState.unknown) {
      return;
    }
    _bootstrapScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapScheduled = false;
      if (!mounted) return;
      unawaited(controller.ensureCapabilities());
      controller.queueTargetStatusBootstrap(widget.target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _boundController;
    final state = controller.registry.peekStateFor(widget.target);
    final isBootstrapping = controller.isTargetBootstrapping(widget.target);
    final isMutationRequestInFlight = controller
        .isTargetMutationRequestInFlight(widget.target);
    final isAssignmentPending = controller.isAssignmentPending(widget.target);
    final isAssignmentRequestInFlight = controller.isAssignmentRequestInFlight(
      widget.target,
    );
    final targetStatusError = controller.targetStatusError(widget.target);
    final l10n = AppLocalizations.of(context)!;
    final hasUnknownStatusSnapshot =
        state.state == SavedRegistryState.unknown &&
        controller.hasTargetStatusSnapshot(widget.target);
    final errorMessage =
        _localError ??
        (targetStatusError == null
            ? null
            : savedErrorMessage(l10n, targetStatusError));
    final hasError = errorMessage != null;
    final isLoading =
        !widget.isAuthResolved ||
        _actionInFlight ||
        isBootstrapping ||
        isMutationRequestInFlight ||
        isAssignmentPending ||
        isAssignmentRequestInFlight;
    final canSaveFromUnknown =
        !_targetUnavailable &&
        hasUnknownStatusSnapshot &&
        controller.isBookmarkExpansionAvailable(widget.target);
    final canSaveFromConfirmedUnsaved =
        !_targetUnavailable &&
        state.shouldRenderUnsaved &&
        state.eligibility == SavedEligibility.eligible &&
        controller.isBookmarkExpansionAvailable(widget.target);
    final canSave = canSaveFromUnknown || canSaveFromConfirmedUnsaved;
    final isUnavailable =
        _targetUnavailable ||
        ((state.shouldRenderUnsaved || hasUnknownStatusSnapshot) && !canSave);
    final canPress =
        widget.isAuthResolved &&
        !_actionInFlight &&
        !isBootstrapping &&
        !isMutationRequestInFlight &&
        !isAssignmentPending;
    final tooltip = _tooltipFor(
      l10n,
      state,
      isLoading: isLoading,
      errorMessage: errorMessage,
      isUnavailable: isUnavailable,
      canSaveFromUnknown: canSaveFromUnknown,
    );
    final colors = AppDesignSystem.colorsFor(context);
    final iconColor =
        hasError || state.state == SavedRegistryState.pendingUnknown
        ? colors.danger
        : state.shouldRenderSaved
        ? colors.primary
        : isUnavailable
        ? colors.white.withValues(alpha: 0.72)
        : colors.white;
    final buttonStyle = AppButtonStyles.icon(colors).copyWith(
      backgroundColor: WidgetStatePropertyAll(
        state.shouldRenderSaved
            ? colors.black.withValues(alpha: 0.82)
            : colors.black.withValues(alpha: 0.68),
      ),
      side: WidgetStatePropertyAll(
        BorderSide(
          color: state.shouldRenderSaved
              ? colors.primary.withValues(alpha: 0.88)
              : colors.white.withValues(alpha: 0.24),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        enabled: canPress,
        label: tooltip,
        toggled: widget.isAuthResolved
            ? state.shouldRenderSaved
                  ? true
                  : state.shouldRenderUnsaved
                  ? false
                  : null
            : null,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppSizes.minTapTarget,
            child: IconButton(
              key: ValueKey(
                'saved-bookmark-${widget.target.entityType.wireValue}-${widget.target.entityId}',
              ),
              onPressed: canPress ? () => unawaited(_handlePressed()) : null,
              padding: AppInsets.none,
              constraints: const BoxConstraints.tightFor(
                width: AppSizes.minTapTarget,
                height: AppSizes.minTapTarget,
              ),
              style: buttonStyle,
              icon: _BookmarkIcon(
                state: state,
                isLoading: isLoading,
                color: iconColor,
                canSaveFromUnknown: canSaveFromUnknown,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tooltipFor(
    AppLocalizations l10n,
    SavedTargetState state, {
    required bool isLoading,
    required String? errorMessage,
    required bool isUnavailable,
    required bool canSaveFromUnknown,
  }) {
    if (!widget.isAuthResolved) return l10n.savedBookmarkCheckingTooltip;
    if (!widget.isAuthenticated) return l10n.savedBookmarkAuthTooltip;
    if (errorMessage != null) return errorMessage;
    if (state.state == SavedRegistryState.pendingUnknown) {
      return l10n.savedBookmarkPendingUnknownTooltip;
    }
    if (isLoading || state.state == SavedRegistryState.pending) {
      return state.state == SavedRegistryState.unknown
          ? l10n.savedBookmarkCheckingTooltip
          : l10n.savedBookmarkUpdatingTooltip;
    }
    if (canSaveFromUnknown) return l10n.savedBookmarkSaveTooltip;
    if (isUnavailable) return l10n.savedBookmarkUnavailableTooltip;
    if (state.shouldRenderSaved) return l10n.savedBookmarkManageTooltip;
    if (state.shouldRenderUnsaved) return l10n.savedBookmarkSaveTooltip;
    return l10n.savedBookmarkCheckingTooltip;
  }

  Future<void> _handlePressed() async {
    if (_actionInFlight) return;
    if (!widget.isAuthResolved) return;
    if (!widget.isAuthenticated) {
      widget.onAuthRequired();
      return;
    }
    final controller = _boundController;
    if (!controller.isBookmarkExpansionAvailable(widget.target)) {
      await _runGuarded(() => controller.ensureCapabilities(force: true));
      if (!mounted) return;
      if (!controller.isBookmarkExpansionAvailable(widget.target)) {
        final capabilitiesError = controller.initializationError;
        if (capabilitiesError != null) {
          _setError(
            savedErrorMessage(AppLocalizations.of(context)!, capabilitiesError),
          );
        } else {
          _showUnavailableMessage();
        }
        return;
      }
    }

    final state = controller.registry.peekStateFor(widget.target);
    if (state.state == SavedRegistryState.unknown) {
      if (!controller.hasTargetStatusSnapshot(widget.target)) {
        await _bootstrapStatus(showError: true);
        return;
      }
      await _runGuarded(_saveAndOpenCollectionPicker);
      return;
    }
    if (controller.isTargetMutationRequestInFlight(widget.target)) return;
    if (state.isLocked) {
      await _runGuarded(() async {
        final result = await controller.resolveBookmarkMutation(widget.target);
        await _handleConfirmedResult(result);
      });
      return;
    }
    if (state.shouldRenderSaved) {
      await _runGuarded(_openCollectionPicker);
      return;
    }
    if (state.shouldRenderUnsaved &&
        state.eligibility == SavedEligibility.eligible &&
        controller.isBookmarkExpansionAvailable(widget.target)) {
      await _runGuarded(_saveAndOpenCollectionPicker);
      return;
    }
    if (state.shouldRenderUnsaved) {
      await _runGuarded(_refreshStatusAndSaveIfAvailable);
      return;
    }
    _showUnavailableMessage();
  }

  Future<void> _bootstrapStatus({required bool showError}) async {
    if (_actionInFlight) return;
    await _runGuarded(() async {
      await _boundController.bootstrapTargetStatuses(<SavedTarget>[
        widget.target,
      ], force: true);
    }, showError: showError);
  }

  Future<void> _saveAndOpenCollectionPicker() async {
    final controller = _boundController;
    final result = await controller.saveBookmark(
      widget.target,
      sourceSurface: widget.sourceSurface,
    );
    await _handleConfirmedResult(result);
  }

  Future<void> _refreshStatusAndSaveIfAvailable() async {
    final controller = _boundController;
    await controller.bootstrapTargetStatuses(<SavedTarget>[
      widget.target,
    ], force: true);
    if (!mounted) return;

    final refreshed = controller.registry.peekStateFor(widget.target);
    if (refreshed.shouldRenderSaved) {
      setState(() => _targetUnavailable = false);
      await _openCollectionPicker();
      return;
    }
    final canSaveFromUnknown =
        refreshed.state == SavedRegistryState.unknown &&
        controller.hasTargetStatusSnapshot(widget.target);
    final canSaveFromConfirmedUnsaved =
        refreshed.shouldRenderUnsaved &&
        refreshed.eligibility == SavedEligibility.eligible;
    if ((canSaveFromUnknown || canSaveFromConfirmedUnsaved) &&
        controller.isBookmarkExpansionAvailable(widget.target)) {
      setState(() => _targetUnavailable = false);
      await _saveAndOpenCollectionPicker();
      return;
    }
    _showUnavailableMessage();
  }

  Future<void> _handleConfirmedResult(SavedUserActionResult result) async {
    final state = _boundController.registry.peekStateFor(widget.target);
    if ((result == SavedUserActionResult.applied ||
            result == SavedUserActionResult.noOp) &&
        state.shouldRenderSaved) {
      await _openCollectionPicker();
      return;
    }
    _handleActionResult(result);
  }

  Future<void> _openCollectionPicker() async {
    final controller = _boundController;
    final epoch = controller.lifecycleEpoch;
    await controller.ensureCapabilities();
    if (!mounted || controller.lifecycleEpoch != epoch) return;
    final result = await showSavedCollectionPicker(
      context: context,
      controller: controller,
      target: widget.target,
      sourceSurface: widget.sourceSurface,
      allowGlobalUnsave: true,
      previewTitle: widget.previewTitle,
      previewSubtitle: widget.previewSubtitle,
      previewImageUrl: widget.previewImageUrl,
    );
    if (!mounted || controller.lifecycleEpoch != epoch || result == null) {
      return;
    }
    _handleActionResult(result);
  }

  Future<void> _runGuarded(
    Future<void> Function() action, {
    bool showError = true,
  }) async {
    if (_actionInFlight) return;
    setState(() {
      _actionInFlight = true;
      _localError = null;
    });
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return;
      final targetUnavailable = isSavedTargetUnavailableError(error);
      if (targetUnavailable) {
        _targetUnavailable = true;
        try {
          await _boundController.bootstrapTargetStatuses(<SavedTarget>[
            widget.target,
          ], force: true);
        } on Object {
          // The mutation denial remains authoritative until this widget reloads.
        }
        if (!mounted) return;
      }
      final message = savedErrorMessage(AppLocalizations.of(context)!, error);
      setState(() => _localError = message);
      if (showError) {
        _showRetryMessage(
          message,
          allowRetry: !targetUnavailable && isSavedErrorRetryable(error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  void _handleActionResult(SavedUserActionResult result) {
    if (!mounted ||
        result == SavedUserActionResult.applied ||
        result == SavedUserActionResult.noOp ||
        result == SavedUserActionResult.superseded) {
      return;
    }
    final message = savedActionMessage(AppLocalizations.of(context)!, result);
    if (result == SavedUserActionResult.pending) {
      _showRetryMessage(message);
    } else {
      setState(() => _localError = message);
      _showRetryMessage(message);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _localError = message);
    _showRetryMessage(message);
  }

  void _showUnavailableMessage() {
    if (!mounted) return;
    _showRetryMessage(
      AppLocalizations.of(context)!.savedBookmarkUnavailableTooltip,
      allowRetry: false,
    );
  }

  void _showRetryMessage(String message, {bool allowRetry = true}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: allowRetry
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.retryButton,
                  onPressed: () {
                    if (mounted) unawaited(_handlePressed());
                  },
                )
              : null,
        ),
      );
  }
}

class _BookmarkIcon extends StatelessWidget {
  const _BookmarkIcon({
    required this.state,
    required this.isLoading,
    required this.color,
    required this.canSaveFromUnknown,
  });

  final SavedTargetState state;
  final bool isLoading;
  final Color color;
  final bool canSaveFromUnknown;

  @override
  Widget build(BuildContext context) {
    final showProgress =
        isLoading ||
        state.state == SavedRegistryState.pending ||
        state.state == SavedRegistryState.pendingUnknown;
    if (state.state == SavedRegistryState.unknown && showProgress) {
      return SizedBox.square(
        dimension: AppSizes.iconMd,
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      );
    }
    return SizedBox.square(
      dimension: AppSizes.iconLg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            state.shouldRenderSaved
                ? Icons.bookmark_rounded
                : canSaveFromUnknown
                ? Icons.bookmark_add_outlined
                : Icons.bookmark_border_rounded,
            size: AppSizes.iconMd,
            color: color,
          ),
          if (showProgress)
            SizedBox.square(
              dimension: AppSizes.iconLg,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
