import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:inflap/core/ui/app_modal_templates.dart';
import 'package:inflap/features/stories/editor/data/story_editor_api.dart';
import 'package:inflap/features/stories/editor/data/story_editor_dto.dart';
import 'package:inflap/features/stories/editor/data/story_editor_recovery_store.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';
import 'package:inflap/features/stories/editor/domain/story_editor_autosave_policy.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_controller.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_screen.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_trust_context.dart';
import 'package:inflap/features/stories/editor/presentation/widgets/story_add_block_sheet.dart';
import 'package:inflap/features/stories/editor/presentation/widgets/story_editor_toolbar.dart';
import 'package:inflap/features/stories/editor/presentation/widgets/story_metadata_panel.dart';
import 'package:inflap/features/stories/editor/presentation/widgets/story_media_block.dart';
import 'package:inflap/features/stories/editor/presentation/widgets/story_publish_panel.dart';
import 'package:inflap/features/stories/models/post_profile_contract.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/features/stories/story_ui.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/screens/stories/create_story_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StoryEditorScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('CreateStoryScreen delegates to the block editor', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const CreateStoryScreen()));

      expect(find.byType(StoryEditorScreen), findsOneWidget);
      expect(_storyBlockCanvasFinder(), findsOneWidget);
      expect(find.byType(StoryEditorToolbar), findsOneWidget);
    });

    testWidgets(
      'community composer shows trust banner and disables publish when posting is restricted',
      (tester) async {
        await tester.pumpWidget(
          _app(
            const CreateStoryScreen(
              communityId: 'community-1',
              communityTrustContext: StoryEditorTrustContext(
                kind: StoryEditorTrustBannerKind.blocked,
                title: 'Posting blocked',
                message: 'Moderators need to lift this restriction first.',
                blocksPublishing: true,
              ),
            ),
          ),
        );

        expect(find.text('Posting blocked'), findsOneWidget);
        expect(
          find.text('Moderators need to lift this restriction first.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Save draft'),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Publish'),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('create editor exposes a guarded back button', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/posts/create'),
                child: const Text('Open editor'),
              ),
            ),
          ),
          GoRoute(
            path: '/posts/create',
            builder: (context, state) => const CreateStoryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(_routerApp(router));
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('story-editor-back-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('story-editor-back-button')));
      await tester.pumpAndSettle();

      expect(find.text('Open editor'), findsOneWidget);
      expect(find.byType(StoryEditorScreen), findsNothing);
    });

    testWidgets('community post mode is selected inside the editor', (
      tester,
    ) async {
      final controller = _controller(api: _FakeStoryEditorApi());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          _screen(
            controller: controller,
            postProfileKey: PostProfileKeys.quickPost,
            availablePostProfileKeys: const [
              PostProfileKeys.quickPost,
              PostProfileKeys.listing,
              PostProfileKeys.eventAnnouncement,
              PostProfileKeys.article,
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('story-editor-post-mode-selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-editor-post-mode-quick_post_v1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-editor-post-mode-listing_v1')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-post-mode-event_announcement_v1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-editor-post-mode-article_v1')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('quick-post-composer')), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('story-editor-post-mode-listing_v1')),
      );
      await tester.pumpAndSettle();

      expect(controller.state.postProfileKey, PostProfileKeys.listing);
      expect(find.byType(StoryMetadataPanel), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-post-composer')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('story-editor-post-mode-article_v1')),
      );
      await tester.pumpAndSettle();

      expect(controller.state.postProfileKey, isNull);
      expect(find.byType(StoryMetadataPanel), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-post-composer')), findsNothing);
    });

    testWidgets(
      'quick post profile uses compact composer instead of block editor',
      (tester) async {
        final controller = StoryEditorController(api: _FakeStoryEditorApi());

        await tester.pumpWidget(
          _app(
            _screen(controller: controller, postProfileKey: 'quick_post_v1'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Quick post'), findsWidgets);
        expect(
          find.byKey(const ValueKey('quick-post-composer')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('quick-post-body-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('quick-post-media-panel')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('quick-post-add-photo')),
          findsOneWidget,
        );
        expect(_storyBlockCanvasFinder(), findsNothing);
        expect(find.byType(StoryMetadataPanel), findsNothing);
        expect(find.byType(StoryEditorToolbar), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('quick-post-body-field')),
          'Кто сегодня едет в Дананг?',
        );
        await tester.pump();

        expect(
          controller.state.document.plainText,
          'Кто сегодня едет в Дананг?',
        );
        expect(controller.state.postProfileKey, 'quick_post_v1');

        await tester.enterText(
          find.byKey(const ValueKey('quick-post-body-field')),
          'Кто сегодня едет в Дананг? ',
        );
        await tester.pump();

        final bodyField = tester.widget<TextField>(
          find.byKey(const ValueKey('quick-post-body-field')),
        );
        expect(bodyField.controller?.text, 'Кто сегодня едет в Дананг? ');

        await tester.ensureVisible(find.byType(StoryPublishPanel));
        expect(find.text('Title'), findsNothing);
        expect(find.text('Cover'), findsNothing);
        expect(find.text('Place'), findsNothing);
        expect(find.text('Country'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(StoryPublishPanel),
            matching: find.text('Content'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(StoryPublishPanel),
            matching: find.text('Media'),
          ),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 800));
      },
    );

    testWidgets(
      'quick post photos use the first image as cover and next images as content',
      (tester) async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final picker = _FakeStoryEditorImagePicker(
          image: StoryEditorPickedImage(
            bytes: base64Decode(_tinyPngBase64),
            fileName: 'quick-photo.png',
            mimeType: 'image/png',
          ),
        );
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeCreate(
          userId: 'user-1',
          postProfileKey: 'quick_post_v1',
        );

        await tester.pumpWidget(
          _app(
            _screen(
              controller: controller,
              postProfileKey: 'quick_post_v1',
              imagePicker: picker,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('quick-post-add-photo')));
        await tester.pump();

        expect(picker.requestedPurposes, [StoryEditorImagePickPurpose.cover]);
        expect(
          mediaUpload.requests.single.kind,
          StoryEditorMediaUploadKind.cover,
        );
        expect(
          controller.state.mediaQueue.items.single.kind,
          StoryEditorMediaUploadKind.cover,
        );

        await tester.tap(find.byKey(const ValueKey('quick-post-add-photo')));
        await tester.pump();

        expect(picker.requestedPurposes, [
          StoryEditorImagePickPurpose.cover,
          StoryEditorImagePickPurpose.inlineImage,
        ]);
        expect(
          mediaUpload.requests.last.kind,
          StoryEditorMediaUploadKind.inlineImage,
        );
        expect(
          controller.state.document.blocks
              .where((block) => block.image != null)
              .length,
          1,
        );
      },
    );

    testWidgets('renders responsive editor chrome on compact screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(_screen()));

      expect(find.text('Post editor'), findsOneWidget);
      expect(find.bySemanticsLabel('Add block'), findsWidgets);
      expect(find.bySemanticsLabel('Undo'), findsOneWidget);
      expect(find.bySemanticsLabel('Bold'), findsNothing);
      expect(find.bySemanticsLabel('Italic'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'compact create flow shows the writing canvas before metadata',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_app(_screen()));

        final canvasTop = tester.getTopLeft(find.text('Start with a block')).dy;
        final metadataTop = tester
            .getTopLeft(find.text('Publication setup'))
            .dy;

        expect(canvasTop, lessThan(metadataTop));
        expect(canvasTop, lessThan(360));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('large text scaling keeps publish actions reachable', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          _screen(),
          mediaQuery: const MediaQueryData(
            size: Size(390, 740),
            textScaler: TextScaler.linear(1.8),
          ),
        ),
      );

      await tester.ensureVisible(find.byType(StoryPublishPanel));

      expect(find.byType(StoryPublishPanel), findsOneWidget);
      expect(find.bySemanticsLabel('Publish story'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('metadata exposes all formats and template picker', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));

      await tester.ensureVisible(
        find.byKey(const ValueKey('story-editor-format-field')),
      );
      await tester.tap(find.byKey(const ValueKey('story-editor-format-field')));
      await tester.pumpAndSettle();

      expect(find.text('Guide'), findsWidgets);
      expect(find.text('Photo Essay'), findsWidgets);
      expect(find.text('Article'), findsWidgets);
      expect(find.text('Culinary'), findsWidgets);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('story-editor-template-picker')),
        findsOneWidget,
      );
    });

    testWidgets('editor material controls use the app accent color', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_screen()));

      final theme = Theme.of(tester.element(find.byType(StoryMetadataPanel)));

      expect(theme.colorScheme.primary, AppPalette.primary);
      expect(theme.colorScheme.secondary, AppPalette.primary);
      expect(theme.textSelectionTheme.cursorColor, AppPalette.primary);
    });

    testWidgets('preview mode renders a read-only published-style story', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.changeTitle('Weekend in Almaty');
      controller.changePlace(placeName: 'Almaty', placeCountryCode: 'KZ');
      controller.changeTags(['mountains', 'food']);
      controller.changeCover('cover-file-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'First public paragraph'),
      );

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('story-editor-preview-page')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-editor-preview-cover')),
        findsOneWidget,
      );
      expect(find.text('Weekend in Almaty'), findsWidgets);
      expect(find.text('First public paragraph'), findsOneWidget);
      expect(find.text('mountains'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);
      expect(find.byType(StoryMetadataPanel), findsNothing);
      expect(find.byType(StoryPublishPanel), findsNothing);
      expect(find.byType(StoryEditorToolbar), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('metadata tags can be added in batches with separators', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));

      final tagsField = find.byKey(const ValueKey('story-editor-tags-field'));
      await tester.ensureVisible(tagsField);
      await tester.enterText(tagsField, 'mountains, food weekend');
      await tester.pump();
      final addTagButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('story-editor-tags-add-button')),
      );
      expect(addTagButton.onPressed, isNotNull);
      addTagButton.onPressed?.call();
      await tester.pump();

      expect(controller.state.metadata.tags, ['mountains', 'food', 'weekend']);
      expect(find.text('mountains'), findsOneWidget);
      expect(find.text('food'), findsOneWidget);
      expect(find.text('weekend'), findsOneWidget);
    });

    testWidgets('metadata dropdown menus use the story picker palette', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_screen()));

      await _expectDropdownMenuUsesStoryPalette(
        tester,
        const ValueKey('story-editor-format-field'),
      );
      await _expectDropdownMenuUsesStoryPalette(
        tester,
        const ValueKey('story-editor-category-field'),
      );
    });

    testWidgets('metadata title focus hides stale content formatting toolbar', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'Hello world'),
      );

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );

      final paragraphField = find.widgetWithText(TextField, 'Hello world');
      await tester.ensureVisible(paragraphField);
      await tester.tap(paragraphField);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Hello world',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-editor-keyboard-formatting-toolbar')),
        findsOneWidget,
      );

      final titleField = find.byKey(const ValueKey('story-editor-title-field'));
      await tester.ensureVisible(titleField);
      await tester.tap(titleField);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-editor-keyboard-formatting-toolbar')),
        findsNothing,
      );
      expect(find.byType(StoryEditorToolbar), findsNothing);
    });

    testWidgets('template picker pre-fills practical starter content', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      final templatePicker = tester
          .widget<PopupMenuButton<StoryEditorTemplatePreset>>(
            find.byType(PopupMenuButton<StoryEditorTemplatePreset>),
          );
      templatePicker.onSelected?.call(StoryEditorTemplatePreset.weekendGuide);
      await tester.pump();

      expect(controller.state.metadata.format, 'GUIDE');
      expect(controller.state.document.blocks, isNotEmpty);
      expect(controller.state.isDirty, isTrue);
    });

    testWidgets(
      'template picker asks before changing structure with edited content',
      (tester) async {
        final controller = _controller();
        controller.initializeCreate(userId: 'user-1');

        await tester.pumpWidget(_app(_screen(controller: controller)));
        final templatePicker = tester
            .widget<PopupMenuButton<StoryEditorTemplatePreset>>(
              find.byType(PopupMenuButton<StoryEditorTemplatePreset>),
            );
        templatePicker.onSelected?.call(StoryEditorTemplatePreset.weekendGuide);
        await tester.pump();
        controller.updateBlock(
          'heading-template-1',
          (block) => block.copyWith(text: 'My weekend'),
        );
        await tester.pump();

        templatePicker.onSelected?.call(StoryEditorTemplatePreset.photoEssay);
        await tester.pumpAndSettle();

        expect(find.text('APPLY NEW STORY STRUCTURE?'), findsOneWidget);
        expect(find.text('Replace template'), findsOneWidget);
        await tester.tap(find.text('Replace template'));
        await tester.pumpAndSettle();

        expect(controller.state.document.blocks.map((block) => block.text), [
          'My weekend',
          'Photo story',
        ]);
        expect(
          find.text('Morning stop\nLocal food\nEvening view'),
          findsNothing,
        );
      },
    );

    testWidgets('loads edit story by id when no initial story is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryEditorScreen(
            storyId: 'story-42',
            userId: 'user-1',
            controller: _controller(
              api: _FakeStoryEditorApi(
                storyById: _storyVm(
                  id: 'story-42',
                  title: 'Loaded story',
                  contentBlocks: const [
                    {
                      'id': 'paragraph-1',
                      'type': 'paragraph',
                      'text': 'Loaded body',
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Loading story'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Loaded story'), findsWidgets);
      expect(find.text('Loaded body'), findsOneWidget);
    });

    testWidgets('publish checklist reflects missing required fields', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();
      final publishButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Publish'),
      );
      publishButton.onPressed?.call();
      await tester.pump();

      expect(find.text('Title'), findsWidgets);
      expect(find.text('Content type'), findsWidgets);
      expect(find.text('Topic'), findsWidgets);
      expect(find.text('Cover'), findsOneWidget);
      expect(find.text('Place'), findsWidgets);
      expect(
        find.byKey(const ValueKey('publish-check-country-open')),
        findsOneWidget,
      );
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Needs attention'), findsWidgets);
    });

    testWidgets('publish checklist open action scrolls to metadata field', (
      tester,
    ) async {
      final openedFields = <String>[];
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(
        _app(
          StoryEditorScreen(
            controller: controller,
            userId: 'user-1',
            onOpenField: openedFields.add,
          ),
        ),
      );
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final openTitleButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('publish-check-title-open')),
      );
      openTitleButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(openedFields, contains('title'));
      expect(
        find.byKey(const ValueKey('story-editor-title-field')),
        findsOneWidget,
      );
    });

    testWidgets(
      'community posts inherit location and hide manual place selectors',
      (tester) async {
        final controller = _controller();

        await tester.pumpWidget(
          _app(
            _screen(
              controller: controller,
              communityId: 'community-1',
              communityCountryCode: 'VN',
              communityCityId: 'da-nang',
              communityCityName: 'Da Nang',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.state.metadata.placeCountryCode, 'VN');
        expect(controller.state.metadata.placeCityId, 'da-nang');
        expect(controller.state.metadata.placeName, 'Da Nang');
        expect(
          find.byKey(const ValueKey('story-editor-place-field')),
          findsNothing,
        );
        expect(find.text('Country'), findsNothing);
        expect(find.text('City'), findsNothing);

        await tester.ensureVisible(find.byType(StoryPublishPanel));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('publish-check-place-open')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('publish-check-country-open')),
          findsNothing,
        );
      },
    );

    testWidgets('publish actions are stacked vertically', (tester) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final saveRect = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Save draft'),
      );
      final publishRect = tester.getRect(
        find.widgetWithText(FilledButton, 'Publish'),
      );

      expect(saveRect.bottom, lessThan(publishRect.top));
      expect(saveRect.left, moreOrLessEquals(publishRect.left));
      expect(saveRect.width, moreOrLessEquals(publishRect.width));
    });

    testWidgets('save draft highlights and scrolls to missing draft field', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api);
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Save draft'),
      );
      saveButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(api.createDraftRequests, isEmpty);
      final titleFieldFinder = find.byKey(
        const ValueKey('story-editor-title-field'),
      );
      final titleField = tester.widget<TextField>(titleFieldFinder);
      expect(
        titleField.decoration?.errorText,
        'Add a title or at least one story block to save a draft.',
      );
      expect(tester.getTopLeft(titleFieldFinder).dy, greaterThanOrEqualTo(0));
    });

    testWidgets('publish highlights the first missing publish-only field', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller
        ..changeTitle('Ready title')
        ..addBlock(
          StoryBlock.paragraph(id: 'paragraph-1', text: 'Ready content'),
        );

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final publishButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Publish'),
      );
      publishButton.onPressed?.call();
      await tester.pumpAndSettle();

      final coverFieldFinder = find.byKey(
        const ValueKey('story-editor-cover-field'),
      );
      final coverChrome = tester.widget<DecoratedBox>(coverFieldFinder);
      final decoration = coverChrome.decoration as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppPalette.danger);
      expect(tester.getTopLeft(coverFieldFinder).dy, greaterThanOrEqualTo(0));
    });

    testWidgets('published create flow returns the new post to caller', (
      tester,
    ) async {
      final api = _FakeStoryEditorApi();
      final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
      final controller = _controller(api: api, mediaLifecycle: mediaLifecycle);
      controller
        ..initializeCreate(userId: 'user-1')
        ..changeTitle('Published route title')
        ..changeCover('cover-1')
        ..changePlace(placeName: 'Almaty', placeCountryCode: 'KZ')
        ..addBlock(
          StoryBlock.paragraph(id: 'paragraph-1', text: 'Published body'),
        );
      late final GoRouter router;
      PostVm? returnedPost;
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedPost = await context.push<PostVm>('/posts/create');
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
          GoRoute(
            path: '/posts/create',
            builder: (context, state) => _screen(controller: controller),
          ),
        ],
      );

      await tester.pumpWidget(_routerApp(router));
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final publishButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Publish'),
      );
      publishButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(api.createDraftRequests, hasLength(1));
      expect(api.publishRequests, hasLength(1));
      expect(mediaLifecycle.binds, hasLength(2));
      expect(find.byType(StoryEditorScreen), findsNothing);
      expect(find.text('Open editor'), findsOneWidget);
      expect(returnedPost?.id, 'created-story');
    });

    testWidgets('saved create draft returns the new post to caller', (
      tester,
    ) async {
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api);
      controller
        ..initializeCreate(userId: 'user-1')
        ..changeTitle('Draft route title');
      late final GoRouter router;
      PostVm? returnedPost;
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedPost = await context.push<PostVm>('/posts/create');
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
          GoRoute(
            path: '/posts/create',
            builder: (context, state) => _screen(controller: controller),
          ),
        ],
      );

      await tester.pumpWidget(_routerApp(router));
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final saveDraftButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Save draft'),
      );
      saveDraftButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(api.createDraftRequests, hasLength(1));
      expect(find.byType(StoryEditorScreen), findsNothing);
      expect(find.text('Open editor'), findsOneWidget);
      expect(returnedPost?.id, 'created-story');
    });

    testWidgets(
      'save draft locks editor and keeps saving status until navigation-ready',
      (tester) async {
        final api = _FakeStoryEditorApi();
        final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway(
          holdBinds: true,
        );
        final controller = _controller(
          api: api,
          mediaLifecycle: mediaLifecycle,
        );
        controller
          ..initializeCreate(userId: 'user-1')
          ..changeTitle('Locked draft')
          ..changeCover('cover-file-1')
          ..addBlock(
            StoryBlock.paragraph(id: 'paragraph-1', text: 'Locked body'),
          );
        late final GoRouter router;
        PostVm? returnedPost;
        router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedPost = await context.push<PostVm>('/posts/create');
                  },
                  child: const Text('Open editor'),
                ),
              ),
            ),
            GoRoute(
              path: '/posts/create',
              builder: (context, state) => _screen(controller: controller),
            ),
          ],
        );

        await tester.pumpWidget(_routerApp(router));
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(StoryPublishPanel));
        await tester.pumpAndSettle();

        final saveDraftButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Save draft'),
        );
        saveDraftButton.onPressed?.call();
        await tester.pump();

        expect(mediaLifecycle.binds, hasLength(1));
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.saving);
        expect(
          find.byKey(const ValueKey('story-editor-submission-lock')),
          findsOneWidget,
        );
        expect(find.byType(StoryEditorToolbar), findsNothing);
        expect(find.text('Saved'), findsNothing);

        mediaLifecycle.completeNextBind();
        await tester.pumpAndSettle();

        expect(find.byType(StoryEditorScreen), findsNothing);
        expect(find.text('Open editor'), findsOneWidget);
        expect(returnedPost?.id, 'created-story');
      },
    );

    testWidgets(
      'publish locks editor and keeps saving status until navigation-ready',
      (tester) async {
        final api = _FakeStoryEditorApi();
        final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway(
          holdBinds: true,
        );
        final controller = _controller(
          api: api,
          mediaLifecycle: mediaLifecycle,
        );
        controller
          ..initializeEdit(userId: 'user-1', story: _storyVm())
          ..addBlock(
            StoryBlock.paragraph(id: 'paragraph-1', text: 'Published body'),
          );
        late final GoRouter router;
        router = GoRouter(
          initialLocation: '/posts/story-1/edit',
          routes: [
            GoRoute(
              path: '/posts/:postId/edit',
              builder: (context, state) => _screen(controller: controller),
            ),
            GoRoute(
              path: '/posts/:slug',
              builder: (context, state) => Scaffold(
                body: Text('Story details ${state.pathParameters['slug']}'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(_routerApp(router));
        await tester.ensureVisible(find.byType(StoryPublishPanel));
        await tester.pumpAndSettle();

        final publishButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Publish'),
        );
        publishButton.onPressed?.call();
        await tester.pump();

        expect(mediaLifecycle.binds, hasLength(1));
        expect(api.publishRequests, hasLength(1));
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.saving);
        expect(
          find.byKey(const ValueKey('story-editor-submission-lock')),
          findsOneWidget,
        );
        expect(find.byType(StoryEditorToolbar), findsNothing);
        expect(find.text('Saved'), findsNothing);

        mediaLifecycle.completeNextBind();
        await tester.pumpAndSettle();

        expect(find.byType(StoryEditorScreen), findsNothing);
        expect(find.text('Story details story-1'), findsOneWidget);
      },
    );

    testWidgets('save draft errors are visible in the publish panel', (
      tester,
    ) async {
      final controller = _controller(
        api: _FakeStoryEditorApi(
          createDraftError: StoryEditorApiException(
            message: 'Проверьте текст истории.',
            statusCode: 400,
          ),
        ),
      );
      controller.initializeCreate(userId: 'user-1');
      controller.changeTitle('Server rejected draft');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryPublishPanel));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Save draft'),
      );
      saveButton.onPressed?.call();
      await tester.pump();

      expect(find.text('Проверьте текст истории.'), findsOneWidget);
    });

    testWidgets(
      'cover picker queues upload instead of persisting fake file id',
      (tester) async {
        final api = _FakeStoryEditorApi();
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final picker = _FakeStoryEditorImagePicker(
          image: StoryEditorPickedImage(
            bytes: Uint8List.fromList(_tinyJpegBytes),
            fileName: 'cover.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        final controller = _controller(api: api, mediaUpload: mediaUpload);
        controller.initializeCreate(userId: 'user-1');
        controller.changeTitle('Draft with pending cover');

        await tester.pumpWidget(
          _app(_screen(controller: controller, imagePicker: picker)),
        );
        final addCoverButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Add cover'),
        );
        addCoverButton.onPressed?.call();
        await tester.pump();

        expect(picker.requestedPurposes, [StoryEditorImagePickPurpose.cover]);
        expect(mediaUpload.requests.single.bytes, _tinyJpegBytes);
        expect(mediaUpload.requests.single.fileName, 'cover.jpg');
        expect(mediaUpload.requests.single.mimeType, 'image/jpeg');
        expect(controller.state.metadata.coverFileId, isNull);
        expect(
          controller.state.mediaQueue.items.single.kind,
          StoryEditorMediaUploadKind.cover,
        );
        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.uploading,
        );
        expect(
          controller.state.mediaQueue.items.single.localMediaId,
          startsWith('cover-local-'),
        );

        await controller.saveDraft();

        expect(api.createDraftRequests.single.coverFileId, isNull);
        expect(
          api.createDraftRequests.single.toJson().toString(),
          isNot(contains('cover-local-')),
        );
      },
    );

    testWidgets('cover picker shows loader while upload is pending', (
      tester,
    ) async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final picker = _FakeStoryEditorImagePicker(
        image: StoryEditorPickedImage(
          bytes: Uint8List.fromList(_tinyJpegBytes),
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      final controller = _controller(mediaUpload: mediaUpload);
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(
        _app(_screen(controller: controller, imagePicker: picker)),
      );
      final addCoverButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add cover'),
      );
      addCoverButton.onPressed?.call();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-editor-cover-upload-loader')),
        findsOneWidget,
      );
      expect(find.text('Uploading'), findsOneWidget);

      mediaUpload.complete(
        controller.state.mediaQueue.items.single.localMediaId,
        fileId: 'cover-file-1',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-editor-cover-upload-loader')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('story-editor-cover-thumbnail')),
        findsOneWidget,
      );
      expect(find.text('Cover selected'), findsOneWidget);
    });

    testWidgets('uploaded cover is removed from the image overlay action', (
      tester,
    ) async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final picker = _FakeStoryEditorImagePicker(
        image: StoryEditorPickedImage(
          bytes: Uint8List.fromList(_tinyJpegBytes),
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      final controller = _controller(mediaUpload: mediaUpload);
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(
        _app(_screen(controller: controller, imagePicker: picker)),
      );
      final addCoverButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add cover'),
      );
      addCoverButton.onPressed?.call();
      await tester.pump();

      mediaUpload.complete(
        controller.state.mediaQueue.items.single.localMediaId,
        fileId: 'cover-file-1',
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('story-editor-cover-thumbnail')),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Clear'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const ValueKey('story-editor-cover-remove-overlay')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('story-editor-cover-remove-overlay')),
      );
      await tester.pump();

      expect(controller.state.metadata.coverFileId, isNull);
      expect(
        find.byKey(const ValueKey('story-editor-cover-thumbnail')),
        findsNothing,
      );
    });

    testWidgets('image toolbar uploads selected image bytes', (tester) async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final picker = _FakeStoryEditorImagePicker(
        image: StoryEditorPickedImage(
          bytes: Uint8List.fromList(_tinyPngBytes),
          fileName: 'inline.png',
          mimeType: 'image/png',
        ),
      );
      final controller = _controller(mediaUpload: mediaUpload);
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(
        _app(_screen(controller: controller, imagePicker: picker)),
      );
      await tester.ensureVisible(find.byType(StoryEditorToolbar));
      await tester.tap(find.bySemanticsLabel('Image'));
      await tester.pump();

      expect(picker.requestedPurposes, [
        StoryEditorImagePickPurpose.inlineImage,
      ]);
      expect(
        controller.state.document.blocks.single.type,
        StoryBlockType.image,
      );
      expect(mediaUpload.requests.single.bytes, _tinyPngBytes);
      expect(mediaUpload.requests.single.fileName, 'inline.png');
      expect(mediaUpload.requests.single.mimeType, 'image/png');
      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.uploading,
      );

      mediaUpload.complete(
        controller.state.mediaQueue.items.single.localMediaId,
        fileId: 'uploaded-inline-file',
      );
      await tester.pump();

      expect(
        controller.state.document.blocks.single.image?.fileId,
        'uploaded-inline-file',
      );
      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.uploaded,
      );
    });

    testWidgets('add block sheet inserts and deletes a quote block', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.ensureVisible(find.byType(StoryEditorToolbar));
      await tester.tap(find.bySemanticsLabel('Add block').last);
      await tester.pumpAndSettle();

      expect(find.byType(StoryAddBlockSheet), findsOneWidget);
      final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(bottomSheet.backgroundColor, Colors.transparent);
      final sheetChrome = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('story-add-block-sheet-chrome')),
      );
      final sheetDecoration = sheetChrome.decoration as BoxDecoration;
      final sheetGradient = sheetDecoration.gradient as LinearGradient;
      expect(sheetGradient.colors, [
        const Color(0xFF2B1808),
        const Color(0xFF201208),
      ]);

      final quoteOption = tester.widget<Ink>(
        find.byKey(const ValueKey('story-add-block-option-quote')),
      );
      final quoteDecoration = quoteOption.decoration as BoxDecoration;
      expect(quoteDecoration.color, const Color(0xFF2C2118));

      await tester.tap(find.text('Quote'));
      await tester.pumpAndSettle();

      expect(
        controller.state.document.blocks.single.type,
        StoryBlockType.quote,
      );
      expect(find.bySemanticsLabel('Delete quote block'), findsOneWidget);

      controller.deleteBlock(controller.state.document.blocks.single.id);
      await tester.pump();

      expect(controller.state.document.blocks, isEmpty);
      expect(find.text('Start with a block'), findsOneWidget);
    });

    testWidgets('gallery add flow creates removable queued media block', (
      tester,
    ) async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final picker = _FakeStoryEditorImagePicker(
        images: [
          StoryEditorPickedImage(
            bytes: Uint8List.fromList(_tinyJpegBytes),
            fileName: 'gallery-1.jpg',
            mimeType: 'image/jpeg',
          ),
          StoryEditorPickedImage(
            bytes: Uint8List.fromList(_tinyPngBytes),
            fileName: 'gallery-2.png',
            mimeType: 'image/png',
          ),
          StoryEditorPickedImage(
            bytes: Uint8List.fromList(_tinyJpegBytes),
            fileName: 'gallery-3.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
      );
      final controller = _controller(mediaUpload: mediaUpload);
      controller.initializeCreate(userId: 'user-1');

      await tester.pumpWidget(
        _app(_screen(controller: controller, imagePicker: picker)),
      );
      await tester.tap(find.bySemanticsLabel('Add block').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(picker.requestedPurposes, [StoryEditorImagePickPurpose.gallery]);
      expect(
        controller.state.document.blocks.single.type,
        StoryBlockType.gallery,
      );
      expect(
        controller.state.document.blocks.single.gallery?.images,
        hasLength(3),
      );
      expect(
        controller.state.mediaQueue.items.map((item) => item.blockId),
        everyElement('gallery-gallery-local-1'),
      );
      expect(mediaUpload.requests.map((request) => request.fileName), [
        'gallery-1.jpg',
        'gallery-2.png',
        'gallery-3.jpg',
      ]);
      expect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-3'),
        ),
        findsOneWidget,
      );
      final firstPreview = tester.getRect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-1'),
        ),
      );
      final secondPreview = tester.getRect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-2'),
        ),
      );
      final thirdPreview = tester.getRect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-3'),
        ),
      );
      expect(secondPreview.left, greaterThan(firstPreview.left));
      expect(thirdPreview.left, greaterThan(secondPreview.left));
      expect((secondPreview.top - firstPreview.top).abs(), lessThan(1));
      expect((thirdPreview.top - firstPreview.top).abs(), lessThan(1));
      expect(find.text('Gallery'), findsWidgets);
      expect(find.text('Uploading'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('story-editor-gallery-status-gallery-local-1-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-gallery-status-gallery-local-1-2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-gallery-status-gallery-local-1-3'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Caption'), findsNothing);
      expect(find.widgetWithText(TextField, 'Alt text'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('story-editor-gallery-remove-gallery-local-1-2'),
        ),
      );
      await tester.pump();

      expect(
        controller.state.document.blocks.single.gallery?.images,
        hasLength(2),
      );
      expect(
        controller.state.mediaQueue.items
            .where((item) => item.status != StoryEditorMediaStatus.removed)
            .map((item) => item.galleryImageIndex),
        [0, 1],
      );
      expect(
        controller.state.mediaQueue.items
            .where((item) => item.localMediaId == 'gallery-local-1-2')
            .single
            .status,
        StoryEditorMediaStatus.removed,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-2'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('story-editor-media-preview-gallery-local-1-3'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Delete gallery block'));
      await tester.pump();

      expect(controller.state.document.blocks, isEmpty);
      expect(
        controller.state.mediaQueue.items.map((item) => item.status),
        everyElement(StoryEditorMediaStatus.removed),
      );
    });

    testWidgets('media upload states can be retried and removed', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addImage(localMediaId: 'local-media-1', fileName: 'cover.jpg');

      await tester.pumpWidget(_app(_screen(controller: controller)));

      expect(find.byType(StoryMediaBlock), findsOneWidget);
      expect(find.text('Queued for upload'), findsNothing);
      expect(
        find.byKey(const ValueKey('story-editor-image-status-local-media-1')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Delete image block'));
      await tester.pump();

      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.removed,
      );
      expect(find.byType(StoryMediaBlock), findsNothing);
    });

    testWidgets('focused text block keeps formatting toolbar above keyboard', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(StoryBlock.paragraph(id: 'paragraph-1', text: ''));

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );
      final paragraphField = find.widgetWithText(TextField, 'Write your story');
      await tester.ensureVisible(paragraphField);
      await tester.tap(paragraphField);
      await tester.pump();

      final formattingToolbar = find.byKey(
        const ValueKey('story-editor-keyboard-formatting-toolbar'),
      );
      expect(formattingToolbar, findsOneWidget);
      expect(find.byType(StoryEditorToolbar), findsNothing);
      expect(tester.getSize(formattingToolbar).width, 393);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('Italic'), findsOneWidget);
      expect(find.text('Strikethrough'), findsOneWidget);
      expect(find.text('Underline'), findsOneWidget);
      expect(find.bySemanticsLabel('Add block'), findsNothing);
      expect(find.bySemanticsLabel('Heading'), findsNothing);
      expect(find.bySemanticsLabel('List'), findsNothing);
      expect(find.bySemanticsLabel('Quote'), findsNothing);
      expect(
        tester.getBottomLeft(formattingToolbar).dy,
        lessThanOrEqualTo(852 - 320),
      );
    });

    testWidgets('focused lower text field scrolls above keyboard overlay', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      for (var index = 0; index < 8; index++) {
        controller.addBlock(
          StoryBlock.paragraph(
            id: 'paragraph-$index',
            text: index == 7 ? 'Bottom field text' : 'Filler block $index',
          ),
        );
      }

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );

      final bottomField = find.widgetWithText(TextField, 'Bottom field text');
      await tester.ensureVisible(bottomField);
      await tester.pumpAndSettle();
      final editorScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView && widget.controller != null,
        description: 'editor scroll view',
      );
      await tester.drag(editorScrollView, const Offset(0, 360));
      await tester.pumpAndSettle();

      await tester.tap(bottomField, warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();

      final formattingToolbar = find.byKey(
        const ValueKey('story-editor-keyboard-formatting-toolbar'),
      );
      final visibleTop = tester.getTopLeft(editorScrollView).dy;
      final visibleBottom = tester.getTopLeft(formattingToolbar).dy;
      final visibleCenter = (visibleTop + visibleBottom) / 2;
      final fieldCenter = tester.getCenter(bottomField).dy;

      expect((fieldCenter - visibleCenter).abs(), lessThanOrEqualTo(32));
    });

    testWidgets(
      'focused text block moves formatting toolbar immediately above keyboard',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = _controller();
        controller.initializeCreate(userId: 'user-1');
        controller.addBlock(
          StoryBlock.paragraph(id: 'paragraph-1', text: 'Hello world'),
        );

        await tester.pumpWidget(
          _app(
            _screen(controller: controller),
            mediaQuery: const MediaQueryData(size: Size(393, 852)),
          ),
        );
        final paragraphField = find.widgetWithText(TextField, 'Hello world');
        await tester.ensureVisible(paragraphField);
        await tester.tap(paragraphField);
        await tester.pump();

        expect(find.byType(StoryEditorToolbar), findsOneWidget);

        await tester.pumpWidget(
          _app(
            _screen(controller: controller),
            mediaQuery: const MediaQueryData(
              size: Size(393, 852),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
          ),
        );
        await tester.pump();

        final formattingToolbar = find.byKey(
          const ValueKey('story-editor-keyboard-formatting-toolbar'),
        );
        expect(formattingToolbar, findsOneWidget);
        expect(
          tester.getBottomLeft(formattingToolbar).dy,
          lessThanOrEqualTo(852 - 320),
        );
      },
    );

    testWidgets('bold toolbar applies formatting to selected text range', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'Hello world'),
      );

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );
      final paragraphField = find.widgetWithText(TextField, 'Hello world');
      await tester.ensureVisible(paragraphField);
      await tester.tap(paragraphField);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Hello world',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Bold'));
      await tester.pump();

      final marks = controller.state.document.blocks.single.marks;
      expect(marks, hasLength(1));
      expect(marks.single.type, StoryInlineMarkType.bold);
      expect(marks.single.start, 0);
      expect(marks.single.end, 5);

      final editableFinder = find.descendant(
        of: paragraphField,
        matching: find.byType(EditableText),
      );
      final editable = tester.widget<EditableText>(editableFinder);
      final span = editable.controller.buildTextSpan(
        context: tester.element(editableFinder),
        style: const TextStyle(),
        withComposing: false,
      );
      final children = span.children!.cast<TextSpan>().toList(growable: false);
      expect(children.first.text, 'Hello');
      expect(children.first.style?.fontWeight, FontWeight.w800);
      expect(children.last.text, ' world');
    });

    testWidgets('inline style toolbar ignores collapsed text selection', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'Hello world'),
      );

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );
      final paragraphField = find.widgetWithText(TextField, 'Hello world');
      await tester.ensureVisible(paragraphField);
      await tester.tap(paragraphField);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Bold'));
      await tester.pump();

      expect(controller.state.document.blocks.single.marks, isEmpty);
    });

    testWidgets('inline toolbar supports underline and strikethrough marks', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'Hello world'),
      );

      await tester.pumpWidget(
        _app(
          _screen(controller: controller),
          mediaQuery: const MediaQueryData(
            size: Size(393, 852),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
        ),
      );
      final paragraphField = find.widgetWithText(TextField, 'Hello world');
      await tester.ensureVisible(paragraphField);
      await tester.tap(paragraphField);
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Hello world',
          selection: TextSelection(baseOffset: 6, extentOffset: 11),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Underline'));
      await tester.pump();
      await tester.tap(find.text('Strikethrough'));
      await tester.pump();

      final marks = controller.state.document.blocks.single.marks;
      expect(marks.map((mark) => mark.type), [
        StoryInlineMarkType.underline,
        StoryInlineMarkType.strikethrough,
      ]);
      expect(marks.every((mark) => mark.start == 6 && mark.end == 11), isTrue);
    });

    testWidgets('blocks expose left drag handles for reordering', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(StoryBlock.paragraph(id: 'paragraph-1', text: 'One'));
      controller.addBlock(StoryBlock.quote(id: 'quote-1', text: 'Two'));

      await tester.pumpWidget(_app(_screen(controller: controller)));

      expect(
        find.byKey(
          const ValueKey('story-editor-block-drag-handle-paragraph-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-editor-block-drag-handle-quote-1')),
        findsOneWidget,
      );

      final dragHandle = find.byKey(
        const ValueKey('story-editor-block-drag-handle-paragraph-1'),
      );
      final gesture = await tester.startGesture(tester.getCenter(dragHandle));
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveBy(const Offset(0, 420));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.state.document.blocks.map((block) => block.id), [
        'quote-1',
        'paragraph-1',
      ]);
    });

    testWidgets('block drag start emits one haptic feedback pulse', (
      tester,
    ) async {
      final hapticCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(StoryBlock.paragraph(id: 'paragraph-1', text: 'One'));
      controller.addBlock(StoryBlock.quote(id: 'quote-1', text: 'Two'));

      await tester.pumpWidget(_app(_screen(controller: controller)));

      final dragHandle = find.byKey(
        const ValueKey('story-editor-block-drag-handle-paragraph-1'),
      );
      final gesture = await tester.startGesture(tester.getCenter(dragHandle));
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveBy(const Offset(0, 180));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        hapticCalls
            .where(
              (call) => call.arguments == 'HapticFeedbackType.selectionClick',
            )
            .length,
        1,
      );
    });

    testWidgets('dragging a block near viewport edge auto-scrolls the editor', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      for (var index = 0; index < 14; index++) {
        controller.addBlock(
          StoryBlock.paragraph(
            id: 'paragraph-$index',
            text: 'Paragraph $index\nMore text to give the block height.',
          ),
        );
      }

      await tester.pumpWidget(_app(_screen(controller: controller)));
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      final scrollController = scrollView.controller!;
      expect(scrollController.offset, 0);

      final dragHandle = find.byKey(
        const ValueKey('story-editor-block-drag-handle-paragraph-0'),
      );
      final start = tester.getCenter(dragHandle);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveTo(Offset(start.dx, 680));
      await tester.pump(const Duration(milliseconds: 520));

      expect(scrollController.offset, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('retry media button is shown only when upload failed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: StoryMediaBlock(
                block: StoryBlock.image(
                  id: 'image-local-media-1',
                  image: const StoryImagePayload(
                    fileId: '',
                    uploadState: StoryUploadState.uploading,
                  ),
                ),
                queueItem: const StoryEditorMediaQueueItem(
                  localMediaId: 'local-media-1',
                  blockId: 'image-local-media-1',
                  status: StoryEditorMediaStatus.uploading,
                ),
                selected: false,
                onFocus: () {},
                onRetry: () {},
                onRemove: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsNothing);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: StoryMediaBlock(
                block: StoryBlock.image(
                  id: 'image-local-media-1',
                  image: const StoryImagePayload(
                    fileId: '',
                    uploadState: StoryUploadState.failed,
                  ),
                ),
                queueItem: const StoryEditorMediaQueueItem(
                  localMediaId: 'local-media-1',
                  blockId: 'image-local-media-1',
                  status: StoryEditorMediaStatus.failed,
                ),
                selected: false,
                onFocus: () {},
                onRetry: () {},
                onRemove: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      final failedRetry = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Retry'),
      );
      expect(failedRetry.onPressed, isNotNull);
    });

    testWidgets('completed image media shows status on preview only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: StoryMediaBlock(
                block: StoryBlock.image(
                  id: 'image-local-media-1',
                  image: const StoryImagePayload(
                    fileId: 'uploaded-inline-file',
                    uploadState: StoryUploadState.complete,
                  ),
                ),
                queueItem: const StoryEditorMediaQueueItem(
                  localMediaId: 'local-media-1',
                  blockId: 'image-local-media-1',
                  status: StoryEditorMediaStatus.uploaded,
                  fileId: 'uploaded-inline-file',
                ),
                selected: false,
                onFocus: () {},
                onRetry: () {},
                onRemove: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Upload complete'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsNothing);
      expect(
        find.byKey(const ValueKey('story-editor-image-status-local-media-1')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('image media block hides caption and alt text fields', (
      tester,
    ) async {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addImage(localMediaId: 'local-media-1', fileName: 'cover.jpg');

      await tester.pumpWidget(_app(_screen(controller: controller)));

      expect(find.byType(StoryMediaBlock), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Caption'), findsNothing);
      expect(find.widgetWithText(TextField, 'Alt text'), findsNothing);
    });

    testWidgets('media image and gallery blocks hide text remove buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  StoryMediaBlock(
                    block: StoryBlock.image(
                      id: 'image-local-media-1',
                      image: const StoryImagePayload(
                        fileId: '',
                        uploadState: StoryUploadState.uploading,
                      ),
                    ),
                    queueItem: const StoryEditorMediaQueueItem(
                      localMediaId: 'local-media-1',
                      blockId: 'image-local-media-1',
                      status: StoryEditorMediaStatus.uploading,
                    ),
                    selected: false,
                    onFocus: () {},
                    onRetry: () {},
                    onRemove: () {},
                    onDelete: () {},
                  ),
                  StoryMediaBlock(
                    block: StoryBlock.gallery(
                      id: 'gallery-local-media-1',
                      gallery: StoryGalleryPayload(
                        images: const [
                          StoryImagePayload(
                            fileId: '',
                            uploadState: StoryUploadState.uploading,
                          ),
                        ],
                      ),
                    ),
                    queueItems: const [
                      StoryEditorMediaQueueItem(
                        localMediaId: 'gallery-local-1',
                        blockId: 'gallery-local-media-1',
                        status: StoryEditorMediaStatus.uploading,
                        galleryImageIndex: 0,
                      ),
                    ],
                    selected: false,
                    onFocus: () {},
                    onRetry: () {},
                    onRemove: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(StoryMediaBlock), findsNWidgets(2));
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Remove'), findsNothing);
    });

    testWidgets('failed media localizes known queue error messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: StoryMediaBlock(
                block: StoryBlock.image(
                  id: 'image-local-media-1',
                  image: const StoryImagePayload(
                    fileId: '',
                    uploadState: StoryUploadState.failed,
                  ),
                ),
                queueItem: const StoryEditorMediaQueueItem(
                  localMediaId: 'local-media-1',
                  blockId: 'image-local-media-1',
                  status: StoryEditorMediaStatus.failed,
                  errorCode: StoryEditorMediaErrorCode.retryUpload,
                ),
                selected: false,
                onFocus: () {},
                onRetry: () {},
                onRemove: () {},
                onDelete: () {},
              ),
            ),
          ),
          locale: const Locale('ru'),
        ),
      );

      expect(find.text('Повторите загрузку медиа.'), findsOneWidget);
      expect(find.text('Retry upload.'), findsNothing);
    });

    testWidgets('freshly loaded story does not show unsaved guard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          StoryEditorScreen(
            userId: 'user-1',
            initialStory: _storyVm(title: 'Loaded clean story'),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard post changes?'), findsNothing);
    });

    testWidgets('dirty unsaved guard offers save draft action', (tester) async {
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api);
      controller.initializeEdit(userId: 'user-1', story: _storyVm());
      controller.changeTitle('Unsaved title');

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard post changes?'), findsOneWidget);
      final dialogSaveDraft = find.descendant(
        of: find.byType(AppModalDialogCard),
        matching: find.text('Save draft'),
      );
      expect(dialogSaveDraft, findsOneWidget);

      await tester.tap(dialogSaveDraft);
      await tester.pumpAndSettle();

      expect(api.updateRequests, hasLength(1));
      expect(controller.state.isDirty, isFalse);
    });

    testWidgets('recovery prompt can restore a local snapshot', (tester) async {
      final recovery = _FakeStoryEditorRecovery(
        snapshot: StoryEditorRecoverySnapshot(
          userId: 'user-1',
          localDraftId: 'local-draft-1',
          metadata: StoryEditorMetadataDraft(
            title: 'Recovered draft',
            format: 'STORY',
            category: 'JOURNAL',
            status: 'DRAFT',
          ),
          document: StoryDocument(
            blocks: [
              StoryBlock.paragraph(id: 'paragraph-1', text: 'Recovered body'),
            ],
          ),
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 12),
        ),
      );
      final controller = _controller(recovery: recovery);

      await tester.pumpWidget(_app(_screen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Recover unsaved draft?'), findsOneWidget);

      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered draft'), findsWidgets);
      expect(find.text('Recovered body'), findsOneWidget);
    });
  });
}

