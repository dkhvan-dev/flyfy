enum PostPresentationMode {
  detailArticle,
  inlineThread,
  listingCard,
  eventCard,
  questionThread,
  tripPlanCard,
}

enum PostComposerPreset {
  richArticle,
  quickPost,
  listingForm,
  eventAnnouncementForm,
  questionForm,
  tripPlanForm,
}

abstract final class PostProfileKeys {
  static const article = 'article_v1';
  static const quickPost = 'quick_post_v1';
  static const listing = 'listing_v1';
  static const eventAnnouncement = 'event_announcement_v1';
  static const questionAnswer = 'question_answer_v1';
  static const tripPlan = 'trip_plan_v1';

  static const supported = <String>{
    article,
    quickPost,
    listing,
    eventAnnouncement,
    questionAnswer,
    tripPlan,
  };

  static const mobileWritable = <String>{
    quickPost,
    listing,
    eventAnnouncement,
    questionAnswer,
    tripPlan,
  };
}

class PostProfileContract {
  const PostProfileContract({
    required this.key,
    required this.composerPreset,
    required this.presentationMode,
  });

  final String key;
  final PostComposerPreset composerPreset;
  final PostPresentationMode presentationMode;

  bool get isInlineThread =>
      presentationMode == PostPresentationMode.inlineThread;

  bool get opensDetailPage => !isInlineThread;

  bool get showMetadataPanel => !isInlineThread;

  bool get showTemplatePicker =>
      composerPreset == PostComposerPreset.richArticle;

  bool get showMaterialTaxonomy =>
      composerPreset == PostComposerPreset.richArticle;

  bool get showTags => showMetadataPanel;

  bool get showCover => switch (composerPreset) {
    PostComposerPreset.richArticle ||
    PostComposerPreset.listingForm ||
    PostComposerPreset.eventAnnouncementForm ||
    PostComposerPreset.tripPlanForm => true,
    PostComposerPreset.quickPost || PostComposerPreset.questionForm => false,
  };

  bool get requiresTitle => !isInlineThread;

  bool get requiresMaterialTaxonomy =>
      composerPreset == PostComposerPreset.richArticle;

  bool get requiresCover => composerPreset == PostComposerPreset.richArticle;

  bool get requiresPlace => !isInlineThread;

  static const article = PostProfileContract(
    key: PostProfileKeys.article,
    composerPreset: PostComposerPreset.richArticle,
    presentationMode: PostPresentationMode.detailArticle,
  );

  static const quickPost = PostProfileContract(
    key: PostProfileKeys.quickPost,
    composerPreset: PostComposerPreset.quickPost,
    presentationMode: PostPresentationMode.inlineThread,
  );

  static const listing = PostProfileContract(
    key: PostProfileKeys.listing,
    composerPreset: PostComposerPreset.listingForm,
    presentationMode: PostPresentationMode.listingCard,
  );

  static const eventAnnouncement = PostProfileContract(
    key: PostProfileKeys.eventAnnouncement,
    composerPreset: PostComposerPreset.eventAnnouncementForm,
    presentationMode: PostPresentationMode.eventCard,
  );

  static const questionAnswer = PostProfileContract(
    key: PostProfileKeys.questionAnswer,
    composerPreset: PostComposerPreset.questionForm,
    presentationMode: PostPresentationMode.questionThread,
  );

  static const tripPlan = PostProfileContract(
    key: PostProfileKeys.tripPlan,
    composerPreset: PostComposerPreset.tripPlanForm,
    presentationMode: PostPresentationMode.tripPlanCard,
  );

  static const _byKey = <String, PostProfileContract>{
    PostProfileKeys.article: article,
    PostProfileKeys.quickPost: quickPost,
    PostProfileKeys.listing: listing,
    PostProfileKeys.eventAnnouncement: eventAnnouncement,
    PostProfileKeys.questionAnswer: questionAnswer,
    PostProfileKeys.tripPlan: tripPlan,
  };

  static PostProfileContract resolve(String? rawKey) {
    final key = normalize(rawKey);
    if (key == null) {
      return article;
    }
    return _byKey[key] ?? article;
  }

  static String? normalize(String? rawKey) {
    final normalized = rawKey?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static String? normalizeForApi(String? rawKey) {
    final normalized = normalize(rawKey);
    if (normalized == null || normalized == PostProfileKeys.article) {
      return null;
    }
    return PostProfileKeys.supported.contains(normalized) ? normalized : null;
  }
}
