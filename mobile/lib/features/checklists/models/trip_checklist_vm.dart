enum ChecklistReadinessStatus {
  notReady,
  atRisk,
  onTrack,
  almostReady,
  ready,
  readyWithWarnings,
  unknown,
}

enum ChecklistSourceConfidence { high, medium, low, unknown }

enum CarryPolicy {
  allowed,
  allowedWithConditions,
  prohibited,
  checkAuthority,
  unknown,
}

enum ChecklistItemFeedbackType { helpful, notHelpful, addNextTime, unknown }

class TripChecklistVm {
  const TripChecklistVm({
    required this.instanceId,
    required this.userId,
    required this.tripId,
    required this.items,
    required this.readiness,
    required this.trustNotice,
    required this.generatedAt,
    this.customItems = const [],
    this.personalProgress = PersonalChecklistProgressVm.empty,
    this.updatedAt,
    this.seasonalProfile,
  });

  final String instanceId;
  final String userId;
  final String tripId;
  final List<ChecklistItemVm> items;
  final List<CustomChecklistItemVm> customItems;
  final ChecklistReadinessVm readiness;
  final PersonalChecklistProgressVm personalProgress;
  final ChecklistTrustNoticeVm trustNotice;
  final SeasonalProfileVm? seasonalProfile;
  final DateTime? generatedAt;
  final DateTime? updatedAt;

