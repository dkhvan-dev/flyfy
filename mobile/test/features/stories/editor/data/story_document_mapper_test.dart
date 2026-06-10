import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/editor/data/story_document_mapper.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';

void main() {
  group('StoryDocumentMapper.fromLegacyContent', () {
    test('converts paragraphs and image markers into structured blocks', () {
      const legacy = '''
First paragraph.

Second paragraph.

[[story-image:file-1]]

Tail text.''';

      final document = StoryDocumentMapper.fromLegacyContent(legacy);

      expect(document.version, StoryDocument.currentVersion);
      expect(document.blocks.map((block) => block.type), [
        StoryBlockType.paragraph,
        StoryBlockType.paragraph,
        StoryBlockType.image,
        StoryBlockType.paragraph,
      ]);
      expect(document.blocks[0].text, 'First paragraph.');
      expect(document.blocks[1].text, 'Second paragraph.');
      expect(document.blocks[2].image?.fileId, 'file-1');
      expect(document.blocks[3].text, 'Tail text.');
    });

    test('keeps malformed markers as text content', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        'Intro [[story-image:missing-close',
      );

      expect(document.blocks, hasLength(1));
      expect(document.blocks.single.type, StoryBlockType.paragraph);
      expect(document.blocks.single.text, 'Intro [[story-image:missing-close');
    });

    test('converts adjacent image markers without empty text blocks', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        '[[story-image:file-1]][[story-image:file-2]]',
      );

      expect(document.blocks.map((block) => block.type), [
        StoryBlockType.image,
        StoryBlockType.image,
      ]);
      expect(document.blocks.map((block) => block.image?.fileId), [
        'file-1',
        'file-2',
      ]);
    });

    test('splits marker with surrounding text in one paragraph', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        'Before [[story-image:file-1]] after',
      );

      expect(document.blocks.map((block) => block.type), [
        StoryBlockType.paragraph,
        StoryBlockType.image,
        StoryBlockType.paragraph,
      ]);
      expect(document.blocks[0].text, 'Before');
      expect(document.blocks[1].image?.fileId, 'file-1');
      expect(document.blocks[2].text, 'after');
    });

    test('trims marker file ids and ignores empty marker ids', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        '[[story-image: file-1 ]]\n\n[[story-image:   ]]',
      );

      expect(document.blocks, hasLength(1));
      expect(document.blocks.single.type, StoryBlockType.image);
      expect(document.blocks.single.image?.fileId, 'file-1');
    });

    test('preserves multiple malformed markers as paragraph text', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        'A [[story-image:broken\n\nB [[story-image:still-broken',
      );

      expect(document.blocks.map((block) => block.type), [
        StoryBlockType.paragraph,
        StoryBlockType.paragraph,
      ]);
      expect(document.blocks[0].text, 'A [[story-image:broken');
      expect(document.blocks[1].text, 'B [[story-image:still-broken');
    });

    test('normalizes custom block id prefix before generating ids', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        'Intro\n\n[[story-image:file-1]]',
        blockIdPrefix: ' imported ',
      );

      expect(document.blocks.map((block) => block.id), [
        'imported-0',
        'imported-1',
      ]);
      expect(document.validateForDraft().isValid, isTrue);
    });

    test('falls back to legacy prefix when custom block id prefix is blank', () {
      final document = StoryDocumentMapper.fromLegacyContent(
        'Intro',
        blockIdPrefix: '   ',
      );

      expect(document.blocks.single.id, 'legacy-0');
      expect(document.validateForDraft().isValid, isTrue);
    });
  });

  group('StoryDocumentMapper.toLegacyContent', () {
    test('serializes text blocks and media markers for compatibility', () {
      final document = StoryDocument(
        blocks: [
          StoryBlock.heading(id: 'title', text: 'Arrival', level: 2),
          StoryBlock.paragraph(
            id: 'body',
            text: 'See the mountains',
            marks: const [
              StoryInlineMark.link(
                start: 8,
                end: 17,
                url: 'https://example.com/mountains',
              ),
            ],
          ),
          StoryBlock.gallery(
            id: 'gallery',
            gallery: StoryGalleryPayload(
              images: [
                StoryImagePayload(fileId: 'file-1'),
                StoryImagePayload(fileId: 'file-2'),
              ],
            ),
          ),
          StoryBlock.placeReference(
            id: 'place',
            place: const StoryPlaceReference(
              placeId: 'place-1',
              name: 'Almaty',
              countryCode: 'KZ',
              cityId: 'almaty',
            ),
          ),
        ],
      );

      expect(
        StoryDocumentMapper.toLegacyContent(document),
        [
          'Arrival',
          'See the mountains',
          '[[story-image:file-1]]',
          '[[story-image:file-2]]',
          'Almaty',
        ].join('\n\n'),
      );
    });

    test('round-trips legacy markers without dropping images', () {
      const legacy = 'Before\n\n[[story-image:file-1]]\n\nAfter';

      final document = StoryDocumentMapper.fromLegacyContent(legacy);
      final serialized = StoryDocumentMapper.toLegacyContent(document);

      expect(serialized, legacy);
    });
  });
}
