import 'package:dio/dio.dart';

import '../session_events.dart';

/// Reports a 401 on an authenticated request to [SessionEvents]. Requests sent
/// without a token (anonymous browsing, OTP) and the logout call itself are
/// ignored — a 401 there says nothing about a live session.
class SessionInterceptor extends Interceptor {
  SessionInterceptor(this._events);

  final SessionEvents _events;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final RequestOptions request = err.requestOptions;
    if (err.response?.statusCode == 401 &&
        request.headers['Authorization'] != null &&
        !request.path.endsWith('/auth/logout')) {
      _events.reportTokenRejected();
    }
    handler.next(err);
  }
}
