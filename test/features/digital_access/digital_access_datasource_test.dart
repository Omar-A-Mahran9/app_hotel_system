import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/dummy_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/access_status.dart';

import 'digital_access_test_support.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 14);

  group('DummyDigitalAccessDataSource', () {
    DummyDigitalAccessDataSource source() =>
        DummyDigitalAccessDataSource(clock: () => now);

    test('scenario is a pure function of the reservation id', () {
      final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
      expect(DummyDigitalAccessDataSource.scenarioFor(id),
          DummyCheckInScenario.issuesActive);
      expect(DummyDigitalAccessDataSource.scenarioFor(id),
          DummyCheckInScenario.issuesActive);
    });

    test('no grant is reported before check-in', () async {
      final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
      expect(await source().fetchGrant(id), isNull);
    });

    test('"issuesActive" scenario goes ACTIVE with a 6-digit credential',
        () async {
      final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
      final m = await source().checkIn(fakeCheckInRequest(reservationId: id));
      final grant = m.toEntity();
      expect(grant.status, AccessStatus.active);
      expect(grant.visibleCredential, isNotNull);
      expect(grant.visibleCredential!.length, 6);
      expect(grant.roomNumber, isNotNull);
      expect(grant.expiresAt, isNotNull);
    });

    test('"staysPending" scenario stays ISSUE_REQUESTED, no credential',
        () async {
      final id = reservationIdForCheckIn(DummyCheckInScenario.staysPending);
      final grant =
          (await source().checkIn(fakeCheckInRequest(reservationId: id)))
              .toEntity();
      expect(grant.status, AccessStatus.issueRequested);
      expect(grant.credential, isNull);
    });

    test('"failsThenActive" fails first, then a retry with the same key '
        'succeeds', () async {
      final id = reservationIdForCheckIn(DummyCheckInScenario.failsThenActive);
      final s = source();
      final first = await s.checkIn(fakeCheckInRequest(reservationId: id));
      expect(first.toEntity().status, AccessStatus.failed);
      expect(first.toEntity().failureReason, isNotNull);

      final retry = await s.checkIn(fakeCheckInRequest(reservationId: id));
      expect(retry.toEntity().status, AccessStatus.active);
    });

    test('a duplicate check-in of a successful request replays, not re-issues',
        () async {
      final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
      final s = source();
      final a = await s.checkIn(fakeCheckInRequest(reservationId: id));
      final b = await s.checkIn(fakeCheckInRequest(reservationId: id));
      expect(a.toEntity().credential, b.toEntity().credential);
      expect(await s.fetchGrant(id), isNotNull);
    });

    test('seedGrant places a reservation into a terminal state directly',
        () async {
      final s = source()..seedGrant('rvk', AccessStatus.revoked);
      final grant = (await s.fetchGrant('rvk'))!.toEntity();
      expect(grant.status, AccessStatus.revoked);
      expect(grant.revocationReason, isNotNull);
      expect(grant.visibleCredential, isNull);
    });

    test('failWith seam surfaces an error from both methods', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.checkIn(fakeCheckInRequest()), throwsA(isA<NetworkException>()));
      await expectLater(s.fetchGrant('x'), throwsA(isA<NetworkException>()));
    });
  });

  // `ApiDigitalAccessDataSource` is now a real implementation against the
  // guest check-in/access endpoints — see
  // test/features/digital_access/api_digital_access_data_source_test.dart.
}
