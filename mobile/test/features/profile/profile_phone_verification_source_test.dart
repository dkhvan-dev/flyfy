import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit profile exposes verified phone flow with resend cooldown', () {
    final editProfileSource = File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsStringSync();
    final profileApiSource = File(
      'lib/features/profile/data/profile_api.dart',
    ).readAsStringSync();
    final profileVmSource = File(
      'lib/features/profile/models/user_profile_vm.dart',
    ).readAsStringSync();

    expect(profileApiSource, contains('startPhoneVerification'));
    expect(profileApiSource, contains('verifyPhoneVerification'));
    expect(profileApiSource, contains('resendPhoneVerification'));
    expect(profileApiSource, contains('cancelPendingPhoneVerification'));

    expect(profileVmSource, contains('primaryPhoneMasked'));
    expect(profileVmSource, contains('primaryPhoneVerified'));
    expect(profileVmSource, contains('primaryPhoneVerifiedAt'));

    expect(editProfileSource, contains('_phoneController'));
    expect(editProfileSource, contains('_phoneCodeController'));
    expect(editProfileSource, contains('_initialPhoneInputText(profile)'));
    expect(editProfileSource, contains('_handlePhoneChanged'));
    expect(editProfileSource, contains('_ensurePhonePlusPrefix'));
    expect(editProfileSource, contains('_phoneVerificationChallengeId'));
    expect(editProfileSource, contains('_phoneResendSecondsRemaining'));
    expect(editProfileSource, contains('_isChangingVerifiedPhone'));
    expect(editProfileSource, contains('_startVerifiedPhoneChange'));
    expect(editProfileSource, contains('_cancelVerifiedPhoneChange'));
    expect(editProfileSource, contains('_phoneChangeActionStyle'));
    expect(
      editProfileSource,
      contains('foregroundColor: _EditProfileColors.of(context).primary'),
    );
    expect(editProfileSource, contains('padding: AppEdgeInsets.zero'));
    expect(editProfileSource, contains('alignment: Alignment.centerLeft'));
    expect(
      editProfileSource,
      contains('phone is already verified for this account'),
    );
    expect(editProfileSource, contains('profilePhoneAlreadyVerified'));
    expect(editProfileSource, contains('_startPhoneResendCountdown'));
    expect(editProfileSource, contains('_startPhoneVerification'));
    expect(editProfileSource, contains('_verifyPhoneVerification'));
    expect(editProfileSource, contains('reloadProfile()'));
    expect(editProfileSource, contains('profilePhoneVerificationSection'));
    expect(editProfileSource, contains('profilePhoneCurrentVerifiedAs'));
    expect(editProfileSource, contains('profilePhoneCancelChange'));
    expect(editProfileSource, contains('TextInputType.phone'));
  });
}
