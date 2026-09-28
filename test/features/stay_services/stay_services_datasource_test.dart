import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order_status.dart';

import 'stay_services_test_support.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 12);

  group('DummyStayServicesDataSource', () {
    DummyStayServicesDataSource source() =>
        DummyStayServicesDataSource(clock: () => now);

    test('the catalogue is the fixed fixture, deterministic', () async {
      final a = await source().fetchCatalogue('any');
      final b = await source().fetchCatalogue('other');
      expect(a.services.length, b.services.length);
      expect(a.isEmpty, isFalse);
    });

    test('createOrder makes a `requested` order with a deterministic id',
        () async {
      final s = source();
      final m = await s.createOrder(fakeServiceRequest());
      expect(m.status, ServiceOrderStatus.requested);
      expect(m.reservationId, 'res-1');
      expect(m.serviceId, '101');
      expect(m.unitPrice, 0); // service 101 (Room cleaning) is included
    });

    test('the dummy total is unit x quantity in the backend DTO shape',
        () async {
      // Service 102 (Room service) is priced 30.
      final m = await source()
          .createOrder(fakeServiceRequest(serviceId: '102', quantity: 3));
      expect(m.unitPrice, 30);
      expect(m.totalAmount, 90);
    });

    test('createOrder is idempotent per request', () async {
      final s = source();
      final a = await s.createOrder(fakeServiceRequest());
      final b = await s.createOrder(fakeServiceRequest());
      expect(a.id, b.id);
      final orders = await s.fetchOrders('res-1');
      expect(orders.length, 1);
    });

    test('an unknown service id is a NotFound', () async {
      await expectLater(
        source().createOrder(fakeServiceRequest(serviceId: '9999')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('order progress is a pure function of the order id', () async {
      final id = orderIdForProgress(DummyOrderProgress.getsConfirmed);
      expect(DummyStayServicesDataSource.progressFor(id),
          DummyOrderProgress.getsConfirmed);
    });

    test('a still-requested order can be cancelled', () async {
      final rid = reservationIdWithCancellableOrder();
      final s = source();
      final created = await s.createOrder(fakeServiceRequest(reservationId: rid));
      expect(
          (await s.fetchOrder(rid, created.id)).status,
          ServiceOrderStatus.requested);
      final cancelled = await s.cancelOrder(rid, created.id);
      expect(cancelled.status, ServiceOrderStatus.cancelled);
      expect(cancelled.cancellationReason, isNotNull);
    });

    test('cancelling an already-actioned order is a conflict', () async {
      final rid = reservationIdWithConfirmedOrder();
      final s = source();
      final created = await s.createOrder(fakeServiceRequest(reservationId: rid));
      await expectLater(
        s.cancelOrder(rid, created.id),
        throwsA(isA<ConflictException>()),
      );
    });

    test('fetchOrder for a missing id is a NotFound', () async {
      await expectLater(
        source().fetchOrder('res-1', 'nope'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('failWith seam surfaces an error from every method', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.fetchCatalogue('h'), throwsA(isA<NetworkException>()));
      await expectLater(
          s.fetchOrders('r'), throwsA(isA<NetworkException>()));
      await expectLater(
          s.createOrder(fakeServiceRequest()), throwsA(isA<NetworkException>()));
    });
  });

  // `ApiStayServicesDataSource` is now real except `cancelOrder` (no guest
  // cancel endpoint exists) — see
  // test/features/stay_services/api_stay_services_data_source_test.dart.
}
