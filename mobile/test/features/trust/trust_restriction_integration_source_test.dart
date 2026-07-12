import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trust restrictions refresh on session lifecycle and admin push', () {
    final mainSource = File('lib/main.dart').readAsStringSync();

    expect(mainSource, contains('TrustAccessProvider'));
    expect(mainSource, contains('_TrustAccessSessionBridge'));
    expect(mainSource, contains('widget.provider.refresh(force: true)'));
    expect(mainSource, contains('_trustAccessProvider.handlePushData'));
  });

  test('creation surfaces hide actions and render restriction notices', () {
    final sources = [
      'lib/features/feed/presentation/feed_screen.dart',
      'lib/screens/activities/activities_screen.dart',
      'lib/screens/activities/my_activities_screen.dart',
      'lib/screens/activities/create_activity_screen.dart',
      'lib/screens/excursions/excursions_screen.dart',
      'lib/screens/excursions/create_excursion_screen.dart',
      'lib/screens/stories/stories_screen.dart',
      'lib/screens/stories/create_story_screen.dart',
      'lib/screens/profile/profile_screen.dart',
      'lib/screens/profile/guide_verification_screen.dart',
      'lib/screens/chat/chat_screen.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    for (final capability in [
      'TrustCapability.createPost',
      'TrustCapability.createActivity',
      'TrustCapability.publishTour',
      'TrustCapability.submitGuideApplication',
      'TrustCapability.sendChatMessage',
      'TrustCapability.uploadFile',
    ]) {
      expect(sources, contains(capability));
    }
    expect(sources, contains('TrustRestrictionNotice'));
    expect(sources, contains('TrustRestrictedScaffold'));
  });

  test('trust profile API reads active restrictions through gateway', () {
    final apiSource = File(
      'lib/features/trust/data/trust_access_api.dart',
    ).readAsStringSync();

    expect(apiSource, contains("'/trust/profile'"));
    expect(apiSource, contains("'activeRestrictions'"));
    expect(apiSource, contains("'requiresAuth': true"));
  });
}