Widget _app(Widget child, {MediaQueryData? mediaQuery, Locale? locale}) {
  final wrapped = MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  if (mediaQuery == null) {
    return wrapped;
  }
  return MediaQuery(data: mediaQuery, child: wrapped);
}

Widget _routerApp(GoRouter router) {
  return MaterialApp.router(
    theme: ThemeData.dark(useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

Widget _screen({
  StoryEditorController? controller,
  StoryEditorImagePickerGateway? imagePicker,
  String? postProfileKey,
  List<String>? availablePostProfileKeys,
  String? communityId,
  String? communityCountryCode,
  String? communityCityId,
  String? communityCityName,
}) {
  return StoryEditorScreen(
    controller: controller,
    userId: 'user-1',
    communityId: communityId,
    postProfileKey: postProfileKey,
    availablePostProfileKeys: availablePostProfileKeys,
    communityCountryCode: communityCountryCode,
    communityCityId: communityCityId,
    communityCityName: communityCityName,
    imagePicker: imagePicker ?? _FakeStoryEditorImagePicker(),
  );
}

Finder _storyBlockCanvasFinder() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == 'StoryBlockCanvas',
    description: 'StoryBlockCanvas',
  );
}

Future<void> _expectDropdownMenuUsesStoryPalette(
  WidgetTester tester,
  ValueKey<String> fieldKey,
) async {
  final field = find.byKey(fieldKey);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  final popupFinder = find.descendant(
    of: field,
    matching: find.byType(PopupMenuButton<String>),
  );
  final popup = tester.widget<PopupMenuButton<String>>(popupFinder);
  final fieldWidth = tester.getSize(field).width;

  expect(popup.color, StoryPalette.surfaceRaised);
  expect(popup.surfaceTintColor, Colors.transparent);
  expect(popup.position, PopupMenuPosition.under);
  expect(popup.padding, EdgeInsets.zero);
  expect(popup.constraints?.minWidth, fieldWidth);
  expect(popup.constraints?.maxWidth, fieldWidth);

  await tester.tap(popupFinder);
  await tester.pumpAndSettle();

  final fieldRect = tester.getRect(field);
  final firstMenuItem = find.byType(PopupMenuItem<String>).first;
  final firstMenuItemRect = tester.getRect(firstMenuItem);
  expect(firstMenuItemRect.width, moreOrLessEquals(fieldRect.width));
  expect(firstMenuItemRect.left, moreOrLessEquals(fieldRect.left));
  expect(firstMenuItemRect.right, moreOrLessEquals(fieldRect.right));
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Material && widget.color == StoryPalette.surfaceRaised,
      description: 'story-palette popup menu material',
    ),
    findsWidgets,
  );

  await tester.tapAt(Offset.zero);
  await tester.pumpAndSettle();
}

