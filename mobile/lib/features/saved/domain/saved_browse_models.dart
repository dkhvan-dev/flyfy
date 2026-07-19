import 'saved_operation.dart';
import 'saved_target.dart';

enum SavedDisplayLocale {
  en('en'),
  ru('ru'),
  kk('kk');

  const SavedDisplayLocale(this.wireValue);

  final String wireValue;

  static SavedDisplayLocale fromWireValue(Object? value) {
    return switch (value) {
      'en' => SavedDisplayLocale.en,
      'ru' => SavedDisplayLocale.ru,
      'kk' => SavedDisplayLocale.kk,
      _ => throw FormatException('Unsupported Saved locale: $value.'),
    };
  }
}

enum SavedContentState { available, unavailable }

sealed class SavedCardProjection {
  const SavedCardProjection({required this.projectionVersion});

  final int projectionVersion;
  SavedContentState get contentState;

  factory SavedCardProjection.fromJson(Map<String, dynamic> json) {
    return switch (json['content_state']) {
      'AVAILABLE' => AvailableSavedCardProjection.fromJson(json),
      'UNAVAILABLE' => UnavailableSavedCardProjection.fromJson(json),
      _ => throw FormatException(
        'Unsupported Saved projection state: ${json['content_state']}.',
      ),
    };
  }
}

final class AvailableSavedCardProjection extends SavedCardProjection {
  AvailableSavedCardProjection({
    required super.projectionVersion,
    required this.displayLocale,
    required String title,
    required String canonicalDetailRoute,
    String? subtitle,
    Uri? imageUrl,
    this.sourceUpdatedAt,
  }) : title = _requireText(title, 'title', minimum: 1, maximum: 300),
       canonicalDetailRoute = _requireCanonicalDetailRoute(
         canonicalDetailRoute,
       ),
       subtitle = subtitle == null
           ? null
           : _requireText(subtitle, 'subtitle', maximum: 500),
       imageUrl = _requireHttpUriOrNull(imageUrl, 'imageUrl') {
    _requireVersion(projectionVersion, 'projectionVersion');
    if (sourceUpdatedAt != null) {
      _requireOffsetTimestamp(sourceUpdatedAt!, 'sourceUpdatedAt');
    }
  }

  factory AvailableSavedCardProjection.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'projection_version',
        'content_state',
        'display_locale',
        'title',
        'canonical_detail_route',
      },
      optionalKeys: const {'subtitle', 'image_url', 'source_updated_at'},
    );
    if (json['content_state'] != 'AVAILABLE') {
      throw const FormatException('Projection must be AVAILABLE.');
    }
    final version = json['projection_version'];
    final title = json['title'];
    final canonicalDetailRoute = json['canonical_detail_route'];
    final subtitle = json['subtitle'];
    final imageUrl = json['image_url'];
    if (version is! int ||
        title is! String ||
        canonicalDetailRoute is! String ||
        (json.containsKey('subtitle') && subtitle is! String) ||
        (json.containsKey('image_url') && imageUrl is! String)) {
      throw const FormatException('Available projection fields are malformed.');
    }
    return AvailableSavedCardProjection(
      projectionVersion: version,
      displayLocale: SavedDisplayLocale.fromWireValue(json['display_locale']),
      title: title,
      canonicalDetailRoute: _parseCanonicalDetailRoute(canonicalDetailRoute),
      subtitle: subtitle as String?,
      imageUrl: imageUrl == null ? null : Uri.parse(imageUrl as String),
      sourceUpdatedAt: json.containsKey('source_updated_at')
          ? _parseTimestamp(json['source_updated_at'], 'source_updated_at')
          : null,
    );
  }

  @override
  SavedContentState get contentState => SavedContentState.available;

  final SavedDisplayLocale displayLocale;
  final String title;
  final String canonicalDetailRoute;
  final String? subtitle;
  final Uri? imageUrl;
  final DateTime? sourceUpdatedAt;
}

final class UnavailableSavedCardProjection extends SavedCardProjection {
  UnavailableSavedCardProjection({required super.projectionVersion}) {
    _requireVersion(projectionVersion, 'projectionVersion');
  }

