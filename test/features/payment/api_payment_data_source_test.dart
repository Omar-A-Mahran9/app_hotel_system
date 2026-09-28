import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/api_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';

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

ApiPaymentDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiPaymentDataSource(ApiClient.withDio(dio));
}

void main() {
  test('fetchForReservation returns null when data is null (no payment yet)', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/payment': (200, <String, dynamic>{
        'success': true,
        'message': 'no payment',
        'data': null,
      }),
    });

    expect(await _source(adapter).fetchForReservation('9'), isNull);
  });

  test('fetchForReservation parses an existing GuestPaymentResource', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/payment': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 3,
          'reservation_id': 9,
          'status': 'hold_active',
          'amount': '600.00',
          'currency': 'SAR',
        },
      }),
    });

    final payment = await _source(adapter).fetchForReservation('9');
    expect(payment!.status.wireValue, 'hold_active');
    expect(payment.amount, 600);
  });

  test('requestHold surfaces the deposit-rule-undefined 422 as a validation failure', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/payment/hold': (422, <String, dynamic>{
        'success': false,
        'message': 'No approved guest deposit-amount rule is configured yet.',
        'errors': <String, dynamic>{'reason': 'deposit_amount_rule_undefined'},
      }),
    });

    final request = PaymentHoldRequest(
      reservationId: '9',
      amount: const Money(amount: 600, currency: 'SAR'),
    );

    await expectLater(
      _source(adapter).requestHold(request),
      throwsA(isA<DioException>()
          .having((DioException e) => e.response?.statusCode, 'statusCode', 422)),
    );
    expect(adapter.received.single.headers['Idempotency-Key'], isNotNull);
  });
}
