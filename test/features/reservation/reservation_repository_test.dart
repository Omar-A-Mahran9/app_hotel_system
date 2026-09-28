import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/dummy_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/models/reservation_models.dart';
import 'package:hotel_guest_app/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'reservation_test_support.dart';

class _ThrowingDataSource implements ReservationDataSource {
  const _ThrowingDataSource(this.error);
  final Object error;

  @override
  Future<ReservationModel> create(CreateReservationRequest request) async =>
      throw error;

  @override
  Future<ReservationModel> fetchById(String id) async => throw error;

  @override
  Future<List<ReservationModel>> fetchList() async => throw error;

  @override
  Future<ReservationModel> cancel(String id) async => throw error;

  @override
  Future<ExtendStayResultModel> extend(ExtendStayRequest request) async =>
      throw error;
}

void main() {
  test('maps a created dummy reservation to a domain entity', () async {
    final repo = ReservationRepositoryImpl(
      DummyReservationDataSource(clock: () => DateTime(2026, 9, 8)),
    );

    final Reservation created = await repo.create(fakeRequest());
    expect(created.status, ReservationStatus.pending);
    expect(created.priceSnapshot.amount, 900);

    final Reservation fetched = await repo.getById(created.id);
    expect(fetched.reference, created.reference);
  });

  test('a NotFound from the data source becomes a notFound Failure', () async {
    final repo = ReservationRepositoryImpl(
      DummyReservationDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    await expectLater(
      repo.getById('missing'),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound)),
    );
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo = ReservationRepositoryImpl(
      const _ThrowingDataSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      repo.create(fakeRequest()),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo = ReservationRepositoryImpl(
      const _ThrowingDataSource(FormatException('boom')),
    );
    await expectLater(repo.create(fakeRequest()), throwsA(isA<Failure>()));
  });
}
