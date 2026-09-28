import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/api_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/repositories/checkout_repository.dart';

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

ApiCheckoutDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiCheckoutDataSource(ApiClient.withDio(dio));
}

void main() {
  test('performCheckout parses a completed CheckoutResource', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/checkout': (200, <String, dynamic>{
        'success': true,
        'message': 'Completed',
        'data': <String, dynamic>{
          'reservation': <String, dynamic>{'id': 9, 'hotel_id': 1, 'status': 'checked_out'},
          'checkout': <String, dynamic>{'status': 'completed'},
          'totals': <String, dynamic>{
            'charges_total': '600.00',
            'payments_total': '600.00',
            'outstanding_total': '0.00',
          },
          'currency': 'SAR',
          'payment': <String, dynamic>{'status': 'settled'},
          'invoice': <String, dynamic>{'id': 3, 'invoice_number': 'INV-3', 'status': 'issued'},
        },
      }),
    });

    final result = await _source(adapter).performCheckout(
      const CheckoutRequest(reservationId: '9'),
      const FolioContext(reservationId: '9', accommodationAmount: 600, currency: 'SAR'),
    );

    expect(result.outcome, CheckoutOutcome.completed);
    expect(result.invoice!.invoiceNumber, 'INV-3');
  });

  test('performCheckout re-derives a pending outcome from a real folio on 422', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/checkout': (422, <String, dynamic>{
        'success': false,
        'message': 'Settlement pending',
        'errors': <String, dynamic>{
          'checkout_status': 'awaiting_settlement',
          'payment_status': 'capture_requested',
        },
      }),
      'GET /guest/reservations/9/folio': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'reservation': <String, dynamic>{'id': 9, 'hotel_id': 1, 'guest_id': 2, 'status': 'checkout_in_progress'},
          'currency': 'SAR',
          'charges': <Object?>[],
          'totals': <String, dynamic>{
            'charges_total': '600.00',
            'payments_total': '400.00',
            'outstanding_total': '200.00',
          },
        },
      }),
    });

    final result = await _source(adapter).performCheckout(
      const CheckoutRequest(reservationId: '9'),
      const FolioContext(reservationId: '9', accommodationAmount: 600, currency: 'SAR'),
    );

    expect(result.outcome, CheckoutOutcome.settlementPending);
    expect(result.checkout.outstandingTotal.amount, 200);
  });

  test('fetchInvoice parses items', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/invoice': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'id': 3,
          'reservation_id': 9,
          'invoice_number': 'INV-3',
          'status': 'issued',
          'currency': 'SAR',
          'subtotal': '600.00',
          'payments_total': '600.00',
          'outstanding_total': '0.00',
          'items': <Object?>[],
        },
      }),
    });

    final invoice = await _source(adapter).fetchInvoice('9');
    expect(invoice.invoiceNumber, 'INV-3');
  });
}
