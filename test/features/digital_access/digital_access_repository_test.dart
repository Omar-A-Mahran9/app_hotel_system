import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/dummy_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/data/models/digital_access_models.dart';
import 'package:hotel_guest_app/features/digital_access/data/repositories/digital_access_repository_impl.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/access_status.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';

import 'digital_access_test_support.dart';

class _ThrowingSource implements DigitalAccessDataSource {
  const _ThrowingSource(this.error);
  final Object error;

  @override
  Future<AccessGrantModel?> fetchGrant(String reservationId) async =>
      throw error;

  @override
  Future<AccessGrantModel> checkIn(CheckInRequest request) async => throw error;
}

void main() {
  test('maps a resolved check-in to a CheckInResult', () async {
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    final repo = DigitalAccessRepositoryImpl(
      DummyDigitalAccessDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final result = await repo.checkIn(CheckInRequest(reservationId: id));
    expect(result.outcome, CheckInOutcome.checkedIn);
    expect(result.grant.status, AccessStatus.active);
  });

  test('currentGrant returns a synthetic notIssued when there is none',
      () async {
    final repo = DigitalAccessRepositoryImpl(
      DummyDigitalAccessDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final grant = await repo.currentGrant('nope');
    expect(grant.exists, isFalse);
    expect(grant.status, AccessStatus.notIssued);
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo = DigitalAccessRepositoryImpl(
      const _ThrowingSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      repo.checkIn(fakeCheckInRequest()),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });

  test('a network error becomes a retryable network Failure', () async {
    final repo =
        DigitalAccessRepositoryImpl(const _ThrowingSource(NetworkException()));
    await expectLater(
      repo.currentGrant('x'),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.network)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo = DigitalAccessRepositoryImpl(
      const _ThrowingSource(FormatException('boom')),
    );
    await expectLater(repo.checkIn(fakeCheckInRequest()), throwsA(isA<Failure>()));
  });
}
