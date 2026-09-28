import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/loyalty/data/datasources/dummy_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_transaction_type.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'loyalty_test_support.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 11);
  DummyLoyaltyDataSource source({bool seedLedger = true}) =>
      DummyLoyaltyDataSource(clock: () => now, seedLedger: seedLedger);

  group('DummyLoyaltyDataSource — reads', () {
    test('a seeded account has a cached balance and the program flag', () async {
      final String id = activeProgramId();
      final account = await source().fetchAccount(fakeLoyaltyContext(
          reservationId: id, status: ReservationStatus.checkedIn));
      expect(account.pointsBalance, 1240);
      expect(account.isActive, isTrue);
    });

    test('an unseeded account is empty', () async {
      final account = await source(seedLedger: false).fetchAccount(
          fakeLoyaltyContext(
              reservationId: activeProgramId(),
              status: ReservationStatus.checkedIn));
      expect(account.pointsBalance, 0);
    });

    test('transactions come back newest-first', () async {
      final ledger = await source().fetchTransactions(
          fakeLoyaltyContext(status: ReservationStatus.checkedIn));
      expect(ledger, hasLength(3));
      for (int i = 0; i < ledger.length - 1; i++) {
        expect(
          ledger[i].createdAt!.isAfter(ledger[i + 1].createdAt!) ||
              ledger[i].createdAt!.isAtSameMomentAs(ledger[i + 1].createdAt!),
          isTrue,
        );
      }
    });

    test('the program is off for one deterministic slice', () async {
      final account = await source().fetchAccount(
          fakeLoyaltyContext(reservationId: programInactiveId()));
      expect(account.isActive, isFalse);
    });
  });

  // Mirrors the backend's lifecycle accrual listener: by the time the guest
  // reads a completed stay, its points are already credited — exactly once.
  group('DummyLoyaltyDataSource — automatic accrual', () {
    test('a completed stay is credited once, with one ledger entry', () async {
      final String id = activeProgramId();
      final s = source();
      final account = await s.fetchAccount(
          fakeLoyaltyContext(reservationId: id, amount: 900));
      expect(account.pointsBalance, 1240 + 450); // 900 / 2 (dummy sample rate)

      final ledger =
          await s.fetchTransactions(fakeLoyaltyContext(reservationId: id));
      expect(ledger, hasLength(4));
      final earn = ledger.singleWhere((t) => t.isForReservation(id));
      expect(earn.type, LoyaltyTransactionType.earn);
      expect(earn.points, 450);
    });

    test('repeated reads never double-accrue', () async {
      final String id = activeProgramId();
      final s = source();
      final ctx = fakeLoyaltyContext(reservationId: id);
      await s.fetchAccount(ctx);
      await s.fetchTransactions(ctx);
      final again = await s.fetchAccount(ctx);
      expect(again.pointsBalance, 1240 + 450);
      expect(
        (await s.fetchTransactions(ctx)).where((t) => t.isForReservation(id)),
        hasLength(1),
      );
    });

    test('a not-yet-completed stay earns nothing', () async {
      final String id = activeProgramId();
      final account = await source().fetchAccount(fakeLoyaltyContext(
          reservationId: id, status: ReservationStatus.checkedIn));
      expect(account.pointsBalance, 1240);
    });

    test('an inactive program earns nothing', () async {
      final String id = programInactiveId();
      final s = source();
      await s.fetchAccount(fakeLoyaltyContext(reservationId: id));
      expect(
        (await s.fetchTransactions(fakeLoyaltyContext(reservationId: id)))
            .where((t) => t.isForReservation(id)),
        isEmpty,
      );
    });

    test('a completed stay with no earnable value earns nothing', () async {
      final String id = activeProgramId();
      final account = await source()
          .fetchAccount(fakeLoyaltyContext(reservationId: id, amount: 1));
      expect(account.pointsBalance, 1240);
    });
  });

  group('DummyLoyaltyDataSource — redeem', () {
    LoyaltyContext redeemCtx(String id) => fakeLoyaltyContext(
        reservationId: id, status: ReservationStatus.checkedIn);

    test('redeeming against an eligible booking debits the balance', () async {
      final String id = redeemOkActiveId();
      final s = source();
      final result = await s.redeem(
        RedeemPointsRequest(reservationId: id, points: 100),
        redeemCtx(id),
      );
      expect(result.outcome, LoyaltyRedeemOutcome.redeemed);
      expect(result.transaction!.points, -100);
      expect(
        (await s.fetchAccount(redeemCtx(id))).pointsBalance,
        1240 - 100,
      );
    });

    test('redeeming the same amount again is an idempotent replay', () async {
      final String id = redeemAlreadyActiveId();
      final s = source();
      final first = await s.redeem(
          RedeemPointsRequest(reservationId: id, points: 100), redeemCtx(id));
      final second = await s.redeem(
          RedeemPointsRequest(reservationId: id, points: 100), redeemCtx(id));
      expect(first.outcome, LoyaltyRedeemOutcome.alreadyRedeemed);
      expect(second.outcome, LoyaltyRedeemOutcome.alreadyRedeemed);
    });

    test('a different amount against an already-redeemed booking is blocked',
        () async {
      final String id = redeemAlreadyActiveId();
      final s = source();
      await s.redeem(
          RedeemPointsRequest(reservationId: id, points: 100), redeemCtx(id));
      final other = await s.redeem(
          RedeemPointsRequest(reservationId: id, points: 150), redeemCtx(id));
      expect(other.outcome, LoyaltyRedeemOutcome.alreadyRedeemedDifferent);
    });

    test('redeeming more than the balance is insufficientPoints', () async {
      final String id = redeemOkActiveId();
      final result = await source(seedLedger: false).redeem(
        RedeemPointsRequest(reservationId: id, points: 50),
        redeemCtx(id),
      );
      expect(result.outcome, LoyaltyRedeemOutcome.insufficientPoints);
    });

    test('a non-positive amount is invalidAmount', () async {
      final String id = redeemOkActiveId();
      final result = await source().redeem(
        RedeemPointsRequest(reservationId: id, points: 0),
        redeemCtx(id),
      );
      expect(result.outcome, LoyaltyRedeemOutcome.invalidAmount);
    });

    test('redeeming against a completed (non-active) booking is not eligible',
        () async {
      final String id = redeemOkActiveId();
      final result = await source().redeem(
        RedeemPointsRequest(reservationId: id, points: 100),
        fakeLoyaltyContext(
            reservationId: id, status: ReservationStatus.checkedOut),
      );
      expect(result.outcome, LoyaltyRedeemOutcome.notEligible);
    });
  });

  group('DummyLoyaltyDataSource — failWith seam', () {
    test('surfaces the error from every method', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.fetchAccount(fakeLoyaltyContext()), throwsA(isA<NetworkException>()));
      await expectLater(s.fetchTransactions(fakeLoyaltyContext()),
          throwsA(isA<NetworkException>()));
      await expectLater(
        s.redeem(const RedeemPointsRequest(reservationId: 'x', points: 1),
            fakeLoyaltyContext()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // `ApiLoyaltyDataSource` is now real for reads + redeem; `earn` stays
  // unimplemented — there is no guest-triggerable earn endpoint — see
  // test/features/loyalty/api_loyalty_data_source_test.dart.
}
