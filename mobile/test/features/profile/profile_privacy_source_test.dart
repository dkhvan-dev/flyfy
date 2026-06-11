import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile editing no longer exposes or sends visibility', () async {
    final editProfileSource = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final updateRequestSource = await File(
      'lib/features/profile/models/update_profile_request.dart',
    ).readAsString();
    final profileModelSource = await File(
      'lib/features/profile/models/user_profile_vm.dart',
    ).readAsString();

    expect(editProfileSource, isNot(contains('_isPublic')));
    expect(editProfileSource, isNot(contains('_VisibilityToggleRow')));
    expect(updateRequestSource, isNot(contains('isPublic')));
    expect(profileModelSource, isNot(contains('isPublic')));
  });

  test('profile editing does not render app language picker', () async {
    final editProfileSource = await File(
      'lib/screens/profile/edit_profile_screen.dart',
    ).readAsString();
    final detailsStart = editProfileSource.indexOf(
      'title: l10n.profileSettingsDetailsSection',
    );
    final detailsEnd = editProfileSource.indexOf(
      '_buildPhoneVerificationSection(profile, l10n)',
      detailsStart,
    );

    expect(detailsStart, isNonNegative);
    expect(detailsEnd, greaterThan(detailsStart));

    final detailsSource = editProfileSource.substring(detailsStart, detailsEnd);

    expect(detailsSource, isNot(contains('l10n.appLanguageTitle')));
    expect(detailsSource, isNot(contains('DropdownButtonFormField<String>')));
    expect(detailsSource, isNot(contains("DropdownMenuItem(value: 'ru'")));
    expect(detailsSource, isNot(contains("DropdownMenuItem(value: 'en'")));
    expect(detailsSource, isNot(contains("DropdownMenuItem(value: 'kk'")));
  });
}
