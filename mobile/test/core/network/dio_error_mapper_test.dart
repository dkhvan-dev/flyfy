import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/dio_error_mapper.dart';

void main() {
  test('passes backend error text through without mobile localization', () {
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

    expect(message, 'authentication_required');
  });

  test('prefers localized backend message over technical error code', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/stories'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/stories'),
        statusCode: 401,
        data: const {
          'error': 'authentication_required',
          'message': 'Войдите в аккаунт, чтобы продолжить.',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final message = DioErrorMapper.toMessage(error);

    expect(message, 'Войдите в аккаунт, чтобы продолжить.');
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

  test('extracts a stable backend error code', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/me/excursions'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/me/excursions'),
        statusCode: 409,
        data: const {
          'code': 'excursion.excursion_already_exists_for_this_guide_and_place',
          'message': 'Excursion already exists.',
        },
      ),
      type: DioExceptionType.badResponse,
    );

    expect(
      DioErrorMapper.backendCode(error),
      'excursion.excursion_already_exists_for_this_guide_and_place',
    );
  });
}