  factory UnavailableSavedCardProjection.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {'projection_version', 'content_state'},
    );
    if (json['content_state'] != 'UNAVAILABLE' ||
        json['projection_version'] is! int) {
      throw const FormatException(
        'Unavailable projection fields are malformed.',
      );
    }
    return UnavailableSavedCardProjection(
      projectionVersion: json['projection_version'] as int,
    );
  }

  @override
  SavedContentState get contentState => SavedContentState.unavailable;
}

final class SavedActiveRelationship {
  SavedActiveRelationship({
    required String generation,
    required int version,
    required DateTime savedAt,
    String? attributionId,
  }) : generation = _requireUuid(generation, 'generation'),
       version = _requireVersion(version, 'version', positive: true),
       savedAt = _requireOffsetTimestamp(savedAt, 'savedAt'),
       attributionId = attributionId == null
           ? null
           : _requireUuid(attributionId, 'attributionId');

  factory SavedActiveRelationship.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {'generation', 'version', 'saved_at'},
      optionalKeys: const {'attribution_id'},
    );
    final generation = json['generation'];
    final version = json['version'];
    final attributionId = json['attribution_id'];
    if (generation is! String ||
        version is! int ||
        (json.containsKey('attribution_id') && attributionId is! String)) {
      throw const FormatException('Saved relationship fields are malformed.');
    }
    return SavedActiveRelationship(
      generation: generation,
      version: version,
      savedAt: _parseTimestamp(json['saved_at'], 'saved_at'),
      attributionId: attributionId as String?,
    );
  }

  final String generation;
  final int version;
  final DateTime savedAt;
  final String? attributionId;
}

class SavedListItem {
  SavedListItem({
    required this.target,
    required this.relationship,
    required int effectiveCollectionCount,
    required this.projection,
  }) : effectiveCollectionCount = _requireBoundedInt(
         effectiveCollectionCount,
         'effectiveCollectionCount',
         maximum: 200,
       );

  factory SavedListItem.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'target',
        'relationship',
        'effective_collection_count',
        'projection',
      },
    );
    final count = json['effective_collection_count'];
    if (count is! int) {
      throw const FormatException(
        'effective_collection_count must be an integer.',
      );
    }
    return SavedListItem(
      target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
      relationship: SavedActiveRelationship.fromJson(
        _requireObject(json['relationship'], 'relationship'),
      ),
      effectiveCollectionCount: count,
      projection: SavedCardProjection.fromJson(
        _requireObject(json['projection'], 'projection'),
      ),
    );
  }

  final SavedTarget target;
  final SavedActiveRelationship relationship;
  final int effectiveCollectionCount;
  final SavedCardProjection projection;
}

enum SavedSearchMatchKind {
  exact('EXACT'),
  token('TOKEN'),
  prefix('PREFIX');

  const SavedSearchMatchKind(this.wireValue);
  final String wireValue;
}

enum SavedSearchMatchedField {
  title('TITLE'),
  city('CITY'),
  country('COUNTRY');

  const SavedSearchMatchedField(this.wireValue);
  final String wireValue;
}

final class SavedSearchMatch {
  SavedSearchMatch({
    required int matchRank,
    required this.matchKind,
    required this.matchedField,
    required this.matchedLocale,
    String? alternatePublicDisplayValue,
  }) : matchRank = _requireBoundedInt(matchRank, 'matchRank', maximum: 1000000),
       alternatePublicDisplayValue = alternatePublicDisplayValue == null
           ? null
           : _requireText(
               alternatePublicDisplayValue,
               'alternatePublicDisplayValue',
               maximum: 300,
             );

  factory SavedSearchMatch.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'match_rank',
        'match_kind',
        'matched_field',
        'matched_locale',
      },
      optionalKeys: const {'alternate_public_display_value'},
    );
    final rank = json['match_rank'];
    final alternate = json['alternate_public_display_value'];
    if (rank is! int ||
        (json.containsKey('alternate_public_display_value') &&
            alternate is! String)) {
      throw const FormatException('Search match fields are malformed.');
    }
    return SavedSearchMatch(
      matchRank: rank,
      matchKind: _enumByWire(
        SavedSearchMatchKind.values,
        json['match_kind'],
        (value) => value.wireValue,
        'match_kind',
      ),
      matchedField: _enumByWire(
        SavedSearchMatchedField.values,
        json['matched_field'],
        (value) => value.wireValue,
        'matched_field',
      ),
      matchedLocale: SavedDisplayLocale.fromWireValue(json['matched_locale']),
      alternatePublicDisplayValue: alternate as String?,
    );
  }

  final int matchRank;
  final SavedSearchMatchKind matchKind;
  final SavedSearchMatchedField matchedField;
  final SavedDisplayLocale matchedLocale;
  final String? alternatePublicDisplayValue;
}

