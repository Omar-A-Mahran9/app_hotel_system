import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/data/models/stay_services_models.dart';
import 'package:hotel_guest_app/features/stay_services/data/repositories/stay_services_repository_impl.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';

import 'stay_services_test_support.dart';

class _ThrowingSource implements StayServicesDataSource {
  const _ThrowingSource(this.error);
  final Object error;
  @override
  Future<ServiceCatalogue> fetchCatalogue(String h) async => throw error;
  @override
  Future<List<ServiceOrderModel>> fetchOrders(String r) async => throw error;
  @override
  Future<ServiceOrderModel> fetchOrder(String r, String o) async => throw error;
  @override
  Future<ServiceOrderModel> createOrder(CreateServiceRequest r) async =>
      throw error;
  @override
  Future<ServiceOrderModel> cancelOrder(String r, String o) async => throw error;
}

void main() {
  test('requestService returns an order carrying the request name snapshot',
      () async {
    final repo = StayServicesRepositoryImpl(
      DummyStayServicesDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final ServiceOrder order = await repo.requestService(fakeServiceRequest());
    expect(order.serviceName.resolve(const Locale('en')), 'Room cleaning');
    expect(order.status.wireValue, 'requested');
  });

  test('ordersFor joins each order with the catalogue for a display name',
      () async {
    final repo = StayServicesRepositoryImpl(
      DummyStayServicesDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    await repo.requestService(fakeServiceRequest(serviceId: '102'));
    final orders = await repo.ordersFor('res-1');
    expect(orders, hasLength(1));
    expect(orders.first.serviceName.resolve(const Locale('en')), 'Room service');
  });

  test('a NotFound from the data source becomes a notFound Failure', () async {
    final repo = StayServicesRepositoryImpl(
      DummyStayServicesDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    await expectLater(
      repo.orderById('res-1', 'missing'),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound)),
    );
  });

  test('a Conflict from a bad cancel becomes a conflict Failure', () async {
    final rid = reservationIdWithConfirmedOrder();
    final ds = DummyStayServicesDataSource(clock: () => DateTime(2026, 9, 8));
    final repo = StayServicesRepositoryImpl(ds);
    final o = await repo.requestService(fakeServiceRequest(reservationId: rid));
    await expectLater(
      repo.cancelOrder(rid, o.id),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.conflict)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo =
        StayServicesRepositoryImpl(const _ThrowingSource(FormatException('x')));
    await expectLater(repo.catalogue('h'), throwsA(isA<Failure>()));
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo = StayServicesRepositoryImpl(
      const _ThrowingSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      repo.requestService(fakeServiceRequest()),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });
}
