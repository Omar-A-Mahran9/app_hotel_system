import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/error_mapper.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';

void main() {
  final RequestOptions options = RequestOptions(path: '/x');

  test('connection error maps to a retryable network failure', () {
    final Failure failure = ErrorMapper.toFailure(
      DioException(requestOptions: options, type: DioExceptionType.connectionError),
    );
    expect(failure.kind, FailureKind.network);
    expect(failure.isRetryable, isTrue);
  });

  test('timeouts map to timeout failure', () {
    for (final DioExceptionType type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      final Failure failure = ErrorMapper.toFailure(
        DioException(requestOptions: options, type: type),
      );
      expect(failure.kind, FailureKind.timeout, reason: type.name);
    }
  });

  test('422 response maps to a validation failure with field errors', () {
    final Failure failure = ErrorMapper.toFailure(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 422,
          data: <String, dynamic>{
            'success': false,
            'message': 'The given data was invalid.',
            'errors': <String, dynamic>{
              'email': <String>['The email field is required.'],
            },
          },
        ),
      ),
    );
    expect(failure.kind, FailureKind.validation);
    expect(failure.fieldErrors['email'], <String>['The email field is required.']);
    expect(failure.isRetryable, isFalse);
  });

  test('401 maps to unauthorized, 5xx maps to server', () {
    Failure map(int status) => ErrorMapper.toFailure(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(requestOptions: options, statusCode: status),
          ),
        );
    expect(map(401).kind, FailureKind.unauthorized);
    expect(map(503).kind, FailureKind.server);
  });

  test('NotImplementedInPhaseException maps to notImplemented', () {
    expect(
      ErrorMapper.toFailure(const NotImplementedInPhaseException()).kind,
      FailureKind.notImplemented,
    );
  });
}
