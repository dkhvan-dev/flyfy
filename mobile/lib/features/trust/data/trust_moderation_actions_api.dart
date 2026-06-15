import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

enum TrustModerationEntityType {
  story,
  comment,
  community,
  activity,
  tour,
  profile,
  guide,
  message,
}

enum TrustReportReason {
  spam,
  harassment,
  hateSpeech,
  scam,
  sexualContent,
  violence,
  illegalActivity,
  misleading,
  other,
}

class TrustModerationTarget {
  const TrustModerationTarget({
    required this.entityType,
    required this.entityId,
    this.ownerUserId,
    this.contextId,
  });

  final TrustModerationEntityType entityType;
  final String entityId;
  final String? ownerUserId;
  final String? contextId;
}

class TrustReportContentRequest {
  const TrustReportContentRequest({
    required this.target,
    required this.reason,
    this.details,
  });

  final TrustModerationTarget target;
  final TrustReportReason reason;
  final String? details;
}

class TrustMuteUserRequest {
  const TrustMuteUserRequest({required this.userId, this.sourceTarget});

  final String userId;
  final TrustModerationTarget? sourceTarget;
}

class TrustMuteTargetRequest {
  const TrustMuteTargetRequest({required this.target});

  final TrustModerationTarget target;
}

class TrustRestrictionAppealRequest {
  const TrustRestrictionAppealRequest({
    required this.restrictionId,
    required this.message,
    this.reasonCode = 'user_appeal',
    this.idempotencyKey,
  });

  final String restrictionId;
  final String message;
  final String reasonCode;
  final String? idempotencyKey;
}

abstract class TrustModerationActionsApi {
  Future<void> reportContent(TrustReportContentRequest request);

  Future<void> muteTarget(TrustMuteTargetRequest request);

  Future<void> unmuteTarget(TrustMuteTargetRequest request);

  Future<void> muteUser(TrustMuteUserRequest request);

  Future<void> unmuteUser(TrustMuteUserRequest request);

  Future<void> appealRestriction(TrustRestrictionAppealRequest request);
}

class GatewayTrustModerationActionsApi implements TrustModerationActionsApi {
  GatewayTrustModerationActionsApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<void> reportContent(TrustReportContentRequest request) async {
    switch (request.target.entityType) {
      case TrustModerationEntityType.story:
        final storyId = _requiredValue(request.target.entityId, 'storyId');
        await _apiClient.dio.post(
          '/posts/${Uri.encodeComponent(storyId)}/report',
          data: {
            'reason': _enumWireName(request.reason),
            'details': (request.details ?? '').trim(),
          },
          options: Options(extra: const {'requiresAuth': true}),
        );
        return;
      case TrustModerationEntityType.comment:
      case TrustModerationEntityType.activity:
      case TrustModerationEntityType.tour:
      case TrustModerationEntityType.profile:
      case TrustModerationEntityType.guide:
      case TrustModerationEntityType.message:
        throw UnsupportedError(
          'Report contract is not available for ${request.target.entityType.name}.',
        );
      case TrustModerationEntityType.community:
        final communityId = _requiredValue(
          request.target.entityId,
          'communityId',
        );
        await _apiClient.dio.post(
          '/communities/${Uri.encodeComponent(communityId)}/report',
          data: {
            'reason': _enumWireName(request.reason),
            'details': (request.details ?? '').trim(),
          },
          options: Options(extra: const {'requiresAuth': true}),
        );
        return;
    }
  }

  @override
  Future<void> muteTarget(TrustMuteTargetRequest request) async {
    final target = _requiredTarget(request.target);
    if (target.entityType == TrustModerationEntityType.community) {
      await _apiClient.dio.post(
        '/communities/${Uri.encodeComponent(target.entityId.trim())}/mute',
        options: Options(extra: const {'requiresAuth': true}),
      );
      return;
    }
    throw UnsupportedError(
      'Generic target mute contract is not available yet.',
    );
  }

  @override
  Future<void> unmuteTarget(TrustMuteTargetRequest request) async {
    final target = _requiredTarget(request.target);
    if (target.entityType == TrustModerationEntityType.community) {
      await _apiClient.dio.delete(
        '/communities/${Uri.encodeComponent(target.entityId.trim())}/mute',
        options: Options(extra: const {'requiresAuth': true}),
      );
      return;
    }
    throw UnsupportedError(
      'Generic target unmute contract is not available yet.',
    );
  }

  @override
  Future<void> muteUser(TrustMuteUserRequest request) {
    _requiredValue(request.userId, 'userId');
    throw UnsupportedError('Generic user mute contract is not available yet.');
  }

  @override
  Future<void> unmuteUser(TrustMuteUserRequest request) {
    _requiredValue(request.userId, 'userId');
    throw UnsupportedError(
      'Generic user unmute contract is not available yet.',
    );
  }

  @override
  Future<void> appealRestriction(TrustRestrictionAppealRequest request) async {
    final restrictionId = _requiredValue(
      request.restrictionId,
      'restrictionId',
    );
    await _apiClient.dio.post(
      '/trust/restrictions/${Uri.encodeComponent(restrictionId)}/appeals',
      data: {
        'reasonCode': _requiredValue(request.reasonCode, 'reasonCode'),
        'userMessage': _requiredValue(request.message, 'message'),
        if ((request.idempotencyKey ?? '').trim().isNotEmpty)
          'idempotencyKey': request.idempotencyKey!.trim(),
      },
      options: Options(extra: const {'requiresAuth': true}),
    );
  }
}

TrustModerationTarget _requiredTarget(TrustModerationTarget target) {
  _requiredValue(target.entityId, '${target.entityType.name}Id');
  return target;
}

String _requiredValue(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return trimmed;
}

String _enumWireName(Enum value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.name.length; i += 1) {
    final char = value.name[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0) {
      buffer.write('_');
    }
    buffer.write(char.toUpperCase());
  }
  return buffer.toString();
}
