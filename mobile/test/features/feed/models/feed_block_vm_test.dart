import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/config/app_config.dart';
import 'package:inflap/features/feed/models/feed_block_vm.dart';

void main() {
  test('parses stories tray block into story view models', () {
    final block = FeedBlockVm.fromJson({
      'id': 'tray-1',
      'type': 'stories_tray',
      'data': {
        'stories': [_storyJson('one'), _storyJson('two')],
      },
    });

    expect(block.id, 'tray-1');
    expect(block.type, FeedBlockType.storiesTray);
    expect(block.stories.map((story) => story.id), ['one', 'two']);
    expect(block.post, isNull);
    expect(block.communities, isEmpty);
  });

  test('parses suggested communities block into community view models', () {
    final block = FeedBlockVm.fromJson({
      'id': 'communities-1',
      'type': 'suggested_communities',
      'data': {
        'communities': [
          {
            'id': 'almaty-guides',
            'title': 'Almaty Guides',
            'subtitle': 'Local experiences',
            'avatarFileId': 'file-1',
            'membersCount': 1200,
            'followedByViewer': true,
          },
          {'id': 'istanbul-food', 'name': 'Istanbul Food', 'memberCount': '42'},
          {'id': 'inflap-news', 'title': 'Inflap News', 'followerCount': 77},
        ],
      },
    });

    expect(block.id, 'communities-1');
    expect(block.type, FeedBlockType.suggestedCommunities);
    expect(block.communities, hasLength(3));
    expect(block.communities.first.title, 'Almaty Guides');
    expect(block.communities.first.subtitle, 'Local experiences');
    expect(block.communities.first.avatarFileId, 'file-1');
    expect(block.communities.first.membersCount, 1200);
    expect(block.communities.first.followedByViewer, isTrue);
    expect(block.communities[1].title, 'Istanbul Food');
    expect(block.communities[1].membersCount, 42);
    expect(block.communities.last.title, 'Inflap News');
    expect(block.communities.last.membersCount, 77);
    expect(block.stories, isEmpty);
  });

  test('parses my subscriptions block into communities and people', () {
    final block = FeedBlockVm.fromJson({
      'id': 'subscriptions-1',
      'type': 'my_subscriptions',
      'data': {
        'communities': [
          {
            'id': 'investments',
            'title': 'Investments',
            'followerCount': 6326,
            'followedByViewer': true,
          },
        ],
        'people': [
          {
            'userId': 'friend-1',
            'nickname': 'Aigerim',
            'avatarFileId': 'avatar-1',
            'relationship': 'friend',
            'isOnline': true,
          },
          {'id': 'guide-1', 'nickname': 'Guide Nomad', 'relation': 'following'},
        ],
      },
    });

    expect(block.type, FeedBlockType.mySubscriptions);
    expect(block.communities.single.id, 'investments');
    expect(block.people, hasLength(2));
    expect(block.people.first.userId, 'friend-1');
    expect(block.people.first.nickname, 'Aigerim');
    expect(block.people.first.avatarFileId, 'avatar-1');
    expect(block.people.first.relationship, FeedPersonRelationship.friend);
    expect(block.people.first.isOnline, isTrue);
    expect(block.people.last.userId, 'guide-1');
    expect(block.people.last.relationship, FeedPersonRelationship.following);
  });

  test('parses community rules and drops blank entries', () {
    final community = FeedCommunityVm.fromJson({
      'id': 'community-1',
      'title': 'Almaty Guides',
      'rules': [
        'Share firsthand travel advice.',
        ' ',
        'Keep commercial offers transparent.',
        42,
      ],
    });

    expect(community.rules, [
      'Share firsthand travel advice.',
      'Keep commercial offers transparent.',
      '42',
    ]);
  });

  test('parses localized community title and description maps', () {
    final community = FeedCommunityVm.fromJson({
      'id': 'community-1',
      'title': 'Hobbies',
      'description': 'Fallback description.',
      'titleI18n': {
        'en': 'Hobbies',
        'ru': 'Хобби и мастер-классы',
        'kk': 'Хобби және шеберлік сабақтары',
      },
      'descriptionI18n': {
        'en': 'Workshops and casual meetups.',
        'ru': 'Мастер-классы и встречи по интересам.',
      },
    });

    expect(community.localizedTitle('ru'), 'Хобби и мастер-классы');
    expect(community.localizedTitle('kk'), 'Хобби және шеберлік сабақтары');
    expect(community.localizedTitle('fr'), 'Hobbies');
    expect(
      community.localizedDescription('ru'),
      'Мастер-классы и встречи по интересам.',
    );
    expect(
      community.localizedDescription('kk'),
      'Workshops and casual meetups.',
    );
  });

  test('parses viewer trust status for community profile UX', () {
    final community = FeedCommunityVm.fromJson({
      'id': 'community-1',
      'title': 'Almaty Guides',
      'viewerTrustStatus': 'APPEAL_PENDING',
      'viewerRestrictionId': 'restriction-123',
      'mutedByViewer': true,
    });

    expect(community.viewerTrustStatus, 'APPEAL_PENDING');
    expect(community.viewerRestrictionId, 'restriction-123');
    expect(community.mutedByViewer, isTrue);

    final updated = community.copyWith(
      viewerTrustStatus: 'ACTIVE',
      viewerRestrictionId: null,
      mutedByViewer: false,
    );

    expect(updated.viewerTrustStatus, 'ACTIVE');
    expect(updated.viewerRestrictionId, isNull);
    expect(updated.mutedByViewer, isFalse);
  });

  test('parses default post profile for community composer selection', () {
    final community = FeedCommunityVm.fromJson({
      'id': 'community-1',
      'title': 'Da Nang chat',
      'defaultPostProfileKey': 'quick_post_v1',
    });

    expect(community.defaultPostProfileKey, 'quick_post_v1');
    expect(community.isQuickPostCommunity, isTrue);

    final updated = community.copyWith(defaultPostProfileKey: 'article_v1');

    expect(updated.defaultPostProfileKey, 'article_v1');
    expect(updated.isQuickPostCommunity, isFalse);
  });

  test('parses post card block into a post view model', () {
    final block = FeedBlockVm.fromJson({
      'id': 'post-card-1',
      'type': 'post_card',
      'data': {
        'post': {
          ..._postJson('featured'),
          'coverFileId': 'cover-file-featured',
          'coverImageUrl': '/api/v1/public/files/cover-file-featured/content',
        },
      },
    });

    expect(block.id, 'post-card-1');
    expect(block.type, FeedBlockType.postCard);
    expect(block.post?.id, 'featured');
    expect(
      block.post?.coverUrl,
      '${Uri.parse(AppConfig.apiBaseUrl).origin}/api/v1/public/files/cover-file-featured/content',
    );
    expect(block.stories, isEmpty);
    expect(block.communities, isEmpty);
  });

  test('parses system posts block into post view models', () {
    final block = FeedBlockVm.fromJson({
      'id': 'system-posts',
      'type': 'system_posts',
      'data': {
        'posts': [_postJson('visa-update'), _postJson('safety-update')],
      },
    });

    expect(block.id, 'system-posts');
    expect(block.type, FeedBlockType.systemPosts);
    expect(block.posts.map((post) => post.id), [
      'visa-update',
      'safety-update',
    ]);
    expect(block.post, isNull);
    expect(block.stories, isEmpty);
    expect(block.communities, isEmpty);
  });

  test(
    'parses tour guide and profile feed block types as first-class blocks',
    () {
      final blocks = [
        FeedBlockVm.fromJson({
          'id': 'tour-1',
          'type': 'tour_card',
          'data': {'title': 'Weekend tour'},
        }),
        FeedBlockVm.fromJson({
          'id': 'guide-1',
          'type': 'guide_card',
          'data': {'title': 'Local guide'},
        }),
        FeedBlockVm.fromJson({
          'id': 'profile-1',
          'type': 'profile_card',
          'data': {'title': 'Traveler profile'},
        }),
      ];

      expect(blocks.map((block) => block.type), [
        FeedBlockType.tourCard,
        FeedBlockType.guideCard,
        FeedBlockType.profileCard,
      ]);
      expect(blocks.map((block) => block.id), [
        'tour-1',
        'guide-1',
        'profile-1',
      ]);
    },
  );

  test(
    'parses official news as first-class and unknown discovery blocks safely',
    () {
      final blocks = [
        FeedBlockVm.fromJson({
          'id': 'official-1',
          'type': 'official_news_card',
          'data': {
            'title': 'Travel update',
            'semanticTags': ['visa', 'official'],
          },
        }),
        FeedBlockVm.fromJson({
          'id': 'unsupported-1',
          'type': 'unsupported_discovery_card',
          'data': {'title': 'Future block'},
        }),
      ];

      expect(blocks.map((block) => block.type), [
        FeedBlockType.officialNewsCard,
        FeedBlockType.unknown,
      ]);
      expect(blocks.first.data['semanticTags'], ['visa', 'official']);
      expect(blocks.last.data['title'], 'Future block');
      expect(blocks.every((block) => block.post == null), isTrue);
    },
  );

  test('keeps unknown blocks safe and preserves raw data map', () {
    final block = FeedBlockVm.fromJson({
      'id': 'future-block',
      'type': 'new_backend_block',
      'data': {
        'payload': {'version': 2},
      },
    });

    expect(block.id, 'future-block');
    expect(block.type, FeedBlockType.unknown);
    expect(block.post, isNull);
    expect(block.stories, isEmpty);
    expect(block.communities, isEmpty);
    expect(block.data['payload'], {'version': 2});
  });

  test('parses feed page next cursor and block items safely', () {
    final page = FeedPageVm.fromJson({
      'nextCursor': 'cursor-2',
      'items': [
        {
          'id': 'post-card-1',
          'type': 'post_card',
          'data': {'post': _postJson('one')},
        },
        {'id': 'unknown-1', 'type': 'ads_v2', 'data': 'unexpected-scalar'},
      ],
    });

    expect(page.nextCursor, 'cursor-2');
    expect(page.items, hasLength(2));
    expect(page.items.first.post?.id, 'one');
    expect(page.items.last.type, FeedBlockType.unknown);
    expect(page.items.last.data, isEmpty);
  });

  test('merges cursor pages without duplicating existing feed blocks', () {
    final firstPage = [
      FeedBlockVm.fromJson({
        'id': 'post-card-one',
        'type': 'post_card',
        'data': {'post': _postJson('one')},
      }),
      FeedBlockVm.fromJson({
        'id': 'post-card-two',
        'type': 'post_card',
        'data': {'post': _postJson('two')},
      }),
    ];
    final nextPage = [
      FeedBlockVm.fromJson({
        'id': 'post-card-two',
        'type': 'post_card',
        'data': {'post': _postJson('two-updated')},
      }),
      FeedBlockVm.fromJson({
        'id': 'post-card-three',
        'type': 'post_card',
        'data': {'post': _postJson('three')},
      }),
    ];

    final merged = mergeFeedBlockPages(firstPage, nextPage);

    expect(merged.map((block) => block.id), [
      'post-card-one',
      'post-card-two',
      'post-card-three',
    ]);
    expect(merged[1].post?.id, 'two');
    expect(merged[2].post?.id, 'three');
  });
}

Map<String, Object?> _postJson(String id) {
  return {
    'id': id,
    'slug': 'post-$id',
    'title': 'Post $id',
    'excerpt': 'Excerpt',
    'category': 'JOURNAL',
    'status': 'PUBLISHED',
    'tags': const <String>[],
    'stats': const <String, int>{},
    'author': {
      'userId': 'author-$id',
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
    'likedByViewer': false,
    'shareUrl': '',
    'createdAt': '2026-05-10T00:00:00Z',
    'updatedAt': '2026-05-10T00:00:00Z',
  };
}

Map<String, Object?> _storyJson(String id) {
  return {
    'id': id,
    'caption': 'Story $id',
    'mediaFileId': 'media-$id',
    'mediaType': 'IMAGE',
    'expiresAt': '2026-05-11T00:00:00Z',
    'stats': const <String, int>{},
    'author': {
      'userId': 'author-$id',
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
    'createdAt': '2026-05-10T00:00:00Z',
    'updatedAt': '2026-05-10T00:00:00Z',
  };
}
