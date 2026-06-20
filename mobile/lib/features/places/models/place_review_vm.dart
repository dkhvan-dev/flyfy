import 'place_vm.dart';

class PlaceReviewVm {
  const PlaceReviewVm({
    required this.id,
    required this.placeId,
    required this.rating,
    required this.comment,
    required this.media,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String placeId;
  final double rating;
  final String comment;
  final List<PlaceMediaVm> media;
  final PlaceAuthorVm author;
  final String createdAt;
  final String updatedAt;

  factory PlaceReviewVm.fromJson(Map<String, dynamic> json) {
    final mediaList = (json['media'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaceMediaVm.fromJson)
        .toList();

    return PlaceReviewVm(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? json['placeId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      media: mediaList,
      author: json['author'] is Map<String, dynamic>
          ? PlaceAuthorVm.fromJson(json['author'] as Map<String, dynamic>)
          : const PlaceAuthorVm(userId: ''),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
