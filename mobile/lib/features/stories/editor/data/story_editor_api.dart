import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../models/post_vm.dart';
import 'story_editor_dto.dart';

class StoryEditorApi {
  StoryEditorApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PostVm> getStory(String storyId) {
    return _sendStoryMutation(
      () => _apiClient.dio.get('/posts/${_storyId(storyId)}'),
    );
  }

  Future<PostVm> createDraft(StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/posts',
        data: request.toJson(statusOverride: 'DRAFT'),
      ),
    );
  }

  Future<PostVm> autosave(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/posts/${_storyId(storyId)}/autosave',
        data: request.toJson(),
      ),
    );
  }

  Future<PostVm> update(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.patch(
        '/posts/${_storyId(storyId)}',
        data: request.toJson(),
      ),
    );
  }

  Future<PostVm> publish(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/posts/${_storyId(storyId)}/publish',
        data: request.toJson(statusOverride: 'PUBLISHED'),
      ),
    );
  }

  Future<PostVm> archive(String storyId, {int? revision}) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/posts/${_storyId(storyId)}/archive',
        data: revision == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'revision': revision},
      ),
    );
  }

  Future<PostVm> _sendStoryMutation(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      return PostVm.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StoryEditorApiException.fromDio(error);
    }
  }

  String _storyId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'postId', 'Post id is required.');
    }
    return Uri.encodeComponent(trimmed);
  }
}

class StoryEditorApiException implements Exception {
  StoryEditorApiException({
    required this.message,
    required this.statusCode,
    this.code,
    this.retryAfter = Duration.zero,
    this.nextAvailableAt,
    this.fieldErrors = const [],
  });

  factory StoryEditorApiException.fromDio(DioException error) {
    final data = error.response?.data;
    final payload = data is Map<String, dynamic> ? data : const {};
    final message =
        payload['message']?.toString() ??
        payload['error']?.toString() ??
        error.message ??
        'Story editor request failed.';

    return StoryEditorApiException(
      message: message,
      statusCode: error.response?.statusCode,
      code: payload['code']?.toString(),
      retryAfter: Duration(
        seconds:
            _parseNonNegativeInt(payload['retryAfterSeconds']) ??
            _parseNonNegativeInt(
              error.response?.headers.value('retry-after'),
            ) ??
            0,
      ),
      nextAvailableAt: DateTime.tryParse(
        payload['nextAvailableAt']?.toString() ?? '',
      ),
      fieldErrors: parseStoryEditorFieldErrors(payload),
    );
  }

  final String message;
  final int? statusCode;
  final String? code;
  final Duration retryAfter;
  final DateTime? nextAvailableAt;
  final List<StoryEditorFieldError> fieldErrors;

  @override
  String toString() => 'StoryEditorApiException($statusCode): $message';
}

int? _parseNonNegativeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 0) {
    return null;
  }
  return parsed;
}
