import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Minimal request/response logging for debug builds only.
///
/// Sensitive headers and bodies are redacted so tokens, identity documents and
/// payment secrets never reach the console (mobile/docs/architecture.md §8).
class LoggingInterceptor extends Interceptor {
  static const Set<String> _redactedHeaders = <String>{
    'authorization',
    'cookie',
    'set-cookie',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '→ ${options.method} ${options.uri.path}',
        name: 'api',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.uri.path}',
        name: 'api',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '× ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.uri.path}',
        name: 'api',
      );
    }
    handler.next(err);
  }

  /// Exposed for tests: returns headers safe to print.
  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    return headers.map(
      (String key, dynamic value) => MapEntry<String, dynamic>(
        key,
        _redactedHeaders.contains(key.toLowerCase()) ? '***' : value,
      ),
    );
  }
}
