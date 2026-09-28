import 'package:dio/dio.dart';

/// Tells Laravel which language to localize the response into.
///
/// The backend's `SetLocale` middleware reads `X-Locale` first; without it
/// every localized field falls back to English even when the app is in
/// Arabic. The language is read per request so a switch applies to the very
/// next call without rebuilding the client.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String code = _languageCode();
    options.headers['X-Locale'] = code;
    options.headers['Accept-Language'] = code;
    handler.next(options);
  }
}
