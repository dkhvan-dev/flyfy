import 'package:dio/dio.dart';

class DioErrorMapper {
  static String? backendCode(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final code = data['code'];
    if (code is! String) return null;
    final normalized = code.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String toMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Сервер долго не отвечает. Проверьте соединение и попробуйте снова.';
      case DioExceptionType.sendTimeout:
        return 'Не удалось отправить запрос. Попробуйте снова.';
      case DioExceptionType.receiveTimeout:
        return 'Сервер слишком долго обрабатывает запрос. Попробуйте позже.';
      case DioExceptionType.connectionError:
        return 'Нет подключения к серверу. Проверьте интернет или доступность backend.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        final backendMessage = _backendMessage(data);
        if (backendMessage != null) {
          return backendMessage;
        }

        if (statusCode == 400) {
          return 'Некорректный запрос.';
        }
        if (statusCode == 401) {
          return 'Неверный код или требуется повторная авторизация.';
        }
        if (statusCode == 403) {
          return 'Доступ запрещён.';
        }
        if (statusCode == 404) {
          return 'Сервис не найден.';
        }
        if (statusCode == 409) {
          return 'Конфликт данных.';
        }
        if (statusCode == 422) {
          return 'Проверьте корректность введённых данных.';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'Внутренняя ошибка сервера. Попробуйте позже.';
        }

        return 'Ошибка сервера. Попробуйте позже.';

      case DioExceptionType.cancel:
        return 'Запрос был отменён.';
      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата безопасности.';
      case DioExceptionType.unknown:
        return 'Произошла непредвиденная ошибка сети.';
    }
  }

  static String? _backendMessage(Object? data) {
    if (data is! Map) {
      return null;
    }

    for (final key in const ['message', 'detail', 'error', 'title']) {
      final message = _extractMessage(data[key]);
      if (message != null) {
        return message;
      }
    }
    return null;
  }

  static String? _extractMessage(Object? value) {
    if (value is String) {
      final message = value.trim();
      return message.isEmpty ? null : message;
    }
    if (value is List) {
      final messages = value
          .map(_extractMessage)
          .whereType<String>()
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (value is Map) {
      for (final key in const ['message', 'detail', 'error', 'title']) {
        final message = _extractMessage(value[key]);
        if (message != null) {
          return message;
        }
      }
    }
    return null;
  }
}
