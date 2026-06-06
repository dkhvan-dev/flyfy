import 'package:flutter/material.dart';

import '../../../core/ui/app_colors.dart';
import '../../../core/ui/filter_sheet_chrome.dart';
import '../../../features/activities/models/activity_review_vm.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<SaveActivityReviewsRequest?> showActivityReviewSheet(
  BuildContext context, {
  ActivityReviewVm? activityReview,
  ActivityOrganizerReviewVm? organizerReview,
  required bool allowOrganizerReview,
}) {
  return showModalBottomSheet<SaveActivityReviewsRequest>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ActivityReviewSheet(
      activityReview: activityReview,
      organizerReview: organizerReview,
      allowOrganizerReview: allowOrganizerReview,
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

  void _submit() {
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
        _errorText = AppLocalizations.of(
          context,
        )!.myExcursionsReviewSelectOneError;
      });
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return AppDismissibleModalSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF211609),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.activityReviewSheetTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
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
                      style: const TextStyle(
                        color: AppColors.destructive,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: const Color(0xFF201208),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              value: enabled,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              title: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onChanged: onEnabledChanged,
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
                          color: AppColors.accent,
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
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.myExcursionsReviewHint,
                      hintStyle: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.42),
                      ),
                      counterStyle: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.42),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
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
