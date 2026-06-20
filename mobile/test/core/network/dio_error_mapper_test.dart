import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/dio_error_mapper.dart';

void main() {
  test('maps authentication backend codes to human-readable copy', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/stories'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/stories'),
        statusCode: 401,
        data: const {'error': 'authentication_required'},
      ),
      type: DioExceptionType.badResponse,
    );

    final message = DioErrorMapper.toMessage(error);

    expect(message, isNot(contains('authentication_required')));
    expect(message, contains('Войдите'));
  });

  test('uses maintenance response message instead of title', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/activities/join'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/activities/join'),
        statusCode: 503,
        data: const {
          'error': 'Технические работы',
          'message': 'Сейчас проводятся технические работы. Попробуйте позже.',
          'code': 'activity.technical_maintenance',
          'kind': 'maintenance',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final message = DioErrorMapper.toMessage(error);

    expect(message, 'Сейчас проводятся технические работы. Попробуйте позже.');
  });
}
