import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/features/profile/models/user_profile_vm.dart';

void main() {
  Map<String, dynamic> profileJson({Map<String, dynamic>? friendship}) {
    return <String, dynamic>{
      'user': <String, dynamic>{'id': 'user-1', 'status': 'ACTIVE'},
      'profile': <String, dynamic>{
        'locale': 'ru',
        'timezone': 'Asia/Almaty',
        'isProfileCompleted': true,
      },
      'roles': <String>[],
      'followers': <String, dynamic>{
        'count': 0,
        'isFollowedByMe': false,
      },
      if (friendship != null) 'friendship': friendship,
    };
  }

  test('defaults friendship status to none when backend omits block', () {
    final profile = UserProfileVm.fromJson(profileJson());

    expect(profile.friendshipStatus, UserFriendshipStatus.none);
  });

  test('parses viewer-relative friendship status from backend response', () {
    final profile = UserProfileVm.fromJson(
      profileJson(
        friendship: <String, dynamic>{
          'status': 'INCOMING_REQUEST',
        },
      ),
    );

    expect(profile.friendshipStatus, UserFriendshipStatus.incomingRequest);
    expect(
      profile
          .copyWith(friendshipStatus: UserFriendshipStatus.friends)
          .friendshipStatus,
      UserFriendshipStatus.friends,
    );
  });
}
