import 'dart:convert';

import '../../routing/models/routing_models.dart';

enum UserRouteVisibility {
  private('private'),
  unlisted('unlisted'),
  public('public');

  const UserRouteVisibility(this.backendValue);

  final String backendValue;

  static UserRouteVisibility fromJson(Object? value) {
    final normalized = (value as String? ?? '').trim().toLowerCase();
    return UserRouteVisibility.values.firstWhere(
      (visibility) => visibility.backendValue == normalized,
      orElse: () => UserRouteVisibility.private,
    );
  }
}

class UserRoutePointVm {
  const UserRoutePointVm({
    required this.latitude,
    required this.longitude,
    this.id,
    this.name,
    this.note,
    this.sourceType,
    this.sourceId,
    this.stopDurationMinutes,
  });

  factory UserRoutePointVm.fromJson(Map<String, dynamic> json) {
    return UserRoutePointVm(
      id: _stringOrNull(json['id']),
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
      name: _stringOrNull(json['name']),
      note: _stringOrNull(json['note']),
      sourceType: _stringOrNull(json['sourceType']),
      sourceId: _stringOrNull(json['sourceId']),
      stopDurationMinutes: _intOrNull(json['stopDurationMinutes']),
    );
  }

  factory UserRoutePointVm.fromRoutePoint(RoutePointVm point) {
    return UserRoutePointVm(
      latitude: point.latitude,
      longitude: point.longitude,
      name: point.name,
    );
  }

  final String? id;
  final double latitude;
  final double longitude;
  final String? name;
  final String? note;
  final String? sourceType;
  final String? sourceId;
  final int? stopDurationMinutes;

  Map<String, Object?> toJson() {
    return {
      if ((id ?? '').trim().isNotEmpty) 'id': id!.trim(),
      'latitude': latitude,
      'longitude': longitude,
      if ((name ?? '').trim().isNotEmpty) 'name': name!.trim(),
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      if ((sourceType ?? '').trim().isNotEmpty)
        'sourceType': sourceType!.trim(),
      if ((sourceId ?? '').trim().isNotEmpty) 'sourceId': sourceId!.trim(),
      if (stopDurationMinutes != null)
        'stopDurationMinutes': stopDurationMinutes,
    };
  }

  RoutePointVm toRoutePoint() {
    return RoutePointVm(latitude: latitude, longitude: longitude, name: name);
  }
}

class UserRouteSnapshotVm {
  const UserRouteSnapshotVm({
    required this.provider,
    required this.mode,
    required this.profile,
    required this.distanceMeters,
    required this.durationSeconds,
    this.encodedPolyline,
    this.geometryGeoJson,
  });

  factory UserRouteSnapshotVm.fromJson(Map<String, dynamic> json) {
    return UserRouteSnapshotVm(
      provider: (json['provider'] as String? ?? '').trim(),
      mode: RouteMode.fromJson(json['mode']),
      profile: RouteProfile.fromJson(json['profile']),
      distanceMeters: _intValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
      encodedPolyline: _stringOrNull(json['encodedPolyline']),
      geometryGeoJson: _stringOrNull(json['geometryGeoJson']),
    );
  }

  factory UserRouteSnapshotVm.fromRouteResponse(RouteResponseVm route) {
    final encodedPolyline = _stringOrNull(route.geometry.polyline);
    final displayPoints = route.displayPoints;
    return UserRouteSnapshotVm(
      provider: route.provider,
      mode: route.mode,
      profile: route.profile,
      distanceMeters: route.distanceMeters.round(),
      durationSeconds: route.durationSeconds,
      encodedPolyline: encodedPolyline,
      geometryGeoJson: displayPoints.length >= 2
          ? _geoJsonLineString(displayPoints)
          : null,
    );
  }

  RouteResponseVm toRouteResponse() {
    return RouteResponseVm(
      provider: provider,
      mode: mode,
      profile: profile,
      distanceMeters: distanceMeters.toDouble(),
      durationSeconds: durationSeconds,
      geometry: RouteGeometryVm(
        encoding: encodedPolyline == null ? 'geojson' : 'polyline6',
        polyline: encodedPolyline,
        points: _routePointsFromGeoJson(geometryGeoJson),
      ),
    );
  }

  final String provider;
  final RouteMode mode;
  final RouteProfile profile;
  final int distanceMeters;
  final int durationSeconds;
  final String? encodedPolyline;
  final String? geometryGeoJson;

  Map<String, Object?> toJson() {
    return {
      if (provider.trim().isNotEmpty) 'provider': provider.trim(),
      'mode': mode.backendValue,
      'profile': profile.backendValue,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      if ((encodedPolyline ?? '').trim().isNotEmpty)
        'encodedPolyline': encodedPolyline!.trim(),
      if ((geometryGeoJson ?? '').trim().isNotEmpty)
        'geometryGeoJson': geometryGeoJson!.trim(),
    };
  }
}

class UserRouteStatsVm {
  const UserRouteStatsVm({
    required this.savesCount,
    required this.copiesCount,
    required this.viewsCount,
  });

  factory UserRouteStatsVm.fromJson(Map<String, dynamic> json) {
    return UserRouteStatsVm(
      savesCount: _intValue(json['savesCount']),
      copiesCount: _intValue(json['copiesCount']),
      viewsCount: _intValue(json['viewsCount']),
    );
  }

  final int savesCount;
  final int copiesCount;
  final int viewsCount;
}

