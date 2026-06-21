import 'package:dio/dio.dart';

import '../../features/checklists/models/trip_checklist_vm.dart';
import 'api_client.dart';

class ChecklistApi {
  ChecklistApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TripChecklistVm> previewTripChecklist(
    TripChecklistPreviewRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/checklists/trip-preview',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> getOrCreateTripChecklist(
    TripChecklistPreviewRequest request,
  ) async {
    final response = await _apiClient.dio.post(
      '/checklists/trips',
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<List<TripChecklistSummaryVm>> listTripChecklists({
    String locale = 'ru',
    int limit = 50,
  }) async {
    final normalizedLimit = limit <= 0 ? 50 : limit.clamp(1, 100);
    final response = await _apiClient.dio.get(
      '/checklists/trips',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
        'limit': normalizedLimit.toString(),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (item) =>
              TripChecklistSummaryVm.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.tripId.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<TripChecklistVm> updateChecklistItemStatus({
    required String tripId,
    required String itemId,
    required String status,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.patch(
      '/checklists/trips/$encodedTripId/items/$encodedItemId',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: {'status': status.trim()},
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> setChecklistItemAssignment({
    required String tripId,
    required String itemId,
    required bool assignToMe,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.patch(
      '/checklists/trips/$encodedTripId/items/$encodedItemId/assignment',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: {'assignToMe': assignToMe},
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> createCustomChecklistItem({
    required String tripId,
    required CustomChecklistItemRequest request,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final response = await _apiClient.dio.post(
      '/checklists/trips/$encodedTripId/custom-items',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> updateCustomChecklistItem({
    required String tripId,
    required String itemId,
    required CustomChecklistItemRequest request,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.patch(
      '/checklists/trips/$encodedTripId/custom-items/$encodedItemId',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: request.toJson(),
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> updateCustomChecklistItemStatus({
    required String tripId,
    required String itemId,
    required String status,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.patch(
      '/checklists/trips/$encodedTripId/custom-items/$encodedItemId/status',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: {'status': status.trim()},
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<TripChecklistVm> deleteCustomChecklistItem({
    required String tripId,
    required String itemId,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.delete(
      '/checklists/trips/$encodedTripId/custom-items/$encodedItemId',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return TripChecklistVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<ChecklistReminderListVm> listTripChecklistReminders({
    required String tripId,
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final response = await _apiClient.dio.get(
      '/checklists/trips/$encodedTripId/reminders',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return ChecklistReminderListVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<ChecklistItemFeedbackVm> submitChecklistItemFeedback({
    required String tripId,
    required String itemId,
    required ChecklistItemFeedbackType type,
    String comment = '',
    String locale = 'ru',
  }) async {
    final encodedTripId = Uri.encodeComponent(tripId.trim());
    final encodedItemId = Uri.encodeComponent(itemId.trim());
    final response = await _apiClient.dio.post(
      '/checklists/trips/$encodedTripId/items/$encodedItemId/feedback',
      queryParameters: {
        'lang': locale.trim().isNotEmpty ? locale.trim() : 'ru',
      },
      data: {
        'type': checklistItemFeedbackTypeValue(type),
        'comment': comment.trim(),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );

    final data = response.data;
    return ChecklistItemFeedbackVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<CarryItemPolicyListVm> searchCarryItems({
    required String query,
    String transportMode = 'flight',
    String locale = 'ru',
  }) async {
    final response = await _apiClient.dio.get(
      '/checklists/carry-items/search',
      queryParameters: {
        'q': query.trim(),
        'transportMode': transportMode.trim(),
        'lang': locale.trim(),
      },
      options: Options(extra: const {'requiresAuth': false}),
    );

    final data = response.data;
    return CarryItemPolicyListVm.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }
}

class TripChecklistPreviewRequest {
  const TripChecklistPreviewRequest({
    required this.tripId,
    required this.destination,
    required this.startAt,
    required this.endAt,
    this.userId,
    this.transportModes = const [],
    this.activitySlugs = const [],
    this.hasChildren = false,
    this.preferredLanguage = 'ru',
  });

  final String? userId;
  final String tripId;
  final TripChecklistDestinationRequest destination;
  final DateTime startAt;
  final DateTime endAt;
  final List<String> transportModes;
  final List<String> activitySlugs;
  final bool hasChildren;
  final String preferredLanguage;

  Map<String, Object?> toJson() {
    return {
      if ((userId ?? '').trim().isNotEmpty) 'userId': userId!.trim(),
      'tripId': tripId.trim(),
      'destination': destination.toJson(),
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'transportModes': transportModes
          .map((mode) => mode.trim())
          .where((mode) => mode.isNotEmpty)
          .toList(),
      'activitySlugs': activitySlugs
          .map((slug) => slug.trim())
          .where((slug) => slug.isNotEmpty)
          .toList(),
      'travelerProfile': {
        if (hasChildren) 'hasChildren': true,
        'preferredLanguage': preferredLanguage.trim().isNotEmpty
            ? preferredLanguage.trim()
            : 'ru',
      },
    };
  }
}

class TripChecklistDestinationRequest {
  const TripChecklistDestinationRequest({
    required this.countryCode,
    required this.cityName,
    this.cityId,
  });

  final String countryCode;
  final String cityName;
  final String? cityId;

  Map<String, Object?> toJson() {
    return {
      'countryCode': countryCode.trim().toUpperCase(),
      'cityName': cityName.trim(),
      if ((cityId ?? '').trim().isNotEmpty) 'cityId': cityId!.trim(),
    };
  }
}

class TripChecklistSummaryVm {
  const TripChecklistSummaryVm({
    required this.instanceId,
    required this.userId,
    required this.tripId,
    required this.destination,
    required this.startAt,
    required this.endAt,
    required this.transportModes,
    required this.activitySlugs,
    required this.hasChildren,
    required this.readinessScore,
    required this.readinessStatus,
    required this.itemCount,
    this.destinationCountryName,
    this.generatedAt,
    this.updatedAt,
  });

  final String instanceId;
  final String userId;
  final String tripId;
  final TripChecklistDestinationRequest destination;
  final String? destinationCountryName;
  final DateTime startAt;
  final DateTime endAt;
  final List<String> transportModes;
  final List<String> activitySlugs;
  final bool hasChildren;
  final int readinessScore;
  final String readinessStatus;
  final int itemCount;
  final DateTime? generatedAt;
  final DateTime? updatedAt;

  factory TripChecklistSummaryVm.fromJson(Map<String, dynamic> json) {
    final destination = _mapValue(json['destination']);
    final readiness = _mapValue(json['readiness']);
    return TripChecklistSummaryVm(
      instanceId: json['instanceId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      tripId: json['tripId']?.toString() ?? '',
      destination: TripChecklistDestinationRequest(
        countryCode: destination['countryCode']?.toString() ?? '',
        cityName: destination['cityName']?.toString() ?? '',
        cityId: _blankToNull(destination['cityId']?.toString()),
      ),
      destinationCountryName: _blankToNull(
        destination['countryName']?.toString() ??
            json['destinationCountryName']?.toString(),
      ),
      startAt: _dateTimeValue(json['startAt']),
      endAt: _dateTimeValue(json['endAt']),
      transportModes: _stringListValue(json['transportModes']),
      activitySlugs: _stringListValue(json['activitySlugs']),
      hasChildren: json['hasChildren'] == true,
      readinessScore: (readiness['score'] as num?)?.toInt().clamp(0, 100) ?? 0,
      readinessStatus: readiness['status']?.toString() ?? '',
      itemCount: int.tryParse(json['itemCount']?.toString() ?? '') ?? 0,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class CustomChecklistItemRequest {
  const CustomChecklistItemRequest({
    required this.title,
    this.note = '',
    this.category = 'custom',
    this.priority = 'recommended',
    this.reuseInFuture = false,
  });

  final String title;
  final String note;
  final String category;
  final String priority;
  final bool reuseInFuture;

  Map<String, Object?> toJson() {
    final normalizedCategory = category.trim();
    final normalizedPriority = priority.trim();
    return {
      'title': title.trim(),
      'note': note.trim(),
      'category': normalizedCategory.isNotEmpty ? normalizedCategory : 'custom',
      'priority': normalizedPriority.isNotEmpty
          ? normalizedPriority
          : 'recommended',
      'reuseInFuture': reuseInFuture,
    };
  }
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is! Map) return const <String, dynamic>{};
  return Map<String, dynamic>.from(value);
}

List<String> _stringListValue(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime _dateTimeValue(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
