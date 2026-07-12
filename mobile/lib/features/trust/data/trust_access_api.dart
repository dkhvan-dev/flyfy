import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum TrustRestrictionCode {
  chat('CHAT'),
  activityCreation('ACTIVITY_CREATION'),
  tourPublishing('TOUR_PUBLISHING'),
  fileUpload('FILE_UPLOAD'),
  payout('PAYOUT'),
  guideApplication('GUIDE_APPLICATION'),
  accountSuspension('ACCOUNT_SUSPENSION');

  const TrustRestrictionCode(this.wireName);

  final String wireName;

  static TrustRestrictionCode? fromWireName(Object? value) {
    final normalized = value?.toString().trim().toUpperCase() ?? '';
    for (final code in values) {
      if (code.wireName == normalized) return code;
    }
    return null;
  }
}

class TrustActiveRestriction {
  const TrustActiveRestriction({
    required this.id,
    required this.code,
    required this.reasonCode,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final TrustRestrictionCode code;
  final String reasonCode;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory TrustActiveRestriction.fromJson(Map<String, dynamic> json) {
    final code = TrustRestrictionCode.fromWireName(json['restrictionCode']);
    if (code == null) {
      throw const FormatException('unsupported trust restriction code');
    }
    return TrustActiveRestriction(
      id: (json['restrictionId'] ?? '').toString().trim(),
      code: code,
      reasonCode: (json['reasonCode'] ?? '').toString().trim(),
      expiresAt: _tryParseDate(json['expiresAt']),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

class TrustAccessSnapshot {
  const TrustAccessSnapshot({
    required this.status,
    required this.activeRestrictions,
  });

  final String status;
  final List<TrustActiveRestriction> activeRestrictions;

  factory TrustAccessSnapshot.fromJson(Map<String, dynamic> json) {
    final profile = _asMap(json['profile']);
    final rawRestrictions = json['activeRestrictions'];
    final restrictions = <TrustActiveRestriction>[];
    if (rawRestrictions is List) {
      for (final raw in rawRestrictions) {
        final item = _asMap(raw);
        if (item.isEmpty) continue;
        try {
          final restriction = TrustActiveRestriction.fromJson(item);
          if (restriction.id.isNotEmpty) restrictions.add(restriction);
        } on FormatException {
          // Forward-compatible clients ignore unknown restriction codes.
        }
      }
    }
    return TrustAccessSnapshot(
      status: (profile['status'] ?? '').toString().trim().toUpperCase(),
      activeRestrictions: List.unmodifiable(restrictions),
    );
  }
}

abstract interface class TrustAccessApi {
  Future<TrustAccessSnapshot> getMyTrustAccess();
}

class GatewayTrustAccessApi implements TrustAccessApi {
  GatewayTrustAccessApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<TrustAccessSnapshot> getMyTrustAccess() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/trust/profile',
      options: Options(extra: const {'requiresAuth': true}),
    );
    return TrustAccessSnapshot.fromJson(response.data ?? const {});
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

DateTime? _tryParseDate(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
