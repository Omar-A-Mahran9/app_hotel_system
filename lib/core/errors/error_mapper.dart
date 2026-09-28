import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

/// Converts anything thrown by the data layer into a [Failure].
///
/// Repositories call [toFailure] so that state objects only ever expose the
/// user-safe type. Both [AppException] (raised by our data sources) and raw
/// [DioException] (raised by the HTTP client before interceptors classify it)
/// are handled.
abstract final class ErrorMapper {
  static Failure toFailure(Object error) {
    if (error is Failure) return error;
    if (error is AppException) return _fromAppException(error);
    if (error is DioException) return _fromAppException(fromDioException(error));
    return Failure(FailureKind.unknown, debugMessage: error.toString());
  }

  /// Normalizes a [DioException] into one of our [AppException] types. Kept
  /// public so the HTTP error interceptor can reuse it.
  static AppException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return RequestTimeoutException(cause: error);
      case DioExceptionType.connectionError:
        return NetworkException(cause: error);
      case DioExceptionType.badCertificate:
        return NetworkException(message: 'Bad TLS certificate', cause: error);
      case DioExceptionType.cancel:
        return const UnknownException(message: 'Request cancelled');
      case DioExceptionType.unknown:
        return UnknownException(message: error.message ?? 'Unknown error', cause: error);
      case DioExceptionType.badResponse:
        return _fromStatus(error.response?.statusCode, error.response?.data);
    }
  }

  static AppException _fromStatus(int? status, Object? body) {
    final String message = _serverMessage(body) ?? 'Request failed';
    switch (status) {
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 422:
        return ValidationException(_fieldErrors(body), message);
      case 429:
        return RateLimitException(message: message);
      default:
        if (status != null && status >= 500) {
          return ServerException(message: message, statusCode: status);
        }
        return UnknownException(message: message);
    }
  }

  static Failure _fromAppException(AppException e) {
    final FailureKind kind = switch (e) {
      NetworkException() => FailureKind.network,
      RequestTimeoutException() => FailureKind.timeout,
      UnauthorizedException() => FailureKind.unauthorized,
      ForbiddenException() => FailureKind.forbidden,
      NotFoundException() => FailureKind.notFound,
      ValidationException() => FailureKind.validation,
      ConflictException() => FailureKind.conflict,
      RateLimitException() => FailureKind.rateLimited,
      ServerException() => FailureKind.server,
      NotImplementedInPhaseException() => FailureKind.notImplemented,
      UnknownException() => FailureKind.unknown,
    };
    return Failure(
      kind,
      fieldErrors: e is ValidationException
          ? e.fieldErrors
          : const <String, List<String>>{},
      debugMessage: e.message,
    );
  }

  static String? _serverMessage(Object? body) {
    if (body is Map && body['message'] is String) return body['message'] as String;
    return null;
  }

  static Map<String, List<String>> _fieldErrors(Object? body) {
    if (body is! Map || body['errors'] is! Map) {
      return const <String, List<String>>{};
    }
    final Map<String, List<String>> result = <String, List<String>>{};
    (body['errors'] as Map).forEach((Object? key, Object? value) {
      if (key is String && value is List) {
        result[key] = value.whereType<String>().toList(growable: false);
      }
    });
    return result;
  }
}
