import 'package:dio/dio.dart';

import '../../security/token_store.dart';

/// Attaches the Sanctum bearer token to every request and asks for JSON.
///
/// The token is read from [TokenStore] per request so a fresh login / logout is
/// picked up without rebuilding the client. Nothing is logged here.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    final String? token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
