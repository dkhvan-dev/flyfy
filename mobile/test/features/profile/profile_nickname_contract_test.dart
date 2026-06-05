import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/profile/models/update_profile_request.dart';
import 'package:inflap/features/profile/models/user_profile_vm.dart';

void main() {
  test('update profile request sends nickname contract only', () {
    final json = UpdateProfileRequest(
      firstName: 'Aruzhan',
      lastName: 'T.',
      nickname: '@nomad_aru',
    ).toJson();

    expect(json['nickname'], '@nomad_aru');
    expect(json.containsKey('displayName'), isFalse);
  });

  test('user profile view model reads nickname contract only', () {
    final profile = UserProfileVm.fromJson({
      'user': {'id': 'user-1', 'status': 'ACTIVE'},
      'profile': {
        'nickname': '@nomad_aru',
        'locale': 'ru',
        'timezone': 'Asia/Almaty',
        'isProfileCompleted': true,
      },
      'roles': <String>[],
      'followers': {'count': 0, 'isFollowedByMe': false},
      'friendship': {'status': 'NONE'},
    });

    expect(profile.nickname, '@nomad_aru');
    expect(profile.preferredName, '@nomad_aru');
  });
}
