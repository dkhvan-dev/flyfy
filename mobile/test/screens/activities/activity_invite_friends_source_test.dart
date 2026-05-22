import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity details participants sheet can invite friends', () async {
    final detailsSource = await File(
      'lib/screens/activities/activity_details_screen.dart',
    ).readAsString();
    final activityApiSource = await File(
      'lib/core/network/activity_api.dart',
    ).readAsString();
    final l10nSource = await File('lib/l10n/app_ru.arb').readAsString();

    expect(detailsSource, contains('_showInviteFriendsSheet'));
    expect(detailsSource, contains('getMyFriends('));
    expect(detailsSource, contains('inviteFriends('));
    expect(detailsSource, contains('activityInviteFriendsButton'));
    expect(detailsSource, contains('activityInviteFriendsSend'));
    expect(detailsSource, contains('Set<String> _invitedFriendIds'));
    expect(detailsSource, contains('AppFilterApplyButton('));

    expect(activityApiSource, contains('Future<void> inviteFriends'));
    expect(
      activityApiSource,
      contains("'/activities/\$activityId/participants/invite-friends'"),
    );
    expect(activityApiSource, contains("'userIds': userIds"));

    expect(l10nSource, contains('activityInviteFriendsButton'));
    expect(l10nSource, contains('activityInviteFriendsSuccess'));
  });
}
