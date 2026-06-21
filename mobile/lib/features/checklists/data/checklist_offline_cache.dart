import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_checklist_vm.dart';
import '../models/travel_checklist_route_args.dart';

class CachedTravelChecklistEntry {
  const CachedTravelChecklistEntry({
    required this.routeArgs,
    required this.savedAt,
    required this.readinessScore,
    required this.readinessStatus,
    required this.itemCount,
  });

  final TravelChecklistRouteArgs routeArgs;
  final DateTime savedAt;
  final int readinessScore;
  final String readinessStatus;
  final int itemCount;

  factory CachedTravelChecklistEntry.fromJson(Map<String, dynamic> json) {
    final routeArgs = json['routeArgs'];
    return CachedTravelChecklistEntry(
      routeArgs: routeArgs is Map
          ? TravelChecklistRouteArgs.fromJson(
              Map<String, dynamic>.from(routeArgs),
            )
          : TravelChecklistRouteArgs.fromJson(const <String, dynamic>{}),
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      readinessScore:
          int.tryParse(json['readinessScore']?.toString() ?? '') ?? 0,
      readinessStatus: json['readinessStatus']?.toString() ?? '',
      itemCount: int.tryParse(json['itemCount']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'tripId': routeArgs.normalizedTripId,
      'savedAt': savedAt.toUtc().toIso8601String(),
      'routeArgs': routeArgs.toJson(),
      'readinessScore': readinessScore,
      'readinessStatus': readinessStatus,
      'itemCount': itemCount,
    };
  }
}

class ChecklistOfflineCache {
  ChecklistOfflineCache({Future<SharedPreferences> Function()? prefsProvider})
    : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static const _keyPrefix = 'inflap.checklists.trip.';
  static const _indexKey = 'inflap.checklists.trip.index';
  static const _schemaVersion = 1;
  static const _maxIndexedChecklists = 50;

  final Future<SharedPreferences> Function() _prefsProvider;

  Future<TripChecklistVm?> readTripChecklist(String tripId) async {
    final storageKey = _storageKey(tripId);
    if (storageKey == null) return null;

    try {
      final prefs = await _prefsProvider();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final checklist = decoded['checklist'];
      if (checklist is! Map<String, dynamic>) return null;

      return TripChecklistVm.fromJson(checklist);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTripChecklist(
    String tripId,
    TripChecklistVm checklist, {
    TravelChecklistRouteArgs? routeArgs,
  }) async {
    final storageKey = _storageKey(tripId);
    if (storageKey == null) return;

    final prefs = await _prefsProvider();
    final savedAt = DateTime.now().toUtc();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'savedAt': savedAt.toIso8601String(),
        'checklist': checklist.toJson(),
      }),
    );

    if (routeArgs != null) {
      await _upsertChecklistIndex(
        prefs: prefs,
        entry: CachedTravelChecklistEntry(
          routeArgs: routeArgs,
          savedAt: savedAt,
          readinessScore: checklist.readiness.score,
          readinessStatus: _readinessStatusValue(checklist.readiness.status),
          itemCount: checklist.items.length,
        ),
      );
    }
  }

  Future<List<CachedTravelChecklistEntry>> listTripChecklistEntries() async {
    try {
      final prefs = await _prefsProvider();
      final entries = _readChecklistIndex(prefs);
      return entries
          .where((entry) => entry.routeArgs.normalizedTripId.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> replaceTripChecklistEntries(
    Iterable<CachedTravelChecklistEntry> entries,
  ) async {
    try {
      final normalizedEntries =
          entries
              .where(
                (entry) => entry.routeArgs.normalizedTripId.trim().isNotEmpty,
              )
              .toList(growable: false)
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final prefs = await _prefsProvider();
      await prefs.setString(
        _indexKey,
        jsonEncode({
          'schemaVersion': _schemaVersion,
          'items': normalizedEntries
              .take(_maxIndexedChecklists)
              .map((entry) => entry.toJson())
              .toList(growable: false),
        }),
      );
    } catch (_) {
      return;
    }
  }

  Future<void> removeTripChecklist(String tripId) async {
    final storageKey = _storageKey(tripId);
    if (storageKey == null) return;

    try {
      final prefs = await _prefsProvider();
      await prefs.remove(storageKey);
      await _removeChecklistIndexEntry(prefs: prefs, tripId: tripId);
    } catch (_) {
      return;
    }
  }

  String? _storageKey(String tripId) {
    final normalized = tripId.trim();
    if (normalized.isEmpty) return null;
    return '$_keyPrefix${base64UrlEncode(utf8.encode(normalized))}';
  }

  List<CachedTravelChecklistEntry> _readChecklistIndex(
    SharedPreferences prefs,
  ) {
    final raw = prefs.getString(_indexKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];

    final items = decoded['items'];
    if (items is! List) return const [];

    final entries = <CachedTravelChecklistEntry>[];
    for (final item in items) {
      if (item is! Map) continue;
      try {
        entries.add(
          CachedTravelChecklistEntry.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (_) {
        continue;
      }
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries;
  }

  Future<void> _upsertChecklistIndex({
    required SharedPreferences prefs,
    required CachedTravelChecklistEntry entry,
  }) async {
    final entries = _readChecklistIndex(prefs)
        .where(
          (candidate) =>
              candidate.routeArgs.normalizedTripId !=
              entry.routeArgs.normalizedTripId,
        )
        .toList();
    entries.insert(0, entry);

    await prefs.setString(
      _indexKey,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'items': entries
            .take(_maxIndexedChecklists)
            .map((entry) => entry.toJson())
            .toList(growable: false),
      }),
    );
  }

  Future<void> _removeChecklistIndexEntry({
    required SharedPreferences prefs,
    required String tripId,
  }) async {
    final normalizedTripId = tripId.trim();
    if (normalizedTripId.isEmpty) return;

    final entries = _readChecklistIndex(prefs)
        .where(
          (candidate) =>
              candidate.routeArgs.normalizedTripId != normalizedTripId,
        )
        .toList(growable: false);

    await prefs.setString(
      _indexKey,
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'items': entries.map((entry) => entry.toJson()).toList(growable: false),
      }),
    );
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
