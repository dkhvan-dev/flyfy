import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/files/app_file_opener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('inflap/file_opener');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'open delegates local files to the app-owned native file opener',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return <String, Object?>{'status': 'done'};
          });

      final result = await AppFileOpener().open(
        '/tmp/inflap-ticket.pdf',
        contentType: 'application/pdf',
      );

      expect(result.status, AppFileOpenStatus.done);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'openFile');
      expect(calls.single.arguments, <String, Object?>{
        'path': '/tmp/inflap-ticket.pdf',
        'contentType': 'application/pdf',
      });
    },
  );

  test('open maps native no-app responses to a typed result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return <String, Object?>{
            'status': 'no_app',
            'message': 'No app can open this file',
          };
        });

    final result = await AppFileOpener().open('/tmp/archive.bin');

    expect(result.status, AppFileOpenStatus.noApp);
    expect(result.message, 'No app can open this file');
  });

  test(
    'open returns fileNotFound for blank paths without calling native code',
    () async {
      var nativeCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            nativeCallCount++;
            return <String, Object?>{'status': 'done'};
          });

      final result = await AppFileOpener().open('   ');

      expect(result.status, AppFileOpenStatus.fileNotFound);
      expect(nativeCallCount, 0);
    },
  );
}
