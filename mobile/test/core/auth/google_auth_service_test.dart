import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/auth/google_auth_service.dart';

void main() {
  test(
    'requests a Google ID token for the configured backend audience',
    () async {
      final gateway = _FakeGoogleSignInGateway(
        account: const GoogleAuthSignInAccount(idToken: 'real-google-id-token'),
      );
      final service = GoogleAuthService(gateway: gateway);

      final idToken = await service.requestIdToken();

      expect(idToken, 'real-google-id-token');
      expect(
        gateway.initializedServerClientId,
        GoogleAuthConfig.serverClientId,
      );
      expect(gateway.initializedIosClientId, GoogleAuthConfig.iosClientId);
      expect(gateway.authenticateCallCount, 1);
    },
  );

  test('rejects Google sign-in when no ID token is returned', () async {
    final service = GoogleAuthService(
      gateway: _FakeGoogleSignInGateway(
        account: const GoogleAuthSignInAccount(idToken: ''),
      ),
    );

    expect(service.requestIdToken, throwsA(isA<GoogleAuthException>()));
  });
}

final class _FakeGoogleSignInGateway implements GoogleSignInGateway {
  _FakeGoogleSignInGateway({required this.account});

  final GoogleAuthSignInAccount? account;

  String? initializedIosClientId;
  String? initializedServerClientId;
  int authenticateCallCount = 0;

  @override
  Future<void> initialize({
    String? clientId,
    required String serverClientId,
  }) async {
    initializedIosClientId = clientId;
    initializedServerClientId = serverClientId;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<GoogleAuthSignInAccount?> authenticate() async {
    authenticateCallCount += 1;
    return account;
  }
}
