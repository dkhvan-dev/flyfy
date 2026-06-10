import '../../story_content_codec.dart';
import '../domain/story_document.dart';

class StoryDocumentMapper {
  const StoryDocumentMapper._();

  static StoryDocument fromLegacyContent(
    String rawContent, {
    String blockIdPrefix = 'legacy',
  }) {
    final blocks = <StoryBlock>[];
    final normalizedBlockIdPrefix = _normalizeBlockIdPrefix(blockIdPrefix);
    var index = 0;

    for (final part in parseStoryContentParts(rawContent)) {
      if (part.isText) {
        for (final paragraph in _splitParagraphs(part.text ?? '')) {
          blocks.add(
            StoryBlock.paragraph(
              id: '$normalizedBlockIdPrefix-${index++}',
              text: paragraph,
            ),
          );
        }
      } else {
        final fileId = (part.imageFileId ?? '').trim();
        if (fileId.isNotEmpty) {
          blocks.add(
            StoryBlock.image(
              id: '$normalizedBlockIdPrefix-${index++}',
              image: StoryImagePayload(fileId: fileId),
            ),
          );
        }
      }
    }

    return StoryDocument(blocks: blocks);
  }

  static String toLegacyContent(StoryDocument document) {
    final parts = <String>[];
    for (final block in document.blocks) {
      switch (block.type) {
        case StoryBlockType.paragraph:
        case StoryBlockType.heading:
        case StoryBlockType.bulletedList:
        case StoryBlockType.numberedList:
        case StoryBlockType.quote:
        case StoryBlockType.callout:
          final text = (block.text ?? '').trim();
          if (text.isNotEmpty) {
            parts.add(text);
          }
        case StoryBlockType.image:
          final marker = storyImageMarker(block.image?.fileId ?? '');
          if (marker.isNotEmpty) {
            parts.add(marker);
          }
        case StoryBlockType.gallery:
          for (final image in block.gallery?.images ?? const []) {
            final marker = storyImageMarker(image.fileId);
            if (marker.isNotEmpty) {
              parts.add(marker);
            }
          }
        case StoryBlockType.placeReference:
          final placeName = (block.place?.name ?? '').trim();
          if (placeName.isNotEmpty) {
            parts.add(placeName);
          }
        case StoryBlockType.divider:
          break;
      }
    }
    return parts.join('\n\n').trim();
  }

  static List<String> _splitParagraphs(String rawText) {
    return rawText
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String _normalizeBlockIdPrefix(String rawPrefix) {
    final prefix = rawPrefix.trim();
    return prefix.isEmpty ? 'legacy' : prefix;
  }
}
