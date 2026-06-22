enum RouteMode {
  walking('walking'),
  cycling('cycling'),
  driving('driving'),
  transit('transit');

  const RouteMode(this.backendValue);

  final String backendValue;

  static RouteMode fromJson(Object? value) {
    final normalized = (value as String? ?? '').trim().toLowerCase();
    return RouteMode.values.firstWhere(
      (mode) => mode.backendValue == normalized,
      orElse: () => RouteMode.walking,
    );
  }
}

enum RouteProfile {
  touristWalk('tourist_walk'),
  fastWalk('fast_walk'),
  bikeCity('bike_city'),
  carStandard('car_standard'),
  guideRoute('guide_route'),
  dayPlan('day_plan'),
  transit('transit');

  const RouteProfile(this.backendValue);

  final String backendValue;

  static RouteProfile fromJson(Object? value) {
    final normalized = (value as String? ?? '').trim().toLowerCase();
    return RouteProfile.values.firstWhere(
      (profile) => profile.backendValue == normalized,
      orElse: () => RouteProfile.touristWalk,
    );
  }
}

class RouteProfileInfoVm {
  const RouteProfileInfoVm({
    required this.id,
    required this.mode,
    required this.label,
    required this.description,
  });

  factory RouteProfileInfoVm.fromJson(Map<String, dynamic> json) {
    return RouteProfileInfoVm(
      id: RouteProfile.fromJson(json['id']),
      mode: RouteMode.fromJson(json['mode']),
      label: (json['label'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
    );
  }

  final RouteProfile id;
  final RouteMode mode;
  final String label;
  final String description;
}

class RoutePointVm {
  const RoutePointVm({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  factory RoutePointVm.fromJson(Map<String, dynamic> json) {
    return RoutePointVm(
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
      name: _stringOrNull(json['name']),
    );
  }

  final double latitude;
  final double longitude;
  final String? name;

  Map<String, Object?> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if ((name ?? '').trim().isNotEmpty) 'name': name!.trim(),
    };
  }
}

class RouteRequestVm {
  const RouteRequestVm({
    required this.profile,
    required this.points,
    this.mode,
    this.departureTime,
    this.arrivalTime,
  });

  final RouteProfile profile;
  final List<RoutePointVm> points;
  final RouteMode? mode;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      'points': points.map((point) => point.toJson()).toList(growable: false),
      if (departureTime != null)
        'departureTime': departureTime!.toUtc().toIso8601String(),
      if (arrivalTime != null)
        'arrivalTime': arrivalTime!.toUtc().toIso8601String(),
    };
  }
}

class EtaRequestVm {
  const EtaRequestVm({
    required this.profile,
    required this.origin,
    required this.destination,
    this.mode,
    this.departureTime,
  });

  final RouteProfile profile;
  final RoutePointVm origin;
  final RoutePointVm destination;
  final RouteMode? mode;
  final DateTime? departureTime;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      if (departureTime != null)
        'departureTime': departureTime!.toUtc().toIso8601String(),
    };
  }
}

class MatrixRequestVm {
  const MatrixRequestVm({
    required this.profile,
    required this.origins,
    required this.destinations,
    this.mode,
  });

  final RouteProfile profile;
  final List<RoutePointVm> origins;
  final List<RoutePointVm> destinations;
  final RouteMode? mode;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      'origins': origins.map((point) => point.toJson()).toList(growable: false),
      'destinations': destinations
          .map((point) => point.toJson())
          .toList(growable: false),
    };
  }
}

class IsochroneRequestVm {
  const IsochroneRequestVm({
    required this.profile,
    required this.origin,
    required this.minutes,
    this.mode,
  });

  final RouteProfile profile;
  final RoutePointVm origin;
  final List<int> minutes;
  final RouteMode? mode;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      'origin': origin.toJson(),
      'minutes': minutes,
    };
  }
}

class ItineraryOptimizationRequestVm {
  const ItineraryOptimizationRequestVm({
    required this.profile,
    required this.stops,
    this.mode,
    this.start,
    this.end,
  });

  final RouteProfile profile;
  final List<RoutePointVm> stops;
  final RouteMode? mode;
  final RoutePointVm? start;
  final RoutePointVm? end;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      if (start != null) 'start': start!.toJson(),
      'stops': stops.map((point) => point.toJson()).toList(growable: false),
      if (end != null) 'end': end!.toJson(),
    };
  }
}

class MapMatchRequestVm {
  const MapMatchRequestVm({
    required this.profile,
    required this.trace,
    this.mode,
  });

  final RouteProfile profile;
  final List<RoutePointVm> trace;
  final RouteMode? mode;

