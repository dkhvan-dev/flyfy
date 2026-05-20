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

class ReviewDraftRequest {
  const ReviewDraftRequest({
    required this.rating,
    required this.comment,
  });

  final double rating;
  final String comment;

  Map<String, dynamic> toJson() {
    return {'rating': rating, 'comment': comment.trim()};
  }
}

class ReviewMutationRequest {
  const ReviewMutationRequest._({
    this.rating,
    this.comment,
    this.delete = false,
  });

  factory ReviewMutationRequest.fromDraft(ReviewDraftRequest draft) {
    return ReviewMutationRequest._(
      rating: draft.rating,
      comment: draft.comment,
    );
  }

  const ReviewMutationRequest.delete() : this._(delete: true);

  final double? rating;
  final String? comment;
  final bool delete;

  Map<String, dynamic> toJson() {
    if (delete) return const {'delete': true};
    return {
      'rating': rating,
      'comment': (comment ?? '').trim(),
    };
  }
}

class SaveBookingReviewsRequest {
  const SaveBookingReviewsRequest({
    this.excursionReview,
    this.guideReview,
  });

  final ReviewMutationRequest? excursionReview;
  final ReviewMutationRequest? guideReview;

  Map<String, dynamic> toJson() {
    return {
      if (excursionReview != null) 'excursionReview': excursionReview!.toJson(),
      if (guideReview != null) 'guideReview': guideReview!.toJson(),
    };
  }
}
