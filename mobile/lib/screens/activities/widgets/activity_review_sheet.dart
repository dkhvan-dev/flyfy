import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../features/activities/models/activity_review_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

Future<SaveActivityReviewsRequest?> showActivityReviewSheet(
  BuildContext context, {
  ActivityReviewVm? activityReview,
  ActivityOrganizerReviewVm? organizerReview,
  required bool allowOrganizerReview,
}) {
  final colors = AppDesignSystem.colorsFor(context);

  return showAppModalBottomSheet<SaveActivityReviewsRequest>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.transparent,
    builder: (context) => Theme(
      data: AppDesignSystem.themeFor(context),
      child: _ActivityReviewSheet(
        activityReview: activityReview,
        organizerReview: organizerReview,
        allowOrganizerReview: allowOrganizerReview,
      ),
    ),
  );
}

class _ActivityReviewSheet extends StatefulWidget {
  const _ActivityReviewSheet({
    required this.activityReview,
    required this.organizerReview,
    required this.allowOrganizerReview,
  });

  final ActivityReviewVm? activityReview;
  final ActivityOrganizerReviewVm? organizerReview;
  final bool allowOrganizerReview;

  @override
  State<_ActivityReviewSheet> createState() => _ActivityReviewSheetState();
}

class _ActivityReviewSheetState extends State<_ActivityReviewSheet> {
  late final TextEditingController _activityCommentController;
  late final TextEditingController _organizerCommentController;
  late bool _activityEnabled;
  late bool _organizerEnabled;
  late double _activityRating;
  late double _organizerRating;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _activityEnabled = true;
    _organizerEnabled = widget.allowOrganizerReview;
    _activityRating = (widget.activityReview?.rating ?? 5)
        .clamp(1, 5)
        .toDouble();
    _organizerRating = (widget.organizerReview?.rating ?? 5)
        .clamp(1, 5)
        .toDouble();
    _activityCommentController = TextEditingController(
      text: widget.activityReview?.comment ?? '',
    );
    _organizerCommentController = TextEditingController(
      text: widget.organizerReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _activityCommentController.dispose();
    _organizerCommentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final activityMutation = _activityEnabled
        ? ActivityReviewMutationRequest(
            rating: _activityRating,
            comment: _activityCommentController.text,
          )
        : widget.activityReview == null
        ? null
        : ActivityReviewMutationRequest(
            rating: widget.activityReview!.rating,
            comment: widget.activityReview!.comment,
            delete: true,
          );

    final organizerMutation = !widget.allowOrganizerReview
        ? null
        : _organizerEnabled
        ? ActivityReviewMutationRequest(
            rating: _organizerRating,
            comment: _organizerCommentController.text,
          )
        : widget.organizerReview == null
        ? null
        : ActivityReviewMutationRequest(
            rating: widget.organizerReview!.rating,
            comment: widget.organizerReview!.comment,
            delete: true,
          );

    if (activityMutation == null && organizerMutation == null) {
      setState(() {
        _errorText = l10n.myExcursionsReviewSelectOneError;
      });
      return;
    }

    final confirmed = await showAppModalDialog<bool>(
      context: context,
      barrierColor: colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        final dialogColors = AppDesignSystem.colorsFor(dialogContext);

        return Theme(
          data: AppDesignSystem.themeFor(dialogContext),
          child: Dialog(
            backgroundColor: dialogColors.transparent,
            insetPadding: const AppEdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: AppBoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dialogColors.surfaceRaised.withValues(alpha: 0.99),
                      dialogColors.background,
                    ],
                  ),
                  borderRadius: AppBorderRadius.circular(24),
                  border: Border.all(color: dialogColors.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: dialogColors.black.withValues(alpha: 0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const AppEdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activityReviewPublishConfirmTitle,
                        style: AppTextStyle(
                          color: dialogColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.activityReviewPublishConfirmDescription,
                        style: AppTextStyle(
                          color: dialogColors.textSecondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: dialogColors.primary,
                              ),
                              child: Text(l10n.cancelButton),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: AppButtonStyles.primary(dialogColors)
                                  .copyWith(
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: AppBorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                              child: Text(
                                l10n.activityReviewPublishConfirmButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }

    Navigator.of(context).pop(
      SaveActivityReviewsRequest(
        activityReview: activityMutation,
        organizerReview: organizerMutation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Theme(
      data: AppDesignSystem.themeFor(context),
      child: AppModalSheetFrame(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: _activityReviewSheetDecoration(colors),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: AppEdgeInsets.only(bottom: bottomInset),
                child: ListView(
                  shrinkWrap: true,
                  padding: const AppEdgeInsets.fromLTRB(20, 18, 20, 22),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: AppBoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.30),
                          borderRadius: AppBorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.activityReviewSheetTitle,
                      style: AppTextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActivityReviewEditor(
                      title: l10n.activityReviewActivityLabel,
                      enabled: _activityEnabled,
                      rating: _activityRating,
                      commentController: _activityCommentController,
                      onEnabledChanged: (value) =>
                          setState(() => _activityEnabled = value),
                      onRatingChanged: (value) =>
                          setState(() => _activityRating = value),
                    ),
                    if (widget.allowOrganizerReview) ...[
                      const SizedBox(height: 14),
                      _ActivityReviewEditor(
                        title: l10n.activityReviewOrganizerLabel,
                        enabled: _organizerEnabled,
                        rating: _organizerRating,
                        commentController: _organizerCommentController,
                        onEnabledChanged: (value) =>
                            setState(() => _organizerEnabled = value),
                        onRatingChanged: (value) =>
                            setState(() => _organizerRating = value),
                      ),
                    ],
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        style: AppTextStyle(
                          color: colors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _submit,
                      style: AppButtonStyles.primary(colors).copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(50),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: AppBorderRadius.circular(16),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review_rounded),
                      label: Text(l10n.myExcursionsReviewPublish),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityReviewEditor extends StatelessWidget {
  const _ActivityReviewEditor({
    required this.title,
    required this.enabled,
    required this.rating,
    required this.commentController,
    required this.onEnabledChanged,
    required this.onRatingChanged,
  });

  final String title;
  final bool enabled;
  final double rating;
  final TextEditingController commentController;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<double> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppDesignSystem.colorsFor(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const AppEdgeInsets.all(14),
        decoration: _activityReviewEditorDecoration(colors),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: colors.transparent,
              child: SwitchListTile.adaptive(
                value: enabled,
                contentPadding: AppEdgeInsets.zero,
                activeThumbColor: colors.primary,
                title: Text(
                  title,
                  style: AppTextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onChanged: onEnabledChanged,
              ),
            ),
            IgnorePointer(
              ignoring: !enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 2,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        tooltip: l10n.myExcursionsReviewRating,
                        onPressed: () => onRatingChanged(value.toDouble()),
                        icon: Icon(
                          value <= rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: colors.primary,
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 2000,
                    style: AppTextStyle(color: colors.textPrimary),
                    decoration: _activityReviewInputDecoration(l10n, colors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _activityReviewSheetDecoration(AppColors colors) {
  return AppBoxDecoration(
    color: colors.surface,
    borderRadius: const AppBorderRadius.vertical(
      top: AppRadiusValue.circular(24),
    ),
  );
}

BoxDecoration _activityReviewEditorDecoration(AppColors colors) {
  return AppBoxDecoration(
    color: colors.surfaceHigh.withValues(alpha: 0.72),
    borderRadius: AppBorderRadius.circular(16),
    border: Border.all(color: colors.border),
  );
}

InputDecoration _activityReviewInputDecoration(
  AppLocalizations l10n,
  AppColors colors,
) {
  final border = OutlineInputBorder(
    borderRadius: AppBorderRadius.circular(14),
    borderSide: BorderSide(color: colors.border),
  );

  return AppInputDecoration(
    hintText: l10n.myExcursionsReviewHint,
    hintStyle: AppTextStyle(
      color: colors.textSecondary.withValues(alpha: 0.72),
    ),
    counterStyle: AppTextStyle(
      color: colors.textSecondary.withValues(alpha: 0.72),
    ),
    filled: true,
    fillColor: colors.surfaceRaised,
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: AppBorderRadius.circular(14),
      borderSide: BorderSide(color: colors.primary),
    ),
  );
}
