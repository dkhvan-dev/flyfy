import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/data/story_editor_api.dart';
import 'package:inflap/features/stories/editor/data/story_editor_dto.dart';
import 'package:inflap/features/stories/editor/data/story_editor_recovery_store.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';
import 'package:inflap/features/stories/editor/domain/story_editor_autosave_policy.dart';
import 'package:inflap/features/stories/editor/presentation/story_editor_controller.dart';
import 'package:inflap/features/stories/models/story_vm.dart';

void main() {
  group('StoryEditorController', () {
    test('initializes create mode with a local draft id and empty state', () {
      final controller = _controller();

      controller.initializeCreate(userId: ' user-1 ');

      expect(controller.state.mode, StoryEditorMode.create);
      expect(controller.state.userId, 'user-1');
      expect(controller.state.localDraftId, 'local-draft-1');
      expect(controller.state.storyId, isNull);
      expect(controller.state.metadata.title, '');
      expect(controller.state.metadata.format, 'STORY');
      expect(controller.state.metadata.category, 'JOURNAL');
      expect(controller.state.document.blocks, isEmpty);
      expect(controller.state.saveStatus.phase, StoryEditorSavePhase.idle);
      expect(controller.state.recovery.hasSnapshot, isFalse);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.canRedo, isFalse);
    });

    test('initializes edit mode from an existing story snapshot', () {
      final story = _storyVm(
        id: 'story-1',
        title: 'Existing story',
        revision: 7,
        contentBlocks: [
          {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Remote content'},
        ],
      );
      final controller = _controller();

      controller.initializeEdit(userId: 'user-1', story: story);

      expect(controller.state.mode, StoryEditorMode.edit);
      expect(controller.state.storyId, 'story-1');
      expect(controller.state.localDraftId, isNull);
      expect(controller.state.metadata.title, 'Existing story');
      expect(controller.state.metadata.format, 'GUIDE');
      expect(controller.state.metadata.category, 'JOURNAL');
      expect(controller.state.metadata.coverFileId, 'cover-1');
      expect(controller.state.metadata.placeCountryCode, 'KZ');
      expect(controller.state.revision, 7);
      expect(controller.state.document.blocks.single.text, 'Remote content');
      expect(controller.state.isDirty, isFalse);
    });

    test('tracks dirty state and undo redo for metadata edits', () {
      final controller = _controller();
      controller.initializeEdit(userId: 'user-1', story: _storyVm());

      controller.changeTitle('Edited title');

      expect(controller.state.isDirty, isTrue);
      expect(controller.state.canUndo, isTrue);
      expect(controller.state.canRedo, isFalse);
      expect(controller.state.metadata.title, 'Edited title');

      controller.undo();

      expect(controller.state.metadata.title, 'Remote title');
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.canRedo, isTrue);

      controller.redo();

      expect(controller.state.metadata.title, 'Edited title');
      expect(controller.state.isDirty, isTrue);
      expect(controller.state.canUndo, isTrue);
    });

    test('tracks dirty state and undo redo for document edits', () {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');

      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-1', text: 'Body'),
      );

      expect(controller.state.document.blocks, hasLength(1));
      expect(controller.state.isDirty, isTrue);
      expect(controller.state.canUndo, isTrue);

      controller.undo();

      expect(controller.state.document.blocks, isEmpty);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canRedo, isTrue);

      controller.redo();

      expect(controller.state.document.blocks.single.text, 'Body');
      expect(controller.state.isDirty, isTrue);
    });

    test(
      'template replacement swaps untouched template blocks instead of stacking them',
      () {
        final controller = _controller();
        controller.initializeCreate(userId: 'user-1');

        controller.applyTemplate(
          templateId: 'weekend_guide',
          templateVersion: '1',
          format: 'GUIDE',
          category: 'GUIDE',
          blocks: [
            StoryBlock.heading(id: 'heading-template-1', text: 'Weekend plan'),
            StoryBlock.bulletedList(
              id: 'list-template-2',
              text: 'Morning stop\nLocal food',
            ),
          ],
        );
        controller.applyTemplate(
          templateId: 'photo_essay',
          templateVersion: '1',
          format: 'PHOTO_ESSAY',
          category: 'PHOTO_ESSAY',
          blocks: [
            StoryBlock.heading(id: 'heading-template-3', text: 'Photo story'),
          ],
        );

        expect(controller.state.metadata.format, 'PHOTO_ESSAY');
        expect(controller.state.metadata.category, 'PHOTO_ESSAY');
        expect(controller.state.template.appliedTemplateId, 'photo_essay');
        expect(controller.state.document.blocks.map((block) => block.text), [
          'Photo story',
        ]);
      },
    );

    test(
      'template replacement preserves user-authored and edited template blocks',
      () {
        final controller = _controller();
        controller.initializeCreate(userId: 'user-1');
        controller.applyTemplate(
          templateId: 'weekend_guide',
          templateVersion: '1',
          format: 'GUIDE',
          category: 'GUIDE',
          blocks: [
            StoryBlock.heading(id: 'heading-template-1', text: 'Weekend plan'),
            StoryBlock.bulletedList(
              id: 'list-template-2',
              text: 'Morning stop\nLocal food',
            ),
          ],
        );
        controller.updateBlock(
          'heading-template-1',
          (block) => block.copyWith(text: 'My real weekend plan'),
        );
        controller.addBlock(
          StoryBlock.paragraph(id: 'paragraph-user-1', text: 'Personal note'),
        );

        controller.applyTemplate(
          templateId: 'photo_essay',
          templateVersion: '1',
          format: 'PHOTO_ESSAY',
          category: 'PHOTO_ESSAY',
          blocks: [
            StoryBlock.heading(id: 'heading-template-3', text: 'Photo story'),
          ],
        );

        expect(controller.state.document.blocks.map((block) => block.text), [
          'My real weekend plan',
          'Personal note',
          'Photo story',
        ]);
        expect(
          controller.state.template.originFor('heading-template-1'),
          StoryEditorTemplateBlockOrigin.userEditedTemplate,
        );
        expect(
          controller.state.template.originFor('paragraph-user-1'),
          StoryEditorTemplateBlockOrigin.user,
        );
      },
    );

    test('template metadata-only mode leaves content untouched', () {
      final controller = _controller();
      controller.initializeCreate(userId: 'user-1');
      controller.addBlock(
        StoryBlock.paragraph(id: 'paragraph-user-1', text: 'Existing body'),
      );

      controller.applyTemplate(
        templateId: 'food_notes',
        templateVersion: '1',
        format: 'CULINARY',
        category: 'CULINARY',
        blocks: [
          StoryBlock.heading(id: 'heading-template-1', text: 'Where to eat'),
        ],
        mode: StoryEditorTemplateApplyMode.metadataOnly,
      );

      expect(controller.state.metadata.format, 'CULINARY');
      expect(controller.state.metadata.category, 'CULINARY');
      expect(controller.state.document.blocks.single.text, 'Existing body');
      expect(controller.state.template.appliedTemplateId, 'food_notes');
    });

    test(
      'template append mode keeps current content and appends new blocks',
      () {
        final controller = _controller();
        controller.initializeCreate(userId: 'user-1');
        controller.addBlock(
          StoryBlock.paragraph(id: 'paragraph-user-1', text: 'Existing body'),
        );

        controller.applyTemplate(
          templateId: 'food_notes',
          templateVersion: '1',
          format: 'CULINARY',
          category: 'CULINARY',
          blocks: [
            StoryBlock.heading(id: 'heading-template-1', text: 'Where to eat'),
          ],
          mode: StoryEditorTemplateApplyMode.append,
        );

        expect(controller.state.document.blocks.map((block) => block.text), [
          'Existing body',
          'Where to eat',
        ]);
        expect(
          controller.state.template.originFor('heading-template-1'),
          StoryEditorTemplateBlockOrigin.template,
        );
      },
    );

    test(
      'manual draft save creates remote draft without cover or content',
      () async {
        final api = _FakeStoryEditorApi();
        final recovery = _FakeStoryEditorRecovery();
        final controller = _controller(api: api, recovery: recovery);
        controller.initializeCreate(userId: 'user-1');
        controller.changeTitle('Pocket draft');

        await controller.saveDraft();

        expect(api.createDraftRequests, hasLength(1));
        expect(api.createDraftRequests.single.title, 'Pocket draft');
        expect(api.createDraftRequests.single.coverFileId, isNull);
        expect(api.createDraftRequests.single.document.blocks, isEmpty);
        expect(controller.state.storyId, 'created-story');
        expect(controller.state.localDraftId, isNull);
        expect(controller.state.mode, StoryEditorMode.edit);
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.saved);
        expect(recovery.cleared, hasLength(1));
      },
    );

    test('save draft binds uploaded story media to saved story', () async {
      final api = _FakeStoryEditorApi();
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
      final controller = _controller(
        api: api,
        mediaUpload: mediaUpload,
        mediaLifecycle: mediaLifecycle,
      );
      controller.initializeCreate(userId: 'user-1');
      controller.changeTitle('Weekend route');

      final coverUpload = controller.uploadCover(
        localMediaId: 'cover-local-1',
        fileName: 'cover.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1]),
      );
      mediaUpload.complete('cover-local-1', fileId: 'cover-file-1');
      await coverUpload;

      final imageUpload = controller.addImage(
        localMediaId: 'local-media-1',
        fileName: 'body.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([2]),
      );
      mediaUpload.complete('local-media-1', fileId: 'inline-file-1');
      await imageUpload;

      await controller.saveDraft();

      expect(mediaLifecycle.binds, hasLength(1));
      expect(mediaLifecycle.binds.single.storyId, 'created-story');
      expect(mediaLifecycle.binds.single.coverFileId, 'cover-file-1');
      expect(mediaLifecycle.binds.single.contentFileIds, ['inline-file-1']);
    });

    test('save draft stops locally when title and content are empty', () async {
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api);
      controller.initializeCreate(userId: 'user-1');

      await controller.saveDraft();

      expect(api.createDraftRequests, isEmpty);
      expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
      expect(
        controller.state.publishValidation.errors.map((error) => error.code),
        everyElement('draft_required'),
      );
      expect(
        controller.state.publishValidation.errors.map((error) => error.field),
        ['title', 'contentBlocks'],
      );
    });

    test(
      'cover upload after failed draft save keeps draft validation scope',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeCreate(userId: 'user-1');

        await controller.saveDraft();

        expect(
          controller.state.publishValidation.errors.map((error) => error.field),
          ['title', 'contentBlocks'],
        );

        final upload = controller.uploadCover(
          localMediaId: 'cover-local-1',
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

        expect(
          controller.state.publishValidation.errors.map((error) => error.field),
          ['title', 'contentBlocks'],
        );

        mediaUpload.complete('cover-local-1', fileId: 'cover-file-1');
        await upload;

        expect(
          controller.state.publishValidation.errors.map((error) => error.field),
          ['title', 'contentBlocks'],
        );
      },
    );

    test('save success clears dirty state and edit history', () async {
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api);
      controller.initializeEdit(userId: 'user-1', story: _storyVm());
      controller.changeTitle('Saved title');

      await controller.saveDraft();

      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.canRedo, isFalse);
    });

    test('publish surfaces backend validation errors', () async {
      final api = _FakeStoryEditorApi(
        publishError: StoryEditorApiException(
          message: 'Validation failed.',
          statusCode: 422,
          fieldErrors: const [
            StoryEditorFieldError(
              field: 'coverFileId',
              code: 'cover_required',
              message: 'Cover is required.',
            ),
          ],
        ),
      );
      final controller = _controller(api: api);
      controller.initializeEdit(
        userId: 'user-1',
        story: _storyVm(
          contentBlocks: [
            {
              'id': 'paragraph-1',
              'type': 'paragraph',
              'text': 'Publishable body',
            },
          ],
        ),
      );

      await controller.publish();

      expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
      expect(controller.state.publishValidation.isValid, isFalse);
      expect(
        controller.state.publishValidation.errors.single.field,
        'coverFileId',
      );
      expect(
        controller.state.publishValidation.errors.single.code,
        'cover_required',
      );
    });

    test('autosave delegates remote and recovery work successfully', () async {
      final api = _FakeStoryEditorApi();
      final recovery = _FakeStoryEditorRecovery();
      final autosave = _FakeAutosaveScheduler();
      final controller = _controller(
        api: api,
        recovery: recovery,
        autosave: autosave,
      );
      controller.initializeEdit(userId: 'user-1', story: _storyVm());

      controller.changeTitle('Autosaved title');
      await autosave.lastWork!.saveLocalSnapshot();
      await autosave.lastWork!.saveRemote();

      expect(autosave.meaningfulEdits, 1);
      expect(recovery.saved.single.metadata.title, 'Autosaved title');
      expect(api.autosaveRequests.single.title, 'Autosaved title');
      expect(controller.state.saveStatus.phase, StoryEditorSavePhase.saved);
    });

    test(
      'autosave failure keeps a local recovery snapshot and reports failure',
      () async {
        final api = _FakeStoryEditorApi(
          autosaveError: const StoryEditorTransientAutosaveException('offline'),
        );
        final recovery = _FakeStoryEditorRecovery();
        final autosave = _FakeAutosaveScheduler();
        final controller = _controller(
          api: api,
          recovery: recovery,
          autosave: autosave,
        );
        controller.initializeEdit(userId: 'user-1', story: _storyVm());

        controller.changeTitle('Offline title');
        await autosave.lastWork!.saveLocalSnapshot();
        await expectLater(
          autosave.lastWork!.saveRemote(),
          throwsA(isA<StoryEditorTransientAutosaveException>()),
        );

        expect(recovery.saved.single.metadata.title, 'Offline title');
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
        expect(controller.state.recovery.hasSnapshot, isTrue);
      },
    );

    test(
      'revision conflicts set conflict state without overwriting local edits',
      () async {
        final api = _FakeStoryEditorApi(
          updateError: StoryEditorApiException(
            message: 'Revision conflict.',
            statusCode: 409,
            fieldErrors: const [
              StoryEditorFieldError(
                field: 'revision',
                code: 'revision_conflict',
                message: 'Story was changed elsewhere.',
              ),
            ],
          ),
        );
        final controller = _controller(api: api);
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(revision: 3),
        );
        controller.changeTitle('Local unsaved title');

        await controller.saveDraft();

        expect(controller.state.metadata.title, 'Local unsaved title');
        expect(controller.state.revision, 3);
        expect(controller.state.conflict.hasConflict, isTrue);
        expect(controller.state.conflict.message, 'Revision conflict.');
        expect(
          controller.state.saveStatus.phase,
          StoryEditorSavePhase.conflict,
        );
      },
    );

    test(
      'uploads inline image media and replaces preview with file id',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeCreate(userId: 'user-1');

        final upload = controller.addImage(
          localMediaId: 'local-media-1',
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          byteSize: 3,
          localPath: '/tmp/cover.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

        expect(controller.state.mediaQueue.items, hasLength(1));
        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.uploading,
        );
        expect(
          controller.state.mediaQueue.items.single.localPath,
          '/tmp/cover.jpg',
        );
        expect(
          controller.state.mediaQueue.items.single.previewBytes,
          isNotNull,
        );
        expect(controller.state.document.blocks.single.image?.fileId, isEmpty);
        expect(
          controller.state.document.blocks.single.image?.uploadState,
          StoryUploadState.uploading,
        );
        mediaUpload.complete('local-media-1', fileId: 'file-1');
        await upload;

        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.uploaded,
        );
        expect(controller.state.mediaQueue.items.single.fileId, 'file-1');
        expect(controller.state.document.blocks.single.image?.fileId, 'file-1');
        expect(
          controller.state.document.blocks.single.image?.uploadState,
          StoryUploadState.complete,
        );
        expect(
          mediaUpload.requests.single.kind,
          StoryEditorMediaUploadKind.inlineImage,
        );
      },
    );

    test(
      'uploads gallery images into one block without overwriting indexes',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeCreate(userId: 'user-1');

        final upload = controller.addGalleryUploads(
          localGalleryId: 'gallery-local-1',
          images: [
            StoryEditorGalleryUploadDraft(
              localMediaId: 'gallery-local-1-1',
              fileName: 'first.jpg',
              mimeType: 'image/jpeg',
              bytes: Uint8List.fromList([1]),
            ),
            StoryEditorGalleryUploadDraft(
              localMediaId: 'gallery-local-1-2',
              fileName: 'second.png',
              mimeType: 'image/png',
              bytes: Uint8List.fromList([2]),
            ),
          ],
        );

        expect(
          controller.state.document.blocks.single.type,
          StoryBlockType.gallery,
        );
        expect(
          controller.state.document.blocks.single.gallery?.images,
          hasLength(2),
        );
        expect(controller.state.mediaQueue.items, hasLength(2));
        expect(mediaUpload.requests.map((request) => request.fileName), [
          'first.jpg',
          'second.png',
        ]);

        mediaUpload.complete('gallery-local-1-2', fileId: 'file-2');
        await Future<void>.delayed(Duration.zero);
        mediaUpload.complete('gallery-local-1-1', fileId: 'file-1');
        await upload;

        final images = controller.state.document.blocks.single.gallery!.images;
        expect(images.map((image) => image.fileId), ['file-1', 'file-2']);
        expect(
          images.map((image) => image.uploadState),
          everyElement(StoryUploadState.complete),
        );
      },
    );

    test(
      'removes one uploaded gallery image without deleting the gallery block',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
        final controller = _controller(
          mediaUpload: mediaUpload,
          mediaLifecycle: mediaLifecycle,
        );
        controller.initializeCreate(userId: 'user-1');

        final upload = controller.addGalleryUploads(
          localGalleryId: 'gallery-local-1',
          images: [
            StoryEditorGalleryUploadDraft(
              localMediaId: 'gallery-local-1-1',
              fileName: 'first.jpg',
              mimeType: 'image/jpeg',
              bytes: Uint8List.fromList([1]),
            ),
            StoryEditorGalleryUploadDraft(
              localMediaId: 'gallery-local-1-2',
              fileName: 'second.png',
              mimeType: 'image/png',
              bytes: Uint8List.fromList([2]),
            ),
            StoryEditorGalleryUploadDraft(
              localMediaId: 'gallery-local-1-3',
              fileName: 'third.jpg',
              mimeType: 'image/jpeg',
              bytes: Uint8List.fromList([3]),
            ),
          ],
        );
        mediaUpload.complete('gallery-local-1-1', fileId: 'file-1');
        mediaUpload.complete('gallery-local-1-2', fileId: 'file-2');
        mediaUpload.complete('gallery-local-1-3', fileId: 'file-3');
        await upload;

        controller.removeGalleryImage(
          blockId: 'gallery-gallery-local-1',
          imageIndex: 1,
        );

        expect(controller.state.document.blocks, hasLength(1));
        expect(
          controller.state.document.blocks.single.gallery?.images.map(
            (image) => image.fileId,
          ),
          ['file-1', 'file-3'],
        );
        expect(mediaLifecycle.releasedFileIds, ['file-2']);
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
      },
    );

    test('removed uploaded media is released as an unbound upload', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
      final controller = _controller(
        mediaUpload: mediaUpload,
        mediaLifecycle: mediaLifecycle,
      );
      controller.initializeCreate(userId: 'user-1');

      final upload = controller.addImage(
        localMediaId: 'local-media-1',
        fileName: 'body.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1]),
      );
      mediaUpload.complete('local-media-1', fileId: 'inline-file-1');
      await upload;

      controller.removeMediaUpload('local-media-1');

      expect(mediaLifecycle.releasedFileIds, ['inline-file-1']);
    });

    test('deleting media blocks removes linked media queue items', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
      final controller = _controller(
        mediaUpload: mediaUpload,
        mediaLifecycle: mediaLifecycle,
      );
      controller.initializeCreate(userId: 'user-1');

      final imageUpload = controller.addImage(
        localMediaId: 'local-media-1',
        fileName: 'body.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1]),
      );
      mediaUpload.complete('local-media-1', fileId: 'inline-file-1');
      await imageUpload;

      controller.deleteBlock('image-local-media-1');

      expect(controller.state.document.blocks, isEmpty);
      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.removed,
      );
      expect(mediaLifecycle.releasedFileIds, ['inline-file-1']);
    });

    test(
      'failed image upload can be retried without losing preview data',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeCreate(userId: 'user-1');

        final upload = controller.addImage(
          localMediaId: 'local-media-1',
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          byteSize: 3,
          localPath: '/tmp/cover.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );
        mediaUpload.fail('local-media-1', StateError('Network timeout'));
        await upload;

        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.failed,
        );
        expect(
          controller.state.mediaQueue.items.single.localPath,
          '/tmp/cover.jpg',
        );
        expect(
          controller.state.mediaQueue.items.single.previewBytes,
          isNotNull,
        );
        expect(
          controller.state.mediaQueue.items.single.errorCode,
          StoryEditorMediaErrorCode.uploadFailed,
        );
        expect(
          controller.state.document.blocks.single.image?.uploadState,
          StoryUploadState.failed,
        );

        final retry = controller.retryMediaUpload('local-media-1');
        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.uploading,
        );
        mediaUpload.complete('local-media-1', fileId: 'file-2');
        await retry;

        expect(
          controller.state.mediaQueue.items.single.status,
          StoryEditorMediaStatus.uploaded,
        );
        expect(controller.state.document.blocks.single.image?.fileId, 'file-2');
        expect(mediaUpload.requests, hasLength(2));
      },
    );

    test('stale cover upload completion releases superseded file', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final mediaLifecycle = _FakeStoryEditorMediaLifecycleGateway();
      final controller = _controller(
        mediaUpload: mediaUpload,
        mediaLifecycle: mediaLifecycle,
      );
      controller.initializeCreate(userId: 'user-1');

      final first = controller.uploadCover(
        localMediaId: 'cover-local-1',
        fileName: 'old-cover.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1]),
      );
      final second = controller.uploadCover(
        localMediaId: 'cover-local-2',
        fileName: 'new-cover.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([2]),
      );

      mediaUpload.completeAttempt(1, fileId: 'new-cover-file');
      await second;
      mediaUpload.completeAttempt(0, fileId: 'old-cover-file');
      await first;

      expect(controller.state.metadata.coverFileId, 'new-cover-file');
      expect(mediaLifecycle.releasedFileIds, ['old-cover-file']);
    });

    test('retry media upload is only available for failed media', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final controller = _controller(mediaUpload: mediaUpload);
      controller.initializeCreate(userId: 'user-1');

      final upload = controller.addImage(
        localMediaId: 'local-media-1',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await controller.retryMediaUpload('local-media-1');

      expect(mediaUpload.requests, hasLength(1));
      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.uploading,
      );

      mediaUpload.complete('local-media-1', fileId: 'file-1');
      await upload;

      await controller.retryMediaUpload('local-media-1');

      expect(mediaUpload.requests, hasLength(1));

      controller.removeMediaUpload('local-media-1');
      await controller.retryMediaUpload('local-media-1');

      expect(mediaUpload.requests, hasLength(1));
    });

    test(
      'stale cover upload completion cannot overwrite newer replacement',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeEdit(userId: 'user-1', story: _storyVm());

        final first = controller.uploadCover(
          localMediaId: 'cover-local-1',
          fileName: 'old-cover.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([1]),
        );
        final second = controller.uploadCover(
          localMediaId: 'cover-local-2',
          fileName: 'new-cover.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([2]),
        );

        mediaUpload.completeAttempt(1, fileId: 'new-cover-file');
        await second;
        mediaUpload.completeAttempt(0, fileId: 'old-cover-file');
        await first;

        expect(controller.state.metadata.coverFileId, 'new-cover-file');
        expect(
          controller.state.mediaQueue.items
              .where((item) => item.kind == StoryEditorMediaUploadKind.cover)
              .last
              .fileId,
          'new-cover-file',
        );
      },
    );

    test(
      'cover upload clears stale cover id and blocks publish until uploaded',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final api = _FakeStoryEditorApi();
        final controller = _controller(api: api, mediaUpload: mediaUpload);
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(
            coverFileId: 'old-cover-file',
            contentBlocks: [
              {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Body'},
            ],
          ),
        );

        final upload = controller.uploadCover(
          localMediaId: 'cover-local-1',
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          localPath: '/tmp/cover.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );

        expect(controller.state.metadata.coverFileId, isNull);
        expect(
          controller.state.publishValidation.errors.map((error) => error.code),
          contains('media_upload_pending'),
        );

        await controller.publish();

        expect(api.publishRequests, isEmpty);

        mediaUpload.complete('cover-local-1', fileId: 'new-cover-file');
        await upload;

        expect(controller.state.metadata.coverFileId, 'new-cover-file');
        expect(
          controller.state.publishValidation.errors.map((error) => error.code),
          isNot(contains('media_upload_pending')),
        );
      },
    );

    test(
      'failed cover upload keeps cover pending and preserves source',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final controller = _controller(mediaUpload: mediaUpload);
        controller.initializeEdit(userId: 'user-1', story: _storyVm());

        final upload = controller.uploadCover(
          localMediaId: 'cover-local-1',
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          localPath: '/tmp/cover.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );
        mediaUpload.fail('cover-local-1', StateError('Network timeout'));
        await upload;

        final item = controller.state.mediaQueue.items.single;
        expect(controller.state.metadata.coverFileId, isNull);
        expect(item.kind, StoryEditorMediaUploadKind.cover);
        expect(item.status, StoryEditorMediaStatus.failed);
        expect(item.localPath, '/tmp/cover.jpg');
        expect(item.previewBytes, isNotNull);
        expect(
          controller.state.publishValidation.errors.map((error) => error.code),
          contains('media_upload_pending'),
        );
      },
    );

    test('failed media can be removed without blocking publish', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api, mediaUpload: mediaUpload);
      controller.initializeEdit(
        userId: 'user-1',
        story: _storyVm(
          contentBlocks: [
            {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Body'},
          ],
        ),
      );

      final upload = controller.addImage(
        localMediaId: 'local-media-1',
        fileName: 'cover.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      mediaUpload.fail('local-media-1', StateError('Network timeout'));
      await upload;

      controller.removeMediaUpload('local-media-1');

      expect(
        controller.state.mediaQueue.items.single.status,
        StoryEditorMediaStatus.removed,
      );
      expect(
        controller.state.document.blocks.map((block) => block.id),
        isNot(contains('image-local-media-1')),
      );
      expect(
        controller.state.publishValidation.errors.map((error) => error.code),
        isNot(contains('media_upload_pending')),
      );

      await controller.publish();

      expect(api.publishRequests, hasLength(1));
    });

    test('publish is blocked while required media is uploading', () async {
      final mediaUpload = _FakeStoryEditorMediaUploadGateway();
      final api = _FakeStoryEditorApi();
      final controller = _controller(api: api, mediaUpload: mediaUpload);
      controller.initializeEdit(
        userId: 'user-1',
        story: _storyVm(
          contentBlocks: [
            {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Body'},
          ],
        ),
      );

      final upload = controller.addImage(
        localMediaId: 'local-media-1',
        fileName: 'cover.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await controller.publish();

      expect(api.publishRequests, isEmpty);
      expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
      expect(
        controller.state.publishValidation.errors.map((error) => error.code),
        contains('media_upload_pending'),
      );

      mediaUpload.complete('local-media-1', fileId: 'file-1');
      await upload;
    });

    test(
      'recovery snapshot preserves pending media status kind and source',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final recovery = _FakeStoryEditorRecovery();
        final autosave = _FakeAutosaveScheduler();
        final controller = _controller(
          recovery: recovery,
          autosave: autosave,
          mediaUpload: mediaUpload,
        );
        controller.initializeCreate(userId: 'user-1');

        final upload = controller.addImage(
          localMediaId: 'local-media-1',
          fileName: 'image.jpg',
          mimeType: 'image/jpeg',
          byteSize: 3,
          localPath: '/tmp/image.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );
        mediaUpload.fail('local-media-1', StateError('Network timeout'));
        await upload;
        await autosave.lastWork!.saveLocalSnapshot();

        final pending = recovery.saved.single.pendingMediaReferences.single;
        expect(pending.localMediaId, 'local-media-1');
        expect(pending.kind, StoryEditorMediaUploadKind.inlineImage.name);
        expect(pending.status, StoryEditorMediaStatus.failed.name);
        expect(pending.localPath, '/tmp/image.jpg');
        expect(pending.previewBytes, orderedEquals([1, 2, 3]));
      },
    );

    test(
      'recovery restores cover media kind status and retry source',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final snapshot = StoryEditorRecoverySnapshot(
          userId: 'user-1',
          storyId: 'story-1',
          metadata: StoryEditorMetadataDraft(
            title: 'Recovered title',
            format: 'STORY',
            category: 'JOURNAL',
            status: 'DRAFT',
          ),
          document: StoryDocument(
            blocks: [
              StoryBlock.paragraph(id: 'paragraph-1', text: 'Recovered body'),
            ],
          ),
          pendingMediaReferences: [
            StoryEditorPendingMediaReference(
              localMediaId: 'cover-local-1',
              kind: StoryEditorMediaUploadKind.cover.name,
              status: StoryEditorMediaStatus.failed.name,
              fileName: 'cover.jpg',
              mimeType: 'image/jpeg',
              byteSize: 3,
              localPath: '/tmp/cover.jpg',
              previewBytes: Uint8List.fromList([1, 2, 3]),
            ),
          ],
          lastRemoteRevision: 9,
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 10),
        );
        final controller = _controller(
          recovery: _FakeStoryEditorRecovery(snapshot: snapshot),
          mediaUpload: mediaUpload,
        );
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(id: 'story-1'),
        );

        await controller.loadRecoverySnapshot();
        await controller.recoverLocalSnapshot();

        final item = controller.state.mediaQueue.items.single;
        expect(item.kind, StoryEditorMediaUploadKind.cover);
        expect(item.status, StoryEditorMediaStatus.failed);
        expect(item.localPath, '/tmp/cover.jpg');
        expect(item.previewBytes, orderedEquals([1, 2, 3]));

        final retry = controller.retryMediaUpload('cover-local-1');
        expect(
          mediaUpload.requests.single.kind,
          StoryEditorMediaUploadKind.cover,
        );
        mediaUpload.complete('cover-local-1', fileId: 'cover-file-1');
        await retry;

        expect(controller.state.metadata.coverFileId, 'cover-file-1');
      },
    );

    test(
      'recovered queued media with source becomes failed so it can be retried',
      () async {
        final mediaUpload = _FakeStoryEditorMediaUploadGateway();
        final snapshot = StoryEditorRecoverySnapshot(
          userId: 'user-1',
          storyId: 'story-1',
          metadata: StoryEditorMetadataDraft(
            title: 'Recovered title',
            format: 'STORY',
            category: 'JOURNAL',
            status: 'DRAFT',
            coverFileId: 'cover-1',
            placeName: 'Almaty',
          ),
          document: StoryDocument(
            blocks: [
              StoryBlock.image(
                id: 'image-local-media-1',
                image: const StoryImagePayload(
                  fileId: '',
                  uploadState: StoryUploadState.uploading,
                ),
              ),
            ],
          ),
          pendingMediaReferences: [
            const StoryEditorPendingMediaReference(
              localMediaId: 'local-media-1',
              kind: 'inlineImage',
              status: 'uploading',
              blockId: 'image-local-media-1',
              fileName: 'image.jpg',
              mimeType: 'image/jpeg',
              localPath: '/tmp/image.jpg',
            ),
          ],
          lastRemoteRevision: 9,
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 10),
        );
        final controller = _controller(
          recovery: _FakeStoryEditorRecovery(snapshot: snapshot),
          mediaUpload: mediaUpload,
        );
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(id: 'story-1'),
        );

        await controller.loadRecoverySnapshot();
        await controller.recoverLocalSnapshot();

        final item = controller.state.mediaQueue.items.single;
        expect(item.status, StoryEditorMediaStatus.failed);
        expect(item.localPath, '/tmp/image.jpg');
        expect(item.errorCode, StoryEditorMediaErrorCode.uploadInterrupted);
        expect(
          controller.state.document.blocks.single.image?.uploadState,
          StoryUploadState.failed,
        );

        final retry = controller.retryMediaUpload('local-media-1');
        expect(mediaUpload.requests.single.localPath, '/tmp/image.jpg');
        mediaUpload.complete('local-media-1', fileId: 'file-1');
        await retry;

        expect(controller.state.document.blocks.single.image?.fileId, 'file-1');
      },
    );

    test('loads and discards recovery snapshots', () async {
      final snapshot = StoryEditorRecoverySnapshot(
        userId: 'user-1',
        storyId: 'story-1',
        metadata: StoryEditorMetadataDraft(
          title: 'Recovered title',
          format: 'STORY',
          category: 'JOURNAL',
          status: 'DRAFT',
        ),
        document: StoryDocument(
          blocks: [
            StoryBlock.paragraph(id: 'paragraph-1', text: 'Recovered body'),
          ],
        ),
        lastRemoteRevision: 9,
        lastLocalEditAt: DateTime.utc(2026, 6, 8, 10),
      );
      final recovery = _FakeStoryEditorRecovery(snapshot: snapshot);
      final controller = _controller(recovery: recovery);
      controller.initializeEdit(
        userId: 'user-1',
        story: _storyVm(id: 'story-1'),
      );

      final found = await controller.loadRecoverySnapshot();
      await controller.recoverLocalSnapshot();

      expect(found, isTrue);
      expect(controller.state.recovery.hasSnapshot, isTrue);
      expect(controller.state.metadata.title, 'Recovered title');
      expect(controller.state.document.blocks.single.text, 'Recovered body');
      expect(controller.state.revision, 9);

      await controller.discardLocalSnapshot();

      expect(recovery.cleared, hasLength(1));
      expect(controller.state.recovery.hasSnapshot, isFalse);
    });

    test(
      'autosave callbacks use the state captured when the edit was scheduled',
      () async {
        final api = _FakeStoryEditorApi();
        final recovery = _FakeStoryEditorRecovery();
        final autosave = _FakeAutosaveScheduler();
        final controller = _controller(
          api: api,
          recovery: recovery,
          autosave: autosave,
        );
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(
            contentBlocks: [
              {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Body'},
            ],
          ),
        );

        controller.changeTitle('First title');
        final firstWork = autosave.lastWork!;
        controller.changeTitle('Second title');

        await firstWork.saveLocalSnapshot();
        await firstWork.saveRemote();

        expect(recovery.saved.single.metadata.title, 'First title');
        expect(api.autosaveRequests.single.title, 'First title');
        expect(controller.state.metadata.title, 'Second title');
        expect(controller.state.revision, 5);
      },
    );

    test('stale manual save response does not overwrite newer edits', () async {
      final updateCompleter = Completer<StoryVm>();
      final api = _FakeStoryEditorApi(updateCompleter: updateCompleter);
      final controller = _controller(api: api);
      controller.initializeEdit(userId: 'user-1', story: _storyVm(revision: 5));

      controller.changeTitle('Title sent to server');
      final save = controller.saveDraft();
      controller.changeTitle('Newer local title');
      updateCompleter.complete(_storyVm(title: 'Server title', revision: 6));
      await save;

      expect(api.updateRequests.single.title, 'Title sent to server');
      expect(controller.state.metadata.title, 'Newer local title');
      expect(controller.state.revision, 5);
    });

    test('async save completion does not notify after dispose', () async {
      final updateCompleter = Completer<StoryVm>();
      final api = _FakeStoryEditorApi(updateCompleter: updateCompleter);
      final controller = _controller(api: api);
      var notifications = 0;
      controller
        ..initializeEdit(userId: 'user-1', story: _storyVm())
        ..addListener(() => notifications++);

      final save = controller.saveDraft();
      controller.dispose();
      updateCompleter.complete(_storyVm(title: 'Server title', revision: 6));

      await expectLater(save, completes);
      expect(notifications, 1);
    });

    test(
      'recovery ignores snapshots from a different editor identity',
      () async {
        final snapshot = StoryEditorRecoverySnapshot(
          userId: 'user-2',
          storyId: 'story-2',
          metadata: StoryEditorMetadataDraft(
            title: 'Wrong snapshot',
            format: 'STORY',
            category: 'JOURNAL',
            status: 'DRAFT',
          ),
          document: StoryDocument(
            blocks: [
              StoryBlock.paragraph(id: 'paragraph-1', text: 'Wrong body'),
            ],
          ),
          lastLocalEditAt: DateTime.utc(2026, 6, 8, 10),
        );
        final controller = _controller(
          recovery: _FakeStoryEditorRecovery(snapshot: snapshot),
        );
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(id: 'story-1', title: 'Current title'),
        );

        final found = await controller.loadRecoverySnapshot();
        await controller.recoverLocalSnapshot();

        expect(found, isFalse);
        expect(controller.state.recovery.hasSnapshot, isFalse);
        expect(controller.state.metadata.title, 'Current title');
      },
    );

    test(
      'publish stops locally when required metadata checklist is incomplete',
      () async {
        final api = _FakeStoryEditorApi();
        final controller = _controller(api: api);
        controller.initializeCreate(userId: 'user-1');
        controller
          ..changeFormat('')
          ..changeCategory('')
          ..changeTitle('');

        await controller.publish();

        expect(api.publishRequests, isEmpty);
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
        expect(
          controller.state.publishValidation.errors.map((error) => error.code),
          containsAll([
            'title_required',
            'format_required',
            'category_required',
            'cover_required',
            'place_required',
            'content_required',
          ]),
        );
      },
    );

    test(
      'publish requires a country even when place text is present',
      () async {
        final api = _FakeStoryEditorApi();
        final controller = _controller(api: api);
        controller.initializeCreate(userId: 'user-1');
        controller
          ..changeTitle('Ready title')
          ..changeCover('cover-1')
          ..changePlace(placeName: 'Almaty', clearCountryCode: true)
          ..addBlock(
            StoryBlock.paragraph(id: 'paragraph-1', text: 'Ready content'),
          );

        await controller.publish();

        expect(api.publishRequests, isEmpty);
        expect(controller.state.saveStatus.phase, StoryEditorSavePhase.failed);
        expect(
          controller.state.publishValidation.errors.map((error) => error.code),
          contains('country_required'),
        );
        expect(
          controller.state.publishValidation.errors.map((error) => error.field),
          contains('country'),
        );
      },
    );

    test(
      'autosave and publish clear recovery after confirmed remote success',
      () async {
        final api = _FakeStoryEditorApi();
        final recovery = _FakeStoryEditorRecovery();
        final autosave = _FakeAutosaveScheduler();
        final controller = _controller(
          api: api,
          recovery: recovery,
          autosave: autosave,
        );
        controller.initializeEdit(
          userId: 'user-1',
          story: _storyVm(
            contentBlocks: [
              {'id': 'paragraph-1', 'type': 'paragraph', 'text': 'Body'},
            ],
          ),
        );

        controller.changeTitle('Autosaved title');
        await autosave.lastWork!.saveLocalSnapshot();
        await autosave.lastWork!.saveRemote();

        expect(
          recovery.cleared,
          contains((userId: 'user-1', storyId: 'story-1', localDraftId: null)),
        );

        await controller.publish();

        expect(recovery.cleared.length, greaterThanOrEqualTo(2));
        expect(recovery.cleared.last.storyId, 'story-1');
      },
    );

    test('metadata cover and place can be explicitly cleared', () {
      final controller = _controller();
      controller.initializeEdit(userId: 'user-1', story: _storyVm());

      controller.changeCover(null);
      controller.clearPlace();

      expect(controller.state.metadata.coverFileId, isNull);
      expect(controller.state.metadata.placeName, isNull);
      expect(controller.state.metadata.placeCountryCode, isNull);
      expect(controller.state.metadata.placeCityId, isNull);
    });

    test(
      'pending image media is not serialized as a completed backend file id',
      () async {
        final api = _FakeStoryEditorApi();
        final controller = _controller(api: api);
        controller.initializeCreate(userId: 'user-1');
        controller
          ..changeTitle('Draft with pending image')
          ..addImage(localMediaId: 'local-media-1');

        await controller.saveDraft();

        final request = api.createDraftRequests.single;
        expect(request.document.blocks.single.image?.fileId, isEmpty);

        final body = request.toJson();
        final blocks = _contentBlocksFromRequestBody(body);
        expect(blocks, isEmpty);
        expect(controller.state.publishValidation.isValid, isFalse);
      },
    );

    test('conflict field errors are immutable in controller state', () async {
      final errors = [
        const StoryEditorFieldError(
          field: 'revision',
          code: 'revision_conflict',
          message: 'Conflict.',
        ),
      ];
      final api = _FakeStoryEditorApi(
        updateError: StoryEditorApiException(
          message: 'Conflict.',
          statusCode: 409,
          fieldErrors: errors,
        ),
      );
      final controller = _controller(api: api);
      controller.initializeEdit(userId: 'user-1', story: _storyVm());

      await controller.saveDraft();
      errors.clear();

      expect(controller.state.conflict.fieldErrors, hasLength(1));
      expect(
        () => controller.state.conflict.fieldErrors.add(
          const StoryEditorFieldError(
            field: 'revision',
            code: 'another',
            message: 'Another.',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
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

StoryVm _storyVm({
  String id = 'story-1',
  String title = 'Remote title',
  String format = 'GUIDE',
  String category = 'JOURNAL',
  String status = 'DRAFT',
  String? coverFileId = 'cover-1',
  String? placeName = 'Almaty',
  String? placeCountryCode = 'KZ',
  String? placeCityId = 'almaty',
  List<String> tags = const ['mountains'],
  int revision = 5,
  List<Map<String, dynamic>> contentBlocks = const [],
}) {
  return StoryVm(
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
    stats: StoryStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: StoryAuthorVm(
      userId: 'user-1',
      locale: 'en',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: '',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 7),
  );
}

class _FakeStoryEditorApi implements StoryEditorApiGateway {
  _FakeStoryEditorApi({
    StoryVm? storyById,
    this.autosaveError,
    this.updateError,
    this.publishError,
    this.updateCompleter,
  }) : storyById = storyById ?? _storyVm();

  final StoryVm storyById;
  final Object? autosaveError;
  final Object? updateError;
  final Object? publishError;
  final Completer<StoryVm>? updateCompleter;
  final createDraftRequests = <StoryEditorWriteRequest>[];
  final autosaveRequests = <StoryEditorWriteRequest>[];
  final updateRequests = <StoryEditorWriteRequest>[];
  final publishRequests = <StoryEditorWriteRequest>[];
  final archiveRevisions = <int?>[];

  @override
  Future<StoryVm> getStory(String storyId) async {
    return storyById;
  }

  @override
  Future<StoryVm> createDraft(StoryEditorWriteRequest request) async {
    createDraftRequests.add(request);
    final contentBlocks = _contentBlocksFromRequestBody(request.toJson());
    return _storyVm(
      id: 'created-story',
      title: request.title,
      coverFileId: request.coverFileId,
      contentBlocks: contentBlocks,
      revision: 1,
    );
  }

  @override
  Future<StoryVm> autosave(
    String storyId,
    StoryEditorWriteRequest request,
  ) async {
    autosaveRequests.add(request);
    final error = autosaveError;
    if (error != null) throw error;
    return _storyVm(
      id: storyId,
      title: request.title,
      revision: (request.revision ?? 0) + 1,
    );
  }

  @override
  Future<StoryVm> update(
    String storyId,
    StoryEditorWriteRequest request,
  ) async {
    updateRequests.add(request);
    final completer = updateCompleter;
    if (completer != null) {
      return completer.future;
    }
    final error = updateError;
    if (error != null) throw error;
    return _storyVm(
      id: storyId,
      title: request.title,
      revision: (request.revision ?? 0) + 1,
    );
  }

  @override
  Future<StoryVm> publish(
    String storyId,
    StoryEditorWriteRequest request,
  ) async {
    publishRequests.add(request);
    final error = publishError;
    if (error != null) throw error;
    return _storyVm(
      id: storyId,
      title: request.title,
      revision: (request.revision ?? 0) + 1,
    ).copyWith(status: 'PUBLISHED');
  }

  @override
  Future<StoryVm> archive(String storyId, {int? revision}) async {
    archiveRevisions.add(revision);
    return _storyVm(
      id: storyId,
      revision: (revision ?? 0) + 1,
    ).copyWith(status: 'ARCHIVED');
  }
}

List<Map<String, dynamic>> _contentBlocksFromRequestBody(
  Map<String, dynamic> body,
) {
  final document = body['contentBlocks'];
  final rawBlocks = switch (document) {
    final Map<String, dynamic> value when value['blocks'] is List =>
      value['blocks'] as List<dynamic>,
    final List<dynamic> value => value,
    _ => const <dynamic>[],
  };
  return rawBlocks.whereType<Map<String, dynamic>>().toList(growable: false);
}

class _FakeStoryEditorRecovery implements StoryEditorRecoveryGateway {
  _FakeStoryEditorRecovery({this.snapshot});

  StoryEditorRecoverySnapshot? snapshot;
  final saved = <StoryEditorRecoverySnapshot>[];
  final cleared = <({String userId, String? storyId, String? localDraftId})>[];

  @override
  Future<bool> save(StoryEditorRecoverySnapshot snapshot) async {
    saved.add(snapshot);
    this.snapshot = snapshot;
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
  Future<bool> clear({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) async {
    cleared.add((userId: userId, storyId: storyId, localDraftId: localDraftId));
    snapshot = null;
    return true;
  }
}

class _FakeAutosaveScheduler implements StoryEditorAutosaveScheduler {
  StoryEditorAutosaveWork? lastWork;
  int meaningfulEdits = 0;
  int criticalEdits = 0;

  @override
  StoryEditorAutosaveState get state => const StoryEditorAutosaveState.idle();

  @override
  void recordMeaningfulEdit(StoryEditorAutosaveWork work) {
    meaningfulEdits++;
    lastWork = work;
  }

  @override
  void recordPublishCriticalMetadataChange(StoryEditorAutosaveWork work) {
    criticalEdits++;
    lastWork = work;
  }

  @override
  void dispose() {}
}

class _FakeStoryEditorMediaUploadGateway
    implements StoryEditorMediaUploadGateway {
  final requests = <StoryEditorMediaUploadRequest>[];
  final _attempts = <_FakeUploadAttempt>[];
  final _pending = <String, Completer<StoryEditorUploadedMedia>>{};

  @override
  Future<StoryEditorUploadedMedia> upload(
    StoryEditorMediaUploadRequest request,
  ) {
    requests.add(request);
    final completer = Completer<StoryEditorUploadedMedia>();
    _attempts.add(_FakeUploadAttempt(request.localMediaId, completer));
    _pending[request.localMediaId] = completer;
    return completer.future;
  }

  void complete(String localMediaId, {required String fileId}) {
    _pending
        .remove(localMediaId)
        ?.complete(StoryEditorUploadedMedia(fileId: fileId));
  }

  void fail(String localMediaId, Object error) {
    _pending.remove(localMediaId)?.completeError(error);
  }

  void completeAttempt(int index, {required String fileId}) {
    final attempt = _attempts[index];
    if (!attempt.completer.isCompleted) {
      attempt.completer.complete(StoryEditorUploadedMedia(fileId: fileId));
    }
    if (identical(_pending[attempt.localMediaId], attempt.completer)) {
      _pending.remove(attempt.localMediaId);
    }
  }
}

class _FakeUploadAttempt {
  const _FakeUploadAttempt(this.localMediaId, this.completer);

  final String localMediaId;
  final Completer<StoryEditorUploadedMedia> completer;
}

class _FakeStoryEditorMediaLifecycleGateway
    implements StoryEditorMediaLifecycleGateway {
  final binds = <_StoryMediaBindCall>[];
  final releasedFileIds = <String>[];

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
  }

  @override
  Future<void> releaseStoryMedia(Iterable<String> fileIds) async {
    releasedFileIds.addAll(fileIds);
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
