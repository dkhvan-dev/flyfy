import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile app does not expose the removed side drawer', () async {
    expect(
      File('lib/screens/common/app_side_drawer.dart').existsSync(),
      isFalse,
    );

    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in sourceFiles) {
      final path = file.path;
      final source = await file.readAsString();

      expect(
        source,
        isNot(contains('AppSideDrawer')),
        reason: '$path must not construct the removed drawer',
      );
      expect(
        source,
        isNot(contains('app_side_drawer.dart')),
        reason: '$path must not import the removed drawer',
      );
      expect(
        source,
        isNot(matches(RegExp(r'\b(?:drawer|endDrawer)\s*:'))),
        reason: '$path must not attach a Scaffold drawer',
      );
      expect(
        source,
        isNot(matches(RegExp(r'\bDrawer\s*\('))),
        reason: '$path must not construct a Material drawer',
      );
      expect(
        source,
        isNot(matches(RegExp(r'\bopen(?:End)?Drawer\s*\('))),
        reason: '$path must not open a side drawer programmatically',
      );
      expect(
        source,
        isNot(contains('drawerEnableOpenDragGesture')),
        reason: '$path must not enable drawer edge gestures',
      );
      expect(
        source,
        isNot(contains('drawerEdgeDragWidth')),
        reason: '$path must not reserve an edge-swipe area',
      );
      expect(
        source,
        isNot(matches(RegExp(r'Icons\.menu(?:_rounded)?\b'))),
        reason: '$path must not restore the drawer hamburger action',
      );
    }
  });
}
