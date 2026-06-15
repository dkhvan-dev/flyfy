enum StoryEditorTrustBannerKind { blocked, muted, pendingAppeal, rejected }

class StoryEditorTrustContext {
  const StoryEditorTrustContext({
    required this.kind,
    required this.title,
    required this.message,
    this.blocksPublishing = false,
  });

  final StoryEditorTrustBannerKind kind;
  final String title;
  final String message;
  final bool blocksPublishing;
}
