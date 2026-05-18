import 'package:dio/dio.dart';

class DioErrorMapper {
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

        if (data is Map<String, dynamic>) {
          final message = data['error'] ?? data['message'] ?? data['detail'];
          if (message is String && message.trim().isNotEmpty) {
            return _localizedBackendMessage(message.trim());
          }
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

  static String _localizedBackendMessage(String message) {
    return switch (message) {
      'invalid excursion itinerary description' =>
        'Описание каждого этапа маршрута должно быть не короче 5 символов.',
      'excursion already exists for this guide and attraction' =>
        'У вас уже есть экскурсия по этой достопримечательности.',
      'excursion schedule slot must start at least 3 hours from now' =>
        'Выберите дату и время минимум за 3 часа до начала.',
      _ => message,
    };
  }
}
