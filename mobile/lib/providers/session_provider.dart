import 'package:flutter/foundation.dart';

import '../core/storage/secure_storage.dart';
import '../features/profile/data/profile_api.dart';
import '../features/profile/models/user_profile_vm.dart';

enum SessionStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    SecureStorage? secureStorage,
    ProfileApi? profileApi,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _profileApi = profileApi ?? ProfileApi();

  final SecureStorage _secureStorage;
  final ProfileApi _profileApi;

  SessionStatus _status = SessionStatus.initial;
  UserProfileVm? _profile;

  SessionStatus get status => _status;
  UserProfileVm? get profile => _profile;

  bool get isAuthenticated => _status == SessionStatus.authenticated;
  bool get isLoading => _status == SessionStatus.loading;

  Future<void> restoreSession() async {
    _status = SessionStatus.loading;
    notifyListeners();

    try {
        final token = await _secureStorage.getAccessToken();
        if (token == null || token.isEmpty) {
        _profile = null;
        _status = SessionStatus.unauthenticated;
        notifyListeners();
        return;
        }

        _profile = await _profileApi.getOrInitMe();
        _status = SessionStatus.authenticated;
        notifyListeners();
    } catch (_) {
        _profile = null;
        _status = SessionStatus.unauthenticated;
        notifyListeners();
    }
    }

  Future<void> reloadProfile() async {
    if (!isAuthenticated) return;

    try {
      _profile = await _profileApi.getMe();
      notifyListeners();
    } catch (_) {
      // ignore soft reload failure
    }
  }

  Future<void> clearSession() async {
    _profile = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}