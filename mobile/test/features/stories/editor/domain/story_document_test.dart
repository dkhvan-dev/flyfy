import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';

void main() {
  group('StoryDocument editing', () {
    test(
      'updateBlock returns a new document without mutating the original',
      () {
        final original = StoryDocument(
          blocks: [
            StoryBlock.paragraph(id: 'intro', text: 'Before'),
            StoryBlock.divider(id: 'break'),
          ],
        );

        final updated = original.updateBlock(
          'intro',
          (block) => block.copyWith(text: 'After'),
        );

        expect(original.blockById('intro')?.text, 'Before');
        expect(updated.blockById('intro')?.text, 'After');
        expect(updated.blocks.last, same(original.blocks.last));
      },
    );

    test('lookup and editing helpers require canonical block ids', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(id: 'body', text: 'Body'),
          StoryBlock.paragraph(id: ' spaced ', text: 'Spaced'),
        ],
      );

      expect(document.validateForDraft().codes, contains('block_id_invalid'));
      expect(document.blockById('body')?.text, 'Body');
      expect(document.blockById(' body '), isNull);
      expect(
        document.updateBlock(
          ' body ',
          (block) => block.copyWith(text: 'Changed'),
        ),
        same(document),
      );
      expect(document.removeBlock(' body '), same(document));
      expect(document.moveBlock(' body ', 0), same(document));
    });

    test('moveBlock reorders blocks immutably', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(id: 'a', text: 'A'),
          StoryBlock.paragraph(id: 'b', text: 'B'),
          StoryBlock.paragraph(id: 'c', text: 'C'),
        ],
      );

      final moved = document.moveBlock('c', 0);

      expect(document.blocks.map((block) => block.id), ['a', 'b', 'c']);
      expect(moved.blocks.map((block) => block.id), ['c', 'a', 'b']);
    });

    test('block copyWith preserves type and compatible payload shape', () {
      final block = StoryBlock.image(
        id: 'image',
        image: const StoryImagePayload(fileId: 'file-1'),
      );

      final updated = block.copyWith(
        id: 'image-2',
        text: 'ignored',
        gallery: StoryGalleryPayload(
          images: const [StoryImagePayload(fileId: 'file-2')],
        ),
      );

      expect(updated.type, StoryBlockType.image);
      expect(updated.id, 'image-2');
      expect(updated.image?.fileId, 'file-1');
      expect(updated.text, isNull);
      expect(updated.gallery, isNull);
    });

    test('defensively copies nested input lists', () {
      final marks = [const StoryInlineMark.bold(start: 0, end: 4)];
      final block = StoryBlock.paragraph(
        id: 'body',
        text: 'Body text',
        marks: marks,
      );
      final blocks = [block];
      final images = [const StoryImagePayload(fileId: 'file-1')];
      final gallery = StoryGalleryPayload(images: images);

      final document = StoryDocument(blocks: blocks);

      blocks.add(StoryBlock.paragraph(id: 'late', text: 'Late mutation'));
      marks.add(const StoryInlineMark.italic(start: 5, end: 9));
      images.add(const StoryImagePayload(fileId: 'file-2'));

      expect(document.blocks, hasLength(1));
      expect(document.blocks.single.marks, hasLength(1));
      expect(gallery.images, hasLength(1));
      expect(
        () => document.blocks.add(StoryBlock.divider(id: 'blocked')),
        throwsUnsupportedError,
      );
      expect(
        () => document.blocks.single.marks.add(
          const StoryInlineMark.italic(start: 0, end: 4),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => gallery.images.add(const StoryImagePayload(fileId: 'blocked')),
        throwsUnsupportedError,
      );
    });

    test('nullable copyWith fields can be cleared explicitly', () {
      const link = StoryInlineMark.link(
        start: 0,
        end: 4,
        url: 'https://example.com',
      );
      const place = StoryPlaceReference(
        placeId: 'place-1',
        name: 'Almaty',
        countryCode: 'KZ',
        cityId: 'almaty',
        latitude: 43.2,
        longitude: 76.9,
      );
      final paragraph = StoryBlock.paragraph(id: 'body', text: 'Body');

      expect(link.copyWith(clearUrl: true).url, isNull);
      expect(
        place
            .copyWith(
              clearPlaceId: true,
              clearCountryCode: true,
              clearCityId: true,
              clearLatitude: true,
              clearLongitude: true,
            )
            .placeId,
        isNull,
      );
      expect(paragraph.copyWith(clearText: true).text, '');
    });
  });

  group('StoryDocument validation', () {
    test('empty valid document is draft-saveable but not publish-ready', () {
      final document = StoryDocument();

      expect(document.isDraftSaveable, isTrue);
      expect(document.isUploadComplete, isTrue);
      expect(document.isPublishReady, isFalse);
      expect(document.validateForPublish().codes, contains('content_required'));
    });

    test('text content makes document publish-ready', () {
      final document = StoryDocument(
        blocks: [StoryBlock.paragraph(id: 'body', text: 'A calm travel note')],
      );

      expect(document.isDraftSaveable, isTrue);
      expect(document.isUploadComplete, isTrue);
      expect(document.isPublishReady, isTrue);
      expect(document.plainText, 'A calm travel note');
    });

    test('incomplete image upload blocks publishing but not draft saving', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.image(
            id: 'image',
            image: const StoryImagePayload(
              fileId: '',
              uploadState: StoryUploadState.uploading,
            ),
          ),
        ],
      );

      expect(document.isDraftSaveable, isTrue);
      expect(document.isUploadComplete, isFalse);
      expect(document.isPublishReady, isFalse);
      expect(
        document.validateForPublish().codes,
        contains('upload_incomplete'),
      );
    });

    test('gallery upload completeness is validated for publishing', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.gallery(
            id: 'gallery',
            gallery: StoryGalleryPayload(
              images: [
                StoryImagePayload(fileId: 'ready'),
                StoryImagePayload(
                  fileId: '',
                  uploadState: StoryUploadState.uploading,
                ),
              ],
            ),
          ),
        ],
      );

      expect(document.isDraftSaveable, isTrue);
      expect(document.isUploadComplete, isFalse);
      expect(document.isPublishReady, isFalse);
      expect(
        document.validateForPublish().codes,
        contains('image_upload_incomplete'),
      );
    });

    test('empty gallery is rejected', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.gallery(
            id: 'gallery',
            gallery: StoryGalleryPayload(images: []),
          ),
        ],
      );

      expect(
        document.validateForDraft().codes,
        contains('gallery_images_required'),
      );
    });

    test('place reference requires a meaningful place', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.placeReference(
            id: 'place',
            place: const StoryPlaceReference(name: '  '),
          ),
        ],
      );

      expect(
        document.validateForDraft().codes,
        contains('place_reference_required'),
      );
    });

    test('route reference requires a route id and publishable title', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.routeReference(
            id: 'route',
            route: const StoryRouteReference(
              routeId: '',
              title: '  ',
              profile: 'pedestrian',
              distanceMeters: 1800,
              durationSeconds: 1320,
              stopsCount: 3,
              shareUrl: 'https://inflap.app/user-routes/route-1',
            ),
          ),
        ],
      );

      expect(
        document.validateForDraft().codes,
        contains('route_reference_required'),
      );
    });

    test('heading level must stay within supported range', () {
      final document = StoryDocument(
        blocks: [StoryBlock.heading(id: 'heading', text: 'Too deep', level: 4)],
      );

      expect(
        document.validateForDraft().codes,
        contains('heading_level_invalid'),
      );
    });

    test('invalid document version is rejected', () {
      final document = StoryDocument(
        version: StoryDocument.currentVersion + 1,
        blocks: [StoryBlock.paragraph(id: 'body', text: 'Body')],
      );

      expect(document.validateForDraft().codes, contains('invalid_version'));
    });

    test('block id is required', () {
      final document = StoryDocument(
        blocks: [StoryBlock.paragraph(id: '  ', text: 'Body')],
      );

      expect(document.validateForDraft().codes, contains('block_id_required'));
    });

    test('block id must already be trimmed', () {
      final document = StoryDocument(
        blocks: [StoryBlock.paragraph(id: ' body ', text: 'Body')],
      );

      expect(document.validateForDraft().codes, contains('block_id_invalid'));
    });

    test('inline mark range must stay within text bounds', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(
            id: 'body',
            text: 'Short',
            marks: const [StoryInlineMark.bold(start: 2, end: 20)],
          ),
        ],
      );

      expect(document.validateForDraft().codes, contains('mark_range_invalid'));
    });

    test('completed image requires a file id', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.image(
            id: 'image',
            image: const StoryImagePayload(fileId: ''),
          ),
        ],
      );

      expect(
        document.validateForDraft().codes,
        contains('image_file_id_required'),
      );
    });

    test(
      'plain text includes place and route references and ignores media',
      () {
        final document = StoryDocument(
          blocks: [
            StoryBlock.image(
              id: 'image',
              image: const StoryImagePayload(fileId: 'file-1'),
            ),
            StoryBlock.gallery(
              id: 'gallery',
              gallery: StoryGalleryPayload(
                images: const [StoryImagePayload(fileId: 'file-2')],
              ),
            ),
            StoryBlock.placeReference(
              id: 'place',
              place: const StoryPlaceReference(name: 'Almaty'),
            ),
            StoryBlock.routeReference(
              id: 'route',
              route: const StoryRouteReference(
                routeId: 'route-1',
                title: 'Panfilov morning walk',
                profile: 'pedestrian',
                distanceMeters: 1800,
                durationSeconds: 1320,
                stopsCount: 3,
                shareUrl: 'https://inflap.app/user-routes/route-1',
              ),
            ),
          ],
        );

        expect(document.plainText, 'Almaty\n\nPanfilov morning walk');
      },
    );

    test('unsafe link marks are rejected for drafts and publishing', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(
            id: 'body',
            text: 'Open this',
            marks: const [
              StoryInlineMark.link(
                start: 0,
                end: 4,
                url: 'javascript:alert(1)',
              ),
            ],
          ),
        ],
      );

      expect(document.isDraftSaveable, isFalse);
      expect(document.isPublishReady, isFalse);
      expect(document.validateForDraft().codes, contains('unsafe_link'));
    });

    test('text length limits are enforced', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(
            id: 'body',
            text: 'a' * (StoryDocumentLimits.maxTextBlockLength + 1),
          ),
        ],
      );

      expect(document.isDraftSaveable, isFalse);
      expect(document.validateForDraft().codes, contains('text_too_long'));
    });

    test('duplicate block ids are rejected', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.paragraph(id: 'same', text: 'One'),
          StoryBlock.paragraph(id: 'same', text: 'Two'),
        ],
      );

      expect(document.isDraftSaveable, isFalse);
      expect(document.validateForDraft().codes, contains('duplicate_block_id'));
    });

    test('validation issues are unmodifiable', () {
      final result = StoryDocument(
        blocks: [StoryBlock.paragraph(id: 'body', text: '')],
      ).validateForPublish();

      expect(
        () => result.issues.add(
          const StoryValidationIssue(code: 'x', message: 'x'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
