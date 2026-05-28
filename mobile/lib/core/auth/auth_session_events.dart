import 'dart:async';

class AuthSessionEvents {
  AuthSessionEvents();

  static final AuthSessionEvents instance = AuthSessionEvents();

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast(sync: true);

  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  void notifySessionExpired() {
    if (_sessionExpiredController.isClosed) return;
    _sessionExpiredController.add(null);
  }

  Future<void> dispose() async {
    await _sessionExpiredController.close();
  }
}
