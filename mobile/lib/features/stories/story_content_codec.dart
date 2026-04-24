class StoryContentPart {
  const StoryContentPart.text(this.text) : imageFileId = null;

  const StoryContentPart.image(this.imageFileId) : text = null;

  final String? text;
  final String? imageFileId;

  bool get isText => text != null;
}

final RegExp _storyImageMarkerRegExp = RegExp(r'\[\[story-image:([^\]]+)\]\]');

String storyImageMarker(String fileId) {
  final normalized = fileId.trim();
  if (normalized.isEmpty) {
    return '';
  }
  return '[[story-image:$normalized]]';
}

List<StoryContentPart> parseStoryContentParts(String rawContent) {
  final content = rawContent.trim();
  if (content.isEmpty) {
    return const <StoryContentPart>[];
  }

  final parts = <StoryContentPart>[];
  var cursor = 0;
  for (final match in _storyImageMarkerRegExp.allMatches(content)) {
    final before = content.substring(cursor, match.start).trim();
    if (before.isNotEmpty) {
      parts.add(StoryContentPart.text(before));
    }

    final fileId = (match.group(1) ?? '').trim();
    if (fileId.isNotEmpty) {
      parts.add(StoryContentPart.image(fileId));
    }
    cursor = match.end;
  }

  final tail = content.substring(cursor).trim();
  if (tail.isNotEmpty) {
    parts.add(StoryContentPart.text(tail));
  }

  return parts;
}

String extractStoryVisibleText(String rawContent) {
  final withoutMarkers = rawContent.replaceAllMapped(
    _storyImageMarkerRegExp,
    (_) => '\n\n',
  );
  return withoutMarkers
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}
