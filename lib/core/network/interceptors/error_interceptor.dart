import 'package:dio/dio.dart';

import '../../errors/error_mapper.dart';

/// Rejects failed responses with a normalized [AppException] instead of a raw
/// [DioException], so data sources catch a single, typed hierarchy.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ErrorMapper.fromDioException(err),
      ),
    );
  }
}
