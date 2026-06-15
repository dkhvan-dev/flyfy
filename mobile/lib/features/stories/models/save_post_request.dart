class SavePostRequest {
  SavePostRequest({
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    this.format = 'ARTICLE',
    this.contentBlocks,
    this.contentSchemaVersion = 1,
    this.coverFileId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    this.tags = const [],
  });

  final String title;
  final String content;
  final String format;
  final Map<String, dynamic>? contentBlocks;
  final int contentSchemaVersion;
  final String category;
  final String status;
  final String? coverFileId;
  final String? placeName;
  final String? placeCountryCode;
  final String? placeCityId;
  final List<String> tags;

  Map<String, dynamic> toJson() {
    return {
      'title': title.trim(),
      'content': content.trim(),
      'format': format.trim().isEmpty ? 'ARTICLE' : format.trim().toUpperCase(),
      'category': category.trim(),
      'status': status.trim(),
      if (contentBlocks != null) 'contentBlocks': contentBlocks,
      if (contentBlocks != null) 'contentSchemaVersion': contentSchemaVersion,
      'coverFileId': (coverFileId ?? '').trim().isEmpty
          ? null
          : coverFileId!.trim(),
      'placeName': (placeName ?? '').trim().isEmpty ? null : placeName!.trim(),
      'placeCountryCode': (placeCountryCode ?? '').trim().isEmpty
          ? null
          : placeCountryCode!.trim().toUpperCase(),
      'placeCityId': (placeCityId ?? '').trim().isEmpty
          ? null
          : placeCityId!.trim(),
      'tags': tags
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    };
  }
}