final class SavedSearchItem extends SavedListItem {
  SavedSearchItem({
    required super.target,
    required super.relationship,
    required super.effectiveCollectionCount,
    required super.projection,
    required this.match,
  });

  factory SavedSearchItem.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'target',
        'relationship',
        'effective_collection_count',
        'projection',
        'match',
      },
    );
    final count = json['effective_collection_count'];
    if (count is! int) {
      throw const FormatException(
        'effective_collection_count must be an integer.',
      );
    }
    return SavedSearchItem(
      target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
      relationship: SavedActiveRelationship.fromJson(
        _requireObject(json['relationship'], 'relationship'),
      ),
      effectiveCollectionCount: count,
      projection: SavedCardProjection.fromJson(
        _requireObject(json['projection'], 'projection'),
      ),
      match: SavedSearchMatch.fromJson(_requireObject(json['match'], 'match')),
    );
  }

  final SavedSearchMatch match;
}

enum SavedQuotaResource {
  savedItems('SAVED_ITEMS'),
  savedCollections('SAVED_COLLECTIONS'),
  collectionMemberships('COLLECTION_MEMBERSHIPS'),
  ownerMemberships('OWNER_MEMBERSHIPS');

  const SavedQuotaResource(this.wireValue);
  final String wireValue;
}

final class SavedQuotaWarning {
  SavedQuotaWarning({
    required this.resource,
    required int limit,
    required int remaining,
  }) : limit = _requireBoundedInt(limit, 'limit', minimum: 1),
       remaining = _requireBoundedInt(remaining, 'remaining');

  factory SavedQuotaWarning.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, requiredKeys: const {'resource', 'limit', 'remaining'});
    final limit = json['limit'];
    final remaining = json['remaining'];
    if (limit is! int || remaining is! int) {
      throw const FormatException('Quota warning fields are malformed.');
    }
    if (remaining > limit) {
      throw const FormatException('Quota remaining cannot exceed its limit.');
    }
    return SavedQuotaWarning(
      resource: _enumByWire(
        SavedQuotaResource.values,
        json['resource'],
        (value) => value.wireValue,
        'resource',
      ),
      limit: limit,
      remaining: remaining,
    );
  }

  final SavedQuotaResource resource;
  final int limit;
  final int remaining;
}

final class SavedPage<T extends SavedListItem> {
  SavedPage({
    required Iterable<T> items,
    required this.nextCursor,
    required this.hasMore,
    this.quotaWarning,
    bool validateDateOrder = false,
  }) : items = List<T>.unmodifiable(items) {
    if (this.items.length > 100) {
      throw ArgumentError.value(this.items.length, 'items.length');
    }
    if ((nextCursor != null) != hasMore) {
      throw ArgumentError('nextCursor presence must match hasMore.');
    }
    if (nextCursor != null) {
      _requireText(nextCursor!, 'nextCursor', minimum: 1, maximum: 4096);
    }
    if (validateDateOrder) {
      for (var index = 1; index < this.items.length; index++) {
        if (this.items[index].relationship.savedAt.isAfter(
          this.items[index - 1].relationship.savedAt,
        )) {
          throw const FormatException(
            'Saved list page is not ordered by saved_at descending.',
          );
        }
      }
    }
  }

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  final SavedQuotaWarning? quotaWarning;
}

SavedPage<SavedListItem> parseSavedItemsPage(Map<String, dynamic> json) {
  _requireKeys(
    json,
    requiredKeys: const {'items', 'next_cursor', 'has_more'},
    optionalKeys: const {'quota_warning'},
  );
  final rawItems = json['items'];
  final nextCursor = json['next_cursor'];
  final hasMore = json['has_more'];
  if (rawItems is! List<dynamic> ||
      (nextCursor != null && nextCursor is! String) ||
      hasMore is! bool) {
    throw const FormatException('Saved page fields are malformed.');
  }
  return SavedPage<SavedListItem>(
    items: rawItems
        .map(
          (value) => SavedListItem.fromJson(_requireObject(value, 'items[]')),
        )
        .toList(growable: false),
    nextCursor: nextCursor as String?,
    hasMore: hasMore,
    quotaWarning: json.containsKey('quota_warning')
        ? SavedQuotaWarning.fromJson(
            _requireObject(json['quota_warning'], 'quota_warning'),
          )
        : null,
    validateDateOrder: true,
  );
}

