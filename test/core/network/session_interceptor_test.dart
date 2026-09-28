import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/interceptors/session_interceptor.dart';
import 'package:hotel_guest_app/core/network/session_events.dart';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'message': 'Unauthenticated.'}),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

Future<int> _rejections({
  required int status,
  required String path,
  String? token,
}) async {
  final SessionEvents events = SessionEvents();
  int count = 0;
  events.tokenRejected.listen((_) => count++);
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = _StatusAdapter(status)
    ..interceptors.add(SessionInterceptor(events));
  try {
    await dio.get<dynamic>(
      path,
      options: Options(headers: <String, dynamic>{
        if (token != null) 'Authorization': 'Bearer $token',
      }),
    );
  } on DioException catch (_) {}
  await pumpEventQueue();
  events.dispose();
  return count;
}

void main() {
  test('a 401 on an authenticated request reports the token as rejected',
      () async {
    expect(
      await _rejections(status: 401, path: '/guest/reservations', token: 't'),
      1,
    );
  });

  test('a 401 without a token (anonymous browsing) reports nothing', () async {
    expect(await _rejections(status: 401, path: '/guest/reservations'), 0);
  });

  test('the logout call and non-401 failures report nothing', () async {
    expect(
      await _rejections(status: 401, path: '/guest/auth/logout', token: 't'),
      0,
    );
    expect(
      await _rejections(status: 403, path: '/guest/reservations', token: 't'),
      0,
    );
    expect(
      await _rejections(status: 500, path: '/guest/reservations', token: 't'),
      0,
    );
  });
}
