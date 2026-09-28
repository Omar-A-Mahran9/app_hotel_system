import 'package:hotel_guest_app/features/loyalty/data/datasources/dummy_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

export '../payment/payment_test_support.dart' show fakeReservation;

/// A [LoyaltyContext] with sane defaults for a completed, points-earning stay.
LoyaltyContext fakeLoyaltyContext({
  String reservationId = 'res-1',
  ReservationStatus status = ReservationStatus.checkedOut,
  int amount = 900,
  String currency = 'SAR',
}) =>
    LoyaltyContext(
      reservationId: reservationId,
      reservationStatus: status,
      reservationAmount: amount,
      currency: currency,
    );

String _find(bool Function(String id) predicate) {
  for (int i = 0; i < 4000; i++) {
    final String id = 'L$i';
    if (predicate(id)) return id;
  }
  throw StateError('no reservation id matched the predicate');
}

/// A reservation whose loyalty program is active.
String activeProgramId() =>
    _find((String id) => DummyLoyaltyDataSource.programActiveFor(id));

/// Program active + a redeemable redeem scenario.
String redeemOkActiveId() => _find((String id) =>
    DummyLoyaltyDataSource.programActiveFor(id) &&
    DummyLoyaltyDataSource.redeemScenarioFor(id) ==
        DummyRedeemScenario.redeemsOk);

/// Program active + the "already redeemed" redeem scenario.
String redeemAlreadyActiveId() => _find((String id) =>
    DummyLoyaltyDataSource.programActiveFor(id) &&
    DummyLoyaltyDataSource.redeemScenarioFor(id) ==
        DummyRedeemScenario.alreadyRedeemed);

/// The loyalty program is off for this reservation slice.
String programInactiveId() =>
    _find((String id) => !DummyLoyaltyDataSource.programActiveFor(id));