SavedPage<SavedSearchItem> parseSavedSearchPage(Map<String, dynamic> json) {
  _requireKeys(
    json,
    requiredKeys: const {'items', 'next_cursor', 'has_more'},
    optionalKeys: const {'quota_warning'},
  );
  final rawItems = json['items'];
  final nextCursor = json['next_cursor'];
  final hasMore = json['has_more'];
  if (rawItems is! List<dynamic> ||
      (nextCursor != null && nextCursor is! String) ||
      hasMore is! bool) {
    throw const FormatException('Saved search page fields are malformed.');
  }
  return SavedPage<SavedSearchItem>(
    items: rawItems
        .map(
          (value) => SavedSearchItem.fromJson(_requireObject(value, 'items[]')),
        )
        .toList(growable: false),
    nextCursor: nextCursor as String?,
    hasMore: hasMore,
    quotaWarning: json.containsKey('quota_warning')
        ? SavedQuotaWarning.fromJson(
            _requireObject(json['quota_warning'], 'quota_warning'),
          )
        : null,
  );
}

final class SavedProductFlags {
  const SavedProductFlags({
    required this.savedItemsEnabled,
    required this.searchEnabled,
    required this.collectionsEnabled,
  });

  factory SavedProductFlags.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'saved_items_enabled',
        'search_enabled',
        'collections_enabled',
      },
    );
    final savedItems = json['saved_items_enabled'];
    final search = json['search_enabled'];
    final collections = json['collections_enabled'];
    if (savedItems is! bool || search is! bool || collections is! bool) {
      throw const FormatException('Saved product flags are malformed.');
    }
    return SavedProductFlags(
      savedItemsEnabled: savedItems,
      searchEnabled: search,
      collectionsEnabled: collections,
    );
  }

  final bool savedItemsEnabled;
  final bool searchEnabled;
  final bool collectionsEnabled;
}

final class SavedCapabilities {
  SavedCapabilities({
    required String capabilityRevision,
    required this.productFlags,
    required this.hasConfirmedSavedData,
    required Iterable<SavedEntityType> supportedEntityTypes,
    required this.effectiveLocale,
    this.quotaWarning,
  }) : capabilityRevision = _requireText(
         capabilityRevision,
         'capabilityRevision',
         minimum: 1,
         maximum: 128,
       ),
       supportedEntityTypes = Set<SavedEntityType>.unmodifiable(
         supportedEntityTypes,
       ) {
    if (this.supportedEntityTypes.length > 4) {
      throw ArgumentError.value(supportedEntityTypes, 'supportedEntityTypes');
    }
  }

  factory SavedCapabilities.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'capability_revision',
        'product_flags',
        'has_confirmed_saved_data',
        'supported_entity_types',
        'effective_locale',
      },
      optionalKeys: const {'quota_warning'},
    );
    final revision = json['capability_revision'];
    final hasData = json['has_confirmed_saved_data'];
    final rawTypes = json['supported_entity_types'];
    if (revision is! String || hasData is! bool || rawTypes is! List<dynamic>) {
      throw const FormatException('Saved capabilities fields are malformed.');
    }
    final types = rawTypes
        .map(SavedEntityType.fromWireValue)
        .toList(growable: false);
    if (types.toSet().length != types.length) {
      throw const FormatException('supported_entity_types must be unique.');
    }
    return SavedCapabilities(
      capabilityRevision: revision,
      productFlags: SavedProductFlags.fromJson(
        _requireObject(json['product_flags'], 'product_flags'),
      ),
      hasConfirmedSavedData: hasData,
      supportedEntityTypes: types,
      effectiveLocale: SavedDisplayLocale.fromWireValue(
        json['effective_locale'],
      ),
      quotaWarning: json.containsKey('quota_warning')
          ? SavedQuotaWarning.fromJson(
              _requireObject(json['quota_warning'], 'quota_warning'),
            )
          : null,
    );
  }

  final String capabilityRevision;
  final SavedProductFlags productFlags;
  final bool hasConfirmedSavedData;
  final Set<SavedEntityType> supportedEntityTypes;
  final SavedDisplayLocale effectiveLocale;
  final SavedQuotaWarning? quotaWarning;
}

