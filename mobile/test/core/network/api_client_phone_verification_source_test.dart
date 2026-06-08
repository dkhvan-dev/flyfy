import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'api client exposes authenticated profile phone verification endpoints',
    () async {
      final source = await File(
        'lib/core/network/api_client.dart',
      ).readAsString();

      expect(source, contains('startProfilePhoneVerification'));
      expect(source, contains('verifyProfilePhoneVerification'));
      expect(source, contains('resendProfilePhoneVerification'));
      expect(source, contains('cancelPendingProfilePhoneVerification'));
      expect(source, contains('/users/me/phone/verification/start'));
      expect(source, contains('/users/me/phone/verification/verify'));
      expect(source, contains('/users/me/phone/verification/resend'));
      expect(source, contains('/users/me/phone/pending'));
    },
  );
}
