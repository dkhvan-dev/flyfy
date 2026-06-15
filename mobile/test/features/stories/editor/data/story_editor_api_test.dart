import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/api_client.dart';
import 'package:inflap/core/storage/secure_storage.dart';
import 'package:inflap/features/stories/editor/data/story_editor_api.dart';
import 'package:inflap/features/stories/editor/data/story_editor_dto.dart';
import 'package:inflap/features/stories/editor/domain/story_document.dart';

void main() {
  test(
    'createDraft posts a structured draft body and parses post fields',
    () async {
      final adapter = _QueuedJsonAdapter([
        _ResponseStub(_storyJson('story-1')),
      ]);
      final api = _api(adapter);

      final story = await api.createDraft(_editorRequest());

      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, '/api/v1/posts');
      expect(adapter.captured.single.body['status'], 'DRAFT');
      expect(adapter.captured.single.body['format'], 'GUIDE');
      expect(adapter.captured.single.body['communityId'], 'community-1');
      expect(adapter.captured.single.body['contentSchemaVersion'], 1);
      expect(adapter.captured.single.body, isNot(contains('content')));

      final document =
          adapter.captured.single.body['contentBlocks'] as Map<String, dynamic>;
      expect(document['version'], 1);

      final blocks = document['blocks'] as List;
      expect(blocks.first, containsPair('type', 'heading'));
      expect(blocks.first, containsPair('level', 2));
      expect((blocks[1] as Map<String, dynamic>)['marks'], [
        {'type': 'underline', 'start': 0, 'end': 4},
        {'type': 'strikethrough', 'start': 5, 'end': 9},
        {'type': 'link', 'start': 8, 'end': 17, 'url': 'https://example.com'},
      ]);
      expect(blocks[2], {
        'id': 'list-1',
        'type': 'bulleted_list',
        'items': [
          {'text': 'Morning'},
          {'text': 'Local food'},
          {'text': 'Evening view'},
        ],
      });
      expect(blocks[3], {'id': 'image-1', 'type': 'image', 'fileId': 'file-1'});
      expect(blocks[4], {
        'id': 'gallery-1',
        'type': 'gallery',
        'images': [
          {'fileId': 'file-2'},
          {'fileId': 'file-3'},
        ],
      });
      expect(blocks[5], {
        'id': 'place-1',
        'type': 'place_reference',
        'placeId': 'place-1',
        'placeName': 'Almaty',
        'placeCountryCode': 'KZ',
        'placeCityId': 'almaty',
      });

      expect(story.format, 'GUIDE');
      expect(story.contentSchemaVersion, 1);
      expect(story.contentBlocks, hasLength(6));
      expect(story.revision, 8);
      expect(story.lastAutosavedAt, DateTime.parse('2026-06-01T10:00:00Z'));
      expect(story.archivedAt, DateTime.parse('2026-06-02T10:00:00Z'));
      expect(story.moderationStatus, 'PENDING');
    },
  );

  test(
    'story editor writes structured blocks without legacy rollback switch',
    () {
      final body = _editorRequest().toJson();

      expect(body, isNot(contains('content')));

      final apiSource = File(
        'lib/features/stories/editor/data/story_editor_api.dart',
      ).readAsStringSync();
      final dtoSource = File(
        'lib/features/stories/editor/data/story_editor_dto.dart',
      ).readAsStringSync();
      final configSource = File(
        'lib/core/config/app_config.dart',
      ).readAsStringSync();
      final legacyFlag = ['send', 'Legacy', 'Story', 'Content'].join();
      final legacyDefine = [
        'INFLAP',
        'SEND',
        'LEGACY',
        'STORY',
        'CONTENT',
      ].join('_');
      final includeLegacyParameter = ['include', 'Legacy', 'Content'].join();
      final privateLegacyGetter = ['_', 'legacy', 'Content'].join();

      expect(apiSource, isNot(contains(legacyFlag)));
      expect(apiSource, isNot(contains(includeLegacyParameter)));
      expect(dtoSource, isNot(contains(includeLegacyParameter)));
      expect(dtoSource, isNot(contains(privateLegacyGetter)));
      expect(configSource, isNot(contains(legacyFlag)));
      expect(configSource, isNot(contains(legacyDefine)));
    },
  );

  test('editor mutations use dedicated post lifecycle endpoints', () async {
    final adapter = _QueuedJsonAdapter([
      _ResponseStub(_storyJson('story-1')),
      _ResponseStub(_storyJson('story-1')),
      _ResponseStub(_storyJson('story-1')),
      _ResponseStub(_storyJson('story-1')),
    ]);
    final api = _api(adapter);

    await api.autosave(' story-1 ', _editorRequest());
    await api.update('story-1', _editorRequest());
    await api.publish('story-1', _editorRequest());
    await api.archive('story-1', revision: 8);

    expect(
      adapter.captured.map((request) => '${request.method} ${request.path}'),
      [
        'POST /api/v1/posts/story-1/autosave',
        'PATCH /api/v1/posts/story-1',
        'POST /api/v1/posts/story-1/publish',
        'POST /api/v1/posts/story-1/archive',
      ],
    );
    expect(adapter.captured.last.body, {'revision': 8});
  });

  test('maps backend field validation errors from Dio responses', () async {
    final adapter = _QueuedJsonAdapter([
      _ResponseStub({
        'fieldErrors': [
          {
            'field': 'contentBlocks',
            'code': 'image_file_id_required',
            'message': 'Image file id is required.',
            'blockId': 'image-1',
          },
        ],
      }, statusCode: 422),
    ]);
    final api = _api(adapter);

    await expectLater(
      api.publish('story-1', _editorRequest()),
      throwsA(
        isA<StoryEditorApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.fieldErrors.single.field,
              'field',
              'contentBlocks',
            )
            .having(
              (error) => error.fieldErrors.single.code,
              'code',
              'image_file_id_required',
            )
            .having(
              (error) => error.fieldErrors.single.blockId,
              'blockId',
              'image-1',
            ),
      ),
    );
  });

  test(
    'preserves structured field errors from map keyed backend payloads',
    () async {
      final adapter = _QueuedJsonAdapter([
        _ResponseStub({
          'fieldErrors': {
            'contentBlocks': [
              {
                'code': 'unsafe_link',
                'message': 'Only http and https links are supported.',
                'blockId': 'paragraph-1',
              },
              {
                'field': 'coverFileId',
                'code': 'cover_required',
                'message': 'Cover is required.',
              },
            ],
          },
        }, statusCode: 422),
      ]);
      final api = _api(adapter);

      await expectLater(
        api.publish('story-1', _editorRequest()),
        throwsA(
          isA<StoryEditorApiException>()
              .having((error) => error.fieldErrors, 'fieldErrors', [
                isA<StoryEditorFieldError>()
                    .having((error) => error.field, 'field', 'contentBlocks')
                    .having((error) => error.code, 'code', 'unsafe_link')
                    .having(
                      (error) => error.message,
                      'message',
                      'Only http and https links are supported.',
                    )
                    .having((error) => error.blockId, 'blockId', 'paragraph-1'),
                isA<StoryEditorFieldError>()
                    .having((error) => error.field, 'field', 'coverFileId')
                    .having((error) => error.code, 'code', 'cover_required')
                    .having(
                      (error) => error.message,
                      'message',
                      'Cover is required.',
                    ),
              ]),
        ),
      );
    },
  );
}

