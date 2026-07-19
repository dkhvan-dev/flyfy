import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/saved/domain/saved_browse_models.dart';
import 'package:inflap/features/saved/domain/saved_target.dart';

void main() {
  test('list page strictly parses available and unavailable projections', () {
    final page = parseSavedItemsPage(<String, dynamic>{
      'items': <Object?>[
        savedItemJson(id: 'activity-1', savedAt: '2026-07-16T10:00:00Z'),
        savedItemJson(
          id: 'activity-2',
          savedAt: '2026-07-15T10:00:00Z',
          available: false,
        ),
      ],
      'next_cursor': 'opaque-cursor',
      'has_more': true,
    });

    expect(page.items, hasLength(2));
    expect(page.items.first.projection, isA<AvailableSavedCardProjection>());
    expect(
      (page.items.first.projection as AvailableSavedCardProjection)
          .canonicalDetailRoute,
      '/activities/activity-1',
    );
    expect(page.items.last.projection, isA<UnavailableSavedCardProjection>());
    expect(page.nextCursor, 'opaque-cursor');
  });

  test('available projections require exact canonical detail routes', () {
    const cases = <({SavedEntityType type, String id, String route})>[
      (
        type: SavedEntityType.attraction,
        id: 'place-1',
        route: '/places/place-1',
      ),
      (
        type: SavedEntityType.activity,
        id: 'activity-1',
        route: '/activities/activity-1',
      ),
      (
        type: SavedEntityType.guide,
        id: 'guide-1',
        route: '/users/guide-1/profile',
      ),
      (
        type: SavedEntityType.user,
        id: 'user-1',
        route: '/users/user-1/profile',
      ),
      (type: SavedEntityType.post, id: 'post-1', route: '/posts/post-1'),
    ];

    for (final testCase in cases) {
      final page = parseSavedItemsPage(<String, dynamic>{
        'items': <Object?>[
          savedItemJson(
            id: testCase.id,
            savedAt: '2026-07-16T10:00:00Z',
            entityType: testCase.type,
            canonicalDetailRoute: testCase.route,
          ),
        ],
        'next_cursor': null,
        'has_more': false,
      });

      expect(
        (page.items.single.projection as AvailableSavedCardProjection)
            .canonicalDetailRoute,
        testCase.route,
      );
    }

    for (final route in <String>[
      '',
      'https://flyfy.example/activities/activity-1',
      '/activities/',
      '/activities/activity-1/details',
      '/activities/activity-1?source=saved',
      '/activities/activity-1#saved',
      '/activities/activity%2F1',
      r'/activities/activity-1\edit',
      '/excursions/excursion-1',
      ' /activities/activity-1',
      '/activities/${List<String>.filled(245, 'a').join()}',
    ]) {
      expect(
        () => _parseSingleSavedItem(
          savedItemJson(
            id: 'activity-1',
            savedAt: '2026-07-16T10:00:00Z',
            canonicalDetailRoute: route,
          ),
        ),
        throwsFormatException,
        reason: 'route must fail closed: $route',
      );
    }

    final missingRoute = savedItemJson(
      id: 'activity-1',
      savedAt: '2026-07-16T10:00:00Z',
    );
    (missingRoute['projection']! as Map<String, Object?>).remove(
      'canonical_detail_route',
    );
    expect(() => _parseSingleSavedItem(missingRoute), throwsFormatException);

    final nullRoute = savedItemJson(
      id: 'activity-1',
      savedAt: '2026-07-16T10:00:00Z',
    );
    (nullRoute['projection']!
            as Map<String, Object?>)['canonical_detail_route'] =
        null;
    expect(() => _parseSingleSavedItem(nullRoute), throwsFormatException);

    final unavailableWithRoute = savedItemJson(
      id: 'activity-1',
      savedAt: '2026-07-16T10:00:00Z',
      available: false,
    );
    (unavailableWithRoute['projection']!
            as Map<String, Object?>)['canonical_detail_route'] =
        '/activities/activity-1';
    expect(
      () => _parseSingleSavedItem(unavailableWithRoute),
      throwsFormatException,
    );
  });

  test('normal pages reject date-order violations and extended JSON', () {
    expect(
      () => parseSavedItemsPage(<String, dynamic>{
        'items': <Object?>[
          savedItemJson(id: 'older', savedAt: '2026-07-15T10:00:00Z'),
          savedItemJson(id: 'newer', savedAt: '2026-07-16T10:00:00Z'),
        ],
        'next_cursor': null,
        'has_more': false,
      }),
      throwsFormatException,
    );
    expect(
      () => parseSavedItemsPage(<String, dynamic>{
        'items': <Object?>[],
        'next_cursor': null,
        'has_more': false,
        'total_count': 0,
      }),
      throwsFormatException,
    );
  });

  test('search page preserves relevance order without client date sorting', () {
    final page = parseSavedSearchPage(<String, dynamic>{
      'items': <Object?>[
        <String, Object?>{
          ...savedItemJson(id: 'exact-old', savedAt: '2026-07-10T10:00:00Z'),
          'match': <String, Object?>{
            'match_rank': 0,
            'match_kind': 'EXACT',
            'matched_field': 'TITLE',
            'matched_locale': 'en',
          },
        },
        <String, Object?>{
          ...savedItemJson(id: 'prefix-new', savedAt: '2026-07-16T10:00:00Z'),
          'match': <String, Object?>{
            'match_rank': 2,
            'match_kind': 'PREFIX',
            'matched_field': 'CITY',
            'matched_locale': 'ru',
          },
        },
      ],
      'next_cursor': null,
      'has_more': false,
    });

    expect(page.items.map((item) => item.target.entityId), [
      'exact-old',
      'prefix-new',
    ]);
  });

  test('capabilities gate unsupported entity types exactly', () {
    final capabilities = SavedCapabilities.fromJson(<String, dynamic>{
      'capability_revision': 'rev-7',
      'product_flags': <String, Object?>{
        'saved_items_enabled': true,
        'search_enabled': true,
        'collections_enabled': true,
      },
      'has_confirmed_saved_data': true,
      'supported_entity_types': <Object?>['ACTIVITY', 'ATTRACTION', 'USER'],
      'effective_locale': 'kk',
    });

    expect(
      capabilities.supportedEntityTypes,
      equals(<SavedEntityType>{
        SavedEntityType.activity,
        SavedEntityType.attraction,
        SavedEntityType.user,
      }),
    );
    expect(capabilities.effectiveLocale, SavedDisplayLocale.kk);
  });

  test(
    'collection list and assignment snapshot parse exact OpenAPI shapes',
    () {
      final collections = SavedCollectionsList.fromJson(<String, dynamic>{
        'collections': <Object?>[
          collectionJson(
            id: collectionA,
            title: 'Almaty',
            organizedAt: '2026-07-16T10:00:00Z',
          ),
          collectionJson(
            id: collectionB,
            title: 'Astana',
            organizedAt: '2026-07-15T10:00:00Z',
          ),
        ],
      });
      final snapshot = SavedTargetCollectionsSnapshot.fromJson(
        <String, dynamic>{
          'snapshot_version': 9,
          'target': const <String, Object?>{
            'entity_type': 'ACTIVITY',
            'entity_id': 'activity-1',
          },
          'relationship': <String, Object?>{
            'state': 'ACTIVE',
            'generation': relationshipGeneration,
            'version': 4,
          },
          'dependent_membership_version': 3,
          'effective_collection_ids': <Object?>[collectionA],
          'collection_options': <Object?>[
            <String, Object?>{
              'collection_id': collectionA,
              'title': 'Almaty',
              'metadata_version': 1,
              'lifecycle_version': 1,
            },
            <String, Object?>{
              'collection_id': collectionB,
              'title': 'Astana',
              'metadata_version': 2,
              'lifecycle_version': 1,
            },
          ],
        },
      );

      expect(collections.collections, hasLength(2));
      expect(snapshot.effectiveCollectionIds, [collectionA]);
      expect(
        snapshot.desiredSetJson(desiredCollectionIds: [collectionB]),
        <String, Object?>{
          'expected_relationship': <String, Object?>{
            'state': 'EXPECTED_ACTIVE',
            'generation': relationshipGeneration,
            'version': 4,
          },
          'expected_dependent_membership_version': 3,
          'desired_collection_ids': <String>[collectionB],
        },
      );
      expect(
        () => snapshot.desiredSetJson(
          desiredCollectionIds: [collectionB, collectionB],
        ),
        throwsArgumentError,
      );
    },
  );

  test('collection order violations are rejected', () {
    expect(
      () => SavedCollectionsList.fromJson(<String, dynamic>{
        'collections': <Object?>[
          collectionJson(
            id: collectionA,
            title: 'Older first',
            organizedAt: '2026-07-15T10:00:00Z',
          ),
          collectionJson(
            id: collectionB,
            title: 'Newer second',
            organizedAt: '2026-07-16T10:00:00Z',
          ),
        ],
      }),
      throwsFormatException,
    );
  });
}

