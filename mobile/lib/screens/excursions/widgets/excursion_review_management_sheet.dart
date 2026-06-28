import 'package:flutter/material.dart';
import 'package:inflap/core/ui/app_design_system.dart';

import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../features/excursions/models/create_excursion_review_request.dart';
import '../../../features/excursions/models/excursion_booking_vm.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';

enum ExcursionReviewAction { edit, delete }

class ExcursionReviewEditDraft {
  const ExcursionReviewEditDraft({required this.rating, required this.comment});

  final double rating;
  final String comment;

  ReviewDraftRequest toRequest() {
    return ReviewDraftRequest(rating: rating, comment: comment);
  }
}

Future<ExcursionReviewAction?> showExcursionReviewActionsSheet(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  return showAppModalBottomSheet<ExcursionReviewAction>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.transparent,
    builder: (context) {
      return AppModalSheetFrame(
        child: Container(
          width: double.infinity,
          padding: const AppEdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: const AppBoxDecoration(
            color: AppPalette.warmInk78,
            borderRadius: AppBorderRadius.vertical(
              top: AppRadiusValue.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: AppBoxDecoration(
                      color: AppPalette.white.withValues(alpha: 0.18),
                      borderRadius: AppBorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.excursionReviewActionsTitle,
                  style: const AppTextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _ReviewActionTile(
                  icon: Icons.edit_rounded,
                  label: l10n.excursionReviewEditAction,
                  onTap: () =>
                      Navigator.of(context).pop(ExcursionReviewAction.edit),
                ),
                _ReviewActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.excursionReviewDeleteAction,
                  destructive: true,
                  onTap: () =>
                      Navigator.of(context).pop(ExcursionReviewAction.delete),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<ExcursionReviewEditDraft?> showExcursionReviewEditSheet(
  BuildContext context, {
  required ExcursionReviewVm review,
}) {
  return showAppModalBottomSheet<ExcursionReviewEditDraft>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.transparent,
    builder: (context) => _ExcursionReviewEditSheet(review: review),
  );
}

class _ReviewActionTile extends StatelessWidget {
  const _ReviewActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppPalette.danger : AppPalette.primary;
    return Material(
      color: AppPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.circular(8),
        child: Padding(
          padding: const AppEdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcursionReviewEditSheet extends StatefulWidget {
  const _ExcursionReviewEditSheet({required this.review});

  final ExcursionReviewVm review;

  @override
  State<_ExcursionReviewEditSheet> createState() =>
      _ExcursionReviewEditSheetState();
}

class _ExcursionReviewEditSheetState extends State<_ExcursionReviewEditSheet> {
  late final TextEditingController _commentController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating.clamp(1, 5).toDouble();
    _commentController = TextEditingController(text: widget.review.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      ExcursionReviewEditDraft(
        rating: _rating,
        comment: _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppModalSheetFrame(
      child: Container(
        width: double.infinity,
        padding: AppEdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const AppBoxDecoration(
          color: AppPalette.warmInk78,
          borderRadius: AppBorderRadius.vertical(
            top: AppRadiusValue.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const AppEdgeInsets.fromLTRB(22, 22, 22, 24),
            children: [
              Text(
                l10n.excursionReviewEditTitle,
                style: const AppTextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 2,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: l10n.myExcursionsReviewRating,
                    onPressed: () => setState(() => _rating = value.toDouble()),
                    icon: Icon(
                      value <= _rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppPalette.primary,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 5,
                minLines: 3,
                maxLength: 600,
                cursorColor: AppPalette.primary,
                style: const AppTextStyle(color: AppPalette.textPrimary),
                decoration: AppInputDecoration(
                  hintText: l10n.myExcursionsReviewHint,
                  hintStyle: const AppTextStyle(
                    color: AppPalette.orangeMuted02,
                  ),
                  filled: true,
                  fillColor: AppPalette.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppFilterApplyButton(
                label: l10n.excursionReviewEditSave,
                icon: Icons.check_rounded,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