StoryEditorController _controller({
  StoryEditorApiGateway? api,
  StoryEditorRecoveryGateway? recovery,
  StoryEditorAutosaveScheduler? autosave,
  StoryEditorMediaUploadGateway? mediaUpload,
  StoryEditorMediaLifecycleGateway? mediaLifecycle,
}) {
  return StoryEditorController(
    api: api ?? _FakeStoryEditorApi(),
    recovery: recovery ?? _FakeStoryEditorRecovery(),
    autosave: autosave ?? _FakeAutosaveScheduler(),
    mediaUpload: mediaUpload ?? _FakeStoryEditorMediaUploadGateway(),
    mediaLifecycle: mediaLifecycle ?? _FakeStoryEditorMediaLifecycleGateway(),
    localDraftIdFactory: () => 'local-draft-1',
    now: () => DateTime.utc(2026, 6, 8, 12),
  );
}

PostVm _storyVm({
  String id = 'story-1',
  String title = 'Remote title',
  String format = 'STORY',
  String category = 'JOURNAL',
  String status = 'DRAFT',
  String? coverFileId = 'cover-1',
  String? placeName = 'Almaty',
  String? placeCountryCode = 'KZ',
  String? placeCityId = 'almaty',
  List<String> tags = const ['mountains'],
  int revision = 1,
  List<Map<String, dynamic>> contentBlocks = const [],
}) {
  return PostVm(
    id: id,
    slug: id,
    title: title,
    excerpt: '',
    content: '',
    format: format,
    contentBlocks: contentBlocks,
    revision: revision,
    category: category,
    status: status,
    coverFileId: coverFileId,
    placeName: placeName,
    placeCountryCode: placeCountryCode,
    placeCityId: placeCityId,
    tags: tags,
    stats: PostStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: '',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 8),
  );
}

