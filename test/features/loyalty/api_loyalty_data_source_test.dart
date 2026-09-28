import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/loyalty/data/datasources/api_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

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

ApiLoyaltyDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiLoyaltyDataSource(ApiClient.withDio(dio));
}

const LoyaltyContext _ctx = LoyaltyContext(
  reservationId: '9',
  reservationStatus: ReservationStatus.verified,
  reservationAmount: 600,
  currency: 'SAR',
);

void main() {
  test('fetchAccount parses the balance', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/loyalty': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{'id': 1, 'guest_id': 2, 'points_balance': 500, 'is_active': true},
      }),
    });

    final account = await _source(adapter).fetchAccount(_ctx);
    expect(account.pointsBalance, 500);
  });

  test('redeem maps a 201 to LoyaltyRedeemOutcome.redeemed', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/loyalty/redeem': (201, <String, dynamic>{
        'success': true,
        'message': 'Redeemed',
        'data': <String, dynamic>{
          'id': 5,
          'type': 'redeem',
          'points': -100,
          'source_type': 'reservation',
          'source_id': 9,
        },
      }),
    });

    final result = await _source(adapter).redeem(
      const RedeemPointsRequest(reservationId: '9', points: 100),
      _ctx,
    );

    expect(result.outcome, LoyaltyRedeemOutcome.redeemed);
    expect(adapter.received.single.data, <String, dynamic>{'points': 100});
  });

  test('redeem maps insufficient_points_balance reason to insufficientPoints', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/loyalty/redeem': (422, <String, dynamic>{
        'success': false,
        'message': 'This loyalty operation is not allowed.',
        'errors': <String, dynamic>{'reason': 'insufficient_points_balance'},
      }),
    });

    final result = await _source(adapter).redeem(
      const RedeemPointsRequest(reservationId: '9', points: 100000),
      _ctx,
    );

    expect(result.outcome, LoyaltyRedeemOutcome.insufficientPoints);
    expect(result.transaction, isNull);
  });

  test('redeem maps a field-level points validation error to invalidAmount', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/loyalty/redeem': (422, <String, dynamic>{
        'success': false,
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'points': <String>['The points field must be at least 1.'],
        },
      }),
    });

    final result = await _source(adapter).redeem(
      const RedeemPointsRequest(reservationId: '9', points: 0),
      _ctx,
    );

    expect(result.outcome, LoyaltyRedeemOutcome.invalidAmount);
  });
}
