import 'package:flutter/material.dart';

import '../../../../../core/ui/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../data/story_editor_dto.dart';
import '../story_editor_controller.dart';
import 'story_editor_style.dart';

class StoryPublishPanel extends StatelessWidget {
  const StoryPublishPanel({
    super.key,
    required this.state,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onOpenField,
  });

  final StoryEditorState state;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final ValueChanged<String> onOpenField;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errors = state.publishValidation.errors;
    final metadata = state.metadata;
    final checks = [
      _ChecklistItem(
        field: 'title',
        label: l10n.storyEditorChecklistTitle,
        complete: metadata.title.trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'format',
        label: l10n.storyEditorChecklistFormat,
        complete: metadata.format.trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'category',
        label: l10n.storyEditorChecklistCategory,
        complete: metadata.category.trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'coverFileId',
        label: l10n.storyEditorChecklistCover,
        complete: (metadata.coverFileId ?? '').trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'place',
        label: l10n.storyEditorChecklistPlace,
        complete:
            (metadata.placeName ?? '').trim().isNotEmpty ||
            (metadata.placeCityId ?? '').trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'country',
        label: l10n.storyEditorChecklistCountry,
        complete: (metadata.placeCountryCode ?? '').trim().isNotEmpty,
      ),
      _ChecklistItem(
        field: 'contentBlocks',
        label: l10n.storyEditorChecklistContent,
        complete: state.document.validateForPublish().issues.every(
          (issue) => issue.code != 'content_required',
        ),
      ),
      _ChecklistItem(
        field: 'mediaQueue',
        label: l10n.storyEditorChecklistMedia,
        complete:
            state.mediaQueue.items.isEmpty ||
            state.mediaQueue.items.every(
              (item) =>
                  item.status == StoryEditorMediaStatus.uploaded ||
                  item.status == StoryEditorMediaStatus.removed,
            ),
      ),
    ];
    final isSaving = state.saveStatus.phase == StoryEditorSavePhase.saving;
    final saveStatusMessage = _saveStatusMessage(l10n, state.saveStatus);