StoryEditorApi _api(_QueuedJsonAdapter adapter) {
  return StoryEditorApi(
    apiClient: ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'))
        ..httpClientAdapter = adapter,
      secureStorage: _FakeSecureStorage(),
    ),
  );
}

StoryEditorWriteRequest _editorRequest() {
  final document = StoryDocument(
    blocks: [
      StoryBlock.heading(id: 'heading-1', text: 'Arrival', level: 2),
      StoryBlock.paragraph(
        id: 'paragraph-1',
        text: 'Read more',
        marks: const [
          StoryInlineMark.underline(start: 0, end: 4),
          StoryInlineMark.strikethrough(start: 5, end: 9),
          StoryInlineMark.link(start: 8, end: 17, url: 'https://example.com'),
        ],
      ),
      StoryBlock.bulletedList(
        id: 'list-1',
        text: 'Morning\nLocal food\nEvening view',
      ),
      StoryBlock.image(
        id: 'image-1',
        image: const StoryImagePayload(fileId: 'file-1'),
      ),
      StoryBlock.gallery(
        id: 'gallery-1',
        gallery: StoryGalleryPayload(
          images: const [
            StoryImagePayload(fileId: 'file-2'),
            StoryImagePayload(fileId: 'file-3'),
          ],
        ),
      ),
      StoryBlock.placeReference(
        id: 'place-1',
        place: const StoryPlaceReference(
          placeId: 'place-1',
          name: 'Almaty',
          countryCode: 'kz',
          cityId: ' almaty ',
          latitude: 43.2389,
          longitude: 76.8897,
        ),
      ),
    ],
  );

  return StoryEditorWriteRequest(
    title: ' Arrival ',
    format: ' guide ',
    category: ' journal ',
    status: 'draft',
    document: document,
    communityId: ' community-1 ',
    revision: 7,
    coverFileId: ' cover-1 ',
    placeName: ' Almaty ',
    placeCountryCode: ' kz ',
    placeCityId: ' almaty ',
    tags: const [' mountains ', ''],
    metadata: const {'source': 'editor'},
  );
}

