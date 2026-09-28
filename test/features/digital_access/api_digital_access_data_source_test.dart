import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/api_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    final String key = '${options.method} ${options.path}';
    final (int, Map<String, dynamic>) entry =
        routes[key] ?? (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiDigitalAccessDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiDigitalAccessDataSource(ApiClient.withDio(dio));
}

void main() {
  test('checkIn parses an ACTIVE grant on 201', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/check-in': (201, <String, dynamic>{
        'success': true,
        'message': 'checked in',
        'data': <String, dynamic>{
          'reservation_id': 9,
          'status': 'active',
          'access_mode': 'pin',
          'credential': '1234',
        },
      }),
    });

    final grant = await _source(adapter).checkIn(const CheckInRequest(reservationId: '9'));
    expect(grant.status.isActive, isTrue);
    expect(grant.credential, '1234');
    expect(adapter.received.single.headers['Idempotency-Key'], isNotNull);
  });

  test('checkIn re-reads the grant on 422 issuance-failed instead of throwing', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/check-in': (422, <String, dynamic>{
        'success': false,
        'message': 'Issue failed',
        'errors': <String, dynamic>{'status': 'failed'},
      }),
      'GET /guest/reservations/9/access': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'reservation_id': 9,
          'status': 'failed',
          'access_mode': 'pin',
          'failure_reason': 'provider_error',
        },
      }),
    });

    final grant = await _source(adapter).checkIn(const CheckInRequest(reservationId: '9'));
    expect(grant.status.isFailed, isTrue);
    expect(grant.credential, isNull);
  });

  test('fetchGrant returns null when there is no grant yet', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/access': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': null,
      }),
    });

    expect(await _source(adapter).fetchGrant('9'), isNull);
  });
}
