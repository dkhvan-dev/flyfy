import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum PushPlatform {
  android('android'),
  ios('ios');

  const PushPlatform(this.wireValue);

  final String wireValue;
}

enum PushProvider {
  fcm('fcm'),
  apns('apns'),
  hms('hms');

  const PushProvider(this.wireValue);

  final String wireValue;
}

enum PushEnvironment {
  sandbox('sandbox'),
  production('production');

  const PushEnvironment(this.wireValue);

  final String wireValue;
}

class DeviceTokenRegistration {
  const DeviceTokenRegistration({
    required this.platform,
    required this.provider,
    required this.environment,
    required this.token,
    required this.appBundleId,
    required this.appVersion,
    required this.deviceModel,
    required this.manufacturer,
    required this.locale,
    required this.timezone,
  });

  final PushPlatform platform;
  final PushProvider provider;
  final PushEnvironment environment;
  final String token;
  final String appBundleId;
  final String appVersion;
  final String deviceModel;
  final String manufacturer;
  final String locale;
  final String timezone;

  Map<String, Object?> toJson() {
    return {
      'platform': platform.wireValue,
      'provider': provider.wireValue,
      'environment': environment.wireValue,
      'token': token.trim(),
      'appBundleId': appBundleId.trim(),
      'appVersion': appVersion.trim(),
      'deviceModel': deviceModel.trim(),
      'manufacturer': manufacturer.trim(),
      'locale': locale.trim(),
      'timezone': timezone.trim(),
    };
  }
}

class RegisteredDeviceToken {
  const RegisteredDeviceToken({required this.id});

  factory RegisteredDeviceToken.fromJson(Map<String, dynamic> json) {
    return RegisteredDeviceToken(id: json['id']?.toString() ?? '');
  }

  final String id;
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.deepLink,
    required this.data,
    required this.createdAt,
    required this.readAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      priority: json['priority']?.toString() ?? 'normal',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      deepLink: json['deepLink']?.toString() ?? '',
      data: _stringMap(json['data']),
      createdAt: _dateTime(json['createdAt']),
      readAt: _nullableDateTime(json['readAt']),
    );
  }

  final String id;
  final String category;
  final String priority;
  final String title;
  final String body;
  final String imageUrl;
  final String deepLink;
  final Map<String, String> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}

class NotificationCategorySummary {
  const NotificationCategorySummary({
    required this.category,
    required this.unreadCount,
    required this.totalCount,
    required this.latest,
  });

  factory NotificationCategorySummary.fromJson(Map<String, dynamic> json) {
    final latestJson = json['latest'];
    return NotificationCategorySummary(
      category: json['category']?.toString() ?? 'general',
      unreadCount: _intValue(json['unreadCount']),
      totalCount: _intValue(json['totalCount']),
      latest: UserNotification.fromJson(
        latestJson is Map<String, dynamic> ? latestJson : <String, dynamic>{},
      ),
    );
  }

  final String category;
  final int unreadCount;
  final int totalCount;
  final UserNotification latest;

  bool get hasUnread => unreadCount > 0;
}

class NotificationReadResult {
  const NotificationReadResult({required this.updatedCount});

  factory NotificationReadResult.fromJson(Map<String, dynamic> json) {
    return NotificationReadResult(
      updatedCount: _intValue(json['updatedCount']),
    );
  }

  final int updatedCount;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.activityEnabled,
    required this.excursionEnabled,
    required this.chatEnabled,
    required this.marketingEnabled,
    required this.quietHoursEnabled,
    required this.quietHoursStartMinutes,
    required this.quietHoursEndMinutes,
    required this.timezone,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      pushEnabled: true,
      activityEnabled: true,
      excursionEnabled: true,
      chatEnabled: true,
      marketingEnabled: false,
      quietHoursEnabled: false,
      quietHoursStartMinutes: 22 * 60,
      quietHoursEndMinutes: 8 * 60,
      timezone: 'UTC',
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] != false,
      activityEnabled: json['activityEnabled'] != false,
      excursionEnabled: json['excursionEnabled'] != false,
      chatEnabled: json['chatEnabled'] != false,
      marketingEnabled: json['marketingEnabled'] == true,
      quietHoursEnabled: json['quietHoursEnabled'] == true,
      quietHoursStartMinutes: _minuteValue(
        json['quietHoursStartMinutes'],
        22 * 60,
      ),
      quietHoursEndMinutes: _minuteValue(json['quietHoursEndMinutes'], 8 * 60),
      timezone: _nonEmptyString(json['timezone'], 'UTC'),
    );
  }

  final bool pushEnabled;
  final bool activityEnabled;
  final bool excursionEnabled;
  final bool chatEnabled;
  final bool marketingEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStartMinutes;
  final int quietHoursEndMinutes;
  final String timezone;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? activityEnabled,
    bool? excursionEnabled,
    bool? chatEnabled,
    bool? marketingEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
    String? timezone,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      activityEnabled: activityEnabled ?? this.activityEnabled,
      excursionEnabled: excursionEnabled ?? this.excursionEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes ?? this.quietHoursEndMinutes,
      timezone: timezone ?? this.timezone,
    );
  }
}