Map<String, Object?> _storyJson(String id) {
  return {
    'id': id,
    'slug': 'story-$id',
    'title': 'Story $id',
    'excerpt': 'Excerpt',
    'content': 'Arrival legacy',
    'format': 'GUIDE',
    'contentSchemaVersion': 1,
    'contentBlocks': _editorRequest().toJson()['contentBlocks'],
    'revision': 8,
    'lastAutosavedAt': '2026-06-01T10:00:00Z',
    'archivedAt': '2026-06-02T10:00:00Z',
    'moderationStatus': 'PENDING',
    'category': 'JOURNAL',
    'status': 'DRAFT',
    'coverFileId': 'cover-1',
    'placeName': 'Almaty',
    'placeCountryCode': 'KZ',
    'placeCityId': 'almaty',
    'tags': const ['mountains'],
    'stats': const <String, int>{},
    'author': const {
      'userId': 'author-1',
      'locale': 'en',
      'timezone': 'Asia/Almaty',
    },
    'likedByViewer': false,
    'shareUrl': '',
    'createdAt': '2026-05-10T00:00:00Z',
    'updatedAt': '2026-06-01T10:00:00Z',
  };
}

class _FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> getAccessToken() async => 'access-token';

  @override
  Future<String?> getRefreshToken() async => null;
}

class _ResponseStub {
  const _ResponseStub(this.payload, {this.statusCode = 200});

  final Map<String, Object?> payload;
  final int statusCode;
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> body;
}

class _QueuedJsonAdapter implements HttpClientAdapter {
  _QueuedJsonAdapter(List<_ResponseStub> responses)
    : _responses = Queue.of(responses);

  final Queue<_ResponseStub> _responses;
  final List<_CapturedRequest> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = await _decodeBody(requestStream);
    captured.add(
      _CapturedRequest(
        method: options.method,
        path: options.uri.path,
        body: body,
      ),
    );
    final response = _responses.removeFirst();
    return ResponseBody.fromString(
      jsonEncode(response.payload),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Future<Map<String, dynamic>> _decodeBody(
    Stream<Uint8List>? requestStream,
  ) async {
    if (requestStream == null) {
      return const {};
    }
    final builder = BytesBuilder();
    await for (final chunk in requestStream) {
      builder.add(chunk);
    }
    final bodyText = utf8.decode(builder.takeBytes());
    if (bodyText.trim().isEmpty) {
      return const {};
    }
    return jsonDecode(bodyText) as Map<String, dynamic>;
  }

  @override
  void close({bool force = false}) {}
}