class UserRouteVm {
  const UserRouteVm({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.visibility,
    required this.profile,
    required this.points,
    required this.snapshot,
    required this.stats,
    required this.savedByMe,
    this.sourceRouteId,
    this.description,
    this.cityCode,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory UserRouteVm.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final rawTags = json['tags'];
    return UserRouteVm(
      id: (json['id'] as String? ?? '').trim(),
      ownerUserId: (json['ownerUserId'] as String? ?? '').trim(),
      sourceRouteId: _stringOrNull(json['sourceRouteId']),
      title: (json['title'] as String? ?? '').trim(),
      description: _stringOrNull(json['description']),
      visibility: UserRouteVisibility.fromJson(json['visibility']),
      profile: RouteProfile.fromJson(json['profile']),
      cityCode: _stringOrNull(json['cityCode']),
      tags: rawTags is List
          ? rawTags
                .whereType<String>()
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(growable: false)
          : const [],
      points: rawPoints is List
          ? rawPoints
                .whereType<Map>()
                .map((point) => UserRoutePointVm.fromJson(_dynamicMap(point)))
                .toList(growable: false)
          : const [],
      snapshot: UserRouteSnapshotVm.fromJson(
        _dynamicMap(json['snapshot'] as Map? ?? const {}),
      ),
      stats: UserRouteStatsVm.fromJson(
        _dynamicMap(json['stats'] as Map? ?? const {}),
      ),
      savedByMe: json['savedByMe'] == true,
      createdAt: _dateTimeOrNull(json['createdAt']),
      updatedAt: _dateTimeOrNull(json['updatedAt']),
    );
  }

  final String id;
  final String ownerUserId;
  final String? sourceRouteId;
  final String title;
  final String? description;
  final UserRouteVisibility visibility;
  final RouteProfile profile;
  final String? cityCode;
  final List<String> tags;
  final List<UserRoutePointVm> points;
  final UserRouteSnapshotVm snapshot;
  final UserRouteStatsVm stats;
  final bool savedByMe;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class CreateUserRouteRequestVm {
  const CreateUserRouteRequestVm({
    required this.title,
    required this.visibility,
    required this.profile,
    required this.points,
    required this.snapshot,
    this.description,
    this.cityCode,
    this.tags = const [],
  });

  factory CreateUserRouteRequestVm.fromBuiltRoute({
    required String title,
    required RouteResponseVm route,
    required List<RoutePointVm> points,
    String? description,
    UserRouteVisibility visibility = UserRouteVisibility.private,
    String? cityCode,
    List<String> tags = const [],
  }) {
    return CreateUserRouteRequestVm(
      title: title,
      description: description,
      visibility: visibility,
      profile: route.profile,
      cityCode: cityCode,
      tags: tags,
      points: points
          .map(UserRoutePointVm.fromRoutePoint)
          .toList(growable: false),
      snapshot: UserRouteSnapshotVm.fromRouteResponse(route),
    );
  }

  final String title;
  final String? description;
  final UserRouteVisibility visibility;
  final RouteProfile profile;
  final String? cityCode;
  final List<String> tags;
  final List<UserRoutePointVm> points;
  final UserRouteSnapshotVm snapshot;

  Map<String, Object?> toJson() {
    return {
      'title': title.trim(),
      if ((description ?? '').trim().isNotEmpty)
        'description': description!.trim(),
      'visibility': visibility.backendValue,
      'profile': profile.backendValue,
      if ((cityCode ?? '').trim().isNotEmpty) 'cityCode': cityCode!.trim(),
      if (tags.isNotEmpty)
        'tags': tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false),
      'points': points.map((point) => point.toJson()).toList(growable: false),
      'snapshot': snapshot.toJson(),
    };
  }
}

class UpdateUserRouteRequestVm {
  const UpdateUserRouteRequestVm({
    this.title,
    this.description,
    this.visibility,
    this.profile,
    this.cityCode,
    this.tags,
    this.points,
    this.snapshot,
  });

  final String? title;
  final String? description;
  final UserRouteVisibility? visibility;
  final RouteProfile? profile;
  final String? cityCode;
  final List<String>? tags;
  final List<UserRoutePointVm>? points;
  final UserRouteSnapshotVm? snapshot;

  Map<String, Object?> toJson() {
    return {
      if (title != null) 'title': title!.trim(),
      if (description != null) 'description': description!.trim(),
      if (visibility != null) 'visibility': visibility!.backendValue,
      if (profile != null) 'profile': profile!.backendValue,
      if (cityCode != null) 'cityCode': cityCode!.trim(),
      if (tags != null)
        'tags': tags!
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false),
      if (points != null)
        'points': points!
            .map((point) => point.toJson())
            .toList(growable: false),
      if (snapshot != null) 'snapshot': snapshot!.toJson(),
    };
  }
}

Map<String, dynamic> _dynamicMap(Map<Object?, Object?> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

String? _stringOrNull(Object? value) {
  final text = (value as String? ?? '').trim();
  return text.isEmpty ? null : text;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _intValue(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  return _intValue(value);
}

String _geoJsonLineString(List<RoutePointVm> points) {
  return jsonEncode({
    'type': 'LineString',
    'coordinates': points
        .map((point) => [point.longitude, point.latitude])
        .toList(growable: false),
  });
}

List<RoutePointVm> _routePointsFromGeoJson(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return const [];
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    if ((decoded['type'] as String? ?? '').toLowerCase() != 'linestring') {
      return const [];
    }

    final coordinates = decoded['coordinates'];
    if (coordinates is! List) {
      return const [];
    }

    return coordinates
        .whereType<List>()
        .map((coordinate) {
          if (coordinate.length < 2) {
            return null;
          }
          final longitude = _doubleOrNull(coordinate[0]);
          final latitude = _doubleOrNull(coordinate[1]);
          if (latitude == null || longitude == null) {
            return null;
          }
          return RoutePointVm(latitude: latitude, longitude: longitude);
        })
        .whereType<RoutePointVm>()
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

double? _doubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _dateTimeOrNull(Object? value) {
  final text = (value as String? ?? '').trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