    return DecoratedBox(
      decoration: storyEditorPanelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(StoryEditorSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.storyEditorPublishReadiness,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (state.saveStatus.phase != StoryEditorSavePhase.idle)
                  Chip(
                    label: Text(_saveStatusLabel(l10n, state.saveStatus.phase)),
                  ),
              ],
            ),
            const SizedBox(height: StoryEditorSpacing.md),
            ...checks.map((item) {
              final fieldErrors = errors
                  .where(
                    (error) =>
                        error.field == item.field ||
                        (item.field == 'contentBlocks' &&
                            error.field == 'contentBlocks') ||
                        (item.field == 'mediaQueue' &&
                            error.field == 'mediaQueue'),
                  )
                  .toList(growable: false);
              final complete = item.complete && fieldErrors.isEmpty;
              return _PublishChecklistTile(
                item: item,
                complete: complete,
                status: complete
                    ? l10n.storyEditorChecklistReady
                    : fieldErrors.isEmpty
                    ? l10n.storyEditorChecklistNeedsAttention
                    : _fieldErrorMessage(l10n, fieldErrors.first),
                openLabel: l10n.storyEditorChecklistOpen,
                onOpen: () => onOpenField(item.field),
              );
            }),
            if (state.conflict.hasConflict) ...[
              const SizedBox(height: StoryEditorSpacing.md),
              Text(
                state.conflict.message ?? l10n.storyEditorConflictFallback,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.accent),
              ),
            ],
            if (saveStatusMessage != null) ...[
              const SizedBox(height: StoryEditorSpacing.md),
              _SaveStatusMessage(
                phase: state.saveStatus.phase,
                message: saveStatusMessage,
              ),
            ],
            const SizedBox(height: StoryEditorSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: isSaving ? null : onSaveDraft,
                  child: _ButtonLabelContent(
                    icon: Icons.save_outlined,
                    label: l10n.storyEditorSaveDraft,
                  ),
                ),
                const SizedBox(height: StoryEditorSpacing.sm),
                Semantics(
                  label: l10n.storyEditorPublishSemantic,
                  button: true,
                  child: FilledButton(
                    onPressed: isSaving ? null : onPublish,
                    child: _ButtonLabelContent(
                      icon: Icons.publish_rounded,
                      label: l10n.storyEditorPublish,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _saveStatusLabel(AppLocalizations l10n, StoryEditorSavePhase phase) {
    return switch (phase) {
      StoryEditorSavePhase.idle => l10n.storyEditorAutosaveIdle,
      StoryEditorSavePhase.saving => l10n.storyEditorAutosaveSaving,
      StoryEditorSavePhase.saved => l10n.storyEditorAutosaveSaved,
      StoryEditorSavePhase.failed => l10n.storyEditorAutosaveFailed,
      StoryEditorSavePhase.conflict => l10n.storyEditorAutosaveConflict,
    };
  }

  String? _saveStatusMessage(
    AppLocalizations l10n,
    StoryEditorSaveStatus status,
  ) {
    final message = status.message?.trim();
    return switch (status.phase) {
      StoryEditorSavePhase.idle => null,
      StoryEditorSavePhase.saving => l10n.storyEditorAutosaveSaving,
      StoryEditorSavePhase.saved => l10n.storyEditorAutosaveSaved,
      StoryEditorSavePhase.failed =>
        message?.isNotEmpty == true ? message : l10n.storyEditorAutosaveFailed,
      StoryEditorSavePhase.conflict =>
        message?.isNotEmpty == true
            ? message
            : l10n.storyEditorAutosaveConflict,
    };
  }

  String _fieldErrorMessage(
    AppLocalizations l10n,
    StoryEditorFieldError error,
  ) {
    return switch (error.code.trim()) {
      'draft_required' => l10n.storyEditorValidationDraftRequired,
      'title_required' => l10n.storyEditorValidationTitleRequired,
      'format_required' => l10n.storyEditorValidationFormatRequired,
      'category_required' => l10n.storyEditorValidationCategoryRequired,
      'cover_required' => l10n.storyEditorValidationCoverRequired,
      'place_required' => l10n.storyEditorValidationPlaceRequired,
      'country_required' => l10n.storyEditorValidationCountryRequired,
      'content_required' => l10n.storyEditorValidationContentRequired,
      'media_upload_pending' => l10n.storyEditorValidationMediaPending,
      _ => error.message,
    };
  }
}

class _SaveStatusMessage extends StatelessWidget {
  const _SaveStatusMessage({required this.phase, required this.message});

  final StoryEditorSavePhase phase;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      StoryEditorSavePhase.saved => AppColors.success,
      StoryEditorSavePhase.failed ||
      StoryEditorSavePhase.conflict => AppColors.accent,
      StoryEditorSavePhase.saving => AppColors.textSecondary,
      StoryEditorSavePhase.idle => AppColors.textSecondary,
    };
    final icon = switch (phase) {
      StoryEditorSavePhase.saved => Icons.check_circle_rounded,
      StoryEditorSavePhase.failed => Icons.error_outline_rounded,
      StoryEditorSavePhase.conflict => Icons.sync_problem_rounded,
      StoryEditorSavePhase.saving => Icons.sync_rounded,
      StoryEditorSavePhase.idle => Icons.info_outline_rounded,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(StoryEditorSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: StoryEditorSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.field,
    required this.label,
    required this.complete,
  });

  final String field;
  final String label;
  final bool complete;
}

class _PublishChecklistTile extends StatelessWidget {
  const _PublishChecklistTile({
    required this.item,
    required this.complete,
    required this.status,
    required this.openLabel,
    required this.onOpen,
  });

  final _ChecklistItem item;
  final bool complete;
  final String status;
  final String openLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackAction = constraints.maxWidth < 340 || textScale > 1.25;
        final icon = Icon(
          complete ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: complete ? AppColors.success : AppColors.accent,
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: StoryEditorSpacing.xs),
            Text(
              status,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
        final action = TextButton(
          key: ValueKey('publish-check-${item.field}-open'),
          onPressed: onOpen,
          child: Text(openLabel, overflow: TextOverflow.ellipsis),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: StoryEditorSpacing.xs),
          child: stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        const SizedBox(width: StoryEditorSpacing.md),
                        Expanded(child: copy),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: action,
                    ),
                  ],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: StoryEditorSpacing.md),
                    Expanded(child: copy),
                    const SizedBox(width: StoryEditorSpacing.sm),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _ButtonLabelContent extends StatelessWidget {
  const _ButtonLabelContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: StoryEditorSpacing.sm),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
