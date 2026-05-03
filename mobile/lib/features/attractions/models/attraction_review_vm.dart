import 'attraction_vm.dart';

class AttractionReviewVm {
  const AttractionReviewVm({
    required this.id,
    required this.attractionId,
    required this.rating,
    required this.comment,
    required this.media,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String attractionId;
  final double rating;
  final String comment;
  final List<AttractionMediaVm> media;
  final AttractionAuthorVm author;
  final String createdAt;
  final String updatedAt;

  factory AttractionReviewVm.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AttractionMediaVm.fromJson)
        .toList();

    return AttractionReviewVm(
      id: json['id'] as String? ?? '',
      attractionId: json['attractionId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      media: mediaList,
      author: json['author'] is Map<String, dynamic>
          ? AttractionAuthorVm.fromJson(json['author'] as Map<String, dynamic>)
          : const AttractionAuthorVm(userId: ''),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
