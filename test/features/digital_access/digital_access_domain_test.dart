import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/access_grant.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/access_status.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

void main() {
  group('AccessStatus', () {
    test('every value round-trips through its wire value', () {
      for (final AccessStatus s in AccessStatus.values) {
        expect(AccessStatus.fromWire(s.wireValue), s);
      }
    });

    test('wire values match the Laravel AccessGrant constants', () {
      expect(AccessStatus.notIssued.wireValue, 'not_issued');
      expect(AccessStatus.issueRequested.wireValue, 'issue_requested');
      expect(AccessStatus.active.wireValue, 'active');
      expect(AccessStatus.revoked.wireValue, 'revoked');
      expect(AccessStatus.expired.wireValue, 'expired');
    });

    test('an unknown wire value falls back to notIssued', () {
      expect(AccessStatus.fromWire('???'), AccessStatus.notIssued);
    });

    test('terminal statuses mirror the state machine', () {
      expect(AccessStatus.revoked.isTerminal, isTrue);
      expect(AccessStatus.expired.isTerminal, isTrue);
      expect(AccessStatus.active.isTerminal, isFalse);
      expect(AccessStatus.failed.isTerminal, isFalse);
    });

    test('predicates', () {
      expect(AccessStatus.active.isActive, isTrue);
      expect(AccessStatus.failed.isFailed, isTrue);
      expect(AccessStatus.issueRequested.isIssuing, isTrue);
      expect(AccessStatus.notIssued.isNotIssued, isTrue);
    });
  });

  group('AccessMode', () {
    test('round-trips and defaults to pinCode', () {
      expect(AccessMode.fromWire('pin_code'), AccessMode.pinCode);
      expect(AccessMode.fromWire('smart_lock'), AccessMode.smartLock);
      expect(AccessMode.fromWire(null), AccessMode.pinCode);
      expect(AccessMode.fromWire('weird'), AccessMode.pinCode);
    });
  });

  group('AccessGrant — credential safety', () {
    AccessGrant grant(AccessStatus status) => AccessGrant(
          reservationId: 'r1',
          status: status,
          mode: AccessMode.pinCode,
          credential: '842916',
        );

    test('visibleCredential is only exposed while ACTIVE', () {
      expect(grant(AccessStatus.active).visibleCredential, '842916');
      expect(grant(AccessStatus.revoked).visibleCredential, isNull);
      expect(grant(AccessStatus.expired).visibleCredential, isNull);
      expect(grant(AccessStatus.failed).visibleCredential, isNull);
      expect(grant(AccessStatus.issueRequested).visibleCredential, isNull);
    });

    test('toString never contains the credential', () {
      expect(grant(AccessStatus.active).toString(), isNot(contains('842916')));
    });

    test('notIssued factory does not "exist"', () {
      final g = AccessGrant.notIssued('r1');
      expect(g.status, AccessStatus.notIssued);
      expect(g.exists, isFalse);
      expect(grant(AccessStatus.active).exists, isTrue);
    });
  });

  group('CheckInEligibility', () {
    test('maps each reservation status to a gate', () {
      expect(CheckInEligibility.fromReservation(ReservationStatus.verified),
          CheckInEligibility.ready);
      expect(CheckInEligibility.fromReservation(ReservationStatus.pending),
          CheckInEligibility.notReady);
      expect(CheckInEligibility.fromReservation(ReservationStatus.depositHeld),
          CheckInEligibility.notReady);
      expect(CheckInEligibility.fromReservation(ReservationStatus.checkedIn),
          CheckInEligibility.alreadyCheckedIn);
      expect(CheckInEligibility.fromReservation(ReservationStatus.inStay),
          CheckInEligibility.alreadyCheckedIn);
      expect(CheckInEligibility.fromReservation(ReservationStatus.checkedOut),
          CheckInEligibility.unavailable);
      expect(CheckInEligibility.fromReservation(ReservationStatus.cancelled),
          CheckInEligibility.unavailable);
    });

    test('only "ready" can start check-in', () {
      expect(CheckInEligibility.ready.canStart, isTrue);
      expect(CheckInEligibility.notReady.canStart, isFalse);
      expect(CheckInEligibility.alreadyCheckedIn.canStart, isFalse);
      expect(CheckInEligibility.unavailable.canStart, isFalse);
    });
  });

  group('CheckInOutcome / CheckInResult', () {
    AccessGrant g(AccessStatus s) =>
        AccessGrant(reservationId: 'r1', status: s, mode: AccessMode.pinCode);

    test('maps grant status to a safe outcome', () {
      expect(CheckInOutcome.fromGrant(g(AccessStatus.active)),
          CheckInOutcome.checkedIn);
      expect(CheckInOutcome.fromGrant(g(AccessStatus.failed)),
          CheckInOutcome.issueFailed);
      expect(CheckInOutcome.fromGrant(g(AccessStatus.issueRequested)),
          CheckInOutcome.pending);
    });

    test('success / retryable partition', () {
      expect(CheckInOutcome.checkedIn.isSuccess, isTrue);
      expect(CheckInOutcome.issueFailed.isRetryable, isTrue);
      expect(CheckInOutcome.pending.isSuccess, isFalse);
      expect(CheckInOutcome.pending.isRetryable, isFalse);
    });

    test('CheckInResult.of derives the outcome', () {
      expect(CheckInResult.of(g(AccessStatus.active)).outcome,
          CheckInOutcome.checkedIn);
    });
  });

  group('CheckInRequest', () {
    test('idempotency key is stable, no time / random', () {
      const a = CheckInRequest(reservationId: 'r1');
      const b = CheckInRequest(reservationId: 'r1');
      expect(a.idempotencyKey, 'checkin:r1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different reservation yields a different key', () {
      expect(const CheckInRequest(reservationId: 'r2').idempotencyKey,
          isNot(const CheckInRequest(reservationId: 'r1').idempotencyKey));
    });
  });
}