final class SavedCollectionOption {
  SavedCollectionOption({
    required String collectionId,
    required String title,
    required int metadataVersion,
    required int lifecycleVersion,
  }) : collectionId = _requireUuid(collectionId, 'collectionId'),
       title = _requireText(title, 'title', minimum: 1, maximum: 80),
       metadataVersion = _requireVersion(metadataVersion, 'metadataVersion'),
       lifecycleVersion = _requireVersion(lifecycleVersion, 'lifecycleVersion');

  factory SavedCollectionOption.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'collection_id',
        'title',
        'metadata_version',
        'lifecycle_version',
      },
    );
    final id = json['collection_id'];
    final title = json['title'];
    final metadataVersion = json['metadata_version'];
    final lifecycleVersion = json['lifecycle_version'];
    if (id is! String ||
        title is! String ||
        metadataVersion is! int ||
        lifecycleVersion is! int) {
      throw const FormatException('Collection option fields are malformed.');
    }
    return SavedCollectionOption(
      collectionId: id,
      title: title,
      metadataVersion: metadataVersion,
      lifecycleVersion: lifecycleVersion,
    );
  }

  final String collectionId;
  final String title;
  final int metadataVersion;
  final int lifecycleVersion;
}

final class SavedTargetCollectionsSnapshot {
  SavedTargetCollectionsSnapshot({
    required int snapshotVersion,
    required this.target,
    required this.relationship,
    required int dependentMembershipVersion,
    required Iterable<String> effectiveCollectionIds,
    required Iterable<SavedCollectionOption> collectionOptions,
    this.quotaWarning,
  }) : snapshotVersion = _requireVersion(snapshotVersion, 'snapshotVersion'),
       dependentMembershipVersion = _requireVersion(
         dependentMembershipVersion,
         'dependentMembershipVersion',
       ),
       effectiveCollectionIds = _requireUniqueUuids(
         effectiveCollectionIds,
         'effectiveCollectionIds',
         maximum: 200,
       ),
       collectionOptions = List<SavedCollectionOption>.unmodifiable(
         collectionOptions,
       ) {
    if (this.collectionOptions.length > 200 ||
        this.collectionOptions
                .map((item) => item.collectionId)
                .toSet()
                .length !=
            this.collectionOptions.length) {
      throw ArgumentError.value(collectionOptions, 'collectionOptions');
    }
  }

  factory SavedTargetCollectionsSnapshot.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {
        'snapshot_version',
        'target',
        'relationship',
        'dependent_membership_version',
        'effective_collection_ids',
        'collection_options',
      },
      optionalKeys: const {'quota_warning'},
    );
    final snapshotVersion = json['snapshot_version'];
    final membershipVersion = json['dependent_membership_version'];
    final rawIds = json['effective_collection_ids'];
    final rawOptions = json['collection_options'];
    if (snapshotVersion is! int ||
        membershipVersion is! int ||
        rawIds is! List<dynamic> ||
        rawIds.any((value) => value is! String) ||
        rawOptions is! List<dynamic>) {
      throw const FormatException('Target collection snapshot is malformed.');
    }
    return SavedTargetCollectionsSnapshot(
      snapshotVersion: snapshotVersion,
      target: SavedTarget.fromJson(_requireObject(json['target'], 'target')),
      relationship: SavedRelationshipSnapshot.fromJson(
        _requireObject(json['relationship'], 'relationship'),
      ),
      dependentMembershipVersion: membershipVersion,
      effectiveCollectionIds: rawIds.cast<String>(),
      collectionOptions: rawOptions
          .map(
            (value) => SavedCollectionOption.fromJson(
              _requireObject(value, 'collection_options[]'),
            ),
          )
          .toList(growable: false),
      quotaWarning: json.containsKey('quota_warning')
          ? SavedQuotaWarning.fromJson(
              _requireObject(json['quota_warning'], 'quota_warning'),
            )
          : null,
    );
  }

  final int snapshotVersion;
  final SavedTarget target;
  final SavedRelationshipSnapshot relationship;
  final int dependentMembershipVersion;
  final List<String> effectiveCollectionIds;
  final List<SavedCollectionOption> collectionOptions;
  final SavedQuotaWarning? quotaWarning;

  Map<String, Object?> desiredSetJson({
    required Iterable<String> desiredCollectionIds,
    SavedNewCollection? newCollection,
  }) {
    final desiredIds = _requireUniqueUuids(
      desiredCollectionIds,
      'desiredCollectionIds',
      maximum: 200,
    );
    return <String, Object?>{
      'expected_relationship': switch (relationship) {
        AbsentRelationshipSnapshot() => const <String, Object?>{
          'state': 'EXPECTED_ABSENT',
        },
        ExistingRelationshipSnapshot(
          :final state,
          :final generation,
          :final version,
        ) =>
          <String, Object?>{
            'state': switch (state) {
              SavedRelationshipState.active => 'EXPECTED_ACTIVE',
              SavedRelationshipState.removed => 'EXPECTED_REMOVED',
              SavedRelationshipState.absent => throw StateError(
                'Existing relationship cannot be absent.',
              ),
            },
            'generation': generation,
            'version': version,
          },
      },
      'expected_dependent_membership_version': dependentMembershipVersion,
      'desired_collection_ids': desiredIds,
      if (newCollection != null) 'new_collection': newCollection.toJson(),
    };
  }
}

