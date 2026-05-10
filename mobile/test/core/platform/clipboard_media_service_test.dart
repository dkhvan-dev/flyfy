import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:superapp/core/platform/clipboard_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/clipboard_media');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('readImage returns image bytes from platform clipboard', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'readImage');
      return {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'contentType': 'image/png',
        'name': 'crop.png',
      };
    });

    final item = await ClipboardMediaService(channel: channel).readImage();

    expect(item, isNotNull);
    expect(item!.bytes, [1, 2, 3]);
    expect(item.contentType, 'image/png');
    expect(item.name, 'crop.png');
  });

  test('readImage ignores non-image clipboard payloads', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      return {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'contentType': 'text/plain',
        'name': 'notes.txt',
      };
    });

    final item = await ClipboardMediaService(channel: channel).readImage();

    expect(item, isNull);
  });
}