const relationshipGeneration = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
const collectionA = '11111111-2222-3333-4444-555555555555';
const collectionB = '66666666-7777-8888-9999-aaaaaaaaaaaa';

Map<String, Object?> savedItemJson({
  required String id,
  required String savedAt,
  bool available = true,
  SavedEntityType entityType = SavedEntityType.activity,
  String? canonicalDetailRoute,
}) {
  return <String, Object?>{
    'target': <String, Object?>{
      'entity_type': entityType.wireValue,
      'entity_id': id,
    },
    'relationship': <String, Object?>{
      'generation': relationshipGeneration,
      'version': 4,
      'saved_at': savedAt,
    },
    'effective_collection_count': 1,
    'projection': available
        ? <String, Object?>{
            'projection_version': 2,
            'content_state': 'AVAILABLE',
            'display_locale': 'en',
            'title': 'Saved activity $id',
            'subtitle': 'Almaty',
            'image_url': 'https://images.example.test/$id.jpg',
            'canonical_detail_route': canonicalDetailRoute ?? '/activities/$id',
          }
        : <String, Object?>{
            'projection_version': 3,
            'content_state': 'UNAVAILABLE',
          },
  };
}

SavedListItem _parseSingleSavedItem(Map<String, Object?> item) {
  return parseSavedItemsPage(<String, dynamic>{
    'items': <Object?>[item],
    'next_cursor': null,
    'has_more': false,
  }).items.single;
}

Map<String, Object?> collectionJson({
  required String id,
  required String title,
  required String organizedAt,
}) {
  return <String, Object?>{
    'collection_id': id,
    'title': title,
    'lifecycle_state': 'ACTIVE',
    'metadata_version': 1,
    'lifecycle_version': 1,
    'active_item_count': 1,
    'cover_preview': const <String, Object?>{'kind': 'GENERIC'},
    'organized_at': organizedAt,
    'created_at': '2026-07-01T10:00:00Z',
    'updated_at': organizedAt,
  };
}
