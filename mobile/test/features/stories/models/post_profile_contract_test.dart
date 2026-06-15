import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/stories/models/post_profile_contract.dart';
import 'package:inflap/features/stories/models/post_vm.dart';

void main() {
  group('PostProfileContract', () {
    test('resolves known production profile keys to presentation modes', () {
      expect(
        PostProfileContract.resolve(PostProfileKeys.quickPost).presentationMode,
        PostPresentationMode.inlineThread,
      );
      expect(
        PostProfileContract.resolve(PostProfileKeys.article).presentationMode,
        PostPresentationMode.detailArticle,
      );
      expect(
        PostProfileContract.resolve(PostProfileKeys.listing).presentationMode,
        PostPresentationMode.listingCard,
      );
      expect(
        PostProfileContract.resolve(
          PostProfileKeys.eventAnnouncement,
        ).presentationMode,
        PostPresentationMode.eventCard,
      );
      expect(
        PostProfileContract.resolve(
          PostProfileKeys.questionAnswer,
        ).presentationMode,
        PostPresentationMode.questionThread,
      );
      expect(
        PostProfileContract.resolve(PostProfileKeys.tripPlan).presentationMode,
        PostPresentationMode.tripPlanCard,
      );
    });

    test('falls back to article for empty and unknown profile keys', () {
      expect(PostProfileContract.resolve(null).key, PostProfileKeys.article);
      expect(PostProfileContract.resolve('  ').key, PostProfileKeys.article);
      expect(
        PostProfileContract.resolve('unknown_v1').key,
        PostProfileKeys.article,
      );
    });

    test('marks only inline-thread profiles as list-native posts', () {
      expect(
        PostProfileContract.resolve(PostProfileKeys.quickPost).opensDetailPage,
        isFalse,
      );
      expect(
        PostProfileContract.resolve(PostProfileKeys.article).opensDetailPage,
        isTrue,
      );
      expect(
        PostProfileContract.resolve(PostProfileKeys.listing).opensDetailPage,
        isTrue,
      );
    });

    test('exposes per-profile composer field policy', () {
      final article = PostProfileContract.resolve(PostProfileKeys.article);
      final quickPost = PostProfileContract.resolve(PostProfileKeys.quickPost);
      final listing = PostProfileContract.resolve(PostProfileKeys.listing);
      final question = PostProfileContract.resolve(
        PostProfileKeys.questionAnswer,
      );

      expect(article.showTemplatePicker, isTrue);
      expect(article.showMaterialTaxonomy, isTrue);
      expect(article.requiresCover, isTrue);

      expect(quickPost.showMetadataPanel, isFalse);
      expect(quickPost.requiresTitle, isFalse);
      expect(quickPost.requiresCover, isFalse);

      expect(listing.showTemplatePicker, isFalse);
      expect(listing.showMaterialTaxonomy, isFalse);
      expect(listing.showTags, isTrue);
      expect(listing.showCover, isTrue);
      expect(listing.requiresCover, isFalse);

      expect(question.showCover, isFalse);
      expect(question.showTags, isTrue);
    });

    test('normalizes supported non-article profile keys for API writes', () {
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.quickPost),
        PostProfileKeys.quickPost,
      );
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.article),
        isNull,
      );
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.listing),
        PostProfileKeys.listing,
      );
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.eventAnnouncement),
        PostProfileKeys.eventAnnouncement,
      );
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.questionAnswer),
        PostProfileKeys.questionAnswer,
      );
      expect(
        PostProfileContract.normalizeForApi(PostProfileKeys.tripPlan),
        PostProfileKeys.tripPlan,
      );
      expect(PostProfileContract.normalizeForApi('unknown_v1'), isNull);
    });
  });

  group('PostVm profile helpers', () {
    test('uses resolved profile contract for detail navigation', () {
      final quickPost = _post(postProfileKey: PostProfileKeys.quickPost);
      final article = _post(postProfileKey: PostProfileKeys.article);
      final listing = _post(postProfileKey: PostProfileKeys.listing);

      expect(quickPost.isQuickPost, isTrue);
      expect(quickPost.opensDetailPage, isFalse);
      expect(article.opensDetailPage, isTrue);
      expect(listing.opensDetailPage, isTrue);
    });

    test('detects meaningful post edits after publish/create timestamp', () {
      final post = _post(
        postProfileKey: PostProfileKeys.quickPost,
        createdAt: DateTime.utc(2026, 6, 10, 12),
        publishedAt: DateTime.utc(2026, 6, 10, 12),
        updatedAt: DateTime.utc(2026, 6, 10, 12, 4),
      );

      expect(post.wasEditedAfterPublish, isTrue);
      expect(post.editedAt, DateTime.utc(2026, 6, 10, 12, 4));
    });
  });
}

PostVm _post({
  String? postProfileKey,
  DateTime? createdAt,
  DateTime? publishedAt,
  DateTime? updatedAt,
}) {
  final baseCreatedAt = createdAt ?? DateTime.utc(2026);
  return PostVm(
    id: 'post-1',
    slug: 'post-1',
    title: 'Title',
    excerpt: 'Excerpt',
    category: 'JOURNAL',
    status: 'PUBLISHED',
    tags: const [],
    stats: PostStatsVm(views: 0, likes: 0, comments: 0, shares: 0),
    author: PostAuthorVm(
      userId: 'user-1',
      locale: 'ru',
      timezone: 'Asia/Almaty',
    ),
    likedByViewer: false,
    shareUrl: '',
    postProfileKey: postProfileKey,
    publishedAt: publishedAt,
    createdAt: baseCreatedAt,
    updatedAt: updatedAt ?? baseCreatedAt,
  );
}
