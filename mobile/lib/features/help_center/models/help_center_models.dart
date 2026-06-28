enum HelpCenterSurface {
  helpCenter('help_center'),
  places('places'),
  activityDetails('activity_details'),
  excursionDetails('excursion_details'),
  placeDetails('place_details'),
  currencyConverter('currency_converter');

  const HelpCenterSurface(this.wireValue);

  final String wireValue;
}

enum HelpArticleActionType {
  openChat('open_chat'),
  contactSupport('contact_support'),
  openRoute('open_route'),
  unknown('unknown');

  const HelpArticleActionType(this.wireValue);

  final String wireValue;

  static HelpArticleActionType fromWireValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return HelpArticleActionType.values.firstWhere(
      (type) => type.wireValue == normalized,
      orElse: () => HelpArticleActionType.unknown,
    );
  }
}

enum SupportTicketCategory {
  account('account'),
  auth('auth'),
  safety('safety'),
  activities('activities'),
  excursions('excursions'),
  guides('guides'),
  places('places'),
  payments('payments'),
  refunds('refunds'),
  currency('currency'),
  technical('technical'),
  rules('rules');

  const SupportTicketCategory(this.wireValue);

  final String wireValue;

  static SupportTicketCategory fromWireValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return SupportTicketCategory.values.firstWhere(
      (category) => category.wireValue == normalized,
      orElse: () => SupportTicketCategory.technical,
    );
  }
}

class SupportChatOpenIntent {
  const SupportChatOpenIntent({
    required this.category,
    required this.source,
    required this.intent,
    this.context = const {},
  });

  final SupportTicketCategory category;
  final String source;
  final String intent;
  final Map<String, String> context;
}

class HelpArticleActionVm {
  const HelpArticleActionVm({
    required this.type,
    required this.target,
    this.label,
  });

  final HelpArticleActionType type;
  final String target;
  final String? label;

  factory HelpArticleActionVm.fromJson(Map<String, dynamic> json) {
    return HelpArticleActionVm(
      type: HelpArticleActionType.fromWireValue(
        _stringValue(json['type'] ?? json['Type']),
      ),
      target: _stringValue(json['target'] ?? json['Target']) ?? '',
      label: _blankToNull(_stringValue(json['label'] ?? json['Label'])),
    );
  }
}

class HelpArticleVm {
  const HelpArticleVm({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortAnswer,
    required this.body,
    required this.actions,
    required this.relatedArticleIds,
    required this.tags,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String shortAnswer;
  final String body;
  final List<HelpArticleActionVm> actions;
  final List<String> relatedArticleIds;
  final List<String> tags;
  final DateTime? updatedAt;

  factory HelpArticleVm.fromJson(Map<String, dynamic> json) {
    return HelpArticleVm(
      id: _stringValue(json['id']) ?? '',
      slug: _stringValue(json['slug']) ?? '',
      title: _stringValue(json['title']) ?? '',
      shortAnswer: _stringValue(json['shortAnswer']) ?? '',
      body: _stringValue(json['body']) ?? '',
      actions: _mapList(
        json['actions'],
      ).map(HelpArticleActionVm.fromJson).toList(growable: false),
      relatedArticleIds: _stringList(json['relatedArticleIds']),
      tags: _stringList(json['tags']),
      updatedAt: DateTime.tryParse(_stringValue(json['updatedAt']) ?? ''),
    );
  }
}

class HelpArticlePageVm {
  const HelpArticlePageVm({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
    this.nextOffset,
  });

  final List<HelpArticleVm> items;
  final int total;
  final int limit;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory HelpArticlePageVm.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return HelpArticlePageVm(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(HelpArticleVm.fromJson)
          .where((article) => article.id.trim().isNotEmpty)
          .toList(growable: false),
      total: _intValue(json['total']),
      limit: _intValue(json['limit']),
      offset: _intValue(json['offset']),
      nextOffset: json.containsKey('nextOffset')
          ? _intValue(json['nextOffset'])
          : null,
      hasMore: _boolValue(json['hasMore']),
    );
  }
}

class HelpCategoryVm {
  const HelpCategoryVm({
    required this.id,
    required this.slug,
    required this.title,
    required this.sortOrder,
    required this.articleCount,
  });

  final String id;
  final String slug;
  final String title;
  final int sortOrder;
  final int articleCount;

  factory HelpCategoryVm.fromJson(Map<String, dynamic> json) {
    return HelpCategoryVm(
      id: _stringValue(json['id']) ?? '',
      slug: _stringValue(json['slug']) ?? '',
      title: _stringValue(json['title']) ?? '',
      sortOrder: _intValue(json['sortOrder']),
      articleCount: _intValue(json['articleCount']),
    );
  }
}

class SupportTicketVm {
  const SupportTicketVm({
    required this.id,
    required this.status,
    required this.category,
    required this.priority,
    required this.context,
    this.conversationId = '',
    this.source = '',
    this.locale = '',
    this.assigneeId = '',
    this.firstResponseAt,
    this.resolvedAt,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String status;
  final SupportTicketCategory category;
  final String priority;
  final String source;
  final String locale;
  final String assigneeId;
  final Map<String, String> context;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupportTicketVm.fromJson(Map<String, dynamic> json) {
    return SupportTicketVm(
      id: _stringValue(json['id']) ?? '',
      conversationId: _stringValue(json['conversationId']) ?? '',
      status: _stringValue(json['status']) ?? '',
      category: SupportTicketCategory.fromWireValue(
        _stringValue(json['category']),
      ),
      priority: _stringValue(json['priority']) ?? '',
      source: _stringValue(json['source']) ?? '',
      locale: _stringValue(json['locale']) ?? '',
      assigneeId: _stringValue(json['assigneeId']) ?? '',
      context: _stringMap(json['context']),
      firstResponseAt: _dateValue(json['firstResponseAt']),
      resolvedAt: _dateValue(json['resolvedAt']),
      lastMessageAt: _dateValue(json['lastMessageAt']),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
    );
  }
}

class SupportTicketEventVm {
  const SupportTicketEventVm({
    required this.ticketId,
    required this.actorId,
    required this.actorType,
    required this.eventType,
    required this.payload,
    this.createdAt,
  });

  final String ticketId;
  final String actorId;
  final String actorType;
  final String eventType;
  final Map<String, String> payload;
  final DateTime? createdAt;

  factory SupportTicketEventVm.fromJson(Map<String, dynamic> json) {
    return SupportTicketEventVm(
      ticketId: _stringValue(json['ticketId']) ?? '',
      actorId: _stringValue(json['actorId']) ?? '',
      actorType: _stringValue(json['actorType']) ?? '',
      eventType: _stringValue(json['eventType']) ?? '',
      payload: _stringMap(json['payload']),
      createdAt: _dateValue(json['createdAt']),
    );
  }
}

class SupportTicketDetailVm {
  const SupportTicketDetailVm({required this.ticket, required this.events});

  final SupportTicketVm ticket;
  final List<SupportTicketEventVm> events;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List<dynamic>) return const [];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List<dynamic>) return const [];
  return value
      .map(_stringValue)
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map<String, dynamic>) return const {};
  return value.map((key, item) => MapEntry(key, _stringValue(item) ?? ''))
    ..removeWhere((key, item) => key.trim().isEmpty || item.trim().isEmpty);
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_stringValue(value)?.trim() ?? '') ?? 0;
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  final normalized = _stringValue(value)?.trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime? _dateValue(Object? value) {
  final raw = _stringValue(value);
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
