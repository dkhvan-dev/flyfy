import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'profile connections screen uses excursions search filter and sort chrome',
      () async {
    final source = await File(
      'lib/screens/profile/profile_connections_screen.dart',
    ).readAsString();

    expect(source, contains('class ProfileConnectionsScreen'));
    expect(source, contains('AppListSearchField('));
    expect(source, contains('AppInlineSortRow<_ConnectionSortMode>'));
    expect(source, contains('AppFilterSheetHeader('));
    expect(source, contains('AppFilterApplyButton('));
    expect(source, contains('showModalBottomSheet<_ConnectionFilters>'));
    expect(source, contains('TabBar('));
    expect(source, contains('TabBarView('));
    expect(source, isNot(contains('_ConnectionSortMode.online')));
    expect(source, isNot(contains('profileConnectionsSortOnline')));
  });

  test('profile connections support paginated friends and following actions',
      () async {
    final source = await File(
      'lib/screens/profile/profile_connections_screen.dart',
    ).readAsString();
    final apiClientSource =
        await File('lib/core/network/api_client.dart').readAsString();
    final profileApiSource = await File(
      'lib/features/profile/data/profile_api.dart',
    ).readAsString();
    final routerSource =
        await File('lib/core/router/app_router.dart').readAsString();
    final profileSource =
        await File('lib/screens/profile/profile_screen.dart').readAsString();

    expect(source, contains('getMyFriends('));
    expect(source, contains('getMyFollowing('));
    expect(source, contains('showMenu<_ConnectionAction>'));
    expect(source, contains('IconButton('));
    expect(source, contains('Icons.more_horiz_rounded'));
    expect(source, contains('onActionsTap: (buttonContext) =>'));
    expect(source, contains('buttonBox.localToGlobal('));
    expect(source, isNot(contains('onLongPress')));
    expect(source, contains('removeFriend(user.userId)'));
    expect(source, contains('unfollowUser(user.userId)'));
    expect(source, contains('createDirectConversation(user.userId)'));
    expect(source, contains("context.push('/users/"));
    expect(source, contains("context.push('/chats/"));

    expect(apiClientSource, contains("'/users/me/friends'"));
    expect(apiClientSource, contains("'/users/me/following'"));
    expect(apiClientSource, contains("'sortDirection': sortDirection"));
    expect(apiClientSource, contains("'onlineOnly': true"));
    expect(profileApiSource,
        contains('Future<ProfileFollowersPageVm> getMyFriends'));
    expect(profileApiSource,
        contains('Future<ProfileFollowersPageVm> getMyFollowing'));
    expect(routerSource, contains("path: '/profile/connections'"));
    expect(profileSource, contains("context.push('/profile/connections')"));
  });
}