  Map<String, Object?> toJson() {
    return {
      'profile': profile.backendValue,
      if (mode != null) 'mode': mode!.backendValue,
      'trace': trace.map((point) => point.toJson()).toList(growable: false),
    };
  }
}

class RouteGeometryVm {
  const RouteGeometryVm({
    required this.encoding,
    this.polyline,
    this.points = const [],
  });

  factory RouteGeometryVm.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    return RouteGeometryVm(
      encoding: (json['encoding'] as String? ?? '').trim(),
      polyline: _stringOrNull(json['polyline']),
      points: rawPoints is List
          ? rawPoints
                .whereType<Map<String, dynamic>>()
                .map(RoutePointVm.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String encoding;
  final String? polyline;
  final List<RoutePointVm> points;

  List<RoutePointVm> get displayPoints {
    if (points.isNotEmpty) {
      return points;
    }

    final encoded = polyline;
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    final normalizedEncoding = encoding.toLowerCase();
    if (normalizedEncoding == 'polyline6') {
      return _decodePolyline(encoded, precision: 6);
    }
    if (normalizedEncoding == 'polyline' || normalizedEncoding == 'polyline5') {
      return _decodePolyline(encoded, precision: 5);
    }
    return const [];
  }
}

class RouteWarningVm {
  const RouteWarningVm({required this.code, required this.message});

  factory RouteWarningVm.fromJson(Map<String, dynamic> json) {
    return RouteWarningVm(
      code: (json['code'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
    );
  }

  final String code;
  final String message;
}

class RouteLegVm {
  const RouteLegVm({
    required this.fromIndex,
    required this.toIndex,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.steps = const [],
  });

  factory RouteLegVm.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    return RouteLegVm(
      fromIndex: _intValue(json['fromIndex']),
      toIndex: _intValue(json['toIndex']),
      distanceMeters: _doubleValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
      geometry: RouteGeometryVm.fromJson(
        (json['geometry'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map>()
                .map(
                  (step) => RouteStepVm.fromJson(step.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final int fromIndex;
  final int toIndex;
  final double distanceMeters;
  final int durationSeconds;
  final RouteGeometryVm geometry;
  final List<RouteStepVm> steps;
}

class RouteStepVm {
  const RouteStepVm({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteStepVm.fromJson(Map<String, dynamic> json) {
    return RouteStepVm(
      instruction: (json['instruction'] as String? ?? '').trim(),
      distanceMeters: _doubleValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
    );
  }

  final String instruction;
  final double distanceMeters;
  final int durationSeconds;
}

class RouteResponseVm {
  const RouteResponseVm({
    required this.provider,
    required this.mode,
    required this.profile,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.legs = const [],
    this.warnings = const [],
  });

  factory RouteResponseVm.fromJson(Map<String, dynamic> json) {
    final rawWarnings = json['warnings'];
    final rawLegs = json['legs'];
    return RouteResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      mode: RouteMode.fromJson(json['mode']),
      profile: RouteProfile.fromJson(json['profile']),
      distanceMeters: _doubleValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
      geometry: RouteGeometryVm.fromJson(
        (json['geometry'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      legs: rawLegs is List
          ? rawLegs
                .whereType<Map>()
                .map((leg) => RouteLegVm.fromJson(leg.cast<String, dynamic>()))
                .toList(growable: false)
          : const [],
      warnings: rawWarnings is List
          ? rawWarnings
                .whereType<Map<String, dynamic>>()
                .map(RouteWarningVm.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String provider;
  final RouteMode mode;
  final RouteProfile profile;
  final double distanceMeters;
  final int durationSeconds;
  final RouteGeometryVm geometry;
  final List<RouteLegVm> legs;
  final List<RouteWarningVm> warnings;

  List<RoutePointVm> get displayPoints {
    final combined = <RoutePointVm>[];
    for (final leg in legs) {
      for (final point in leg.geometry.displayPoints) {
        if (combined.isNotEmpty && _sameRoutePoint(combined.last, point)) {
          continue;
        }
        combined.add(point);
      }
    }
    if (combined.length >= 2) {
      return combined;
    }
    return geometry.displayPoints;
  }
}

class EtaResponseVm {
  const EtaResponseVm({
    required this.provider,
    required this.mode,
    required this.profile,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory EtaResponseVm.fromJson(Map<String, dynamic> json) {
    return EtaResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      mode: RouteMode.fromJson(json['mode']),
      profile: RouteProfile.fromJson(json['profile']),
      distanceMeters: _doubleValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
    );
  }

  final String provider;
  final RouteMode mode;
  final RouteProfile profile;
  final double distanceMeters;
  final int durationSeconds;
}

class MatrixResponseVm {
  const MatrixResponseVm({required this.provider, required this.rows});

  factory MatrixResponseVm.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'];
    return MatrixResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      rows: rawRows is List
          ? rawRows
                .whereType<Map>()
                .map((row) => MatrixRowVm.fromJson(row.cast<String, dynamic>()))
                .toList(growable: false)
          : const [],
    );
  }

  final String provider;
  final List<MatrixRowVm> rows;
}

class MatrixRowVm {
  const MatrixRowVm({required this.cells});

  factory MatrixRowVm.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'];
    return MatrixRowVm(
      cells: rawCells is List
          ? rawCells
                .whereType<Map>()
                .map(
                  (cell) => MatrixCellVm.fromJson(cell.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final List<MatrixCellVm> cells;
}

class MatrixCellVm {
  const MatrixCellVm({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.reachable,
  });

  factory MatrixCellVm.fromJson(Map<String, dynamic> json) {
    return MatrixCellVm(
      distanceMeters: _doubleValue(json['distanceMeters']),
      durationSeconds: _intValue(json['durationSeconds']),
      reachable: json['reachable'] == true,
    );
  }

  final double distanceMeters;
  final int durationSeconds;
  final bool reachable;
}

class IsochroneResponseVm {
  const IsochroneResponseVm({required this.provider, required this.features});

  factory IsochroneResponseVm.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    return IsochroneResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      features: rawFeatures is List
          ? rawFeatures
                .whereType<Map>()
                .map((feature) => feature.cast<String, dynamic>())
                .toList(growable: false)
          : const [],
    );
  }

  final String provider;
  final List<Map<String, dynamic>> features;
}

class ItineraryOptimizationResponseVm {
  const ItineraryOptimizationResponseVm({
    required this.provider,
    required this.orderedStops,
    required this.route,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  factory ItineraryOptimizationResponseVm.fromJson(Map<String, dynamic> json) {
    final rawStops = json['orderedStops'];
    return ItineraryOptimizationResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      orderedStops: rawStops is List
          ? rawStops
                .whereType<Map>()
                .map(
                  (point) =>
                      RoutePointVm.fromJson(point.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
      route: RouteResponseVm.fromJson(
        (json['route'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      durationSeconds: _intValue(json['durationSeconds']),
      distanceMeters: _doubleValue(json['distanceMeters']),
    );
  }

  final String provider;
  final List<RoutePointVm> orderedStops;
  final RouteResponseVm route;
  final int durationSeconds;
  final double distanceMeters;
}

class MapMatchResponseVm {
  const MapMatchResponseVm({required this.provider, required this.route});

  factory MapMatchResponseVm.fromJson(Map<String, dynamic> json) {
    return MapMatchResponseVm(
      provider: (json['provider'] as String? ?? '').trim(),
      route: RouteResponseVm.fromJson(
        (json['route'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  final String provider;
  final RouteResponseVm route;
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _intValue(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _stringOrNull(Object? value) {
  final string = (value as String? ?? '').trim();
  return string.isEmpty ? null : string;
}

bool _sameRoutePoint(RoutePointVm a, RoutePointVm b) {
  return (a.latitude - b.latitude).abs() < 0.0000001 &&
      (a.longitude - b.longitude).abs() < 0.0000001;
}

List<RoutePointVm> _decodePolyline(String encoded, {required int precision}) {
  final factor = precision == 6 ? 1000000.0 : 100000.0;
  final points = <RoutePointVm>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  while (index < encoded.length) {
    final decodedLatitude = _readPolylineValue(encoded, index);
    if (decodedLatitude == null) {
      return const [];
    }
    index = decodedLatitude.nextIndex;
    latitude += decodedLatitude.delta;

    final decodedLongitude = _readPolylineValue(encoded, index);
    if (decodedLongitude == null) {
      return const [];
    }
    index = decodedLongitude.nextIndex;
    longitude += decodedLongitude.delta;

    points.add(
      RoutePointVm(latitude: latitude / factor, longitude: longitude / factor),
    );
  }

  return points;
}

({int delta, int nextIndex})? _readPolylineValue(String encoded, int start) {
  var result = 0;
  var shift = 0;
  var index = start;

  while (index < encoded.length) {
    final byte = encoded.codeUnitAt(index) - 63;
    if (byte < 0) {
      return null;
    }
    index += 1;
    result |= (byte & 0x1F) << shift;

    if (byte < 0x20) {
      final delta = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
      return (delta: delta, nextIndex: index);
    }

    shift += 5;
    if (shift > 30) {
      return null;
    }
  }

  return null;
}
