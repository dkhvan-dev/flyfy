import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../models/story_vm.dart';
import 'story_editor_dto.dart';

class StoryEditorApi {
  StoryEditorApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StoryVm> getStory(String storyId) {
    return _sendStoryMutation(
      () => _apiClient.dio.get('/stories/${_storyId(storyId)}'),
    );
  }

  Future<StoryVm> createDraft(StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/stories',
        data: request.toJson(statusOverride: 'DRAFT'),
      ),
    );
  }

  Future<StoryVm> autosave(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/stories/${_storyId(storyId)}/autosave',
        data: request.toJson(),
      ),
    );
  }

  Future<StoryVm> update(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.patch(
        '/stories/${_storyId(storyId)}',
        data: request.toJson(),
      ),
    );
  }

  Future<StoryVm> publish(String storyId, StoryEditorWriteRequest request) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/stories/${_storyId(storyId)}/publish',
        data: request.toJson(statusOverride: 'PUBLISHED'),
      ),
    );
  }

  Future<StoryVm> archive(String storyId, {int? revision}) {
    return _sendStoryMutation(
      () => _apiClient.dio.post(
        '/stories/${_storyId(storyId)}/archive',
        data: revision == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'revision': revision},
      ),
    );
  }

  Future<StoryVm> _sendStoryMutation(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      return StoryVm.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw StoryEditorApiException.fromDio(error);
    }
  }

  String _storyId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'storyId', 'Story id is required.');
    }
    return Uri.encodeComponent(trimmed);
  }
}

class StoryEditorApiException implements Exception {
  StoryEditorApiException({
    required this.message,
    required this.statusCode,
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
      fieldErrors: parseStoryEditorFieldErrors(payload),
    );
  }

  final String message;
  final int? statusCode;
  final List<StoryEditorFieldError> fieldErrors;

  @override
  String toString() => 'StoryEditorApiException($statusCode): $message';
}
