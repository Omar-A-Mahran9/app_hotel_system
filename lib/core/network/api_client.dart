import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../security/token_store.dart';
import 'api_image_url_resolver.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/locale_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/session_interceptor.dart';
import 'session_events.dart';

/// Thin wrapper over [Dio] that centralizes base URL, `/api/v1` prefix,
/// timeouts, auth headers and error normalization (mobile/docs/architecture.md §5).
///
/// API data sources depend on this — screens never touch it, and never call
/// `http`/`Dio` directly (mobile/docs/coding_rules.md §6). Phase 0 wires the
/// client but no feature endpoint is called yet.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStore tokenStore,
    String Function()? languageCode,
    SessionEvents? sessionEvents,
  })
      : _imageUrlResolver = ApiImageUrlResolver(config.apiBaseUrl),
        _dio = Dio(
          BaseOptions(
            baseUrl: config.apiRoot,
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    _dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(tokenStore),
      if (languageCode != null) LocaleInterceptor(languageCode),
      LoggingInterceptor(),
      if (sessionEvents != null) SessionInterceptor(sessionEvents),
      ErrorInterceptor(),
    ]);
  }

  /// Test seam: inject a preconfigured [Dio] (e.g. with `MockAdapter`), and
  /// optionally an [imageUrlResolver] for tests that exercise media-URL
  /// rewriting. Defaults to a no-op resolver (empty API base URL never
  /// matches a dev loopback host), matching plain HTTP-mocking tests that
  /// don't care about it.
  ApiClient.withDio(
    this._dio, {
    this._imageUrlResolver = const ApiImageUrlResolver(''),
  });

  final Dio _dio;
  final ApiImageUrlResolver _imageUrlResolver;

  /// Rewrites a real API media URL (`cover_url`, `gallery[].url`, …) onto a
  /// host this client can actually reach — see [ApiImageUrlResolver]. Never
  /// fabricates a URL: input that isn't a recognized dev loopback host (a
  /// real CDN/production URL, or already `null`) passes through unchanged,
  /// so a hotel with no photo still renders no photo in real API mode.
  String? resolveMediaUrl(String? rawUrl) => _imageUrlResolver.resolve(rawUrl);

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      queryParameters: query,
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
      options: headers == null ? null : Options(headers: headers),
    );
    return _asJsonMap(response.data);
  }

  /// Same as [postJson] but also returns the HTTP status code — for the rare
  /// caller that must distinguish e.g. 201 "created" from 200 "returned the
  /// existing resource" on the same success envelope shape (the review
  /// submit duplicate-returns-existing rule).
  Future<(Map<String, dynamic> json, int? statusCode)> postJsonWithStatus(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
      options: headers == null ? null : Options(headers: headers),
    );
    return (_asJsonMap(response.data), response.statusCode);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final Response<dynamic> response = await _dio.patch<dynamic>(
      path,
      data: body,
      options: headers == null ? null : Options(headers: headers),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      path,
      data: body,
      options: headers == null ? null : Options(headers: headers),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      path,
      options: headers == null ? null : Options(headers: headers),
    );
    return _asJsonMap(response.data);
  }

  /// Multipart upload — one or more files plus scalar fields. Used by the
  /// identity-verification document / selfie endpoints (Slice 4).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, MultipartFile> files,
    Map<String, dynamic> fields = const <String, dynamic>{},
    Map<String, String>? headers,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{...fields, ...files});
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: form,
      options: headers == null ? null : Options(headers: headers),
      onSendProgress: onSendProgress,
    );
    return _asJsonMap(response.data);
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{'data': data};
  }
}
