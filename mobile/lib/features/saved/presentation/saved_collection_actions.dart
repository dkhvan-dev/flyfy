import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/app_design_system.dart';
import '../../../core/ui/app_modal_templates.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'saved_ui_messages.dart';
import 'state/saved_screen_controller.dart';

Future<void> createSavedCollectionFromUi({
  required BuildContext context,
  required SavedScreenController controller,
}) async {
  final lifecycleEpoch = controller.lifecycleEpoch;
  final l10n = AppLocalizations.of(context)!;
  final title = await showSavedCollectionTitleEditor(
    context: context,
    title: l10n.savedCollectionCreateTitle,
    initialValue: '',
    lifecycleEpoch: lifecycleEpoch,
  );
  if (title == null ||
      !context.mounted ||
      controller.lifecycleEpoch != lifecycleEpoch) {
    return;
  }

  try {
    final result = await controller.createCollection(title);
    if (!context.mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
    final message =
        result == SavedUserActionResult.applied ||
            result == SavedUserActionResult.noOp
        ? AppLocalizations.of(context)!.savedCollectionCreated
        : savedActionMessage(AppLocalizations.of(context)!, result);
    _showSavedMessage(context, message);
  } on Object catch (error) {
    if (!context.mounted || controller.lifecycleEpoch != lifecycleEpoch) return;
    _showSavedMessage(
      context,
      savedErrorMessage(AppLocalizations.of(context)!, error),
    );
  }
}

Future<String?> showSavedCollectionTitleEditor({
  required BuildContext context,
  required String title,
  required String initialValue,
  required int lifecycleEpoch,
}) {
  final expanded = MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;
  if (expanded) {
    return showAppModalDialog<String>(
      context: context,
      builder: (context) => _CollectionTitleEditor(
        title: title,
        initialValue: initialValue,
        lifecycleEpoch: lifecycleEpoch,
        presentation: _CollectionTitleEditorPresentation.dialog,
      ),
    );
  }
  return showAppModalBottomSheet<String>(
    context: context,
    builder: (context) => _CollectionTitleEditor(
      title: title,
      initialValue: initialValue,
      lifecycleEpoch: lifecycleEpoch,
      presentation: _CollectionTitleEditorPresentation.sheet,
    ),
  );
}

void _showSavedMessage(BuildContext context, String message) {
  if (message.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

enum _CollectionTitleEditorPresentation { dialog, sheet }

class _CollectionTitleEditor extends StatefulWidget {
  const _CollectionTitleEditor({
    required this.title,
    required this.initialValue,
    required this.lifecycleEpoch,
    required this.presentation,
  });

  final String title;
  final String initialValue;
  final int lifecycleEpoch;
  final _CollectionTitleEditorPresentation presentation;

  @override
  State<_CollectionTitleEditor> createState() => _CollectionTitleEditorState();
}

class _CollectionTitleEditorState extends State<_CollectionTitleEditor> {
  late final TextEditingController _controller;
  bool _closingForLifecycle = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final savedController = context.watch<SavedScreenController>();
    if (savedController.lifecycleEpoch != widget.lifecycleEpoch) {
      if (!_closingForLifecycle) {
        _closingForLifecycle = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
      return const SizedBox.shrink();
    }
    final colors = AppDesignSystem.colorsFor(context);
    final l10n = AppLocalizations.of(context)!;
    final normalizedTitle = _controller.text.trim();
    final valid =
        normalizedTitle.isNotEmpty && normalizedTitle.runes.length <= 80;
    final editor = TextField(
      key: const ValueKey('saved-collection-title-field'),
      controller: _controller,
      autofocus: true,
      maxLength: 80,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: valid
          ? (_) => Navigator.pop(context, _controller.text.trim())
          : null,
      decoration: AppInputDecorations.textField(
        label: l10n.savedCollectionTitleLabel,
        hint: l10n.savedCollectionTitleHint,
      ),
    );
    final actions = <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.cancelButton),
      ),
      FilledButton.icon(
        key: const ValueKey('saved-collection-title-submit'),
        onPressed: valid
            ? () => Navigator.pop(context, _controller.text.trim())
            : null,
        style: AppButtonStyles.primary(colors),
        icon: const Icon(Icons.check_rounded),
        label: Text(l10n.confirm),
      ),
    ];

    if (widget.presentation == _CollectionTitleEditorPresentation.dialog) {
      final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      return AnimatedPadding(
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        padding: AppEdgeInsets.only(bottom: keyboardInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: AppModalDialogCard(
            title: Text(widget.title),
            content: Padding(
              padding: const AppEdgeInsets.only(top: AppSpacing.xs),
              child: editor,
            ),
            actions: actions,
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppInsets.panel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            editor,
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
