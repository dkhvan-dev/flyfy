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

  test('story editor template picker opens a modal bottom sheet', () {
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
    expect(
      popupSource,
      contains('showAppModalBottomSheet<StoryEditorTemplatePreset>'),
    );
    expect(popupSource, contains('_StoryTemplateMenuItem('));
    expect(popupSource, contains('Icons.check_circle_rounded'));
    expect(
      popupSource,
      isNot(contains('PopupMenuButton<StoryEditorTemplatePreset>')),
    );
    expect(
      popupSource,
      isNot(contains('PopupMenuItem<StoryEditorTemplatePreset>')),
    );
  });

  test(
    'story editor template picker bottom sheet starts at phone bottom edge',
    () {
      final source = File(
        'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
      ).readAsStringSync();

      final popupStart = source.indexOf('class _StoryTemplatePickerField');
      final formatStart = source.indexOf('class _MetadataPopupField');
      expect(popupStart, isNonNegative);
      expect(formatStart, greaterThan(popupStart));

      final popupSource = source.substring(popupStart, formatStart);
      expect(popupSource, contains('useSafeArea: false'));
    },
  );

  test('story editor header uses compact adaptive V2 chrome', () {
    final source = File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsStringSync();

    final appBarStart = source.indexOf('class _StoryEditorAppBar');
    final layoutStart = source.indexOf('class _EditorFormLayout');
    expect(appBarStart, isNonNegative);
    expect(layoutStart, greaterThan(appBarStart));

    final appBarSource = source.substring(appBarStart, layoutStart);

    expect(
      appBarSource,
      contains('Size get preferredSize => const Size.fromHeight(48)'),
    );
    expect(appBarSource, contains('toolbarHeight: 48'));
    expect(appBarSource, contains('centerTitle: true'));
    expect(
      appBarSource,
      contains('backgroundColor: context.storyEditorColors.surface'),
    );
    expect(
      appBarSource,
      contains('foregroundColor: context.storyEditorColors.textPrimary'),
    );
    expect(appBarSource, contains('shape: Border('));
    expect(
      appBarSource,
      contains('BorderSide(color: context.storyEditorColors.border)'),
    );
    expect(appBarSource, isNot(contains('StoryPalette.backgroundTop')));
    expect(appBarSource, isNot(contains('StoryPalette.text')));
  });

  test('story editor metadata pickers open modal bottom sheets', () {
    final source = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();

    final popupStart = source.indexOf('class _MetadataPopupField');
    final popupEnd = source.indexOf('class _StoryMetadataMenuItem');
    expect(popupStart, isNonNegative);
    expect(popupEnd, greaterThan(popupStart));
    final popupSource = source.substring(popupStart, popupEnd);

    expect(popupSource, contains('showAppModalBottomSheet<String>'));
    expect(popupSource, contains('_StoryMetadataMenuItem('));
    expect(popupSource, contains('Icons.check_circle_rounded'));
    expect(popupSource, contains('AppDesignSystem.colorsFor(context)'));
    expect(popupSource, isNot(contains('PopupMenuButton<String>')));
    expect(popupSource, isNot(contains('PopupMenuItem<String>')));
    expect(popupSource, isNot(contains('AppPalette.')));
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

  test('story editor chrome preserves keyboard insets and V2 migrated blocks', () {
    final screen = File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsStringSync();
    final toolbar = File(
      'lib/features/stories/editor/presentation/widgets/story_editor_toolbar.dart',
    ).readAsStringSync();
    final canvas = File(
      'lib/features/stories/editor/presentation/widgets/story_block_canvas.dart',
    ).readAsStringSync();
    final style = File(
      'lib/features/stories/editor/presentation/widgets/story_editor_style.dart',
    ).readAsStringSync();
    final media = File(
      'lib/features/stories/editor/presentation/widgets/story_media_block.dart',
    ).readAsStringSync();
    final metadata = File(
      'lib/features/stories/editor/presentation/widgets/story_metadata_panel.dart',
    ).readAsStringSync();
    final publish = File(
      'lib/features/stories/editor/presentation/widgets/story_publish_panel.dart',
    ).readAsStringSync();
    final addSheet = File(
      'lib/features/stories/editor/presentation/widgets/story_add_block_sheet.dart',
    ).readAsStringSync();
    final text = File(
      'lib/features/stories/editor/presentation/widgets/story_text_block.dart',
    ).readAsStringSync();

    expect(screen, contains('AnimatedPadding('));
    expect(screen, contains('MediaQuery.viewInsetsOf(context).bottom'));
    expect(screen, contains('app_design_system.dart'));
    expect(screen, contains('AppDesignSystem.colorsFor(context)'));
    expect(screen, contains('storyEditorColors.primary'));
    expect(screen, contains('storyEditorColors.secondary'));
    expect(screen, contains('storyEditorColors.secondaryContainer'));
    expect(screen, contains('storyEditorColors.borderSecondary'));
    expect(screen, isNot(contains('AppPalette.')));
    for (final source in [
      style,
      toolbar,
      text,
      media,
      canvas,
      metadata,
      publish,
      addSheet,
    ]) {
      expect(source, contains('app_design_system.dart'));
      expect(source, contains('AppDesignSystem.colorsFor(context)'));
      if (identical(source, addSheet)) {
        expect(source, contains('colors.secondaryContainer'));
        expect(source, contains('colors.borderSecondary'));
        expect(source, contains('colors.secondary'));
      }
      expect(source, isNot(contains('AppPalette.')));
      expect(source, isNot(contains('colorScheme.primary')));
    }
  });

  test('quick post editor uses clean adaptive V2 light-theme chrome', () {
    final source = File(
      'lib/features/stories/editor/presentation/story_editor_screen.dart',
    ).readAsStringSync();

    final colorsStart = source.indexOf('final class _StoryEditorColors');
    final colorsEnd = source.indexOf('extension _StoryEditorColorContext');
    final selectorStart = source.indexOf('class _StoryEditorPostModeSelector');
    final composerStart = source.indexOf('class _QuickPostComposer');
    final mediaStart = source.indexOf('class _QuickPostMediaPanel');
    final thumbnailStart = source.indexOf('class _QuickPostMediaThumbnail');
    final appBarStart = source.indexOf('class _StoryEditorAppBar');

    expect(colorsStart, isNonNegative);
    expect(colorsEnd, greaterThan(colorsStart));
    expect(selectorStart, isNonNegative);
    expect(composerStart, greaterThan(selectorStart));
    expect(mediaStart, greaterThan(composerStart));
    expect(thumbnailStart, greaterThan(mediaStart));
    expect(appBarStart, greaterThan(thumbnailStart));

    final colorsSource = source.substring(colorsStart, colorsEnd);
    final selectorSource = source.substring(selectorStart, composerStart);
    final composerSource = source.substring(composerStart, mediaStart);
    final mediaSource = source.substring(mediaStart, thumbnailStart);
    final thumbnailSource = source.substring(thumbnailStart, appBarStart);

    expect(
      colorsSource,
      contains('Color get quickPostPanelSurface => colors.surfaceRaised'),
    );
    expect(
      colorsSource,
      contains('Color get quickPostPanelBorder => colors.border'),
    );
    expect(
      colorsSource,
      contains('Color get quickPostInputSurface => colors.surface'),
    );
    expect(
      colorsSource,
      contains(
        'Color get quickPostSelectedChipSurface => colors.primaryContainer',
      ),
    );
    expect(
      colorsSource,
      contains('Color get quickPostSelectedChipText => colors.textPrimary'),
    );
    expect(source, contains('List<BoxShadow>? _storyEditorDarkThemeShadow('));
    expect(
      source,
      contains('if (Theme.of(context).brightness == Brightness.light)'),
    );

    for (final sectionSource in [
      selectorSource,
      composerSource,
      mediaSource,
      thumbnailSource,
    ]) {
      expect(sectionSource, isNot(contains('StoryPalette.')));
    }

    expect(
      selectorSource,
      contains('context.storyEditorColors.quickPostPanelSurface'),
    );
    expect(
      selectorSource,
      contains('context.storyEditorColors.quickPostPanelBorder'),
    );
    expect(
      selectorSource,
      contains('context.storyEditorColors.quickPostSelectedChipSurface'),
    );
    expect(selectorSource, contains('quickPostSelectedChipText'));
    expect(selectorSource, isNot(contains('primary.withValues(alpha: 0.22)')));

    expect(
      composerSource,
      contains('context.storyEditorColors.quickPostPanelSurface'),
    );
    expect(
      composerSource,
      contains('context.storyEditorColors.quickPostPanelBorder'),
    );
    expect(composerSource, contains('boxShadow: _storyEditorDarkThemeShadow('));
    expect(
      composerSource,
      contains('context.storyEditorColors.quickPostInputSurface'),
    );
    expect(composerSource, isNot(contains('white.withValues(alpha: 0.08)')));
    expect(
      composerSource,
      isNot(contains('surfaceRaised.withValues(alpha: 0.72)')),
    );

    expect(
      mediaSource,
      contains('context.storyEditorColors.quickPostPanelSurface'),
    );
    expect(
      mediaSource,
      contains('context.storyEditorColors.quickPostPanelBorder'),
    );
    expect(mediaSource, isNot(contains('primary.withValues(alpha: 0.22)')));

    expect(
      thumbnailSource,
      contains('context.storyEditorColors.quickPostThumbnailSurface'),
    );
    expect(
      thumbnailSource,
      contains('context.storyEditorColors.quickPostPanelBorder'),
    );
    expect(thumbnailSource, isNot(contains('white.withValues(alpha: 0.08)')));
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
