class SaveStoryRequest {
  SaveStoryRequest({
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    this.coverFileId,
    this.placeName,
    this.placeCountryCode,
    this.placeCityId,
    this.tags = const [],
  });

  final String title;
  final String content;
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
      'category': category.trim(),
      'status': status.trim(),
      'coverFileId':
          (coverFileId ?? '').trim().isEmpty ? null : coverFileId!.trim(),
      'placeName': (placeName ?? '').trim().isEmpty ? null : placeName!.trim(),
      'placeCountryCode': (placeCountryCode ?? '').trim().isEmpty
          ? null
          : placeCountryCode!.trim().toUpperCase(),
      'placeCityId':
          (placeCityId ?? '').trim().isEmpty ? null : placeCityId!.trim(),
      'tags': tags
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    };
  }
}
