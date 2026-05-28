import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/auth/auth_session_events.dart';
import 'package:superapp/core/network/api_client.dart';
import 'package:superapp/core/storage/secure_storage.dart';
import 'package:superapp/features/profile/data/profile_api.dart';
import 'package:superapp/features/profile/models/user_profile_vm.dart';
import 'package:superapp/providers/auth_provider.dart';
import 'package:superapp/providers/session_provider.dart';

void main() {
  test('AuthProvider marks user unauthenticated when session expires',
      () async {
    final events = AuthSessionEvents();
    final storage = _MemorySecureStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final provider = AuthProvider(
      apiClient: ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1')),
        secureStorage: storage,
        authSessionEvents: events,
      ),
      secureStorage: storage,
      authSessionEvents: events,
    );

    await provider.checkAuthStatus();
    expect(provider.state, AuthState.authenticated);

    events.notifySessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(provider.state, AuthState.unauthenticated);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    provider.dispose();
  });

  test('SessionProvider clears cached profile when session expires', () async {
    final events = AuthSessionEvents();
    final provider = SessionProvider(
      secureStorage: _MemorySecureStorage(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
      profileApi: _FakeProfileApi(),
      authSessionEvents: events,
    );

    await provider.restoreSession();
    expect(provider.status, SessionStatus.authenticated);
    expect(provider.profile?.userId, 'user-1');

    events.notifySessionExpired();
    await Future<void>.delayed(Duration.zero);

    expect(provider.status, SessionStatus.unauthenticated);
    expect(provider.profile, isNull);
    provider.dispose();
  });
}

class _MemorySecureStorage extends SecureStorage {
  _MemorySecureStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> deleteTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeProfileApi extends ProfileApi {
  _FakeProfileApi()
      : super(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1')),
          ),
        );

  @override
  Future<UserProfileVm> getOrInitMe({
    String? primaryPhoneHint,
    String? primaryEmailHint,
  }) async {
    return _profile();
  }

  @override
  Future<UserProfileVm> getMe() async => _profile();

  UserProfileVm _profile() {
    return UserProfileVm(
      userId: 'user-1',
      status: 'ACTIVE',
      locale: 'ru',
      timezone: 'Asia/Almaty',
      isProfileCompleted: true,
      roles: const [],
      followersCount: 0,
      isFollowedByMe: false,
      friendshipStatus: UserFriendshipStatus.none,
      displayName: 'Test User',
    );
  }
}
