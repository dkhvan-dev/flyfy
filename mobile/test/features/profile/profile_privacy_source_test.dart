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
}
