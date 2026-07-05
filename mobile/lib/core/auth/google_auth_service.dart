import 'package:google_sign_in/google_sign_in.dart';

abstract interface class GoogleAuthTokenProvider {
  Future<String?> requestIdToken();
}

final class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1074367607068-o73jd816mvfu1c295a6034cntem3ug6f.apps.googleusercontent.com',
  );

  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '1074367607068-8j0h6fpqvavv9t9ftahn9fi3dqj6uq8t.apps.googleusercontent.com',
  );
}

final class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => 'GoogleAuthException: $message';
}

final class GoogleAuthSignInAccount {
  const GoogleAuthSignInAccount({required this.idToken});

  final String? idToken;
}

abstract interface class GoogleSignInGateway {
  Future<void> initialize({String? clientId, required String serverClientId});

  bool supportsAuthenticate();

  Future<GoogleAuthSignInAccount?> authenticate();
}

final class GoogleSignInPluginGateway implements GoogleSignInGateway {
  @override
  Future<void> initialize({String? clientId, required String serverClientId}) {
    return GoogleSignIn.instance.initialize(
      clientId: _emptyToNull(clientId),
      serverClientId: serverClientId,
    );
  }

  @override
  bool supportsAuthenticate() {
    return GoogleSignIn.instance.supportsAuthenticate();
  }

  @override
  Future<GoogleAuthSignInAccount?> authenticate() async {
    final account = await GoogleSignIn.instance.authenticate();
    return GoogleAuthSignInAccount(idToken: account.authentication.idToken);
  }
}

final class GoogleAuthService implements GoogleAuthTokenProvider {
  GoogleAuthService({GoogleSignInGateway? gateway})
    : _gateway = gateway ?? GoogleSignInPluginGateway();

  final GoogleSignInGateway _gateway;
  Future<void>? _initializeFuture;

  @override
  Future<String?> requestIdToken() async {
    final serverClientId = GoogleAuthConfig.serverClientId.trim();
    if (serverClientId.isEmpty) {
      throw const GoogleAuthException(
        'Google server client ID is not configured.',
      );
    }

    await _ensureInitialized(serverClientId);

    if (!_gateway.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Google Sign-In is not available on this platform.',
      );
    }

    final account = await _authenticate();
    if (account == null) return null;

    final idToken = account.idToken?.trim();
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleAuthException('Google did not return an ID token.');
    }

    return idToken;
  }

  Future<void> _ensureInitialized(String serverClientId) {
    return _initializeFuture ??= _gateway.initialize(
      clientId: GoogleAuthConfig.iosClientId,
      serverClientId: serverClientId,
    );
  }

  Future<GoogleAuthSignInAccount?> _authenticate() async {
    try {
      return await _gateway.authenticate();
    } on GoogleSignInException catch (error) {
      if (_isUserCancellation(error.code)) {
        return null;
      }

      final description = error.description?.trim();
      throw GoogleAuthException(
        description == null || description.isEmpty
            ? 'Google Sign-In failed.'
            : description,
      );
    }
  }

  bool _isUserCancellation(GoogleSignInExceptionCode code) {
    return code == GoogleSignInExceptionCode.canceled ||
        code == GoogleSignInExceptionCode.interrupted;
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
