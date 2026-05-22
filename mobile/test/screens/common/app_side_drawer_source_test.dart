import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drawer header does not show location under logged-in nickname',
      () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final menuStart = source.indexOf('_DrawerMenuItem(', drawerStart);

    expect(drawerStart, isNonNegative);
    expect(menuStart, greaterThan(drawerStart));

    final headerSource = source.substring(drawerStart, menuStart);

    expect(
      headerSource,
      isNot(contains('final profileSubtitle = isLoggedIn ? location')),
    );
    expect(
        headerSource,
        isNot(contains(
            'Text(\n                                              profileSubtitle')));
    expect(headerSource, contains('if (!isLoggedIn) ...['));
    expect(headerSource, contains('l10n.homeSubtitle'));
  });

  test('drawer header shows localized identity status for logged-in users',
      () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final menuStart = source.indexOf('_DrawerMenuItem(', drawerStart);

    expect(drawerStart, isNonNegative);
    expect(menuStart, greaterThan(drawerStart));

    final headerSource = source.substring(drawerStart, menuStart);

    expect(source, contains('String resolveDrawerIdentityStatus({'));
    expect(source, contains('l10n.drawerStatusVerifiedGuide'));
    expect(source, contains('l10n.drawerStatusGuide'));
    expect(source, contains('l10n.drawerStatusTraveler'));
    expect(source, contains('l10n.drawerStatusCompleteProfile'));
    expect(headerSource, contains('final identityStatus ='));
    expect(headerSource, contains('resolveDrawerIdentityStatus('));
    expect(source, contains('showGuideBadge'));
    expect(source, contains('profile?.isGuide'));
    expect(source, contains('profile?.isProfileCompleted'));
    expect(headerSource, contains('identityStatus'));
  });

  test('drawer identity status badge is rendered below nickname', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final menuStart = source.indexOf('_DrawerMenuItem(', drawerStart);

    expect(drawerStart, isNonNegative);
    expect(menuStart, greaterThan(drawerStart));

    final headerSource = source.substring(drawerStart, menuStart);
    final profileColumnStart = headerSource.indexOf(
      'Expanded(\n                                        child: Column(',
    );
    final profileColumnEnd = headerSource.indexOf(
      'SizedBox(width: layout.trailingGap)',
      profileColumnStart,
    );

    expect(profileColumnStart, isNonNegative);
    expect(profileColumnEnd, greaterThan(profileColumnStart));

    final profileColumnSource = headerSource.substring(
      profileColumnStart,
      profileColumnEnd,
    );
    final nicknameIndex = profileColumnSource.indexOf('profileTitle,');
    final badgeIndex = profileColumnSource.indexOf('identityStatus,');

    expect(nicknameIndex, isNonNegative);
    expect(badgeIndex, isNonNegative);
    expect(badgeIndex, greaterThan(nicknameIndex));
  });
}
