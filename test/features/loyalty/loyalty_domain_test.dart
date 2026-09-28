import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_account.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_transaction_type.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'loyalty_test_support.dart';

void main() {
  group('LoyaltyTransactionType', () {
    test('round-trips through the exact Laravel wire values', () {
      for (final LoyaltyTransactionType t in LoyaltyTransactionType.values) {
        expect(LoyaltyTransactionType.fromWire(t.wireValue), t);
      }
      expect(LoyaltyTransactionType.earn.wireValue, 'earn');
      expect(LoyaltyTransactionType.redeem.wireValue, 'redeem');
      expect(LoyaltyTransactionType.reverse.wireValue, 'reverse');
      expect(LoyaltyTransactionType.adjust.wireValue, 'adjust');
      expect(LoyaltyTransactionType.expire.wireValue, 'expire');
    });

    test('an unknown value defensively maps to adjust, never throws', () {
      expect(LoyaltyTransactionType.fromWire('tier_upgrade'),
          LoyaltyTransactionType.adjust);
    });

    test('guest-operation + credit predicates', () {
      expect(LoyaltyTransactionType.earn.isGuestOperation, isTrue);
      expect(LoyaltyTransactionType.redeem.isGuestOperation, isTrue);
      expect(LoyaltyTransactionType.adjust.isGuestOperation, isFalse);
      expect(LoyaltyTransactionType.earn.isCredit, isTrue);
      expect(LoyaltyTransactionType.redeem.isCredit, isFalse);
    });
  });

  group('LoyaltyTransaction', () {
    LoyaltyTransaction tx(int points, {String? sourceId}) => LoyaltyTransaction(
          id: 'x',
          type: points >= 0
              ? LoyaltyTransactionType.earn
              : LoyaltyTransactionType.redeem,
          points: points,
          sourceType: sourceId == null ? null : 'reservation',
          sourceId: sourceId,
        );

    test('magnitude is unsigned; credit/debit follow the sign', () {
      expect(tx(450).magnitude, 450);
      expect(tx(-290).magnitude, 290);
      expect(tx(450).isCredit, isTrue);
      expect(tx(-290).isDebit, isTrue);
    });

    test('isForReservation needs both the source type and id to match', () {
      expect(tx(10, sourceId: 'r1').isForReservation('r1'), isTrue);
      expect(tx(10, sourceId: 'r1').isForReservation('r2'), isFalse);
      expect(tx(10).isForReservation('r1'), isFalse);
    });
  });

  group('LoyaltyAccount', () {
    test('hasPoints; the unknown placeholder is empty + inactive', () {
      expect(const LoyaltyAccount(pointsBalance: 5, isActive: true).hasPoints,
          isTrue);
      expect(const LoyaltyAccount(pointsBalance: 0, isActive: true).hasPoints,
          isFalse);
      expect(LoyaltyAccount.unknown.pointsBalance, 0);
      expect(LoyaltyAccount.unknown.isActive, isFalse);
    });
  });

  group('LoyaltyContext eligibility (UX pre-check mirrors the backend)', () {
    LoyaltyContext ctx(ReservationStatus s) => fakeLoyaltyContext(status: s);

    test('completed stay = CHECKED_OUT or INVOICED only', () {
      expect(ctx(ReservationStatus.checkedOut).isCompletedStay, isTrue);
      expect(ctx(ReservationStatus.invoiced).isCompletedStay, isTrue);
      for (final ReservationStatus s in <ReservationStatus>[
        ReservationStatus.pending,
        ReservationStatus.checkedIn,
        ReservationStatus.inStay,
        ReservationStatus.cancelled,
      ]) {
        expect(ctx(s).isCompletedStay, isFalse, reason: s.name);
      }
    });

    test('redeemable booking = the active pre-completion statuses', () {
      for (final ReservationStatus s in <ReservationStatus>[
        ReservationStatus.pending,
        ReservationStatus.depositHeld,
        ReservationStatus.verified,
        ReservationStatus.checkedIn,
        ReservationStatus.inStay,
      ]) {
        expect(ctx(s).isRedeemableBooking, isTrue, reason: s.name);
      }
      for (final ReservationStatus s in <ReservationStatus>[
        ReservationStatus.checkedOut,
        ReservationStatus.invoiced,
        ReservationStatus.cancelled,
      ]) {
        expect(ctx(s).isRedeemableBooking, isFalse, reason: s.name);
      }
    });
  });

  group('redeem requests', () {
    test('idempotency keys are stable and carry no time / randomness', () {
      expect(
          const RedeemPointsRequest(reservationId: 'r1', points: 100)
              .idempotencyKey,
          'loyalty:redeem:r1:100');
    });

    test('redeem equality includes points', () {
      expect(const RedeemPointsRequest(reservationId: 'r1', points: 100),
          const RedeemPointsRequest(reservationId: 'r1', points: 100));
      expect(const RedeemPointsRequest(reservationId: 'r1', points: 100),
          isNot(const RedeemPointsRequest(reservationId: 'r1', points: 150)));
    });
  });

  group('business outcomes are success/blocked, never a Failure', () {
    test('redeem outcomes', () {
      expect(LoyaltyRedeemOutcome.redeemed.isSuccess, isTrue);
      expect(LoyaltyRedeemOutcome.alreadyRedeemed.isSuccess, isTrue);
      expect(LoyaltyRedeemOutcome.alreadyRedeemedDifferent.isBlocked, isTrue);
      expect(LoyaltyRedeemOutcome.insufficientPoints.isBlocked, isTrue);
      expect(LoyaltyRedeemOutcome.invalidAmount.isBlocked, isTrue);
    });
  });
}
