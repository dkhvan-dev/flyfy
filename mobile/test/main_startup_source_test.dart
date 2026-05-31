import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup side effects are deferred until after the first frame', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('_scheduleDeferredStartupWork();'));
    expect(source, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(source, contains('Future<void> _runDeferredStartupWork() async'));
    expect(source, contains('waitUntilFirstFrameRasterized'));
    expect(source, contains('Future<void>.delayed(_deferredStartupDelay)'));
    expect(source, contains('static const _deferredPushStartupDelay'));
    expect(
      source,
      contains('Future<void> _runDeferredPushStartupWork() async'),
    );
    expect(source, contains('FirebaseMessaging.onBackgroundMessage('));
    expect(source, contains('_firebaseMessagingBackgroundHandler'));

    final initStateBody = source.substring(
      source.indexOf('  void initState() {'),
      source.indexOf('  @override\n  void dispose() {'),
    );
    expect(initStateBody, isNot(contains('_bootstrapAuth();')));
    expect(
      initStateBody,
      isNot(contains('_pushNotificationCoordinator.start()')),
    );

    final startupBody = source.substring(
      source.indexOf('  Future<void> _runDeferredStartupWork() async {'),
      source.indexOf('  Future<void> _runDeferredPushStartupWork() async {'),
    );
    expect(startupBody, contains('unawaited(_runDeferredPushStartupWork())'));
    expect(startupBody, isNot(contains('_initializeFirebaseMessaging()')));
    expect(startupBody, isNot(contains('_startPushNotifications()')));

    final firebaseInitBody = source.substring(
      source.indexOf('  Future<void> _initializeFirebaseMessaging() async {'),
      source.indexOf('  Future<void> _startPushNotifications() async {'),
    );
    expect(
      firebaseInitBody,
      isNot(contains('FirebaseMessaging.onBackgroundMessage')),
    );
  });
}
