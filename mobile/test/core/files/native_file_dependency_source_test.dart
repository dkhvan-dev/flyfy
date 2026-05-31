import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mobile app does not depend on deprecated file opening and picker plugins',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final chatCache = await File(
        'lib/core/files/chat_file_cache.dart',
      ).readAsString();
      final chatScreen = await File(
        'lib/screens/chat/chat_screen.dart',
      ).readAsString();
      final sharedContent = await File(
        'lib/screens/chat/chat_shared_content_screen.dart',
      ).readAsString();
      final guideVerification = await File(
        'lib/screens/profile/guide_verification_screen.dart',
      ).readAsString();

      expect(pubspec, isNot(contains('open_filex:')));
      expect(pubspec, isNot(contains('file_picker:')));
      expect(pubspec, contains('file_selector:'));
      expect(pubspec, isNot(contains('third_party/flutter_plugins')));
      expect(await Directory('third_party/flutter_plugins').exists(), isFalse);

      for (final source in [
        chatCache,
        chatScreen,
        sharedContent,
        guideVerification,
      ]) {
        expect(source, isNot(contains("package:open_filex/open_filex.dart")));
        expect(source, isNot(contains("package:file_picker/file_picker.dart")));
        expect(source, isNot(contains('OpenFilex')));
        expect(source, isNot(contains('FilePicker')));
        expect(source, isNot(contains('ResultType')));
      }
    },
  );

  test(
    'ios project uses Swift Package Manager without CocoaPods integration',
    () async {
      final debugConfig = await File(
        'ios/Flutter/Debug.xcconfig',
      ).readAsString();
      final releaseConfig = await File(
        'ios/Flutter/Release.xcconfig',
      ).readAsString();
      final profileConfig = await File(
        'ios/Flutter/Profile.xcconfig',
      ).readAsString();
      final workspace = await File(
        'ios/Runner.xcworkspace/contents.xcworkspacedata',
      ).readAsString();
      final xcodeProject = await File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsString();

      expect(await File('ios/Podfile').exists(), isFalse);
      expect(await File('ios/Podfile.lock').exists(), isFalse);
      expect(debugConfig, isNot(contains('Pods/Target Support Files')));
      expect(releaseConfig, isNot(contains('Pods/Target Support Files')));
      expect(profileConfig, isNot(contains('Pods/Target Support Files')));
      expect(workspace, isNot(contains('Pods/Pods.xcodeproj')));
      expect(xcodeProject, contains('FlutterGeneratedPluginSwiftPackage'));
      expect(xcodeProject, isNot(contains('Pods_Runner.framework')));
    },
  );
}
