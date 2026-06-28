import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drawer pins footer while only the menu section scrolls', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final helpersStart = source.indexOf('class _DrawerPinnedFooter');

    expect(drawerStart, isNonNegative);
    expect(helpersStart, greaterThan(drawerStart));

    final drawerSource = source.substring(drawerStart, helpersStart);

    expect(drawerSource, contains('Expanded('));
    expect(drawerSource, contains('SingleChildScrollView('));
    expect(drawerSource, contains('_DrawerPinnedFooter('));
    expect(drawerSource, isNot(contains('CustomScrollView(')));
    expect(drawerSource, isNot(contains('SliverFillRemaining(')));
  });

  test('drawer header does not show location under logged-in nickname', () async {
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
      isNot(
        contains(
          'Text(\n                                              profileSubtitle',
        ),
      ),
    );
    expect(headerSource, contains('if (!isLoggedIn) ...['));
    expect(headerSource, contains('l10n.homeSubtitle'));
  });

  test(
    'drawer header shows localized identity status for logged-in users',
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
    },
  );

  test('drawer profile header exposes a semantic button target', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final menuStart = source.indexOf('_DrawerMenuItem(', drawerStart);

    expect(drawerStart, isNonNegative);
    expect(menuStart, greaterThan(drawerStart));

    final headerSource = source.substring(drawerStart, menuStart);

    expect(headerSource, contains('final headerSemanticLabel ='));
    expect(headerSource, contains('Semantics('));
    expect(headerSource, contains('button: true'));
    expect(headerSource, contains('enabled: true'));
    expect(headerSource, contains('label: headerSemanticLabel'));
    expect(headerSource, contains('ExcludeSemantics('));
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
    final nicknameIndex = headerSource.indexOf('profileTitle,');
    final badgeIndex = headerSource.indexOf('identityStatus,');

    expect(nicknameIndex, isNonNegative);
    expect(badgeIndex, isNonNegative);
    expect(badgeIndex, greaterThan(nicknameIndex));
  });

  test('drawer login footer action keeps accent icon readable', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();
    final actionStart = source.indexOf('class _DrawerFooterAction');

    expect(actionStart, isNonNegative);

    final actionSource = source.substring(actionStart);

    expect(actionSource, contains('AppPalette.warmSurface28'));
    expect(actionSource, contains('AppPalette.warmSurface66'));
    expect(actionSource, contains('AppPalette.primary'));
    expect(actionSource, contains('isAccent'));
    expect(actionSource, contains('? AppPalette.warmSurface28'));
    expect(
      actionSource,
      isNot(contains('colors: [AppPalette.amberSoft14, AppPalette.primary]')),
    );
  });

  test('drawer menu rows expose semantic button targets', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();
    final itemStart = source.indexOf('class _DrawerMenuItem');
    final itemEnd = source.indexOf('class _DrawerFooterAction', itemStart);

    expect(itemStart, isNonNegative);
    expect(itemEnd, greaterThan(itemStart));

    final itemSource = source.substring(itemStart, itemEnd);

    expect(itemSource, contains('Semantics('));
    expect(itemSource, contains('button: true'));
    expect(itemSource, contains('enabled: true'));
    expect(itemSource, contains('selected: isActive'));
    expect(itemSource, contains('label: label'));
    expect(itemSource, contains('ExcludeSemantics('));
  });

  test('drawer exposes optional my checklists menu entry', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();

    final drawerStart = source.indexOf('class AppSideDrawer');
    final helpersStart = source.indexOf('class _DrawerPinnedFooter');

    expect(drawerStart, isNonNegative);
    expect(helpersStart, greaterThan(drawerStart));

    final drawerSource = source.substring(drawerStart, helpersStart);

    expect(source, contains('AppDrawerActiveItem.myChecklists'));
    expect(drawerSource, contains('onMyChecklistsTap'));
    expect(drawerSource, contains('l10n.travelChecklistRecentTitle'));
    expect(drawerSource, contains('Icons.checklist_rtl_rounded'));
  });

  test('drawer footer action exposes localized semantic labels', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();
    final actionStart = source.indexOf('class _DrawerFooterAction');

    expect(actionStart, isNonNegative);

    final actionSource = source.substring(actionStart);

    expect(source, contains('semanticLabel: isLoggedIn'));
    expect(source, contains('l10n.logoutButton'));
    expect(source, contains('l10n.authLoginAction'));
    expect(actionSource, contains('required this.semanticLabel'));
    expect(actionSource, contains('final String semanticLabel'));
    expect(actionSource, contains('Semantics('));
    expect(actionSource, contains('button: true'));
    expect(actionSource, contains('enabled: true'));
    expect(actionSource, contains('label: semanticLabel'));
    expect(actionSource, contains('ExcludeSemantics('));
  });

  test('drawer no longer exposes app language switcher in menu', () async {
    final source = await File(
      'lib/screens/common/app_side_drawer.dart',
    ).readAsString();
    final drawerStart = source.indexOf('class AppSideDrawer');
    final helpersStart = source.indexOf('class _DrawerPinnedFooter');

    expect(drawerStart, isNonNegative);
    expect(helpersStart, greaterThan(drawerStart));

    final drawerSource = source.substring(drawerStart, helpersStart);

    expect(drawerSource, isNot(contains('languageLabel')));
    expect(drawerSource, isNot(contains('onLanguageTap')));
    expect(drawerSource, isNot(contains('l10n.appLanguageTitle')));
    expect(drawerSource, isNot(contains('Icons.language_rounded')));
    expect(drawerSource, isNot(contains('_LanguageOptionTile')));
  });
}
