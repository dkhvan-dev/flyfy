import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';
import 'package:inflap/features/stories/models/post_vm.dart';
import 'package:inflap/features/stories/widgets/story_document_renderer.dart';

void main() {
  Future<void> pumpRenderer(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }

  group('StoryDocumentRenderer', () {
    testWidgets('renders structured story blocks from PostVm', (tester) async {
      final story = _story(
        content: 'Stale text should not win',
        contentBlocks: [
          {
            'id': 'heading-1',
            'type': 'heading',
            'text': 'Morning in Almaty',
            'level': 2,
          },
          {
            'id': 'paragraph-1',
            'type': 'paragraph',
            'text': 'Start before the city wakes up.',
          },
          {
            'id': 'list-1',
            'type': 'bulleted_list',
            'text': 'Coffee near Panfilov Park\nGreen Bazaar stop',
          },
          {'id': 'quote-1', 'type': 'quote', 'text': 'Go slow.'},
          {
            'id': 'callout-1',
            'type': 'callout',
            'text': 'Bring cash for small vendors.',
          },
          {
            'id': 'image-1',
            'type': 'image',
            'image': {'fileId': 'image-file-1'},
          },
          {
            'id': 'gallery-1',
            'type': 'gallery',
            'gallery': {
              'images': [
                {'fileId': 'gallery-file-1'},
                {'fileId': 'gallery-file-2'},
                {'fileId': 'gallery-file-3'},
              ],
            },
          },
          {'id': 'divider-1', 'type': 'divider'},
          {
            'id': 'place-1',
            'type': 'place_reference',
            'place': {'name': 'Kok Tobe', 'countryCode': 'KZ'},
          },
        ],
      );

      await pumpRenderer(tester, StoryDocumentRenderer(story: story));

      expect(find.text('Morning in Almaty'), findsOneWidget);
      expect(find.text('Start before the city wakes up.'), findsOneWidget);
      expect(find.text('Coffee near Panfilov Park'), findsOneWidget);
      expect(find.text('Green Bazaar stop'), findsOneWidget);
      expect(find.text('Go slow.'), findsOneWidget);
      expect(find.text('Bring cash for small vendors.'), findsOneWidget);
      expect(find.text('Cable car view'), findsNothing);
      final firstImage = tester.getRect(
        find.byKey(const ValueKey('story-document-image-gallery-file-1-0')),
      );
      final secondImage = tester.getRect(
        find.byKey(const ValueKey('story-document-image-gallery-file-2-1')),
      );
      final thirdImage = tester.getRect(
        find.byKey(const ValueKey('story-document-image-gallery-file-3-2')),
      );
      expect(secondImage.left, greaterThan(firstImage.left));
      expect(thirdImage.left, greaterThan(secondImage.left));
      expect((secondImage.top - firstImage.top).abs(), lessThan(1));
      expect((thirdImage.top - firstImage.top).abs(), lessThan(1));
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('Kok Tobe'), findsOneWidget);
      expect(find.textContaining('KZ'), findsOneWidget);
      expect(find.text('Stale text should not win'), findsNothing);
    });

    testWidgets('renders editor preview from structured document', (
      tester,
    ) async {
      final document = StoryDocument(
        blocks: [
          StoryBlock.heading(id: 'heading-1', text: 'Preview title'),
          StoryBlock.numberedList(id: 'list-1', text: 'Pack bags\nBoard train'),
        ],
      );

      await pumpRenderer(tester, StoryDocumentRenderer(document: document));

      expect(find.text('Preview title'), findsOneWidget);
      expect(find.text('Pack bags'), findsOneWidget);
      expect(find.text('Board train'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('opens tapped gallery image with the full image list', (
      tester,
    ) async {
      List<StoryImagePayload>? openedImages;
      int? openedIndex;
      final document = StoryDocument(
        blocks: [
          StoryBlock.gallery(
            id: 'gallery-1',
            gallery: StoryGalleryPayload(
              images: const [
                StoryImagePayload(fileId: 'gallery-file-1'),
                StoryImagePayload(fileId: 'gallery-file-2'),
                StoryImagePayload(fileId: 'gallery-file-3'),
              ],
            ),
          ),
        ],
      );

      await pumpRenderer(
        tester,
        StoryDocumentRenderer(
          document: document,
          onOpenImages: (images, initialIndex) {
            openedImages = images;
            openedIndex = initialIndex;
          },
        ),
      );

      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(-160, 0),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('story-document-image-gallery-file-2-1')),
      );

      expect(openedIndex, 1);
      expect(openedImages?.map((image) => image.fileId), [
        'gallery-file-1',
        'gallery-file-2',
        'gallery-file-3',
      ]);
    });

    testWidgets('falls back to excerpt when structured blocks are missing', (
      tester,
    ) async {
      final story = _story(
        content: 'Stale content.\n\n[[story-image:legacy-file]]',
      );

      await pumpRenderer(tester, StoryDocumentRenderer(story: story));

      expect(find.text('Story excerpt'), findsOneWidget);
      expect(find.text('Stale content.'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('hides invalid empty blocks gracefully', (tester) async {
      final document = StoryDocument(
        blocks: [
          StoryBlock.heading(id: 'empty-heading', text: '   '),
          StoryBlock.paragraph(id: 'empty-paragraph', text: ''),
          StoryBlock.bulletedList(id: 'empty-list', text: '\n\n'),
          StoryBlock.quote(id: 'empty-quote', text: ' '),
          StoryBlock.callout(id: 'empty-callout', text: ''),
          StoryBlock.image(
            id: 'empty-image',
            image: const StoryImagePayload(fileId: ''),
          ),
          StoryBlock.gallery(
            id: 'empty-gallery',
            gallery: StoryGalleryPayload(
              images: const [StoryImagePayload(fileId: '')],
            ),
          ),
          StoryBlock.placeReference(
            id: 'empty-place',
            place: const StoryPlaceReference(name: ''),
          ),
          StoryBlock.paragraph(id: 'visible', text: 'Still visible'),
        ],
      );

      await pumpRenderer(tester, StoryDocumentRenderer(document: document));

      expect(find.text('Still visible'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.place_outlined), findsNothing);
      expect(find.byIcon(Icons.format_quote_rounded), findsNothing);
    });

    testWidgets('shows image error placeholder without breaking layout', (
      tester,
    ) async {
      final document = StoryDocument(
        blocks: [
          StoryBlock.image(
            id: 'image-1',
            image: const StoryImagePayload(fileId: 'broken-image-file'),
          ),
        ],
      );

      await pumpRenderer(tester, StoryDocumentRenderer(document: document));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

PostVm _story({
  String? content,
  List<Map<String, dynamic>> contentBlocks = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return PostVm(
    id: 'story-1',
    slug: 'story-1',
    title: 'Story title',
    excerpt: 'Story excerpt',
    content: content,
    contentBlocks: contentBlocks,
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const [],
    stats: PostStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(userId: 'author-1', locale: 'en', timezone: 'UTC'),
    likedByViewer: false,
    shareUrl: 'https://example.test/stories/story-1',
    createdAt: now,
    updatedAt: now,
  );
}