final class SavedNewCollection {
  SavedNewCollection({required String clientCreationId, required String title})
    : clientCreationId = _requireUuidV4(clientCreationId, 'clientCreationId'),
      title = _requireText(title, 'title', minimum: 1, maximum: 80);

  final String clientCreationId;
  final String title;

  Map<String, Object?> toJson() => <String, Object?>{
    'client_creation_id': clientCreationId,
    'title': title,
  };
}

final class SavedCollectionsList {
  SavedCollectionsList({
    required Iterable<SavedCollectionRecord> collections,
    this.quotaWarning,
  }) : collections = List<SavedCollectionRecord>.unmodifiable(collections) {
    if (this.collections.length > 200) {
      throw ArgumentError.value(this.collections.length, 'collections.length');
    }
    for (var index = 1; index < this.collections.length; index++) {
      final previous = this.collections[index - 1];
      final current = this.collections[index];
      if (current.organizedAt.isAfter(previous.organizedAt) ||
          (current.organizedAt == previous.organizedAt &&
              current.collectionId.compareTo(previous.collectionId) > 0)) {
        throw const FormatException(
          'Collections are not ordered by organized_at/id descending.',
        );
      }
    }
  }

  factory SavedCollectionsList.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {'collections'},
      optionalKeys: const {'quota_warning'},
    );
    final rawCollections = json['collections'];
    if (rawCollections is! List<dynamic>) {
      throw const FormatException('collections must be an array.');
    }
    return SavedCollectionsList(
      collections: rawCollections
          .map(
            (value) => SavedCollectionRecord.fromJson(
              _requireObject(value, 'collections[]'),
            ),
          )
          .toList(growable: false),
      quotaWarning: json.containsKey('quota_warning')
          ? SavedQuotaWarning.fromJson(
              _requireObject(json['quota_warning'], 'quota_warning'),
            )
          : null,
    );
  }

  final List<SavedCollectionRecord> collections;
  final SavedQuotaWarning? quotaWarning;
}

final class SavedCollectionDetail {
  const SavedCollectionDetail({required this.collection, this.quotaWarning});

  factory SavedCollectionDetail.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      requiredKeys: const {'collection'},
      optionalKeys: const {'quota_warning'},
    );
    return SavedCollectionDetail(
      collection: SavedCollectionRecord.fromJson(
        _requireObject(json['collection'], 'collection'),
      ),
      quotaWarning: json.containsKey('quota_warning')
          ? SavedQuotaWarning.fromJson(
              _requireObject(json['quota_warning'], 'quota_warning'),
            )
          : null,
    );
  }

  final SavedCollectionRecord collection;
  final SavedQuotaWarning? quotaWarning;
}

Map<String, dynamic> requireSavedJsonObject(Object? value, String fieldName) {
  return _requireObject(value, fieldName);
}