class _FakeStoryEditorApi implements StoryEditorApiGateway {
  _FakeStoryEditorApi({PostVm? storyById, this.createDraftError})
    : storyById = storyById ?? _storyVm();

  final PostVm storyById;
  final Object? createDraftError;
  final createDraftRequests = <StoryEditorWriteRequest>[];
  final autosaveRequests = <StoryEditorWriteRequest>[];
  final updateRequests = <StoryEditorWriteRequest>[];
  final publishRequests = <StoryEditorWriteRequest>[];

  @override
  Future<PostVm> getStory(String storyId) async {
    return storyById;
  }

  @override
  Future<PostVm> archive(String storyId, {int? revision}) async {
    return _storyVm(id: storyId, revision: (revision ?? 0) + 1);
  }

  @override
  Future<PostVm> autosave(
    String storyId,
    StoryEditorWriteRequest request,
  ) async {
    autosaveRequests.add(request);
    return _storyVm(id: storyId, title: request.title);
  }

  @override
  Future<PostVm> createDraft(StoryEditorWriteRequest request) async {
    final error = createDraftError;
    if (error != null) {
      throw error;
    }
    createDraftRequests.add(request);
    return _storyVm(id: 'created-story', title: request.title);
  }

  @override
  Future<PostVm> publish(
    String storyId,
    StoryEditorWriteRequest request,
  ) async {
    publishRequests.add(request);
    return _storyVm(id: storyId, title: request.title, status: 'PUBLISHED');
  }

