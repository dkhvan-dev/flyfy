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
}
