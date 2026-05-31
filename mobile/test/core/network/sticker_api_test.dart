import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/network/sticker_api.dart';
import 'package:inflap/core/storage/secure_storage.dart';

void main() {
  test('uploads sticker binary through file-manager gateway endpoint', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
      ..httpClientAdapter = adapter;
    final api = StickerApi(
      apiClient: ApiClient(dio: dio, secureStorage: _FakeSecureStorage()),
    );

    await api.uploadBinary(
      upload: const StickerUploadRequestVm(
        uploadSessionId: 'upload-session-id',
        fileId: '8cbe61fb-0764-49b2-a5fb-982cd9c5c54a',
        method: 'PUT',
        url: 'http://file-manager-minio:9000/inflap-files/object-key',
        headers: {'X-Amz-SignedHeaders': 'host'},
      ),
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      contentType: 'image/png',
    );

    expect(adapter.request?.method, 'PUT');
    expect(
      adapter.request?.uri.toString(),
      'http://backend.test/api/v1/files/8cbe61fb-0764-49b2-a5fb-982cd9c5c54a/binary',
    );
    expect(adapter.request?.headers['Content-Type'], 'image/png');
    expect(
      adapter.request?.headers.containsKey('X-Amz-SignedHeaders'),
      isFalse,
    );
    expect(adapter.body, [1, 2, 3, 4]);
  });
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  List<int> body = const [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    body = await _readBody(requestStream);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}

  Future<List<int>> _readBody(Stream<Uint8List>? requestStream) async {
    if (requestStream == null) {
      return const [];
    }

    final bytes = <int>[];
    await for (final chunk in requestStream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }
}