class NotificationPreferencesUpdate {
  const NotificationPreferencesUpdate({
    this.pushEnabled,
    this.activityEnabled,
    this.excursionEnabled,
    this.chatEnabled,
    this.marketingEnabled,
    this.quietHoursEnabled,
    this.quietHoursStartMinutes,
    this.quietHoursEndMinutes,
    this.timezone,
  });

  final bool? pushEnabled;
  final bool? activityEnabled;
  final bool? excursionEnabled;
  final bool? chatEnabled;
  final bool? marketingEnabled;
  final bool? quietHoursEnabled;
  final int? quietHoursStartMinutes;
  final int? quietHoursEndMinutes;
  final String? timezone;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (pushEnabled != null) 'pushEnabled': pushEnabled,
      if (activityEnabled != null) 'activityEnabled': activityEnabled,
      if (excursionEnabled != null) 'excursionEnabled': excursionEnabled,
      if (chatEnabled != null) 'chatEnabled': chatEnabled,
      if (marketingEnabled != null) 'marketingEnabled': marketingEnabled,
      if (quietHoursEnabled != null) 'quietHoursEnabled': quietHoursEnabled,
      if (quietHoursStartMinutes != null)
        'quietHoursStartMinutes': quietHoursStartMinutes,
      if (quietHoursEndMinutes != null)
        'quietHoursEndMinutes': quietHoursEndMinutes,
      if (timezone != null) 'timezone': timezone?.trim(),
    };
  }
}

abstract interface class NotificationDeviceTokenClient {
  Future<RegisteredDeviceToken> registerDeviceToken(
    DeviceTokenRegistration registration,
  );

  Future<void> deleteDeviceToken(String deviceTokenId);
}

abstract interface class NotificationInboxClient {
  Future<List<NotificationCategorySummary>> listNotificationCategories({
    int limit = 20,
  });

  Future<List<UserNotification>> listNotifications({
    required String category,
    int limit = 30,
    int offset = 0,
  });

  Future<NotificationReadResult> markNotificationCategoryRead({
    required String category,
  });

  Future<NotificationPreferences> getNotificationPreferences();

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferencesUpdate update,
  );
}

class NotificationApi
    implements NotificationDeviceTokenClient, NotificationInboxClient {
  NotificationApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<RegisteredDeviceToken> registerDeviceToken(
    DeviceTokenRegistration registration,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/notifications/device-tokens',
      data: registration.toJson(),
    );
    return RegisteredDeviceToken.fromJson(response.data ?? {});
  }

  @override
  Future<void> deleteDeviceToken(String deviceTokenId) async {
    final encodedDeviceTokenId = Uri.encodeComponent(deviceTokenId.trim());
    await _apiClient.dio.delete<void>(
      '/notifications/device-tokens/$encodedDeviceTokenId',
      options: Options(extra: const <String, dynamic>{'requiresAuth': true}),
    );
  }

  @override
  Future<List<NotificationCategorySummary>> listNotificationCategories({
    int limit = 20,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/notifications/categories',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    final rawCategories = response.data?['categories'];
    if (rawCategories is! List) {
      return const [];
    }
    return rawCategories
        .whereType<Map<String, dynamic>>()
        .map(NotificationCategorySummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<UserNotification>> listNotifications({
    required String category,
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: <String, dynamic>{
        'category': category.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    final rawNotifications = response.data?['notifications'];
    if (rawNotifications is! List) {
      return const [];
    }
    return rawNotifications
        .whereType<Map<String, dynamic>>()
        .map(UserNotification.fromJson)
        .toList(growable: false);
  }

  @override
  Future<NotificationReadResult> markNotificationCategoryRead({
    required String category,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/notifications/read-all',
      data: <String, dynamic>{'category': category.trim()},
    );
    return NotificationReadResult.fromJson(response.data ?? {});
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/notifications/preferences',
    );
    return NotificationPreferences.fromJson(response.data ?? {});
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferencesUpdate update,
  ) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      '/notifications/preferences',
      data: update.toJson(),
    );
    return NotificationPreferences.fromJson(response.data ?? {});
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return value.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

DateTime _dateTime(Object? value) {
  return _nullableDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _minuteValue(Object? value, int fallback) {
  final parsed = _intValue(value);
  if (parsed < 0 || parsed >= 24 * 60) {
    return fallback;
  }
  return parsed;
}

String _nonEmptyString(Object? value, String fallback) {
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) {
    return fallback;
  }
  return normalized;
}