void _requireKeys(
  Map<String, dynamic> json, {
  required Set<String> requiredKeys,
  Set<String> optionalKeys = const {},
}) {
  final allowed = <String>{...requiredKeys, ...optionalKeys};
  final missing = requiredKeys.difference(json.keys.toSet());
  final extra = json.keys.toSet().difference(allowed);
  if (missing.isNotEmpty || extra.isNotEmpty) {
    throw FormatException(
      'Saved object keys are invalid. Missing: $missing; extra: $extra.',
    );
  }
}

Map<String, dynamic> _requireObject(Object? value, String fieldName) {
  if (value is! Map<dynamic, dynamic> ||
      value.keys.any((key) => key is! String)) {
    throw FormatException('$fieldName must be an object with string keys.');
  }
  return Map<String, dynamic>.from(value);
}

String _requireText(
  String value,
  String fieldName, {
  int minimum = 0,
  required int maximum,
}) {
  if (value.runes.length < minimum || value.runes.length > maximum) {
    throw ArgumentError.value(value, fieldName, 'Invalid code-point length.');
  }
  if (value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'Control characters are forbidden.',
    );
  }
  return value;
}

int _requireVersion(int value, String fieldName, {bool positive = false}) {
  if (value < (positive ? 1 : 0)) {
    throw ArgumentError.value(value, fieldName, 'Invalid version.');
  }
  return value;
}

int _requireBoundedInt(
  int value,
  String fieldName, {
  int minimum = 0,
  int? maximum,
}) {
  if (value < minimum || (maximum != null && value > maximum)) {
    throw ArgumentError.value(value, fieldName, 'Outside allowed bounds.');
  }
  return value;
}

DateTime _parseTimestamp(Object? value, String fieldName) {
  if (value is! String || !value.contains(RegExp(r'(Z|[+-]\d\d:\d\d)$'))) {
    throw FormatException('$fieldName must be an offset RFC 3339 timestamp.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$fieldName must be an RFC 3339 timestamp.');
  }
  return parsed.toUtc();
}

DateTime _requireOffsetTimestamp(DateTime value, String fieldName) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, fieldName, 'Must be normalized to UTC.');
  }
  return value;
}

Uri? _requireHttpUriOrNull(Uri? value, String fieldName) {
  if (value == null) return null;
  if (value.toString().length > 2048 ||
      !value.isAbsolute ||
      (value.scheme != 'https' && value.scheme != 'http') ||
      value.host.isEmpty ||
      value.hasFragment ||
      value.userInfo.isNotEmpty) {
    throw ArgumentError.value(value, fieldName, 'Must be a safe HTTP(S) URI.');
  }
  return value;
}

final RegExp _canonicalDetailRoutePattern = RegExp(
  r'^(?:/(?:places|activities|posts)/[^/?#%\\]+|/users/[^/?#%\\]+/profile)$',
);

String _requireCanonicalDetailRoute(String value) {
  _requireText(value, 'canonicalDetailRoute', minimum: 1, maximum: 256);
  if (value.trim() != value || !_canonicalDetailRoutePattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'canonicalDetailRoute',
      'Must be an exact first-party Saved detail route.',
    );
  }
  return value;
}

String _parseCanonicalDetailRoute(String value) {
  try {
    return _requireCanonicalDetailRoute(value);
  } on ArgumentError {
    throw const FormatException('canonical_detail_route is malformed.');
  }
}

String _requireUuid(String value, String fieldName) {
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (!uuid.hasMatch(value)) {
    throw ArgumentError.value(value, fieldName, 'Must be a UUID.');
  }
  return value;
}

String _requireUuidV4(String value, String fieldName) {
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  if (!uuid.hasMatch(value)) {
    throw ArgumentError.value(value, fieldName, 'Must be a UUIDv4.');
  }
  return value;
}

List<String> _requireUniqueUuids(
  Iterable<String> values,
  String fieldName, {
  required int maximum,
}) {
  final result = values.map((value) => _requireUuid(value, fieldName)).toList();
  if (result.length > maximum || result.toSet().length != result.length) {
    throw ArgumentError.value(values, fieldName, 'Must be bounded and unique.');
  }
  return List<String>.unmodifiable(result);
}

T _enumByWire<T>(
  Iterable<T> values,
  Object? raw,
  String Function(T value) wireValue,
  String fieldName,
) {
  if (raw is! String) {
    throw FormatException('$fieldName must be a string.');
  }
  for (final value in values) {
    if (wireValue(value) == raw) return value;
  }
  throw FormatException('Unsupported $fieldName: $raw.');
}