  factory TripChecklistVm.fromJson(Map<String, dynamic> json) {
    return TripChecklistVm(
      instanceId: json['instanceId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
      items: _maps(json['items']).map(ChecklistItemVm.fromJson).toList(),
      customItems: _maps(
        json['customItems'],
      ).map(CustomChecklistItemVm.fromJson).toList(),
      readiness: ChecklistReadinessVm.fromJson(_map(json['readiness'])),
      personalProgress: PersonalChecklistProgressVm.fromJson(
        _map(json['personalProgress']),
      ),
      trustNotice: ChecklistTrustNoticeVm.fromJson(_map(json['trustNotice'])),
      seasonalProfile: json['seasonalProfile'] is Map<String, dynamic>
          ? SeasonalProfileVm.fromJson(_map(json['seasonalProfile']))
          : null,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'instanceId': instanceId,
      'userId': userId,
      'tripId': tripId,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'customItems': customItems
          .map((item) => item.toJson())
          .toList(growable: false),
      'readiness': readiness.toJson(),
      'personalProgress': personalProgress.toJson(),
      'trustNotice': trustNotice.toJson(),
      if (seasonalProfile != null) 'seasonalProfile': seasonalProfile!.toJson(),
      if (generatedAt != null)
        'generatedAt': generatedAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }
}

class ChecklistReadinessVm {
  const ChecklistReadinessVm({
    required this.score,
    required this.status,
    required this.blockers,
  });

  final int score;
  final ChecklistReadinessStatus status;
  final List<ChecklistReadinessBlockerVm> blockers;

  factory ChecklistReadinessVm.fromJson(Map<String, dynamic> json) {
    return ChecklistReadinessVm(
      score: (json['score'] as num?)?.toInt().clamp(0, 100) ?? 0,
      status: _readinessStatus(json['status']?.toString()),
      blockers: _maps(
        json['blockers'],
      ).map(ChecklistReadinessBlockerVm.fromJson).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'score': score,
      'status': _readinessStatusValue(status),
      'blockers': blockers
          .map((blocker) => blocker.toJson())
          .toList(growable: false),
    };
  }
}

class ChecklistReadinessBlockerVm {
  const ChecklistReadinessBlockerVm({
    required this.itemId,
    required this.priority,
    required this.reason,
  });

  final String itemId;
  final String priority;
  final String reason;

  factory ChecklistReadinessBlockerVm.fromJson(Map<String, dynamic> json) {
    final rawReason = json['reason'];
    return ChecklistReadinessBlockerVm(
      itemId: json['itemId']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      reason: rawReason is String ? rawReason : _localizedText(rawReason),
    );
  }

  Map<String, Object?> toJson() {
    return {'itemId': itemId, 'priority': priority, 'reason': reason};
  }
}

class ChecklistItemVm {
  const ChecklistItemVm({
    required this.id,
    required this.category,
    required this.priority,
    required this.status,
    required this.assignedUserId,
    required this.title,
    required this.reason,
    required this.trustLevel,
    required this.source,
    required this.requiresUserConfirmation,
    this.deadlineAt,
  });

  final String id;
  final String category;
  final String priority;
  final String status;
  final String assignedUserId;
  final String title;
  final String reason;
  final String trustLevel;
  final ChecklistSourceVm source;
  final bool requiresUserConfirmation;
  final DateTime? deadlineAt;

  factory ChecklistItemVm.fromJson(Map<String, dynamic> json) {
    return ChecklistItemVm(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      assignedUserId: json['assignedUserId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      trustLevel: json['trustLevel']?.toString() ?? '',
      source: ChecklistSourceVm.fromJson(_map(json['source'])),
      requiresUserConfirmation: json['requiresUserConfirmation'] == true,
      deadlineAt: DateTime.tryParse(json['deadlineAt']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category,
      'priority': priority,
      'status': status,
      if (assignedUserId.isNotEmpty) 'assignedUserId': assignedUserId,
      'title': title,
      'reason': reason,
      'trustLevel': trustLevel,
      'source': source.toJson(),
      'requiresUserConfirmation': requiresUserConfirmation,
      if (deadlineAt != null)
        'deadlineAt': deadlineAt!.toUtc().toIso8601String(),
    };
  }

  bool get isCritical => priority == 'critical';

  bool get isDone => status == 'done';
}

class CustomChecklistItemVm {
  const CustomChecklistItemVm({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    required this.priority,
    required this.status,
    required this.assignedUserId,
    required this.reuseInFuture,
    required this.personalTemplateId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String note;
  final String category;
  final String priority;
  final String status;
  final String assignedUserId;
  final bool reuseInFuture;
  final String personalTemplateId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomChecklistItemVm.fromJson(Map<String, dynamic> json) {
    return CustomChecklistItemVm(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      category: json['category']?.toString() ?? 'custom',
      priority: json['priority']?.toString() ?? 'recommended',
      status: json['status']?.toString() ?? 'open',
      assignedUserId: json['assignedUserId']?.toString() ?? '',
      reuseInFuture: json['reuseInFuture'] == true,
      personalTemplateId: json['personalTemplateId']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'category': category,
      'priority': priority,
      'status': status,
      if (assignedUserId.isNotEmpty) 'assignedUserId': assignedUserId,
      'reuseInFuture': reuseInFuture,
      if (personalTemplateId.isNotEmpty)
        'personalTemplateId': personalTemplateId,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

  bool get isDone => status == 'done';
}

class PersonalChecklistProgressVm {
  const PersonalChecklistProgressVm({
    required this.total,
    required this.done,
    required this.percent,
  });

  static const empty = PersonalChecklistProgressVm(
    total: 0,
    done: 0,
    percent: 0,
  );

  final int total;
  final int done;
  final int percent;

  factory PersonalChecklistProgressVm.fromJson(Map<String, dynamic> json) {
    return PersonalChecklistProgressVm(
      total: (json['total'] as num?)?.toInt() ?? 0,
      done: (json['done'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toInt().clamp(0, 100) ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return {'total': total, 'done': done, 'percent': percent};
  }
}

class ChecklistSourceVm {
  const ChecklistSourceVm({
    required this.name,
    required this.url,
    required this.type,
    required this.confidence,
  });

  final String name;
  final String url;
  final String type;
  final ChecklistSourceConfidence confidence;

  factory ChecklistSourceVm.fromJson(Map<String, dynamic> json) {
    return ChecklistSourceVm(
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      confidence: _sourceConfidence(json['confidence']?.toString()),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'confidence': _sourceConfidenceValue(confidence),
    };
  }
}

class ChecklistTrustNoticeVm {
  const ChecklistTrustNoticeVm({
    required this.code,
    required this.title,
    required this.message,
  });

  final String code;
  final String title;
  final String message;

  factory ChecklistTrustNoticeVm.fromJson(Map<String, dynamic> json) {
    return ChecklistTrustNoticeVm(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {'code': code, 'title': title, 'message': message};
  }
}

class SeasonalProfileVm {
  const SeasonalProfileVm({
    required this.month,
    required this.temperatureBand,
    required this.precipitationBand,
    required this.skyBand,
    required this.riskTags,
    required this.packingImplications,
    required this.source,
  });

  final int month;
  final String temperatureBand;
  final String precipitationBand;
  final String skyBand;
  final List<String> riskTags;
  final List<String> packingImplications;
  final ChecklistSourceVm source;

  factory SeasonalProfileVm.fromJson(Map<String, dynamic> json) {
    return SeasonalProfileVm(
      month: (json['month'] as num?)?.toInt() ?? 0,
      temperatureBand: json['temperatureBand']?.toString() ?? '',
      precipitationBand: json['precipitationBand']?.toString() ?? '',
      skyBand: json['skyBand']?.toString() ?? '',
      riskTags: _strings(json['riskTags']),
      packingImplications: _strings(json['packingImplications']),
      source: ChecklistSourceVm.fromJson(_map(json['source'])),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'month': month,
      'temperatureBand': temperatureBand,
      'precipitationBand': precipitationBand,
      'skyBand': skyBand,
      'riskTags': riskTags,
      'packingImplications': packingImplications,
      'source': source.toJson(),
    };
  }
}

class CarryItemPolicyListVm {
  const CarryItemPolicyListVm({required this.items});

  final List<CarryItemPolicyVm> items;

  factory CarryItemPolicyListVm.fromJson(Map<String, dynamic> json) {
    return CarryItemPolicyListVm(
      items: _maps(json['items']).map(CarryItemPolicyVm.fromJson).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class CarryItemPolicyVm {
  const CarryItemPolicyVm({
    required this.itemSlug,
    required this.carryOn,
    required this.checkedBaggage,
    required this.requiresAirlineCheck,
    required this.conditionSummary,
    required this.source,
  });

  final String itemSlug;
  final CarryPolicy carryOn;
  final CarryPolicy checkedBaggage;
  final bool requiresAirlineCheck;
  final String conditionSummary;
  final ChecklistSourceVm source;

  factory CarryItemPolicyVm.fromJson(Map<String, dynamic> json) {
    return CarryItemPolicyVm(
      itemSlug: json['itemSlug']?.toString() ?? '',
      carryOn: _carryPolicy(json['carryOn']?.toString()),
      checkedBaggage: _carryPolicy(json['checkedBaggage']?.toString()),
      requiresAirlineCheck: json['requiresAirlineCheck'] == true,
      conditionSummary: json['conditionSummary']?.toString() ?? '',
      source: ChecklistSourceVm.fromJson(_map(json['source'])),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'itemSlug': itemSlug,
      'carryOn': _carryPolicyValue(carryOn),
      'checkedBaggage': _carryPolicyValue(checkedBaggage),
      'requiresAirlineCheck': requiresAirlineCheck,
      'conditionSummary': conditionSummary,
      'source': source.toJson(),
    };
  }
}

class ChecklistItemFeedbackVm {
  const ChecklistItemFeedbackVm({
    required this.id,
    required this.checklistInstanceId,
    required this.userId,
    required this.tripId,
    required this.itemId,
    required this.type,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String checklistInstanceId;
  final String userId;
  final String tripId;
  final String itemId;
  final ChecklistItemFeedbackType type;
  final String comment;
  final DateTime? createdAt;

  factory ChecklistItemFeedbackVm.fromJson(Map<String, dynamic> json) {
    return ChecklistItemFeedbackVm(
      id: json['id']?.toString() ?? '',
      checklistInstanceId: json['checklistInstanceId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      type: checklistItemFeedbackType(json['type']?.toString()),
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'checklistInstanceId': checklistInstanceId,
      'userId': userId,
      'tripId': tripId,
      'itemId': itemId,
      'type': checklistItemFeedbackTypeValue(type),
      'comment': comment,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
    };
  }
}

class ChecklistReminderListVm {
  const ChecklistReminderListVm({required this.items});

  final List<ChecklistReminderVm> items;

  factory ChecklistReminderListVm.fromJson(Map<String, dynamic> json) {
    return ChecklistReminderListVm(
      items: _maps(json['items']).map(ChecklistReminderVm.fromJson).toList(),
    );
  }
}

class ChecklistReminderVm {
  const ChecklistReminderVm({
    required this.id,
    required this.offsetDays,
    required this.dueAt,
    required this.status,
    required this.title,
    required this.message,
  });

  final String id;
  final int offsetDays;
  final DateTime? dueAt;
  final String status;
  final String title;
  final String message;

  factory ChecklistReminderVm.fromJson(Map<String, dynamic> json) {
    return ChecklistReminderVm(
      id: json['id']?.toString() ?? '',
      offsetDays: (json['offsetDays'] as num?)?.toInt() ?? 0,
      dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

ChecklistReadinessStatus _readinessStatus(String? value) {
  switch (value) {
    case 'not_ready':
      return ChecklistReadinessStatus.notReady;
    case 'at_risk':
      return ChecklistReadinessStatus.atRisk;
    case 'on_track':
      return ChecklistReadinessStatus.onTrack;
    case 'almost_ready':
      return ChecklistReadinessStatus.almostReady;
    case 'ready':
      return ChecklistReadinessStatus.ready;
    case 'ready_with_warnings':
      return ChecklistReadinessStatus.readyWithWarnings;
    default:
      return ChecklistReadinessStatus.unknown;
  }
}

String _readinessStatusValue(ChecklistReadinessStatus status) {
  switch (status) {
    case ChecklistReadinessStatus.notReady:
      return 'not_ready';
    case ChecklistReadinessStatus.atRisk:
      return 'at_risk';
    case ChecklistReadinessStatus.onTrack:
      return 'on_track';
    case ChecklistReadinessStatus.almostReady:
      return 'almost_ready';
    case ChecklistReadinessStatus.ready:
      return 'ready';
    case ChecklistReadinessStatus.readyWithWarnings:
      return 'ready_with_warnings';
    case ChecklistReadinessStatus.unknown:
      return 'unknown';
  }
}

ChecklistSourceConfidence _sourceConfidence(String? value) {
  switch (value) {
    case 'high':
      return ChecklistSourceConfidence.high;
    case 'medium':
      return ChecklistSourceConfidence.medium;
    case 'low':
      return ChecklistSourceConfidence.low;
    default:
      return ChecklistSourceConfidence.unknown;
  }
}

String _sourceConfidenceValue(ChecklistSourceConfidence confidence) {
  switch (confidence) {
    case ChecklistSourceConfidence.high:
      return 'high';
    case ChecklistSourceConfidence.medium:
      return 'medium';
    case ChecklistSourceConfidence.low:
      return 'low';
    case ChecklistSourceConfidence.unknown:
      return 'unknown';
  }
}

CarryPolicy _carryPolicy(String? value) {
  switch (value) {
    case 'allowed':
      return CarryPolicy.allowed;
    case 'allowed_with_conditions':
      return CarryPolicy.allowedWithConditions;
    case 'prohibited':
      return CarryPolicy.prohibited;
    case 'check_authority':
      return CarryPolicy.checkAuthority;
    default:
      return CarryPolicy.unknown;
  }
}

String _carryPolicyValue(CarryPolicy policy) {
  switch (policy) {
    case CarryPolicy.allowed:
      return 'allowed';
    case CarryPolicy.allowedWithConditions:
      return 'allowed_with_conditions';
    case CarryPolicy.prohibited:
      return 'prohibited';
    case CarryPolicy.checkAuthority:
      return 'check_authority';
    case CarryPolicy.unknown:
      return 'unknown';
  }
}

ChecklistItemFeedbackType checklistItemFeedbackType(String? value) {
  switch (value) {
    case 'helpful':
      return ChecklistItemFeedbackType.helpful;
    case 'not_helpful':
      return ChecklistItemFeedbackType.notHelpful;
    case 'add_next_time':
      return ChecklistItemFeedbackType.addNextTime;
    default:
      return ChecklistItemFeedbackType.unknown;
  }
}

String checklistItemFeedbackTypeValue(ChecklistItemFeedbackType type) {
  switch (type) {
    case ChecklistItemFeedbackType.helpful:
      return 'helpful';
    case ChecklistItemFeedbackType.notHelpful:
      return 'not_helpful';
    case ChecklistItemFeedbackType.addNextTime:
      return 'add_next_time';
    case ChecklistItemFeedbackType.unknown:
      return 'unknown';
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}

List<Map<String, dynamic>> _maps(Object? value) {
  return value is List<dynamic>
      ? value.whereType<Map<String, dynamic>>().toList()
      : const <Map<String, dynamic>>[];
}

List<String> _strings(Object? value) {
  return value is List<dynamic>
      ? value.map((item) => item.toString()).toList()
      : const <String>[];
}

String _localizedText(Object? value) {
  if (value is Map<String, dynamic>) {
    return (value['ru'] ?? value['en'] ?? value['kk'] ?? '').toString();
  }
  return value?.toString() ?? '';
}
