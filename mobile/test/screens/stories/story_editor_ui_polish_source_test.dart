import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('story editor toolbar is content-height adaptive', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_editor_toolbar.dart',
    ).readAsStringSync();

    expect(source, contains('ConstrainedBox('));
    expect(source, contains('minHeight:'));
    expect(source, isNot(contains('height: 64')));
  });

  test('story editor template picker is not rendered as a disabled button', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();

    final popupStart = source.indexOf('class _StoryTemplatePickerField');
    final formatStart = source.indexOf('class _MetadataPopupField');
    expect(popupStart, isNonNegative);
    expect(formatStart, greaterThan(popupStart));

    final popupSource = source.substring(popupStart, formatStart);
    expect(popupSource, isNot(contains('onPressed: null')));
    expect(popupSource, isNot(contains('OutlinedButton.icon(')));
    expect(popupSource, contains('DecoratedBox('));
    expect(popupSource, contains('minWidth: fieldWidth'));
    expect(popupSource, contains('maxWidth: fieldWidth'));
    expect(popupSource, contains('_StoryTemplateMenuItem('));
    expect(popupSource, contains('Icons.check_circle_rounded'));
  });

  test('story editor metadata dropdowns use polished full-width menu items', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();

    final popupStart = source.indexOf('class _MetadataPopupField');
    final popupEnd = source.indexOf('class _StoryMetadataMenuItem');
    expect(popupStart, isNonNegative);
    expect(popupEnd, greaterThan(popupStart));
    final popupSource = source.substring(popupStart, popupEnd);

    expect(popupSource, contains('minWidth: fieldWidth'));
    expect(popupSource, contains('maxWidth: fieldWidth'));
    expect(popupSource, contains('_StoryMetadataMenuItem('));
    expect(popupSource, contains('Icons.check_circle_rounded'));
    expect(popupSource, contains('AppColors.accent.withValues(alpha: 0.14)'));
  });

  test('story editor exposes a broader reusable template set', () {
    final metadataSource = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();
    final screenSource = File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsStringSync();

    final enumStart = metadataSource.indexOf('enum StoryEditorTemplatePreset');
    final enumEnd = metadataSource.indexOf('class _MetadataPopupField');
    expect(enumStart, isNonNegative);
    expect(enumEnd, greaterThan(enumStart));
    final enumSource = metadataSource.substring(enumStart, enumEnd);

    expect(enumSource, contains('weekendGuide'));
    expect(enumSource, contains('photoEssay'));
    expect(enumSource, contains('foodNotes'));
    expect(enumSource, contains('cityWalk'));
    expect(enumSource, contains('hiddenGems'));
    expect(enumSource, contains('practicalTips'));
    expect(enumSource, contains('cultureRoute'));

    expect(screenSource, contains("id: 'city_walk'"));
    expect(screenSource, contains("id: 'hidden_gems'"));
    expect(screenSource, contains("id: 'practical_tips'"));
    expect(screenSource, contains("id: 'culture_route'"));
  });

  test('story editor place metadata uses user-facing place controls', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();

    expect(source, contains('AppCountryFilterSection('));
    expect(source, contains('AppCityFilterSection('));
    expect(source, isNot(contains('storyEditorCityPlaceIdLabel')));
  });

  test('story text blocks grow beyond a fixed eight-line editor', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_text_block.dart',
    ).readAsStringSync();

    expect(source, contains('maxLines: null'));
    expect(
      source,
      isNot(contains('maxLines: type == StoryBlockType.heading ? 2 : 8')),
    );
  });

  test('story media and place block headers match text block sizing', () {
    final media = File(
      'lib/features/stories/editor/presentation/widgets/story_media_block.dart',
    ).readAsStringSync();
    final canvas = File(
      'lib/features/stories/editor/presentation/widgets/story_block_canvas.dart',
    ).readAsStringSync();

    final mediaHeaderStart = media.indexOf('Row(\n                children: [');
    final mediaActionsStart = media.indexOf('IconButton(', mediaHeaderStart);
    expect(mediaHeaderStart, isNonNegative);
    expect(mediaActionsStart, greaterThan(mediaHeaderStart));
    final mediaHeaderSource = media.substring(
      mediaHeaderStart,
      mediaActionsStart,
    );

    final placeStart = canvas.indexOf('class _PlaceReferenceBlock');
    final placeEnd = canvas.indexOf('StoryEditorRevealOnFocus(', placeStart);
    expect(placeStart, isNonNegative);
    expect(placeEnd, greaterThan(placeStart));
    final placeHeaderSource = canvas.substring(placeStart, placeEnd);

    expect(mediaHeaderSource, contains('theme.textTheme.labelLarge'));
    expect(mediaHeaderSource, contains('size: 20'));
    expect(mediaHeaderSource, isNot(contains('titleMedium')));
    expect(placeHeaderSource, contains('textTheme.labelLarge'));
    expect(placeHeaderSource, contains('size: 20'));
    expect(placeHeaderSource, isNot(contains('titleMedium')));
  });

  test('story editor chrome follows app palette and keyboard insets', () {
    final screen = File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsStringSync();
    final toolbar = File(
      'lib/features/stories/editor/presentation/widgets/story_editor_toolbar.dart',
    ).readAsStringSync();
    final canvas = File(
      'lib/features/stories/editor/presentation/widgets/story_block_canvas.dart',
    ).readAsStringSync();
    final media = File(
      'lib/features/stories/editor/presentation/widgets/story_media_block.dart',
    ).readAsStringSync();
    final text = File(
      'lib/features/stories/editor/presentation/widgets/story_text_block.dart',
    ).readAsStringSync();

    expect(screen, contains('AnimatedPadding('));
    expect(screen, contains('MediaQuery.viewInsetsOf(context).bottom'));
    for (final source in [toolbar, canvas, media, text]) {
      expect(source, contains('AppColors.'));
      expect(source, isNot(contains('colorScheme.primary')));
    }
  });

  test('story block reordering starts from a delayed drag handle only', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_block_canvas.dart',
    ).readAsStringSync();

    expect(source, contains('ReorderableDelayedDragStartListener('));
    expect(source, isNot(contains('ReorderableDragStartListener(')));
    expect(source, contains('story-editor-block-drag-handle-'));
    expect(source, isNot(contains('Tooltip(')));
  });

  test('story block drag handle scales with story adaptive sizing', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_block_canvas.dart',
    ).readAsStringSync();

    final handleStart = source.indexOf('class _BlockDragHandle');
    expect(handleStart, isNonNegative);
    final handleSource = source.substring(handleStart);

    expect(handleSource, contains('StoryAdaptive.of(context)'));
    expect(handleSource, isNot(contains('width: 36')));
    expect(handleSource, isNot(contains('height: 48')));
    expect(handleSource, isNot(contains('width: 18')));
  });
}
