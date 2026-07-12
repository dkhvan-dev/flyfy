import 'package:flutter/foundation.dart';

import '../data/trust_access_api.dart';

enum TrustCapability {
  createPost,
  createActivity,
  publishTour,
  sendChatMessage,
  uploadFile,
  requestPayout,
  submitGuideApplication,
}

enum TrustAccessState { initial, loading, ready, error }

class TrustAccessProvider extends ChangeNotifier {
  TrustAccessProvider({TrustAccessApi? api, Duration? refreshInterval})
    : _api = api ?? GatewayTrustAccessApi(),
      _refreshInterval = refreshInterval ?? const Duration(minutes: 1);

  final TrustAccessApi _api;
  final Duration _refreshInterval;

  TrustAccessState _state = TrustAccessState.initial;
  TrustAccessSnapshot? _snapshot;
  DateTime? _lastLoadedAt;
  Future<void>? _refreshFuture;
  bool _forceRefreshQueued = false;
  int _generation = 0;

  TrustAccessState get state => _state;
  TrustAccessSnapshot? get snapshot => _snapshot;
  List<TrustActiveRestriction> get activeRestrictions =>
      _snapshot?.activeRestrictions ?? const [];

  bool isRestricted(TrustCapability capability) {
    final codes = activeRestrictions.map((item) => item.code).toSet();
    if (codes.contains(TrustRestrictionCode.accountSuspension)) return true;
    return switch (capability) {
      TrustCapability.createPost => false,
      TrustCapability.createActivity => codes.contains(
        TrustRestrictionCode.activityCreation,
      ),
      TrustCapability.publishTour => codes.contains(
        TrustRestrictionCode.tourPublishing,
      ),
      TrustCapability.sendChatMessage => codes.contains(
        TrustRestrictionCode.chat,
      ),
      TrustCapability.uploadFile => codes.contains(
        TrustRestrictionCode.fileUpload,
      ),
      TrustCapability.requestPayout => codes.contains(
        TrustRestrictionCode.payout,
      ),
      TrustCapability.submitGuideApplication => codes.contains(
        TrustRestrictionCode.guideApplication,
      ),
    };
  }

  Future<void> refresh({bool force = false}) {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      if (force) _forceRefreshQueued = true;
      return inFlight;
    }
    final lastLoadedAt = _lastLoadedAt;
    if (!force &&
        lastLoadedAt != null &&
        DateTime.now().toUtc().difference(lastLoadedAt) < _refreshInterval) {
      return Future.value();
    }

    final next = _runRefreshLoop();
    _refreshFuture = next.whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<void> _runRefreshLoop() async {
    do {
      _forceRefreshQueued = false;
      await _refresh();
    } while (_forceRefreshQueued);
  }

  Future<void> _refresh() async {
    final generation = _generation;
    if (_snapshot == null) {
      _state = TrustAccessState.loading;
      notifyListeners();
    }
    try {
      final snapshot = await _api.getMyTrustAccess();
      if (generation != _generation) return;
      _snapshot = snapshot;
      _lastLoadedAt = DateTime.now().toUtc();
      _state = TrustAccessState.ready;
      notifyListeners();
    } catch (_) {
      if (generation != _generation) return;
      _state = TrustAccessState.error;
      notifyListeners();
    }
  }

  Future<void> handlePushData(Map<String, Object?> data) async {
    final event = (data['adminEvent'] ?? '').toString().trim().toLowerCase();
    if (event == 'user_restriction_created' ||
        event == 'user_restriction_lifted' ||
        event == 'user_restriction_removed' ||
        event == 'user_suspended' ||
        event == 'user_permanently_blocked') {
      await refresh(force: true);
    }
  }

  void clear() {
    _generation += 1;
    _forceRefreshQueued = false;
    _snapshot = null;
    _lastLoadedAt = null;
    _state = TrustAccessState.initial;
    notifyListeners();
  }
}
