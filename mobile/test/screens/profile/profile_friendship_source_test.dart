import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foreign profile keeps follow and friendship actions separate',
      () async {
    final profileSource = await File(
      'lib/screens/profile/profile_screen.dart',
    ).readAsString();
    final apiSource = await File(
      'lib/features/profile/data/profile_api.dart',
    ).readAsString();
    final clientSource = await File(
      'lib/core/network/api_client.dart',
    ).readAsString();

    expect(profileSource, contains('_profileWithRelationshipOverrides'));
    expect(profileSource, contains('_handleFriendshipAction'));
    expect(profileSource, contains('isFriendshipActionLoading'));
    expect(
        profileSource, contains('friendshipStatus: profile.friendshipStatus'));
    expect(profileSource, contains('profileAddFriendAction'));
    expect(profileSource, contains('profileFriendRequestSentAction'));
    expect(profileSource, contains('profileAcceptFriendAction'));
    expect(profileSource, contains('profileDeclineFriendAction'));
    expect(profileSource, contains('profileFriendRequestTitle'));
    expect(profileSource, contains('_incomingFriendRequestSection'));
    expect(profileSource, contains('_handleDeclineFriendRequest'));
    expect(profileSource, contains('onDeclineFriendship'));
    expect(profileSource, contains('profileRemoveFriendAction'));
    expect(profileSource, contains('_confirmRemoveFriend'));
    expect(profileSource, contains('profileRemoveFriendConfirm'));
    expect(profileSource, contains('_confirmUnfollowUser'));
    expect(profileSource, contains('profileUnfollowTitle'));
    expect(profileSource, contains('profileUnfollowDescription'));
    expect(profileSource, contains('profileUnfollowConfirm'));
    expect(profileSource, contains('_ProfileRelationshipConfirmDialog'));
    expect(profileSource, contains('_showRelationshipConfirmDialog'));
    expect(profileSource, contains('_ActivitiesStyleConfirmAction'));
    expect(profileSource, contains('Color(0xFF2B1808)'));
    expect(profileSource, contains('Color(0xFF201208)'));
    expect(profileSource, contains('_secondaryActionRow'));
    expect(profileSource, contains('Wrap('));
    expect(profileSource, contains('runSpacing:'));
    expect(profileSource, contains('constraints.maxWidth < 360'));
    expect(profileSource, contains('AppColors.destruct'));
    expect(
        profileSource, contains('_outlinedActionStyle(context, accent: true)'));
    expect(profileSource, isNot(contains('profileFriendsAction')));

    expect(apiSource, contains('sendFriendRequest'));
    expect(apiSource, contains('cancelFriendRequest'));
    expect(apiSource, contains('declineFriendRequest'));
    expect(apiSource, contains('_apiClient.declineFriendRequest'));
    expect(apiSource, contains('acceptFriendRequest'));
    expect(apiSource, contains('removeFriend'));

    expect(clientSource, contains(r"'/users/$userId/friend-request'"));
    expect(clientSource, contains('declineFriendRequest'));
    expect(clientSource, contains(r"'/users/$userId/friendship'"));
  });
}
