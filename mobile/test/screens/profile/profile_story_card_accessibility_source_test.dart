import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile story cards expose a semantic button target', () {
    final source = File(
      'lib/screens/profile/widgets/profile_story_card.dart',
    ).readAsStringSync();

    expect(source, contains('Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('label: story.title'));
    expect(source, contains('onTap: onTap'));
  });
}