  @override
  Future<PostVm> update(String storyId, StoryEditorWriteRequest request) async {
    updateRequests.add(request);
    return _storyVm(id: storyId, title: request.title);
  }
}

class _FakeStoryEditorRecovery implements StoryEditorRecoveryGateway {
  _FakeStoryEditorRecovery({this.snapshot});

  StoryEditorRecoverySnapshot? snapshot;

  @override
  Future<bool> clear({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) async {
    snapshot = null;
    return true;
  }

  @override
  Future<StoryEditorRecoverySnapshot?> load({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) async {
    return snapshot;
  }

  @override
  Future<bool> save(StoryEditorRecoverySnapshot snapshot) async {
    this.snapshot = snapshot;
    return true;
  }
}

class _FakeAutosaveScheduler implements StoryEditorAutosaveScheduler {
  StoryEditorAutosaveWork? lastWork;

  @override
  StoryEditorAutosaveState get state => const StoryEditorAutosaveState.idle();

  @override
  void dispose() {}

  @override
  void recordMeaningfulEdit(StoryEditorAutosaveWork work) {
    lastWork = work;
  }

  @override
  void recordPublishCriticalMetadataChange(StoryEditorAutosaveWork work) {
    lastWork = work;
  }
}

class _FakeStoryEditorImagePicker implements StoryEditorImagePickerGateway {
  _FakeStoryEditorImagePicker({
    this.image,
    List<StoryEditorPickedImage>? images,
  }) : images = images ?? const [];

  final StoryEditorPickedImage? image;
  final List<StoryEditorPickedImage> images;
  final requestedPurposes = <StoryEditorImagePickPurpose>[];

  @override
  Future<StoryEditorPickedImage?> pickImage(
    StoryEditorImagePickPurpose purpose,
  ) async {
    requestedPurposes.add(purpose);
    return image ?? (images.isEmpty ? null : images.first);
  }

  @override
  Future<List<StoryEditorPickedImage>> pickImages(
    StoryEditorImagePickPurpose purpose,
  ) async {
    requestedPurposes.add(purpose);
    return images;
  }
}

class _FakeStoryEditorMediaUploadGateway
    implements StoryEditorMediaUploadGateway {
  final requests = <StoryEditorMediaUploadRequest>[];
  final _pending = <String, Completer<StoryEditorUploadedMedia>>{};

  @override
  Future<StoryEditorUploadedMedia> upload(
    StoryEditorMediaUploadRequest request,
  ) {
    requests.add(request);
    final completer = Completer<StoryEditorUploadedMedia>();
    _pending[request.localMediaId] = completer;
    return completer.future;
  }

  void complete(String localMediaId, {required String fileId}) {
    _pending
        .remove(localMediaId)
        ?.complete(StoryEditorUploadedMedia(fileId: fileId));
  }
}

class _FakeStoryEditorMediaLifecycleGateway
    implements StoryEditorMediaLifecycleGateway {
  _FakeStoryEditorMediaLifecycleGateway({this.holdBinds = false});

  final bool holdBinds;
  final binds = <_StoryMediaBindCall>[];
  final releasedFileIds = <String>[];
  final _pendingBinds = <Completer<void>>[];

  @override
  Future<void> bindStoryMedia({
    required String storyId,
    required String? coverFileId,
    required Iterable<String> contentFileIds,
  }) async {
    binds.add(
      _StoryMediaBindCall(
        storyId: storyId,
        coverFileId: coverFileId,
        contentFileIds: contentFileIds.toList(growable: false),
      ),
    );
    if (holdBinds) {
      final completer = Completer<void>();
      _pendingBinds.add(completer);
      return completer.future;
    }
  }

  @override
  Future<void> releaseStoryMedia(Iterable<String> fileIds) async {
    releasedFileIds.addAll(fileIds);
  }

  void completeNextBind() {
    if (_pendingBinds.isEmpty) {
      return;
    }
    _pendingBinds.removeAt(0).complete();
  }
}

class _StoryMediaBindCall {
  const _StoryMediaBindCall({
    required this.storyId,
    required this.coverFileId,
    required this.contentFileIds,
  });

  final String storyId;
  final String? coverFileId;
  final List<String> contentFileIds;
}

const _tinyJpegBytes = <int>[0xFF, 0xD8, 0xFF, 0xD9];
const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';
const _tinyPngBytes = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
