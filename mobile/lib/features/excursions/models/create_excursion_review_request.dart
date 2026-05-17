class CreateExcursionReviewRequest {
  const CreateExcursionReviewRequest({
    required this.rating,
    required this.comment,
  });

  final double rating;
  final String comment;

  Map<String, dynamic> toJson() {
    return {'rating': rating, 'comment': comment.trim()};
  }
}
