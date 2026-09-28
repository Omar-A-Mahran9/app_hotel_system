import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/api_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';

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

ApiStayServicesDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiStayServicesDataSource(ApiClient.withDio(dio));
}

void main() {
  test('fetchCatalogue merges categories + services', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/1/service-categories': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'Spa', 'is_active': true},
        ],
      }),
      'GET /guest/hotels/1/services': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 10,
            'service_category_id': 1,
            'name': 'Massage',
            'description': '60 min',
            'price': '150.00',
            'currency': 'SAR',
            'is_active': true,
          },
        ],
      }),
    });

    final catalogue = await _source(adapter).fetchCatalogue('1');
    expect(catalogue.categories.single.name.en, 'Spa');
    expect(catalogue.services.single.price.amount, 150);
  });

  test('createOrder posts service_id/quantity/notes with Idempotency-Key', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/service-orders': (201, <String, dynamic>{
        'success': true,
        'message': 'Created',
        'data': <String, dynamic>{
          'id': 5,
          'reservation_id': 9,
          'service_id': 10,
          'quantity': 2,
          'unit_price_snapshot': '150.00',
          'currency_snapshot': 'SAR',
          'total_amount': '300.00',
          'status': 'requested',
          'requested_at': '2026-09-01T00:00:00Z',
        },
      }),
    });

    final order = await _source(adapter).createOrder(const CreateServiceRequest(
      reservationId: '9',
      serviceId: '10',
      serviceName: LocalizedText(ar: 'مساج', en: 'Massage'),
      quantity: 2,
    ));

    expect(order.totalAmount, 300);
    expect(adapter.received.single.data, <String, dynamic>{
      'service_id': 10,
      'quantity': 2,
    });
    expect(adapter.received.single.headers['Idempotency-Key'], isNotNull);
  });
}
